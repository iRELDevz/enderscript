#include "defs.h"


    RODATA
s_syntax:
    .ascii "syntax"
    .byte 0
s_exp_stmt:
    .ascii "expected statement"
    .byte 0
s_exp_eol:
    .ascii "expected end of line"
    .byte 0
s_exp_type:
    .ascii "expected type after '.'"
    .byte 0
s_unk_type1:
    .ascii "unknown type '"
    .byte 0
s_unk_type2:
    .ascii "', expected int, str, or bool"
    .byte 0
s_exp_eq_type:
    .ascii "expected '=' after variable type"
    .byte 0
s_exp_after_n:
    .ascii "expected '.' or '=' after variable name"
    .byte 0
s_exp_mode:
    .ascii "expected print mode after '.'"
    .byte 0
s_exp_shr_p:
    .ascii "expected '>>' after 'print'"
    .byte 0
s_exp_shr_s:
    .ascii "expected '>>' after 'show'"
    .byte 0
s_exp_out:
    .ascii "expected value after '>>'"
    .byte 0
s_exp_rbrace:
    .ascii "expected '}'"
    .byte 0
s_exp_rparen:
    .ascii "expected ')'"
    .byte 0
s_too_deep:
    .ascii "expression is nested more than 1000 levels deep"
    .byte 0
s_too_long:
    .ascii "expression has more than 2000 values and operators"
    .byte 0
s_exp_colon:
    .ascii "expected ':' after the if condition"
    .byte 0
s_exp_block:
    .ascii "expected an indented block after 'if'"
    .byte 0
s_unexp_ind:
    .ascii "unexpected indentation"
    .byte 0
s_exp_cmp:
    .ascii "expected 'is', '==', 'isnot', '!=', '<', '>', '<=' or '>=' in the if condition"
    .byte 0
s_elif_no_if:
    .ascii "'elif' must follow an 'if' block"
    .byte 0
s_many_elif:
    .ascii "more than 2000 'elif' in one chain"
    .byte 0
s_exp_start:
    .ascii "expected 'start."
    .byte 0
s_after_open:
    .ascii "' on the line after 'loops("
    .byte 0
s_exp_count:
    .ascii "expected a repeat block like '100(' or 'stop."
    .byte 0
s_q_close:
    .ascii "'"
    .byte 0
s_exp_cnt_lp:
    .ascii "expected '(' after the repeat count"
    .byte 0
s_exp_grp_rp:
    .ascii "expected ')' after 'stop."
    .byte 0
s_unexp_rp:
    .ascii "unexpected ')'"
    .byte 0
s_open_block:
    .ascii "expected ')' to close the repeat block"
    .byte 0
s_missing_stop:
    .ascii "expected 'stop."
    .byte 0
s_stop_match:
    .ascii "' does not match 'loops("
    .byte 0
s_stop_q:
    .ascii "'stop."
    .byte 0
s_comma_q:
    .ascii ",'"
    .byte 0
w_start:
    .ascii "start"
    .byte 0
w_stop:
    .ascii "stop"
    .byte 0
s_exp_colon_e:
    .ascii "expected ':' after 'else'"
    .byte 0
s_exp_blk_els:
    .ascii "expected an indented block after 'else'"
    .byte 0
s_else_no_if:
    .ascii "'else' must follow an 'if' block"
    .byte 0
s_too_many_or:
    .ascii "more than 64 values joined with 'or' or 'and'"
    .byte 0
s_exp_loopvar:
    .ascii "expected a variable name after 'for'"
    .byte 0
s_exp_in:
    .ascii "expected 'in' after the loop variable"
    .byte 0
s_exp_range:
    .ascii "expected 'range' after 'in'"
    .byte 0
s_exp_lp_r:
    .ascii "expected '(' after 'range'"
    .byte 0
s_exp_lp_l:
    .ascii "expected '(' after 'loops'"
    .byte 0
s_exp_colon_l:
    .ascii "expected ':' after the loop header"
    .byte 0
s_exp_blk_for:
    .ascii "expected an indented block after 'for'"
    .byte 0
s_exp_blk_lps:
    .ascii "expected an indented block after 'loops'"
    .byte 0
s_no_float:
    .ascii "decimal numbers are not supported yet, use int"
    .byte 0
s_wrap:
    .ascii "values next to text must be wrapped in '{ }'"
    .byte 0
s_exp_value:
    .ascii "expected value"
    .byte 0
s_exp_number:
    .ascii "expected number after '-'"
    .byte 0
s_brk_out:
    .ascii "'break' outside a loop"
    .byte 0
s_cont_out:
    .ascii "'continue' outside a loop"
    .byte 0
s_exp_bname:
    .ascii "expected a loop name after 'break.'"
    .byte 0
s_no_group:
    .ascii "no staged loop named '"
    .byte 0
s_no_group2:
    .ascii "' around this 'break'"
    .byte 0
w_takedata:
    .ascii "takedata"
    .byte 0

    .bss
    .p2align 2
pr_depth:
    .zero (1) * 4
    .p2align 3
ps_depth:
    .zero (1) * 8
ps_lastif:
    .zero (1) * 8
ps_gn:
    .zero (1) * 8
ps_gstack:
    .zero (2 * (MAX_BLOCKS + 1)) * 8
ps_gstmt:
    .zero (MAX_BLOCKS + 1) * 8
ps_pflag:
    .zero (MAX_BLOCKS + 1) * 1
ps_vn:
    .zero (1) * 8
ps_vstack:
    .zero (2 * (MAX_ELIF + 1)) * 8
pr_bmsg:
    .zero (1) * 8
ps_stack:
    .zero (MAX_BLOCKS + 1) * 8
pg_nops:
    .zero (1) * 8
pg_ops:
    .zero (MAX_OR) * 4
pg_conn:
    .zero (MAX_OR) * 4
pg_oracc:
    .zero (1) * 4
pg_and:
    .zero (1) * 4
pg_op:
    .zero (1) * 4
pg_tok:
    .zero (1) * 4
pg_rhs:
    .zero (1) * 4

    .text



syn_error:
    stp x29, x30, [sp, #-16]!
    mov w19, w11
    mov x20, x10
    bl msg_reset
    mov x10, x20
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w19
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

FUNC parse
    adrp x8, g_ntok
    add x8, x8, :lo12:g_ntok
    ldr x16, [x8]
    mov x10, x16
    adds x10, x10, #1
    lsl x17, x10, #5
    mov x10, x17
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    str x9, [x8]
    mov x25, x9
    adrp x8, g_ntok
    add x8, x8, :lo12:g_ntok
    ldr x16, [x8]
    mov x10, x16
    adds x10, x10, #1
    lsl x17, x10, #4
    mov x10, x17
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    str x9, [x8]
    adrp x8, g_ntok
    add x8, x8, :lo12:g_ntok
    ldr x16, [x8]
    mov x10, x16
    adds x10, x10, #1
    lsl x17, x10, #2
    mov x10, x17
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    str x9, [x8]
    mov x17, #0
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    str x17, [x8]
    mov x17, #0
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    str x17, [x8]
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    mov x17, #0
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    str x17, [x8]
    mov x17, #0
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    str x17, [x8]
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    ldr x16, [x8]
    mov x23, x16
    eor w24, w24, w24
    eor w26, w26, w26

.Lparse_stmt:
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.ne .Lparse_not_nl
    adds x24, x24, #1
    b .Lparse_stmt
.Lparse_not_nl:
    cmp w9, #0
    b.eq .Lparse_done
    cmp w9, #34
    b.eq .Lparse_dedent
    cmp w9, #33
    b.eq .Lparse_unexpected_indent
    cmp w9, #39
    b.eq .Lparse_else_stmt
    cmp w9, #43
    b.eq .Lparse_elif_stmt
    str x9, [sp, #-16]!
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x10, x16
    bl close_virtual
    ldr x9, [sp], #16
    cmp w9, #24
    b.eq .Lparse_rparen_stmt
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x10, x16
    tst x10, x10
    b.eq .Lparse_no_group
    lsl x17, x10, #4
    mov x10, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x10, lsl #0
    sub x8, x8, #8
    ldr x16, [x8]
    mov x10, x16
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x17, [x8]
    cmp x10, x17
    b.eq .Lparse_group_level
.Lparse_no_group:
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    cmp w9, #26
    b.eq .Lparse_if_stmt
    cmp w9, #35
    b.eq .Lparse_for_stmt
    cmp w9, #38
    b.eq .Lparse_loops_stmt
    cmp w9, #2
    b.eq .Lparse_var_stmt
    cmp w9, #11
    b.eq .Lparse_print_stmt
    cmp w9, #12
    b.eq .Lparse_show_stmt
    cmp w9, #45
    b.eq .Lparse_break_stmt
    cmp w9, #46
    b.eq .Lparse_continue_stmt
    adrp x8, s_exp_stmt
    add x8, x8, :lo12:s_exp_stmt
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_continue_stmt:
    mov w17, #9
    sturh w17, [x25, #0]
    adrp x8, s_cont_out
    add x8, x8, :lo12:s_cont_out
    add x20, x8, #0
    b .Lparse_jump_stmt
.Lparse_break_stmt:
    mov w17, #8
    sturh w17, [x25, #0]
    adrp x8, s_brk_out
    add x8, x8, :lo12:s_brk_out
    add x20, x8, #0
.Lparse_jump_stmt:
    stur w24, [x25, #4]
    mov w17, #0
    sturh w17, [x25, #2]
    mov w17, #0
    stur w17, [x25, #12]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #0
    stur w17, [x25, #28]
    adds x24, x24, #1
    ldurh w16, [x25, #0]
    cmp w16, #8
    b.ne .Lparse_jump_inner
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #5
    b.eq .Lparse_break_group
.Lparse_jump_inner:
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x10, x16
.Lparse_jump_find:
    tst x10, x10
    b.eq .Lparse_jump_none
    subs x10, x10, #1
    adrp x8, ps_stack
    add x8, x8, :lo12:ps_stack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x10, lsl #3
    ldr x16, [x8]
    mov x9, x16
    mov x11, x9
    lsl x17, x11, #5
    mov x11, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x11, x11, x16
    ldurh w16, [x11, #0]
    cmp w16, #5
    b.eq .Lparse_jump_found
    ldurh w16, [x11, #0]
    cmp w16, #6
    b.ne .Lparse_jump_find
.Lparse_jump_found:
    stur w9, [x25, #8]
    ldurh w17, [x11, #2]
    mov w16, #1
    orr w17, w17, w16
    sturh w17, [x11, #2]
    b .Lparse_end_line
.Lparse_jump_none:
    mov x10, x20
    ldur w16, [x25, #4]
    mov w11, w16
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_break_group:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #2
    b.eq .Lparse_bg_name
    adrp x8, s_exp_bname
    add x8, x8, :lo12:s_exp_bname
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_bg_name:
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x20, x16
.Lparse_bg_find:
    tst x20, x20
    b.eq .Lparse_bg_none
    subs x20, x20, #1
    mov x9, x20
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    ldr x16, [x8]
    mov x10, x16
    mov w11, w24
    bl tok_same
    b.ne .Lparse_bg_find
    mov w17, #1
    sturh w17, [x25, #2]
    adrp x8, ps_gstmt
    add x8, x8, :lo12:ps_gstmt
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x20, lsl #3
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #8]
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w17, [x9, #2]
    mov w16, #2
    orr w17, w17, w16
    sturh w17, [x9, #2]
    lsl x17, x20, #4
    mov x20, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x20, lsl #0
    add x8, x8, #8
    ldr x16, [x8]
    mov x10, x16
.Lparse_bg_flag:
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x17, [x8]
    cmp x10, x17
    b.hs .Lparse_bg_done
    adrp x8, ps_stack
    add x8, x8, :lo12:ps_stack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x10, lsl #3
    ldr x16, [x8]
    mov x9, x16
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w16, [x9, #0]
    cmp w16, #5
    b.eq .Lparse_bg_mark
    ldurh w16, [x9, #0]
    cmp w16, #6
    b.ne .Lparse_bg_next
.Lparse_bg_mark:
    ldurh w17, [x9, #2]
    mov w16, #1
    orr w17, w17, w16
    sturh w17, [x9, #2]
.Lparse_bg_next:
    adds x10, x10, #1
    b .Lparse_bg_flag
.Lparse_bg_done:
    adds x24, x24, #1
    b .Lparse_end_line
.Lparse_bg_none:
    mov w19, w24
    bl msg_reset
    adrp x8, s_no_group
    add x8, x8, :lo12:s_no_group
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_no_group2
    add x8, x8, :lo12:s_no_group2
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w19
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lparse_var_stmt:
    stur w24, [x25, #4]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #5
    b.eq .Lparse_decl
    cmp w9, #6
    b.eq .Lparse_assign
    adrp x8, s_exp_after_n
    add x8, x8, :lo12:s_exp_after_n
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_decl:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    mov w10, #1
    cmp w9, #13
    b.eq .Lparse_have_type
    mov w10, #2
    cmp w9, #14
    b.eq .Lparse_have_type
    mov w10, #3
    cmp w9, #15
    b.eq .Lparse_have_type
    cmp w9, #2
    b.eq .Lparse_unknown_type
    adrp x8, s_exp_type
    add x8, x8, :lo12:s_exp_type
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_have_type:
    mov w17, #1
    sturh w17, [x25, #0]
    and w17, w10, #0xffff
    sturh w17, [x25, #2]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #6
    b.eq .Lparse_decl_eq
    adrp x8, s_exp_eq_type
    add x8, x8, :lo12:s_exp_eq_type
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_decl_eq:
    adds x24, x24, #1
    b .Lparse_value_opt
.Lparse_assign:
    mov w17, #2
    sturh w17, [x25, #0]
    adds x24, x24, #1
.Lparse_value_opt:
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #0
    stur w17, [x25, #12]
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_end_line
    cmp w9, #0
    b.eq .Lparse_end_line
    cmp w9, #47
    b.eq .Lparse_input_value
    bl parse_value
    bl push_root
    mov w17, #1
    stur w17, [x25, #12]
    b .Lparse_end_line

.Lparse_input_value:
    ldur w16, [x25, #4]
    mov w19, w16
    ldurh w16, [x25, #0]
    cmp w16, #1
    b.ne .Lparse_input_fill
    adds x25, x25, #32
.Lparse_input_fill:
    mov w17, #11
    sturh w17, [x25, #0]
    mov w17, #1
    sturh w17, [x25, #2]
    stur w19, [x25, #4]
    ldr w17, =4294967295
    stur w17, [x25, #20]
    mov w17, #0
    stur w17, [x25, #8]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #0
    stur w17, [x25, #12]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #8
    b.eq .Lparse_out_body
    b .Lparse_end_line

.Lparse_print_stmt:
    mov w17, #3
    sturh w17, [x25, #0]
    mov w17, #0
    sturh w17, [x25, #2]
    stur w24, [x25, #4]
    ldr w17, =4294967295
    stur w17, [x25, #20]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #5
    b.ne .Lparse_print_shr
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #2
    b.eq .Lparse_print_mode
    adrp x8, s_exp_mode
    add x8, x8, :lo12:s_exp_mode
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_print_mode:
    stur w24, [x25, #20]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
.Lparse_print_shr:
    cmp w9, #8
    b.eq .Lparse_out_body
    adrp x8, s_exp_shr_p
    add x8, x8, :lo12:s_exp_shr_p
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_show_stmt:
    mov w17, #3
    sturh w17, [x25, #0]
    mov w17, #1
    sturh w17, [x25, #2]
    stur w24, [x25, #4]
    ldr w17, =4294967295
    stur w17, [x25, #20]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #8
    b.eq .Lparse_out_body
    adrp x8, s_exp_shr_s
    add x8, x8, :lo12:s_exp_shr_s
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_out_body:
    adds x24, x24, #1
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x19, x16
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_out_empty
    cmp w9, #0
    b.ne .Lparse_out_part
.Lparse_out_empty:
    adrp x8, s_exp_out
    add x8, x8, :lo12:s_exp_out
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_out_part:
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_out_done
    cmp w9, #0
    b.eq .Lparse_out_done
    cmp w9, #4
    b.ne .Lparse_out_not_str
    bl parse_string
    bl push_root
    b .Lparse_out_part
.Lparse_out_not_str:
    cmp w9, #9
    b.ne .Lparse_out_bare
    adds x24, x24, #1
    bl parse_value
    mov w21, w9
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #10
    b.eq .Lparse_out_rbrace_ok
    adrp x8, s_exp_rbrace
    add x8, x8, :lo12:s_exp_rbrace
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_out_rbrace_ok:
    adds x24, x24, #1
    mov w9, w21
    bl push_root
    b .Lparse_out_part
.Lparse_out_bare:
    cmp w9, #3
    b.eq .Lparse_bare
    cmp w9, #7
    b.eq .Lparse_bare
    cmp w9, #16
    b.eq .Lparse_bare
    cmp w9, #17
    b.eq .Lparse_bare
    cmp w9, #18
    b.eq .Lparse_bare
    cmp w9, #2
    b.eq .Lparse_bare
    cmp w9, #23
    b.eq .Lparse_bare
    cmp w9, #25
    b.eq .Lparse_bare
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_bare:
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    cmp x9, x19
    b.eq .Lparse_bare_first
    adrp x8, s_wrap
    add x8, x8, :lo12:s_wrap
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_bare_first:
    mov x20, x24
    bl parse_value
    bl push_root
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_out_done
    cmp w9, #0
    b.eq .Lparse_out_done
    mov x24, x20
    adrp x8, s_wrap
    add x8, x8, :lo12:s_wrap
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_out_done:
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    subs x9, x9, x19
    stur w9, [x25, #12]

.Lparse_end_line:
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_line_ok
    cmp w9, #0
    b.eq .Lparse_line_ok
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_line_ok:
    adds x25, x25, #32
    b .Lparse_stmt

.Lparse_dedent:
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x10, x16
    bl close_virtual
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x10, x16
    tst x10, x10
    b.eq .Lparse_dedent_nogroup
    lsl x17, x10, #4
    mov x10, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x10, lsl #0
    sub x8, x8, #8
    ldr x16, [x8]
    mov x10, x16
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x17, [x8]
    cmp x10, x17
    b.eq .Lparse_done
.Lparse_dedent_nogroup:
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, ps_pflag
    add x8, x8, :lo12:ps_pflag
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    sub x8, x8, #1
    ldrb w16, [x8]
    cmp w16, #0
    b.eq .Lparse_dedent_plain
    adrp x8, s_open_block
    add x8, x8, :lo12:s_open_block
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_dedent_plain:
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    str x17, [x8]
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, ps_stack
    add x8, x8, :lo12:ps_stack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #3
    ldr x16, [x8]
    mov x9, x16
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    mov x11, x9
    lsl x17, x11, #5
    mov x11, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x11, x11, x16
    ldurh w16, [x11, #0]
    cmp w16, #4
    b.ne .Lparse_dedent_kind
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x9, [x8]
.Lparse_dedent_kind:
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x10, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x10, x10, x16
    lsr x17, x10, #5
    mov x10, x17
    stur w10, [x9, #28]
    adds x24, x24, #1
    b .Lparse_stmt

.Lparse_unexpected_indent:
    adrp x8, s_unexp_ind
    add x8, x8, :lo12:s_unexp_ind
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_group_start:
    add x19, x24, #1
    mov w19, w19
    adds x24, x24, #3
.Lparse_gs_nl:
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.ne .Lparse_gs_start
    adds x24, x24, #1
    b .Lparse_gs_nl
.Lparse_gs_start:
    mov w10, w24
    adrp x8, w_start
    add x8, x8, :lo12:w_start
    add x11, x8, #0
    mov w12, #5
    bl tok_word
    b.ne .Lparse_gs_bad
    add x9, x24, #1
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w16, [x8]
    cmp w16, #5
    b.ne .Lparse_gs_bad
    add x10, x24, #2
    mov w10, w10
    mov w11, w19
    bl tok_same
    b.ne .Lparse_gs_bad
    adds x24, x24, #3
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_gs_ok
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_gs_bad:
    adrp x8, s_exp_start
    add x8, x8, :lo12:s_exp_start
    add x20, x8, #0
    adrp x8, s_after_open
    add x8, x8, :lo12:s_after_open
    add x21, x8, #0
    b .Lparse_name_error
.Lparse_gs_ok:
    adds x24, x24, #1
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x9, x16
    cmp x9, #100
    b.lo .Lparse_gs_room
    adrp x8, s_too_many_or
    add x8, x8, :lo12:s_too_many_or
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_gs_room:
    mov w17, #10
    sturh w17, [x25, #0]
    mov w17, #0
    sturh w17, [x25, #2]
    stur w19, [x25, #4]
    mov w17, #0
    stur w17, [x25, #8]
    mov w17, #0
    stur w17, [x25, #12]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x11, x16
    stur w11, [x25, #16]
    mov w17, #0
    stur w17, [x25, #28]
    mov w17, #0
    stur w17, [x25, #20]
    mov w17, #0
    stur w17, [x25, #24]
    adrp x8, ps_gstmt
    add x8, x8, :lo12:ps_gstmt
    add x10, x8, #0
    mov x11, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x11, x11, x16
    lsr x17, x11, #5
    mov x11, x17
    mov x8, x10
    add x8, x8, x9, lsl #3
    str x11, [x8]
    adds x25, x25, #32
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    str x19, [x8]
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x11, x16
    mov x8, x10
    add x8, x8, x9, lsl #0
    add x8, x8, #8
    str x11, [x8]
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    str x17, [x8]
    b .Lparse_stmt

.Lparse_group_name:
    str x30, [sp, #-16]!
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x9, x16
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    sub x8, x8, #16
    ldr w16, [x8]
    mov w19, w16
    ldr x30, [sp], #16
    ret

.Lparse_name_error:
    str x21, [sp, #-16]!
    bl msg_reset
    mov x10, x20
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    ldr x10, [sp], #16
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_comma_q
    add x8, x8, :lo12:s_comma_q
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w24
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lparse_group_level:
    bl .Lparse_group_name
    mov w10, w24
    adrp x8, w_stop
    add x8, x8, :lo12:w_stop
    add x11, x8, #0
    mov w12, #4
    bl tok_word
    b.ne .Lparse_count_block
    add x9, x24, #1
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w16, [x8]
    cmp w16, #5
    b.ne .Lparse_count_block
    add x10, x24, #2
    mov w10, w10
    mov w11, w19
    bl tok_same
    b.eq .Lparse_stop_ok
    adds x24, x24, #2
    b .Lparse_stop_mismatch
.Lparse_stop_ok:
    adds x24, x24, #3
.Lparse_stop_nl:
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.ne .Lparse_stop_paren
    adds x24, x24, #1
    b .Lparse_stop_nl
.Lparse_stop_paren:
    cmp w9, #24
    b.eq .Lparse_stop_close
    bl msg_reset
    adrp x8, s_exp_grp_rp
    add x8, x8, :lo12:s_exp_grp_rp
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_q_close
    add x8, x8, :lo12:s_q_close
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w24
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lparse_stop_close:
    adds x24, x24, #1
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    str x17, [x8]
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x9, x16
    adrp x8, ps_gstmt
    add x8, x8, :lo12:ps_gstmt
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #3
    ldr x16, [x8]
    mov x9, x16
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x10, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x10, x10, x16
    lsr x17, x10, #5
    mov x10, x17
    stur w10, [x9, #28]
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_stmt
    cmp w9, #0
    b.eq .Lparse_stmt
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_stop_mismatch:
    bl msg_reset
    adrp x8, s_stop_q
    add x8, x8, :lo12:s_stop_q
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w24
    mov x0, x10
    bl msg_tok
    adrp x8, s_stop_match
    add x8, x8, :lo12:s_stop_match
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_comma_q
    add x8, x8, :lo12:s_comma_q
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w24
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lparse_count_block:
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #3
    b.eq .Lparse_count_ok
    cmp w9, #2
    b.eq .Lparse_count_ok
    cmp w9, #23
    b.eq .Lparse_count_ok
    cmp w9, #7
    b.eq .Lparse_count_ok
    bl msg_reset
    adrp x8, s_exp_count
    add x8, x8, :lo12:s_exp_count
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_q_close
    add x8, x8, :lo12:s_q_close
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w24
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lparse_count_ok:
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    mov w17, #6
    sturh w17, [x25, #0]
    mov w17, #0
    sturh w17, [x25, #2]
    mov w17, #0
    stur w17, [x25, #28]
    stur w24, [x25, #4]
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x9, x16
    adrp x8, ps_gstmt
    add x8, x8, :lo12:ps_gstmt
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #3
    sub x8, x8, #8
    ldr x16, [x8]
    mov x9, x16
    adds w9, w9, #1
    stur w9, [x25, #20]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #1
    stur w17, [x25, #12]
    bl parse_value
    bl push_root
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #23
    b.eq .Lparse_count_paren
    adrp x8, s_exp_cnt_lp
    add x8, x8, :lo12:s_exp_cnt_lp
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_count_paren:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_count_nl
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_count_nl:
    adds x24, x24, #1
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x9, x16
    cmp x9, #100
    b.lo .Lparse_count_room
    adrp x8, s_too_many_or
    add x8, x8, :lo12:s_too_many_or
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_count_room:
    adrp x8, ps_pflag
    add x8, x8, :lo12:ps_pflag
    add x10, x8, #0
    mov w17, #1
    mov x8, x10
    add x8, x8, x9, lsl #0
    strb w17, [x8]
    adrp x8, ps_stack
    add x8, x8, :lo12:ps_stack
    add x10, x8, #0
    mov x11, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x11, x11, x16
    lsr x17, x11, #5
    mov x11, x17
    mov x8, x10
    add x8, x8, x9, lsl #3
    str x11, [x8]
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    str x17, [x8]
    adds x25, x25, #32
    b .Lparse_stmt

.Lparse_rparen_stmt:
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x9, x16
    tst x9, x9
    b.eq .Lparse_rparen_bad
    adrp x8, ps_pflag
    add x8, x8, :lo12:ps_pflag
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    sub x8, x8, #1
    ldrb w16, [x8]
    cmp w16, #0
    b.ne .Lparse_rparen_close
.Lparse_rparen_bad:
    adrp x8, s_unexp_rp
    add x8, x8, :lo12:s_unexp_rp
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_rparen_close:
    subs x9, x9, #1
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    str x9, [x8]
    adrp x8, ps_stack
    add x8, x8, :lo12:ps_stack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #3
    ldr x16, [x8]
    mov x9, x16
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x10, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x10, x10, x16
    lsr x17, x10, #5
    mov x10, x17
    stur w10, [x9, #28]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_stmt
    cmp w9, #0
    b.eq .Lparse_stmt
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_elif_stmt:
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    ldr x16, [x8]
    mov x9, x16
    cmn x9, #1
    b.ne .Lparse_elif_ok
    adrp x8, s_elif_no_if
    add x8, x8, :lo12:s_elif_no_if
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_elif_ok:
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    ldr x16, [x8]
    cmp x16, #2000
    b.lo .Lparse_elif_room
    adrp x8, s_many_elif
    add x8, x8, :lo12:s_many_elif
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_elif_room:
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    mov w17, #7
    sturh w17, [x25, #0]
    stur w24, [x25, #4]
    stur w9, [x25, #8]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #0
    stur w17, [x25, #12]
    mov w17, #0
    stur w17, [x25, #28]
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    ldr x16, [x8]
    mov x9, x16
    adrp x8, ps_vstack
    add x8, x8, :lo12:ps_vstack
    add x10, x8, #0
    lsl x17, x9, #4
    mov x9, x17
    mov x11, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x11, x11, x16
    lsr x17, x11, #5
    mov x11, x17
    mov x8, x10
    add x8, x8, x9, lsl #0
    str x11, [x8]
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x11, x16
    mov x8, x10
    add x8, x8, x9, lsl #0
    add x8, x8, #8
    str x11, [x8]
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    str x17, [x8]
    adds x25, x25, #32
    b .Lparse_if_stmt

.Lparse_else_stmt:
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    ldr x16, [x8]
    mov x9, x16
    cmn x9, #1
    b.ne .Lparse_else_ok
    adrp x8, s_else_no_if
    add x8, x8, :lo12:s_else_no_if
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_else_ok:
    ldr x17, =18446744073709551615
    adrp x8, ps_lastif
    add x8, x8, :lo12:ps_lastif
    str x17, [x8]
    adrp x8, s_exp_blk_els
    add x8, x8, :lo12:s_exp_blk_els
    add x10, x8, #0
    adrp x8, pr_bmsg
    add x8, x8, :lo12:pr_bmsg
    str x10, [x8]
    mov w17, #7
    sturh w17, [x25, #0]
    stur w24, [x25, #4]
    stur w9, [x25, #8]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #0
    stur w17, [x25, #12]
    mov w17, #0
    stur w17, [x25, #28]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #32
    b.eq .Lparse_if_colon
    adrp x8, s_exp_colon_e
    add x8, x8, :lo12:s_exp_colon_e
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_if_stmt:
    adrp x8, s_exp_block
    add x8, x8, :lo12:s_exp_block
    add x9, x8, #0
    adrp x8, pr_bmsg
    add x8, x8, :lo12:pr_bmsg
    str x9, [x8]
    mov w17, #4
    sturh w17, [x25, #0]
    stur w24, [x25, #4]
    adds x24, x24, #1
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #1
    stur w17, [x25, #12]
    mov w17, #0
    stur w17, [x25, #28]
    bl parse_cond
    bl push_root
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #32
    b.eq .Lparse_if_colon
    adrp x8, s_exp_colon
    add x8, x8, :lo12:s_exp_colon
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_if_colon:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_if_nl
    cmp w9, #0
    b.eq .Lparse_if_no_block
    adrp x8, s_exp_eol
    add x8, x8, :lo12:s_exp_eol
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_if_nl:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #1
    b.eq .Lparse_if_nl
    cmp w9, #33
    b.eq .Lparse_if_block
.Lparse_if_no_block:
    adrp x8, pr_bmsg
    add x8, x8, :lo12:pr_bmsg
    ldr x16, [x8]
    mov x10, x16
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_if_block:
    adds x24, x24, #1
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, ps_pflag
    add x8, x8, :lo12:ps_pflag
    add x10, x8, #0
    mov w17, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    strb w17, [x8]
    adrp x8, ps_stack
    add x8, x8, :lo12:ps_stack
    add x10, x8, #0
    mov x11, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x11, x11, x16
    lsr x17, x11, #5
    mov x11, x17
    mov x8, x10
    add x8, x8, x9, lsl #3
    str x11, [x8]
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, ps_depth
    add x8, x8, :lo12:ps_depth
    str x17, [x8]
    adds x25, x25, #32
    b .Lparse_stmt

.Lparse_for_stmt:
    adrp x8, s_exp_blk_for
    add x8, x8, :lo12:s_exp_blk_for
    add x9, x8, #0
    adrp x8, pr_bmsg
    add x8, x8, :lo12:pr_bmsg
    str x9, [x8]
    mov w17, #5
    sturh w17, [x25, #0]
    mov w17, #0
    sturh w17, [x25, #2]
    mov w17, #0
    stur w17, [x25, #20]
    mov w17, #0
    stur w17, [x25, #28]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #2
    b.eq .Lparse_for_var
    adrp x8, s_exp_loopvar
    add x8, x8, :lo12:s_exp_loopvar
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_for_var:
    stur w24, [x25, #4]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #36
    b.eq .Lparse_for_in
    adrp x8, s_exp_in
    add x8, x8, :lo12:s_exp_in
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_for_in:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #37
    b.eq .Lparse_for_range
    adrp x8, s_exp_range
    add x8, x8, :lo12:s_exp_range
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_for_range:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #23
    b.eq .Lparse_loop_count
    adrp x8, s_exp_lp_r
    add x8, x8, :lo12:s_exp_lp_r
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_loops_stmt:
    adrp x8, s_exp_blk_lps
    add x8, x8, :lo12:s_exp_blk_lps
    add x9, x8, #0
    adrp x8, pr_bmsg
    add x8, x8, :lo12:pr_bmsg
    str x9, [x8]
    mov w17, #6
    sturh w17, [x25, #0]
    mov w17, #0
    sturh w17, [x25, #2]
    mov w17, #0
    stur w17, [x25, #20]
    mov w17, #0
    stur w17, [x25, #28]
    stur w24, [x25, #4]
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #23
    b.eq .Lparse_loops_paren
    adrp x8, s_exp_lp_l
    add x8, x8, :lo12:s_exp_lp_l
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_loops_paren:
    add x9, x24, #2
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    sub x8, x8, #16
    ldrh w16, [x8]
    cmp w16, #2
    b.ne .Lparse_loop_count
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w16, [x8]
    cmp w16, #44
    b.ne .Lparse_loop_count
    b .Lparse_group_start

.Lparse_loop_count:
    adds x24, x24, #1
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x25, #16]
    mov w17, #1
    stur w17, [x25, #12]
    bl parse_value
    bl push_root
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #24
    b.eq .Lparse_loop_rparen
    adrp x8, s_exp_rparen
    add x8, x8, :lo12:s_exp_rparen
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error
.Lparse_loop_rparen:
    adds x24, x24, #1
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #32
    b.eq .Lparse_if_colon
    adrp x8, s_exp_colon_l
    add x8, x8, :lo12:s_exp_colon_l
    add x10, x8, #0
    mov w11, w24
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    b syn_error

.Lparse_unknown_type:
    mov w19, w24
    bl msg_reset
    adrp x8, s_unk_type1
    add x8, x8, :lo12:s_unk_type1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_unk_type2
    add x8, x8, :lo12:s_unk_type2
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w19
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lparse_done:
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    cmp x16, #0
    b.eq .Lparse_done_groups
    bl .Lparse_group_name
    bl msg_reset
    adrp x8, s_missing_stop
    add x8, x8, :lo12:s_missing_stop
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w19
    mov x0, x10
    bl msg_tok
    adrp x8, s_q_close
    add x8, x8, :lo12:s_q_close
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_syntax
    add x8, x8, :lo12:s_syntax
    add x10, x8, #0
    mov w11, w24
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lparse_done_groups:
    eor w10, w10, w10
    bl close_virtual
    mov x9, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x9, x9, x16
    lsr x17, x9, #5
    mov x9, x17
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    str x9, [x8]
    adrp x8, g_nparts
    add x8, x8, :lo12:g_nparts
    str x26, [x8]
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

tok_word:
    stp x29, x30, [sp, #-16]!
    mov x9, x10
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w16, [x9, #0]
    cmp w16, #2
    b.ne .Ltok_word_r
    ldur w16, [x9, #12]
    cmp w16, w12
    b.ne .Ltok_word_r
    ldur w16, [x9, #8]
    mov w13, w16
    adrp x8, g_src
    add x8, x8, :lo12:g_src
    ldr x16, [x8]
    adds x13, x13, x16
    eor w14, w14, w14
.Ltok_word_l:
    cmp w14, w12
    b.hs .Ltok_word_eq
    mov x8, x13
    add x8, x8, x14, lsl #0
    ldrb w17, [x8]
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    mov x8, x11
    add x8, x8, x14, lsl #0
    ldrb w17, [x8]
    cmp w16, w17
    b.ne .Ltok_word_r
    adds w14, w14, #1
    b .Ltok_word_l
.Ltok_word_eq:
    cmp w9, w9
.Ltok_word_r:
    ldp x29, x30, [sp], #16
    ret

tok_same:
    stp x29, x30, [sp, #-16]!
    mov x9, x10
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    ldr x16, [x8]
    adds x9, x9, x16
    mov x12, x11
    lsl x17, x12, #4
    mov x12, x17
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    ldr x16, [x8]
    adds x12, x12, x16
    ldurh w16, [x9, #0]
    cmp w16, #2
    b.ne .Ltok_same_r
    ldur w16, [x9, #12]
    mov w13, w16
    ldur w17, [x12, #12]
    cmp w13, w17
    b.ne .Ltok_same_r
    ldur w16, [x9, #8]
    mov w14, w16
    adrp x8, g_src
    add x8, x8, :lo12:g_src
    ldr x16, [x8]
    adds x14, x14, x16
    ldur w16, [x12, #8]
    mov w15, w16
    adrp x8, g_src
    add x8, x8, :lo12:g_src
    ldr x16, [x8]
    adds x15, x15, x16
    eor w10, w10, w10
.Ltok_same_l:
    cmp w10, w13
    b.hs .Ltok_same_eq
    mov x8, x14
    add x8, x8, x10, lsl #0
    ldrb w17, [x8]
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    mov x8, x15
    add x8, x8, x10, lsl #0
    ldrb w17, [x8]
    cmp w16, w17
    b.ne .Ltok_same_r
    adds w10, w10, #1
    b .Ltok_same_l
.Ltok_same_eq:
    cmp w9, w9
.Ltok_same_r:
    ldp x29, x30, [sp], #16
    ret

close_virtual:
    stp x29, x30, [sp, #-16]!
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    ldr x16, [x8]
    mov x9, x16
    tst x9, x9
    b.eq .Lclose_virtual_r
    subs x9, x9, #1
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, ps_vstack
    add x8, x8, :lo12:ps_vstack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x9, lsl #0
    add x8, x8, #8
    ldr x16, [x8]
    cmp x16, x10
    b.lo .Lclose_virtual_r
    mov x8, x11
    add x8, x8, x9, lsl #0
    ldr x16, [x8]
    mov x9, x16
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x11, x25
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x11, x11, x16
    lsr x17, x11, #5
    mov x11, x17
    stur w11, [x9, #28]
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, ps_vn
    add x8, x8, :lo12:ps_vn
    str x17, [x8]
    ldp x29, x30, [sp], #16
    b close_virtual
.Lclose_virtual_r:
    ldp x29, x30, [sp], #16
    ret

parse_value:
    stp x29, x30, [sp, #-16]!
    mov w17, #0
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    str w17, [x8]
    str x26, [sp, #-16]!
    str x24, [sp, #-16]!
    bl parse_expr
    ldr x11, [sp], #16
    ldr x10, [sp], #16
    mov x12, x26
    subs x12, x12, x10
    cmp x12, #2000
    b.hi .Lparse_value_too_long
    ldp x29, x30, [sp], #16
    ret
.Lparse_value_too_long:
    mov x24, x11
    adrp x8, s_too_long
    add x8, x8, :lo12:s_too_long
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error

push_root:
    stp x29, x30, [sp, #-16]!
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x16, [x8]
    mov x10, x16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x10, lsl #2
    str w9, [x8]
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, g_nroots
    add x8, x8, :lo12:g_nroots
    str x17, [x8]
    ldp x29, x30, [sp], #16
    ret

new_node:
    stp x29, x30, [sp, #-16]!
    mov x14, x26
    lsl x17, x14, #4
    mov x14, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x14, x14, x16
    mov x17, #0
    stur x17, [x14, #0]
    mov x17, #0
    stur x17, [x14, #8]
    and w17, w10, #0xff
    sturb w17, [x14, #0]
    stur w11, [x14, #4]
    mov w9, w26
    adds x26, x26, #1
    ldp x29, x30, [sp], #16
    ret

new_op:
    stp x29, x30, [sp, #-16]!
    str x9, [sp, #-16]!
    mov w10, #6
    mov w11, w15
    bl new_node
    ldr x11, [sp], #16
    and w17, w13, #0xff
    sturb w17, [x14, #1]
    stur w11, [x14, #8]
    stur w12, [x14, #12]
    ldp x29, x30, [sp], #16
    ret

parse_expr:
    stp x29, x30, [sp, #-16]!
    bl parse_term
.Lparse_expr_loop:
    mov w12, w9
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    mov w13, #1
    cmp w9, #19
    b.eq .Lparse_expr_op
    mov w13, #2
    cmp w9, #7
    b.eq .Lparse_expr_op
    mov w9, w12
    ldp x29, x30, [sp], #16
    ret
.Lparse_expr_op:
    str x12, [sp, #-16]!
    str x13, [sp, #-16]!
    str x24, [sp, #-16]!
    adds x24, x24, #1
    bl parse_term
    mov w12, w9
    ldr x15, [sp], #16
    ldr x13, [sp], #16
    ldr x9, [sp], #16
    bl new_op
    b .Lparse_expr_loop

parse_term:
    stp x29, x30, [sp, #-16]!
    bl parse_factor
.Lparse_term_loop:
    mov w12, w9
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    mov w13, #3
    cmp w9, #20
    b.eq .Lparse_term_op
    mov w13, #4
    cmp w9, #21
    b.eq .Lparse_term_op
    mov w13, #5
    cmp w9, #22
    b.eq .Lparse_term_op
    mov w9, w12
    ldp x29, x30, [sp], #16
    ret
.Lparse_term_op:
    str x12, [sp, #-16]!
    str x13, [sp, #-16]!
    str x24, [sp, #-16]!
    adds x24, x24, #1
    bl parse_factor
    mov w12, w9
    ldr x15, [sp], #16
    ldr x13, [sp], #16
    ldr x9, [sp], #16
    bl new_op
    b .Lparse_term_loop

parse_factor:
    stp x29, x30, [sp, #-16]!
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    ldr w17, [x8]
    adds w17, w17, #1
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    str w17, [x8]
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    ldr w16, [x8]
    cmp w16, #1000
    b.hi .Lparse_factor_too_deep
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #7
    b.eq .Lparse_factor_minus
    cmp w9, #23
    b.eq .Lparse_factor_paren
    bl parse_primary
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    ldr w17, [x8]
    subs w17, w17, #1
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    str w17, [x8]
    ldp x29, x30, [sp], #16
    ret
.Lparse_factor_minus:
    mov x9, x24
    adds x9, x9, #1
    lsl x17, x9, #4
    mov x9, x17
    adds x9, x9, x23
    ldurh w9, [x9, #0]
    cmp w9, #3
    b.ne .Lparse_factor_negate
    adds x24, x24, #1
    mov w10, #1
    mov w11, w24
    bl new_node
    mov w17, #1
    sturb w17, [x14, #1]
    adds x24, x24, #1
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    ldr w17, [x8]
    subs w17, w17, #1
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    str w17, [x8]
    ldp x29, x30, [sp], #16
    ret
.Lparse_factor_negate:
    str x24, [sp, #-16]!
    adds x24, x24, #1
    bl parse_factor
    ldr x15, [sp], #16
    mov w13, #6
    ldr w12, =4294967295
    bl new_op
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    ldr w17, [x8]
    subs w17, w17, #1
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    str w17, [x8]
    ldp x29, x30, [sp], #16
    ret
.Lparse_factor_paren:
    adds x24, x24, #1
    bl parse_expr
    mov w12, w9
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #24
    b.eq .Lparse_factor_paren_ok
    adrp x8, s_exp_rparen
    add x8, x8, :lo12:s_exp_rparen
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error
.Lparse_factor_paren_ok:
    adds x24, x24, #1
    mov w9, w12
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    ldr w17, [x8]
    subs w17, w17, #1
    adrp x8, pr_depth
    add x8, x8, :lo12:pr_depth
    str w17, [x8]
    ldp x29, x30, [sp], #16
    ret
.Lparse_factor_too_deep:
    adrp x8, s_too_deep
    add x8, x8, :lo12:s_too_deep
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error

parse_primary:
    stp x29, x30, [sp, #-16]!
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    mov w10, #1
    cmp w9, #3
    b.eq .Lparse_primary_leaf
    mov w10, #2
    cmp w9, #4
    b.eq .Lparse_primary_leaf
    mov w10, #4
    cmp w9, #18
    b.eq .Lparse_primary_leaf
    mov w10, #5
    cmp w9, #2
    b.eq .Lparse_primary_ident
    cmp w9, #16
    b.eq .Lparse_primary_true
    cmp w9, #17
    b.eq .Lparse_primary_false
    cmp w9, #25
    b.eq .Lparse_primary_fnum
    adrp x8, s_exp_value
    add x8, x8, :lo12:s_exp_value
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error
.Lparse_primary_true:
    mov w10, #3
    mov w11, w24
    bl new_node
    mov w17, #1
    stur w17, [x14, #8]
    adds x24, x24, #1
    ldp x29, x30, [sp], #16
    ret
.Lparse_primary_false:
    mov w10, #3
.Lparse_primary_leaf:
    mov w11, w24
    bl new_node
    adds x24, x24, #1
    ldp x29, x30, [sp], #16
    ret
.Lparse_primary_fnum:
    adrp x8, s_no_float
    add x8, x8, :lo12:s_no_float
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error
.Lparse_primary_ident:
    add x9, x24, #1
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w16, [x8]
    cmp w16, #5
    b.ne .Lparse_primary_leaf
    mov x8, x23
    add x8, x8, x9, lsl #0
    add x8, x8, #16
    ldrh w16, [x8]
    cmp w16, #2
    b.ne .Lparse_primary_leaf
    add x10, x24, #2
    mov w10, w10
    adrp x8, w_takedata
    add x8, x8, :lo12:w_takedata
    add x11, x8, #0
    mov w12, #8
    bl tok_word
    mov w10, #5
    b.ne .Lparse_primary_leaf
    str x20, [sp, #-16]!
    adrp x8, ps_gn
    add x8, x8, :lo12:ps_gn
    ldr x16, [x8]
    mov x20, x16
.Lparse_primary_take_find:
    ldr w9, =4294967295
    tst x20, x20
    b.eq .Lparse_primary_take_set
    subs x20, x20, #1
    mov x9, x20
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, ps_gstack
    add x8, x8, :lo12:ps_gstack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    ldr x16, [x8]
    mov x10, x16
    mov w11, w24
    bl tok_same
    b.ne .Lparse_primary_take_find
    adrp x8, ps_gstmt
    add x8, x8, :lo12:ps_gstmt
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x20, lsl #3
    ldr x16, [x8]
    mov x9, x16
.Lparse_primary_take_set:
    ldr x20, [sp], #16
    mov w13, w9
    mov w10, #10
    mov w11, w24
    bl new_node
    stur w13, [x14, #8]
    cmn w13, #1
    b.eq .Lparse_primary_take_done
    mov w12, w13
    lsl x17, x12, #5
    mov x12, x17
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    adds x12, x12, x16
    ldurh w17, [x12, #2]
    mov w16, #1
    orr w17, w17, w16
    sturh w17, [x12, #2]
.Lparse_primary_take_done:
    adds x24, x24, #3
    ldp x29, x30, [sp], #16
    ret

parse_string:
    stp x29, x30, [sp, #-16]!
    mov w10, #2
    mov w11, w24
    bl new_node
    adds x24, x24, #1
    ldp x29, x30, [sp], #16
    ret

new_pair:
    stp x29, x30, [sp, #-16]!
    str x9, [sp, #-16]!
    bl new_node
    ldr x11, [sp], #16
    and w17, w13, #0xff
    sturb w17, [x14, #1]
    stur w11, [x14, #8]
    stur w12, [x14, #12]
    ldp x29, x30, [sp], #16
    ret

parse_cond:
    stp x29, x30, [sp, #-16]!
    bl parse_and
.Lparse_cond_loop:
    str x9, [sp, #-16]!
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #29
    b.ne .Lparse_cond_done
    str x24, [sp, #-16]!
    adds x24, x24, #1
    bl parse_and
    mov w12, w9
    ldr x11, [sp], #16
    ldr x9, [sp], #16
    mov w10, #8
    eor w13, w13, w13
    bl new_pair
    b .Lparse_cond_loop
.Lparse_cond_done:
    ldr x9, [sp], #16
    ldp x29, x30, [sp], #16
    ret

parse_and:
    stp x29, x30, [sp, #-16]!
    bl parse_group
.Lparse_and_loop:
    str x9, [sp, #-16]!
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    cmp w9, #40
    b.ne .Lparse_and_done
    str x24, [sp, #-16]!
    adds x24, x24, #1
    bl parse_group
    mov w12, w9
    ldr x11, [sp], #16
    ldr x9, [sp], #16
    mov w10, #9
    eor w13, w13, w13
    bl new_pair
    b .Lparse_and_loop
.Lparse_and_done:
    ldr x9, [sp], #16
    ldp x29, x30, [sp], #16
    ret

parse_group:
    stp x29, x30, [sp, #-16]!
    mov x17, #0
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    str x17, [x8]
.Lparse_group_operand:
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    ldr x16, [x8]
    mov x9, x16
    cmp x9, #64
    b.hs .Lparse_group_too_many
    str x9, [sp, #-16]!
    bl parse_value
    ldr x10, [sp], #16
    adrp x8, pg_ops
    add x8, x8, :lo12:pg_ops
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x10, lsl #2
    str w9, [x8]
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    str x17, [x8]
    mov x9, x24
    lsl x17, x9, #4
    mov x9, x17
    mov x8, x23
    add x8, x8, x9, lsl #0
    ldrh w9, [x8]
    mov w10, #8
    cmp w9, #29
    b.eq .Lparse_group_connector
    mov w10, #9
    cmp w9, #40
    b.ne .Lparse_group_compare
.Lparse_group_connector:
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    ldr x16, [x8]
    mov x9, x16
    cmp x9, #64
    b.hs .Lparse_group_too_many
    adrp x8, pg_conn
    add x8, x8, :lo12:pg_conn
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x9, lsl #2
    str w10, [x8]
    adds x24, x24, #1
    b .Lparse_group_operand
.Lparse_group_compare:
    mov w13, #1
    cmp w9, #27
    b.eq .Lparse_group_have_op
    mov w13, #2
    cmp w9, #28
    b.eq .Lparse_group_have_op
    mov w13, #3
    cmp w9, #30
    b.eq .Lparse_group_have_op
    mov w13, #4
    cmp w9, #31
    b.eq .Lparse_group_have_op
    mov w13, #5
    cmp w9, #41
    b.eq .Lparse_group_have_op
    mov w13, #6
    cmp w9, #42
    b.eq .Lparse_group_have_op
    adrp x8, s_exp_cmp
    add x8, x8, :lo12:s_exp_cmp
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error
.Lparse_group_have_op:
    adrp x8, pg_op
    add x8, x8, :lo12:pg_op
    str w13, [x8]
    adrp x8, pg_tok
    add x8, x8, :lo12:pg_tok
    str w24, [x8]
    adds x24, x24, #1
    bl parse_value
    adrp x8, pg_rhs
    add x8, x8, :lo12:pg_rhs
    str w9, [x8]
    eor w20, w20, w20
.Lparse_group_cmps:
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    ldr x17, [x8]
    cmp x20, x17
    b.hs .Lparse_group_cmps_done
    adrp x8, pg_ops
    add x8, x8, :lo12:pg_ops
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x20, lsl #2
    ldr w16, [x8]
    mov w9, w16
    adrp x8, pg_rhs
    add x8, x8, :lo12:pg_rhs
    ldr w16, [x8]
    mov w12, w16
    adrp x8, pg_op
    add x8, x8, :lo12:pg_op
    ldr w16, [x8]
    mov w13, w16
    adrp x8, pg_tok
    add x8, x8, :lo12:pg_tok
    ldr w16, [x8]
    mov w11, w16
    mov w10, #7
    bl new_pair
    adrp x8, pg_ops
    add x8, x8, :lo12:pg_ops
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x20, lsl #2
    str w9, [x8]
    adds x20, x20, #1
    b .Lparse_group_cmps
.Lparse_group_cmps_done:
    ldr w17, =4294967295
    adrp x8, pg_oracc
    add x8, x8, :lo12:pg_oracc
    str w17, [x8]
    adrp x8, pg_ops
    add x8, x8, :lo12:pg_ops
    ldr w16, [x8]
    mov w9, w16
    adrp x8, pg_and
    add x8, x8, :lo12:pg_and
    str w9, [x8]
    mov w20, #1
.Lparse_group_chain:
    adrp x8, pg_nops
    add x8, x8, :lo12:pg_nops
    ldr x17, [x8]
    cmp x20, x17
    b.hs .Lparse_group_chain_done
    adrp x8, pg_conn
    add x8, x8, :lo12:pg_conn
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x20, lsl #2
    ldr w16, [x8]
    cmp w16, #9
    b.ne .Lparse_group_chain_or
    adrp x8, pg_and
    add x8, x8, :lo12:pg_and
    ldr w16, [x8]
    mov w9, w16
    adrp x8, pg_ops
    add x8, x8, :lo12:pg_ops
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x20, lsl #2
    ldr w16, [x8]
    mov w12, w16
    adrp x8, pg_tok
    add x8, x8, :lo12:pg_tok
    ldr w16, [x8]
    mov w11, w16
    mov w10, #9
    eor w13, w13, w13
    bl new_pair
    adrp x8, pg_and
    add x8, x8, :lo12:pg_and
    str w9, [x8]
    b .Lparse_group_chain_next
.Lparse_group_chain_or:
    bl .Lparse_group_flush_and
    adrp x8, pg_ops
    add x8, x8, :lo12:pg_ops
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x20, lsl #2
    ldr w16, [x8]
    mov w9, w16
    adrp x8, pg_and
    add x8, x8, :lo12:pg_and
    str w9, [x8]
.Lparse_group_chain_next:
    adds x20, x20, #1
    b .Lparse_group_chain
.Lparse_group_chain_done:
    bl .Lparse_group_flush_and
    adrp x8, pg_oracc
    add x8, x8, :lo12:pg_oracc
    ldr w16, [x8]
    mov w9, w16
    ldp x29, x30, [sp], #16
    ret
.Lparse_group_flush_and:
    str x30, [sp, #-16]!
    adrp x8, pg_and
    add x8, x8, :lo12:pg_and
    ldr w16, [x8]
    mov w9, w16
    adrp x8, pg_oracc
    add x8, x8, :lo12:pg_oracc
    ldr w16, [x8]
    cmn w16, #1
    b.eq .Lparse_group_flush_set
    mov w12, w9
    adrp x8, pg_oracc
    add x8, x8, :lo12:pg_oracc
    ldr w16, [x8]
    mov w9, w16
    adrp x8, pg_tok
    add x8, x8, :lo12:pg_tok
    ldr w16, [x8]
    mov w11, w16
    mov w10, #8
    eor w13, w13, w13
    bl new_pair
.Lparse_group_flush_set:
    adrp x8, pg_oracc
    add x8, x8, :lo12:pg_oracc
    str w9, [x8]
    ldr x30, [sp], #16
    ret
.Lparse_group_too_many:
    adrp x8, s_too_many_or
    add x8, x8, :lo12:s_too_many_or
    add x10, x8, #0
    mov w11, w24
    ldp x29, x30, [sp], #16
    b syn_error

