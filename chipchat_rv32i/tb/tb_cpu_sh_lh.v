module tb_cpu_sh_lh;
    reg clk;
    reg rst_n;
    wire halted;
    wire [31:0] tohost;

    cpu_top #(
        .HEX_FILE("tests/prog_sh_lh.hex")
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
                $display("HALTED tohost=0x%08h", tohost);
                if (tohost == 32'hFFFF8000)
                    $display("PASS tb_cpu_sh_lh");
                else
                    $display("FAIL tb_cpu_sh_lh");
                $finish;
            end
        end

        $display("TIMEOUT tb_cpu_sh_lh");
        $finish;
    end
endmodule
