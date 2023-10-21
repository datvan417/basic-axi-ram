`timescale 1ns/1ns
module axi_spram_tb();

reg	i_clk = 1 'b0, i_rst = 1'b1;

// AW channel
reg	[7:0]	i_awaddr, i_awlen;
reg	[2:0]	i_awsize;
reg	[1:0]	i_awburst;
reg		 	i_awvalid;
wire	 	o_awready;

// W channel
reg	[31:0]	i_wdata;
reg	[3:0]	i_wstrb;
reg			i_wlast, i_wvalid;
wire		o_wready;

// B channel
wire [1:0]	o_bresp;
wire		o_bvalid;
reg			i_bready;

// AR channel
reg	[7:0]	i_araddr, i_arlen;
reg	[2:0]	i_arsize;
reg	[1:0]	i_arburst;
reg		 	i_arvalid;
wire	 	o_arready;

// R channel
wire [31:0]	o_rdata;
wire [1:0]	o_rresp;
wire		o_rlast, o_rvalid;
reg		i_rready;

always #10	i_clk = ~i_clk;

initial
	begin
		#10	i_awaddr = 8'b00000011;
			i_awlen	= 8'h02;
			i_awsize = 3'b010;
			i_awburst = 2'b01;
			i_awvalid = 1'b1;
			i_wvalid = 1'b1;
		
		#40 
			i_awvalid = 1'b0;
			i_wstrb = 4'b1001;

			i_wdata = 32'b00101100011011011011100001101100;
			i_bready = 1'b1;
		
		#40 
			i_wstrb = 4'b0110;
			i_wdata = 32'b00101100011011011011100001101100;
		
		
		#180
			i_araddr = 8'b00000011;
			i_arlen	= 8'h07;
			i_arsize = 3'b010;
			i_arburst = 2'b01;
			i_arvalid = 1'b1;
			i_rready = 1'b1;
			
		
		#120
		$stop;
	end

	memory_dpram DUT
	(
	.clk(i_clk),
	.Reset_n(i_rst),
	.s_awaddr(i_awaddr),
	.s_awlen(i_awlen),	
	.s_awsize(i_awsize),	
	.s_awburst(i_awburst),
	.s_awvalid(i_awvalid),
	.s_awready(o_awready),
	.s_wdata(i_wdata),
	.s_wvalid(i_wvalid),
	.s_wstrb(i_wstrb),
	.s_wlast(i_wlast),
	.s_wready(o_wready),
	.s_bresp(o_bresp),
	.s_bvalid(o_bvalid),
	.s_bready(i_bready),
	.s_araddr(i_araddr),
	.s_arlen(i_arlen),
    .s_arsize(i_arsize),
    .s_arburst(i_arburst),
	.s_arvalid(i_arvalid),
	.s_arready(o_arready),
	.s_rdata(o_rdata),
	.s_rresp(o_rresp),
	.s_rlast(o_rlast),
	.s_rvalid(o_rvalid),
	.s_rready(i_rready)
	);

endmodule