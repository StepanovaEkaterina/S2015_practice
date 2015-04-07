`timescale 1 ns / 1 ns

program ciph_test(
output logic clk,
output logic rst,
output logic [7:0] data,
output logic read,
output logic st_dat,
output logic st_key,

input logic [7:0] get_data
);

logic [0:79] key = 80'h00000000000000000000;
logic [0:79] IV  = 80'h00000000000000000000;

logic [0:287] s;

logic [0:7] t1,t2,t3,z; //bits
logic tb1, tb2, tb3, zb;//bytes

//initialise
function void trivium_init();
s[0:79] = key;
s[80:92] = 0;
s[93:172] = IV;
s[173:284] = 0;
s[285:287] = 3'b111;
for (int i = 0; i<1152; i++)
begin
	t1[0] = s[65]^s[90]&s[91]^s[92]^s[170];
	t2[0] = s[161]^s[174]&s[175]^s[176]^s[263];
	t3[0] = s[242]^s[285]&s[286]^s[287]^s[68];
		
	s[0:92] = s[0:92] >> 1;
	s[93:176] = s[93:176] >> 1;
	s[177:287] = s[177:287] >> 1;
	
	s[0] = t3[0];
	s[93] = t1[0];
	s[177] = t2[0];
end
endfunction;
//bytewise trivium
function logic [0:7] trivium_byte(logic [0:7] data);

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

s[0:92] = s[0:92] >> 8;
s[93:176] = s[93:176] >> 8;
s[177:287] = s[177:287] >> 8;
	
s[0:7] = t3;
s[93:100] = t1;
s[177:184] = t2;

return data;
endfunction
// Bitwise trivium
function logic trivium_bit(logic data);
tb1 = s[65]^s[92];
tb2 = s[161]^s[176];
tb3 = s[242]^s[287];

zb = tb1^tb2^tb3;

tb1 = tb1^s[90]&s[91]^s[170];
tb2 = tb2^s[174]&s[175]^s[263];
tb3 = tb3^s[285]&s[286]^s[68];

s[0:92] = s[0:92] >> 1;
s[93:176] = s[93:176] >> 1;
s[177:287] = s[177:287] >> 1;
	
s[0] = tb3;
s[93] = tb1;
s[177] = tb2;

data=data^zb;

return data;
endfunction
//###########################################################
initial begin
rst = 1;
clk = 0;
trivium_init();
	fork
	
	begin
	#8 rst = 1;
	#8 rst = 0;
	end
	
	forever begin
	#8 clk=~clk;
	end
	
	join
end
endprogram