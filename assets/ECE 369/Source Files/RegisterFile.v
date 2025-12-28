`timescale 1ns / 1ps

module register_file (
    input  wire        clk,
    input  wire        reset,
    input  wire        reg_write,        // enable write (from MEM/WB)
    input  wire [4:0]  read_reg1,        // rs
    input  wire [4:0]  read_reg2,        // rt
    input  wire [4:0]  write_reg,        // destination
    input  wire [31:0] write_data,       // data to write
    output wire [31:0] read_data1,       // rs value
    output wire [31:0] read_data2        // rt value
);

    // 32 registers, 32 bits wide
    reg [31:0] registers [31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    // Writes data on the rising edge of the clock
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else if (reg_write && (write_reg != 0)) begin
            registers[write_reg] <= write_data;
        end
    end

    // base array reads
    wire [31:0] rf_read_data1 = (read_reg1 == 0) ? 32'b0 : registers[read_reg1];
    wire [31:0] rf_read_data2 = (read_reg2 == 0) ? 32'b0 : registers[read_reg2];

    // write-before-read bypass for same-cycle WB?ID
    assign read_data1 = (reg_write && (write_reg != 0) && (write_reg == read_reg1))
                        ? write_data
                        : rf_read_data1;

    assign read_data2 = (reg_write && (write_reg != 0) && (write_reg == read_reg2))
                        ? write_data
                        : rf_read_data2;

endmodule
