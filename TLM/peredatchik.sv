module uart_tx(clk, data, start, tx, ready);

input   wire                    clk;
input   wire    [7:0]   data;
input   wire                    start;
output  reg                             tx;
output  wire                    ready;

reg [7:0] data_tx;
reg [2:0] count;
reg [3:0] state;
initial count = 0;

//ну тут тоже сделано так, что передача в 8 раз медленнее клока
always @(posedge clk)
        count <= count + 1;
assign clock = ~|count;

//смена состояний конечного автомата
always @(posedge clk)
        case (state)
                4'b0000: tx <= 1'b1; // при простое держим единицу 
                4'b0001: tx <= 1'b0; // старт-бит
                4'b0010: tx <= data_tx[0];
                4'b0011: tx <= data_tx[1];
                4'b0100: tx <= data_tx[2];
                4'b0101: tx <= data_tx[3];
                4'b0110: tx <= data_tx[4];
                4'b0111: tx <= data_tx[5];
                4'b1000: tx <= data_tx[6];
                4'b1001: tx <= data_tx[7];
                4'b1010: tx <= 1'b1; //стоп-бит
                default: tx <= 1'b1; 
        endcase

assign ready = (state == 4'b0000);

initial state = 0;

always @(posedge clock)
        begin
                if (start & ready) // шоб во время передачи не пытались
                        begin
                                data_tx <= data; 
                                state <= 4'b0001;
                        end
                else
                        if (state > 4'b1010) // усё передали
                                state <= 4'b0000; 
                        else 
                                if (!ready & clock) 
                                        state <= state + 1'b1;
        end
endmodule
