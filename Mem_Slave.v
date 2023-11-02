module Mem_Slave #(
	parameter	ADDR_WIDTH = 8,
	parameter	DATA_WIDTH = 32,
	parameter	STRB_WIDTH = DATA_WIDTH/8
)
(
	//global signals
	input	wire			clk,
	input	wire			rst,
	
	//AW channel signals
	input	wire							aw_valid,
	input	wire	[7:0]					aw_len,
	input	wire	[2:0]					aw_size,
	input	wire	[1:0]					aw_burst,
	input	wire	[ADDR_WIDTH - 1 : 0]	aw_addr,
	output	wire							aw_ready,
	
	//W channel signals
	input	wire	[DATA_WIDTH - 1 : 0]	w_data,
	input	wire							w_valid,
	input	wire	[STRB_WIDTH - 1 : 0]	w_strb,
	output	wire							w_ready,
	
	//B channel signals
	input	wire							b_ready,
	output	wire	[1:0]					b_resp,
	output	wire							b_valid,
	
	//AR channel signals
	input	wire	[ADDR_WIDTH - 1 : 0]	ar_addr,
	input	wire	[7:0]					ar_len,
	input	wire	[2:0]					ar_size,
	input	wire	[1:0]					ar_burst,
	input	wire							ar_valid,
	output	wire							ar_ready,
	
	//R channel signals
	output	wire	[DATA_WIDTH - 1 : 0]	r_data,
	output	wire							r_valid,
	output	wire	[1:0]					r_resp,
	output	wire							r_last,
	input	wire							r_ready
);
	//Cac trang thai cua Write Transaction
	localparam	[1:0]	STW_IDLE = 2'b00, 
						STW_RUN  = 2'b01, 
						STW_RESP = 2'b10;
	reg	[1:0] stateW = STW_IDLE, stateW_next;
	
	//Cac trang thai cua Read Transaction
	localparam	[0:0]	STR_IDLE = 1'b0,
						STR_RUN	 = 1'b1;
	reg	[0:0] stateR = STR_IDLE, stateR_next;
	
	reg	mem_rd_en, mem_wr_en;
	
	//Cac thanh ghi luu tru trang thai hien tai va trang thai tiep theo tu input nhan vao
	reg	aw_ready_reg = 1'b0, aw_ready_reg_next;
	reg	w_ready_reg = 1'b0, w_ready_reg_next;
	reg	b_valid_reg = 1'b0, b_valid_reg_next;
	reg	[1:0] b_resp_reg = 2'bxx, b_resp_reg_next;
	
	reg	ar_ready_reg = 1'b0, ar_ready_reg_next;
	reg	r_valid_reg = 1'b0, r_valid_reg_next;
	reg	r_last_reg = 1'b0, r_last_reg_next;
	reg	[1:0] r_resp_reg = 2'bxx, r_resp_reg_next;
	
	//Cac thanh ghi can chu y de xu ly
	//Write transaction
	reg	[ADDR_WIDTH - 1 : 0] write_addr = {ADDR_WIDTH{1'b0}}, write_addr_next;
	//So transfer/beat = AxLen + 1
	reg	[7:0]	write_count = 8'd0, write_count_next; //dem so beat/transfer con lai can phai ghi
	reg	[2:0]	write_size = 3'd0, write_size_next;
	reg	[1:0]	write_burst = 2'b00, write_burst_next;
	
	
	//Read transaction
	reg	[ADDR_WIDTH - 1 : 0] read_addr = {ADDR_WIDTH{1'b0}}, read_addr_next;
	reg	[7:0]	read_count = 8'd0, read_count_next;
	reg	[2:0]	read_size = 3'd0, read_size_next;
	reg	[1:0]	read_burst = 2'b00, read_burst_next;
	
	assign	aw_ready = aw_ready_reg;
	assign	w_ready = w_ready_reg;
	assign	b_resp = b_resp_reg;
	assign	b_valid = b_valid_reg;
	
	assign	ar_ready = ar_ready_reg;
	assign	r_valid = r_valid_reg;
	assign	r_last = r_last_reg;
	assign	r_resp = r_resp_reg;
	
//2 Khoi always cho Write Transaction
	//Khoi always de tinh toan trang thai tiep theo
	always	@* begin
		mem_wr_en <= 1'b0;
		
		write_addr_next <= write_addr;	//*
		write_count_next <= write_count;	//*
		write_size_next <= write_size;	//*
		write_burst_next <= write_burst;	//*
		
		stateW_next <= (write_count > 0) ? stateW : STR_IDLE;
		
		aw_ready_reg_next <= 1'b0;
		w_ready_reg_next <= 1'b0;
		b_valid_reg_next <= b_valid_reg && !b_ready;
		b_resp_reg_next <= 2'bxx;
		case(stateW)
			//Kenh AW khoi tao gia tri de chuan bi cho kenh W
			STW_IDLE: begin
				aw_ready_reg_next <= 1'b1;
				if(aw_ready && aw_valid) begin
					write_burst_next <= aw_burst;
					write_count_next <= aw_len; 
					write_addr_next	 <= aw_addr;
					write_size_next	 <= aw_size < $clog2(STRB_WIDTH) ? aw_size : $clog2(STRB_WIDTH);
					
					aw_ready_reg_next <= 1'b0;
					w_ready_reg_next <= 1'b1;
					stateW_next <= STW_RUN;
				end else begin
					stateW_next <= STW_IDLE;
				end
			end
			
			//Kenh W thuc hien tinh toan dia chi o day
			STW_RUN: begin
				w_ready_reg_next <= 1'b1;

				if(w_ready && w_valid) begin
					mem_wr_en <= 1'b1;
					
					write_addr_next <= get_next_addr(write_addr, write_burst, write_size);
					
					write_count_next <= write_count - 1;
									
					if(write_count > 0) begin
						stateW_next <= STW_RUN;
					end else begin
						w_ready_reg_next <= 1'b0;
						b_valid_reg_next <= 1'b1;
						stateW_next <= STW_RESP;
					end
				end else stateW_next <= STW_RUN;
			end
			
			//Kenh B
			STW_RESP: begin
				if(b_ready && b_valid) begin
					b_resp_reg_next <= 2'b00;
					b_valid_reg_next <= 1'b0;
					aw_ready_reg_next <= 1'b1;
					stateW_next <= STW_IDLE;
				end else begin
					b_valid_reg_next <= 1'b1;
					stateW_next <= STW_RESP;
				end
			end
		endcase
	end 
	
	//Khoi always de chuyen trang thai
	always @(posedge clk) begin
		
		stateW <= stateW_next;
		
		aw_ready_reg <= aw_ready_reg_next;
		w_ready_reg <= w_ready_reg_next;
		b_valid_reg <= b_valid_reg_next;
		b_resp_reg <= b_resp_reg_next;
		
		write_addr <= write_addr_next;
		write_burst <= write_burst_next;
		write_count <= write_count_next;
		write_size <= write_size_next;
		
		if(rst) begin
			stateW <= STW_IDLE;
			aw_ready_reg <= 1'b0;
			w_ready_reg <= 1'b0;
			b_valid_reg <= 1'b0;
		end
	end

//2 Khoi always cho Read Transaction
	//Khoi always de tinh toan trang thai tiep theo
	always @* begin
		mem_rd_en <= 1'b0;
		
		read_addr_next <= read_addr;
		read_burst_next <= read_burst;
		read_count_next <= read_count;
		read_size_next <= read_size;
		
		stateR_next <= (read_count > 0) ? stateR : STR_IDLE;
		
		ar_ready_reg_next <= 1'b0;
		r_valid_reg_next <=	r_valid_reg && !r_ready;
		r_resp_reg_next <= 2'bxx;
		r_last_reg_next <= 1'b0;
		
		case(stateR) 
			//Kenh AR hoat dong - Khoi tao transaction bang cach gan cac tin hieu can xu ly
			STR_IDLE: begin
				ar_ready_reg_next <= 1'b1;
				if(ar_ready && ar_valid) begin
					read_addr_next <= ar_addr;
					read_count_next <= ar_len;
					read_size_next <= (ar_size < $clog2(STRB_WIDTH)) ? ar_size : $clog2(STRB_WIDTH);
					read_burst_next <= ar_burst;
					
					ar_ready_reg_next <= 1'b0;
					r_valid_reg_next <= 1'b1;
					stateR_next <= STR_RUN;
				end
			end
			
			//Kenh R hoat dong - Tinh toan dia chi va so luong beat con lai 
			STR_RUN: begin
				if(r_valid && r_ready) begin
					mem_rd_en <= 1'b1;
					r_last_reg_next <= read_count == 0;
					
					read_addr_next <= get_next_addr(read_addr, read_burst, read_size);
					
					read_count_next <= read_count - 1'b1;
					r_resp_reg_next <= 2'b00;
					if(read_count > 0) begin
						r_valid_reg_next <= 1'b1;
						stateR_next <= STR_RUN;
					end else begin
						r_valid_reg_next <= 1'b0;
						ar_ready_reg_next <= 1'b1;
						stateR_next <= STR_IDLE;
					end
				end else stateR_next <= STR_RUN;
			end
		endcase
	end

	//Khoi always thuc hien chuyen trang thai
	always @(posedge clk) begin
		stateR <= stateR_next;
		
		read_addr <= read_addr_next;
		read_burst <= read_burst_next;
		read_size <= read_size_next;
		read_count <= read_count_next;
		
		ar_ready_reg <= ar_ready_reg_next;
		r_last_reg <= r_last_reg_next;
		r_valid_reg <= r_valid_reg_next;
		r_resp_reg <= r_resp_reg_next;
		
		if(rst) begin
			stateR <= STR_IDLE;
			ar_ready_reg <= 1'b0;
			r_valid_reg <= 1'b0;
		end
	
	end

	Mem m
	(
	.clk(clk),
	.rst(rst),
	.wr(mem_wr_en),
	.rd(mem_rd_en),
	.cs(1'b1),
	.wr_addr(write_addr),
	.rd_addr(read_addr),
	.be(w_strb),
	.wr_data(w_data),
	.rd_data(r_data)
	);

	function [ADDR_WIDTH - 1 : 0] get_next_addr;
	input	[ADDR_WIDTH-1:0] addr;
	input	[1:0]	burst;
	input	[2:0]	size;
	begin
		case (burst)
			2'b00: get_next_addr = addr;
			2'b01: get_next_addr = addr + (1 << size);
			2'b10: begin
			end
			2'b11: begin
				get_next_addr = addr;
				$display($time,,"%m ERROR un-defined BURST %01x", burst);
			end
		endcase
	end
	endfunction
	
endmodule

//Nhung dac trung cua AXI so voi cac protocol khac
//Gui data truoc, gui dia chi sau
//Tim hieu them ID
//Bao cao ve dang song cho tung kenh AW, W, B || AR, R
//Ve mach cua code tren 