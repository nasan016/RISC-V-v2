module decode(
    input  [31:0] instr,
    output reg        reg_we,
    output reg        mem_we,
    output reg        mem_re,
    output reg        alu_src_imm,
    output reg [1:0]  wb_sel,
    output reg        branch,
    output reg        jal,
    output reg        jalr,
    output reg [3:0]  alu_op,

    // new
    output reg [1:0]  mem_size,      // 00=byte, 01=half, 10=word
    output reg        load_unsigned  // 0=signed, 1=unsigned
);

    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_SLL  = 4'd5;
    localparam ALU_SRL  = 4'd6;
    localparam ALU_SRA  = 4'd7;
    localparam ALU_SLT  = 4'd8;
    localparam ALU_SLTU = 4'd9;

    localparam WB_ALU   = 2'd0;
    localparam WB_MEM   = 2'd1;
    localparam WB_PC4   = 2'd2;
    localparam WB_IMM_U = 2'd3;

    localparam MEM_BYTE = 2'd0;
    localparam MEM_HALF = 2'd1;
    localparam MEM_WORD = 2'd2;

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];
    wire [11:0] imm12 = instr[31:20];

    always @(*) begin
        reg_we         = 1'b0;
        mem_we         = 1'b0;
        mem_re         = 1'b0;
        alu_src_imm    = 1'b0;
        wb_sel         = WB_ALU;
        branch         = 1'b0;
        jal            = 1'b0;
        jalr           = 1'b0;
        alu_op         = ALU_ADD;
        mem_size       = MEM_WORD;
        load_unsigned  = 1'b0;

        case (opcode)
            7'b0110011: begin
                reg_we = 1'b1;
                wb_sel = WB_ALU;
                case (funct3)
                    3'b000: alu_op = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
                    3'b111: alu_op = ALU_AND;
                    3'b110: alu_op = ALU_OR;
                    3'b100: alu_op = ALU_XOR;
                    3'b001: alu_op = ALU_SLL;
                    3'b101: alu_op = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    default: alu_op = ALU_ADD;
                endcase
            end

            7'b0010011: begin
                reg_we      = 1'b1;
                alu_src_imm = 1'b1;
                wb_sel      = WB_ALU;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;   // addi
                    3'b111: alu_op = ALU_AND;   // andi
                    3'b110: alu_op = ALU_OR;    // ori
                    3'b100: alu_op = ALU_XOR;   // xori
                    3'b010: alu_op = ALU_SLT;   // slti
                    3'b011: alu_op = ALU_SLTU;  // sltiu
                    3'b001: alu_op = ALU_SLL;   // slli
                    3'b101: alu_op = (imm12[11:5] == 7'b0100000) ? ALU_SRA : ALU_SRL;
                    default: alu_op = ALU_ADD;
                endcase
            end

            7'b0000011: begin
                reg_we      = 1'b1;
                mem_re      = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
                wb_sel      = WB_MEM;

                case (funct3)
                    3'b000: begin mem_size = MEM_BYTE; load_unsigned = 1'b0; end // lb
                    3'b001: begin mem_size = MEM_HALF; load_unsigned = 1'b0; end // lh
                    3'b010: begin mem_size = MEM_WORD; load_unsigned = 1'b0; end // lw
                    3'b100: begin mem_size = MEM_BYTE; load_unsigned = 1'b1; end // lbu
                    3'b101: begin mem_size = MEM_HALF; load_unsigned = 1'b1; end // lhu
                    default: begin mem_size = MEM_WORD; load_unsigned = 1'b0; end
                endcase
            end

            7'b0100011: begin
                mem_we      = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;

                case (funct3)
                    3'b000: mem_size = MEM_BYTE; // sb
                    3'b001: mem_size = MEM_HALF; // sh
                    3'b010: mem_size = MEM_WORD; // sw
                    default: mem_size = MEM_WORD;
                endcase
            end

            7'b1100011: begin
                branch = 1'b1;
                alu_op = ALU_SUB;
            end

            7'b1101111: begin
                jal   = 1'b1;
                reg_we = 1'b1;
                wb_sel = WB_PC4;
            end

            7'b1100111: begin
                jalr       = 1'b1;
                reg_we     = 1'b1;
                wb_sel     = WB_PC4;
                alu_src_imm = 1'b1;
                alu_op     = ALU_ADD;
            end

            7'b0110111: begin
                reg_we = 1'b1;
                wb_sel = WB_IMM_U;
            end

            7'b0010111: begin
                reg_we      = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
                wb_sel      = WB_ALU;
            end
        endcase
    end
endmodule
