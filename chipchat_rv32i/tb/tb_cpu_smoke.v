module tb_cpu_smoke;
  reg clk;
  reg rst_n;
  wire halted;
  wire [31:0] tohost;

  cpu_top dut(
    .clk(clk),
    .rst_n(rst_n),
    .halted(halted),
    .tohost(tohost)
  );

  // Expose register file entries as normal waveform signals
  wire [31:0] x0  = dut.rf.x[0];
  wire [31:0] x1  = dut.rf.x[1];
  wire [31:0] x2  = dut.rf.x[2];
  wire [31:0] x3  = dut.rf.x[3];
  wire [31:0] x4  = dut.rf.x[4];
  wire [31:0] x5  = dut.rf.x[5];
  wire [31:0] x6  = dut.rf.x[6];
  wire [31:0] x7  = dut.rf.x[7];
  wire [31:0] x8  = dut.rf.x[8];
  wire [31:0] x9  = dut.rf.x[9];
  wire [31:0] x10 = dut.rf.x[10];
  wire [31:0] x11 = dut.rf.x[11];
  wire [31:0] x12 = dut.rf.x[12];
  wire [31:0] x13 = dut.rf.x[13];
  wire [31:0] x14 = dut.rf.x[14];
  wire [31:0] x15 = dut.rf.x[15];
  wire [31:0] x16 = dut.rf.x[16];
  wire [31:0] x17 = dut.rf.x[17];
  wire [31:0] x18 = dut.rf.x[18];
  wire [31:0] x19 = dut.rf.x[19];
  wire [31:0] x20 = dut.rf.x[20];
  wire [31:0] x21 = dut.rf.x[21];
  wire [31:0] x22 = dut.rf.x[22];
  wire [31:0] x23 = dut.rf.x[23];
  wire [31:0] x24 = dut.rf.x[24];
  wire [31:0] x25 = dut.rf.x[25];
  wire [31:0] x26 = dut.rf.x[26];
  wire [31:0] x27 = dut.rf.x[27];
  wire [31:0] x28 = dut.rf.x[28];
  wire [31:0] x29 = dut.rf.x[29];
  wire [31:0] x30 = dut.rf.x[30];
  wire [31:0] x31 = dut.rf.x[31];

  initial clk = 0;
  always #1 clk = ~clk;

  initial begin
    $dumpfile("smoke.vcd");
    $dumpvars(0, tb_cpu_smoke);
    $dumpvars(0, tb_cpu_smoke.dut.rf);

    rst_n = 0;
    #5;
    rst_n = 1;

    // run until halted or timeout
    repeat (200) begin
      @(posedge clk);
      if (halted) begin
        $display("HALTED tohost=%0d (0x%08h)", tohost, tohost);
        if (tohost == 32'd12) $display("PASS tb_cpu_smoke");
        else $display("FAIL tb_cpu_smoke");
        $finish;
      end
    end

    $display("TIMEOUT tb_cpu_smoke");
    $finish;
  end
endmodule
