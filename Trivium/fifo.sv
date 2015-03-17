module fifo 
(	input logic clk,
	input logic rst,
	input logic [7:0] din,
	input logic read,
	input logic write,
	
	output logic [7:0] dout,
	output logic condition);

logic [5:0] tail; //�����
logic [5:0] head; //������
logic [5:0] count; //������� ���������

logic [35:0][7:0] fifomem; //������ ������

//Read from fifo
 always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		dout <= 0;
	else if (read == 1'b1 && condition != 5'b00000)
		dout <= fifomem[tail]; 
		
//assign dout = fifomem[tail];

// Update FIFO memory.
always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		fifomem <=0;
	else
		if(write == 1'b1 && condition != 5'b100100)
			fifomem [head][7:0] <= din [7:0];

// Update the head register.

always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		head <= 0;
	else 
		if (write == 1'b1 && condition != 5'b100100) 
// WRITE
			head <= head + 1;

// Update the tail register.

always_ff@(posedge clk, negedge rst) 
	if (!rst)
		tail <= 0;
	else 
		if (read == 1'b1 && condition != 5'b00000) 
// READ 
			tail <= tail + 1;

// Update the count register.

always_ff@(posedge clk, negedge rst) 
	if (!rst) 
		count <= 0;
	else 
		case ({read, write})
		2'b00: count <= count;
		2'b01: if (condition != 5'b100100) //WRITE 
				count <= count + 1;
		2'b10: if (condition != 5'b00000) //READ
				count <= count - 1;
		2'b11:count <= count; 
		endcase

always_comb
	if (count == 5'b00000) //FIFO IS EMPTY
		condition=0;
	else if (count ==5'b100100) //FIFO IS FULL
			condition=1;			

endmodule