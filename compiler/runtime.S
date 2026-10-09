#include "defs.h"

    RODATA
    .p2align 4
    .globl rt_start, rt_size, rt_offsets, rt_consts
rt_start:

rt_write:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
1:  cbz x20, 9f
    ldr w9, [x28, #RT_OUT_LEN]
    mov w10, #RT_BUF_SIZE
    subs w11, w10, w9
    b.ne 2f
    bl rt_flush
    b 1b
2:  cmp x11, x20
    csel x11, x11, x20, ls
    ldr x12, [x28, #RT_BUFPTR]
    add x12, x12, x9
    sub x20, x20, x11
    add w9, w9, w11
    str w9, [x28, #RT_OUT_LEN]
3:  ldrb w13, [x19], #1
    strb w13, [x12], #1
    subs x11, x11, #1
    b.ne 3b
    b 1b
9:  ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

rt_write_int:
    stp x29, x30, [sp, #-48]!
    sxtw x9, w0
    add x10, sp, #48
    mov x11, x10
    mov w12, #0
    cmp x9, #0
    b.ge 1f
    neg x9, x9
    mov w12, #1
1:  mov x13, #10
2:  udiv x14, x9, x13
    msub x15, x14, x13, x9
    add w15, w15, #'0'
    strb w15, [x11, #-1]!
    mov x9, x14
    cbnz x9, 2b
    cbz w12, 3f
    mov w15, #'-'
    strb w15, [x11, #-1]!
3:  mov x0, x11
    sub x1, x10, x11
    bl rt_write
    ldp x29, x30, [sp], #48
    ret

rt_write_bool:
    ldr x9, [x28, #RT_CONST]
    cbz w0, 1f
    mov x0, x9
    mov x1, #4
    b rt_write
1:  add x0, x9, #RC_FALSE
    mov x1, #5
    b rt_write

rt_write_str:
    ldr x9, [x0]
    cbz x9, 1f
    ldrh w1, [x0, #8]
    mov x0, x9
    b rt_write
1:  ldr x0, [x28, #RT_CONST]
    add x0, x0, #RC_NULL
    mov x1, #4
    b rt_write

rt_flush:
#if defined(TARGET_WINDOWS)
    stp x29, x30, [sp, #-16]!
    ldr w2, [x28, #RT_OUT_LEN]
    cbz w2, 1f
    ldr x0, [x28, #RT_STDOUT]
    ldr x1, [x28, #RT_BUFPTR]
    add x3, x28, #RT_WRITTEN
    mov x4, #0
    ldr x16, [x28, #RT_WRITEFILE]
    blr x16
    str wzr, [x28, #RT_OUT_LEN]
1:  ldp x29, x30, [sp], #16
    ret
#else
    ldr w2, [x28, #RT_OUT_LEN]
    cbz w2, 3f
    ldr x1, [x28, #RT_BUFPTR]
1:  mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 2f
    add x1, x1, x0
    subs x2, x2, x0
    b.ne 1b
2:  str wzr, [x28, #RT_OUT_LEN]
3:  ret
#endif

rt_str_eq:
    cbz x0, 3f
    cbz x2, 2f
    cmp x1, x3
    b.ne 2f
1:  cbz x1, 4f
    ldrb w9, [x0], #1
    ldrb w10, [x2], #1
    cmp w9, w10
    b.ne 2f
    sub x1, x1, #1
    b 1b
3:  cbnz x2, 2f
4:  mov w0, #1
    ret
2:  mov w0, #0
    ret

rt_div_zero:
    mov w19, w0
    bl rt_flush
    sub sp, sp, #96
    add x21, sp, #96
#if defined(TARGET_WINDOWS)
    mov w9, #0x0A0D
    strh w9, [x21, #-2]
    sub x20, x21, #2
#else
    mov w9, #10
    strb w9, [x21, #-1]
    sub x20, x21, #1
#endif
    mov w10, #10
1:  udiv w11, w19, w10
    msub w12, w11, w10, w19
    add w12, w12, #'0'
    strb w12, [x20, #-1]!
    mov w19, w11
    cbnz w19, 1b
    adr x9, rt_s_divz
    mov x10, #(rt_s_divz_end - rt_s_divz)
    sub x20, x20, x10
    mov x11, #0
2:  ldrb w12, [x9, x11]
    strb w12, [x20, x11]
    add x11, x11, #1
    cmp x11, x10
    b.lo 2b
#if defined(TARGET_WINDOWS)
    mov w0, #-12
    ldr x16, [x28, #RT_GETSTD]
    blr x16
    mov x1, x20
    sub x2, x21, x20
    add x3, x28, #RT_WRITTEN
    mov x4, #0
    ldr x16, [x28, #RT_WRITEFILE]
    blr x16
    mov w0, #1
    ldr x16, [x28, #RT_EXIT]
    blr x16
#else
    mov x0, #2
    mov x1, x20
    sub x2, x21, x20
    mov x8, #64
    svc #0
    mov x0, #1
    mov x8, #94
    svc #0
#endif

rt_s_divz:
    .ascii "runtime error: division by zero on line "
rt_s_divz_end:
    .p2align 2

rt_end:

    .p2align 2
rt_size:
    .word rt_end - rt_start
rt_offsets:
    .word rt_write - rt_start
    .word rt_write_int - rt_start
    .word rt_write_bool - rt_start
    .word rt_write_str - rt_start
    .word rt_flush - rt_start
    .word rt_div_zero - rt_start
    .word rt_str_eq - rt_start
rt_consts:
    .ascii "truefalsenull"
    .byte 0, 0, 0
