module p601zero (
	input clk_in,
	input b_reset,
	
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
	parameter OSC_CLOCK = 12000000;

	parameter CPU_CLOCK = 3000000;

	parameter CLK_DIV_PERIOD = (OSC_CLOCK / CPU_CLOCK) / 2;

	reg [24:0] sys_cnt;
	reg sys_clk = 0;
	
	wire [7:0] seg_byte;
	
/*
	CPU related
 */

	reg sys_res = 1;
	reg sys_nmi = 0;
	reg sys_hold = 0;
	reg sys_halt = 0;
	wire sys_rw;	wire sys_vma;
	wire [15:0] AD;
	wire [7:0] DI;
	wire [7:0] DO;

	wire simpleio_irq;
	wire sys_irq = simpleio_irq && (!sys_res);

	reg [2:0] sys_res_delay = 3'b100;

	always @ (posedge clk_in)
	begin
		if (sys_cnt == (CLK_DIV_PERIOD - 1)) begin
			sys_clk <= !sys_clk;
			sys_cnt <= 0;
		end else sys_cnt <= sys_cnt + 1'b1;
	end

	always @ (posedge sys_clk or negedge b_reset)
	begin
		if (!b_reset) begin
			sys_res <= 1;
			sys_nmi <= 0;
			sys_hold <= 0;
			sys_halt <= 0;
			
			sys_res_delay = 3'b100;
		end else begin
			if (sys_res_delay == 3'b000) begin
				sys_res <= 0;
			end else sys_res_delay <= sys_res_delay - 3'b001;
		end
	end

	assign seg_led_h[8] = 0;
	assign seg_led_l[8] = 0;

	assign seg_led_h[7] = 0;
	assign seg_led_l[7] = 0;
 
	segled segled_h(
		.nibble (seg_byte[7:4]),
		.segs (seg_led_h[6:0])
		);

	segled segled_l(
		.nibble (seg_byte[3:0]),
		.segs (seg_led_l[6:0])
		);


	wire en_brom = (AD[15:12] == 4'b1111);
	wire cs_brom = en_brom && sys_vma;
	wire [7:0] bromd;
	mcu_rom brom (
		.OutClock(sys_clk),
		.Reset(sys_res),
		.OutClockEn(cs_brom),
		.Address(AD[7:0]),
		.Q(bromd)
	);

	wire en_bram = (AD[15:8] == 8'b00000000);
	wire cs_bram = en_bram && sys_vma;
	wire [7:0] bramd;
	mcu_ram bram (
		.clk(sys_clk),
		.AD(AD),
		.DI(DO),
		.DO(bramd),
		.rw(sys_rw),
		.cs(cs_bram)
	);
	wire en_simpleio = (AD[15:3] == 13'b1110011010100); // $E6A0
	wire cs_simpleio = en_simpleio && sys_vma;
	wire [7:0] simpleiod;
	simpleio simpleio1 (
		.clk(sys_clk),
		.rst(sys_res),
		.irq(simpleio_irq),
		.AD(AD[2:0]),
		.DI(DO),
		.DO(simpleiod),
		.rw(sys_rw),
		.cs(cs_simpleio),
		.leds(leds),
		.hex_disp(seg_byte),
		.rgb1(rgb1),
		.rgb2(rgb2),
		.switches(switches),
		.keys(keys)
	);

	wire en_uartio = (AD[15:3] == 13'b1110011010101); // $E6A8
	wire cs_uartio = en_uartio && sys_vma;
	wire [7:0] uartiod;
	uartio uartio1 (
		.clk(sys_clk),
		.rst(sys_res),
		.AD(AD[2:0]),
		.DI(DO),
		.DO(uartiod),
		.rw(sys_rw),
		.cs(cs_uartio),
		.rxd(rxd),
		.txd(txd)
	);

	assign DI = en_brom		? bromd:
				en_bram		? bramd:
				en_simpleio	? simpleiod:
				en_uartio	? uartiod:
				8'b11111111;

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

endmodule
