module top
(	input logic CLK,
	input logic RST,
	input logic [7:0] DATA,
	input logic READ,
	input logic STB_DATA,
	input logic STB_KEY,
	
	output logic [7:0] DATA_OUT);
	
	wire [7:0] STREAM;
	wire WRITE;
Trivium ENCR_DEV
(	.clk(CLK),
	.rst(RST),
	.din(DATA),
	.strob_data(STB_DATA),
	.strob_key(STB_KEY),
	
	.stream(STREAM),
	.wt_sgn(WRITE));
fifo FIFO_DEV
(	.clk(CLK),
	.rst(RST),
	.din(STREAM),
	.read(READ),
	.write(WRITE),
	
	.dout(DATA_OUT));
endmodule