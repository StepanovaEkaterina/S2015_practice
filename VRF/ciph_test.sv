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

//logic [79:0] key = 80'hd8ad98aa04d01b630bb4;
logic [79:0] key = 80'h00000000000000000000;
logic [79:0] IV  = 80'h00000000000000000000;

logic [287:0] s;

logic [7:0] t1,t2,t3,z; //trivium temporary regs

logic [7:0] zerobytes [256]; 
logic [7:0] zerobits [256];

logic [7:0] recieved [256];

int k_num;

//initialise
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
//bytewise trivium
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
// Bitwise trivium
function logic trivium_bit(logic data);
t1[0] = s[65]^s[92];
t2[0] = s[161]^s[176];
t3[0] = s[242]^s[287];

z[0] = t1[0]^t2[0]^t3[0];

t1[0] = t1[0]^s[90]&s[91]^s[170];
t2[0] = t2[0]^s[174]&s[175]^s[263];
t3[0] = t3[0]^s[285]&s[286]^s[68];


s[92:0] = s[92:0] << 1;
s[176:93] = s[176:93] << 1;
s[287:177] = s[287:177] << 1;
	
s[0] = t3[0];
s[93] = t1[0];
s[177] = t2[0];

data=data^z[0];

return data;
endfunction
//#####################################################################
initial begin
rst = 1;
clk = 0;
trivium_init();

for(int i = 0; i < 256; i++)
begin
	zerobytes[i] = trivium_byte(0);
end

trivium_init();

for(int i = 0; i < 256; i++)
begin
	for(int j = 0; j < 8; j++)
		zerobits[i][j] = trivium_bit(0);
end
trivium_init();
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
		8'h00: begin
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
		end
		
		8'h04: begin
			@ (posedge clk)
			#1 st_dat = 1;
			@ (posedge clk)
				data = 0;
			#1 st_dat = 0;
		end
		8'h10: begin
			@ (posedge clk)
			#1 read = 1;
			k_num = 0; //Using k_num again, don't need another variable.
			while(k_num < 256)
			begin @ (posedge clk)
					begin
					#1 recieved[k_num] = get_data;
					k_num++;
					end
			end
			#1 read = 0;
			
			for(int i = 0; i < 256; i++)
			begin
				if(zerobits[i] !=recieved[i])
				begin
					$display("Error at %d position of received data!",i);
					break;
				end
			end
			
		end
		8'h20: begin
			$display("Generate and send new key \n");
		end
		default: $display(sign_reg);
		endcase
	end
	
	join
end
endprogram