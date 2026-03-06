module regfile (
    input         clk,
    input         we,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);

    reg [31:0] x[31:0];
    integer i;

    // Synchronous write
    always @(posedge clk) begin
        if (we && (rd != 5'd0)) begin
            x[rd] <= wd;
        end
    end

    // Optional: initialize x0 to 0 at start-up (XMR safety, not strictly required after reset)
    // But written value shouldn't ever propagate to x0 thanks to logic in reads/writes

    // Combinational reads
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : x[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : x[rs2];

endmodule