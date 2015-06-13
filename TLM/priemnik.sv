module uart_rx (clk, rx, data, data_ready);

input   wire                    clk;
input   wire                    rx;
output  reg     [7:0]           data;
output                          data_ready;

reg rx_ff1, rx_ff2; // две защелки, для вычленения старта передачи 
                    // и вообще, защелки надо, чтобы всякие помехи не ловить

always @(posedge clk)
        begin
                rx_ff1 <= rx;
                rx_ff2 <= rx_ff1;
        end
// отлавливаем старт-бит
wire spad = ~rx_ff1 & rx_ff2;
// состояние приемника
reg receive;
// для корректной симуляции. Насколько знаю, квартус это пропускает
initial receive = 0;

//Ну тут понятно - если старт бит, то включаем режим приема,
//если приняли - выключаем
always @(posedge clk)
        if (spad) 
                receive <= 1'b1;
        else 
                if (data_ready)
                        receive <= 1'b0;
//cигнал начала приема. Для инициализации счетчиков.
wire start = ~receive & spad;

//поскольку у нас clk в 8 раз быстрее rx, делаем делитель
reg [2:0] count_os;

always @(posedge clk)
        if (start)
                count_os <= 1'b0;
        else
                if(receive)
                        count_os <= count_os + 1'b1;
//при переполнении счетчика-делителя выдираем бит из входных данных
wire get_bit = ~|count_os;
//счетчик принятых данных. Как примем 9 бит - можно останавливаться
reg [3:0] count_byte;
always @(posedge get_bit or posedge start)
        begin
                if (start)
                        count_byte <= 0;
                else 
                        count_byte <= count_byte + 4'b1;
        end
wire data_ready = (count_byte == 9);
//сдвигаем регистр данных на одну позицию вправо,
//и пишем принятый бит в старший бит
always @(negedge get_bit)
        if (!data_ready) data <= {rx_ff1, data[7:1]};
endmodule
