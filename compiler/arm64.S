#include "defs.h"

    .bss
    .p2align 3
    .globl enc_text_base, enc_text_va
enc_text_base: .zero 8
enc_text_va:   .zero 8

    .text

LEAF e_word
    str w0, [x27], #4
    ret

LEAF e_mov32
    and w9, w1, #0xFFFF
    MOV32 w10, 0x52800000
    orr w10, w10, w9, lsl #5
    orr w10, w10, w0
    str w10, [x27], #4
    lsr w9, w1, #16
    cbz w9, 1f
    MOV32 w10, 0x72A00000
    orr w10, w10, w9, lsl #5
    orr w10, w10, w0
    str w10, [x27], #4
1:  ret

LEAF e_addr
    and w9, w1, #0xFFF
    MOV32 w10, 0x91000000
    orr w10, w10, w9, lsl #10
    mov w11, #28
    orr w10, w10, w11, lsl #5
    orr w10, w10, w0
    str w10, [x27], #4
    lsr w9, w1, #12
    cbz w9, 1f
    MOV32 w10, 0x91400000
    orr w10, w10, w9, lsl #10
    orr w10, w10, w0, lsl #5
    orr w10, w10, w0
    str w10, [x27], #4
1:  ret

LEAF e_adrp
    LDX x9, enc_text_base
    sub x9, x27, x9
    LDX x10, enc_text_va
    add x9, x9, x10
    lsr x9, x9, #12
    lsr x10, x1, #12
    sub x9, x10, x9
    and w10, w9, #3
    ubfx x11, x9, #2, #19
    MOV32 w12, 0x90000000
    orr w12, w12, w10, lsl #29
    orr w12, w12, w11, lsl #5
    orr w12, w12, w0
    str w12, [x27], #4
    ret

LEAF e_adr_va
    mov x15, x30
    bl e_adrp
    mov x30, x15
    and w9, w1, #0xFFF
    MOV32 w10, 0x91000000
    orr w10, w10, w9, lsl #10
    orr w10, w10, w0, lsl #5
    orr w10, w10, w0
    str w10, [x27], #4
    ret

LEAF e_ldr_va
    mov x15, x30
    bl e_adrp
    mov x30, x15
    and w9, w1, #0xFFF
    lsr w9, w9, #3
    MOV32 w10, 0xF9400000
    orr w10, w10, w9, lsl #10
    orr w10, w10, w0, lsl #5
    orr w10, w10, w0
    str w10, [x27], #4
    ret

LEAF e_bl
    LDX x9, enc_text_base
    sub x9, x27, x9
    sub x9, x0, x9
    asr x9, x9, #2
    and w9, w9, #0x3FFFFFF
    MOV32 w10, 0x94000000
    orr w10, w10, w9
    str w10, [x27], #4
    ret

LEAF e_text_offset
    LDX x9, enc_text_base
    sub x0, x27, x9
    ret
