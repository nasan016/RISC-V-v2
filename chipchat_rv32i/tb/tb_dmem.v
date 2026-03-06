module tb_dmem;
  reg clk;
  reg we;
  reg [31:0] addr;
  reg [31:0] wdata;
  wire [31:0] rdata;

  dmem dut(.clk(clk), .we(we), .addr(addr), .wdata(wdata), .rdata(rdata));

  initial clk = 0;
  always #1 clk = ~clk;

  task rd_expect;
    input [31:0] a;
    input [31:0] exp;
    input [255:0] name;
    begin
      we = 0;
      addr = a;
      #2; // settle combinational read
      if (rdata !== exp) begin
        $display("FAIL %s addr=%h got=%h exp=%h", name, a, rdata, exp);
        $finish;
      end else begin
        $display("PASS %s", name);
      end
    end
  endtask

  initial begin
    $display("Starting DMEM Tests...");
    we = 0; addr = 0; wdata = 0;
    #2;

    // Write word0 @0x0
    we = 1; addr = 32'h0; wdata = 32'hDEAD_BEEF;
    @(posedge clk); #1;
    we = 0;

    // Write word1 @0x4
    we = 1; addr = 32'h4; wdata = 32'h1234_5678;
    @(posedge clk); #1;
    we = 0;

    // Read back explicitly
    rd_expect(32'h0, 32'hDEAD_BEEF, "read @0");
    rd_expect(32'h4, 32'h1234_5678, "read @4");

    $display("ALL DMEM TESTS PASSED");
    $finish;
  end
endmodule
