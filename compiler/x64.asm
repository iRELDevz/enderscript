%include "defs.inc"

section .bss
global x64_text_base
alignb 8
x64_text_base resq 1

section .text

global x64_op_disp
x64_op_disp:
    mov [rdi], rax
    add rdi, r8
    mov [rdi], ecx
    add rdi, 4
    ret

global x64_bytes
x64_bytes:
    mov [rdi], rax
    add rdi, r8
    ret

global x64_imm8
x64_imm8:
    mov [rdi], dl
    inc rdi
    ret

global x64_imm16
x64_imm16:
    mov [rdi], dx
    add rdi, 2
    ret

global x64_imm32
x64_imm32:
    mov [rdi], edx
    add rdi, 4
    ret

global x64_call_rel
x64_call_rel:
    mov byte [rdi], 0xE8
    mov rax, rdi
    sub rax, [x64_text_base]
    add eax, 5
    sub ecx, eax
    mov [rdi + 1], ecx
    add rdi, 5
    ret

global x64_text_offset
x64_text_offset:
    mov rax, rdi
    sub rax, [x64_text_base]
    ret
