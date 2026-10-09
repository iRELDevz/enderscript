#include "defs.h"

#if defined(TARGET_WINDOWS)

#define FILE_ALIGN  0x200
#define SECT_ALIGN  0x1000
#define IDATA_SIZE  176
#define IMAGE_BASE  0x140000000

    .bss
    .p2align 3
    .globl g_image, g_image_size
g_image:       .zero 8
g_image_size:  .zero 8
pe_R:          .zero 8
pe_D:          .zero 8
pe_I:          .zero 8
pe_T:          .zero 8
pe_rdata_vsz:  .zero 8
pe_rdata_raw:  .zero 8
pe_data_vsz:   .zero 8
pe_idata_file: .zero 8

    RODATA
idata_tpl:
    .zero 104
    .short 0
    .asciz "GetStdHandle"
    .byte 0
    .short 0
    .asciz "WriteFile"
    .short 0
    .asciz "ExitProcess"
    .asciz "kernel32.dll"
    .byte 0
    .zero 16

    .text

.macro ALIGN_UP reg, a
    add \reg, \reg, #(\a - 1)
    and \reg, \reg, #~(\a - 1)
.endm

FUNC img_layout
    LDX x9, g_pool_len
    add x9, x9, #RC_SIZE
    STX x9, pe_rdata_vsz
    mov x10, x9
    ALIGN_UP x10, FILE_ALIGN
    STX x10, pe_rdata_raw
    mov x11, #SECT_ALIGN
    STX x11, pe_R
    add x11, x11, x9
    ALIGN_UP x11, SECT_ALIGN
    STX x11, pe_D
    LDX x12, g_vars_size
    add x12, x12, #RT_VARS
    ALIGN_UP x12, 16
    STX x12, img_bufoff
    add x12, x12, #RT_BUF_SIZE
    STX x12, pe_data_vsz
    add x11, x11, x12
    ALIGN_UP x11, SECT_ALIGN
    STX x11, pe_I
    add x11, x11, #IDATA_SIZE
    ALIGN_UP x11, SECT_ALIGN
    STX x11, pe_T
    add x12, x10, #FILE_ALIGN
    STX x12, pe_idata_file
    add x12, x12, #FILE_ALIGN
    STX x12, img_T_off

    movz x13, #0x4000, lsl #16
    movk x13, #0x1, lsl #32
    LDX x9, pe_R
    add x9, x9, x13
    STX x9, img_R_va
    LDX x9, pe_D
    add x9, x9, x13
    STX x9, img_D_va
    LDX x9, pe_T
    add x9, x9, x13
    STX x9, img_T_va
    LDX x9, pe_I
    add x9, x9, x13
    add x9, x9, #72
    STX x9, img_iat_va

    LDX x0, g_nstmt
    lsl x0, x0, #9
    LDX x9, g_npieces
    add x0, x0, x9, lsl #6
    LDX x9, g_nparts
    add x0, x0, x9, lsl #6
    LA x9, rt_size
    ldr w9, [x9]
    add x0, x0, x9
    add x0, x0, #4096
    add x0, x0, x12
    bl mem_alloc
    STX x0, g_image
    add x9, x0, #FILE_ALIGN
    LA x10, rt_consts
    mov x11, #RC_SIZE
1:  ldrb w12, [x10], #1
    strb w12, [x9], #1
    subs x11, x11, #1
    b.ne 1b
    LDX x10, g_pool
    LDX x11, g_pool_len
2:  cbz x11, 3f
    ldrb w12, [x10], #1
    strb w12, [x9], #1
    sub x11, x11, #1
    b 2b
3:  ENDF

FUNC img_finish
    mov x19, x0
    mov x20, x0
    ALIGN_UP x20, FILE_ALIGN
    LDX x21, g_image
    LDX x9, img_T_off
    add x9, x9, x20
    STX x9, g_image_size

    mov w9, #0x5A4D
    strh w9, [x21]
    mov w9, #0x40
    str w9, [x21, #0x3C]
    mov w9, #0x4550
    str w9, [x21, #0x40]
    mov w9, #0xAA64
    strh w9, [x21, #0x44]
    mov w9, #4
    strh w9, [x21, #0x46]
    mov w9, #0xF0
    strh w9, [x21, #0x54]
    mov w9, #0x22
    strh w9, [x21, #0x56]

    add x22, x21, #0x58
    mov w9, #0x20B
    strh w9, [x22]
    mov w9, #1
    strb w9, [x22, #2]
    str w20, [x22, #4]
    LDX x9, pe_rdata_raw
    add x9, x9, #FILE_ALIGN
    str w9, [x22, #8]
    LDX x9, pe_data_vsz
    ALIGN_UP x9, FILE_ALIGN
    str w9, [x22, #12]
    LDX x9, pe_T
    LDX x10, img_entry
    add x10, x10, x9
    str w10, [x22, #16]
    str w9, [x22, #20]
    movz x10, #0x4000, lsl #16
    movk x10, #0x1, lsl #32
    str x10, [x22, #24]
    mov w10, #SECT_ALIGN
    str w10, [x22, #32]
    mov w10, #FILE_ALIGN
    str w10, [x22, #36]
    mov w10, #6
    strh w10, [x22, #40]
    strh w10, [x22, #48]
    add x10, x9, x19
    ALIGN_UP x10, SECT_ALIGN
    str w10, [x22, #56]
    mov w10, #FILE_ALIGN
    str w10, [x22, #60]
    mov w10, #3
    strh w10, [x22, #68]
    mov w10, #0x8160
    strh w10, [x22, #70]
    mov x10, #0x100000
    str x10, [x22, #72]
    mov x10, #0x1000
    str x10, [x22, #80]
    mov x10, #0x100000
    str x10, [x22, #88]
    mov x10, #0x1000
    str x10, [x22, #96]
    mov w10, #16
    str w10, [x22, #108]
    LDX x10, pe_I
    str w10, [x22, #120]
    mov w11, #40
    str w11, [x22, #124]
    add w11, w10, #160
    str w11, [x22, #152]
    mov w11, #12
    str w11, [x22, #156]
    add w11, w10, #72
    str w11, [x22, #208]
    mov w11, #32
    str w11, [x22, #212]

    add x22, x21, #0x148
    movz x9, #0x722E
    movk x9, #0x6164, lsl #16
    movk x9, #0x6174, lsl #32
    str x9, [x22]
    LDX x9, pe_rdata_vsz
    str w9, [x22, #8]
    LDX x9, pe_R
    str w9, [x22, #12]
    LDX x9, pe_rdata_raw
    str w9, [x22, #16]
    mov w9, #FILE_ALIGN
    str w9, [x22, #20]
    MOV32 w9, 0x40000040
    str w9, [x22, #36]

    add x22, x22, #40
    movz x9, #0x642E
    movk x9, #0x7461, lsl #16
    movk x9, #0x61, lsl #32
    str x9, [x22]
    LDX x9, pe_data_vsz
    str w9, [x22, #8]
    LDX x9, pe_D
    str w9, [x22, #12]
    MOV32 w9, 0xC0000080
    str w9, [x22, #36]

    add x22, x22, #40
    movz x9, #0x692E
    movk x9, #0x6164, lsl #16
    movk x9, #0x6174, lsl #32
    str x9, [x22]
    mov w9, #IDATA_SIZE
    str w9, [x22, #8]
    LDX x9, pe_I
    str w9, [x22, #12]
    mov w9, #FILE_ALIGN
    str w9, [x22, #16]
    LDX x9, pe_idata_file
    str w9, [x22, #20]
    MOV32 w9, 0xC0000040
    str w9, [x22, #36]

    add x22, x22, #40
    movz x9, #0x742E
    movk x9, #0x7865, lsl #16
    movk x9, #0x74, lsl #32
    str x9, [x22]
    str w19, [x22, #8]
    LDX x9, pe_T
    str w9, [x22, #12]
    str w20, [x22, #16]
    LDX x9, img_T_off
    str w9, [x22, #20]
    MOV32 w9, 0x60000020
    str w9, [x22, #36]

    LDX x9, pe_idata_file
    add x22, x21, x9
    LA x10, idata_tpl
    mov x11, #0
4:  ldrb w12, [x10, x11]
    strb w12, [x22, x11]
    add x11, x11, #1
    cmp x11, #IDATA_SIZE
    b.lo 4b
    LDX x10, pe_I
    add w11, w10, #40
    str w11, [x22]
    add w11, w10, #146
    str w11, [x22, #12]
    add w11, w10, #72
    str w11, [x22, #16]
    add x11, x10, #104
    str x11, [x22, #40]
    str x11, [x22, #72]
    add x11, x10, #120
    str x11, [x22, #48]
    str x11, [x22, #80]
    add x11, x10, #132
    str x11, [x22, #56]
    str x11, [x22, #88]
    LDX x11, pe_T
    str w11, [x22, #160]
    mov w11, #12
    str w11, [x22, #164]
    ENDF

#endif
