module pc_next(
    input  [31:0] pc,
    input  [31:0] rs1,
    input  [31:0] imm,
    input         branch,
    input         jal,
    input         jalr,
    input         take_branch,
    output reg [31:0] pc_next
);

always @* begin
    if (jalr) begin
        pc_next = (rs1 + imm) & 32'hFFFF_FFFE;
    end else if (jal) begin
        pc_next = pc + imm;
    end else if (branch && take_branch) begin
        pc_next = pc + imm;
    end else begin
        pc_next = pc + 32'd4;
    end
end

endmodule