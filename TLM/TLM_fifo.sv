`timescale 1 ns / 1 ns

program TLM_fifo
(
input logic clk,
input logic rst,
input logic [7:0] din,
input logic read,
input logic write,

output logic [7:0] dout,
output logic [1:0] condition,
output logic read_stb
);

logic [7:0] tail;
logic [7:0] head;
logic [7:0] count;

logic [255:0][7:0] fifomem;

initial begin

fork
	forever begin
	@(posedge clk, negedge rst)
	if (!rst)
	begin
		dout = 0;
		read_stb = 0;
	end
	else if (read == 1'b1 && condition != 2'b00)
	begin
		dout = fifomem[tail];
		read_stb = 1;
	end
		else
		read_stb = 0;	
	end
	
	forever begin
	@(posedge clk, negedge rst) 
	if (!rst) 
		fifomem =0;
	else
		if(write == 1'b1 && condition != 2'b11)
			fifomem [head][7:0] = din [7:0];
	end
	
	forever begin
	@(posedge clk, negedge rst) 
	if (!rst) 
		head = 0;
	else 
		if (write == 1'b1 && condition != 2'b11) 
			head++;
		else if (condition == 2'b00)
			head = 0;
	end
	
	forever begin
	@(posedge clk, negedge rst) 
	if (!rst)
		tail = 0;
	else 
		if (read == 1'b1 && condition != 2'b00)  
			tail++;
		else if (condition == 2'b00)
			tail = 0;
	end
	
	forever begin
	@(posedge clk, negedge rst) 
	if (!rst) 
		count = 0;
	else 
		case ({read_stb, write})
		2'b00: count = count;
		2'b01: if (condition != 2'b11)
				count++;
		2'b10: if (condition != 2'b00)
				count--;
		2'b11:count = count; 
		endcase
	end
	
	forever begin
	#1
	if (count == 8'b00000000)
		condition=2'b00;
	else if (count ==8'b11111111)
			condition=2'b11;
		else
			condition=2'b10;
	end
join

end

endprogram