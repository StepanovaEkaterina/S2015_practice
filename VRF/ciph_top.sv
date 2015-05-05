module ciph_top();

logic clk,rst;
logic key;
logic [7:0] data;
logic read,st_dat,st_key,st_read;

logic [7:0] g_dat, sign_reg;

top TRIVIUM (
	.CLK(clk),
	.RST(rst),
	.KEY(key),
	.DATA(data),
	.READ(read),
	.STB_DATA(st_dat),
	.STB_KEY(st_key),
	
	.DATA_OUT(g_dat),
	.SIGN_REG(sign_reg),
	.STB_READ(st_read)
);

ciph_test TRV_TST (
	.clk(clk),
	.rst(rst),
	.tr_key(key),
	.data(data),
	.read(read),
	.st_dat(st_dat),
	.st_key(st_key),

	.get_data(g_dat),
	.sign_reg(sign_reg),
	.in_strobe(st_read)
);

endmodule