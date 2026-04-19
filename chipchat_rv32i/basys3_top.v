module basys3_top (
    input  wire        clk,     // 100 MHz Basys3 clock
    input  wire        btnC,    // center button = reset
    input  wire [15:0] sw,      // optional: use switches to choose clock speed
    output wire [15:0] led,     // LEDs show halted + tohost
    output wire [6:0]  seg,     // 7-seg off
    output wire [3:0]  an,      // 7-seg off
    output wire        dp       // 7-seg off
);

    // ------------------------------------------------------------
    // Clock divider
    // ------------------------------------------------------------
    reg [31:0] div = 32'd0;

    always @(posedge clk) begin
        div <= div + 32'd1;
    end

    // Choose CPU speed with switches:
    // sw[2:0] = 000 -> div[20]
    // sw[2:0] = 001 -> div[21]
    // sw[2:0] = 010 -> div[22]
    // sw[2:0] = 011 -> div[23]
    // sw[2:0] = 100 -> div[24]
    // sw[2:0] = 101 -> div[25]
    // sw[2:0] = 110 -> div[26]
    // sw[2:0] = 111 -> div[27]
    reg cpu_clk;

    always @(*) begin
        case (sw[2:0])
            3'b000: cpu_clk = div[20];
            3'b001: cpu_clk = div[21];
            3'b010: cpu_clk = div[22];
            3'b011: cpu_clk = div[23];
            3'b100: cpu_clk = div[24];
            3'b101: cpu_clk = div[25];
            3'b110: cpu_clk = div[26];
            3'b111: cpu_clk = div[27];
            default: cpu_clk = div[24];
        endcase
    end

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

    cpu_top dut (
        .clk    (cpu_clk),
        .rst_n  (rst_n),
        .halted (halted),
        .tohost (tohost)
    );

    // ------------------------------------------------------------
    // LEDs
    // led[15]   = halted
    // led[14:0] = low 15 bits of tohost
    //
    // For your smoke test, expected final tohost = 12
    // so when halted goes high, LEDs should show that value.
    // ------------------------------------------------------------
    assign led[15]   = halted;
    assign led[14:0] = tohost[14:0];

    // ------------------------------------------------------------
    // Turn off 7-segment display
    // Basys3 7-seg is active low
    // ------------------------------------------------------------
    assign seg = 7'b1111111;
    assign an  = 4'b1111;
    assign dp  = 1'b1;

endmodule
