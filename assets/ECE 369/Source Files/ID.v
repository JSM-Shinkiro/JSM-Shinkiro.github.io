`timescale 1ns / 1ps

module stage_id (
    input clk,
    input reset,
    input [31:0] instruction_in,
    input [31:0] PC_in,
    input [4:0] wb_WriteRead,
    input [31:0] wb_WriteData,
    input wb_RegWrite,

    // NEW: flush signal from HazardUnit
    input IDEXFlush,

    output reg [31:0] idex_PC_out,
    output reg [31:0] idex_ReadData_1,
    output reg [31:0] idex_ReadData_2,
    output reg [31:0] idex_SignExtended_out,
    output reg [4:0] rs,
    output reg [4:0] rt,
    output reg [4:0] rd,
    output reg [4:0] shamt,
    output reg [5:0] funct,
    output reg idex_RegWrite_out,
    output reg idex_MemtoReg_out,
    output reg idex_MemRead_out,
    output reg idex_MemWrite_out,
    output reg idex_AluSrc,
    output reg idex_RegDst,
    output reg [3:0] idex_AluOP,
    output reg idex_Branch_out,
    output reg idex_Jump,
    output reg idex_JumpReg,
    output reg [1:0] idex_MemSize,
    output reg idex_SignExtendtoMem
);

    // internal signals for sub modules
    wire [31:0] read_data1, read_data2;
    wire [31:0] sign_extended;
    wire reg_write, mem_to_reg, mem_read, mem_write, alu_src, reg_dst;
    wire [3:0] alu_op;
    wire branch, jump, jump_reg;
    wire [1:0] mem_size;
    wire sign_extend_mem;

    // decode instruction bit sections
    wire [5:0] opcode         = instruction_in[31:26];
    wire [4:0] rs_internal    = instruction_in[25:21];
    wire [4:0] rt_internal    = instruction_in[20:16];
    wire [4:0] rd_internal    = instruction_in[15:11];
    wire [4:0] shamt_internal = instruction_in[10:6];
    wire [5:0] funct_internal = instruction_in[5:0];
    wire [15:0] immediate     = instruction_in[15:0];

    // register file
    register_file REGFILE (
        .clk(clk),
        .reset(reset),
        .read_reg1(rs_internal),
        .read_reg2(rt_internal),
        .write_reg(wb_WriteRead),
        .write_data(wb_WriteData),
        .reg_write(wb_RegWrite),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // control unit
    control_unit CONTROL (
        .opcode(opcode),
        .funct(funct_internal),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_dst(reg_dst),
        .alu_op(alu_op),
        .branch(branch),
        .jump(jump),
        .jump_reg(jump_reg),
        .mem_size(mem_size),
        .sign_extend_mem(sign_extend_mem)
    );

    // sign extend
    sign_extend SIGNEXT (
        .in(immediate),
        .out(sign_extended)
    );

    // ID/EX pipeline register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            idex_PC_out          <= 32'b0;
            idex_ReadData_1      <= 32'b0;
            idex_ReadData_2      <= 32'b0;
            idex_SignExtended_out<= 32'b0;
            rs                   <= 5'b0;
            rt                   <= 5'b0;
            rd                   <= 5'b0;
            shamt                <= 5'b0;
            funct                <= 6'b0;

            idex_RegWrite_out    <= 1'b0;
            idex_MemtoReg_out    <= 1'b0;
            idex_MemRead_out     <= 1'b0;
            idex_MemWrite_out    <= 1'b0;
            idex_AluSrc          <= 1'b0;
            idex_RegDst          <= 1'b0;
            idex_AluOP           <= 4'b0;
            idex_Branch_out      <= 1'b0;
            idex_Jump            <= 1'b0;
            idex_JumpReg         <= 1'b0;
            idex_MemSize         <= 2'b0;
            idex_SignExtendtoMem <= 1'b0;

        end else if (IDEXFlush) begin
            // *** inject NOP into EX stage ***
            // Data fields can still be updated; control must be zero

            idex_PC_out          <= PC_in;
            idex_ReadData_1      <= read_data1;
            idex_ReadData_2      <= read_data2;
            idex_SignExtended_out<= sign_extended;
            rs                   <= rs_internal;
            rt                   <= rt_internal;
            rd                   <= rd_internal;
            shamt                <= shamt_internal;
            funct                <= funct_internal;

            // CONTROL SIGNALS = 0  ? NOP
            idex_RegWrite_out    <= 1'b0;
            idex_MemtoReg_out    <= 1'b0;
            idex_MemRead_out     <= 1'b0;
            idex_MemWrite_out    <= 1'b0;
            idex_AluSrc          <= 1'b0;
            idex_RegDst          <= 1'b0;
            idex_AluOP           <= 4'b0;
            idex_Branch_out      <= 1'b0;
            idex_Jump            <= 1'b0;
            idex_JumpReg         <= 1'b0;
            idex_MemSize         <= 2'b0;
            idex_SignExtendtoMem <= 1'b0;

        end else begin
            // normal pipeline advance
            idex_PC_out          <= PC_in;
            idex_ReadData_1      <= read_data1;
            idex_ReadData_2      <= read_data2;
            idex_SignExtended_out<= sign_extended;
            rs                   <= rs_internal;
            rt                   <= rt_internal;
            rd                   <= rd_internal;
            shamt                <= shamt_internal;
            funct                <= funct_internal;

            idex_RegWrite_out    <= reg_write;
            idex_MemtoReg_out    <= mem_to_reg;
            idex_MemRead_out     <= mem_read;
            idex_MemWrite_out    <= mem_write;
            idex_AluSrc          <= alu_src;
            idex_RegDst          <= reg_dst;
            idex_AluOP           <= alu_op;
            idex_Branch_out      <= branch;
            idex_Jump            <= jump;
            idex_JumpReg         <= jump_reg;
            idex_MemSize         <= mem_size;
            idex_SignExtendtoMem <= sign_extend_mem;
        end
    end

endmodule
