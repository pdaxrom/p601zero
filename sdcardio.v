/*
	SD card interface
	
	$0    RW - RDY|XXX|XXX|XXX|XXX|XXX|XXX|SS0
	$1    RW - DATA
	$2    RW - PRESCALER
	RDY - R- IO ready
	SS0 - select SPI device 0
*/
module sdcardio (
	input wire clk,
	input wire rst,
	input wire [2:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
//	output wire irq,

	input wire clk_in,

	output wire sdcs,
	output wire mosi,
	output reg msck,
	input wire miso
);
	reg [7:0] config_reg;
	reg [7:0] rx_data;
	reg [7:0] tx_data;
	reg [7:0] prescaler;
	
	reg start;
	
	reg [7:0] shifted_tx_data;
	reg [3:0] bit_counter;
	reg [7:0] scale_counter;
	wire data_ready = ((bit_counter == 0) && (!msck))?1'b1:1'b0;

	always @ (posedge clk) begin
		if (rst) begin
			config_reg <= 8'b00000001;
			tx_data <= 8'b11111111;
			prescaler <= 0;
			start <= 0;
		end else begin
			if (cs) begin
				if (rw) begin
					case (AD[2:0])
					3'b000: DO <= {data_ready, 3'b0, config_reg[3:0]};
					3'b001: begin
							DO <= rx_data;
						end
					3'b010: DO <= prescaler;
					endcase
				end else begin
					case (AD[2:0])
					3'b000: config_reg <= DI;
					3'b001: begin
							tx_data <= DI;
							start <= 1'b1;
						end
					3'b010: prescaler <= DI;
					endcase
				end
			end else begin
				if (!data_ready) start <= 1'b0;
			end
		end
	end

	assign sdcs = config_reg[0];
	assign mosi = ((bit_counter == 0) && (!msck))?1'b1:shifted_tx_data[7];
//	assign mosi = ((bit_counter == 0) && (!msck))?1'bZ:shifted_tx_data[7];

	always @ (posedge clk_in) begin
		if (rst) begin
			msck <= 0;
			rx_data <= 8'b11111111;
			scale_counter <= 0;
		end else if (start) begin
			shifted_tx_data <= tx_data;
			bit_counter <= 8;
		end else begin
			if (bit_counter != 0) begin
				if (scale_counter == prescaler) begin
					scale_counter <= 0;
					msck <= ~msck;
					if (msck) begin
						shifted_tx_data <= {shifted_tx_data[6:0], 1'b1};
						rx_data <= {rx_data[6:0], miso};
						bit_counter <= bit_counter - 1'b1;
					end
				end else scale_counter <= scale_counter + 1'b1;
			end else msck <= 0;
		end
	end

endmodule
