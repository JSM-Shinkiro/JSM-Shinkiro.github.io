`timescale 1ns / 1ps

module ForwardingUnit (
    input  wire [4:0] idex_rs,
    input  wire [4:0] idex_rt,
    input  wire [4:0] exmem_rd,
    input  wire [4:0] memwb_rd,
    input  wire       exmem_RegWrite,
    input  wire       memwb_RegWrite,
    output reg  [1:0] ForwardA,
    output reg  [1:0] ForwardB
);
    always @(*) begin
        // defaults: no forwarding
        ForwardA = 2'b00;
        ForwardB = 2'b00;

        // EX hazard: EX/MEM ? EX
        if (exmem_RegWrite && (exmem_rd != 0) && (exmem_rd == idex_rs))
            ForwardA = 2'b10;
        if (exmem_RegWrite && (exmem_rd != 0) && (exmem_rd == idex_rt))
            ForwardB = 2'b10;

        // MEM hazard: MEM/WB ? EX (only if EX/MEM didn't already match)
        if (memwb_RegWrite && (memwb_rd != 0) &&
            !(exmem_RegWrite && (exmem_rd != 0) && (exmem_rd == idex_rs)) &&
            (memwb_rd == idex_rs))
            ForwardA = 2'b01;

        if (memwb_RegWrite && (memwb_rd != 0) &&
            !(exmem_RegWrite && (exmem_rd != 0) && (exmem_rd == idex_rt)) &&
            (memwb_rd == idex_rt))
            ForwardB = 2'b01;
    end

endmodule
