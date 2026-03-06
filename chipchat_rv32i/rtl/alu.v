module alu(
    input [31:0] a,
    input [31:0] b,
    input [3:0] op,
    output reg [31:0] y,
    output zero
);

always @(*) begin
    case (op)
        4'd0:  y = a + b;                              // ADD
        4'd1:  y = a - b;                              // SUB
        4'd2:  y = a & b;                              // AND
        4'd3:  y = a | b;                              // OR
        4'd4:  y = a ^ b;                              // XOR
        4'd5:  y = a << b[4:0];                        // SLL
        4'd6:  y = a >> b[4:0];                        // SRL
        4'd7:  y = $signed(a) >>> b[4:0];              // SRA (arithmetic)
        4'd8:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
        4'd9:  y = (a < b) ? 32'd1 : 32'd0;            // SLTU
        default: y = 32'd0;
    endcase
end

assign zero = (y == 32'd0);

endmodule