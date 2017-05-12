/*
	$00 RW - UART DATA
	$01 R- - TIQ RIQ TIE RIE TRD RFE ROE RRD
	$02 RW - Hight prescaler byte
	$03 RW - Low prescaler byte
	
	RRD - RX Ready
	ROE - RX Overflow Error
	RFE - RX Frame Error
	TRD - TX Ready
	RIE - Enable Receiver Interrupt
	TIE - Enabe Transmitter Interrupt
	RIQ - Receiver interrupt status
	TIQ - Transmitter interrupt status

 */
module uartio (
	input wire clk,
	input wire rst,
	input wire [2:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	output wire irq,

	input wire clk_in,

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

	reg [7:0] status_reg;
	reg rx_full;
	reg tx_empty;
 
	assign irq = (status_reg[7] & status_reg[5]) | (status_reg[6] & status_reg[4]);
 
	always @ (posedge clk_in or posedge rx_tvalid or posedge rst) begin: rx_logic
		if (rst) begin
			rx_tready <= 0;
			rx_full <= 0;
		end else if (rx_tvalid) begin
				rx_tready <= ~rx_tready;
				rx_full <= 1;
		end else begin
			rx_tready <= 1;
			if (status_reg[0]) rx_full <= 0;
		end
	end
 
 	always @ (posedge clk_in or posedge tx_tready or posedge rst) begin: tx_logic
		if (rst) begin
			tx_empty <= 0;
		end else if (tx_tready) begin
			tx_empty <= 1;
		end else begin
			if (status_reg[3]) tx_empty <= 0;
		end
	end
 
	always @ (posedge clk or posedge rst) begin: port_logic
		if (rst) begin
			tx_tvalid <= 0;
			tx_data <= 0;
			prescaler <= 16'h0000;
			status_reg <= 8'b00000000;
		end else begin
			tx_tvalid <= 0;
			status_reg[3:0] <= {tx_tready, rx_frame_error, rx_overrun_error, rx_full | status_reg[0]};
			status_reg[7:6] <= {tx_empty & status_reg[5], rx_full & status_reg[4]};

			if (cs) begin
				if (rw) begin
					case (AD[2:0])
					3'b000: begin
						DO <= rx_data;
						status_reg[0] <= 0;
						end
					3'b001: begin
						DO <= status_reg;
						status_reg[7:6] <= 2'b00;
						end
					3'b010: DO <= prescaler[15:8];
					3'b011: DO <= prescaler[7:0];
					default: DO <= 8'b00000000;
					endcase
				end else begin
					case (AD[2:0])
					3'b000: begin
						tx_data <= DI;
						tx_tvalid <= 1;
						end
					3'b001: status_reg[5:4] <= DI[5:4];
					3'b010: prescaler[15:8] <= DI;
					3'b011: prescaler[7:0] <= DI;
					endcase
				end
			end
		end
	end

	uart_rx uart_rx_imp(.clk(clk_in), .rst(rst), .rxd(rxd), .prescale(prescaler),
				.output_axis_tdata(rx_data),
				.output_axis_tvalid(rx_tvalid),
				.output_axis_tready(rx_tready),
				
				.busy(rx_busy),
				.overrun_error(rx_overrun_error),
				.frame_error(rx_frame_error)
				);

	uart_tx uart_tx_imp(.clk(clk_in), .rst(rst), .txd(txd), .prescale(prescaler),
				.input_axis_tdata(tx_data),
				.input_axis_tvalid(tx_tvalid),
				.input_axis_tready(tx_tready),

				.busy(tx_busy)
				);

endmodule
