program main_test();

integer in_file, out_file;
string line;

initial begin
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
end
endprogram