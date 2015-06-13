module top
(	input logic CLK,
	input logic RST,
	input logic KEY,
	input logic [7:0] DATA,
	input logic READ,
	input logic STB_DATA,
	input logic STB_KEY,
	
	output logic [7:0] DATA_OUT,
	output logic [7:0] SIGN_REG,
	output logic STB_READ);
	
	wire [7:0] STREAM;
	wire WRITE;
	wire [1:0] CONDITION;
	
//Trivium ENCR_DEV
TLM_trivium ENCR_DEV
(	.clk(CLK),
	.rst(RST),
	.key(KEY),
	.data(DATA),
	.strob_data(STB_DATA),
	.strob_key(STB_KEY),
	.fifo_cnd (CONDITION),
	
	.stream(STREAM),
	.wt_sgn(WRITE),
	.sign_reg(SIGN_REG));
	
//fifo FIFO_DEV
TLM_fifo FIFO_DEV
(	.clk(CLK),
	.rst(RST),
	.din(STREAM),
	.read(READ),
	.write(WRITE),
	
	.dout(DATA_OUT),
	.condition(CONDITION),
	.read_stb(STB_READ));
endmodule