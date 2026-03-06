module tb_pc_next;
  reg  [31:0] pc, rs1, imm;
  reg  branch, jal, jalr, take_branch;
  wire [31:0] pc_next;

  pc_next dut(
    .pc(pc),
    .rs1(rs1),
    .imm(imm),
    .branch(branch),
    .jal(jal),
    .jalr(jalr),
    .take_branch(take_branch),
    .pc_next(pc_next)
  );

  task check;
    input [31:0] pc_in, rs1_in, imm_in;
    input br, j, jr, tk;
    input [31:0] exp;
    input [255:0] name;
    begin
      pc = pc_in; rs1 = rs1_in; imm = imm_in;
      branch = br; jal = j; jalr = jr; take_branch = tk;
      #1;
      if (pc_next !== exp) begin
        $display("FAIL %s got=%h exp=%h", name, pc_next, exp);
        $finish;
      end else begin
        $display("PASS %s", name);
      end
    end
  endtask

  initial begin
    // default pc+4
    check(32'h0000_1000, 0, 0, 0,0,0,0, 32'h0000_1004, "pc+4 default");

    // branch not taken
    check(32'h0000_1000, 0, 32'h0000_0010, 1,0,0,0, 32'h0000_1004, "branch not taken");

    // branch taken: pc + imm
    check(32'h0000_1000, 0, 32'hFFFF_FFFC, 1,0,0,1, 32'h0000_0FFC, "branch taken -4");

    // jal: pc + imm
    check(32'h0000_2000, 0, 32'h0000_0800, 0,1,0,0, 32'h0000_2800, "jal +2048");

    // jalr: (rs1 + imm) & ~1
    check(32'h0000_0000, 32'h0000_3001, 32'h0000_0003, 0,0,1,0, 32'h0000_3004, "jalr align");

    // priority: jal beats branch
    check(32'h0000_1000, 0, 32'h0000_0010, 1,1,0,1, 32'h0000_1010, "jal priority over branch");

    // priority: jalr beats jal
    check(32'h0000_1000, 32'h0000_4000, 32'h0000_0004, 0,1,1,0, 32'h0000_4004, "jalr priority over jal");

    $display("ALL PC_NEXT TESTS PASSED");
    $finish;
  end
endmodule
