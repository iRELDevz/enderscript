%include "defs.inc"

section .bss
global x86_text_base
alignb 4
x86_text_base resd 1

section .text

global x86_bytes
x86_bytes:
    mov [edi], eax
    add edi, ecx
    ret

global x86_imm32
x86_imm32:
    mov [edi], edx
    add edi, 4
    ret

global x86_imm16
x86_imm16:
    mov [edi], dx
    add edi, 2
    ret

global x86_imm8
x86_imm8:
    mov [edi], dl
    inc edi
    ret

global x86_op_abs
x86_op_abs:
    mov [edi], eax
    add edi, ecx
    mov [edi], edx
    add edi, 4
    ret

global x86_call_rel
x86_call_rel:
    mov byte [edi], 0xE8
    mov eax, edi
    sub eax, [x86_text_base]
    add eax, 5
    sub ecx, eax
    mov [edi + 1], ecx
    add edi, 5
    ret

global x86_text_offset
x86_text_offset:
    mov eax, edi
    sub eax, [x86_text_base]
    ret
