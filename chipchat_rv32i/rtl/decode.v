module decode(
    input  [31:0] instr,
    output reg reg_we,
    output reg mem_we,
    output reg mem_re,
    output reg alu_src_imm,
    output reg [1:0] wb_sel,
    output reg branch,
    output reg jal,
    output reg jalr,
    output reg [3:0] alu_op
);

    // ALU OPs
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

    // WB SEL
    localparam WB_ALU   = 2'd0;
    localparam WB_MEM   = 2'd1;
    localparam WB_PC4   = 2'd2;
    localparam WB_IMM_U = 2'd3;

    wire [6:0] opcode  = instr[6:0];
    wire [2:0] funct3  = instr[14:12];
    wire [6:0] funct7  = instr[31:25];
    wire [4:0] shamt   = instr[24:20];
    wire [11:0] imm12  = instr[31:20];
    wire [6:0] imm7    = instr[31:25];
    wire [4:0] imm5    = instr[11:7];

    always @(*) begin
        // defaults (safe, zero)
        reg_we      = 1'b0;
        mem_we      = 1'b0;
        mem_re      = 1'b0;
        alu_src_imm = 1'b0;
        wb_sel      = WB_ALU;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        alu_op      = ALU_ADD;

        case (opcode)
            7'b0110011: begin // R-type
                reg_we      = 1'b1;
                alu_src_imm = 1'b0;
                wb_sel      = WB_ALU;
                mem_we      = 1'b0;
                mem_re      = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                case (funct3)
                    3'b000: alu_op = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD; // SUB or ADD
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
            7'b0010011: begin // I-type (OP-IMM)
                reg_we      = 1'b1;
                alu_src_imm = 1'b1;
                wb_sel      = WB_ALU;
                case (funct3)
                    3'b000: alu_op = ALU_ADD; // ADDI
                    3'b111: alu_op = ALU_AND; // ANDI
                    3'b110: alu_op = ALU_OR;  // ORI
                    3'b100: alu_op = ALU_XOR; // XORI
                    3'b010: alu_op = ALU_SLT; // SLTI
                    3'b011: alu_op = ALU_SLTU;// SLTIU
                    3'b001: alu_op = ALU_SLL; // SLLI (ignore upper bits for shamt, hardware will do the check)
                    3'b101: begin // SRLI/SRAI
                        if (imm12[11:5] == 7'b0100000)
                            alu_op = ALU_SRA; // SRAI
                        else
                            alu_op = ALU_SRL; // SRLI
                    end
                    default: alu_op = ALU_ADD;
                endcase
            end
            7'b0000011: begin // LOAD (assume LW, funct3=010)
                reg_we      = 1'b1;
                mem_re      = 1'b1;
                mem_we      = 1'b0;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
                wb_sel      = WB_MEM;
            end
            7'b0100011: begin // STORE (assume SW, funct3=010)
                reg_we      = 1'b0;
                mem_we      = 1'b1;
                mem_re      = 1'b0;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
                wb_sel      = WB_ALU;
            end
            7'b1100011: begin // BRANCH
                branch      = 1'b1;
                reg_we      = 1'b0;
                mem_we      = 1'b0;
                mem_re      = 1'b0;
                alu_src_imm = 1'b0;
                wb_sel      = WB_ALU;
                alu_op      = ALU_SUB; // For comparison
            end
            7'b1101111: begin // JAL
                jal         = 1'b1;
                reg_we      = 1'b1;
                wb_sel      = WB_PC4;
                mem_we      = 1'b0;
                mem_re      = 1'b0;
                branch      = 1'b0;
                alu_src_imm = 1'b0;
            end
            7'b1100111: begin // JALR
                jalr        = 1'b1;
                reg_we      = 1'b1;
                wb_sel      = WB_PC4;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
            end
            7'b0110111: begin // LUI
                reg_we      = 1'b1;
                wb_sel      = WB_IMM_U;
                // alu_src_imm, alu_op = default (0, ADD)
            end
            7'b0010111: begin // AUIPC
                reg_we      = 1'b1;
                alu_src_imm = 1'b1;
                alu_op      = ALU_ADD;
                wb_sel      = WB_ALU;
            end
            default: begin
                // safe defaults already set
            end
        endcase
    end

endmodule