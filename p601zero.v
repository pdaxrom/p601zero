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
	output txd,

	output[16:0] SRAM_AD,
	inout[7:0] SRAM_DQ,
	output SRAM_WE_n,
	output SRAM_OE_n,
	output SRAM_CS2,
	
	output sdcs,
	output mosi,
	output msck,
	input miso
);
	parameter OSC_CLOCK = 12000000;

	parameter CPU_CLOCK = 3000000;

	parameter CLK_DIV_PERIOD = (OSC_CLOCK / CPU_CLOCK) / 2;
	
	parameter LED_REFRESH_CLOCK = 50;
	
	parameter LED_DIV_PERIOD = (OSC_CLOCK / LED_REFRESH_CLOCK) / 2;

	reg [24:0] sys_cnt;
	reg sys_clk = 0;
	
	reg [24:0] led_cnt;
	reg [1:0] led_anode;
	wire [7:0] seg_byte;
	
/*
	CPU related
 */

	reg sys_res = 1;
	reg sys_hold;
	reg sys_halt;
	wire sys_rw;	wire sys_vma;
	wire [15:0] AD;
	wire [7:0] DI;
	wire [7:0] DO;

	wire simpleio_irq;
	wire uartio_irq;
	wire sys_irq = (simpleio_irq | uartio_irq) && (!sys_res);

	wire sys_nmi = (!keys[2]) && (!sys_res);

	reg [2:0] sys_res_delay = 3'b100;

	always @ (posedge clk_in)
	begin		if (sys_cnt == (CLK_DIV_PERIOD - 1)) begin
			sys_clk <= !sys_clk;
			sys_cnt <= 0;
		end else sys_cnt <= sys_cnt + 1'b1;
		
		if (sys_res) led_anode <= 2'b01;
		else begin
			if (led_cnt == (LED_DIV_PERIOD - 1)) begin
				led_anode <= ~led_anode;
				led_cnt <= 0;
			end else led_cnt <= led_cnt + 1'b1;
		end
	end

	always @ (posedge sys_clk or negedge b_reset)
	begin
		if (!b_reset) begin
			sys_res <= 1;
			sys_hold <= 0;
			sys_halt <= 0;
			
			sys_res_delay = 3'b100;
		end else begin
			if (sys_res_delay == 3'b000) begin
				sys_res <= 0;
			end else sys_res_delay <= sys_res_delay - 3'b001;
		end
	end

	assign seg_led_h[8] = led_anode[1];
	assign seg_led_l[8] = led_anode[0];

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

	wire en_sdcardio = DS6; // $E6C0
	wire cs_sdcardio = en_sdcardio && sys_vma;
	wire [7:0] sdcardiod;
	sdcardio sdcardio_impl(
		.clk(sys_clk),
		.rst(sys_res),
		.AD(AD[2:0]),
		.DI(DO),
		.DO(sdcardiod),
		.rw(sys_rw),
		.cs(cs_sdcardio),
		
		.sdcs(sdcs),
		.mosi(mosi),
		.msck(msck),
		.miso(miso)
	);

	wire en_pagesel = DS7; // $E6F0
	wire cs_pagesel = en_pagesel && sys_vma;
	wire [7:0] pageseld;
	wire [4:0] mempage;
	wire bram_disable;
	pagesel pagesel_imp (
		.clk(sys_clk),
		.rst(sys_res),
		.AD(AD[4:0]),
		.DI(DO),
		.DO(pageseld),
		.rw(sys_rw),
		.cs(cs_pagesel),
		.page(mempage),
		.bram_disable(bram_disable)
	);

	wire en_brom = (AD[15:12] == 4'b1111);
	wire cs_brom = en_brom && sys_vma;
	wire [7:0] bromd;
	mcu_rom brom (
		.OutClock(sys_clk),
		.Reset(sys_res),
		.OutClockEn(cs_brom),
		.Address(AD[9:0]),
		.Q(bromd)
	);

	wire en_bram = (AD[15:12] == 4'b0000) && (!bram_disable);
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

	wire en_ram = !(en_brom | en_bram | en_simpleio | en_uartio | en_sdcardio | en_pagesel);
	wire cs_ram = en_ram && sys_vma;
	wire[7:0] ramd;
	sram sram1 (
		.clk(sys_clk),
		.AD(AD),
		.DI(DO),
		.DO(ramd),
		.rw(sys_rw),
		.cs(cs_ram),
		.page(mempage),

		.SRAM_AD(SRAM_AD),
		.SRAM_DQ(SRAM_DQ),
		.SRAM_WE_n(SRAM_WE_n),
		.SRAM_OE_n(SRAM_OE_n),
		.SRAM_CS2(SRAM_CS2)
	);

	assign DI = en_ram      ? ramd:
				en_bram		? bramd:
				en_brom		? bromd:
				en_simpleio	? simpleiod:
				en_uartio	? uartiod:
				en_sdcardio ? sdcardiod:
				en_pagesel  ? pageseld:
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
