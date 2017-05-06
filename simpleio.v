/*
	$0000 RW - 8 leds
	$0001 RW - 0RGB0RGB 2 leds
	$0002 RW - Byte hex display  (HHHHLLLL)
	$0004 R- - SSSSKKKK switches and keys
	$0008 RW - UART DATA
	$0009 R- - XXX XXX TBS TRD RFE ROE RBS RRD
	$000A RW - Hight prescaler byte
	$000B RW - Low prescaler byte
	
	RRD - RX Ready
	RBS - RX Busy
	ROE - RX Overflow Error
	RFE - RX Frame Error
	TRD - TX Ready
	TBS - TX Busy
	
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
	reg [15:0] prescaler;

	reg [7:0] tx_data;
	reg		tx_tvalid;
	wire	tx_tready;

	wire [7:0] rx_data;
	wire	rx_tvalid;
	reg		rx_tready;

    wire	tx_busy;
    wire	rx_busy;
    wire	rx_overrun_error;
    wire	rx_frame_error;
	
	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			leds <= 8'b11111111;
			rgb1 <= 8'b111;
			rgb2 <= 8'b111;
			hex_disp <= 0;
			prescaler <= 16'h0000;
			rx_tready <= 1;
			tx_tvalid <= 0;
		end else begin
			if (rx_tvalid) begin
					rx_tready <= 0;
			end
			if (tx_tready) begin
					tx_tvalid <= 0;
			end
			if (cs) begin
				if (rw == 0) begin
					case (Address[3:0])
					4'b0000: leds <= ~DI;
					4'b0001: begin
						rgb1 <= ~DI[6:4];
						rgb2 <= ~DI[2:0];
						end
					4'b0010: hex_disp <= DI;
					4'b1000: begin
						tx_data <= DI;
						tx_tvalid <= 1;
						end
					4'b1010: prescaler[15:8] <= DI;
					4'b1011: prescaler[7:0] <= DI;
					endcase
				end else begin
					case (Address[3:0])
					4'b0000: DO <= leds;
					4'b0001: begin
						DO[6:4] <= rgb1;
						DO[2:0] <= rgb2;
						end
					4'b0010: DO <= hex_disp;
					4'b0100: DO <= {switches, keys};
					4'b1000: begin
						DO <= rx_data;
						rx_tready <= 1;
						end
					4'b1001: DO <= {1'b0, 1'b0, tx_busy, tx_tready, rx_frame_error, rx_overrun_error, rx_busy, ~rx_tready};
					4'b1010: DO <= prescaler[15:8];
					4'b1011: DO <= prescaler[7:0];
					default: DO <= 8'b00000000;
					endcase
				end
			end
		end
	end

	uart uart1(.clk(clk), .rst(rst), .rxd(rxd), .txd(txd), .prescale(prescaler),
				.output_axis_tdata(rx_data),
				.output_axis_tvalid(rx_tvalid),
				.output_axis_tready(rx_tready),
				
				.input_axis_tdata(tx_data),
				.input_axis_tvalid(tx_tvalid),
				.input_axis_tready(tx_tready),

				.tx_busy(tx_busy),
				.rx_busy(rx_busy),
				.rx_overrun_error(rx_overrun_error),
				.rx_frame_error(rx_frame_error)

				);

endmodule
