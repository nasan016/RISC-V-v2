module basys3_top (
    input  wire        clk,     // 100 MHz Basys3 clock
    input  wire        btnC,    // center button = reset
    input  wire        RsRx,    // USB UART receive into FPGA
    output wire        RsTx,    // USB UART transmit from FPGA
    input  wire [15:0] sw,      // switches are mirrored onto LEDs for debug
    output wire [15:0] led,     // LEDs show UART/CPU debug state
    output wire [6:0]  seg,     // 7-seg off
    output wire [3:0]  an,      // 7-seg off
    output wire        dp       // 7-seg off
);

    // ------------------------------------------------------------
    // Reset
    // btnC pressed => reset asserted
    // cpu_top expects active-low reset
    // ------------------------------------------------------------
    wire rst_n = ~btnC;

    // ------------------------------------------------------------
    // CPU
    // ------------------------------------------------------------
    wire        halted;
    wire [31:0] tohost;
    wire [7:0]  uart_rx_data;
    wire        uart_rx_valid;
    wire        uart_rx_consume;
    wire [7:0]  uart_tx_data;
    wire        uart_tx_start;
    wire        uart_tx_busy;

    uart_rx #(
        .CLKS_PER_BIT(868)
    ) uart_rx0 (
        .clk     (clk),
        .rst_n   (rst_n),
        .rx      (RsRx),
        .consume (uart_rx_consume),
        .data    (uart_rx_data),
        .valid   (uart_rx_valid)
    );

    uart_tx #(
        .CLKS_PER_BIT(868)
    ) uart_tx0 (
        .clk   (clk),
        .rst_n (rst_n),
        .data  (uart_tx_data),
        .start (uart_tx_start),
        .tx    (RsTx),
        .busy  (uart_tx_busy)
    );

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
        .uart_tx_busy    (uart_tx_busy),
        .halted          (halted),
        .tohost          (tohost)
    );

    // ------------------------------------------------------------
    // LEDs
    // led[15]   = halted
    // led[14]   = RX byte waiting
    // led[13]   = TX ready
    // led[12:8] = sw[4:0]
    // led[7:0]  = low byte of tohost
    // ------------------------------------------------------------
    assign led[15]   = halted;
    assign led[14]   = uart_rx_valid;
    assign led[13]   = ~uart_tx_busy;
    assign led[12:0] = {sw[4:0], tohost[7:0]};

    // ------------------------------------------------------------
    // Turn off 7-segment display
    // Basys3 7-seg is active low
    // ------------------------------------------------------------
    assign seg = 7'b1111111;
    assign an  = 4'b1111;
    assign dp  = 1'b1;

endmodule
