`timescale 1ns / 1ps

module control_unit (
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output reg  reg_write,
    output reg  mem_to_reg,
    output reg  mem_read,
    output reg  mem_write,
    output reg  alu_src,
    output reg  reg_dst,
    output reg  [3:0] alu_op,
    output reg  branch,
    output reg  jump,
    output reg  jump_reg,
    output reg  [1:0] mem_size,
    output reg  sign_extend_mem
);

    always @(*) begin
        // Default values
        reg_write       = 1'b0;
        mem_to_reg      = 1'b0;
        mem_read        = 1'b0;
        mem_write       = 1'b0;
        alu_src         = 1'b0;
        reg_dst         = 1'b0;
        alu_op          = 4'b0010;
        branch          = 1'b0;
        jump            = 1'b0;
        jump_reg        = 1'b0;
        mem_size        = 2'b10;   // Word
        sign_extend_mem = 1'b1;

        case (opcode)
            // Regsiter instructions
            6'b000000: begin
                reg_write = 1'b1;
                reg_dst   = 1'b1;
                alu_op    = 4'b1111; // Use funct field
                if (funct == 6'b001000) begin // jr
                    reg_write = 1'b0;
                    jump_reg  = 1'b1;
                end
            end

            // Immediate arithmetic instruction output settings
            6'b001000: begin // ADDI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0010;
            end
            6'b001100: begin // ANDI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0000;
            end
            6'b001101: begin // ORI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0001;
            end
            6'b001110: begin // XORI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0100;
            end
            6'b001010: begin // SLTI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0111;
            end

            // Load instruction output set
            6'b100011: begin // LW
                reg_write = 1'b1;
                mem_to_reg = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0010;
                mem_size = 2'b10; // word
            end
            6'b100001: begin // LH
                reg_write = 1'b1;
                mem_to_reg = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0010;
                mem_size = 2'b01; // half
                sign_extend_mem = 1'b1;
            end
            6'b100000: begin // LB
                reg_write = 1'b1;
                mem_to_reg = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0010;
                mem_size = 2'b00; // byte
                sign_extend_mem = 1'b1;
            end

            // Store instruction set
            6'b101011: begin // SW
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0010;
                mem_size = 2'b10;
            end
            6'b101001: begin // SH
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0010;
                mem_size = 2'b01;
            end
            6'b101000: begin // SB
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0010;
                mem_size = 2'b00;
            end

            // Branch set
            6'b000100: begin // BEQ
                branch = 1'b1;
                alu_op = 4'b0110; // SUB
            end
            6'b000101: begin // BNE
                branch = 1'b1;
                alu_op = 4'b0110;
            end
            6'b000111: begin // BGTZ
                branch = 1'b1;
                alu_op = 4'b1000;
            end
            6'b000110: begin // BLEZ
                branch = 1'b1;
                alu_op = 4'b1001;
            end
            6'b000001: begin // BLTZ / BGEZ
                branch = 1'b1;
                alu_op = 4'b1010;
            end

            // Jump instruction set
            6'b000010: begin // J
                jump = 1'b1;
            end
            6'b000011: begin // JAL
                jump = 1'b1;
                reg_write = 1'b1;
            end
            
            // SPECIAL2 instructions (e.g., MUL)
            6'b011100: begin
                // Only implement MUL (opcode 0x1C, funct 0x02)
                case (funct)
                    6'b000010: begin // MUL rd, rs, rt
                        reg_write = 1'b1;     // write back to rd
                        reg_dst   = 1'b1;     // use rd as destination
                        alu_src   = 1'b0;     // both operands from regs
                        alu_op    = 4'b0011;  // use ALU's MUL operation
                    end
                    default: begin
                        // other SPECIAL2 ops (madd, etc.) not implemented ? nop
                    end
                endcase
            end

            
            default: begin
                // nop instruction = 0
            end
        endcase
    end

endmodule
