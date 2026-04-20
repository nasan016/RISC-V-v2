
# LLM Generated RISC-V Processor

This CPU currently implements the following 35 **RV32I** instructions:

```
R-Type:

add
sub
and
or
xor
sll
srl
sra
slt
sltu
```

```
I-Type:

addi
andi
ori
xori
slti
sltiu
slli
srli
srai
```

```
LOADS:

lb
lbu
lh
lhu
lw
```

```
STORES:

sb
sh
sw
```

```
BRANCHES:

beq
bne
blt
bge
bltu
bgeu
```

```
JUMPS/UPPER-IMMEDIATE:

jal
jalr
lui
auipc
```


*Not Implemented:*

```
ecall, ebreak, fence, fence.i
```

These instructions were left out because they are **not required for the main goals of this CPU** which are:

* arithmetic and logic execution
* memory access
* branching and jumps
* integration testing
* FPGA deployment of a basic working processor

# Verification Against Spike:

In addition to the RTL integration tests, this project was also checked against [**Spike**](https://github.com/riscv-software-src/riscv-isa-sim), the reference RISC-V ISA simulator.

## Verification Strategy:

1. **RTL Integration Testing**:
* Verilog testbenches run `.hex` programs directly on the CPU
* Results are checked using the `tohost` convention at address `0x100`

2. **Spike ISA Verification**:
* Equivalent RV32I assembly/C programs are compiled into ELF files
* Programs are executed with:

    ```bash
    spike --isa=RV32I -l pk program.elf 2> spike.log
    ```

* Spike logs are inspected to confirm instruction execution and expected final results.

#### Example: Smoke Test
The smoke test checks basic arithmetic and register writeback.

```asm
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
j    .
```

#### Relavant Spike Log:

```
core   0: 0x00010074 (0x00500093) li      ra, 5
core   0: 0x00010078 (0x00700113) li      sp, 7
core   0: 0x0001007c (0x002081b3) add     gp, ra, sp
core   0: 0x00010080 (0x0000006f) j       pc + 0x0
```

`ra` = `x1`

`sp` = `x2`

`gp` = `x3`

[RISC-V Reference Regarding Register Naming Conventions (p. 91)](https://riscv.org/wp-content/uploads/2024/12/riscv-calling.pdf)

#### Corresponding RTL Result:

```
HALTED tohost=12 (0x0000000c)
PASS tb_cpu_smoke
```

Both Spike and the RTL implementation produce the same expected architectural result for the smoke test.

## Basys3 FPGA + UART Bringup

The board entry point is:

```text
chipchat_rv32i/basys3_top.v
```

Set the Vivado top module to:

```text
basys3_top
```

Do not set `cpu_top` as the Vivado top. `cpu_top` is only the CPU core. `basys3_top` is the wrapper that connects the CPU to the Basys3 clock, reset button, LEDs, and USB UART pins.

### Vivado Files To Add

Add these as design sources:

```text
chipchat_rv32i/basys3_top.v
chipchat_rv32i/rtl/alu.v
chipchat_rv32i/rtl/branch_cmp.v
chipchat_rv32i/rtl/cpu_top.v
chipchat_rv32i/rtl/decode.v
chipchat_rv32i/rtl/dmem.v
chipchat_rv32i/rtl/imem.v
chipchat_rv32i/rtl/immgen.v
chipchat_rv32i/rtl/pc_next.v
chipchat_rv32i/rtl/regfile.v
chipchat_rv32i/rtl/uart_rx.v
chipchat_rv32i/rtl/uart_tx.v
```

Add this as the constraints file:

```text
chipchat_rv32i/xdc/basys3.xdc
```

Do not add files from `chipchat_rv32i/tb/` as design sources. Those are simulation testbenches.

### ROM Program Hex

The program that runs on the CPU is baked into instruction memory from:

```text
chipchat_rv32i/tests/uart_shell.hex
```

`basys3_top.v` passes this path into `cpu_top`:

```verilog
.HEX_FILE("tests/uart_shell.hex")
```

That means Vivado must be able to find this relative path:

```text
tests/uart_shell.hex
```

The easiest setup is to run/create the Vivado project from inside `chipchat_rv32i`, or add `chipchat_rv32i/tests/uart_shell.hex` to the Vivado project as a memory/init file. If synthesis warns that it cannot open `uart_shell.hex`, the CPU will not boot the UART shell correctly.

To rebuild the hex file after editing the assembly program:

```bash
cd chipchat_rv32i
./tools/build_uart_shell.sh
```

The source assembly program is:

```text
chipchat_rv32i/programs/uart_shell.S
```

### UART Memory Map

The CPU talks to the UART using normal RISC-V loads and stores at fixed addresses:

```text
0x1000_0000  UART TX data
             Store a byte here to transmit it.

0x1000_0004  UART RX data
             Load from here to read the pending byte.
             Reading this address consumes the byte.

0x1000_0008  UART status
             bit 0 = RX valid, a byte is waiting
             bit 1 = TX ready, transmitter can accept a byte
```

The UART uses:

```text
115200 baud
8 data bits
no parity
1 stop bit
no flow control
```

### Basys3 Pin Mapping

These are the top-level Verilog ports in `basys3_top.v` and the Basys3 FPGA pins assigned in `xdc/basys3.xdc`.

```text
clk   -> W5    100 MHz Basys3 clock
btnC  -> U18   center button, CPU reset while pressed
RsRx  -> B18   USB UART receive into FPGA
RsTx  -> A18   USB UART transmit from FPGA
```

The switch pins are:

```text
sw[0]  -> V17
sw[1]  -> V16
sw[2]  -> W16
sw[3]  -> W17
sw[4]  -> W15
sw[5]  -> V15
sw[6]  -> W14
sw[7]  -> W13
sw[8]  -> V2
sw[9]  -> T3
sw[10] -> T2
sw[11] -> R3
sw[12] -> W2
sw[13] -> U1
sw[14] -> T1
sw[15] -> R2
```

The LED pins are:

```text
led[0]  -> U16
led[1]  -> E19
led[2]  -> U19
led[3]  -> V19
led[4]  -> W18
led[5]  -> U15
led[6]  -> U14
led[7]  -> V14
led[8]  -> V13
led[9]  -> V3
led[10] -> W3
led[11] -> U3
led[12] -> P3
led[13] -> N3
led[14] -> P1
led[15] -> L1
```

The 7-segment display is intentionally turned off by `basys3_top.v`.

### LED Debug Meaning

The LEDs are wired like this:

```verilog
assign led[15]   = halted;
assign led[14]   = uart_rx_valid;
assign led[13]   = ~uart_tx_busy;
assign led[12:0] = {sw[4:0], tohost[7:0]};
```

In plain English:

```text
led[15]    CPU halted
led[14]    UART has received a byte waiting for the CPU
led[13]    UART transmitter is ready
led[12:8]  mirrors switches sw[4:0]
led[7:0]   low byte of tohost debug value
```

For the UART shell, `led[13]` being on is normal. It means the UART transmitter is idle and ready to send.

### Running The UART Shell

After programming the Basys3 with the generated bitstream, open a serial terminal.

On Linux, first find the serial device:

```bash
dmesg | grep -iE 'ttyUSB|ttyACM|digilent|ftdi|xilinx' | tail -50
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
ls -l /dev/serial/by-id/ 2>/dev/null
```

If Linux says the board attached to `ttyUSB1`, open:

```bash
screen /dev/ttyUSB1 115200
```

If it attached to `ttyUSB0`, open:

```bash
screen /dev/ttyUSB0 115200
```

If using `picocom`:

```bash
picocom -b 115200 --flow n /dev/ttyUSB1
```

Press and release `btnC` after opening the terminal. Expected boot text:

```text
RV32I ready
rv32>
```

Supported commands:

```text
hello <name>
./fact <n>
./fib <n>
```

Examples:

```text
rv32> hello ada
hello ada!
rv32> ./fact 5
120
rv32> ./fib 10
55
```

To exit `screen`:

```text
Ctrl-a
k
y
```

### Common Bringup Problems

If Vivado cannot find the board, Linux must see the USB device first:

```bash
lsusb
sudo dmesg -w
```

Plug the board in while `dmesg -w` is running. Look for `Digilent`, `FTDI`, `ttyUSB0`, or `ttyUSB1`.

If `/dev/ttyUSB*` does not exist, try loading the FTDI serial drivers:

```bash
sudo modprobe ftdi_sio
sudo modprobe usbserial
```

Then unplug and replug the board.

If `screen` says permission denied:

```bash
sudo usermod -aG dialout $USER
```

Log out and log back in after running that command.

If the serial terminal is blank:

```text
1. Make sure the board was programmed after the last unplug.
2. Make sure Vivado used basys3_top as the top module.
3. Make sure uart_shell.hex was found during synthesis.
4. Try both /dev/ttyUSB0 and /dev/ttyUSB1.
5. Press and release btnC while the serial terminal is open.
```

Unplugging the Basys3 resets the board and clears the FPGA configuration. The bitstream is volatile unless you separately program flash. After unplugging, program the FPGA again from Vivado.
