module tb_immgen;
    reg  [31:0] instr;
    wire [31:0] imm;

    // Instantiate the Unit Under Test (UUT)
    immgen dut (
        .instr(instr),
        .imm(imm)
    );

    // Task for checking results
    task check_result;
        input [31:0] expected;
        input [255:0] test_name;
        begin
            #1; // Small delay to allow combinatorial logic to settle
            if (imm !== expected) begin
                $display("FAIL %s: instr=%h, got=%h, exp=%h", test_name, instr, imm, expected);
                $finish;
            end else begin
                $display("PASS %s", test_name);
            end
        end
    endtask

    // Helper functions to build instructions
    function [31:0] mk_i(input [6:0] opc, input [11:0] i12);
        mk_i = {i12, 13'b0, opc};
    endfunction

    function [31:0] mk_s(input [6:0] opc, input [11:0] i12);
        mk_s = {i12[11:5], 13'b0, i12[4:0], opc};
    endfunction

    initial begin
        $display("Starting ImmGen Tests...");

        // -------- I-type: OP-IMM (0010011) --------
        instr = mk_i(7'b0010011, 12'hFFF); 
        check_result(32'hFFFF_FFFF, "I-Type negative");

        instr = mk_i(7'b0010011, 12'h7FF); 
        check_result(32'h0000_07FF, "I-Type positive");

        // -------- S-type: STORE (0100011) --------
        instr = mk_s(7'b0100011, 12'hFFF);
        check_result(32'hFFFF_FFFF, "S-Type negative");

        // -------- B-type: BRANCH (1100011) --------
        // Target: -4 (offset 13'h1FFC)
        instr = 32'h0;
        instr[6:0]   = 7'b1100011;
        instr[31]    = 1'b1;      // imm[12]
        instr[7]     = 1'b1;      // imm[11]
        instr[30:25] = 6'b111111; // imm[10:5]
        instr[11:8]  = 4'b1110;   // imm[4:1]
        check_result(32'hFFFF_FFFC, "B-Type -4");

        // -------- U-type: LUI (0110111) --------
        instr = {20'h12345, 5'b0, 7'b0110111};
        check_result(32'h12345000, "U-Type LUI");

        // -------- J-type: JAL (1101111) --------
        // Target: -2 (offset 21'h1FFFFE)
        instr = 32'h0;
        instr[6:0]   = 7'b1101111;
        instr[31]    = 1'b1;    // imm[20]
        instr[19:12] = 8'hFF;   // imm[19:12]
        instr[20]    = 1'b1;    // imm[11]
        instr[30:21] = 10'h3FF; // imm[10:1]
        check_result(32'hFFFF_FFFE, "J-Type -2");

        $display("ALL IMMGEN TESTS PASSED");
        $finish;
    end
endmodule
