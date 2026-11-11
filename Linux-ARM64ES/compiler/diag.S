#include "defs.h"

#define MSG_CAP  1024
#define LINE_CAP 2048

    .bss
    .p2align 3
num_tmp:  .zero 32
msg_buf:  .zero MSG_CAP
line_buf: .zero LINE_CAP

    .data
    .p2align 3
msg_desc:  .quad 0, MSG_CAP, msg_buf
line_desc: .quad 0, LINE_CAP, line_buf

    RODATA
s_error_sp:  .asciz " error: "
s_warning:   .asciz ": warning: "
s_error_pre: .asciz "error: "
s_quote:     .asciz "'"
#if defined(TARGET_WINDOWS)
s_nl:        .asciz "\r\n"
#else
s_nl:        .asciz "\n"
#endif

    .text

LEAF buf_add
    ldr x9, [x2]
    ldr x10, [x2, #8]
    ldr x11, [x2, #16]
1:  cbz x1, 2f
    cmp x9, x10
    b.hs 2f
    ldrb w12, [x0], #1
    strb w12, [x11, x9]
    add x9, x9, #1
    sub x1, x1, #1
    b 1b
2:  str x9, [x2]
    ret

LEAF msg_reset
    LA x9, msg_desc
    str xzr, [x9]
    ret

LEAF msg_add
    LA x2, msg_desc
    b buf_add

LEAF line_add
    LA x2, line_desc
    b buf_add

LEAF zlen_leaf
    mov x9, x0
1:  ldrb w10, [x9]
    cbz w10, 2f
    add x9, x9, #1
    b 1b
2:  sub x1, x9, x0
    ret

LEAF msg_addz
    mov x15, x30
    bl zlen_leaf
    mov x30, x15
    b msg_add

LEAF line_addz
    mov x15, x30
    bl zlen_leaf
    mov x30, x15
    b line_add

LEAF msg_addc
    LA x9, num_tmp
    strb w0, [x9]
    mov x0, x9
    mov x1, #1
    b msg_add

LEAF line_addc
    LA x9, num_tmp
    strb w0, [x9]
    mov x0, x9
    mov x1, #1
    b line_add

LEAF u64_to_dec
    LA x9, num_tmp
    add x9, x9, #32
    mov x10, x9
    mov x11, #10
1:  udiv x12, x0, x11
    msub x13, x12, x11, x0
    add w13, w13, #'0'
    strb w13, [x10, #-1]!
    mov x0, x12
    cbnz x0, 1b
    mov x0, x10
    sub x1, x9, x10
    ret

LEAF msg_addu
    mov x15, x30
    bl u64_to_dec
    mov x30, x15
    b msg_add

LEAF line_addu
    mov x15, x30
    bl u64_to_dec
    mov x30, x15
    b line_add

LEAF msg_tok
    LDX x9, g_tokens
    add x9, x9, w0, uxtw #4
    ldr w10, [x9, #T_OFF]
    ldr w1, [x9, #T_LEN]
    LDX x11, g_src
    add x0, x11, x10
    b msg_add

LEAF tok_pos
    LDX x9, g_tokens
    add x9, x9, w0, uxtw #4
    ldr w1, [x9, #T_LINE]
    ldrh w2, [x9, #T_COL]
    ret

FUNC line_head
    mov x19, x1
    mov x20, x2
    LA x9, line_desc
    str xzr, [x9]
    LDX x0, g_file
    bl line_addz
    mov w0, #':'
    bl line_addc
    mov x0, x19
    bl line_addu
    mov w0, #':'
    bl line_addc
    mov x0, x20
    bl line_addu
    ENDF

FUNC line_flush
    LA x0, msg_buf
    LA x9, msg_desc
    ldr x1, [x9]
    bl line_add
    LA x0, s_nl
    bl line_addz
    LA x0, line_buf
    LA x9, line_desc
    ldr x1, [x9]
    bl write_err
    ENDF

LEAF diag_error_tok
    mov x19, x0
    mov w0, w1
    bl tok_pos
    mov x0, x19

FUNC diag_error_at
    mov x19, x0
    bl line_head
    mov w0, #':'
    bl line_addc
    mov w0, #' '
    bl line_addc
    mov x0, x19
    bl line_addz
    LA x0, s_error_sp
    bl line_addz
    bl line_flush
    mov w0, #1
    bl sys_exit

FUNC diag_warn_tok
    bl tok_pos
    bl line_head
    LA x0, s_warning
    bl line_addz
    bl line_flush
    ENDF

FUNC fatal
    mov x19, x0
    bl msg_reset
    mov x0, x19
    bl msg_addz
    b .Lfatal_out

FUNC fatal_path
    mov x19, x0
    mov x20, x1
    bl msg_reset
    mov x0, x19
    bl msg_addz
    mov x0, x20
    bl msg_addz
    LA x0, s_quote
    bl msg_addz
.Lfatal_out:
    LA x9, line_desc
    str xzr, [x9]
    LA x0, s_error_pre
    bl line_addz
    bl line_flush
    mov w0, #1
    bl sys_exit
