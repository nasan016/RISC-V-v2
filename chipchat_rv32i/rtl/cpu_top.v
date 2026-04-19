module cpu_top #(
    parameter HEX_FILE = "tests/prog.hex"
)(
    input clk,
    input rst_n,
    input      [7:0] uart_rx_data,
    input            uart_rx_valid,
    output           uart_rx_consume,
    output     [7:0] uart_tx_data,
    output           uart_tx_start,
    input            uart_tx_busy,
    output reg halted,
    output reg [31:0] tohost
);

    localparam [31:0] TOHOST_ADDR = 32'h0000_0100;
    localparam [31:0] UART_BASE   = 32'h1000_0000;

    localparam MEM_BYTE = 2'd0;
    localparam MEM_HALF = 2'd1;
    localparam MEM_WORD = 2'd2;

    reg [31:0] pc;

    wire [31:0] instr;
    imem #(.HEX_FILE(HEX_FILE)) im (
        .addr(pc),
        .instr(instr)
    );

    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];

    wire       reg_we;
    wire       mem_we;
    wire       mem_re;
    wire       alu_src_imm;
    wire [1:0] wb_sel;
    wire       branch;
    wire       jal;
    wire       jalr;
    wire [3:0] alu_op;
    wire [1:0] mem_size;
    wire       load_unsigned;

    decode dec (
        .instr(instr),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .alu_src_imm(alu_src_imm),
        .wb_sel(wb_sel),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .alu_op(alu_op),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned)
    );

    wire [31:0] imm;
    immgen ig (
        .instr(instr),
        .imm(imm)
    );

    wire [31:0] rs1_val;
    wire [31:0] rs2_val;
    reg  [31:0] wb_data;
    wire reg_we_actual = reg_we & ~halted;

    regfile rf (
        .clk(clk),
        .we(reg_we_actual),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wb_data),
        .rd1(rs1_val),
        .rd2(rs2_val)
    );

    wire [31:0] alu_b = alu_src_imm ? imm : rs2_val;
    wire [31:0] alu_y;
    wire        alu_zero;

    alu ualu (
        .a(rs1_val),
        .b(alu_b),
        .op(alu_op),
        .y(alu_y),
        .zero(alu_zero)
    );

    wire take_branch;
    branch_cmp bc (
        .funct3(funct3),
        .rs1(rs1_val),
        .rs2(rs2_val),
        .take(take_branch)
    );

    wire [31:0] dmem_rdata;
    wire uart_hit       = (alu_y[31:4] == UART_BASE[31:4]);
    wire uart_tx_hit    = uart_hit && (alu_y[3:0] == 4'h0);
    wire uart_rx_hit    = uart_hit && (alu_y[3:0] == 4'h4);
    wire uart_stat_hit  = uart_hit && (alu_y[3:0] == 4'h8);
    wire uart_tx_ready  = !(uart_tx_busy === 1'b1);
    wire uart_rx_ready  = (uart_rx_valid === 1'b1);
    wire tohost_hit     = mem_we && (alu_y == TOHOST_ADDR);
    wire dmem_we_actual = mem_we & ~halted & ~tohost_hit & ~uart_hit;

    assign uart_tx_data    = rs2_val[7:0];
    assign uart_tx_start   = mem_we & ~halted & uart_tx_hit & uart_tx_ready;
    assign uart_rx_consume = mem_re & ~halted & uart_rx_hit & uart_rx_ready;

    dmem dm (
        .clk(clk),
        .we(dmem_we_actual),
        .mem_size(mem_size),
        .addr(alu_y),
        .wdata(rs2_val),
        .rdata(dmem_rdata)
    );

    wire [31:0] uart_rdata =
        uart_rx_hit   ? {24'b0, uart_rx_data} :
        uart_stat_hit ? {30'b0, uart_tx_ready, uart_rx_ready} :
                        32'b0;

    wire [31:0] mem_rdata = uart_hit ? uart_rdata : dmem_rdata;

    wire [7:0] load_byte =
        (alu_y[1:0] == 2'd0) ? mem_rdata[7:0]   :
        (alu_y[1:0] == 2'd1) ? mem_rdata[15:8]  :
        (alu_y[1:0] == 2'd2) ? mem_rdata[23:16] :
                               mem_rdata[31:24];

    wire [15:0] load_half =
        alu_y[1] ? mem_rdata[31:16] : mem_rdata[15:0];

    reg [31:0] load_data_ext;
    always @(*) begin
        case (mem_size)
            MEM_BYTE: load_data_ext =
                load_unsigned ? {24'b0, load_byte} : {{24{load_byte[7]}}, load_byte};

            MEM_HALF: load_data_ext =
                load_unsigned ? {16'b0, load_half} : {{16{load_half[15]}}, load_half};

            MEM_WORD: load_data_ext = mem_rdata;

            default:  load_data_ext = mem_rdata;
        endcase
    end

    wire [31:0] pc_next_val;
    pc_next pn (
        .pc(pc),
        .rs1(rs1_val),
        .imm(imm),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .take_branch(take_branch),
        .pc_next(pc_next_val)
    );

    always @(*) begin
        case (wb_sel)
            2'b00: wb_data = alu_y;
            2'b01: wb_data = load_data_ext;
            2'b10: wb_data = pc + 32'd4;
            2'b11: wb_data = imm;
            default: wb_data = 32'b0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc     <= 32'b0;
            halted <= 1'b0;
            tohost <= 32'b0;
        end else begin
            if (!halted) begin
                pc <= pc_next_val;
            end

            if (tohost_hit && !halted) begin
                halted <= 1'b1;
                tohost <= rs2_val;
            end
        end
    end
endmodule
