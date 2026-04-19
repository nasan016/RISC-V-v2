module uart_tx #(
    parameter integer CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,
    input  wire       start,
    output reg        tx,
    output wire       busy
);

    localparam [2:0] S_IDLE  = 3'd0;
    localparam [2:0] S_START = 3'd1;
    localparam [2:0] S_DATA  = 3'd2;
    localparam [2:0] S_STOP  = 3'd3;

    reg [2:0] state;
    reg [31:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] shifter;

    assign busy = (state != S_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_count <= 32'd0;
            bit_index <= 3'd0;
            shifter   <= 8'd0;
            tx        <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= 32'd0;
                    bit_index <= 3'd0;
                    if (start) begin
                        shifter <= data;
                        state   <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 32'd0;
                        state     <= S_DATA;
                    end else begin
                        clk_count <= clk_count + 32'd1;
                    end
                end

                S_DATA: begin
                    tx <= shifter[bit_index];
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 32'd0;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= S_STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end else begin
                        clk_count <= clk_count + 32'd1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 32'd0;
                        state     <= S_IDLE;
                    end else begin
                        clk_count <= clk_count + 32'd1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    tx    <= 1'b1;
                end
            endcase
        end
    end
endmodule
