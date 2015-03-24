module fifo 
(	input logic clk,
	input logic rst,
	input logic [7:0] din,
	input logic read,
	input logic write,
	
	output logic [7:0] dout,
	output logic [1:0] condition);

logic [5:0] tail; //�����
logic [5:0] head; //������
logic [5:0] count; //������� ���������

logic [255:0][7:0] fifomem; //������ ������

//Read from fifo
 always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		dout <= 0;
	else if (read == 1'b1 && condition != 2'b00)
		dout <= fifomem[tail]; 
		
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

// Update the tail register.

always_ff@(posedge clk, negedge rst) 
	if (!rst)
		tail <= 0;
	else 
		if (read == 1'b1 && condition != 2'b00) 
// READ 
			tail <= tail + 1;

// Update the count register.

always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		count <= 0;
	else 
		case ({read, write})
		2'b00: count <= count;
		2'b01: if (condition != 2'b11) //WRITE 
				count <= count + 1;
		2'b10: if (condition != 2'b00) //READ
				count <= count - 1;
		2'b11:count <= count; 
		endcase

always_comb
	if (count == 5'b00000) //FIFO IS EMPTY
		condition=2'b00;
	else if (count ==5'b100100) //FIFO IS FULL
			condition=2'b11;			

endmodule