module videocrt (
	input wire clk_in,
	input wire clk,
	input wire rst,
	input wire [3:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

//	input wire mode,

	output reg [15:0] VAD,
	input wire [7:0] VDI,
	output reg vram_cs,
	input wire vram_complete,

	// physical connection
	output wire [1:0] tvout
);
	wire pixel_clk;
	
	wire [8:0] cntHS;
	wire [8:0] cntVS;
	wire vbl;
	wire out_sync;

	reg [7:0] HS_total;
	reg [7:0] HS_displayed;
	reg [7:0] HS_pos;
	reg [7:0] HS_width;
	reg [7:0] VS_total;
	reg [7:0] VS_adj;
	reg [7:0] VS_displayed;
	reg [7:0] VS_pos;
	reg [7:0] SCNL_max;
	reg [13:0] frame_addr;

	reg [8:0] HS_start;
	reg [8:0] HS_end;
	reg [8:0] HS_cnt;
	reg [8:0] HS_cnt_end;
	reg [8:0] VS_start;
	reg [8:0] VS_end;
	reg [13:0] VS_addr;
	reg [2:0] SCNL_addr;
	reg [13:0] addr_tmp;
	reg [15:0] addr_tmp16;

	reg [2:0] pixel_cnt;

	reg VAD_inc;
	reg VAD_complete;
	reg [7:0] VDI_data;
	reg [7:0] shift_reg;

	//reg [7:0] CGAddr;
	wire [7:0] CGData;

	reg [4:0] mc6845_addr;

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			frame_addr <= 16'h0000;
		end else begin
			if (cs) begin
				if (rw) begin
					if (AD[0]) begin
						case (mc6845_addr[4:0])
						4'b00000: DO <= HS_total;
						4'b00001: DO <= HS_displayed;
						4'b00010: DO <= HS_pos;
						4'b00011: DO <= HS_width;
						4'b00100: DO <= VS_total;
						4'b00101: DO <= VS_adj;
						4'b00110: DO <= VS_displayed;
						4'b00111: DO <= VS_pos;
						4'b01001: DO <= SCNL_max;
						4'b01100: DO <= {2'b00, frame_addr[13:8]};
						4'b01101: DO <= frame_addr[7:0];
						default: DO <= 8'h00;
						endcase
					end else DO <= {3'b000, mc6845_addr};
				end else begin
					if (AD[0]) begin
						case (mc6845_addr[4:0])
						4'b00000: HS_total <= DI;
						4'b00001: HS_displayed <= DI;
						4'b00010: HS_pos <= DI;
						4'b00011: HS_width <= DI;
						4'b00100: VS_total <= DI;
						4'b00101: VS_adj <= DI;
						4'b00110: VS_displayed <= DI;
						4'b00111: VS_pos <= DI;
						4'b01001: SCNL_max <= DI;
						4'b01100: frame_addr[13:8] <= DI[5:0];
						4'b01101: frame_addr[7:0] <= DI;
						endcase
					end else mc6845_addr <= DI[4:0];
				end
			end
		end
	end

	always @ (posedge clk) begin
		if (rst) begin
			VAD_complete <= 0;
			vram_cs <= 0;
		end else begin
			if (VAD_inc && (!VAD_complete)) begin
				VAD <= addr_tmp16;
				VAD_complete <= 1;
				vram_cs <= 1;
			end else begin
				if (!VAD_inc) VAD_complete <= 0;
				if (vram_complete) begin
					VDI_data <= VDI;
					vram_cs <= 0;
				end
			end
		end
	end

	reg VDI_init;

	always @ (posedge pixel_clk) begin
		if (rst) VDI_init <= 1;
		else if (vbl) begin
			pixel_cnt <= 3'b000;
			HS_start <= (HS_total - (HS_pos + HS_width)) << 3;
			VS_start <= ((VS_total - VS_pos) << 3) + VS_adj;
			HS_end <= HS_start + (HS_displayed << 3);
			VS_end <= HS_start + (VS_displayed << 3);

			addr_tmp16 <= {frame_addr[12:0], 3'b000};
			addr_tmp <= frame_addr;
			SCNL_addr <= 0;
			HS_cnt <= 0;
			
			if (VDI_init && (!VAD_inc)) begin
				VAD_inc <= 1;
			end else begin
				VDI_init <= 0;
				if (VAD_inc && VAD_complete) VAD_inc <= 0;
			end
			
		end else begin
			VDI_init <= 1;
			if (((cntHS > HS_start) && (cntHS <= HS_end )) &&
				((cntVS > VS_start) && (cntVS <= VS_end))) begin
				if (pixel_cnt == 0) begin
					if (HS_cnt == (HS_displayed - 1)) begin
						HS_cnt <= 0;
						if (SCNL_addr == 3'b111) begin
							SCNL_addr <= 3'b000;
							addr_tmp16[2:0] <= 3'b000;
							addr_tmp16[15:3] <= addr_tmp[12:0] + HS_displayed;
							addr_tmp <= addr_tmp + HS_displayed;
						end else begin
							SCNL_addr <= SCNL_addr + 1'b1;
							addr_tmp16[2:0] <= addr_tmp16[2:0] + 1'b1;
							addr_tmp16[15:3] <= addr_tmp[12:0];
						end
					end else begin
						HS_cnt <= HS_cnt + 1'b1;
						addr_tmp16[15:3] <= addr_tmp16[15:3] + 1'b1;
					end
					shift_reg <= VDI_data;
					//shift_reg <= CGData;
					VAD_inc <= 1;
				end else begin
					shift_reg <= shift_reg << 1;
					if (VAD_inc && VAD_complete) VAD_inc <= 0;
				end
				pixel_cnt <= pixel_cnt + 1'b1;
			end else begin
				shift_reg <= 8'h00;
			end
		end
	end
	assign tvout[1] = (vbl || (cntHS < 37))?1'b0:shift_reg[7];
	assign tvout[0] = out_sync;

	tvout tvout_impl (
		.clk_in(clk_in),
		.rst(rst),
		.cntHS(cntHS),
		.cntVS(cntVS),
		.pixel_clk(pixel_clk),
		.vbl(vbl),
		.out_sync(out_sync)
	);
	
	cgrom cgrom_impl (
		.Address({VDI_data[6:0] ,VDI_data[7], SCNL_addr}),
		.Q(CGData)
	);
endmodule
