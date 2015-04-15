//описать состояние ошибки при неполном/переполненом ключе 
module Trivium
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

	logic [92:0] 			reg_str_1;
	logic [83:0] 			reg_str_2;
	logic [110:0] 			reg_str_3; 
	logic [79:0] 			vector=80'h00000000000000000000; //Вектор инициализации
	logic [7:0] 			z, t_1, t_2, t_3;
			
	logic [11:0] 			cnt_init;//Счетчик инициализации
	logic [63:0] 			err_cnt; //2^64
	logic [6:0] 			key_cnt;  //Счетчик элементов ключа
	logic [8:0] 			encry_cnt; //Счетчик зашифрованных данных
			
	logic [7:0] 			data_reg; //Регистр входных данных
	logic [79:0] 			key_reg; //Регистр ключа шифрования
		
	enum logic [5:0] {NoKey, GetKey, KeyOK, Init, Wait_Data, Moving_Secret, Secret_Ready, Error, Total_RST} nxt, prev;

always_ff@(posedge clk, negedge rst)
begin
	if (!rst)
		prev<=NoKey;
	else
		prev<=nxt;
end
always_ff@(posedge clk, negedge rst)
begin
	if (!rst)
		sign_reg<=8'b00000000;
	else
	begin
		unique case (prev)
		NoKey:
			sign_reg<=8'b00000000;
		GetKey:
			sign_reg<=8'b00000000;
		KeyOK:
			sign_reg<=8'b00000001;
		Init:
			sign_reg<=8'b00000010;
		Wait_Data:
			sign_reg<=8'b00000100;
		Moving_Secret:
			sign_reg<=8'b00001000;
		Secret_Ready:
			sign_reg<=8'b00010000;
		Error:
			sign_reg<=8'b00100000;
		Total_RST:
			sign_reg<=8'b01000000;
		default:
		    sign_reg<=8'b00000000;
		endcase
	end
end

always_comb
begin
	unique case (prev)
	NoKey:
	begin
		if (strob_key)
			nxt=GetKey;
		else
		begin
			if (strob_data)
				nxt=Total_RST;
			else
			  nxt=NoKey;
		end
	end
	GetKey:
	begin
		if (!strob_key)
			nxt=KeyOK;
		else 
			nxt=GetKey;
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
		else
			if (encry_cnt==8'b11111111)
				nxt=Secret_Ready;
			else
				nxt=Moving_Secret;
	end
	Secret_Ready:
	begin
		if (fifo_cnd==2'b00)
			nxt=Wait_Data;
		else
			nxt=Secret_Ready;
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
  if (!rst)
  begin
	stream<=0;
	wt_sgn<=0;
	reg_str_1<=0;
	reg_str_2<=0;
	reg_str_3<=0;
	cnt_init<=0;
	err_cnt<=0;
	key_cnt<=0;
	encry_cnt<=0;
	data_reg<=0;
	key_reg<=0;
  end
  else
  begin
	wt_sgn<=0;
	unique case(prev)
	NoKey:
		key_reg<={key_reg[78:0],key};
	GetKey:
	begin
		if (key_cnt<1010000)
		begin
			key_reg<={key_reg[78:0],key};
			key_cnt<=key_cnt+1;
		end
		else
		begin
			key_reg<=key_reg;
			key_cnt<=key_cnt;
		end
	end
	KeyOK:
	begin
		reg_str_1[76:0]<=key_reg[79:3];
		reg_str_2[79:0]<=vector;
		reg_str_3[79:77]<=3'b111;
	end
	Wait_Data:
		data_reg<=data;
	Init:
	begin
		reg_str_1<={reg_str_1[91:0],reg_str_3[65]^reg_str_3[110]^reg_str_3[108]&reg_str_3[109]^reg_str_1[68]};
		reg_str_2<={reg_str_2[82:0],reg_str_1[65]^reg_str_1[92]^reg_str_1[90]&reg_str_1[91]^reg_str_2[78]};
		reg_str_3<={reg_str_3[109:0],reg_str_2[68]^reg_str_2[83]^reg_str_2[81]&reg_str_2[82]^reg_str_3[86]};
		cnt_init<=cnt_init+1;
	end
	Moving_Secret:
	begin
		reg_str_1<={reg_str_1[84:0],t_1};
		reg_str_2<={reg_str_2[75:0],t_2};
		reg_str_3<={reg_str_3[102:0],t_3};
		stream<=data_reg^z;
		wt_sgn<=1;
		err_cnt<=err_cnt+1;
		encry_cnt<=encry_cnt+1;
	end
	Total_RST:
	begin
		reg_str_1<=0;
		reg_str_2<=0;
		reg_str_3<=0;
		data_reg<=0;
		stream<=0;
		cnt_init<=0;
		err_cnt<=0;
		encry_cnt<=0;
	end
	default:
	begin
		stream<=stream;
		wt_sgn<=wt_sgn;
		reg_str_1<=reg_str_1;
		reg_str_2<=reg_str_2;
		reg_str_3<=reg_str_3;
		cnt_init<=cnt_init;
		err_cnt<=err_cnt;
		key_cnt<=key_cnt;
		encry_cnt<=encry_cnt;
		data_reg<=data_reg;
		key_reg<=key_reg;
	end
  endcase
  end
end

always_comb
begin
  for(int i=0;i<8;i++)
    begin
      z[i]=reg_str_1[65-i]^reg_str_1[92-i]^reg_str_2[68-i]^reg_str_2[83-i]^reg_str_3[65-i]^reg_str_3[110-i];
      t_1[i]=reg_str_1[65-i]^reg_str_1[92-i]^reg_str_1[90-i]&reg_str_1[91-i]^reg_str_2[78-i];
      t_2[i]=reg_str_2[68-i]^reg_str_2[83-i]^reg_str_2[81-i]&reg_str_2[82-i]^reg_str_3[86-i];
      t_3[i]=reg_str_3[65-i]^reg_str_3[110-i]^reg_str_3[108-i]&reg_str_3[109-i]^reg_str_1[68-i];
    end
end

endmodule	

