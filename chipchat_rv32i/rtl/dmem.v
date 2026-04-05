module dmem(
    input         clk,
    input         we,
    input  [1:0]  mem_size,   // 00=byte, 01=half, 10=word
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);

    localparam MEM_BYTE = 2'd0;
    localparam MEM_HALF = 2'd1;
    localparam MEM_WORD = 2'd2;

    reg [31:0] ram [0:1023];
    wire [9:0] idx = addr[11:2];
    wire [1:0] byte_off = addr[1:0];

    reg [31:0] next_word;

    always @(*) begin
        next_word = ram[idx];
        case (mem_size)
            MEM_BYTE: begin
                case (byte_off)
                    2'd0: next_word[7:0]   = wdata[7:0];
                    2'd1: next_word[15:8]  = wdata[7:0];
                    2'd2: next_word[23:16] = wdata[7:0];
                    2'd3: next_word[31:24] = wdata[7:0];
                endcase
            end

            MEM_HALF: begin
                case (byte_off[1])
                    1'b0: next_word[15:0]  = wdata[15:0];
                    1'b1: next_word[31:16] = wdata[15:0];
                endcase
            end

            MEM_WORD: begin
                next_word = wdata;
            end

            default: begin
                next_word = ram[idx];
            end
        endcase
    end

    always @(posedge clk) begin
        if (we) begin
            ram[idx] <= next_word;
        end
    end

    assign rdata = ram[idx];
endmodule
