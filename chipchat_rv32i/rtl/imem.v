module imem(
  input  [31:0] addr,
  output [31:0] instr
);
  reg [31:0] rom [0:1023];
  wire [9:0] idx = addr[11:2];

  assign instr = rom[idx];

  // Load program from hex file: each line is one 32-bit word in hex
  initial begin
    $readmemh("tests/prog.hex", rom);
  end
endmodule
