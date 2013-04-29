`define WIDTH 160
`define HEIGHT 120
`define VRAM_SIZE (`WIDTH * `HEIGHT)
`define VGA_SIGNAL_WIDTH 800
`define VGA_SIGNAL_HEIGHT 525
`define VGA_DISPLAY_WIDTH 640
`define VGA_DISPLAY_HEIGHT 480
`define VGA_HSYNC_WIDTH 96



module VGA(clk, rgb_out, hsync, vsync, write_addr, wdata, write_en, reset_vram);
	input clk;
	output [2:0]rgb_out;
	output hsync, vsync;

	// VRAM
	input [14:0] write_addr;
	input wdata, write_en, reset_vram;

	reg vga_clk, i_hs, i_vs, i_hdisp, i_vdisp;
	reg rgb_reg;
	reg [9:0]hcount, vcount;
	wire [9:0]x, y;
	wire [9:0]dx, dy;
	wire q_sig;
	wire [2:0]color;

	wire [14:0] read_addr;
	RAM160x120	vram (
		.clock ( clk ),
		.data ( wdata ),
		.rdaddress ( read_addr ),
		.wraddress ( write_addr ),
		.wren ( write_en ),
		.q ( q_sig )
	);

	always @(posedge clk) begin
		vga_clk = ~vga_clk;
	end

	always @(posedge vga_clk) begin
		if(hcount == `VGA_SIGNAL_WIDTH - 1)
			hcount = 0;
		else
			hcount = hcount + 10'd1;
	end

	always @(posedge vga_clk) begin
		if(hcount == 0)
			i_hs = 0;
		else if(hcount == `VGA_HSYNC_WIDTH)
			i_hs = 1;
	end

	always @(posedge vga_clk) begin
		integer start_display = `VGA_HSYNC_WIDTH + 40 + 8;
		if(hcount == start_display)
			// after hsync+back porch+left borer
			i_hdisp = 1;
		else if(hcount == start_display + `VGA_DISPLAY_WIDTH)
			i_hdisp = 0;
	end

	always @(posedge i_hs) begin
		if(vcount == 520)
			vcount = 0;
		else
			vcount = vcount + 1'd1;
	end

	always @(posedge i_hs) begin
		if(vcount == 0)
			i_vs = 0;
		else if(vcount == 2) // vsync
			i_vs = 1;
	end

	always @(posedge i_hs) begin
		if(vcount == 31) // why not 35 or 34
			i_vdisp = 1;
		else if(vcount == 511) // why not 515
			i_vdisp = 0;
	end

	assign x = hcount - 10'd144;
	assign y = vcount - 10'd35;
	assign read_addr = (x / 15'd4) + (y / 15'd4) * 15'd160;
	assign hsync = i_hs;
	assign vsync = i_vs;
	assign color = q_sig & ~(x[1:0] == 0 | y[1:0] == 0) ? 3'b001 : 3'b111;
	assign rgb_out = (i_hdisp & i_vdisp) ? color : 3'b000;
endmodule

module LFSR(clk, bits);
	input clk;
	output [166:0] bits;

	reg [166:0] lfsr = 166'h0123456789ABCDEF_CAFEBABE_DEADBEEF;

	always @(posedge clk) begin
		lfsr[0] <= ^{lfsr[160], lfsr[166]};
		lfsr[166:1] <= lfsr[165:0];
	end
	assign bits = lfsr;
endmodule

module DE0etude(switch, dip, clk, gpio, led, hsync, vsync, rgb);
	input [2:0] switch;
	input [9:0] dip;
	input clk;
	input [4:0] gpio;
	output [9:0] led;
	output hsync, vsync;
	output [2:0] rgb;
	
	wire [166:0] lfsr;
	LFSR LFSR_instance(clk, lfsr);

	wire [2:0]rgb_in = gpio[2:0];
	wire hsync_in = gpio[3];
	wire vsync_in = gpio[4];
	reg [19:0] in_addr;
	reg [9:0] in_h, in_v, in_x, in_y;	
	reg vga_clk;

	
	always @(posedge vga_clk) begin
		if(~vsync_in) begin
			in_h <= 0;
			in_v <= 0;
		end else begin
			if(in_h == `VGA_SIGNAL_WIDTH - 1) begin
				in_h <= 0;
				if(in_v == `VGA_SIGNAL_HEIGHT - 1) begin
					in_v <= 0;
				end else begin
					in_v <= in_v + 10'b1;
				end
			end else begin
				in_h <= in_h + 10'b1;
			end
		end
	end

	always @(posedge vga_clk) begin
		if(33 < in_v && in_v < 480 + 33 && 152 < in_h && in_h < 152 + 640 )begin
			`define x (in_h - 152)
			`define y (in_v - 33)
			if(`x & 3 == 0 && `y & 3 == 0) begin
				write_en = 1;
				write_addr = (`x / 4) + `y / 4 * 160;
				wdata = rgb_in[0];
			end else begin
				write_en = 0;
			end
		end
	end
	
	function make_output;
		input wdata;
		input [19:0] write_addr;
		input [9:0] dip;
		input [2:0] switch;
		begin
			make_output = (
				wdata
				& ~dip[0] // suppress output
				| dip[1]  // force output
			);
		end
	endfunction

	wire cell_q;
	reg [14:0] write_addr;
	reg wdata = 0, write_en;

	VGA vga_module(
		clk, rgb, hsync, vsync,
		write_addr, make_output(wdata, write_addr, dip, switch),
		write_en, 0
	);
	reg [31:0] divide;
	reg shift_clk, rule_clk, addr_clk;
	reg blink;
	assign led[0] = blink;
	
	always @(posedge clk) begin
		vga_clk = ~vga_clk;
		divide = divide + 1'd1;
		if(divide >= 32'd50_000_000) begin
			blink <= ~blink;
			divide = 0;
		end
	end

endmodule