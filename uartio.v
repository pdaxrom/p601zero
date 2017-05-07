/*
	$00 RW - UART DATA
	$01 R- - XXX XXX TBS TRD RFE ROE RBS RRD
	$02 RW - Hight prescaler byte
	$03 RW - Low prescaler byte
	
	RRD - RX Ready
	RBS - RX Busy
	ROE - RX Overflow Error
	RFE - RX Frame Error
	TRD - TX Ready
	TBS - TX Busy

 */
module uartio (
	input wire clk,
	input wire rst,
	input wire [2:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

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
					case (AD[2:0])
					3'b000: begin
						tx_data <= DI;
						tx_tvalid <= 1;
						end
					3'b010: prescaler[15:8] <= DI;
					3'b011: prescaler[7:0] <= DI;
					endcase
				end else begin
					case (AD[2:0])
					3'b000: begin
						DO <= rx_data;
						rx_tready <= 1;
						end
					3'b001: DO <= {1'b0, 1'b0, tx_busy, tx_tready, rx_frame_error, rx_overrun_error, rx_busy, ~rx_tready};
					3'b010: DO <= prescaler[15:8];
					3'b011: DO <= prescaler[7:0];
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
