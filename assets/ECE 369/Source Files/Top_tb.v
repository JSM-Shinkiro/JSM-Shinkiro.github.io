`timescale 1ns / 1ps

module Top_tb;

    reg Clk;
    reg Reset;
    wire [31:0] WriteDataOut;
    wire [31:0] PCVal;

    // Instantiate your Top module
    Top uut (
        .Clk(Clk),
        .Reset(Reset),
        .WriteDataOut(WriteDataOut),
        .PCVal(PCVal)
    );

    // Clock generation: 10 ns period
    initial Clk = 0;
    always #5 Clk = ~Clk;

    initial begin
        // Reset pulse
        Reset = 1;
        #20;
        Reset = 0;

        // Run simulation for 500 ns
        #500;

        $finish;
    end

    // Monitor signals
    initial begin
        $display("Time | PC      | WriteDataOut");
        $monitor("%0t | %h | %h", $time, PCVal, WriteDataOut);
    end

endmodule
