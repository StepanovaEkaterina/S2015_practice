Как получется ключ?

module Trivium
(	input logic clk,
	input logic rst,
	input logic [79:0] key,
//	input logic [1:0] buff_cond,
	input logic data,
	input logic strop_data,
	input logic strop_key,
	
	output logic stream);

logic [92:0] reg_str_1;
logic [83:0] reg_str_2;
logic [110:0] reg_str_3; 
logic [79:0] vector; //Вектор инициализации
logic [11:0] count_init;//Счетчик инициализации
logic [64:0] err_cnt;//2^64
logic [1:0] data_reg;
 

enum [8:0] {NoKey, KeyOK, Init, Wait_Data, Moving_Secret, Secret_Ready, Error, Total_RST} nxt, prev;

always_comb
begin
	unique case (prev)
	NoKey:
	begin
		if (key)
			nxt=KeyOK;
		else
			nxt=NoKey;
		if (data)
			nxt=Total_RST;
	end
	KeyOK:
		nxt=Init;
	Init:
	begin
		if (count_init<11'b10010000000)
			nxt=Init;
		else
			nxt=Wait_Data;
	end
	Wait_Data:
	begin
		if (strop_data)
		begin
			nxt=Moving_Secret;
			data_reg[0]=data;
		end
		else
			nxt=Wait_Data;
	end
	Moving_Secret:
	begin
		if (err_cnt)
			nxt=NoKey;
		else if (!strop_data)
				nxt=Wait_Data;
	end
	Secret_Ready:
	begin
		nxt=Wait_Data;
		if (strop_data)
			nxt=Error;
	end
	Error:
		nxt=NoKey;
	Total_RST:
		nxt=NoKey;
	default:
		nxt=NoKey;
	endcase
end	

always_ff@(posedge clk, negedge rst)
begin
	unique case(prev)
	Init:
	begin
		reg_str_1<={reg_str_1[91:0],reg_str_3[65]^reg_str_3[110]^reg_str_3[108]&reg_str_3[109]^reg_str_1[68]};
		reg_str_2<={reg_str_2[82:0],reg_str_1[65]^reg_str_1[92]^reg_str_1[90]&reg_str_1[91]^reg_str_2[78]};
		reg_str_3<={reg_str_1[109:0],reg_str_2[68]^reg_str_2[83]^reg_str_2[81]&reg_str_2[82]^reg_str_3[86]};
		count_init<=count_init+1;
	end
	Moving_Secret:
	begin
		stream<=data_reg[1]^reg_str_1[65]^reg_str_1[92]^reg_str_2[68]^reg_str_2[83]^reg_str_3[65]^reg_str_3[110];
		
		reg_str_1<={reg_str_1[91:0],reg_str_3[65]^reg_str_3[110]^reg_str_3[108]&reg_str_3[109]^reg_str_1[68]};
		reg_str_2<={reg_str_2[82:0],reg_str_1[65]^reg_str_1[92]^reg_str_1[90]&reg_str_1[91]^reg_str_2[78]};
		reg_str_3<={reg_str_1[109:0],reg_str_2[68]^reg_str_2[83]^reg_str_2[81]&reg_str_2[82]^reg_str_3[86]};
		
		data_reg<=data_reg<<1;
		err_cnt<=err_cnt+1;
	end
	Total_RST:
	begin
		reg_str_1<=0;
		reg_str_2<=0;
		reg_str_3<=0;
		data_reg<=0;
		stream<=0;
		count_init<=0;
		err_cnt<=0;
	end
end

endmodule	