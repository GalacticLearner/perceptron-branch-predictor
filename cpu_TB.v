`timescale 1ns/1ns
`define PERIOD1 100
`define WORD_SIZE 16

`define NUM_TEST 4
`define TESTID_SIZE 5

module cpu_TB();

    reg reset_n;
    reg clk;    

    wire readM1;
    wire [`WORD_SIZE-1:0] address1;
    wire [`WORD_SIZE-1:0] data1;
    wire readM2;
    wire writeM2;
    wire [`WORD_SIZE-1:0] address2;
    wire [`WORD_SIZE-1:0] data2;

    wire [`WORD_SIZE-1:0] num_inst;
    wire [`WORD_SIZE-1:0] output_port;
    wire is_halted;


    integer i;
    integer num_clock;

    cpu UUT (clk, reset_n, readM1, address1, data1, readM2, writeM2, address2, data2, num_inst, output_port, is_halted);
    Memory NUUT(clk, reset_n, readM1, address1, data1, readM2, writeM2, address2, data2);

    initial begin
        clk = 0;
        reset_n = 1;
        #(`PERIOD1/4) reset_n = 0;
        #(`PERIOD1 + `PERIOD1/2) reset_n = 1;
    end

    always #(`PERIOD1/2) clk = ~clk;

    initial begin
        #200;
        $monitor("T=%0t: ID(op=%h fn=%h) WB(op=%h fn=%h WF=%b) | WWD=%b out=%h | num=%h", 
            $time, UUT.ID_opCode, UUT.ID_funcCode,
            UUT.WB_opCode, UUT.WB_funcCode,
            UUT.WB_WriteFlag, UUT.WB_isWWD,
            output_port, num_inst);
    end

    event testbench_finish;
    initial #(`PERIOD1*10000) -> testbench_finish;

    reg [`TESTID_SIZE*8-1:0] TestID[`NUM_TEST-1:0];
    reg [`WORD_SIZE-1:0] TestNumInst [`NUM_TEST-1:0];
    reg [`WORD_SIZE-1:0] TestAns[`NUM_TEST-1:0];
    reg TestPassed[`NUM_TEST-1:0];

    // ✅ FIXED initial block
    initial begin
        TestID[0] = "1-1"; TestNumInst[0] = 16'h0003; TestAns[0] = 16'h0000; TestPassed[0] = 1'bx;
        TestID[1] = "1-2"; TestNumInst[1] = 16'h0005; TestAns[1] = 16'h0000; TestPassed[1] = 1'bx;
        TestID[2] = "1-3"; TestNumInst[2] = 16'h0007; TestAns[2] = 16'h0000; TestPassed[2] = 1'bx;
        TestID[3] = "1-4"; TestNumInst[3] = 16'h0009; TestAns[3] = 16'h0000; TestPassed[3] = 1'bx;
    end

    always @ (posedge clk) begin 
        if (reset_n == 1) begin
            num_clock <= num_clock + 1;

            for(i=0; i<`NUM_TEST; i=i+1) begin
                if (num_inst == TestNumInst[i]) begin
                    if (output_port == TestAns[i]) begin
                        TestPassed[i] <= 1'b1;
                    end
                    else begin
                        TestPassed[i] <= 1'b0;
                        $display("Test #%s has been failed!", TestID[i]);
                        $display("output_port = 0x%0x (Ans : 0x%0x)", output_port, TestAns[i]);
                        -> testbench_finish;
                    end
                end
            end

            if (is_halted == 1)
                -> testbench_finish;
        end
        else begin
            num_clock <= 0;
        end
    end                                            

    reg [`WORD_SIZE-1:0] Passed;

    initial begin
        Passed = 0;
    end

    always @(testbench_finish) begin
        
        $display("Clock #%d", num_clock);
        $display("The testbench is finished. Summarizing...");

        for(i=0; i<`NUM_TEST; i=i+1) begin
            if (TestPassed[i] == 1)
                Passed = Passed + 1;
            else                                       
                $display("Test #%s : %s", TestID[i],
                    (TestPassed[i] === 0) ? "Wrong" : "No Result");
        end

        if (Passed == `NUM_TEST)
		begin
            $display("All Pass!");
			$display("Total Cycles: %0d", num_clock);
			$display("Execution Time: %0d ns", num_clock * `PERIOD1);
		end
        else
            $display("Pass : %0d/%0d", Passed, `NUM_TEST);

        $finish;
    end

endmodule