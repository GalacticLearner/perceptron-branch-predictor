`timescale 1ns/1ns
`define WORD_SIZE 16

// Perceptron Branch Predictor Module
// Implements a perceptron-based branch prediction scheme
// Key parameters:
// - NUM_PERCEPTRONS: Number of perceptron entries in the prediction table
// - HISTORY_WIDTH: Number of bits in the global history register
// - WEIGHT_WIDTH: Number of bits for representing weights
// - WEIGHT_INT_WIDTH: Integer width for weight calculations

module PerceptronBranchPredictor(
    input clk,
    input reset_n,
    
    // Prediction interface
    input [`WORD_SIZE-1:0] branch_pc,        // Branch program counter
    input [`WORD_SIZE-1:0] global_history,   // Global branch history register
    output reg prediction,                    // 1: taken, 0: not taken
    
    // Training interface
    input train_enable,                       // Enable weight update
    input [`WORD_SIZE-1:0] train_pc,          // PC of branch being trained
    input train_actual,                       // Actual branch outcome
    input signed [15:0] last_y,               // Last computed y value for training
    
    // Debug/status
    output reg [7:0] hash_index              // Hashed index (for debugging)
);

    // Parameters
    localparam NUM_PERCEPTRONS = 256;         // 256 perceptron entries (8-bit hash)
    localparam HISTORY_WIDTH = 8;             // 8-bit global history
    localparam NUM_WEIGHTS = HISTORY_WIDTH + 1; // +1 for bias term
    localparam WEIGHT_WIDTH = 8;              // 8-bit signed weights
    localparam THETA = 15;                    // Threshold for updating weights
    
    // Perceptron table: [entry][weight_index]
    // Each perceptron has HISTORY_WIDTH+1 weights (including bias)
    reg signed [WEIGHT_WIDTH-1:0] perceptron_table [NUM_PERCEPTRONS-1:0][NUM_WEIGHTS-1:0];
    
    // Internal signals
    reg signed [WEIGHT_WIDTH-1:0] perceptron [NUM_WEIGHTS-1:0];
    reg signed [15:0] y_value;
    wire [7:0] hash_idx;
    wire [7:0] train_hash_idx;
    integer i, j;
    
    // Hash function: Simple XOR-based hash to compute index from PC
    function [7:0] compute_hash;
        input [`WORD_SIZE-1:0] pc;
        begin
            // Simple hash: XOR of upper and lower 8 bits
            compute_hash = pc[15:8] ^ pc[7:0];
        end
    endfunction
    
    assign hash_idx = compute_hash(branch_pc);
    assign train_hash_idx = compute_hash(train_pc);
    
    // Initialize perceptron table
    initial begin
        for (i = 0; i < NUM_PERCEPTRONS; i = i + 1) begin
            // Initialize all weights to 0
            for (j = 0; j < NUM_WEIGHTS; j = j + 1) begin
                perceptron_table[i][j] = 8'h00;
            end
        end
    end
    
    // Prediction stage: Compute dot product and generate prediction
    always @(*) begin
        hash_index = hash_idx;
        
        // Fetch perceptron from table
        for (j = 0; j < NUM_WEIGHTS; j = j + 1) begin
            perceptron[j] = perceptron_table[hash_idx][j];
        end
        
        // Compute y = bias + sum(weight[i] * history[i])
        y_value = {{8{perceptron[0][WEIGHT_WIDTH-1]}}, perceptron[0]};  // Bias (sign-extended)
        
        for (j = 1; j < NUM_WEIGHTS; j = j + 1) begin
            // Multiply weight by history bit and accumulate
            if (global_history[j-1] == 1'b1) begin
                y_value = y_value + {{8{perceptron[j][WEIGHT_WIDTH-1]}}, perceptron[j]};
            end
        end
        
        // Prediction: taken if y >= 0, not taken if y < 0
        if (y_value < 16'h0000) begin
            prediction = 1'b0;  // Not taken
        end else begin
            prediction = 1'b1;  // Taken
        end
    end
    
    // Training stage: Update weights based on actual outcome
    always @(posedge clk) begin
        if (!reset_n) begin
            // Reset: reinitialize all weights
            for (i = 0; i < NUM_PERCEPTRONS; i = i + 1) begin
                for (j = 0; j < NUM_WEIGHTS; j = j + 1) begin
                    perceptron_table[i][j] <= 8'h00;
                end
            end
        end else if (train_enable) begin
            // Fetch the perceptron to be trained
            for (j = 0; j < NUM_WEIGHTS; j = j + 1) begin
                perceptron[j] = perceptron_table[train_hash_idx][j];
            end
            
            // Update rule: if prediction was wrong, or |y| < theta, update weights
            // Update bias weight
            if ((train_actual == 1'b1 && last_y < 0) || 
                (train_actual == 1'b0 && last_y >= 0) ||
                (last_y[15] == 1'b0 && last_y < 16'd15)) begin  // |y| < theta
                
                // Update bias: increment if actual is 1, decrement if actual is 0
                if (train_actual == 1'b1) begin
                    perceptron_table[train_hash_idx][0] <= perceptron[0] + 1'b1;
                end else begin
                    perceptron_table[train_hash_idx][0] <= perceptron[0] - 1'b1;
                end
                
                // Update history-based weights
                for (j = 1; j < NUM_WEIGHTS; j = j + 1) begin
                    if (train_actual == 1'b1) begin
                        // Branch was taken: increment weights where history is 1
                        if (global_history[j-1] == 1'b1) begin
                            perceptron_table[train_hash_idx][j] <= perceptron[j] + 1'b1;
                        end else begin
                            perceptron_table[train_hash_idx][j] <= perceptron[j] - 1'b1;
                        end
                    end else begin
                        // Branch was not taken: decrement weights where history is 1
                        if (global_history[j-1] == 1'b1) begin
                            perceptron_table[train_hash_idx][j] <= perceptron[j] - 1'b1;
                        end else begin
                            perceptron_table[train_hash_idx][j] <= perceptron[j] + 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule

// Global History Register Module
// Maintains the global branch history for use by the perceptron predictor
module GlobalHistoryRegister(
    input clk,
    input reset_n,
    input branch_outcome,      // Actual outcome of a branch (1: taken, 0: not taken)
    input update_enable,       // Enable history update
    output reg [7:0] history   // Current global history register
);

    always @(posedge clk) begin
        if (!reset_n) begin
            history <= 8'h00;
        end else if (update_enable) begin
            // Shift history left and insert new outcome at bit 0
            history <= {history[6:0], branch_outcome};
        end
    end

endmodule

// Integration wrapper: Perceptron predictor with history register
module PerceptronPredictionUnit(
    input clk,
    input reset_n,
    
    // Prediction request
    input [`WORD_SIZE-1:0] branch_pc,
    output prediction,
    
    // Training signals
    input train_enable,
    input [`WORD_SIZE-1:0] train_pc,
    input train_actual,
    input signed [15:0] last_y,
    
    // Debug output
    output [7:0] hash_index
);

    wire [7:0] global_history;
    
    // Instantiate the global history register
    GlobalHistoryRegister ghr_inst(
        .clk(clk),
        .reset_n(reset_n),
        .branch_outcome(train_actual),
        .update_enable(train_enable),
        .history(global_history)
    );
    
    // Instantiate the perceptron predictor
    PerceptronBranchPredictor perceptron_inst(
        .clk(clk),
        .reset_n(reset_n),
        .branch_pc(branch_pc),
        .global_history({{8{1'b0}}, global_history}),  // Pad to WORD_SIZE
        .prediction(prediction),
        .train_enable(train_enable),
        .train_pc(train_pc),
        .train_actual(train_actual),
        .last_y(last_y),
        .hash_index(hash_index)
    );

endmodule
