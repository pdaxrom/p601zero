/*
	$00 RW - UART DATA
	$01 R- - TIQ RIQ TIE RIE TRD RFE ROE RRD
	$02 RW - Hight prescaler byte
	$03 RW - Low prescaler byte
	$04 RW - Keyboard data
	$05 RW - KIQ KIE KEN XXX XXX XXX KPR KRD
	
	RRD - RX Ready
	ROE - RX Overflow Error
	RFE - RX Frame Error
	TRD - TX Ready
	RIE - Enable Receiver Interrupt
	TIE - Enabe Transmitter Interrupt
	RIQ - Receiver interrupt status
	TIQ - Transmitter interrupt status
	
	KIQ - Keyboard irq
	KIE - Keyboard irq enable
	KEN - Enable keyboard (Disable UART out)
	KPR - Keyboard data parity bit
	KRD - Keyboard data ready

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
	inout txd
);

	reg ps2_clk;
	reg ps2_dat;
	reg [10:0] kbd_data; // start bit + 8 bit data + parity bit + stop bit
	reg [1:0] kbd_conf;

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
 
	wire kbd_irq = kbd_conf[1] & kbd_conf[0] & kbd_data[10];
 
	assign irq = (status_reg[7] & status_reg[5]) | (status_reg[6] & status_reg[4]) | kbd_irq;
 
	always @ (posedge clk_in or posedge rst) begin: rx_logic
		if (rst) begin
			rx_tready <= 0;
			rx_full <= 0;
			tx_empty <= 0;
		end else begin
			if (rx_tvalid) begin
				rx_tready <= ~rx_tready;
				rx_full <= 1;
			end else begin
				rx_tready <= 1;
				if (status_reg[0]) rx_full <= 0;
			end
			if (tx_tready) tx_empty <= 1;
			else if (status_reg[3]) tx_empty <= 0;
		end
	end
 
	always @ (posedge clk or posedge rst) begin: port_logic
		if (rst) begin
			tx_tvalid <= 0;
			tx_data <= 0;
			prescaler <= 16'h0000;
			status_reg <= 8'b00000000;
			kbd_conf <= 0;
			kbd_data <= 0;
			ps2_clk <= 0;
			ps2_dat <= 0;
		end else begin
			tx_tvalid <= 0;
			status_reg[3:0] <= {tx_tready, rx_frame_error, rx_overrun_error, rx_full | status_reg[0]};
			status_reg[7:6] <= {(tx_empty | status_reg[7]) & status_reg[5], (rx_full | status_reg[6]) & status_reg[4]};

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
					4'b100: begin
						DO <= kbd_data[8:1];
						kbd_data <= 0;
						end
					4'b101: DO <= {kbd_irq, kbd_conf, kbd_data[9], kbd_data[10]};
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
					3'b101: kbd_conf <= DI[6:5];
					endcase
				end
			end
			if (kbd_conf[0]) begin
				if (ps2_clk & (~rxd)) begin
					if (kbd_data[10] & (~kbd_data[0])) kbd_data <= 0;
					else kbd_data <= (kbd_data << 1) | ps2_dat;
				end
				ps2_clk <= rxd;
				ps2_dat <= txd;
			end
		end
	end

//	always @ (posedge clk_in) ps2_clk <= rxd;
//	always @ (posedge clk_in) ps2_dat <= txd;

//	always @ (negedge ps2_clk) begin: ps2_logic
//		if (rst) kbd_data <= 0;
//		else begin
//			if (kbd_data[10] & (~kbd_data[0])) kbd_data <= 0;
//			else kbd_data <= (kbd_data << 1) | ps2_dat;
//		end
//	end

	wire uart_rxd = kbd_conf[0] ? 1'b0 : rxd;
	wire uart_txd;
	assign txd = kbd_conf[0] ? 1'bZ : uart_txd;

	uart_rx uart_rx_imp(.clk(clk_in), .rst(rst), .rxd(uart_rxd), .prescale(prescaler),
				.output_axis_tdata(rx_data),
				.output_axis_tvalid(rx_tvalid),
				.output_axis_tready(rx_tready),
				
				.busy(rx_busy),
				.overrun_error(rx_overrun_error),
				.frame_error(rx_frame_error)
				);

	uart_tx uart_tx_imp(.clk(clk_in), .rst(rst), .txd(uart_txd), .prescale(prescaler),
				.input_axis_tdata(tx_data),
				.input_axis_tvalid(tx_tvalid),
				.input_axis_tready(tx_tready),

				.busy(tx_busy)
				);

endmodule
