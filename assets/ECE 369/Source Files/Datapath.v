///////////////////////////////////////
//   ECE 369, Lab 4/5
/////////////////////////////////

`timescale 1ns / 1ps

module Datapath (
    input clk,
    input reset,
    output [31:0] write_data,
    output [31:0] pc_out,
    output [31:0] inst_out // trying to test if instr is correct
);

    // IF/ID Pipeline register signals
    wire [31:0] ifid_pc, ifid_instruction;
    assign inst_out = ifid_instruction; //assign to pull out instruction value for verification
    
    // Extract rs/rt from IF/ID instruction for hazard detection
    wire [4:0] ifid_rs = ifid_instruction[25:21];
    wire [4:0] ifid_rt = ifid_instruction[20:16];

    // Hazard unit control signals
    wire pc_write;
    wire ifid_write;
    wire idex_flush;

    
    // ID/EX Pipeline register signals
    wire [31:0] idex_pc, idex_read_data1, idex_read_data2;
    wire [31:0] idex_sign_extended;
    wire [4:0] idex_rs, idex_rt, idex_rd;
    wire [4:0] idex_shamt;
    wire [5:0] idex_funct;
    wire idex_reg_write, idex_mem_to_reg, idex_mem_read, idex_mem_write;
    wire idex_alu_src, idex_reg_dst;
    wire [3:0] idex_alu_op;
    wire idex_branch, idex_jump, idex_jump_reg;
    wire [1:0] idex_mem_size;  // used for byte, half, word
    wire idex_sign_extend_mem;
    
    // Hazard Detection Unit instantiation
    HazardUnit hazard_unit (
        .idex_memread (idex_mem_read),
        .idex_rt      (idex_rt),
        .ifid_rs      (ifid_rs),
        .ifid_rt      (ifid_rt),
        .pc_write     (pc_write),
        .ifid_write   (ifid_write),
        .idex_flush   (idex_flush)
    );
    
    
    // EX/MEM Pipeline register signals
    wire [31:0] exmem_alu_result, exmem_write_data;
    wire [31:0] exmem_branch_target, exmem_pc;
    wire [4:0] exmem_write_reg;
    wire exmem_reg_write, exmem_mem_to_reg, exmem_mem_read, exmem_mem_write;
    wire exmem_zero, exmem_branch;
    wire [1:0] exmem_mem_size;
    wire exmem_sign_extend_mem;
    
    // MEM/WB Pipeline Register signals
    wire [31:0] memwb_read_data, memwb_alu_result;
    wire [4:0] memwb_write_reg;
    wire memwb_reg_write, memwb_mem_to_reg;
    
    // Branch/jump control wires
    wire pc_src;
    wire [31:0] branch_target;
    
    // Writeback stage control
    wire [31:0] wb_data;
    assign wb_data = memwb_mem_to_reg ? memwb_read_data : memwb_alu_result;
        //the Wb stage mux
    
    // Output signals for top.v
    assign write_data = memwb_reg_write ? wb_data : 32'b0;
    assign pc_out = ifid_pc;
    
    // Forwarding unit control signals
    wire [1:0] forwardA;
    wire [1:0] forwardB;

    ForwardingUnit fwd_unit (
        .idex_rs       (idex_rs),
        .idex_rt       (idex_rt),
        .exmem_rd      (exmem_write_reg),
        .memwb_rd      (memwb_write_reg),
        .exmem_RegWrite(exmem_reg_write),
        .memwb_RegWrite(memwb_reg_write),
        .ForwardA      (forwardA),
        .ForwardB      (forwardB)
    );

    // Stage instantiations
    
    //stage instruction fetch
    stage_if if_stage (
        .clk(clk),
        .reset(reset),
        .PCSrc(pc_src),
        .BranchTarget(branch_target),
        .PCWrite(pc_write),          // Hazard Detection Unit
        .IFIDWrite(ifid_write),      // Hazard Detection Unit
        .PC_out(ifid_pc),
        .instruction(ifid_instruction)
    );


    //  instruction decode stage
    stage_id id_stage (
        .clk(clk),
        .reset(reset),
        .instruction_in(ifid_instruction),
        .PC_in(ifid_pc),
        .wb_WriteRead(memwb_write_reg),
        .wb_WriteData(wb_data),
        .wb_RegWrite(memwb_reg_write),

        .IDEXFlush(idex_flush),              // Hazard Detection Unit

        .idex_PC_out(idex_pc),
        .idex_ReadData_1(idex_read_data1),
        .idex_ReadData_2(idex_read_data2),
        .idex_SignExtended_out(idex_sign_extended),
        .rs(idex_rs),
        .rt(idex_rt),
        .rd(idex_rd),
        .shamt(idex_shamt),
        .funct(idex_funct),
        .idex_RegWrite_out(idex_reg_write),
        .idex_MemtoReg_out(idex_mem_to_reg),
        .idex_MemRead_out(idex_mem_read),
        .idex_MemWrite_out(idex_mem_write),
        .idex_AluSrc(idex_alu_src),
        .idex_RegDst(idex_reg_dst),
        .idex_AluOP(idex_alu_op),
        .idex_Branch_out(idex_branch),
        .idex_Jump(idex_jump),
        .idex_JumpReg(idex_jump_reg),
        .idex_MemSize(idex_mem_size),
        .idex_SignExtendtoMem(idex_sign_extend_mem)
    );


    // stage execution
    stage_ex ex_stage (
        .clk(clk),
        .reset(reset),
        .idex_PC_in(idex_pc),
        .idex_ReadData_1(idex_read_data1),
        .idex_ReadData_2(idex_read_data2),
        .idex_SignExtended_in(idex_sign_extended),
        .idex_rs(idex_rs),
        .idex_rt(idex_rt),
        .idex_rd(idex_rd),
        .idex_shamt(idex_shamt),
        .idex_funct(idex_funct),
        .idex_RegWrite(idex_reg_write),
        .idex_MemtoReg_in(idex_mem_to_reg),
        .idex_MemRead_in(idex_mem_read),
        .idex_MemWrite(idex_mem_write),
        .idex_AluSrc_in(idex_alu_src),
        .idex_RegDst(idex_reg_dst),
        .idex_AluOP(idex_alu_op),
        .idex_Branch(idex_branch),
        .idex_Jump(idex_jump),
        .idex_JumpReg(idex_jump_reg),
        .idex_MemSize_in(idex_mem_size),
        .idex_SignExtendMem_in(idex_sign_extend_mem),

        // NEW forwarding-related ports:
        .ForwardA(forwardA),
        .ForwardB(forwardB),
        .exmem_AluResult_in(exmem_alu_result),
        .memwb_AluResult_in(memwb_alu_result),
        .memwb_ReadData_in(memwb_read_data),
        .memwb_MemtoReg_in(memwb_mem_to_reg),

        .exmem_AluResult_out(exmem_alu_result),
        .exmem_WriteData_out(exmem_write_data),
        .exmem_WriteReg(exmem_write_reg),
        .exmem_RegWrite_out(exmem_reg_write),
        .exmem_MemtoReg(exmem_mem_to_reg),
        .exmem_MemRead_out(exmem_mem_read),
        .exmem_MemWrite_out(exmem_mem_write),
        .exmem_Zero(exmem_zero),
        .exmem_Branch_out(exmem_branch),
        .exmem_BranchTarget_out(exmem_branch_target),
        .exmem_PC_out(exmem_pc),
        .exmem_MemSize_out(exmem_mem_size),
        .exmem_SignExtendMem_out(exmem_sign_extend_mem)
    );



    //stage memory
    stage_mem mem_stage (
        .clk(clk),
        .reset(reset),
        .exmem_AluResult_in(exmem_alu_result),
        .exmem_WriteData(exmem_write_data),
        .exmem_WriteReg_in(exmem_write_reg),
        .exmem_RegWrite_in(exmem_reg_write),
        .exmem_MemtoReg(exmem_mem_to_reg),
        .exmem_MemRead(exmem_mem_read),
        .exmem_MemWrite(exmem_mem_write),
        .exmem_Zero(exmem_zero),
        .exmem_Branch(exmem_branch),
        .exmem_BranchTarget_in(exmem_branch_target),
        .exmem_MemSize(exmem_mem_size),
        .exmem_SignExtendMem(exmem_sign_extend_mem),
        .memwb_ReadData(memwb_read_data),
        .memwb_AluResult_out(memwb_alu_result),
        .memwb_WriteReg_out(memwb_write_reg),
        .memwb_RegWrite_out(memwb_reg_write),
        .memwb_MemtoReg(memwb_mem_to_reg),
        .PCSrc(pc_src),
        .BranchTarget_out(branch_target)
    );


endmodule
