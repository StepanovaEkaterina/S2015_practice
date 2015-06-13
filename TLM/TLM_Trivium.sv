`timescale 1 ns / 1 ns

program TLM_trivium
(	input logic 			clk,
	input logic 			rst,
	input logic 			key,
	input logic 			[7:0] data,
	input logic 			strob_data,
	input logic 			strob_key,
	input logic 			[1:0] fifo_cnd,
	
	output logic 			[7:0] stream,
	output logic 			wt_sgn,
	output logic 			[7:0] sign_reg);
	
logic [287:0] s;
	
logic [79:0] key_reg;
logic [79:0] IV  = 80'hc686715b56d470466509;

logic [7:0] t1,t2,t3,z; //trivium temporary regs

int cnt_init;
logic [63:0] err_cnt;
int key_cnt;
int encry_cnt;

logic [7:0] 			data_reg;
logic					strob_data_tmp;
enum logic [5:0] {NoKey, GetKey, KeyOK, Init, Moving_Secret, Secret_Ready, Error, Error_Key, Total_RST} nxt, prev;

initial begin

fork

forever begin
@(posedge clk, negedge rst)
begin
	if (!rst)
	begin
		prev=NoKey;
		strob_data_tmp=0;
		data_reg=0;
		sign_reg=8'b00000000;
		key_cnt=0;
		key_reg=0;
		
		stream=0;
		wt_sgn=0;
		s=s;
		cnt_init=0;
		err_cnt=0;
		encry_cnt=0;
		t1 = 0;
		t2 = 0;
		t3 = 0;
		z = 0;
	end
	else 
		prev=nxt;
end
end

forever begin
@(posedge clk, negedge rst)
begin
	if (rst)
	begin
		strob_data_tmp=strob_data;
		data_reg=data;
	end
end
end

forever begin
@(posedge clk, negedge rst)
begin
	if (rst)
	begin
		unique case (prev)
		NoKey:
			sign_reg<=8'b00000000;
		GetKey:
			sign_reg<=8'b00000000;
		Moving_Secret:
			sign_reg<=8'b00000001;
		Secret_Ready:
			sign_reg<=8'b00000010;
		Error:
			sign_reg<=8'b00000100;
		Error_Key:
			sign_reg<=8'b00001000;
		Total_RST:
			sign_reg<=8'b00010000;
		default:
		    sign_reg<=8'b00000000;
		endcase
	end
end
end

forever begin
@(posedge clk, negedge rst)
unique case (prev)
	NoKey:
	begin
		if (strob_key)
			nxt=GetKey;
		else
			nxt=NoKey;
	end
	GetKey:
	begin
		if (key_cnt<7'b1001111)
			if (strob_key)
				nxt=GetKey;
			else
				nxt=Error_Key;
		else if (strob_key)
				nxt=Error_Key;
			else
				nxt=KeyOK;
	end
	KeyOK:
	begin
		if (strob_key)
			nxt=Error_Key;
		else
			nxt=Init;
	end
	Init:
	begin
		if (cnt_init<11'b10001111111)
			nxt=Init;
		else
			nxt=Moving_Secret;
	end
	Moving_Secret:
	begin
		if (strob_key)
			nxt=GetKey;
		else if (err_cnt>=2**64-1)
				nxt=Error;
			else if (encry_cnt == 8'b11111111)
					nxt=Secret_Ready;
				else
					nxt=Moving_Secret;
	end
	Secret_Ready:
	begin
		if (fifo_cnd==2'b00)
			nxt=Moving_Secret;
		else
			nxt=Secret_Ready;
	end
	Error:
	begin
		if (strob_data)
			nxt=Total_RST;
		else if (strob_key)
				nxt=GetKey;
			else
				nxt=Error;
	end
	Error_Key:
		nxt=NoKey;
	Total_RST:
		nxt=NoKey;
	default:
		nxt=NoKey;
	endcase
end

forever begin
@(posedge clk, negedge rst)
begin
	if(rst)
		unique case(prev)
		NoKey:
			key_reg={key_reg[78:0],key};
		GetKey:
		begin
			if (key_cnt<7'b1010000)
			begin
				key_reg={key_reg[78:0],key};
				key_cnt=key_cnt+1;
			end
		else
			begin
				key_reg=key_reg;
				key_cnt=key_cnt;
			end
		end
		KeyOK:
		begin
			key_cnt=0;
			if (strob_key)
				key_reg<={key_reg[78:0],key};
		end
		Moving_Secret:
		begin
			if (strob_key)
				key_reg={key_reg[78:0],key};
		end
		Error:
		begin
			if (strob_key)
				key_reg={key_reg[78:0],key};
		end
		Error_Key:
		begin
			key_cnt=0;
			key_reg=0;
		end
		Total_RST:
		begin
			key_cnt=0;
			key_reg=0;
		end
		default:
		begin
			key_cnt=key_cnt;
			key_reg=key_reg;
		end
		endcase
end
end

forever begin
@(posedge clk, negedge rst)
begin
  if (rst)
  begin
	wt_sgn=0;
	unique case(prev)
	GetKey:
	begin
		s=0;
	end
	KeyOK:
	begin
	s[77:0] = key_reg[79:2];
	s[92:78] = 0;
	s[172:93] = IV;
	s[284:173] = 0;
	s[287:285] = 3'b111;
	end
	Init:
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
		cnt_init++;
	end
	Moving_Secret:
	begin
	cnt_init<=0;
		if (strob_data_tmp)
		begin
			for(int i = 0; i<8; i++)
			begin
				t1[7-i] = s[65-i]^s[92-i];
				t2[7-i] = s[161-i]^s[176-i];
				t3[7-i] = s[242-i]^s[287-i];
			
				z[i] = t1[7-i]^t2[7-i]^t3[7-i];
			end
			stream=data_reg^z;
			wt_sgn=1;
			err_cnt++;
			encry_cnt++;
			for(int i = 0; i<8; i++)
			begin
				t1[7-i] = t1[7-i]^s[90-i]&s[91-i]^s[170-i];
				t2[7-i] = t2[7-i]^s[174-i]&s[175-i]^s[263-i];
				t3[7-i] = t3[7-i]^s[285-i]&s[286-i]^s[68-i];
			end
			s[92:0] = s[92:0] << 8;
			s[176:93] = s[176:93] << 8;
			s[287:177] = s[287:177] << 8;
				
			s[7:0] = t3;
			s[100:93] = t1;
			s[184:177] = t2;
		end
		else
		begin
			wt_sgn=0;
			stream=0;
		end
	end
	Secret_Ready:
	begin
		encry_cnt=0;
		stream=0;
	end
	Total_RST:
	begin
		s=0;
		stream=0;
		cnt_init=0;
		err_cnt=0;
		encry_cnt=0;
	end
	default:
	begin
		stream=stream;
		wt_sgn=wt_sgn;
		s=s;
		cnt_init=cnt_init;
		err_cnt=err_cnt;
		encry_cnt=encry_cnt;
	end
  endcase
  end
end
end

join

end

endprogram