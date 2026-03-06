module dmem(
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);

reg [31:0] ram [0:1023];
wire [9:0] idx = addr[11:2];

always @(posedge clk) begin
    if (we) begin
        ram[idx] <= wdata;
    end
end

assign rdata = ram[idx];

endmodule