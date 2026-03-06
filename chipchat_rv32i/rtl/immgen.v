module immgen(
  input  [31:0] instr,
  output reg [31:0] imm
);

  wire [6:0] opcode = instr[6:0];

  // Immediate extraction
  wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
  wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [31:0] imm_u = {instr[31:12], 12'b0};
  wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

  always @(*) begin
    case (opcode)
      7'b0010011, // OP-IMM
      7'b0000011, // LOAD
      7'b1100111: // JALR
        imm = imm_i;
      7'b0100011: // STORE
        imm = imm_s;
      7'b1100011: // BRANCH
        imm = imm_b;
      7'b0110111, // LUI
      7'b0010111: // AUIPC
        imm = imm_u;
      7'b1101111: // JAL
        imm = imm_j;
      default:
        imm = imm_i;
    endcase
  end

endmodule