program main_test();

integer in_file, out_file, control_file;

//logic [0:79] key = 80'hd8ad98aa04d01b630bb4; //very random key
//logic [0:79] IV =  80'h3045eefcf5307b776266;  //very random IV
logic [0:79] key =	 80'h00000000000000000000;
logic [0:79] IV =  	 80'h00000000000000000000;
logic [0:92] s_1; //shifting part (key)
logic [0:83] s_2; //shifting part (IV)
logic [0:110] s_3;//shifting part (0's)

logic [0:7] total_bits [128];

logic [0:7] middle_string;

logic t_1, t_2, t_3; //temporary registers
logic [0:7] t1,t2,t3,zo;
logic z; //cipher reg

function void trivium_id(); //initialisation

s_1[0:79] = key;
s_1[80:92] = 0;
s_2[0:79] = IV;
s_2[80:83] = 0;
s_3[0:107] = 0;
s_3[108:110] = 3'b111;

for (int i = 0; i < 1152; i++)
begin
	t_1 = s_1[65]^s_1[90]&s_1[91]^s_1[92]^s_2[77];
	t_2 = s_2[68]^s_2[81]&s_2[82]^s_2[83]^s_3[86];
	t_3 = s_3[65]^s_3[108]&s_3[109]^s_3[110]^s_1[68];
		
	s_1 = s_1 >> 1;
	s_2 = s_2 >> 1;
	s_3 = s_3 >> 1;
	
	s_1[0] = t_3;
	s_2[0] = t_1;
	s_3[0] = t_2;
 end
endfunction;

function logic trivium_c(logic enc);
begin
	t_1 = s_1[65]^s_1[92];
	t_2 = s_2[68]^s_2[83];
	t_3 = s_3[65]^s_3[110];

	z = t_1^t_2^t_3;

	t_1 = t_1^s_1[90]&s_1[91]^s_2[77];
	t_2 = t_2^s_2[81]&s_2[82]^s_3[86];
	t_3 = t_3^s_3[108]&s_3[109]^s_1[68];

	s_1 = s_1 >> 1;
	s_2 = s_2 >> 1;
	s_3 = s_3 >> 1;
		
	s_1[0] = t_3;
	s_2[0] = t_1;
	s_3[0] = t_2;

    enc=enc^z;
	return enc;
end
endfunction;

function logic [0:7] trivium_oct(logic [0:7] enc);

for(int i = 0; i <8; i++)
begin
	t1[i] = s_1[65-i]^s_1[92-i];
	t2[i] = s_2[68-i]^s_2[83-i];
	t3[i] = s_3[65-i]^s_3[110-i];
	
	zo[i] = t1[i]^t2[i]^t3[i];
end

for(int i = 0; i<8; i++)
begin
	t1[i] = t_1^s_1[90-i]&s_1[91-i]^s_2[77-i];
	t2[i] = t_2^s_2[81-i]&s_2[82-i]^s_3[86-i];
	t3[i] = t_3^s_3[108-i]&s_3[109-i]^s_1[68-i];
	
	enc[i]=enc[i]^zo[i];
end

s_1 = s_1 >> 8;
s_2 = s_2 >> 8;
s_3 = s_3 >> 8;

s_1[0:7] = t3;
s_2[0:7] = t1;
s_3[0:7] = t2;

return enc; //
endfunction;



initial begin
	trivium_id(); 
//Opening files #######################################
	in_file = $fopen("initial.txt","rb");
	if(in_file == 0) begin
		$display("Unable to open file.");
	end
	
	out_file = $fopen("encrypted.txt","wb");
	if(out_file == 0) begin
		$display("Unable to open file.");
	end
	
	control_file = $fopen("result.txt","wb");
	if(out_file == 0) begin
		$display("Unable to open file.");
	end
//Opening files #######################################
	while(!$feof(in_file))
		begin
		$fread(middle_string,in_file);
		/*
		for(int i = 0; i < 8; i++)
		begin
			middle_string[i]=trivium_c(middle_string[i]);
		end
		*/
		middle_string = trivium_oct(middle_string);
		$fwrite(out_file,"%s",middle_string);
		end
	
	$fclose(in_file);
	$fclose(out_file);
	trivium_id();
	
	out_file = $fopen("encrypted.txt","rb");
	if(out_file == 0) begin
		$display("Unable to open file.");
	end
	
	while(!$feof(out_file))
	begin
		$fread(middle_string,out_file);
		/*
		for(int i = 0; i < 8; i++)
		begin
			middle_string[i]=trivium_c(middle_string[i]);
		end
		*/
		middle_string = trivium_oct(middle_string);
		$fwrite(control_file,"%s",middle_string);
		end
	
	$fclose(out_file);
	$fclose(control_file);
	
	trivium_id();
	for(int i = 0; i < 128; i++)
	begin
			total_bits[i]=trivium_oct(8'b00000000);
	end

end
endprogram