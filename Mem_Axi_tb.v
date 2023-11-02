`timescale 1ns/1ns
module Mem_Axi_tb #(
	parameter	DATA_WIDTH = 32,
	parameter	ADDR_WIDTH = 8,
	parameter	STRB_WIDTH = DATA_WIDTH/8
)();

reg	i_clk = 1 'b0, i_rst = 1'b0;

// AW channel
reg	[7:0]	i_awaddr, i_awlen;
reg	[2:0]	i_awsize;
reg	[1:0]	i_awburst;
reg		 	i_awvalid;
wire	 	o_awready;

// W channel
reg	[31:0]	i_wdata;
reg	[3:0]	i_wstrb;
reg			i_wvalid;
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
			i_awaddr = 8'b00000011;
			i_awlen	= 8'h02;
			i_awsize = 3'b010;
			i_awburst = 2'b01;
			i_awvalid = 1'b1;
			i_wvalid = 1'b1;
			i_wstrb = 4'b1111;
			i_wdata = 32'd1000;
			i_bready = 1'b0;
		
		#40

			i_araddr = 8'b00000011;
			i_arvalid = 1'b1;
			i_arlen	= 8'h02;
			i_arsize = 3'b010;
			i_arburst = 2'b00;
			i_rready = 1'b1;
			
		
		#30
			i_rready = 1'b0;
			
		#20
			i_rready = 1'b1;
			i_wdata = 32'd2000;
			
			
		#100
			i_bready = 1'b1;
			i_rready = 1'b0;
		
		#40
			i_rready = 1'b1;
		
/* 		#40 
			i_awvalid = 1'b0;
			i_wstrb = 4'b1001;

			i_wdata = 32'b00101100011011011011100001101100;
			i_bready = 1'b1;
		
		#40 
			i_wstrb = 4'b0110;
			i_wdata = 32'b00101100011011011011100001101100;
		
		 */
				
		
/* 		#50
			i_araddr = 8'b00000111;
		 */
		#50
			i_wdata = 32'd5000;
		#200
		
		$stop;
	end
	
	Mem_Slave DUT (
	.clk(i_clk),
	.rst(i_rst),
	.aw_addr(i_awaddr),
	.aw_len(i_awlen),	
	.aw_size(i_awsize),	
	.aw_burst(i_awburst),
	.aw_valid(i_awvalid),
	.aw_ready(o_awready),
	.w_data(i_wdata),
	.w_valid(i_wvalid),
	.w_strb(i_wstrb),
	.w_ready(o_wready),
	.b_resp(o_bresp),
	.b_valid(o_bvalid),
	.b_ready(i_bready),
	.ar_addr(i_araddr),
	.ar_len(i_arlen),
    .ar_size(i_arsize),
    .ar_burst(i_arburst),
	.ar_valid(i_arvalid),
	.ar_ready(o_arready),
	.r_data(o_rdata),
	.r_resp(o_rresp),
	.r_last(o_rlast),
	.r_valid(o_rvalid),
	.r_ready(i_rready)
	);
endmodule
