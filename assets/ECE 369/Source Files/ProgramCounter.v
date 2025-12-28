`timescale 1ns / 1ps

module program_counter (
    input clk,
    input reset,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);

    // Updates the PC on clock or reset
    always @ (posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 32'b0; // resets pc back to 0
        else
            pc_out <= pc_in;
    end

endmodule
