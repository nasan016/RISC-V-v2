module tb_decode;
  reg  [31:0] instr;

  wire reg_we, mem_we, mem_re, alu_src_imm, branch, jal, jalr;
  wire [1:0] wb_sel;
  wire [3:0] alu_op;

  decode dut(
    .instr(instr),
    .reg_we(reg_we),
    .mem_we(mem_we),
    .mem_re(mem_re),
    .alu_src_imm(alu_src_imm),
    .wb_sel(wb_sel),
    .branch(branch),
    .jal(jal),
    .jalr(jalr),
    .alu_op(alu_op)
  );

  task expect1;
    input got, exp;
    input [255:0] name;
    begin
      if (got !== exp) begin
        $display("FAIL %s got=%b exp=%b instr=%h", name, got, exp, instr);
        $finish;
      end
    end
  endtask

  task expectN;
    input [31:0] got, exp;
    input [255:0] name;
    begin
      if (got !== exp) begin
        $display("FAIL %s got=%h exp=%h instr=%h", name, got, exp, instr);
        $finish;
      end
    end
  endtask

  // Helpers to build instructions (only fields that matter)
  function [31:0] R;
    input [6:0] opc; input [2:0] f3; input [6:0] f7;
    begin R = {f7, 5'd2, 5'd1, f3, 5'd3, opc}; end // rs2=2 rs1=1 rd=3
  endfunction
  function [31:0] I;
    input [6:0] opc; input [2:0] f3; input [11:0] imm12;
    begin I = {imm12, 5'd1, f3, 5'd3, opc}; end // rs1=1 rd=3
  endfunction
  function [31:0] S;
    input [6:0] opc; input [2:0] f3; input [11:0] imm12;
    begin S = {imm12[11:5], 5'd2, 5'd1, f3, imm12[4:0], opc}; end // rs2=2 rs1=1
  endfunction
  function [31:0] B;
    input [6:0] opc; input [2:0] f3;
    begin
      // imm doesn't matter for decode; set to 0
      B = {1'b0, 6'b0, 5'd2, 5'd1, f3, 4'b0, 1'b0, opc};
    end
  endfunction
  function [31:0] U;
    input [6:0] opc;
    begin U = {20'hABCDE, 5'd3, opc}; end
  endfunction
  function [31:0] J;
    input [6:0] opc;
    begin J = {1'b0, 8'h0, 1'b0, 10'h0, 5'd3, opc}; end
  endfunction

  initial begin
    // wb_sel: 00=ALU, 01=MEM, 10=PC+4, 11=IMM_U
    // alu_op encoding: 0 ADD,1 SUB,2 AND,3 OR,4 XOR,5 SLL,6 SRL,7 SRA,8 SLT,9 SLTU

    // R-type ADD
    instr = R(7'b0110011, 3'b000, 7'b0000000); #1;
    expect1(reg_we, 1, "R ADD reg_we");
    expect1(alu_src_imm, 0, "R ADD alu_src_imm");
    expectN(alu_op, 4'd0, "R ADD alu_op");
    expectN(wb_sel, 2'd0, "R ADD wb_sel");

    // R-type SUB
    instr = R(7'b0110011, 3'b000, 7'b0100000); #1;
    expectN(alu_op, 4'd1, "R SUB alu_op");

    // I-type ADDI
    instr = I(7'b0010011, 3'b000, 12'h010); #1;
    expect1(reg_we, 1, "I ADDI reg_we");
    expect1(alu_src_imm, 1, "I ADDI alu_src_imm");
    expectN(alu_op, 4'd0, "I ADDI alu_op");
    expectN(wb_sel, 2'd0, "I ADDI wb_sel");

    // I-type SRAI (funct3=101, imm[11:5]=0100000)
    instr = I(7'b0010011, 3'b101, {7'b0100000,5'd3}); #1;
    expectN(alu_op, 4'd7, "I SRAI alu_op");

    // LW (LOAD)
    instr = I(7'b0000011, 3'b010, 12'h000); #1;
    expect1(reg_we, 1, "LW reg_we");
    expect1(mem_re, 1, "LW mem_re");
    expectN(wb_sel, 2'd1, "LW wb_sel=MEM");
    expectN(alu_op, 4'd0, "LW uses ADD for addr");
    expect1(alu_src_imm, 1, "LW alu_src_imm");

    // SW (STORE)
    instr = S(7'b0100011, 3'b010, 12'h000); #1;
    expect1(mem_we, 1, "SW mem_we");
    expect1(reg_we, 0, "SW reg_we=0");
    expectN(alu_op, 4'd0, "SW addr add");
    expect1(alu_src_imm, 1, "SW alu_src_imm");

    // BEQ (BRANCH)
    instr = B(7'b1100011, 3'b000); #1;
    expect1(branch, 1, "BEQ branch=1");
    expect1(reg_we, 0, "BEQ reg_we=0");
    expectN(alu_op, 4'd1, "BEQ uses SUB (optional but we enforce)"); // common design

    // JAL
    instr = J(7'b1101111); #1;
    expect1(jal, 1, "JAL jal=1");
    expect1(reg_we, 1, "JAL reg_we=1");
    expectN(wb_sel, 2'd2, "JAL wb_sel=PC+4");

    // JALR
    instr = I(7'b1100111, 3'b000, 12'h000); #1;
    expect1(jalr, 1, "JALR jalr=1");
    expect1(reg_we, 1, "JALR reg_we=1");
    expectN(wb_sel, 2'd2, "JALR wb_sel=PC+4");
    expectN(alu_op, 4'd0, "JALR uses ADD for target");
    expect1(alu_src_imm, 1, "JALR alu_src_imm");

    // LUI (U-type)
    instr = U(7'b0110111); #1;
    expect1(reg_we, 1, "LUI reg_we=1");
    expectN(wb_sel, 2'd3, "LUI wb_sel=IMM_U");

    // AUIPC (U-type) - we treat as ALU op ADD with src=imm, wb_sel=ALU
    instr = U(7'b0010111); #1;
    expect1(reg_we, 1, "AUIPC reg_we=1");
    expect1(alu_src_imm, 1, "AUIPC alu_src_imm=1");
    expectN(alu_op, 4'd0, "AUIPC alu_op=ADD");
    expectN(wb_sel, 2'd0, "AUIPC wb_sel=ALU");

    $display("ALL DECODE TESTS PASSED");
    $finish;
  end
endmodule
