`timescale 1ns / 1ps

module HazardUnit (
    input  wire        idex_memread,  // 1 if EX-stage instruction is lw
    input  wire [4:0]  idex_rt,       // destination reg of lw in EX
    input  wire [4:0]  ifid_rs,       // rs of instruction in ID
    input  wire [4:0]  ifid_rt,       // rt of instruction in ID

    output reg         pc_write,      // 0 = stall PC
    output reg         ifid_write,    // 0 = stall IF/ID
    output reg         idex_flush     // 1 = inject NOP into ID/EX
);

    always @* begin
        // default: no hazard
        pc_write   = 1'b1;
        ifid_write = 1'b1;
        idex_flush = 1'b0;

        // Classic load-use hazard:
        // lw rt, ... followed by instr that uses rt in rs or rt
        if (idex_memread &&
            (idex_rt != 5'd0) &&
            ( (idex_rt == ifid_rs) || (idex_rt == ifid_rt) )
        ) begin
            pc_write   = 1'b0;  // freeze PC
            ifid_write = 1'b0;  // freeze IF/ID
            idex_flush = 1'b1;  // turn current EX-stage control into NOP
        end
    end

endmodule
