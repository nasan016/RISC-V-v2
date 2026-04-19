module tb_imem;
  reg  [31:0] addr;
  wire [31:0] instr;

  imem #(.HEX_FILE("tests/prog_imem_unit.hex")) dut(.addr(addr), .instr(instr));

  initial begin
    // preload with known pattern (we'll do it via initial block in imem for now)
    addr = 32'h0; #1;
    if (instr !== 32'h11111111) begin $display("FAIL imem[0]"); $finish; end

    addr = 32'h4; #1;
    if (instr !== 32'h22222222) begin $display("FAIL imem[1]"); $finish; end

    addr = 32'h8; #1;
    if (instr !== 32'h33333333) begin $display("FAIL imem[2]"); $finish; end

    $display("ALL IMEM TESTS PASSED");
    $finish;
  end
endmodule
