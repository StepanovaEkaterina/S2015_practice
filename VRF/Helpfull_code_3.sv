program cipher_test();

logic [0:79] key = 80'h00000000000000000000;
logic [0:79] IV  = 80'h00000000000000000000;

logic [0:287] s;
logic z;

logic [0:7] allbit [256];

logic t1,t2,t3;

function void trivium_init();
s[0:79] = key;
s[80:92] = 0;
s[93:172] = IV;
s[173:284] = 0;
s[285:287] = 3'b111;
for (int i = 0; i<1152; i++)
begin
	t1 = s[65]^s[90]&s[91]^s[92]^s[170];
	t2 = s[161]^s[174]&s[175]^s[176]^s[263];
	t3 = s[242]^s[285]&s[286]^s[287]^s[68];
		
	s[0:92] = s[0:92] >> 1;
	s[93:176] = s[93:176] >> 1;
	s[177:287] = s[177:287] >> 1;
	
	s[0] = t3;
	s[93] = t1;
	s[177] = t2;
end
endfunction;

function logic trivium_bit(logic data);
t1 = s[65]^s[92];
t2 = s[161]^s[176];
t3 = s[242]^s[287];

z = t1^t2^t3;

t1 = t1^s[90]&s[91]^s[170];
t2 = t2^s[174]&s[175]^s[263];
t3 = t3^s[285]&s[286]^s[68];

s[0:92] = s[0:92] >> 1;
s[93:176] = s[93:176] >> 1;
s[177:287] = s[177:287] >> 1;
	
s[0] = t3;
s[93] = t1;
s[177] = t2;

data=data^z;
return z; //FIX ME!
endfunction

initial begin
trivium_init();
for(int i = 0; i<256; i++)
begin
	for(int j = 0; j<8; j++)
	begin
		allbit[i][j] = trivium_bit(0);
	end
end

end
endprogram