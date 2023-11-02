//
//Mem 256*32 bits
//
module Mem #(
	parameter	DATA_WIDTH = 32,
	parameter	ADDR_WIDTH = 8,
	parameter	STRB_WIDTH = DATA_WIDTH/8
)
(
	input	wire						clk,
	input	wire						rst,
	input	wire	[ADDR_WIDTH-1:0]	wr_addr,
	input	wire	[ADDR_WIDTH-1:0]	rd_addr,
	input	wire						wr,
	input	wire						rd,
	input	wire	[DATA_WIDTH-1:0]	wr_data,
	input	wire						cs,
	input	wire	[STRB_WIDTH-1:0]	be,
	output	reg 	[DATA_WIDTH-1:0]	rd_data		
);

	parameter VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
	reg	[DATA_WIDTH - 1 : 0] mem [2**ADDR_WIDTH - 1 : 0];
	integer i, j;
	
	initial begin
		for (i = 0; i < 2**VALID_ADDR_WIDTH; i = i + 2**(VALID_ADDR_WIDTH/2)) begin
			for (j = i; j < i + 2**(VALID_ADDR_WIDTH/2); j = j + 1) begin
				mem[j] = 0;
			end
		end
	end
	
	always @(posedge clk) begin
		if(cs & wr) begin
			for(i = 0; i < STRB_WIDTH; i = i + 1) begin
				if(be[i]) mem[wr_addr][8*i +: 8] <= wr_data[8*i +: 8];
			end
		end 
	end
	
	always @(posedge clk) begin
		if(cs & rd) begin
			rd_data <= mem[rd_addr];
		end else begin
			rd_data <= {DATA_WIDTH{1'bx}};
		end
	end
endmodule