module Trivium
(	input logic clk,
	input logic rst,
	input logic key,
	input logic [7:0] data,
	input logic strob_data,
	input logic strob_key,
	
	output logic [7:0] stream,
	output logic wt_sgn,
	output logic [7:0] sign_reg);

logic [92:0] reg_str_1;
logic [83:0] reg_str_2;
logic [110:0] reg_str_3; 
logic [79:0] vector=80'h00000000000000000000; //Вектор инициализации
logic [7:0] z, t_1, t_2, t_3;

logic [11:0] cnt_init;//Счетчик инициализации
logic [63:0] err_cnt; //2^64
logic [6:0] key_cnt;  //Счетчик элементов ключа

logic [7:0] data_reg; //Регистр входных данных
logic [79:0] key_reg; //Регистр ключа шифрования
 

enum {NoKey, GetKey, KeyOK, Init, Wait_Data, Moving_Secret, Secret_Ready, Error, Total_RST} nxt, prev;

always_comb
begin
	unique case (prev)
	NoKey:
	begin
		if (strob_key)
			nxt=GetKey;
		else
		begin
			nxt=NoKey;
			if (data)
				nxt=Total_RST;
			if (strob_data)
				nxt=Total_RST;
		end
	end
	GetKey:
	begin
		if (key_cnt<1010000)
			nxt=GetKey;
		else
			nxt=KeyOK;
	end
	KeyOK:
		nxt=Init;
	Init:
	begin
		if (cnt_init<11'b10010000000)
			nxt=Init;
		else
			nxt=Wait_Data;
	end
	Wait_Data:
	begin
		if (strob_data)
			nxt=Moving_Secret;
		else
			nxt=Wait_Data;
	end
	Moving_Secret:
	begin
		if (err_cnt)
			nxt=NoKey;
	end
	Secret_Ready:
	begin
		nxt=Wait_Data;
		if (strob_data)
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

