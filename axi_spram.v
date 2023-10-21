//memory ram single port 256*32bits
//
module axi_spram
#(
	//do rong duong bus
	parameter	DATA_WIDTH = 32,
	//do rong dia chi duong bus
	parameter	ADDR_WIDTH = 8,
	//So bit tin hieu WSTRB
	parameter	STRB_WIDTH = DATA_WIDTH/8
)
(
	//global signals
	input 	wire							clk,
	input 	wire							Reset_n,
	
	//AW channel signals
	input 	wire	[ADDR_WIDTH - 1: 0]		s_awaddr,
	input	wire	[7:0]					s_awlen,	//So beats trong 1 burst
	input	wire	[2:0]					s_awsize,	//So byte toi da trong 1 beats. So byte nay phai < DATA_WIDTH
	input	wire	[1:0]					s_awburst,
	input	wire							s_awvalid,
	output	wire							s_awready,
	
	//W channel signals
	input	wire	[DATA_WIDTH - 1: 0]		s_wdata,
	input	wire							s_wvalid,
	input	wire	[STRB_WIDTH - 1: 0]		s_wstrb,
	input	wire							s_wlast,
	output	wire							s_wready,
	
	//B channel signals
	output	wire	[1:0]					s_bresp,
	output	wire							s_bvalid,
	input	wire							s_bready,
	
	//AR channel signals
	input	wire	[ADDR_WIDTH - 1: 0]		s_araddr,
	input  	wire 	[7:0]             		s_arlen,
    input  	wire 	[2:0]             		s_arsize,
    input  	wire 	[1:0]             		s_arburst,
	input	wire							s_arvalid,
	output	wire							s_arready,
	
	//R channel	signals
	output	wire	[DATA_WIDTH - 1: 0]		s_rdata,
	output	wire	[1:0]					s_rresp,
	output 	wire                   			s_rlast,
	output	wire							s_rvalid,
	input	wire							s_rready
	
);
	parameter VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
	
	
	localparam [1:0]	STW_IDLE = 2'b00,
						STW_RUN	= 2'b01,
						STW_RESP = 2'b10;
						
	reg [1:0]	stateW = STW_IDLE, stateW_next;

	localparam	[0:0]	STR_IDLE = 1'b0,
						STR_RUN = 1'b1;
	reg	[0:0]	stateR = STR_IDLE, stateR_next;
	
	
	reg	[DATA_WIDTH - 1: 0]	mem [2**VALID_ADDR_WIDTH - 1: 0];
	reg	mem_wr_en, mem_rd_en;
	
	reg [ADDR_WIDTH - 1:0] read_addr = {ADDR_WIDTH{1'b0}}, read_addr_next;
	reg [7:0] read_count = 8'd0, read_count_next;
	reg [2:0] read_size = 3'd0, read_size_next;
	reg [1:0] read_burst = 2'd0, read_burst_next;

	reg [ADDR_WIDTH - 1:0] write_addr = {ADDR_WIDTH{1'b0}}, write_addr_next;
	reg [7:0] write_count = 8'd0, write_count_next;
	reg [2:0] write_size = 3'd0, write_size_next;
	reg [1:0] write_burst = 2'd0, write_burst_next;
	
	
	reg	s_awready_reg = 1'b0, s_awready_reg_next;
	reg	s_wready_reg = 1'b0, s_wready_reg_next;
	reg	s_bvalid_reg = 1'b0, s_bvalid_reg_next;
	reg	s_arready_reg = 1'b0, s_arready_reg_next;
	reg	s_rvalid_reg = 1'b0, s_rvalid_reg_next;
	reg	[DATA_WIDTH - 1:0]	s_rdata_reg = {DATA_WIDTH{1'b0}}, s_rdata_reg_next;
	reg s_rlast_reg = 1'b0, s_rlast_reg_next;
	
	wire [VALID_ADDR_WIDTH - 1:0] s_awaddr_valid = s_awaddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
	wire [VALID_ADDR_WIDTH - 1:0] s_araddr_valid = s_araddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
	wire [VALID_ADDR_WIDTH - 1:0] read_addr_valid = read_addr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
	wire [VALID_ADDR_WIDTH - 1:0] write_addr_valid = write_addr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);

	
	assign	s_awready = s_awready_reg;
	assign	s_wready = s_wready_reg;
	assign	s_bresp = 2'b00;
	assign	s_bvalid = s_bvalid_reg;
	assign	s_arready = s_arready_reg;
	assign	s_rdata = s_rdata_reg;
	assign	s_rresp = 2'b00;
	assign	s_rlast = s_rlast_reg;
	assign	s_rvalid = s_rvalid_reg;
	
	integer i, j;
	
	initial begin
    for (i = 0; i < 2**VALID_ADDR_WIDTH; i = i + 2**(VALID_ADDR_WIDTH/2)) begin
        for (j = i; j < i + 2**(VALID_ADDR_WIDTH/2); j = j + 1) begin
            mem[j] = 0;
        end
    end
end
	
	//write transaction
	always @* begin
		mem_wr_en = 1'b0;
		
		stateW_next = STW_IDLE;
		
		write_addr_next = write_addr;
		write_count_next = write_count;
		write_size_next = write_size;
		write_burst_next = write_burst;
	
		s_awready_reg_next = 1'b0;
		s_wready_reg_next = 1'b0;
		s_bvalid_reg_next = s_bvalid_reg && !s_bready;
		
		case (stateW)
			STW_IDLE: begin
				s_awready_reg_next = 1'b1;
				
				if(s_awready && s_awvalid) begin
					write_addr_next = s_awaddr;
					write_count_next = s_awlen;
					write_size_next = s_awsize < $clog2(DATA_WIDTH/8) ? s_awsize : $clog2(DATA_WIDTH/8);
					write_burst_next = s_awburst;
					
					s_awready_reg_next = 1'b0;
					s_wready_reg_next = 1'b1;
					stateW_next = STW_RUN;
				end else begin
					stateW_next = STW_IDLE;
				end
			end
			
			STW_RUN: begin
				s_wready_reg_next = 1'b1;
				if (s_wready && s_wvalid) begin
					mem_wr_en = 1'b1;
					if(write_burst == 2'b01) begin
						write_addr_next = write_addr + (1 << write_size);
					end else begin
						write_addr_next = write_addr;
					end
					write_count_next = write_count - 1;
					if(write_count > 0) begin
						stateW_next = STR_RUN;
					end else begin
						s_wready_reg_next = 1'b0;
						if(s_bready && !s_bvalid) begin
							s_bvalid_reg_next = 1'b1;
							s_awready_reg_next = 1'b1;
							stateW_next = STW_IDLE;
						end else begin
							stateW_next = STW_RESP;
						end
					end
				end else begin
					stateW_next = STW_RUN;
				end
			end
			STW_RESP: begin
				if(s_bready && !s_bvalid) begin
					s_bvalid_reg_next = 1'b1;
					s_awready_reg_next = 1'b1;
					stateW_next = STW_IDLE;
				end else begin
					stateW_next = STW_RESP;
					end
				end
		endcase
	end
	
 	always @(posedge clk or negedge Reset_n)
	begin
		stateW <= stateW_next;
		
		write_addr 	<= write_addr_next;
		write_count <= write_count_next;
		write_size 	<= write_size_next;
		write_burst <= write_burst_next;
		
		s_awready_reg 	<=	s_awready_reg_next;
		s_wready_reg 	<=	s_wready_reg_next;
		s_bvalid_reg 	<= 	s_bvalid_reg_next;
		
		//[start_bit +: width]
		//[start_bit -: width]
		//WSTRB[n] sẽ quản lý WDATA[(n*8)+7:(n*8)] với n = 0, 1, 2, 3, 4, ... 
		//[(i*8)+7:(i*8)] = [8*i +:8] 
		//[7:0] | [15:8] | [23:16]  1001
		for(i = 0; i < STRB_WIDTH; i = i + 1)
		begin
			if(mem_wr_en && s_wstrb[i])
				mem[write_addr_valid][8*i +:8] <= s_wdata[8*i +:8];
				
			if (!Reset_n) begin
				stateW <= STW_IDLE;

				s_awready_reg <= 1'b0;
				s_wready_reg <= 1'b0;
				s_bvalid_reg <= 1'b0;
			end
		end
	end
	
	//Read transaction
	always @* begin
		stateR_next = STR_IDLE;
		
		mem_rd_en = 1'b0;
		
		s_rlast_reg_next = s_rlast_reg;
		s_arready_reg_next = 1'b0;
		s_rvalid_reg_next = s_rvalid_reg && !s_rready;
		
		case(stateR)
			STR_IDLE: begin
				s_arready_reg_next = 1'b1;
				if(s_arvalid && s_arready)
				begin
					read_addr_next = s_araddr;
					read_count_next = s_arlen;
					read_size_next = s_arsize < $clog2(DATA_WIDTH/8) ? s_arsize : $clog2(DATA_WIDTH/8);
					read_burst_next = s_arburst;
					
					s_arready_reg_next = 1'b0;
					stateR_next = STR_RUN;
				end else begin
					stateR_next = STR_IDLE;
				end
			end
			STR_RUN: begin
				if(s_rready || !s_rvalid_reg) begin
					mem_rd_en = 1'b1;
					
					s_rvalid_reg_next = 1'b1;
					s_rlast_reg_next = read_count == 0;
					
					if(read_burst == 2'b01) begin
						read_addr_next = read_addr + (1 << read_size);
					end else begin
						read_addr_next = read_addr;
					end
					
					read_count_next = read_count - 1;
					if(read_count > 0) begin
						stateR_next = STR_RUN;
					end else begin
						s_arready_reg_next = 1'b1;
						stateR_next = STR_IDLE;
					end 
				end else begin
					stateR_next = STR_RUN;
				end
			end
		endcase
	end
	
	always @ (posedge clk or negedge Reset_n) begin
		
		stateR <= stateR_next;
		
		read_addr <= read_addr_next;
		read_count <= read_count_next;
		read_burst <= read_burst_next;
		read_size <= read_size_next;
		
		s_arready_reg <= s_arready_reg_next;
		s_rvalid_reg <= s_rvalid_reg_next;
		s_rlast_reg <= s_rlast_reg_next;
		
		if(mem_rd_en) begin
			s_rdata_reg <= mem [read_addr_valid];
		end
		
		if(!Reset_n) begin
			stateR <= STR_IDLE;
			
			s_arready_reg <= 1'b0;
			s_rvalid_reg <= 1'b0;
			s_rlast_reg <= 1'b0;
		end
	end 
endmodule