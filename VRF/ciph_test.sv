`timescale 1 ns / 1 ns

program ciph_test(
output logic clk,
output logic rst,
output logic tr_key,
output logic [7:0] data,
output logic read,
output logic st_dat,
output logic st_key,


input logic [7:0] get_data,
input logic [7:0] sign_reg
);

logic [79:0] key = 80'h00000000000000000000;
logic [79:0] IV  = 80'h00000000000000000000;

logic [287:0] s;

logic [7:0] t1,t2,t3,z; //trivium temporary regs

logic [7:0] sent [255]; 

logic [7:0] recieved [255];

logic [7:0] dechiphrated [255];

int log, session;

int k_num, data_num, read_num;

//initialise#############################################################################
function void trivium_init();
s[77:0] = key[79:2];
s[92:78] = 0;
s[172:93] = IV;
s[284:173] = 0;
s[287:285] = 3'b111;

for (int i = 0; i<288*4; i++)
begin
	t1[0] = s[65]^s[92]^s[90]&s[91]^s[170];
	t2[0] = s[161]^s[176]^s[174]&s[175]^s[263];
	t3[0] = s[242]^s[287]^s[285]&s[286]^s[68];
	
	s[92:0] = s[92:0] << 1;
	s[176:93] = s[176:93] << 1;
	s[287:177] = s[287:177] << 1;
	
	s[0] = t3[0];
	s[93] = t1[0];
	s[177] = t2[0];
end
endfunction;
//bytewise trivium#######################################################################
function logic [7:0] trivium_byte(logic [7:0] data);

for(int i = 0; i<8; i++)
begin
	t1[7-i] = s[65-i]^s[92-i];
	t2[7-i] = s[161-i]^s[176-i];
	t3[7-i] = s[242-i]^s[287-i];

	z[i] = t1[7-i]^t2[7-i]^t3[7-i];
end

for(int i = 0; i<8; i++)
begin
	t1[7-i] = t1[7-i]^s[90-i]&s[91-i]^s[170-i];
	t2[7-i] = t2[7-i]^s[174-i]&s[175-i]^s[263-i];
	t3[7-i] = t3[7-i]^s[285-i]&s[286-i]^s[68-i];
	
end

data=data^z;

s[92:0] = s[92:0] << 8;
s[176:93] = s[176:93] << 8;
s[287:177] = s[287:177] << 8;
	
s[7:0] = t3;
s[100:93] = t1;
s[184:177] = t2;

return data;
endfunction
//sending key##########################################################################
task sendkey();
@ (posedge clk)
#1 st_key = 1;
k_num = 0;
while (k_num < 80)
	begin
	@ (posedge clk)
	begin
		#1
		tr_key = key[79-k_num];
		k_num++;
	end
	end
st_key = 0;
endtask
//Sending data######################################################################
task senddata();
st_dat = 1;
data_num = 0;
while(data_num < 255)
begin @ (posedge clk)
	begin
	data = sent[data_num];
	data_num++;
	end
end
#1 st_dat = 0;
endtask
// Getting data from device###############################################################
task download();
@ (posedge clk)
#1 read = 1;
read_num = 0;
while(read_num < 255)
begin @ (posedge clk)
	begin
	#1 recieved[read_num] = get_data;
	read_num++;
	end
end
#1 read = 0;
endtask
//generate random data################################################################
function void produce();
for(int i = 0; i < 255; i++)
begin
	sent[i] = $urandom_range(0,255);
end
endfunction
//decipher and download################################################################
function int dec_and_comp();
int errcode;

for(int i = 0; i < 255; i++)
begin
	dechiphrated[i] = trivium_byte(recieved[i]);
end

for(int i = 0; i < 255; i++)
begin
	if(dechiphrated[i] !=sent[i])
	begin
		errcode = i;
		break;
	end
	else if (i == 254)
		errcode = 999;
end
return errcode;
endfunction

//write to file#######################################################################
function void result_file(string filename);
session = $fopen(filename, "w");
if(session == 0)
		$display("Unable to open file.");
$fwrite(session,"Ключ:\n");
$fwrite(session,"%h\n",key);
$fwrite(session,"\nОтправленные данные:\n");
for(int i = 0; i < 16; i++)
begin
	for(int j = 0; j < 16; j++)
	begin
	$fwrite(session,"%h ",sent[16*i+j]);
	end
	$fwrite(session,"\n");
end
$fwrite(session,"\nПринятые данные:\n");
for(int i = 0; i < 16; i++)
begin
	for(int j = 0; j < 16; j++)
	begin
	$fwrite(session,"%h ",recieved[16*i+j]);
	end
	$fwrite(session,"\n");
end
$fwrite(session,"\nРасшифрованные данные:\n");
for(int i = 0; i < 16; i++)
begin
	for(int j = 0; j < 16; j++)
	begin
	$fwrite(session,"%h ",dechiphrated[16*i+j]);
	end
	$fwrite(session,"\n");
end
$fclose(session);
endfunction

//write log###########################################################################
function void log_file(int result, string tcase,string refer);
log = $fopen("test_log.txt","a+");
if(log == 0)
		$display("Unable to open file.");
$fwrite(log,"%s:\n",tcase);
if(result != 999)
begin
	$fwrite (log,"Error at position %d of received data.\n", result);
	$fwrite (log,"See file \"%s\" for more.\n\n", refer);
end
else
begin
	$fwrite(log,"Device works properly.\n");
	$fwrite (log,"See file \"%s\" for more.\n\n", refer);
end
$fclose(log);
endfunction

//generate key######################################################################
function void prod_key();
key[31:0] = $urandom;
key[63:32] = $urandom;
key[79:64] = $urandom_range(0,16'hffff);
trivium_init();
endfunction


//#####################################################################
initial begin
rst = 1;
clk = 0;

fork
begin
#8 rst = 0;
st_key = 0;
st_dat = 0;
data = 0;
tr_key = 0;
read = 0;
#8 rst = 1;
end

forever begin
#8 clk=~clk;
end

forever begin
#100
case(sign_reg)
8'h04: begin
	$display("Error \n");
end

8'h08: begin
	$display("Total reset \n");
end
endcase
end
//Main testing block##########################################################
begin
#100
produce();
prod_key();
wait(sign_reg == 8'h00);
sendkey();
wait(sign_reg == 8'h01);
senddata();
wait(sign_reg == 8'h02);
download();
log_file(dec_and_comp(),"Normal work test","first.txt");
result_file("first.txt");

#100
produce();
prod_key();
sendkey();
wait(sign_reg == 8'h01);
senddata();
wait(sign_reg == 8'h02);
download();
log_file(dec_and_comp(),"One more normal work test","second.txt");
result_file("second.txt");

#100
produce();
prod_key();
sendkey();
wait(sign_reg == 8'h01);
senddata();
sendkey();
wait(sign_reg == 8'h02);
download();
log_file(dec_and_comp(),"Sending and key","third.txt");
result_file("third.txt");

#100
produce();
prod_key();
sendkey();
wait(sign_reg == 8'h01);
senddata();
wait(sign_reg == 8'h02);
sendkey();
download();
log_file(dec_and_comp(),"Download and key","4.txt");
result_file("4.txt");

#100
produce();
prod_key();
sendkey();
wait(sign_reg == 8'h01);
senddata();
sendkey();
wait(sign_reg == 8'h02);
download();
log_file(dec_and_comp(),"Sending and key forked","third_1.txt");
result_file("third_1.txt");

#100
produce();
prod_key();
sendkey();
wait(sign_reg == 8'h01);
senddata();
wait(sign_reg == 8'h02);
fork
	sendkey();
	download();
join
log_file(dec_and_comp(),"Download and key forked","4_1.txt");
result_file("4_1.txt");

#100
produce();
prod_key();
fork
	sendkey();
	senddata();
	download();
join
download();
log_file(dec_and_comp(),"All 3 operations at onece","5.txt");
result_file("5.txt");
end

join
end
endprogram