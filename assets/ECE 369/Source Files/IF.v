`timescale 1ns / 1ps

module stage_if (
    input clk,
    input reset,
    input PCSrc,
    input PCWrite,        // NEW
    input IFIDWrite,      // NEW
    input [31:0] BranchTarget,

    output reg [31:0] PC_out,
    output reg [31:0] instruction   // MUST be reg now
);

    // Internal signals
    wire [31:0] next_pc;
    reg  [31:0] pc;                 // MUST be reg since we control when it updates

    // Next PC logic
    assign next_pc = PCSrc ? BranchTarget : (pc + 4);

    // Program counter (now implemented locally, not separate module)
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else if (PCWrite)            // <<< stall support
            pc <= next_pc;
        // else PC holds during stall
    end

    // Instruction memory
    wire [31:0] fetched_instr;
    instruction_memory IMEM (
        .address(pc),
        .instruction(fetched_instr)
    );

    // IF/ID pipeline registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_out     <= 32'b0;
            instruction <= 32'b0;
        end 
        else if (IFIDWrite) begin    // <<< stall support
            PC_out      <= pc;
            instruction <= fetched_instr;
        end
        // else: hold previous IF/ID values
    end

endmodule
