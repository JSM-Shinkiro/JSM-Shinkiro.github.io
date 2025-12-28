`timescale 1ns / 1ps

module stage_mem (
    input clk,
    input reset,
    input [31:0] exmem_AluResult_in,
    input [31:0] exmem_WriteData,
    input [4:0] exmem_WriteReg_in,
    input exmem_RegWrite_in,
    input exmem_MemtoReg,
    input exmem_MemRead,
    input exmem_MemWrite,
    input exmem_Zero,
    input exmem_Branch,
    input [31:0] exmem_BranchTarget_in,
    input [1:0] exmem_MemSize,
    input exmem_SignExtendMem,
    output reg [31:0] memwb_ReadData,
    output reg [31:0] memwb_AluResult_out,
    output reg [4:0] memwb_WriteReg_out,
    output reg memwb_RegWrite_out,
    output reg memwb_MemtoReg,
    output PCSrc,
    output [31:0] BranchTarget_out
);

    // Internal read data from memory
    wire [31:0] read_data;

    // Branch decision
    assign PCSrc = exmem_Branch;
    assign BranchTarget_out = exmem_BranchTarget_in;

    // Data Memory instantiation
    data_memory DMEM (
        .clk(clk),
        .address(exmem_AluResult_in),
        .write_data(exmem_WriteData),
        .mem_read(exmem_MemRead),
        .mem_write(exmem_MemWrite),
        .mem_size(exmem_MemSize),
        .sign_extend(exmem_SignExtendMem),
        .read_data(read_data)
    );

    // Mem/Wb Pipeline register value setter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            memwb_ReadData <= 32'b0;
            memwb_AluResult_out <= 32'b0;
            memwb_WriteReg_out <= 5'b0;
            memwb_RegWrite_out <= 1'b0;
            memwb_MemtoReg <= 1'b0;
        end else begin
            memwb_ReadData <= read_data;
            memwb_AluResult_out <= exmem_AluResult_in;
            memwb_WriteReg_out <= exmem_WriteReg_in;
            memwb_RegWrite_out <= exmem_RegWrite_in;
            memwb_MemtoReg <= exmem_MemtoReg;
        end
    end

endmodule
