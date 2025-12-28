`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ECE369A - Lab 5 FPGA Display PC Value and Register Write Data
//////////////////////////////////////////////////////////////////////////////////

// Jose Salinas: 40%
// Brenden Edwards: 30%
// Victor Majore: 30%

module Top(
    input  wire       Clk,   // 100 MHz board clock (E3)
    input  wire       Reset, // restart button (active-high) (N17)
    output wire [6:0] out7,  // seven segment segments a-g (active-low)
    output wire [7:0] en_out // digit enables (active-low)
);

    // slows the clock to display the numbers in a readable way
    // uses a synchronous Reset
    wire slow_Clk;
    wire clk = Clk;
    wire reset = Reset;
    wire [31:0] write_data;
    wire [31:0] pc_out;
    
    ClkDiv u_Clkdiv (
        .Clk   (Clk),
        .Rst   (1'b0), //set divider permanently low (free-run)
        .ClkOut(slow_Clk)
    );

    // synchronizes Reset for slow clock (since Reset is asynchronous)
    reg [1:0] rst_sync = 2'b11;   
    always @(posedge slow_Clk) begin
        rst_sync <= {rst_sync[0], Reset};
    end
    wire Reset_slow = rst_sync[1];


    // Datapath
    Datapath dp (
        .clk    (slow_Clk),         // Slow clock
        .reset  (Reset_slow),       // Slow reset
        .pc_out  (pc_out),          // Current PCValue
        .write_data    (write_data) // Data being written into register current cycle
        );
    

    // 2 digit display module
    Two4DigitDisplay u_disp (
        .Clk     (Clk),
        .NumberA (write_data[15:0]), //lower 16 bits on left 4 digits
        .NumberB (pc_out[15:0]), //upper 16 bits on right 4 digits
        //(in hex)
        .out7    (out7), //connect 7seg out
        .en_out  (en_out) //digit select out each refresh
        );

endmodule
