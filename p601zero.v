module p601zero (
	input clk_in,
	input b_reset,
//	input b_step,
//	input b_mode,
	
	input  [3:0] switches,
	input  [2:0] keys,
	output [8:0] seg_led_h,
	output [8:0] seg_led_l,
	output [7:0] leds,
	output [2:0] rgb1,
	output [2:0] rgb2,
	
	input rxd,
	output txd
);
	reg [7:0] time_sec;
	parameter OSC_CLOCK = 12000000;

	parameter CPU_CLOCK = 3000000;

	parameter RTC_CLOCK = 50;

	parameter CLK_DIV_PERIOD = (OSC_CLOCK / CPU_CLOCK) / 2;

	parameter RTC_DIV_PERIOD = (OSC_CLOCK / RTC_CLOCK) / 2;

	reg [24:0] sys_cnt;
	
	reg [24:0] rtc_cnt;
	reg rtc_clk = 0;
	
	reg [1:0] seg_mode = 0;
	
	wire [7:0] seg_byte;
	
	reg led_pow_h = 0;
	reg led_pow_l = 1;

/*
	CPU related
 */

	reg sys_clk = 0;
	reg sys_res = 1;
	reg sys_nmi = 0;
	reg sys_irq = 0;
	reg sys_hold = 0;
	reg sys_halt = 0;
	wire sys_rw;	wire sys_vma;
	wire [15:0] AD;
	wire [7:0] DI;
	wire [7:0] DO;

	reg [2:0] sys_res_delay = 3'b100;

	always @ (posedge clk_in)
	begin
		if (sys_cnt == (CLK_DIV_PERIOD - 1)) begin
			sys_clk <= !sys_clk;
			sys_cnt <= 0;
		end else sys_cnt <= sys_cnt + 1'b1;

		if (rtc_cnt == (RTC_DIV_PERIOD - 1)) begin
			rtc_clk <= !rtc_clk;
			rtc_cnt <= 0;
		end else rtc_cnt <= rtc_cnt + 1'b1;

		if (rtc_clk == 0)
		begin
			led_pow_h <= !led_pow_h;
			led_pow_l <= !led_pow_l;
		end
	end

/*
	always @ (posedge b_mode)
	begin
		seg_mode <= seg_mode + 2'b01;
	end
 */
	always @ (posedge sys_clk or negedge b_reset)
	begin
		if (!b_reset) begin
			sys_res <= 1;
			sys_nmi <= 0;
			sys_irq <= 0;
			sys_hold <= 0;
			sys_halt <= 0;
			
			sys_res_delay = 3'b100;
		end else begin
			if (sys_res_delay == 3'b000) begin
				sys_res <= 0;
				sys_irq <= rtc_clk;
			end else sys_res_delay <= sys_res_delay - 3'b001;
		end
	end

	assign seg_led_h[8] = led_pow_h;
	assign seg_led_l[8] = led_pow_l;

	assign seg_led_h[7] = seg_mode[0];
	assign seg_led_l[7] = seg_mode[1];
//	assign seg_led_l[7] = sys_clk;

/*
	always @*
	begin
		case(seg_mode)
		2'b00: seg_byte <= DI;
		2'b01: seg_byte <= AD[15:8];
		2'b10: seg_byte <= AD[7:0];
		2'b11: seg_byte <= DO;
		endcase;
	end
 */
 
	segled segled_h(
		.nibble (seg_byte[7:4]),
		.segs (seg_led_h[6:0])
		);

	segled segled_l(
		.nibble (seg_byte[3:0]),
		.segs (seg_led_l[6:0])
		);


	wire en_brom = (AD[15:12] == 4'b1111) & sys_vma;
	wire [7:0] bromd;
	bootrom brom (
		.clk(sys_clk),
		.Address(AD),
		.DO(bromd),
		.rw(sys_rw)
	);

	wire en_bram = (AD[15:8] == 8'b00000000) & sys_vma;
	wire [7:0] bramd;
	bootram bram (
		.clk(sys_clk),
		.Address(AD),
		.DI(DO),
		.DO(bramd),
		.rw(sys_rw),
		.cs(en_bram)
	);

	wire en_superio = (AD[15:8] == 8'b11100110) & sys_vma;
	//wire cs_superio = en_superio & sys_vma;
	wire [7:0] superiod;
	simpleio superio (
		.clk(sys_clk),
		.rst(sys_res),
		.Address(AD[3:0]),
		.DI(DO),
		.DO(superiod),
		.rw(sys_rw),
		.cs(en_superio),
		.leds(leds),
		.hex_disp(seg_byte),
		.rgb1(rgb1),
		.rgb2(rgb2),
		.switches(switches),
		.keys(keys),
		.rxd(rxd),
		.txd(txd)
	);

	chipsel adsel (
		DI,
		en_brom, bromd,
		en_bram, bramd,
		en_superio, superiod,
		8'b11111111
	);

	cpu68 mc6801 (
		.clk(sys_clk),
		.rst(sys_res),
		.irq(sys_irq),
		.nmi(sys_nmi),
		.hold(sys_hold),
		.halt(sys_halt),
		.rw(sys_rw),
		.vma(sys_vma),
		.address(AD),
		.data_in(DI),
		.data_out(DO)
	);

//	assign leds = 8'b11111111;
//	assign rgb1 = 3'b111;
//	assign rgb2 = 3'b111;

endmodule
