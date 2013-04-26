`define WIDTH 160;
`define HEIGHT 120;
`define VRAM_SIZE (WIDTH * HEIGHT);

module VGA(clk, rgb_out, hsync, vsync, write_addr, wdata, write_en, reset_vram);
	input clk;
	output [2:0]rgb_out;
	output hsync, vsync;

	// VRAM
	input [19:0]write_addr;
	input wdata, write_en, reset_vram;
	
	reg vga_clk, i_hs, i_vs, i_hdisp, i_vdisp;
	reg rgb_reg;
	reg [9:0]hcount, vcount;
	wire [9:0]x, y;
	wire [9:0]dx, dy;
	wire q_sig;
	wire [2:0]color;
	
	wire [19:0]read_addr;
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
	//	assign read_addr = x + y * 20'd640;
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

	function is_rpento;
		input [19:0] write_addr;
		begin
			is_rpento = (write_addr == 9680 | write_addr == 9681 | write_addr == 9841 | write_addr == 9842 | write_addr == 10001);
		end
	endfunction
	
   wire [166:0]      lfsr;
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
				// put r-pentomino
				| (~switch[2] & is_rpento(write_addr))
				// xor random
				^ (dip[2] & lfsr[166])
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
	
	

	
	reg [322:0]buffer;
	integer i;
	always @(posedge shift_clk) begin
		buffer[0] <= cell_q;
		for(i = 0; i < 322; i = i + 1) begin
			buffer[i + 1] <= buffer[i];
		end
	end
	




	wire [8:0] neighbors;
	assign neighbors = {buffer[2:0], buffer[162:160], buffer[322:320]};
	always @(posedge rule_clk) begin
		case(neighbors)
			9'b000_000_000: wdata = 1'b0;
			9'b000_000_001: wdata = 1'b0;
			9'b000_000_010: wdata = 1'b0;
			9'b000_000_011: wdata = 1'b0;
			9'b000_000_100: wdata = 1'b0;
			9'b000_000_101: wdata = 1'b0;
			9'b000_000_110: wdata = 1'b0;
			9'b000_000_111: wdata = 1'b1;
			9'b000_001_000: wdata = 1'b0;
			9'b000_001_001: wdata = 1'b0;
			9'b000_001_010: wdata = 1'b0;
			9'b000_001_011: wdata = 1'b1;
			9'b000_001_100: wdata = 1'b0;
			9'b000_001_101: wdata = 1'b1;
			9'b000_001_110: wdata = 1'b1;
			9'b000_001_111: wdata = 1'b0;
			9'b000_010_000: wdata = 1'b0;
			9'b000_010_001: wdata = 1'b0;
			9'b000_010_010: wdata = 1'b0;
			9'b000_010_011: wdata = 1'b1;
			9'b000_010_100: wdata = 1'b0;
			9'b000_010_101: wdata = 1'b1;
			9'b000_010_110: wdata = 1'b1;
			9'b000_010_111: wdata = 1'b1;
			9'b000_011_000: wdata = 1'b0;
			9'b000_011_001: wdata = 1'b1;
			9'b000_011_010: wdata = 1'b1;
			9'b000_011_011: wdata = 1'b1;
			9'b000_011_100: wdata = 1'b1;
			9'b000_011_101: wdata = 1'b1;
			9'b000_011_110: wdata = 1'b1;
			9'b000_011_111: wdata = 1'b0;
			9'b000_100_000: wdata = 1'b0;
			9'b000_100_001: wdata = 1'b0;
			9'b000_100_010: wdata = 1'b0;
			9'b000_100_011: wdata = 1'b1;
			9'b000_100_100: wdata = 1'b0;
			9'b000_100_101: wdata = 1'b1;
			9'b000_100_110: wdata = 1'b1;
			9'b000_100_111: wdata = 1'b0;
			9'b000_101_000: wdata = 1'b0;
			9'b000_101_001: wdata = 1'b1;
			9'b000_101_010: wdata = 1'b1;
			9'b000_101_011: wdata = 1'b0;
			9'b000_101_100: wdata = 1'b1;
			9'b000_101_101: wdata = 1'b0;
			9'b000_101_110: wdata = 1'b0;
			9'b000_101_111: wdata = 1'b0;
			9'b000_110_000: wdata = 1'b0;
			9'b000_110_001: wdata = 1'b1;
			9'b000_110_010: wdata = 1'b1;
			9'b000_110_011: wdata = 1'b1;
			9'b000_110_100: wdata = 1'b1;
			9'b000_110_101: wdata = 1'b1;
			9'b000_110_110: wdata = 1'b1;
			9'b000_110_111: wdata = 1'b0;
			9'b000_111_000: wdata = 1'b1;
			9'b000_111_001: wdata = 1'b1;
			9'b000_111_010: wdata = 1'b1;
			9'b000_111_011: wdata = 1'b0;
			9'b000_111_100: wdata = 1'b1;
			9'b000_111_101: wdata = 1'b0;
			9'b000_111_110: wdata = 1'b0;
			9'b000_111_111: wdata = 1'b0;
			9'b001_000_000: wdata = 1'b0;
			9'b001_000_001: wdata = 1'b0;
			9'b001_000_010: wdata = 1'b0;
			9'b001_000_011: wdata = 1'b1;
			9'b001_000_100: wdata = 1'b0;
			9'b001_000_101: wdata = 1'b1;
			9'b001_000_110: wdata = 1'b1;
			9'b001_000_111: wdata = 1'b0;
			9'b001_001_000: wdata = 1'b0;
			9'b001_001_001: wdata = 1'b1;
			9'b001_001_010: wdata = 1'b1;
			9'b001_001_011: wdata = 1'b0;
			9'b001_001_100: wdata = 1'b1;
			9'b001_001_101: wdata = 1'b0;
			9'b001_001_110: wdata = 1'b0;
			9'b001_001_111: wdata = 1'b0;
			9'b001_010_000: wdata = 1'b0;
			9'b001_010_001: wdata = 1'b1;
			9'b001_010_010: wdata = 1'b1;
			9'b001_010_011: wdata = 1'b1;
			9'b001_010_100: wdata = 1'b1;
			9'b001_010_101: wdata = 1'b1;
			9'b001_010_110: wdata = 1'b1;
			9'b001_010_111: wdata = 1'b0;
			9'b001_011_000: wdata = 1'b1;
			9'b001_011_001: wdata = 1'b1;
			9'b001_011_010: wdata = 1'b1;
			9'b001_011_011: wdata = 1'b0;
			9'b001_011_100: wdata = 1'b1;
			9'b001_011_101: wdata = 1'b0;
			9'b001_011_110: wdata = 1'b0;
			9'b001_011_111: wdata = 1'b0;
			9'b001_100_000: wdata = 1'b0;
			9'b001_100_001: wdata = 1'b1;
			9'b001_100_010: wdata = 1'b1;
			9'b001_100_011: wdata = 1'b0;
			9'b001_100_100: wdata = 1'b1;
			9'b001_100_101: wdata = 1'b0;
			9'b001_100_110: wdata = 1'b0;
			9'b001_100_111: wdata = 1'b0;
			9'b001_101_000: wdata = 1'b1;
			9'b001_101_001: wdata = 1'b0;
			9'b001_101_010: wdata = 1'b0;
			9'b001_101_011: wdata = 1'b0;
			9'b001_101_100: wdata = 1'b0;
			9'b001_101_101: wdata = 1'b0;
			9'b001_101_110: wdata = 1'b0;
			9'b001_101_111: wdata = 1'b0;
			9'b001_110_000: wdata = 1'b1;
			9'b001_110_001: wdata = 1'b1;
			9'b001_110_010: wdata = 1'b1;
			9'b001_110_011: wdata = 1'b0;
			9'b001_110_100: wdata = 1'b1;
			9'b001_110_101: wdata = 1'b0;
			9'b001_110_110: wdata = 1'b0;
			9'b001_110_111: wdata = 1'b0;
			9'b001_111_000: wdata = 1'b1;
			9'b001_111_001: wdata = 1'b0;
			9'b001_111_010: wdata = 1'b0;
			9'b001_111_011: wdata = 1'b0;
			9'b001_111_100: wdata = 1'b0;
			9'b001_111_101: wdata = 1'b0;
			9'b001_111_110: wdata = 1'b0;
			9'b001_111_111: wdata = 1'b0;
			9'b010_000_000: wdata = 1'b0;
			9'b010_000_001: wdata = 1'b0;
			9'b010_000_010: wdata = 1'b0;
			9'b010_000_011: wdata = 1'b1;
			9'b010_000_100: wdata = 1'b0;
			9'b010_000_101: wdata = 1'b1;
			9'b010_000_110: wdata = 1'b1;
			9'b010_000_111: wdata = 1'b0;
			9'b010_001_000: wdata = 1'b0;
			9'b010_001_001: wdata = 1'b1;
			9'b010_001_010: wdata = 1'b1;
			9'b010_001_011: wdata = 1'b0;
			9'b010_001_100: wdata = 1'b1;
			9'b010_001_101: wdata = 1'b0;
			9'b010_001_110: wdata = 1'b0;
			9'b010_001_111: wdata = 1'b0;
			9'b010_010_000: wdata = 1'b0;
			9'b010_010_001: wdata = 1'b1;
			9'b010_010_010: wdata = 1'b1;
			9'b010_010_011: wdata = 1'b1;
			9'b010_010_100: wdata = 1'b1;
			9'b010_010_101: wdata = 1'b1;
			9'b010_010_110: wdata = 1'b1;
			9'b010_010_111: wdata = 1'b0;
			9'b010_011_000: wdata = 1'b1;
			9'b010_011_001: wdata = 1'b1;
			9'b010_011_010: wdata = 1'b1;
			9'b010_011_011: wdata = 1'b0;
			9'b010_011_100: wdata = 1'b1;
			9'b010_011_101: wdata = 1'b0;
			9'b010_011_110: wdata = 1'b0;
			9'b010_011_111: wdata = 1'b0;
			9'b010_100_000: wdata = 1'b0;
			9'b010_100_001: wdata = 1'b1;
			9'b010_100_010: wdata = 1'b1;
			9'b010_100_011: wdata = 1'b0;
			9'b010_100_100: wdata = 1'b1;
			9'b010_100_101: wdata = 1'b0;
			9'b010_100_110: wdata = 1'b0;
			9'b010_100_111: wdata = 1'b0;
			9'b010_101_000: wdata = 1'b1;
			9'b010_101_001: wdata = 1'b0;
			9'b010_101_010: wdata = 1'b0;
			9'b010_101_011: wdata = 1'b0;
			9'b010_101_100: wdata = 1'b0;
			9'b010_101_101: wdata = 1'b0;
			9'b010_101_110: wdata = 1'b0;
			9'b010_101_111: wdata = 1'b0;
			9'b010_110_000: wdata = 1'b1;
			9'b010_110_001: wdata = 1'b1;
			9'b010_110_010: wdata = 1'b1;
			9'b010_110_011: wdata = 1'b0;
			9'b010_110_100: wdata = 1'b1;
			9'b010_110_101: wdata = 1'b0;
			9'b010_110_110: wdata = 1'b0;
			9'b010_110_111: wdata = 1'b0;
			9'b010_111_000: wdata = 1'b1;
			9'b010_111_001: wdata = 1'b0;
			9'b010_111_010: wdata = 1'b0;
			9'b010_111_011: wdata = 1'b0;
			9'b010_111_100: wdata = 1'b0;
			9'b010_111_101: wdata = 1'b0;
			9'b010_111_110: wdata = 1'b0;
			9'b010_111_111: wdata = 1'b0;
			9'b011_000_000: wdata = 1'b0;
			9'b011_000_001: wdata = 1'b1;
			9'b011_000_010: wdata = 1'b1;
			9'b011_000_011: wdata = 1'b0;
			9'b011_000_100: wdata = 1'b1;
			9'b011_000_101: wdata = 1'b0;
			9'b011_000_110: wdata = 1'b0;
			9'b011_000_111: wdata = 1'b0;
			9'b011_001_000: wdata = 1'b1;
			9'b011_001_001: wdata = 1'b0;
			9'b011_001_010: wdata = 1'b0;
			9'b011_001_011: wdata = 1'b0;
			9'b011_001_100: wdata = 1'b0;
			9'b011_001_101: wdata = 1'b0;
			9'b011_001_110: wdata = 1'b0;
			9'b011_001_111: wdata = 1'b0;
			9'b011_010_000: wdata = 1'b1;
			9'b011_010_001: wdata = 1'b1;
			9'b011_010_010: wdata = 1'b1;
			9'b011_010_011: wdata = 1'b0;
			9'b011_010_100: wdata = 1'b1;
			9'b011_010_101: wdata = 1'b0;
			9'b011_010_110: wdata = 1'b0;
			9'b011_010_111: wdata = 1'b0;
			9'b011_011_000: wdata = 1'b1;
			9'b011_011_001: wdata = 1'b0;
			9'b011_011_010: wdata = 1'b0;
			9'b011_011_011: wdata = 1'b0;
			9'b011_011_100: wdata = 1'b0;
			9'b011_011_101: wdata = 1'b0;
			9'b011_011_110: wdata = 1'b0;
			9'b011_011_111: wdata = 1'b0;
			9'b011_100_000: wdata = 1'b1;
			9'b011_100_001: wdata = 1'b0;
			9'b011_100_010: wdata = 1'b0;
			9'b011_100_011: wdata = 1'b0;
			9'b011_100_100: wdata = 1'b0;
			9'b011_100_101: wdata = 1'b0;
			9'b011_100_110: wdata = 1'b0;
			9'b011_100_111: wdata = 1'b0;
			9'b011_101_000: wdata = 1'b0;
			9'b011_101_001: wdata = 1'b0;
			9'b011_101_010: wdata = 1'b0;
			9'b011_101_011: wdata = 1'b0;
			9'b011_101_100: wdata = 1'b0;
			9'b011_101_101: wdata = 1'b0;
			9'b011_101_110: wdata = 1'b0;
			9'b011_101_111: wdata = 1'b0;
			9'b011_110_000: wdata = 1'b1;
			9'b011_110_001: wdata = 1'b0;
			9'b011_110_010: wdata = 1'b0;
			9'b011_110_011: wdata = 1'b0;
			9'b011_110_100: wdata = 1'b0;
			9'b011_110_101: wdata = 1'b0;
			9'b011_110_110: wdata = 1'b0;
			9'b011_110_111: wdata = 1'b0;
			9'b011_111_000: wdata = 1'b0;
			9'b011_111_001: wdata = 1'b0;
			9'b011_111_010: wdata = 1'b0;
			9'b011_111_011: wdata = 1'b0;
			9'b011_111_100: wdata = 1'b0;
			9'b011_111_101: wdata = 1'b0;
			9'b011_111_110: wdata = 1'b0;
			9'b011_111_111: wdata = 1'b0;
			9'b100_000_000: wdata = 1'b0;
			9'b100_000_001: wdata = 1'b0;
			9'b100_000_010: wdata = 1'b0;
			9'b100_000_011: wdata = 1'b1;
			9'b100_000_100: wdata = 1'b0;
			9'b100_000_101: wdata = 1'b1;
			9'b100_000_110: wdata = 1'b1;
			9'b100_000_111: wdata = 1'b0;
			9'b100_001_000: wdata = 1'b0;
			9'b100_001_001: wdata = 1'b1;
			9'b100_001_010: wdata = 1'b1;
			9'b100_001_011: wdata = 1'b0;
			9'b100_001_100: wdata = 1'b1;
			9'b100_001_101: wdata = 1'b0;
			9'b100_001_110: wdata = 1'b0;
			9'b100_001_111: wdata = 1'b0;
			9'b100_010_000: wdata = 1'b0;
			9'b100_010_001: wdata = 1'b1;
			9'b100_010_010: wdata = 1'b1;
			9'b100_010_011: wdata = 1'b1;
			9'b100_010_100: wdata = 1'b1;
			9'b100_010_101: wdata = 1'b1;
			9'b100_010_110: wdata = 1'b1;
			9'b100_010_111: wdata = 1'b0;
			9'b100_011_000: wdata = 1'b1;
			9'b100_011_001: wdata = 1'b1;
			9'b100_011_010: wdata = 1'b1;
			9'b100_011_011: wdata = 1'b0;
			9'b100_011_100: wdata = 1'b1;
			9'b100_011_101: wdata = 1'b0;
			9'b100_011_110: wdata = 1'b0;
			9'b100_011_111: wdata = 1'b0;
			9'b100_100_000: wdata = 1'b0;
			9'b100_100_001: wdata = 1'b1;
			9'b100_100_010: wdata = 1'b1;
			9'b100_100_011: wdata = 1'b0;
			9'b100_100_100: wdata = 1'b1;
			9'b100_100_101: wdata = 1'b0;
			9'b100_100_110: wdata = 1'b0;
			9'b100_100_111: wdata = 1'b0;
			9'b100_101_000: wdata = 1'b1;
			9'b100_101_001: wdata = 1'b0;
			9'b100_101_010: wdata = 1'b0;
			9'b100_101_011: wdata = 1'b0;
			9'b100_101_100: wdata = 1'b0;
			9'b100_101_101: wdata = 1'b0;
			9'b100_101_110: wdata = 1'b0;
			9'b100_101_111: wdata = 1'b0;
			9'b100_110_000: wdata = 1'b1;
			9'b100_110_001: wdata = 1'b1;
			9'b100_110_010: wdata = 1'b1;
			9'b100_110_011: wdata = 1'b0;
			9'b100_110_100: wdata = 1'b1;
			9'b100_110_101: wdata = 1'b0;
			9'b100_110_110: wdata = 1'b0;
			9'b100_110_111: wdata = 1'b0;
			9'b100_111_000: wdata = 1'b1;
			9'b100_111_001: wdata = 1'b0;
			9'b100_111_010: wdata = 1'b0;
			9'b100_111_011: wdata = 1'b0;
			9'b100_111_100: wdata = 1'b0;
			9'b100_111_101: wdata = 1'b0;
			9'b100_111_110: wdata = 1'b0;
			9'b100_111_111: wdata = 1'b0;
			9'b101_000_000: wdata = 1'b0;
			9'b101_000_001: wdata = 1'b1;
			9'b101_000_010: wdata = 1'b1;
			9'b101_000_011: wdata = 1'b0;
			9'b101_000_100: wdata = 1'b1;
			9'b101_000_101: wdata = 1'b0;
			9'b101_000_110: wdata = 1'b0;
			9'b101_000_111: wdata = 1'b0;
			9'b101_001_000: wdata = 1'b1;
			9'b101_001_001: wdata = 1'b0;
			9'b101_001_010: wdata = 1'b0;
			9'b101_001_011: wdata = 1'b0;
			9'b101_001_100: wdata = 1'b0;
			9'b101_001_101: wdata = 1'b0;
			9'b101_001_110: wdata = 1'b0;
			9'b101_001_111: wdata = 1'b0;
			9'b101_010_000: wdata = 1'b1;
			9'b101_010_001: wdata = 1'b1;
			9'b101_010_010: wdata = 1'b1;
			9'b101_010_011: wdata = 1'b0;
			9'b101_010_100: wdata = 1'b1;
			9'b101_010_101: wdata = 1'b0;
			9'b101_010_110: wdata = 1'b0;
			9'b101_010_111: wdata = 1'b0;
			9'b101_011_000: wdata = 1'b1;
			9'b101_011_001: wdata = 1'b0;
			9'b101_011_010: wdata = 1'b0;
			9'b101_011_011: wdata = 1'b0;
			9'b101_011_100: wdata = 1'b0;
			9'b101_011_101: wdata = 1'b0;
			9'b101_011_110: wdata = 1'b0;
			9'b101_011_111: wdata = 1'b0;
			9'b101_100_000: wdata = 1'b1;
			9'b101_100_001: wdata = 1'b0;
			9'b101_100_010: wdata = 1'b0;
			9'b101_100_011: wdata = 1'b0;
			9'b101_100_100: wdata = 1'b0;
			9'b101_100_101: wdata = 1'b0;
			9'b101_100_110: wdata = 1'b0;
			9'b101_100_111: wdata = 1'b0;
			9'b101_101_000: wdata = 1'b0;
			9'b101_101_001: wdata = 1'b0;
			9'b101_101_010: wdata = 1'b0;
			9'b101_101_011: wdata = 1'b0;
			9'b101_101_100: wdata = 1'b0;
			9'b101_101_101: wdata = 1'b0;
			9'b101_101_110: wdata = 1'b0;
			9'b101_101_111: wdata = 1'b0;
			9'b101_110_000: wdata = 1'b1;
			9'b101_110_001: wdata = 1'b0;
			9'b101_110_010: wdata = 1'b0;
			9'b101_110_011: wdata = 1'b0;
			9'b101_110_100: wdata = 1'b0;
			9'b101_110_101: wdata = 1'b0;
			9'b101_110_110: wdata = 1'b0;
			9'b101_110_111: wdata = 1'b0;
			9'b101_111_000: wdata = 1'b0;
			9'b101_111_001: wdata = 1'b0;
			9'b101_111_010: wdata = 1'b0;
			9'b101_111_011: wdata = 1'b0;
			9'b101_111_100: wdata = 1'b0;
			9'b101_111_101: wdata = 1'b0;
			9'b101_111_110: wdata = 1'b0;
			9'b101_111_111: wdata = 1'b0;
			9'b110_000_000: wdata = 1'b0;
			9'b110_000_001: wdata = 1'b1;
			9'b110_000_010: wdata = 1'b1;
			9'b110_000_011: wdata = 1'b0;
			9'b110_000_100: wdata = 1'b1;
			9'b110_000_101: wdata = 1'b0;
			9'b110_000_110: wdata = 1'b0;
			9'b110_000_111: wdata = 1'b0;
			9'b110_001_000: wdata = 1'b1;
			9'b110_001_001: wdata = 1'b0;
			9'b110_001_010: wdata = 1'b0;
			9'b110_001_011: wdata = 1'b0;
			9'b110_001_100: wdata = 1'b0;
			9'b110_001_101: wdata = 1'b0;
			9'b110_001_110: wdata = 1'b0;
			9'b110_001_111: wdata = 1'b0;
			9'b110_010_000: wdata = 1'b1;
			9'b110_010_001: wdata = 1'b1;
			9'b110_010_010: wdata = 1'b1;
			9'b110_010_011: wdata = 1'b0;
			9'b110_010_100: wdata = 1'b1;
			9'b110_010_101: wdata = 1'b0;
			9'b110_010_110: wdata = 1'b0;
			9'b110_010_111: wdata = 1'b0;
			9'b110_011_000: wdata = 1'b1;
			9'b110_011_001: wdata = 1'b0;
			9'b110_011_010: wdata = 1'b0;
			9'b110_011_011: wdata = 1'b0;
			9'b110_011_100: wdata = 1'b0;
			9'b110_011_101: wdata = 1'b0;
			9'b110_011_110: wdata = 1'b0;
			9'b110_011_111: wdata = 1'b0;
			9'b110_100_000: wdata = 1'b1;
			9'b110_100_001: wdata = 1'b0;
			9'b110_100_010: wdata = 1'b0;
			9'b110_100_011: wdata = 1'b0;
			9'b110_100_100: wdata = 1'b0;
			9'b110_100_101: wdata = 1'b0;
			9'b110_100_110: wdata = 1'b0;
			9'b110_100_111: wdata = 1'b0;
			9'b110_101_000: wdata = 1'b0;
			9'b110_101_001: wdata = 1'b0;
			9'b110_101_010: wdata = 1'b0;
			9'b110_101_011: wdata = 1'b0;
			9'b110_101_100: wdata = 1'b0;
			9'b110_101_101: wdata = 1'b0;
			9'b110_101_110: wdata = 1'b0;
			9'b110_101_111: wdata = 1'b0;
			9'b110_110_000: wdata = 1'b1;
			9'b110_110_001: wdata = 1'b0;
			9'b110_110_010: wdata = 1'b0;
			9'b110_110_011: wdata = 1'b0;
			9'b110_110_100: wdata = 1'b0;
			9'b110_110_101: wdata = 1'b0;
			9'b110_110_110: wdata = 1'b0;
			9'b110_110_111: wdata = 1'b0;
			9'b110_111_000: wdata = 1'b0;
			9'b110_111_001: wdata = 1'b0;
			9'b110_111_010: wdata = 1'b0;
			9'b110_111_011: wdata = 1'b0;
			9'b110_111_100: wdata = 1'b0;
			9'b110_111_101: wdata = 1'b0;
			9'b110_111_110: wdata = 1'b0;
			9'b110_111_111: wdata = 1'b0;
			9'b111_000_000: wdata = 1'b1;
			9'b111_000_001: wdata = 1'b0;
			9'b111_000_010: wdata = 1'b0;
			9'b111_000_011: wdata = 1'b0;
			9'b111_000_100: wdata = 1'b0;
			9'b111_000_101: wdata = 1'b0;
			9'b111_000_110: wdata = 1'b0;
			9'b111_000_111: wdata = 1'b0;
			9'b111_001_000: wdata = 1'b0;
			9'b111_001_001: wdata = 1'b0;
			9'b111_001_010: wdata = 1'b0;
			9'b111_001_011: wdata = 1'b0;
			9'b111_001_100: wdata = 1'b0;
			9'b111_001_101: wdata = 1'b0;
			9'b111_001_110: wdata = 1'b0;
			9'b111_001_111: wdata = 1'b0;
			9'b111_010_000: wdata = 1'b1;
			9'b111_010_001: wdata = 1'b0;
			9'b111_010_010: wdata = 1'b0;
			9'b111_010_011: wdata = 1'b0;
			9'b111_010_100: wdata = 1'b0;
			9'b111_010_101: wdata = 1'b0;
			9'b111_010_110: wdata = 1'b0;
			9'b111_010_111: wdata = 1'b0;
			9'b111_011_000: wdata = 1'b0;
			9'b111_011_001: wdata = 1'b0;
			9'b111_011_010: wdata = 1'b0;
			9'b111_011_011: wdata = 1'b0;
			9'b111_011_100: wdata = 1'b0;
			9'b111_011_101: wdata = 1'b0;
			9'b111_011_110: wdata = 1'b0;
			9'b111_011_111: wdata = 1'b0;
			9'b111_100_000: wdata = 1'b0;
			9'b111_100_001: wdata = 1'b0;
			9'b111_100_010: wdata = 1'b0;
			9'b111_100_011: wdata = 1'b0;
			9'b111_100_100: wdata = 1'b0;
			9'b111_100_101: wdata = 1'b0;
			9'b111_100_110: wdata = 1'b0;
			9'b111_100_111: wdata = 1'b0;
			9'b111_101_000: wdata = 1'b0;
			9'b111_101_001: wdata = 1'b0;
			9'b111_101_010: wdata = 1'b0;
			9'b111_101_011: wdata = 1'b0;
			9'b111_101_100: wdata = 1'b0;
			9'b111_101_101: wdata = 1'b0;
			9'b111_101_110: wdata = 1'b0;
			9'b111_101_111: wdata = 1'b0;
			9'b111_110_000: wdata = 1'b0;
			9'b111_110_001: wdata = 1'b0;
			9'b111_110_010: wdata = 1'b0;
			9'b111_110_011: wdata = 1'b0;
			9'b111_110_100: wdata = 1'b0;
			9'b111_110_101: wdata = 1'b0;
			9'b111_110_110: wdata = 1'b0;
			9'b111_110_111: wdata = 1'b0;
			9'b111_111_000: wdata = 1'b0;
			9'b111_111_001: wdata = 1'b0;
			9'b111_111_010: wdata = 1'b0;
			9'b111_111_011: wdata = 1'b0;
			9'b111_111_100: wdata = 1'b0;
			9'b111_111_101: wdata = 1'b0;
			9'b111_111_110: wdata = 1'b0;
			9'b111_111_111: wdata = 1'b0;
		endcase
	end

	always @(posedge clk) begin
		divide = divide + 1'd1;		
		if(divide >= 32'd50_000_000) begin
			blink <= ~blink;
			divide = 0;
		end
		case(dip[4] ? divide[2:1] : divide[10:9])
			2'b00: begin write_en <= 0; addr_clk <= 1; end
			2'b01: begin addr_clk <= 0; shift_clk <= 1; end
			2'b10: begin shift_clk <= 0; rule_clk <= 1; end
			2'b11: begin rule_clk <= 0; write_en <= 1; end
		endcase
	end
	
endmodule