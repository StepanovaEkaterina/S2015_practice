module fifo 
(	input logic clk,
	input logic rst,
	input logic [7:0] din,
	input logic read,
	input logic write,
	
	output logic [7:0] dout,
	output logic [1:0] condition,
	output logic read_stb);

logic [7:0] tail; //�����
logic [7:0] head; //������
logic [7:0] count; //������� ���������

logic [255:0][7:0] fifomem; //������ ������

//Read from fifo
 always_ff@(posedge clk, negedge rst) 
	if (!rst)
	begin 
		dout <= 0;
		read_stb <= 0;
	end
	else if (read == 1'b1 && condition != 2'b00)
	begin
		dout <= fifomem[tail];
		read_stb<=1;
	end
		else
		read_stb<=0;	
//assign dout = fifomem[tail];

// Update FIFO memory.
always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		fifomem <=0;
	else
		if(write == 1'b1 && condition != 2'b11)
			fifomem [head][7:0] <= din [7:0];

// Update the head register.

always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		head <= 0;
	else 
		if (write == 1'b1 && condition != 2'b11) 
// WRITE
			head <= head + 1;
		else if (condition == 2'b00)
			head <= 0;

// Update the tail register.

always_ff@(posedge clk, negedge rst) 
	if (!rst)
		tail <= 0;
	else 
		if (read == 1'b1 && condition != 2'b00) 
// READ 
			tail <= tail + 1;
		else if (condition == 2'b00)
			tail <= 0;

// Update the count register.

always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		count <= 0;
	else 
		case ({read_stb, write})
		2'b00: count <= count;
		2'b01: if (condition != 2'b11) //WRITE 
				count <= count + 1;
		2'b10: if (condition != 2'b00) //READ
				count <= count - 1;
		2'b11:count <= count; 
		endcase

always_comb
	if (count == 8'b00000000) //FIFO IS EMPTY
		condition=2'b00;
	else if (count ==8'b11111111) //FIFO IS FULL
			condition=2'b11;
		else
			condition=2'b10;

endmodule