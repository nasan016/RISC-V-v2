module tb_cpu_alu_ops;
    reg clk;
    reg rst_n;
    wire halted;
    wire [31:0] tohost;

    cpu_top #(
        .HEX_FILE("tests/prog_alu_ops.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .halted(halted),
        .tohost(tohost)
    );

    initial clk = 0;
    always #1 clk = ~clk;

    initial begin
        rst_n = 0;
        #5;
        rst_n = 1;

        repeat (200) begin
            @(posedge clk);
            if (halted) begin
                $display("HALTED tohost=%0d (0x%08h)", tohost, tohost);
                if (tohost == 32'd7) $display("PASS tb_cpu_alu_ops");
                else $display("FAIL tb_cpu_alu_ops");
                $finish;
            end
        end

        $display("TIMEOUT tb_cpu_alu_ops");
        $finish;
    end
endmodule
