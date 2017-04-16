/*
	$0000 RW - 8 leds
	$0001 RW - 0RGB0RGB 2 leds
	$0002 RW - Byte hex display  (HHHHLLLL)
	$0004 R- - SSSSKKKK switches and keys
	$0006 RW - UART DATA
	$0007 R- - XXXXXXTR Tx ready  busy, Rx ready
	*/

module simpleio (
	input wire clk,
	input wire rst,
	input wire [3:0] Address,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	
	// physical connections
	output reg [7:0] leds,
	output reg [7:0] hex_disp,
	output reg [2:0] rgb1,
	output reg [2:0] rgb2,
	input wire  [3:0] switches,
	input wire  [3:0] keys,
	
	input wire rxd,
	output txd
);
	parameter ClkFreq = 1000000;
	parameter Baud = 9600;

	wire rx_data_ready;
	wire [7:0] rx_data;
	reg [7:0] rx_buffer;
	reg rx_ready;
	
	wire tx_busy;
	wire [7:0] tx_data;

	always @ (posedge clk or posedge rst or posedge rx_data_ready) begin
		if (rst) begin
			leds <= 8'b11111111;
			rgb1 <= 8'b111;
			rgb2 <= 8'b111;
			hex_disp <= 0;
			
			rx_ready <= 0;
		end else if (clk && cs) begin
			if (rw == 0) begin
				case (Address[2:0])
				3'b000: leds <= ~DI;
				3'b001: begin
					rgb1 <= ~DI[6:4];
					rgb2 <= ~DI[2:0];
					end
				3'b010: hex_disp <= DI;
				endcase
			end else begin
				case (Address[2:0])
				3'b000: DO <= leds;
				3'b001: begin
					DO[6:4] <= rgb1;
					DO[2:0] <= rgb2;
					end
				3'b010: DO <= hex_disp;
				3'b100: DO <= {switches, keys};
				3'b110: begin
					DO <= rx_buffer;
					rx_ready <= 0;
					end
				3'b111: DO[1:0] <= {tx_busy, rx_ready};
				default: DO <= 8'b00000000;
				endcase
			end
		end else if (rx_data_ready) begin
			if (rx_ready == 0) begin
				rx_ready <= 1;
				rx_buffer <= rx_data;
			end
		end
	end

	async_receiver #(ClkFreq, Baud) RX(.clk(clk), .RxD(rxd), .RxD_data_ready(rx_data_ready), .RxD_data(rx_data));

	wire tx_start = (Address[2:0] == 3'b110) && (rw == 0) && cs && clk && (tx_busy == 0);

	async_transmitter #(ClkFreq, Baud) TX(.clk(clk), .TxD(txd), .TxD_start(tx_start), .TxD_data(DI), .TxD_busy(tx_busy));

endmodule
