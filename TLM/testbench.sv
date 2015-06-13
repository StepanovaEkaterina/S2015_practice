`timescale 1ns / 1ps

module test_uart_rx;
reg clk;
reg rx;
wire data_received;
wire [7:0] data_in;

uart_rx u_rx (clk, rx, data_in, data_received);

always
  #10 clk = ~clk;

initial
        begin
        
                clk = 0;
                rx      = 1;
                #205 rx = 0;
                #160 rx = 1;
                #160 rx = 0;
                #160 rx = 1;
                #160 rx = 0;
                #160 rx = 1;
                #160 rx = 0;
                #160 rx = 1;
                #160 rx = 0;
                #160 rx = 1;
                #578 rx = 0;
                #160 rx = 1;
                #160 rx = 1;
                #160 rx = 1;
                #160 rx = 0;
                #160 rx = 1;
                #160 rx = 1;
                #160 rx = 1;
                #160 rx = 0;
                #160 rx = 1;
        end
initial
                #10000 $finish;
initial 
        begin
                $dumpfile("out.vcd");
                $dumpvars();
        end

  
endmodule
