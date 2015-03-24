module Trivium
(	input logic clk,
	input logic rst,
	input logic [79:0] key,
	input logic buff_cond,
	input logic data,
	
	output logic stream);

logic [92:0] reg_str_1;
logic [83:0] reg_str_2;
logic [110:0] reg_str_3; 
logic [79:0] vector; //Вектор инициализации
logic [11:0] count_init;//Счетчик инициализации
logic [64:0] err_cnt;//2^64
logic t_1, t_2, t_3, z;

enum [8:0] {NoKey, KeyOK, Init, Wait_Data, Moving_Secret, Secret_Ready, Error, Total_RST} nxt, prev;
//Это ни разу не рабочий код. Нужны флаги.
/*always_ff@(posedge clk, negedge rst)
	if (!rst)
		stream<=0;
	else if (count<=11'b10010000000)
	begin
		t_1<=reg_str_1[65]^reg_str_1[92];
		t_2<=reg_str_2[68]^reg_str_2[83];
		t_3<=reg_str_3[65]^reg_str_3[110];
		
		z<=t_1^t_2^t_3;
		
		t_1<=t_1^reg_str_1[90]&reg_str_1[91]^reg_str_2[78];
		t_2<=t_2^reg_str_2[81]&reg_str_2[82]^reg_str_3[86];
		t_3<=t_3^reg_str_3[108]&reg_str_3[109]^reg_str_1[68];
		
		reg_str_1<=reg_str_1<<1;
		reg_str_1[0]<=t_3;
		reg_str_2<=reg_str_2<<1;
		reg_str_2[0]<=t_1;
		reg_str_3<=reg_str_3<<1;
		reg_str_3[0]<=t_2;
	end*/
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
	Wait_Data:
	begin
		if (data)
			nxt=Moving_Secret;
		else
			nxt=Wait_Data;
	end
	Moving_Secret:
	begin
	//Исправить
		if (err_cnt)
			nxt=NoKey;
		if ()
	end
	Secret_Ready:
	begin
		nxt=Wait_Data;
		//Исправить
		if (data)
			nxt=FIFO_Full;
	end
	Error:
		nxt=NoKey;
	Total_RST:
		nxt=NoKey;
	endcase
end	

always_ff@(posedge clk, negedge rst)
begin
	unique case(prev)
	Init:
	begin
		if (count_init<=11'b10010000000)
		begin	
			t_1<=reg_str_1[65]^reg_str_1[92]^reg_str_1[90]&reg_str_1[91]^reg_str_2[78];
			t_2<=reg_str_2[68]^reg_str_2[83]^reg_str_2[81]&reg_str_2[82]^reg_str_3[86];
			t_3<=reg_str_3[65]^reg_str_3[110]^reg_str_3[108]&reg_str_3[109]^reg_str_1[68];
		
			reg_str_1<=reg_str_1<<1;
			reg_str_1[0]<=t_3;
			reg_str_2<=reg_str_2<<1;
			reg_str_2[0]<=t_1;
			reg_str_3<=reg_str_3<<1;
			reg_str_3[0]<=t_2;
		end
	end
end

endmodule
//Нужен флаг конец данных.		