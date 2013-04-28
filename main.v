`define WIDTH 160;
`define HEIGHT 120;
`define VRAM_SIZE (WIDTH * HEIGHT);

module VGA(clk, rgb_out, hsync, vsync, write_addr, wdata, write_en, reset_vram);
	input clk;
	output [2:0]rgb_out;
	output hsync, vsync;

	// VRAM
	input [19:0] write_addr;
	input wdata, write_en, reset_vram;

	reg vga_clk, i_hs, i_vs, i_hdisp, i_vdisp;
	reg rgb_reg;
	reg [9:0]hcount, vcount;
	wire [9:0]x, y;
	wire [9:0]dx, dy;
	wire q_sig;
	wire [2:0]color;

	wire [19:0] read_addr;
	RAM2pot	RAM2pot_inst (
		.aclr ( reset_vram ),
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
		if(hcount == 799)
			hcount = 0;
		else
			hcount = hcount + 10'd1;
	end

	always @(posedge vga_clk) begin
		if(hcount == 0)
			i_hs = 0;
		else if(hcount == 96)
			i_hs = 1;
	end

	always @(posedge vga_clk) begin
		if(hcount == 144)
			i_hdisp = 1;
		else if(hcount == 784)
			i_hdisp = 0;
	end

	always @(posedge i_hs) begin
		if(vcount == 520)
			vcount = 0;
		else
			vcount = vcount + 1'd1;
	end

	always @(posedge i_hs) begin
		if(vcount == 10)
			i_vs = 0;
		else if(vcount == 2)
			i_vs = 1;
	end

	always @(posedge i_hs) begin
		if(vcount == 31)
			i_vdisp = 1;
		else if(vcount == 511)
			i_vdisp = 0;
	end

	assign x = hcount - 10'd144;
	assign y = vcount - 10'd35;
	assign read_addr = (x / 20'd4) + (y / 20'd4) * 20'd160;
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
		for(i = 0; i < 166; i = i + 1) begin
	 lfsr[i + 1] <= lfsr[i];
		end
	end
	assign bits = reg;
endmodule

module DE0etude(switch, led, dip, hsync, vsync, rgb, clk);
	input [2:0] switch;
	input [9:0] dip;
	output [9:0] led;
	input clk;
	output hsync, vsync;
	output [2:0] rgb;

	wire [166:0]		lfsr;
	LFSR LFSR_instance(clk, lfsr);

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

	// 160x120 bits RAM
	Cells	cells (
		.clock ( clk ),
		.data ( make_output(wdata, write_addr, dip, switch) ),
		.rdaddress ( read_addr ),
		.wraddress ( write_addr ),
		.wren ( write_en ),
		.q ( cell_q )
	);
	wire cell_q;
	reg [19:0] write_addr;
	reg [19:0] read_addr = 20'd161;
	reg wdata, write_en;

	VGA vga_module(
		clk, rgb, hsync, vsync,
		write_addr, make_output(wdata, write_addr, dip, switch),
		write_en, 0);
	reg [31:0] divide;
	reg shift_clk, rule_clk, addr_clk;
	reg blink, blink2;
	assign led[0] = blink;
	assign led[1] = blink2;

	always @(posedge addr_clk) begin
		read_addr = read_addr + 1'b1;
		write_addr = write_addr + 1'b1;
		if(read_addr >= 160 * 120) begin
			blink2 = 1;
			read_addr = 0;
		end
		if(write_addr >= 160 * 120) begin
			write_addr = 0;
		end
	end

	always @(posedge clk) begin
		divide = divide + 1'd1;
		if(divide >= 32'd50_000_000) begin
			blink <= ~blink;
			divide = 0;
		end
	   /*
		case(dip[4] ? divide[2:1] : divide[10:9])
			2'b00: begin write_en <= 0; addr_clk <= 1; end
			2'b01: begin addr_clk <= 0; shift_clk <= 1; end
			2'b10: begin shift_clk <= 0; rule_clk <= 1; end
			2'b11: begin rule_clk <= 0; write_en <= 1; end
		endcase
	    */
	end

endmodule