
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
