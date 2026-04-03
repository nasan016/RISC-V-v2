module imem #(
    parameter HEX_FILE = "tests/prog.hex"
)(
    input  [31:0] addr,
    output [31:0] instr
);
    reg [31:0] rom [0:1023];
    wire [9:0] idx = addr[11:2];

    assign instr = rom[idx];

    initial begin
        $readmemh(HEX_FILE, rom);
    end
endmodule
