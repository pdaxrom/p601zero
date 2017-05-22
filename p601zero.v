module p601zero (
	input clk_ext,
	input b_reset,
	
	input  [3:0] switches,
	input  [2:0] keys,
	output [8:0] seg_led_h,
	output [8:0] seg_led_l,
	output [7:0] leds,
	output [2:0] rgb1,
	output [2:0] rgb2,
	
	input rxd,
	output txd,

	output[16:0] SRAM_AD,
	inout[7:0] SRAM_DQ,
	output SRAM_WE_n,
	output SRAM_OE_n,
	output SRAM_CS2,
	
	output[1:0] tvout
);
	parameter OSC_CLOCK = 24000000;

	parameter CPU_CLOCK = 3000000;

	parameter CLK_DIV_PERIOD = (OSC_CLOCK / CPU_CLOCK) / 2;

	wire clk_in;
	
	pll pll1(
		.CLKI(clk_ext),
		.CLKOP(clk_in)
	);

	reg [24:0] sys_cnt;
	reg sys_clk = 0;
	
	wire [7:0] seg_byte;
	
/*
	CPU related
 */

	reg sys_res = 1;
	wire sys_rw;	wire sys_vma;
	wire [15:0] AD;
	wire [7:0] DI;
	wire [7:0] DO;

	wire simpleio_irq;
	wire uartio_irq;
	wire sys_irq = (simpleio_irq | uartio_irq) && (!sys_res);

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

	wire DS0 = (AD[15:5] == 11'b11100110000); // $E600
	wire DS1 = (AD[15:5] == 11'b11100110001); // $E620
	wire DS2 = (AD[15:5] == 11'b11100110010); // $E640
	wire DS3 = (AD[15:5] == 11'b11100110011); // $E660
	wire DS4 = (AD[15:5] == 11'b11100110100); // $E680
	wire DS5 = (AD[15:5] == 11'b11100110101); // $E6A0
	wire DS6 = (AD[15:5] == 11'b11100110110); // $E6C0
	wire DS7 = (AD[15:5] == 11'b11100110111); // $E6E0

	wire en_simpleio = DS5 && (AD[4:3] == 2'b00); // $E6A0
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

	wire en_uartio = DS5 && (AD[4:3] == 2'b01); // $E6A8
	wire cs_uartio = en_uartio && sys_vma;
	wire [7:0] uartiod;
	uartio uartio1 (
		.clk(sys_clk),
		.rst(sys_res),
		.irq(uartio_irq),
		.AD(AD[2:0]),
		.DI(DO),
		.DO(uartiod),
		.rw(sys_rw),
		.cs(cs_uartio),
		.clk_in(clk_in),
		.rxd(rxd),
		.txd(txd)
	);

	wire en_pagesel = DS7;
	wire cs_pagesel = en_pagesel && sys_vma;
	wire [7:0] pageseld;
	wire [4:0] mempage;
	pagesel pagesel_imp (
		.clk(sys_clk),
		.rst(sys_res),
		.AD(AD[4:0]),
		.DI(DO),
		.DO(pageseld),
		.rw(sys_rw),
		.cs(cs_pagesel),
		.page(mempage)
	);

	wire en_videocrt = DS0; // $E600
	wire cs_videocrt = en_videocrt && sys_vma;
	wire [7:0] videocrtd;
	
	wire [15:0] VAD;
	reg [7:0] VDI;
	wire vram_cs;
	reg vram_complete;
	videocrt videocrt_imp (
		.clk_in(clk_in),
		.clk(sys_clk),
		.rst(sys_res),
		.AD(AD[3:0]),
		.DI(DO),
		.DO(videocrtd),
		.rw(sys_rw),
		.cs(cs_videocrt),
		.mode(1'b0),
		.VAD(VAD),
		.VDI(VDI),
		.vram_cs(vram_cs),
		.vram_complete(vram_complete),
		.tvout(tvout)
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

	wire en_ram = !(en_brom | en_simpleio | en_uartio | en_pagesel | en_videocrt);
	wire cs_ram = en_ram && sys_vma;
	wire[7:0] ramd;
	
	wire [15:0] RAM_AD = vram_cs?VAD:AD;
	wire RAM_rw = vram_cs?1'b1:sys_rw;
	wire RAM_cs = vram_cs?1'b1:cs_ram;
	
	sram sram1 (
		.clk(sys_clk),
		.AD(RAM_AD),
		.DI(DO),
		.DO(ramd),
		.rw(RAM_rw),
		.cs(RAM_cs),
		.page(mempage),

		.SRAM_AD(SRAM_AD),
		.SRAM_DQ(SRAM_DQ),
		.SRAM_WE_n(SRAM_WE_n),
		.SRAM_OE_n(SRAM_OE_n),
		.SRAM_CS2(SRAM_CS2)
	);

	always @ (posedge sys_clk or posedge sys_res) begin
		if (sys_res) vram_complete <= 0;
		else begin
			if (vram_cs) begin
				VDI <= ramd;
				vram_complete <= 1;
			end else vram_complete <= 0;
		end
	end

	assign DI = en_ram      ? ramd:
				en_brom		? bromd:
				en_videocrt ? videocrtd:
				en_simpleio	? simpleiod:
				en_uartio	? uartiod:
				en_pagesel  ? pageseld:
				8'b11111111;

	wire sys_hold = vram_cs;

	wire sys_nmi;
	wire sys_halt;

	assign sys_nmi = 1'b0;
	assign sys_halt = 1'b0;

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
