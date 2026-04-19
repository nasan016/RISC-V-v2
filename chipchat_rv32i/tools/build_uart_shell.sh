#!/usr/bin/env bash
set -euo pipefail

mkdir -p build tests

riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o build/uart_shell.o programs/uart_shell.S
riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x0 --no-relax -o build/uart_shell.elf build/uart_shell.o
riscv64-unknown-elf-objcopy -O binary -j .text build/uart_shell.elf build/uart_shell.bin
od -An -v -tx4 build/uart_shell.bin | tr -s ' ' '\n' | sed '/^$/d' > tests/uart_shell.hex
riscv64-unknown-elf-objdump -d build/uart_shell.elf > build/uart_shell.dump

echo "Wrote tests/uart_shell.hex"
