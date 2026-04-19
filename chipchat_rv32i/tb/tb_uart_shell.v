module tb_uart_shell;
    localparam integer INPUT_LEN  = 28;
    localparam integer EXPECT_LEN = 91;

    localparam [8*INPUT_LEN-1:0] INPUT_BYTES =
        "hello bob\015./fact 5\015./fib 10\015";

    localparam [8*EXPECT_LEN-1:0] EXPECT_BYTES =
        "\015\nRV32I ready\015\nrv32> hello bob\015\nhello bob!\015\nrv32> ./fact 5\015\n120\015\nrv32> ./fib 10\015\n55\015\nrv32> ";

    reg clk;
    reg rst_n;
    reg [7:0] uart_rx_data;
    reg uart_rx_valid;
    wire uart_rx_consume;
    wire [7:0] uart_tx_data;
    wire uart_tx_start;
    wire halted;
    wire [31:0] tohost;

    integer input_idx;
    integer expect_idx;
    integer cycles;

    cpu_top #(
        .HEX_FILE("tests/uart_shell.hex")
    ) dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .uart_rx_data    (uart_rx_data),
        .uart_rx_valid   (uart_rx_valid),
        .uart_rx_consume (uart_rx_consume),
        .uart_tx_data    (uart_tx_data),
        .uart_tx_start   (uart_tx_start),
        .uart_tx_busy    (1'b0),
        .halted          (halted),
        .tohost          (tohost)
    );

    function [7:0] input_at;
        input integer idx;
        begin
            input_at = INPUT_BYTES[8*(INPUT_LEN - 1 - idx) +: 8];
        end
    endfunction

    function [7:0] expect_at;
        input integer idx;
        begin
            expect_at = EXPECT_BYTES[8*(EXPECT_LEN - 1 - idx) +: 8];
        end
    endfunction

    initial clk = 0;
    always #1 clk = ~clk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rx_valid <= 1'b0;
            uart_rx_data  <= 8'd0;
            input_idx     <= 0;
        end else begin
            if (uart_rx_consume) begin
                uart_rx_valid <= 1'b0;
                input_idx <= input_idx + 1;
            end else if (!uart_rx_valid && input_idx < INPUT_LEN) begin
                uart_rx_data  <= input_at(input_idx);
                uart_rx_valid <= 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expect_idx <= 0;
        end else if (uart_tx_start) begin
            $write("%c", uart_tx_data);
            if (expect_idx >= EXPECT_LEN) begin
                $display("\nFAIL tb_uart_shell extra output 0x%02h", uart_tx_data);
                $finish;
            end
            if (uart_tx_data !== expect_at(expect_idx)) begin
                $display("\nFAIL tb_uart_shell at output %0d expected 0x%02h got 0x%02h",
                         expect_idx, expect_at(expect_idx), uart_tx_data);
                $finish;
            end
            expect_idx <= expect_idx + 1;
        end
    end

    initial begin
        rst_n = 0;
        cycles = 0;
        #5;
        rst_n = 1;

        while (cycles < 20000) begin
            @(posedge clk);
            cycles = cycles + 1;
            if (expect_idx == EXPECT_LEN) begin
                $display("\nPASS tb_uart_shell");
                $finish;
            end
        end

        $display("\nTIMEOUT tb_uart_shell output_idx=%0d input_idx=%0d", expect_idx, input_idx);
        $finish;
    end
endmodule
