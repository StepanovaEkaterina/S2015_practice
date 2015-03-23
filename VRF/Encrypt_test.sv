program main_test();

integer in_file, out_file;
string line;

logic [0:79] key = 80'hd8ad98aa04d01b630bb4;
logic [0:79] IV = 80'h3045eefcf5307b776266;
logic [0:92] stream_1;
logic [0:83] stream_2;
logic [0:110] stream_3;

logic t_1, t_2, t_3;

function void trivium_id();

stream_1[0:79] = key;
stream_1[80:92] = 0;
stream_2[0:79] = IV;
stream_2[80:83] = 0;
stream_3[0:107] = 0;
stream_3[108:110] = 3'b111;

for (int i = 0; i < 1152; i++)
	begin
		t_1 = stream_1[65]^stream_1[90]&stream_1[91]^stream_1[92]^stream_2[77];
		t_2 = stream_2[68]^stream_2[81]&stream_2[82]^stream_2[83]^stream_3[86];
		t_3 = stream_3[65]^stream_3[108]&stream_3[109]^stream_3[110]^stream_1[68];
		
		stream_1 = stream_1 >> 1;
		stream_2 = stream_2 >> 1;
		stream_3 = stream_3 >> 1;
		
		stream_1[0] = t_3;
		stream_2[0] = t_1;
		stream_3[0] = t_2;
 	end

endfunction;

initial begin
/*
	in_file = $fopen("cookie.txt","r");
	if(in_file == 0) begin
		$display("Unable to open file.");
	end
	
	out_file = $fopen("lol.txt");
	if(out_file == 0) begin
		$display("Unable to open file.");
	end
	
	while(!$feof(in_file)) begin
		if($fgets(line,in_file)) begin
			$fdisplay(out_file, line);
		end
	end
	
	$fclose(in_file);
	$fclose(out_file);
	*/
	trivium_id();
	$display(stream_1);
end
endprogram