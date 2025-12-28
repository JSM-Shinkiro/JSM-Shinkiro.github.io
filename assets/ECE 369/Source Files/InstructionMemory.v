`timescale 1ns / 1ps

module InstructionMemory(
    input  [31:0] Address,
    output reg [31:0] Instruction
);

    // Adjust size to max address in .mem if needed
    reg [31:0] memory [0:1027];  

    // ----------------------------
    // Preload instructions
    // ----------------------------
    initial begin
    $readmemh("instruction_memory.mem", memory);
        end

    // ----------------------------
    // Read instruction (combinational)
    // ----------------------------
    always @(*) begin
        Instruction = memory[Address[31:2]];  // word-aligned
    end

endmodule
