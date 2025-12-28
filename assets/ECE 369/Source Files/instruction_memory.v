`timescale 1ns / 1ps
module instruction_memory(
    input  [31:0] address,
    output reg [31:0] instruction
);
    reg [31:0] memory [0:1023];  // 1028 words for the right file size
    initial begin
        $readmemh("instruction_memory.mem", memory);
    end

    always @(*) begin
        instruction = memory[address[31:2]]; // word-aligned
    end
endmodule