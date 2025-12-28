`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - Mux32Bit2To1.v
// Description - Performs signal multiplexing between 2 32-Bit words.
////////////////////////////////////////////////////////////////////////////////

module Mux32Bit2To1(out, inA, inB, sel);

    output reg [31:0] out;
    
    input [31:0] inA;
    input [31:0] inB;
    input sel;

    /* Fill in the implementation here ... */ 
    
    // Combinational 2:1 mux
    always @* begin
        // Select which 32-bit input drives 'out' based on the 1-bit select 'sel'.
        case (sel)
            1'b0:   out = inA;            // If sel is 0, forward input A to output.
            1'b1:   out = inB;            // If sel is 1, forward input B to output.
    
            // Default case for testbench/simulation porpuses.
            default: out = 32'hXXXX_XXXX; 
        endcase
    end
    

endmodule
