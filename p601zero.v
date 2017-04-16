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
	parameter CPU_CLOCK = 1000000;

	parameter OSC_CLOCK = 12000000;

	parameter CLK_DIV_PERIOD = 3;

	parameter IRQ_DIV_PERIOD = OSC_CLOCK / 50 / 2; // 50 HZ -> clk / 50 / 2= 12000000 / 50 / 2;
	parameter UART_BAUD = 4800;

	reg [24:0] cnt;
	reg clk_div = 0;
	
	reg [24:0] cnt_irq;
	reg clk_div_irq = 0;
	
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

/*
		if (cnt == (CLK_DIV_PERIOD - 1)) cnt <= 0;
		else cnt <= cnt + 1'b1;
		if (cnt < (CLK_DIV_PERIOD >> 1)) clk_div <= 0;
		else clk_div <= 1'b1;
 */
		if (cnt == (CLK_DIV_PERIOD - 1)) begin
			clk_div <= !clk_div;
			cnt <= 0;
		end else cnt <= cnt + 1'b1;



		if (cnt_irq == (IRQ_DIV_PERIOD - 1)) cnt_irq <= 0;
		else cnt_irq <= cnt_irq + 1'b1;
		if (cnt_irq < (IRQ_DIV_PERIOD >> 1)) clk_div_irq <= 0;
		else clk_div_irq <= 1'b1;


		if (cnt_irq[0] == 0)
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
	always @ (posedge clk_div or negedge b_reset)
	begin
		if (!b_reset) begin
			sys_res <= 1;
			sys_nmi <= 0;
			sys_irq <= 0;
			sys_hold <= 0;
			sys_halt <= 0;
			
			sys_res_delay = 3'b100;
		end else begin
			sys_clk <= !sys_clk;
			
			if (sys_res_delay == 3'b000) sys_res <= 0;
			else sys_res_delay <= sys_res_delay - 3'b001;
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


	wire en_brom = (AD[15:12] == 4'b1111);
	wire [7:0] bromd;
	bootrom brom (
		.clk(sys_clk),
		.Address(AD),
		.DO(bromd),
		.rw(sys_rw)
	);

	wire en_bram = (AD[15:8] == 8'b00000000);
	wire [7:0] bramd;
	bootram bram (
		.clk(sys_clk),
		.Address(AD),
		.DI(DO),
		.DO(bramd),
		.rw(sys_rw),
		.cs(en_bram)
	);

	wire en_superio = (AD[15:8] == 8'b11100110);
	wire [7:0] superiod;
	simpleio #(CPU_CLOCK, UART_BAUD) superio (
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
