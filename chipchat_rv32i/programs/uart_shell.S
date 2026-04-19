    .option norvc
    .text
    .globl _start

    .equ UART_TX,     0x10000000
    .equ UART_RX,     0x10000004
    .equ UART_STATUS, 0x10000008
    .equ LINE_BUF,    0x00000200
    .equ DIGIT_BUF,   0x00000240
    .equ RA_SAVE,     0x000001fc

_start:
    li sp, 0x400
    jal ra, print_banner

main_loop:
    jal ra, print_prompt
    li s0, LINE_BUF
    li s1, 0

read_line:
    jal ra, getc
    li t0, 13
    beq a0, t0, line_done
    li t0, 10
    beq a0, t0, line_done
    li t0, 8
    beq a0, t0, backspace
    li t0, 127
    beq a0, t0, backspace

    sltiu t0, s1, 63
    beq t0, zero, read_line
    sb a0, 0(s0)
    addi s0, s0, 1
    addi s1, s1, 1
    jal ra, putc
    jal zero, read_line

backspace:
    beq s1, zero, read_line
    addi s0, s0, -1
    addi s1, s1, -1
    li a0, 8
    jal ra, putc
    li a0, 32
    jal ra, putc
    li a0, 8
    jal ra, putc
    jal zero, read_line

line_done:
    sb zero, 0(s0)
    jal ra, print_crlf
    jal ra, dispatch
    jal zero, main_loop

dispatch:
    addi sp, sp, -4
    sw ra, 0(sp)
    li s0, LINE_BUF

    lbu t0, 0(s0)
    li t1, 'h'
    bne t0, t1, try_fact
    lbu t0, 1(s0)
    li t1, 'e'
    bne t0, t1, try_fact
    lbu t0, 2(s0)
    li t1, 'l'
    bne t0, t1, try_fact
    lbu t0, 3(s0)
    li t1, 'l'
    bne t0, t1, try_fact
    lbu t0, 4(s0)
    li t1, 'o'
    bne t0, t1, try_fact
    lbu t0, 5(s0)
    li t1, ' '
    bne t0, t1, try_fact
    addi a0, s0, 6
    jal zero, cmd_hello

try_fact:
    lbu t0, 0(s0)
    li t1, '.'
    bne t0, t1, try_fib
    lbu t0, 1(s0)
    li t1, '/'
    bne t0, t1, try_fib
    lbu t0, 2(s0)
    li t1, 'f'
    bne t0, t1, try_fib
    lbu t0, 3(s0)
    li t1, 'a'
    bne t0, t1, try_fib
    lbu t0, 4(s0)
    li t1, 'c'
    bne t0, t1, try_fib
    lbu t0, 5(s0)
    li t1, 't'
    bne t0, t1, try_fib
    lbu t0, 6(s0)
    li t1, ' '
    bne t0, t1, try_fib
    addi a0, s0, 7
    jal ra, parse_uint
    jal ra, factorial
    jal ra, print_uint
    jal ra, print_crlf
    jal zero, dispatch_done

try_fib:
    lbu t0, 0(s0)
    li t1, '.'
    bne t0, t1, unknown
    lbu t0, 1(s0)
    li t1, '/'
    bne t0, t1, unknown
    lbu t0, 2(s0)
    li t1, 'f'
    bne t0, t1, unknown
    lbu t0, 3(s0)
    li t1, 'i'
    bne t0, t1, unknown
    lbu t0, 4(s0)
    li t1, 'b'
    bne t0, t1, unknown
    lbu t0, 5(s0)
    li t1, ' '
    bne t0, t1, unknown
    addi a0, s0, 6
    jal ra, parse_uint
    jal ra, fib
    jal ra, print_uint
    jal ra, print_crlf
    jal zero, dispatch_done

unknown:
    jal ra, print_unknown
dispatch_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

cmd_hello:
    addi sp, sp, -4
    sw ra, 0(sp)
    mv s2, a0
    li a0, 'h'
    jal ra, putc
    li a0, 'e'
    jal ra, putc
    li a0, 'l'
    jal ra, putc
    li a0, 'l'
    jal ra, putc
    li a0, 'o'
    jal ra, putc
    li a0, ' '
    jal ra, putc
hello_name_loop:
    lbu a0, 0(s2)
    beq a0, zero, hello_done
    jal ra, putc
    addi s2, s2, 1
    jal zero, hello_name_loop
hello_done:
    li a0, '!'
    jal ra, putc
    jal ra, print_crlf
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

parse_uint:
    mv t0, a0
    li t1, 0
parse_loop:
    lbu t2, 0(t0)
    li t3, '0'
    bltu t2, t3, parse_done
    li t3, '9'
    bltu t3, t2, parse_done
    addi t2, t2, -48
    slli t3, t1, 3
    slli t4, t1, 1
    add t1, t3, t4
    add t1, t1, t2
    addi t0, t0, 1
    jal zero, parse_loop
parse_done:
    mv a0, t1
    ret

factorial:
    li t0, 1
    mv t1, a0
fact_loop:
    beq t1, zero, fact_done
    li t2, 0
    mv t3, t1
fact_mul_loop:
    beq t3, zero, fact_mul_done
    add t2, t2, t0
    addi t3, t3, -1
    jal zero, fact_mul_loop
fact_mul_done:
    mv t0, t2
    addi t1, t1, -1
    jal zero, fact_loop
fact_done:
    mv a0, t0
    ret

fib:
    li t0, 0
    li t1, 1
    mv t2, a0
fib_loop:
    beq t2, zero, fib_done
    add t3, t0, t1
    mv t0, t1
    mv t1, t3
    addi t2, t2, -1
    jal zero, fib_loop
fib_done:
    mv a0, t0
    ret

print_uint:
    li t0, RA_SAVE
    sw ra, 0(t0)
    mv s2, a0
    li s3, DIGIT_BUF
    li s4, 0
    bne s2, zero, print_digit_loop
    li a0, '0'
    jal ra, putc
    jal zero, print_uint_done

print_digit_loop:
    li s5, 0
    mv s6, s2
div10_loop:
    sltiu t1, s6, 10
    bne t1, zero, div10_done
    addi s6, s6, -10
    addi s5, s5, 1
    jal zero, div10_loop
div10_done:
    addi t2, s6, 48
    sb t2, 0(s3)
    addi s3, s3, 1
    addi s4, s4, 1
    mv s2, s5
    bne s2, zero, print_digit_loop

print_digit_rev:
    addi s3, s3, -1
    lbu a0, 0(s3)
    jal ra, putc
    addi s4, s4, -1
    bne s4, zero, print_digit_rev

print_uint_done:
    li t0, RA_SAVE
    lw ra, 0(t0)
    ret

getc:
    li t0, UART_STATUS
getc_wait:
    lw t1, 0(t0)
    andi t1, t1, 1
    beq t1, zero, getc_wait
    li t0, UART_RX
    lw a0, 0(t0)
    andi a0, a0, 255
    ret

putc:
    li t0, UART_STATUS
putc_wait:
    lw t1, 0(t0)
    andi t1, t1, 2
    beq t1, zero, putc_wait
    li t0, UART_TX
    sw a0, 0(t0)
    ret

print_crlf:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 13
    jal ra, putc
    li a0, 10
    jal ra, putc
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

print_banner:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 13
    jal ra, putc
    li a0, 10
    jal ra, putc
    li a0, 'R'
    jal ra, putc
    li a0, 'V'
    jal ra, putc
    li a0, '3'
    jal ra, putc
    li a0, '2'
    jal ra, putc
    li a0, 'I'
    jal ra, putc
    li a0, ' '
    jal ra, putc
    li a0, 'r'
    jal ra, putc
    li a0, 'e'
    jal ra, putc
    li a0, 'a'
    jal ra, putc
    li a0, 'd'
    jal ra, putc
    li a0, 'y'
    jal ra, putc
    jal ra, print_crlf
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

print_prompt:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 'r'
    jal ra, putc
    li a0, 'v'
    jal ra, putc
    li a0, '3'
    jal ra, putc
    li a0, '2'
    jal ra, putc
    li a0, '>'
    jal ra, putc
    li a0, ' '
    jal ra, putc
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

print_unknown:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 'u'
    jal ra, putc
    li a0, 'n'
    jal ra, putc
    li a0, 'k'
    jal ra, putc
    li a0, 'n'
    jal ra, putc
    li a0, 'o'
    jal ra, putc
    li a0, 'w'
    jal ra, putc
    li a0, 'n'
    jal ra, putc
    jal ra, print_crlf
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
