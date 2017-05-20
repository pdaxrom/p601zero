module videocrt (
	input wire clk_in,
	input wire clk,
	input wire rst,
	input wire [3:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

	// physical connection
	output wire [1:0] tvout
);
	wire pixel_clk;
	
	wire [8:0] cntHS;
	wire [8:0] cntVS;
	wire vbl;
	wire out_sync;

	reg [8:0] HS_start;
	reg [8:0] HS_end;
	reg [8:0] VS_start;
	reg [8:0] VS_end;

	reg [15:0] frame_addr;
	reg [15:0] vport_waddr;
	reg [15:0] vport_raddr;
	reg [7:0]  vport_step;
	
	reg [2:0] pixel_cnt;
	reg [15:0] vaddr_cnt;
	
	reg [7:0] shift_reg;

	reg [7:0] video_ram[2047:0];

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			HS_start <= 160; // 20chars * 8
			HS_end <= 480; // (20chars + 40chars) * 8
			VS_start <= 57;
			VS_end <= 257;
			frame_addr <= 16'h0000;
			vport_waddr <= 16'h0000;
			vport_raddr <= 16'h0000;
			vport_step <= 8'h01;
		end else begin
			if (cs) begin
				if (rw) begin
					case (AD[3:0])
					4'b0000: DO <= frame_addr[15:8];
					4'b0001: DO <= frame_addr[7:0];
					4'b0010: DO <= {3'b000, HS_start[8:3]};
					4'b0011: DO <= {3'b000, HS_end[8:3]};
					4'b0100: DO <= { 7'b0000000, VS_start[8]};
					4'b0101: DO <= VS_start[7:0];
					4'b0110: DO <= { 7'b0000000, VS_end[8]};
					4'b0111: DO <= VS_end[7:0];
					4'b1010: DO <= vport_waddr[15:8];
					4'b1011: DO <= vport_waddr[7:0];
					4'b1100: DO <= vport_raddr[15:8];
					4'b1101: DO <= vport_raddr[7:0];
					4'b1110: DO <= vport_step;
					4'b1111: begin
							DO <= video_ram[vport_raddr];
							vport_raddr <= vport_raddr + vport_step;
						end
					endcase
				end else begin
					case (AD[3:0])
					4'b0000: frame_addr[15:8] <= DI;
					4'b0001: frame_addr[7:0] <= DI;
					4'b0010: HS_start <= {DI[5:0], 3'b000};
					4'b0011: HS_end <= {DI[5:0], 3'b000};
					4'b0100: VS_start[8] <= DI[0];
					4'b0101: VS_start[7:0] <= DI;
					4'b0110: VS_end[8] <= DI[0];
					4'b0111: VS_end[7:0] <= DI;
					4'b1010: vport_waddr[15:8] <= DI;
					4'b1011: vport_waddr[7:0] <= DI;
					4'b1100: vport_raddr[15:8] <= DI;
					4'b1101: vport_raddr[7:0] <= DI;
					4'b1110: vport_step <= DI;
					4'b1111: begin
							video_ram[vport_waddr] <= DI;
							//vport_waddr <= vport_waddr + vport_step;
						end
					endcase
				end
			end
		end
	end

	always @ (posedge pixel_clk) begin
		if (vbl) begin
			pixel_cnt <= 3'b000;
			vaddr_cnt <= frame_addr;
		end else begin
			if (((cntHS >= HS_start) && (cntHS < HS_end)) &&
				((cntVS >= VS_start) && (cntVS < VS_end))) begin
				if (pixel_cnt == 0) begin
					shift_reg <= video_ram[vaddr_cnt];
					vaddr_cnt <= vaddr_cnt + 1'b1;
				end else begin
					shift_reg[7:1] <= shift_reg[6:0];
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
endmodule
