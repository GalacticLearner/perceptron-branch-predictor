`timescale 1ns/1ns
`define PERIOD1 100
`define MEMORY_SIZE 256	//	size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16	//	instead of 2^16 words to reduce memory
			//	requirements in the Active-HDL simulator 

module Memory(clk, reset_n, readM1, address1, data1, readM2, writeM2, address2, data2);
	input clk;
	wire clk;
	input reset_n;
	wire reset_n;
	
	input readM1;
	wire readM1;
	input [`WORD_SIZE-1:0] address1;
	wire [`WORD_SIZE-1:0] address1;
	output [`WORD_SIZE-1:0] data1;
	wire [`WORD_SIZE-1:0] data1;
	
	input readM2;
	wire readM2;
	input writeM2;
	wire writeM2;
	input [`WORD_SIZE-1:0] address2;
	wire [`WORD_SIZE-1:0] address2;
	inout [`WORD_SIZE-1:0] data2;
	wire [`WORD_SIZE-1:0] data2;
	
	reg [`WORD_SIZE-1:0] memory [0:`MEMORY_SIZE-1];
	reg [`WORD_SIZE-1:0] outputData2;
	integer i;
	
	assign data2 = readM2?outputData2:`WORD_SIZE'bz;
	assign data1 = readM1 ? ((writeM2 & address1==address2) ? data2 : memory[address1]) : `WORD_SIZE'bz;
	
	initial begin
		// Initialize all to zero first
		for (i = 0; i < `MEMORY_SIZE; i = i + 1)
			memory[i] = 16'h0000;
		// Load test program starting at address 0
		memory[16'h0] = 16'h6000; memory[16'h1] = 16'hf01c; memory[16'h2] = 16'h6100; memory[16'h3] = 16'hf41c;
		memory[16'h4] = 16'h6200; memory[16'h5] = 16'hf81c; memory[16'h6] = 16'h6300; memory[16'h7] = 16'hfc1c;
		memory[16'h8] = 16'h4401; memory[16'h9] = 16'hf01c; memory[16'ha] = 16'h4001; memory[16'hb] = 16'hf01c;
		memory[16'hc] = 16'h5901; memory[16'hd] = 16'hf41c; memory[16'he] = 16'h5502; memory[16'hf] = 16'hf41c;
		memory[16'h10] = 16'h5503; memory[16'h11] = 16'hf41c; memory[16'h12] = 16'hf2c0; memory[16'h13] = 16'hfc1c;
		memory[16'h14] = 16'hf6c0; memory[16'h15] = 16'hfc1c; memory[16'h16] = 16'hf1c0; memory[16'h17] = 16'hfc1c;
		memory[16'h18] = 16'hf2c1; memory[16'h19] = 16'hfc1c; memory[16'h1a] = 16'hf8c1; memory[16'h1b] = 16'hfc1c;
		memory[16'h1c] = 16'hf6c1; memory[16'h1d] = 16'hfc1c; memory[16'h1e] = 16'hf9c1; memory[16'h1f] = 16'hfc1c;
		memory[16'h20] = 16'hf1c1; memory[16'h21] = 16'hfc1c; memory[16'h22] = 16'hf4c1; memory[16'h23] = 16'hfc1c;
	end
	
	always@(posedge clk) begin
		if(readM2) outputData2 <= memory[address2];
		if(writeM2) memory[address2] <= data2;
	end
endmodule