/*
	Onboard devices:
	$00 RW - 8 leds
	$01 RW - High 7seg led
	$02 RW - Low  7seg led
	$03 RW - 0RGB0RGB 2 leds
	$04 R- - SSSSKKKK switches and keys
	
	Timer:
	$08 RW - IRQ | IEN | XXX | XXX | XXX | XXX | XXX | RUN
	$09 RW - Prescaler 24-16 bits
	$0A RW - Prescaler 15-8 bits
	$0B RW - Prescaler 7-0 bits
	
	IRQ - R- interrupt line status
	IEN - RW enable interrupt
	RUN - RW start/stop timer
 */

module simpleio (
	input wire clk,
	input wire rst,
	input wire [3:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	output wire irq,
	
	input wire clk_in,
	
	// physical connections
	output reg [7:0] leds,
	output reg [7:0] led7hi,
	output reg [7:0] led7lo,
	output reg [2:0] rgb1,
	output reg [2:0] rgb2,
	input wire  [3:0] switches,
	input wire  [3:0] keys
);
	reg [23:0] timer_cnt;
	reg [23:0] timer_prescaler;
	reg [7:0] timer_mode;
	reg timer_eq_flag;
	
	assign irq = timer_mode[7] & timer_mode[6];
	
	always @ (posedge clk_in) begin
		if (rst) begin
			timer_cnt <= 0;
			timer_eq_flag <= 0;
		end else begin
			if (timer_mode[0]) begin
				if (timer_cnt == timer_prescaler) begin
					timer_eq_flag <= 1;
					timer_cnt <= 0;
				end else begin
					timer_cnt <= timer_cnt + 1'b1;
					if (timer_mode[7]) timer_eq_flag <= 0;
				end
			end
		end
	end
	
	always @ (posedge clk) begin
		if (rst) begin
			leds <= 8'b11111111;
			rgb1 <= 8'b111;
			rgb2 <= 8'b111;
			led7hi <= 0;
			led7lo <= 0;
			timer_mode <= 0;
			timer_prescaler <= 0;
		end else begin
			if (timer_eq_flag) timer_mode[7] <= 1;

			if (cs) begin
				if (rw) begin
					case (AD[3:0])
					4'b0000: DO <= ~leds;
					4'b0001: DO <= led7hi;
					4'b0010: DO <= led7lo;
					4'b0011: begin
						DO[6:4] <= ~rgb1;
						DO[2:0] <= ~rgb2;
						end
					4'b0100: DO <= {switches, ~keys};
					4'b1000: begin
						DO <= timer_mode;
						timer_mode[7] <= 0;
						end
					4'b1001: DO <= timer_mode[0]?timer_cnt[23:16]:timer_prescaler[23:16];
					4'b1010: DO <= timer_mode[0]?timer_cnt[15:8]:timer_prescaler[15:8];
					4'b1011: DO <= timer_mode[0]?timer_cnt[7:0]:timer_prescaler[7:0];
					endcase
				end else begin
					case (AD[3:0])
					4'b0000: leds <= ~DI;
					4'b0001: led7hi <= DI;
					4'b0010: led7lo <= DI;
					4'b0011: begin
						rgb1 <= ~DI[6:4];
						rgb2 <= ~DI[2:0];
						end
					4'b1000: timer_mode[6:0] <= DI[6:0];
					4'b1001: timer_prescaler[23:16] <= DI;
					4'b1010: timer_prescaler[15:8] <= DI;
					4'b1011: timer_prescaler[7:0] <= DI;
					endcase
				end
			end
		end
	end
endmodule
