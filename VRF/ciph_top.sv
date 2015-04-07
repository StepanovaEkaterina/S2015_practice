module ciph_top();

logic clk,rst;
logic key;
logic [0:7] data;
logic read,st_dat,st_key;

logic [0:7] g_dat;

top TRIVIUM (
	.CLK(clk),
	.RST(rst),
	.KEY(key),
	.DATA(data),
	.READ(read),
	.STB_DATA(st_dat),
	.STB_KEY(st_key),
	
	.DATA_OUT(g_dat)
);

ciph_test TRV_TST (
	.clk(clk),
	.rst(rst),
	.tr_key(key),
	.data(data),
	.read(read),
	.st_dat(st_dat),
	.st_key(st_key),

	.get_data(g_dat)
);

endmodule