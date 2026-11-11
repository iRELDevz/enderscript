#include "defs.h"

#if !defined(TARGET_WINDOWS)

#define BASE_VA   0x400000
#define DATA_VA   0x40000000
#define HDR_SIZE  176

    .bss
    .p2align 3
    .globl g_image, g_image_size
g_image:      .zero 8
g_image_size: .zero 8
el_data_vsz:  .zero 8

    .text

FUNC img_layout
    mov x9, #BASE_VA
    add x9, x9, #HDR_SIZE
    STX x9, img_R_va
    LDX x10, g_pool_len
    add x10, x10, #(HDR_SIZE + RC_SIZE + 15)
    and x10, x10, #~15
    STX x10, img_T_off
    mov x9, #BASE_VA
    add x9, x9, x10
    STX x9, img_T_va
    mov x9, #DATA_VA
    STX x9, img_D_va
    LDX x11, g_vars_size
    add x11, x11, #(RT_VARS + 15)
    and x11, x11, #~15
    STX x11, img_bufoff
    add x11, x11, #RT_BUF_SIZE
    STX x11, el_data_vsz

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
    add x0, x0, x10
    bl mem_alloc
    STX x0, g_image
    add x9, x0, #HDR_SIZE
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
    LDX x21, g_image
    LDX x9, img_T_off
    add x19, x9, x0
    STX x19, g_image_size

    MOV32 w9, 0x464C457F
    str w9, [x21]
    mov w9, #2
    strb w9, [x21, #4]
    mov w9, #1
    strb w9, [x21, #5]
    strb w9, [x21, #6]
    mov w9, #2
    strh w9, [x21, #16]
    mov w9, #183
    strh w9, [x21, #18]
    mov w9, #1
    str w9, [x21, #20]
    LDX x9, img_T_va
    LDX x10, img_entry
    add x9, x9, x10
    str x9, [x21, #24]
    mov x9, #64
    str x9, [x21, #32]
    mov w9, #64
    strh w9, [x21, #52]
    mov w9, #56
    strh w9, [x21, #54]
    mov w9, #2
    strh w9, [x21, #56]

    add x22, x21, #64
    mov w9, #1
    str w9, [x22]
    mov w9, #5
    str w9, [x22, #4]
    str xzr, [x22, #8]
    mov x9, #BASE_VA
    str x9, [x22, #16]
    str x9, [x22, #24]
    str x19, [x22, #32]
    str x19, [x22, #40]
    mov x9, #0x10000
    str x9, [x22, #48]

    add x22, x22, #56
    mov w9, #1
    str w9, [x22]
    mov w9, #6
    str w9, [x22, #4]
    str xzr, [x22, #8]
    mov x9, #DATA_VA
    str x9, [x22, #16]
    str x9, [x22, #24]
    str xzr, [x22, #32]
    LDX x9, el_data_vsz
    str x9, [x22, #40]
    mov x9, #0x10000
    str x9, [x22, #48]
    ENDF

#endif
