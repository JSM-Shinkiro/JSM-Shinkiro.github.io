`timescale 1ns / 1ps

module stage_ex (
    input clk,
    input reset,

    input [31:0] idex_PC_in,
    input [31:0] idex_ReadData_1,
    input [31:0] idex_ReadData_2,
    input [31:0] idex_SignExtended_in,
    input [4:0]  idex_rs,
    input [4:0]  idex_rt,
    input [4:0]  idex_rd,
    input [4:0]  idex_shamt,
    input [5:0]  idex_funct,
    input        idex_RegWrite,
    input        idex_MemtoReg_in,
    input        idex_MemRead_in,
    input        idex_MemWrite,
    input        idex_AluSrc_in,
    input        idex_RegDst,
    input [3:0]  idex_AluOP,
    input        idex_Branch,
    input        idex_Jump,
    input        idex_JumpReg,
    input [1:0]  idex_MemSize_in,
    input        idex_SignExtendMem_in,

    // NEW forwarding inputs
    input [1:0]  ForwardA,
    input [1:0]  ForwardB,
    input [31:0] exmem_AluResult_in,
    input [31:0] memwb_AluResult_in,
    input [31:0] memwb_ReadData_in,
    input        memwb_MemtoReg_in,

    output reg [31:0] exmem_AluResult_out,
    output reg [31:0] exmem_WriteData_out,
    output reg [4:0]  exmem_WriteReg,
    output reg        exmem_RegWrite_out,
    output reg        exmem_MemtoReg,
    output reg        exmem_MemRead_out,
    output reg        exmem_MemWrite_out,
    output reg        exmem_Zero,
    output reg        exmem_Branch_out,
    output reg [31:0] exmem_BranchTarget_out,
    output reg [31:0] exmem_PC_out,
    output reg [1:0]  exmem_MemSize_out,
    output reg        exmem_SignExtendMem_out
);

    // Forwarding mux sources
    wire [31:0] wb_forward_data = memwb_MemtoReg_in ? memwb_ReadData_in
                                                    : memwb_AluResult_in;

    wire [31:0] alu_srcA =
        (ForwardA == 2'b00) ? idex_ReadData_1 :
        (ForwardA == 2'b10) ? exmem_AluResult_in :
        (ForwardA == 2'b01) ? wb_forward_data :
                              idex_ReadData_1;

    wire [31:0] alu_srcB_reg =
        (ForwardB == 2'b00) ? idex_ReadData_2 :
        (ForwardB == 2'b10) ? exmem_AluResult_in :
        (ForwardB == 2'b01) ? wb_forward_data :
                              idex_ReadData_2;

    // ALUSrc mux (uses forwarded B as base)
    wire [31:0] alu_input2 = idex_AluSrc_in ? idex_SignExtended_in : alu_srcB_reg;

    wire [31:0] alu_result;
    wire        zero;
    wire [31:0] branch_target;

    // Write register selection (same as before)
    wire [4:0] write_reg =
        idex_Jump ? 5'd31 : (idex_RegDst ? idex_rd : idex_rt);

    // Branch target calculation (you can later choose to use alu_srcA for JR)
    assign branch_target = idex_JumpReg ? alu_srcA :
                           idex_Jump    ? {idex_PC_in[31:28], idex_SignExtended_in[25:0], 2'b00} :
                           idex_PC_in + (idex_SignExtended_in << 2);

    // ALU instantiation
    alu ALU (
        .input1(alu_srcA),
        .input2(alu_input2),
        .shamt(idex_shamt),
        .alu_control(idex_AluOP),
        .funct(idex_funct),
        .result(alu_result),
        .zero(zero)
    );

    // EX/MEM pipeline registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            exmem_AluResult_out   <= 32'b0;
            exmem_WriteData_out   <= 32'b0;
            exmem_WriteReg        <= 5'b0;
            exmem_RegWrite_out    <= 1'b0;
            exmem_MemtoReg        <= 1'b0;
            exmem_MemRead_out     <= 1'b0;
            exmem_MemWrite_out    <= 1'b0;
            exmem_Zero            <= 1'b0;
            exmem_Branch_out      <= 1'b0;
            exmem_BranchTarget_out<= 32'b0;
            exmem_PC_out          <= 32'b0;
            exmem_MemSize_out     <= 2'b0;
            exmem_SignExtendMem_out <= 1'b0;
        end else begin
            exmem_AluResult_out   <= idex_Jump ? idex_PC_in + 4 : alu_result; // jal
            exmem_WriteData_out   <= alu_srcB_reg;  // forwarded store data
            exmem_WriteReg        <= write_reg;
            exmem_RegWrite_out    <= idex_RegWrite;
            exmem_MemtoReg        <= idex_MemtoReg_in;
            exmem_MemRead_out     <= idex_MemRead_in;
            exmem_MemWrite_out    <= idex_MemWrite;
            exmem_Zero            <= zero;
            exmem_Branch_out      <= idex_Branch | idex_Jump | idex_JumpReg;
            exmem_BranchTarget_out<= branch_target;
            exmem_PC_out          <= idex_PC_in;
            exmem_MemSize_out     <= idex_MemSize_in;
            exmem_SignExtendMem_out <= idex_SignExtendMem_in;
        end
    end

endmodule
