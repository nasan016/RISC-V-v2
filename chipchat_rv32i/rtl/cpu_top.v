module cpu_top(
    input clk,
    input rst_n,
    output reg halted,
    output reg [31:0] tohost
);

    // Constants
    localparam [31:0] TOHOST_ADDR = 32'h0000_0100;

    // Program counter
    reg [31:0] pc;

    // Instruction fetch
    wire [31:0] instr;
    imem im(
        .addr(pc),
        .instr(instr)
    );

    // Instruction fields
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];

    // Control signals from decode
    wire alu_src_imm;
    wire [3:0] alu_op;
    wire mem_we;
    wire branch;
    wire jal;
    wire jalr;
    wire reg_we;
    wire [1:0] wb_sel;

    decode dec(
        .instr(instr),
        .alu_src_imm(alu_src_imm),
        .alu_op(alu_op),
        .mem_we(mem_we),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .reg_we(reg_we),
        .wb_sel(wb_sel)
    );

    // Immediate
    wire [31:0] imm;
    immgen ig(
        .instr(instr),
        .imm(imm)
    );

    // Register file
    wire [31:0] rs1_val, rs2_val;
    reg [31:0] wb_data;
    wire reg_we_actual = reg_we & ~halted;

    regfile rf(
        .clk(clk),
        .we(reg_we_actual),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wb_data),
        .rd1(rs1_val),
        .rd2(rs2_val)
    );

    // ALU and branch
    wire [31:0] alu_b = alu_src_imm ? imm : rs2_val;
    wire [31:0] alu_y;
    wire alu_zero;

    alu ualu(
        .a(rs1_val),
        .b(alu_b),
        .op(alu_op),
        .y(alu_y),
        .zero(alu_zero)
    );

    wire take_branch;
    branch_cmp bc(
        .funct3(funct3),
        .rs1(rs1_val),
        .rs2(rs2_val),
        .take(take_branch)
    );

    // Data memory
    wire [31:0] dmem_rdata;
    wire tohost_hit = mem_we && (alu_y == TOHOST_ADDR);
    wire dmem_we_actual = mem_we & ~halted & ~tohost_hit;

    dmem dm(
        .clk(clk),
        .we(dmem_we_actual),
        .addr(alu_y),
        .wdata(rs2_val),
        .rdata(dmem_rdata)
    );

    // Next PC
    wire [31:0] pc_next_val;
    pc_next pn(
        .pc(pc),
        .rs1(rs1_val),
        .imm(imm),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .take_branch(take_branch),
        .pc_next(pc_next_val)
    );

    // Writeback mux
    always @(*) begin
        case (wb_sel)
            2'b00: wb_data = alu_y;
            2'b01: wb_data = dmem_rdata;
            2'b10: wb_data = pc + 32'd4;
            2'b11: wb_data = imm;
            default: wb_data = 32'b0;
        endcase
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'b0;
            halted <= 1'b0;
            tohost <= 32'b0;
        end else begin
            if (!halted) begin
                pc <= pc_next_val;
            end
            // TOHOST handling
            if (tohost_hit && !halted) begin
                halted <= 1'b1;
                tohost <= rs2_val;
            end
        end
    end

endmodule