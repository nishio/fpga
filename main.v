`define WIDTH = 160;
`define HEIGHT = 120;
`define VRAM_SIZE = WIDTH * HEIGHT;

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

module DE0etude(switch, led, dip, hsync, vsync, rgb, clk);
	input [2:0] switch;
	input [9:0] dip;
	output [9:0] led;
	input clk;
	output hsync, vsync;
   output [2:0] rgb;

	// 160x120 bits RAM
	Cells	cells (
		.clock ( clk ),
		.data ( 
			wdata & ~no_output | force_output 
			| (~switch[2] & (write_addr == 9680 | write_addr == 9681 | write_addr == 9841 | write_addr == 9842 | write_addr == 10001))),
		.rdaddress ( read_addr ),
		.wraddress ( write_addr ),
		.wren ( write_en ),
		.q ( cell_q )
	);
	wire cell_q;
	reg [19:0] write_addr;
	reg [19:0] read_addr;
	reg wdata, write_en;
	wire rdata;
	wire no_output = dip[1];
	wire force_output = dip[2];
	VGA vga_module(
		clk, rgb, hsync, vsync, 
		write_addr, 
		( 
			wdata & ~no_output | force_output 
			| (~switch[2] & (write_addr == 9680 | write_addr == 9681 | write_addr == 9841 | write_addr == 9842 | write_addr == 10001))),
		write_en, ~switch[0]);
	reg [31:0] divide;
	reg shift_clk, rule_clk, addr_clk;
	reg blink, blink2;
	assign led[0] = blink;
	assign led[1] = blink2;
	
	always @(posedge addr_clk) begin
		read_addr = read_addr + 1'b1;
		write_addr = write_addr + 1'b1;
		if(read_addr > 160 * 120) begin
			blink2 = 1;
			read_addr = 0;
		end
		if(read_addr < 322) begin
			write_addr = 0;
		end else if(read_addr == 322) begin
			blink2 = 0;
			write_addr = 161;
		end
	end
	
	

	
	reg [322:0]buffer;
	always @(posedge shift_clk) begin
		buffer[0] <= cell_q;
		buffer[1] <= buffer[0];
		buffer[2] <= buffer[1];
		buffer[3] <= buffer[2];
		buffer[4] <= buffer[3];
		buffer[5] <= buffer[4];
		buffer[6] <= buffer[5];
		buffer[7] <= buffer[6];
		buffer[8] <= buffer[7];
		buffer[9] <= buffer[8];
		buffer[10] <= buffer[9];
		buffer[11] <= buffer[10];
		buffer[12] <= buffer[11];
		buffer[13] <= buffer[12];
		buffer[14] <= buffer[13];
		buffer[15] <= buffer[14];
		buffer[16] <= buffer[15];
		buffer[17] <= buffer[16];
		buffer[18] <= buffer[17];
		buffer[19] <= buffer[18];
		buffer[20] <= buffer[19];
		buffer[21] <= buffer[20];
		buffer[22] <= buffer[21];
		buffer[23] <= buffer[22];
		buffer[24] <= buffer[23];
		buffer[25] <= buffer[24];
		buffer[26] <= buffer[25];
		buffer[27] <= buffer[26];
		buffer[28] <= buffer[27];
		buffer[29] <= buffer[28];
		buffer[30] <= buffer[29];
		buffer[31] <= buffer[30];
		buffer[32] <= buffer[31];
		buffer[33] <= buffer[32];
		buffer[34] <= buffer[33];
		buffer[35] <= buffer[34];
		buffer[36] <= buffer[35];
		buffer[37] <= buffer[36];
		buffer[38] <= buffer[37];
		buffer[39] <= buffer[38];
		buffer[40] <= buffer[39];
		buffer[41] <= buffer[40];
		buffer[42] <= buffer[41];
		buffer[43] <= buffer[42];
		buffer[44] <= buffer[43];
		buffer[45] <= buffer[44];
		buffer[46] <= buffer[45];
		buffer[47] <= buffer[46];
		buffer[48] <= buffer[47];
		buffer[49] <= buffer[48];
		buffer[50] <= buffer[49];
		buffer[51] <= buffer[50];
		buffer[52] <= buffer[51];
		buffer[53] <= buffer[52];
		buffer[54] <= buffer[53];
		buffer[55] <= buffer[54];
		buffer[56] <= buffer[55];
		buffer[57] <= buffer[56];
		buffer[58] <= buffer[57];
		buffer[59] <= buffer[58];
		buffer[60] <= buffer[59];
		buffer[61] <= buffer[60];
		buffer[62] <= buffer[61];
		buffer[63] <= buffer[62];
		buffer[64] <= buffer[63];
		buffer[65] <= buffer[64];
		buffer[66] <= buffer[65];
		buffer[67] <= buffer[66];
		buffer[68] <= buffer[67];
		buffer[69] <= buffer[68];
		buffer[70] <= buffer[69];
		buffer[71] <= buffer[70];
		buffer[72] <= buffer[71];
		buffer[73] <= buffer[72];
		buffer[74] <= buffer[73];
		buffer[75] <= buffer[74];
		buffer[76] <= buffer[75];
		buffer[77] <= buffer[76];
		buffer[78] <= buffer[77];
		buffer[79] <= buffer[78];
		buffer[80] <= buffer[79];
		buffer[81] <= buffer[80];
		buffer[82] <= buffer[81];
		buffer[83] <= buffer[82];
		buffer[84] <= buffer[83];
		buffer[85] <= buffer[84];
		buffer[86] <= buffer[85];
		buffer[87] <= buffer[86];
		buffer[88] <= buffer[87];
		buffer[89] <= buffer[88];
		buffer[90] <= buffer[89];
		buffer[91] <= buffer[90];
		buffer[92] <= buffer[91];
		buffer[93] <= buffer[92];
		buffer[94] <= buffer[93];
		buffer[95] <= buffer[94];
		buffer[96] <= buffer[95];
		buffer[97] <= buffer[96];
		buffer[98] <= buffer[97];
		buffer[99] <= buffer[98];
		buffer[100] <= buffer[99];
		buffer[101] <= buffer[100];
		buffer[102] <= buffer[101];
		buffer[103] <= buffer[102];
		buffer[104] <= buffer[103];
		buffer[105] <= buffer[104];
		buffer[106] <= buffer[105];
		buffer[107] <= buffer[106];
		buffer[108] <= buffer[107];
		buffer[109] <= buffer[108];
		buffer[110] <= buffer[109];
		buffer[111] <= buffer[110];
		buffer[112] <= buffer[111];
		buffer[113] <= buffer[112];
		buffer[114] <= buffer[113];
		buffer[115] <= buffer[114];
		buffer[116] <= buffer[115];
		buffer[117] <= buffer[116];
		buffer[118] <= buffer[117];
		buffer[119] <= buffer[118];
		buffer[120] <= buffer[119];
		buffer[121] <= buffer[120];
		buffer[122] <= buffer[121];
		buffer[123] <= buffer[122];
		buffer[124] <= buffer[123];
		buffer[125] <= buffer[124];
		buffer[126] <= buffer[125];
		buffer[127] <= buffer[126];
		buffer[128] <= buffer[127];
		buffer[129] <= buffer[128];
		buffer[130] <= buffer[129];
		buffer[131] <= buffer[130];
		buffer[132] <= buffer[131];
		buffer[133] <= buffer[132];
		buffer[134] <= buffer[133];
		buffer[135] <= buffer[134];
		buffer[136] <= buffer[135];
		buffer[137] <= buffer[136];
		buffer[138] <= buffer[137];
		buffer[139] <= buffer[138];
		buffer[140] <= buffer[139];
		buffer[141] <= buffer[140];
		buffer[142] <= buffer[141];
		buffer[143] <= buffer[142];
		buffer[144] <= buffer[143];
		buffer[145] <= buffer[144];
		buffer[146] <= buffer[145];
		buffer[147] <= buffer[146];
		buffer[148] <= buffer[147];
		buffer[149] <= buffer[148];
		buffer[150] <= buffer[149];
		buffer[151] <= buffer[150];
		buffer[152] <= buffer[151];
		buffer[153] <= buffer[152];
		buffer[154] <= buffer[153];
		buffer[155] <= buffer[154];
		buffer[156] <= buffer[155];
		buffer[157] <= buffer[156];
		buffer[158] <= buffer[157];
		buffer[159] <= buffer[158];
		buffer[160] <= buffer[159];
		buffer[161] <= buffer[160];
		buffer[162] <= buffer[161];
		buffer[163] <= buffer[162];
		buffer[164] <= buffer[163];
		buffer[165] <= buffer[164];
		buffer[166] <= buffer[165];
		buffer[167] <= buffer[166];
		buffer[168] <= buffer[167];
		buffer[169] <= buffer[168];
		buffer[170] <= buffer[169];
		buffer[171] <= buffer[170];
		buffer[172] <= buffer[171];
		buffer[173] <= buffer[172];
		buffer[174] <= buffer[173];
		buffer[175] <= buffer[174];
		buffer[176] <= buffer[175];
		buffer[177] <= buffer[176];
		buffer[178] <= buffer[177];
		buffer[179] <= buffer[178];
		buffer[180] <= buffer[179];
		buffer[181] <= buffer[180];
		buffer[182] <= buffer[181];
		buffer[183] <= buffer[182];
		buffer[184] <= buffer[183];
		buffer[185] <= buffer[184];
		buffer[186] <= buffer[185];
		buffer[187] <= buffer[186];
		buffer[188] <= buffer[187];
		buffer[189] <= buffer[188];
		buffer[190] <= buffer[189];
		buffer[191] <= buffer[190];
		buffer[192] <= buffer[191];
		buffer[193] <= buffer[192];
		buffer[194] <= buffer[193];
		buffer[195] <= buffer[194];
		buffer[196] <= buffer[195];
		buffer[197] <= buffer[196];
		buffer[198] <= buffer[197];
		buffer[199] <= buffer[198];
		buffer[200] <= buffer[199];
		buffer[201] <= buffer[200];
		buffer[202] <= buffer[201];
		buffer[203] <= buffer[202];
		buffer[204] <= buffer[203];
		buffer[205] <= buffer[204];
		buffer[206] <= buffer[205];
		buffer[207] <= buffer[206];
		buffer[208] <= buffer[207];
		buffer[209] <= buffer[208];
		buffer[210] <= buffer[209];
		buffer[211] <= buffer[210];
		buffer[212] <= buffer[211];
		buffer[213] <= buffer[212];
		buffer[214] <= buffer[213];
		buffer[215] <= buffer[214];
		buffer[216] <= buffer[215];
		buffer[217] <= buffer[216];
		buffer[218] <= buffer[217];
		buffer[219] <= buffer[218];
		buffer[220] <= buffer[219];
		buffer[221] <= buffer[220];
		buffer[222] <= buffer[221];
		buffer[223] <= buffer[222];
		buffer[224] <= buffer[223];
		buffer[225] <= buffer[224];
		buffer[226] <= buffer[225];
		buffer[227] <= buffer[226];
		buffer[228] <= buffer[227];
		buffer[229] <= buffer[228];
		buffer[230] <= buffer[229];
		buffer[231] <= buffer[230];
		buffer[232] <= buffer[231];
		buffer[233] <= buffer[232];
		buffer[234] <= buffer[233];
		buffer[235] <= buffer[234];
		buffer[236] <= buffer[235];
		buffer[237] <= buffer[236];
		buffer[238] <= buffer[237];
		buffer[239] <= buffer[238];
		buffer[240] <= buffer[239];
		buffer[241] <= buffer[240];
		buffer[242] <= buffer[241];
		buffer[243] <= buffer[242];
		buffer[244] <= buffer[243];
		buffer[245] <= buffer[244];
		buffer[246] <= buffer[245];
		buffer[247] <= buffer[246];
		buffer[248] <= buffer[247];
		buffer[249] <= buffer[248];
		buffer[250] <= buffer[249];
		buffer[251] <= buffer[250];
		buffer[252] <= buffer[251];
		buffer[253] <= buffer[252];
		buffer[254] <= buffer[253];
		buffer[255] <= buffer[254];
		buffer[256] <= buffer[255];
		buffer[257] <= buffer[256];
		buffer[258] <= buffer[257];
		buffer[259] <= buffer[258];
		buffer[260] <= buffer[259];
		buffer[261] <= buffer[260];
		buffer[262] <= buffer[261];
		buffer[263] <= buffer[262];
		buffer[264] <= buffer[263];
		buffer[265] <= buffer[264];
		buffer[266] <= buffer[265];
		buffer[267] <= buffer[266];
		buffer[268] <= buffer[267];
		buffer[269] <= buffer[268];
		buffer[270] <= buffer[269];
		buffer[271] <= buffer[270];
		buffer[272] <= buffer[271];
		buffer[273] <= buffer[272];
		buffer[274] <= buffer[273];
		buffer[275] <= buffer[274];
		buffer[276] <= buffer[275];
		buffer[277] <= buffer[276];
		buffer[278] <= buffer[277];
		buffer[279] <= buffer[278];
		buffer[280] <= buffer[279];
		buffer[281] <= buffer[280];
		buffer[282] <= buffer[281];
		buffer[283] <= buffer[282];
		buffer[284] <= buffer[283];
		buffer[285] <= buffer[284];
		buffer[286] <= buffer[285];
		buffer[287] <= buffer[286];
		buffer[288] <= buffer[287];
		buffer[289] <= buffer[288];
		buffer[290] <= buffer[289];
		buffer[291] <= buffer[290];
		buffer[292] <= buffer[291];
		buffer[293] <= buffer[292];
		buffer[294] <= buffer[293];
		buffer[295] <= buffer[294];
		buffer[296] <= buffer[295];
		buffer[297] <= buffer[296];
		buffer[298] <= buffer[297];
		buffer[299] <= buffer[298];
		buffer[300] <= buffer[299];
		buffer[301] <= buffer[300];
		buffer[302] <= buffer[301];
		buffer[303] <= buffer[302];
		buffer[304] <= buffer[303];
		buffer[305] <= buffer[304];
		buffer[306] <= buffer[305];
		buffer[307] <= buffer[306];
		buffer[308] <= buffer[307];
		buffer[309] <= buffer[308];
		buffer[310] <= buffer[309];
		buffer[311] <= buffer[310];
		buffer[312] <= buffer[311];
		buffer[313] <= buffer[312];
		buffer[314] <= buffer[313];
		buffer[315] <= buffer[314];
		buffer[316] <= buffer[315];
		buffer[317] <= buffer[316];
		buffer[318] <= buffer[317];
		buffer[319] <= buffer[318];
		buffer[320] <= buffer[319];
		buffer[321] <= buffer[320];
		buffer[322] <= buffer[321];
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