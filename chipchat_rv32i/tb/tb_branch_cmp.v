module tb_branch_cmp;
  reg  [2:0] funct3;
  reg  [31:0] rs1, rs2;
  wire take;

  branch_cmp dut(.funct3(funct3), .rs1(rs1), .rs2(rs2), .take(take));

  task check;
    input [2:0] f3;
    input [31:0] a, b;
    input exp;
    input [255:0] name;
    begin
      funct3 = f3; rs1 = a; rs2 = b;
      #1;
      if (take !== exp) begin
        $display("FAIL %s f3=%b rs1=%h rs2=%h got=%b exp=%b", name, f3, a, b, take, exp);
        $finish;
      end else begin
        $display("PASS %s", name);
      end
    end
  endtask

  initial begin
    // funct3 meanings for branches:
    // 000 BEQ, 001 BNE, 100 BLT, 101 BGE, 110 BLTU, 111 BGEU

    // BEQ / BNE
    check(3'b000, 32'h5, 32'h5, 1'b1, "BEQ true");
    check(3'b000, 32'h5, 32'h6, 1'b0, "BEQ false");
    check(3'b001, 32'h5, 32'h6, 1'b1, "BNE true");
    check(3'b001, 32'h5, 32'h5, 1'b0, "BNE false");

    // Signed compares
    check(3'b100, 32'hFFFF_FFFF, 32'h0000_0001, 1'b1, "BLT signed (-1 < 1)");
    check(3'b101, 32'hFFFF_FFFF, 32'h0000_0001, 1'b0, "BGE signed (-1 >= 1) false");
    check(3'b100, 32'h8000_0000, 32'h0000_0000, 1'b1, "BLT signed (minint < 0)");
    check(3'b101, 32'h0000_0000, 32'h8000_0000, 1'b1, "BGE signed (0 >= minint)");

    // Unsigned compares
    check(3'b110, 32'hFFFF_FFFF, 32'h0000_0001, 1'b0, "BLTU unsigned (max < 1) false");
    check(3'b111, 32'hFFFF_FFFF, 32'h0000_0001, 1'b1, "BGEU unsigned (max >= 1) true");
    check(3'b110, 32'h0000_0000, 32'h8000_0000, 1'b1, "BLTU unsigned (0 < 0x80000000)");
    check(3'b111, 32'h0000_0000, 32'h8000_0000, 1'b0, "BGEU unsigned (0 >= 0x80000000) false");

    $display("ALL BRANCH_CMP TESTS PASSED");
    $finish;
  end
endmodule
