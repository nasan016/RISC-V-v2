module tb_regfile;
    reg clk;
    reg we;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;

    // This instantiates the module located in chipchat_rv32i/rtl/regfile.v
    regfile dut(
        .clk(clk),
        .we(we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    // Clock generation
    initial clk = 0;
    always #1 clk = ~clk;

    // Standard check task
    task check;
        input [31:0] got, exp;
        input [255:0] msg;
        begin
            if (got !== exp) begin
                $display("FAIL %s | got=%h exp=%h", msg, got, exp);
                $finish;
            end else begin
                $display("PASS %s", msg);
            end
        end
    endtask

    initial begin
        // Reset signals
        we = 0; rs1 = 0; rs2 = 0; rd = 0; wd = 0;
        #5;

        // 1. Verify x0 is strictly 0 (RISC-V Requirement)
        rs1 = 0; 
        #1; check(rd1, 32'h0, "x0_is_zero_at_init");

        // 2. Write and Read back x1
        we = 1; rd = 5'd1; wd = 32'h12345678;
        @(posedge clk); 
        #1; we = 0; rs1 = 5'd1;
        #1; check(rd1, 32'h12345678, "write_read_x1");

        // 3. Attempt write to x0 (Must fail)
        we = 1; rd = 5'd0; wd = 32'hFFFFFFFF;
        @(posedge clk);
        #1; we = 0; rs1 = 5'd0;
        #1; check(rd1, 32'h0, "x0_write_protection");

        // 4. Dual port check (Read x1 and x2 simultaneously)
        we = 1; rd = 5'd2; wd = 32'hABCDEF00;
        @(posedge clk);
        #1; we = 0; rs1 = 5'd1; rs2 = 5'd2;
        #1; 
        check(rd1, 32'h12345678, "dual_read_rs1");
        check(rd2, 32'hABCDEF00, "dual_read_rs2");

        $display("ALL REGFILE TESTS PASSED");
        $finish;
    end
endmodule
