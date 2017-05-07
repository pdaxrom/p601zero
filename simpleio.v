/*
	Onboard devices:
	$00 RW - 8 leds
	$01 RW - 0RGB0RGB 2 leds
	$02 RW - Byte hex display  (HHHHLLLL)
	$03 R- - SSSSKKKK switches and keys
	
	Timer:
	$04 RW - IRQ | IEN | XXX | XXX | XXX | XXX | XXX | RUN
	$05 RW - Prescaler 24-16 bits
	$06 RW - Prescaler 15-8 bits
	$07 RW - Prescaler 7-0 bits
	IRQ - R- interrupt line status
	IEN - RW enable interrupt
	RUN - RW start/stop timer
 */

module simpleio (
	input wire clk,
	input wire rst,
	input wire [2:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	output wire irq,
	
	// physical connections
	output reg [7:0] leds,
	output reg [7:0] hex_disp,
	output reg [2:0] rgb1,
	output reg [2:0] rgb2,
	input wire  [3:0] switches,
	input wire  [3:0] keys
);
	reg [23:0] timer_cnt;
	reg [23:0] timer_prescaler;
	reg [7:0] timer_mode;
	
	assign irq = timer_mode[7] & timer_mode[6];
	
	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			leds <= 8'b11111111;
			rgb1 <= 8'b111;
			rgb2 <= 8'b111;
			hex_disp <= 0;
			timer_mode <= 0;
			timer_cnt <= 0;
			timer_prescaler <= 0;
		end else begin
			if (timer_mode[0]) begin
				if (timer_cnt == timer_prescaler) begin
					timer_mode[7] <= 1;
					timer_cnt <= 0;
				end else begin
					timer_cnt <= timer_cnt + 1'b1;
				end
			end

			if (cs) begin
				if (rw) begin
					case (AD[2:0])
					3'b000: DO <= ~leds;
					3'b001: begin
						DO[6:4] <= ~rgb1;
						DO[2:0] <= ~rgb2;
						end
					3'b010: DO <= hex_disp;
					3'b011: DO <= {switches, ~keys};
					3'b100: begin
						DO <= timer_mode;
						timer_mode[7] <= 0;
						end
					3'b101: DO <= timer_mode[0]?timer_cnt[23:16]:timer_prescaler[23:16];
					3'b110: DO <= timer_mode[0]?timer_cnt[15:8]:timer_prescaler[15:8];
					3'b111: DO <= timer_mode[0]?timer_cnt[7:0]:timer_prescaler[7:0];
					endcase
				end else begin
					case (AD[2:0])
					3'b000: leds <= ~DI;
					3'b001: begin
						rgb1 <= ~DI[6:4];
						rgb2 <= ~DI[2:0];
						end
					3'b010: hex_disp <= DI;
					3'b100: timer_mode[6:0] <= DI[6:0];
					3'b101: timer_prescaler[23:16] <= DI;
					3'b110: timer_prescaler[15:8] <= DI;
					3'b111: timer_prescaler[7:0] <= DI;
					endcase
				end
			end
		end
	end
endmodule
