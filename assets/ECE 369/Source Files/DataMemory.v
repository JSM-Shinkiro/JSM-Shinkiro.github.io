`timescale 1ns / 1ps

module data_memory (
    input        clk,
    input  [31:0] address,
    input  [31:0] write_data,
    input         mem_read,
    input         mem_write,
    input  [1:0]  mem_size,       // 00=byte, 01=half, 10=word
    input         sign_extend,
    output [31:0] read_data
);

    (* ram_style = "block" *) reg [31:0] memory [0:255];

    wire [7:0]  byte_offset = address[1:0];   // lower 2 bits for byte select
    wire [7:0]  half_offset = address[1];     // lower bit for halfword select
    wire [7:0]  word_index  = address[9:2];   // top 8 bits for 256-word memory

    reg [31:0] read_result;

    // memory initialization
    initial begin
        $readmemh("data_memory.mem", memory);
    end

    // Selection logic for store word
    always @(posedge clk) begin
        if (mem_write) begin
            case (mem_size)
                2'b00: begin // Byte
                    memory[word_index][8*byte_offset +: 8] <= write_data[7:0];
                end
                2'b01: begin // Halfword
                    memory[word_index][16*half_offset +: 16] <= write_data[15:0];
                end
                2'b10: begin // Word
                    memory[word_index] <= write_data;
                end
            endcase
        end
    end

    // Logic for load word
    always @(*) begin
        case (mem_size)
            2'b00: begin // Byte
                if (sign_extend) //used to check if negative or pos
                    read_result = {{24{memory[word_index][8*byte_offset + 7]}}, memory[word_index][8*byte_offset +: 8]};
                else
                    read_result = {24'b0, memory[word_index][8*byte_offset +: 8]};
            end
            2'b01: begin // Halfword
                if (sign_extend)
                    read_result = {{16{memory[word_index][16*half_offset + 15]}}, memory[word_index][16*half_offset +: 16]};
                else
                    read_result = {16'b0, memory[word_index][16*half_offset +: 16]};
            end
            2'b10: begin // Word
                read_result = memory[word_index];
            end
            default: read_result = 32'b0;
        endcase
    end

    assign read_data = mem_read ? read_result : 32'b0;

endmodule
