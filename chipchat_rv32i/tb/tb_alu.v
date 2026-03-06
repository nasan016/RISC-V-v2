module tb_alu;
  reg  [31:0] a, b;
  reg  [3:0]  op;
  wire [31:0] y;
  wire        zero;

  alu dut(.a(a), .b(b), .op(op), .y(y), .zero(zero));

  // Reference helpers
  function [31:0] ref_alu;
    input [31:0] aa, bb;
    input [3:0]  oop;
    reg signed [31:0] as, bs;
    begin
      as = aa;
      bs = bb;
      case (oop)
        4'd0: ref_alu = aa + bb;
        4'd1: ref_alu = aa - bb;
        4'd2: ref_alu = aa & bb;
        4'd3: ref_alu = aa | bb;
        4'd4: ref_alu = aa ^ bb;
        4'd5: ref_alu = aa << bb[4:0];
        4'd6: ref_alu = aa >> bb[4:0];
        4'd7: ref_alu = as >>> bb[4:0];
        4'd8: ref_alu = (as < bs) ? 32'd1 : 32'd0;
        4'd9: ref_alu = (aa < bb) ? 32'd1 : 32'd0;
        default: ref_alu = 32'h0;
      endcase
    end
  endfunction

  task check;
    input [31:0] aa, bb;
    input [3:0]  oop;
    reg   [31:0] exp;
    begin
      a = aa; b = bb; op = oop;
      #1; // settle
      exp = ref_alu(aa, bb, oop);
      if (y !== exp) begin
        $display("FAIL: op=%0d a=%h b=%h got=%h exp=%h", oop, aa, bb, y, exp);
        $finish;
      end
      if (zero !== (exp==32'h0)) begin
        $display("FAIL zero: op=%0d a=%h b=%h got=%b exp=%b", oop, aa, bb, zero, (exp==32'h0));
        $finish;
      end
    end
  endtask

  integer i;
  reg [31:0] seed;

  initial begin
    seed = 32'hC0FFEE01;

    // Directed edge cases
    check(32'h00000000, 32'h00000000, 4'd0);
    check(32'hFFFFFFFF, 32'h00000001, 4'd0); // wrap
    check(32'h00000000, 32'h00000001, 4'd1);
    check(32'h80000000, 32'h0000001F, 4'd7); // SRA big shift
    check(32'h80000000, 32'h0000001F, 4'd6); // SRL
    check(32'h00000001, 32'h0000001F, 4'd5); // SLL
    check(32'hFFFFFFFF, 32'h00000001, 4'd8); // SLT signed (-1 < 1) true
    check(32'hFFFFFFFF, 32'h00000001, 4'd9); // SLTU unsigned (max < 1) false

    // Randomized regression (fixed seed)
    for (i = 0; i < 200; i = i + 1) begin
      seed = seed * 32'h0019660D + 32'h3C6EF35F; // LCG
      check(seed, seed ^ 32'hA5A5A5A5, i % 10);
    end

    $display("PASS tb_alu");
    $finish;
  end
endmodule
