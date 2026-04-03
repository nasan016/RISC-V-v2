module cpu_top #(
    parameter HEX_FILE = "tests/prog.hex"
)(
    input clk,
    input rst_n,
    output reg halted,
    output reg [31:0] tohost
);

    // =========================
    // Constants
    // =========================
    localparam [31:0] TOHOST_ADDR = 32'h0000_0100;

    // =========================
    // Program Counter
    // =========================
    reg [31:0] pc;

    // =========================
    // Instruction Fetch
    // =========================
    wire [31:0] instr;

    imem #(
        .HEX_FILE(HEX_FILE)
    ) im (
        .addr(pc),
        .instr(instr)
    );

    // =========================
    // Instruction Fields
    // =========================
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];

    // =========================
    // Control Signals
    // =========================
    wire       reg_we;
    wire       mem_we;
    wire       mem_re;       // decode has this even if dmem is always-read for now
    wire       alu_src_imm;
    wire [1:0] wb_sel;
    wire       branch;
    wire       jal;
    wire       jalr;
    wire [3:0] alu_op;

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
        .alu_op(alu_op)
    );

    // =========================
    // Immediate Generator
    // =========================
    wire [31:0] imm;

    immgen ig (
        .instr(instr),
        .imm(imm)
    );

    // =========================
    // Register File
    // =========================
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

    // =========================
    // ALU
    // =========================
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

    // =========================
    // Branch Compare
    // =========================
    wire take_branch;

    branch_cmp bc (
        .funct3(funct3),
        .rs1(rs1_val),
        .rs2(rs2_val),
        .take(take_branch)
    );

    // =========================
    // Data Memory
    // =========================
    wire [31:0] dmem_rdata;

    wire tohost_hit    = mem_we && (alu_y == TOHOST_ADDR);
    wire dmem_we_actual = mem_we & ~halted & ~tohost_hit;

    dmem dm (
        .clk(clk),
        .we(dmem_we_actual),
        .addr(alu_y),
        .wdata(rs2_val),
        .rdata(dmem_rdata)
    );

    // =========================
    // Next PC Logic
    // =========================
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

    // =========================
    // Writeback Mux
    // wb_sel:
    //   00 = ALU
    //   01 = DMEM
    //   10 = PC + 4
    //   11 = IMM (for LUI)
    // =========================
    always @(*) begin
        case (wb_sel)
            2'b00: wb_data = alu_y;
            2'b01: wb_data = dmem_rdata;
            2'b10: wb_data = pc + 32'd4;
            2'b11: wb_data = imm;
            default: wb_data = 32'b0;
        endcase
    end

    // =========================
    // Sequential State Updates
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc     <= 32'b0;
            halted <= 1'b0;
            tohost <= 32'b0;
        end else begin
            if (!halted) begin
                pc <= pc_next_val;
            end

            // Halt when program stores to TOHOST_ADDR
            if (tohost_hit && !halted) begin
                halted <= 1'b1;
                tohost <= rs2_val;
            end
        end
    end

endmodule
