`timescale 1ns / 1ps

module alu (
    input signed [31:0] input1,
    input signed [31:0] input2,
    input  [4:0]  shamt,
    input  [3:0]  alu_control,
    input  [5:0]  funct,
    output [31:0] result,
    output        zero
);
    reg signed [31:0] alu_result;

    always @(*) begin
        case (alu_control)
            4'b0000: alu_result = input1 & input2;                    // AND
            4'b0001: alu_result = input1 | input2;                    // OR
            4'b0010: alu_result = input1 + input2;                    // ADD
            4'b0011: alu_result = input1 * input2;                    // MUL
            4'b0100: alu_result = input1 ^ input2;                    // XOR
            4'b0101: alu_result = ~(input1 | input2);                 // NOR
            4'b0110: alu_result = input1 - input2;                    // SUB
            4'b0111: alu_result = ($signed(input1) < $signed(input2)) ? 32'b1 : 32'b0;  // SLT
            4'b1011: alu_result = (input1 < input2) ? 32'b1 : 32'b0;  // SLTU
            4'b1100: alu_result = input2 << shamt;                    // SLL
            4'b1101: alu_result = input2 >> shamt;                    // SRL
            4'b1110: alu_result = $signed(input2) >>> shamt;          // SRA
            4'b1111: begin  // R-type operations
                case (funct)
                    6'b100000: alu_result = input1 + input2;          // add
                    6'b100010: alu_result = input1 - input2;          // sub
                    6'b100100: alu_result = input1 & input2;          // and
                    6'b100101: alu_result = input1 | input2;          // or
                    6'b100110: alu_result = input1 ^ input2;          // xor
                    6'b100111: alu_result = ~(input1 | input2);       // nor
                    6'b101010: alu_result = ($signed(input1) < $signed(input2)) ? 32'b1 : 32'b0;  // slt
                    6'b101011: alu_result = (input1 < input2) ? 32'b1 : 32'b0;  // sltu
                    6'b000000: alu_result = input2 << shamt;          // sll
                    6'b000010: alu_result = input2 >> shamt;          // srl
                    6'b000011: alu_result = $signed(input2) >>> shamt;// sra
                    6'b011000: alu_result = input1 * input2;          // mul
                    6'b001000: alu_result = input1;                   // jr 
                    default: alu_result = 32'b0;
                endcase
            end
            default: alu_result = 32'b0;
        endcase
    end

    assign result = alu_result;
    assign zero = (alu_result == 32'b0);

endmodule
