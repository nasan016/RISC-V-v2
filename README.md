
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
