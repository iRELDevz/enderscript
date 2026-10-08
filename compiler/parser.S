#include "defs.h"

    RODATA
s_syntax:      .asciz "syntax"
s_exp_stmt:    .asciz "expected statement"
s_exp_eol:     .asciz "expected end of line"
s_exp_type:    .asciz "expected type after '.'"
s_unk_type1:   .asciz "unknown type '"
s_unk_type2:   .asciz "', expected int, str, or bool"
s_exp_eq_type: .asciz "expected '=' after variable type"
s_exp_after_n: .asciz "expected '.' or '=' after variable name"
s_exp_mode:    .asciz "expected print mode after '.'"
s_exp_shr_p:   .asciz "expected '>>' after 'print'"
s_exp_shr_s:   .asciz "expected '>>' after 'show'"
s_exp_out:     .asciz "expected value after '>>'"
s_exp_rbrace:  .asciz "expected '}'"
s_exp_rparen:  .asciz "expected ')'"
s_too_deep:    .asciz "expression is nested more than 1000 levels deep"
s_too_long:    .asciz "expression has more than 2000 values and operators"
s_no_float:    .asciz "decimal numbers are not supported yet, use int"
s_wrap:        .asciz "values next to text must be wrapped in '{ }'"
s_exp_value:   .asciz "expected value"
s_exp_number:  .asciz "expected number after '-'"

    .bss
    .p2align 3
pr_depth: .zero 8

    .text

.macro CUR
    add x9, x19, x20, lsl #4
    ldrh w9, [x9]
.endm

.macro SYNERR msg
    LA x0, \msg
    mov w1, w20
    b syn_error
.endm

LEAF syn_error
    mov x27, x0
    mov w28, w1
    bl msg_reset
    mov x0, x27
    bl msg_addz
    LA x0, s_syntax
    mov w1, w28
    bl diag_error_tok

FUNC parse
    LDX x0, g_ntok
    add x0, x0, #1
    lsl x0, x0, #5
    bl mem_alloc
    STX x0, g_stmts
    mov x21, x0
    LDX x0, g_ntok
    add x0, x0, #1
    lsl x0, x0, #4
    bl mem_alloc
    STX x0, g_parts
    LDX x0, g_ntok
    add x0, x0, #1
    lsl x0, x0, #2
    bl mem_alloc
    STX x0, g_roots
    STX xzr, g_nroots
    LDX x19, g_tokens
    mov x20, #0
    mov x22, #0

.Lps_stmt:
    CUR
    cmp w9, #TK_NL
    b.ne .Lps_not_nl
    add x20, x20, #1
    b .Lps_stmt
.Lps_not_nl:
    cmp w9, #TK_EOF
    b.eq .Lps_done
    cmp w9, #TK_IDENT
    b.eq .Lps_var
    cmp w9, #TK_PRINT
    b.eq .Lps_print
    cmp w9, #TK_SHOW
    b.eq .Lps_show
    SYNERR s_exp_stmt

.Lps_var:
    str w20, [x21, #S_TOK]
    add x20, x20, #1
    CUR
    cmp w9, #TK_DOT
    b.eq .Lps_decl
    cmp w9, #TK_EQ
    b.eq .Lps_assign
    SYNERR s_exp_after_n
.Lps_decl:
    add x20, x20, #1
    CUR
    mov w10, #TY_INT
    cmp w9, #TK_KINT
    b.eq .Lps_have_type
    mov w10, #TY_STR
    cmp w9, #TK_KSTR
    b.eq .Lps_have_type
    mov w10, #TY_BOOL
    cmp w9, #TK_KBOOL
    b.eq .Lps_have_type
    cmp w9, #TK_IDENT
    b.eq .Lps_unknown_type
    SYNERR s_exp_type
.Lps_have_type:
    mov w11, #SK_DECL
    strh w11, [x21, #S_KIND]
    strh w10, [x21, #S_MODE]
    add x20, x20, #1
    CUR
    cmp w9, #TK_EQ
    b.eq .Lps_decl_eq
    SYNERR s_exp_eq_type
.Lps_decl_eq:
    add x20, x20, #1
    b .Lps_value_opt
.Lps_assign:
    mov w11, #SK_ASSIGN
    strh w11, [x21, #S_KIND]
    add x20, x20, #1
.Lps_value_opt:
    LDX x9, g_nroots
    str w9, [x21, #S_PARTS]
    str wzr, [x21, #S_NPARTS]
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_end_line
    cmp w9, #TK_EOF
    b.eq .Lps_end_line
    bl parse_value
    bl push_root
    mov w11, #1
    str w11, [x21, #S_NPARTS]
    b .Lps_end_line

.Lps_print:
    mov w11, #SK_OUT
    strh w11, [x21, #S_KIND]
    strh wzr, [x21, #S_MODE]
    str w20, [x21, #S_TOK]
    mov w11, #-1
    str w11, [x21, #S_MODETOK]
    add x20, x20, #1
    CUR
    cmp w9, #TK_DOT
    b.ne .Lps_print_shr
    add x20, x20, #1
    CUR
    cmp w9, #TK_IDENT
    b.eq .Lps_print_mode
    SYNERR s_exp_mode
.Lps_print_mode:
    str w20, [x21, #S_MODETOK]
    add x20, x20, #1
    CUR
.Lps_print_shr:
    cmp w9, #TK_SHR
    b.eq .Lps_out_body
    SYNERR s_exp_shr_p

.Lps_show:
    mov w11, #SK_OUT
    strh w11, [x21, #S_KIND]
    mov w11, #1
    strh w11, [x21, #S_MODE]
    str w20, [x21, #S_TOK]
    mov w11, #-1
    str w11, [x21, #S_MODETOK]
    add x20, x20, #1
    CUR
    cmp w9, #TK_SHR
    b.eq .Lps_out_body
    SYNERR s_exp_shr_s

.Lps_out_body:
    add x20, x20, #1
    LDX x9, g_nroots
    str w9, [x21, #S_PARTS]
    mov x23, x9
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_out_empty
    cmp w9, #TK_EOF
    b.ne .Lps_out_part
.Lps_out_empty:
    SYNERR s_exp_out
.Lps_out_part:
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_out_done
    cmp w9, #TK_EOF
    b.eq .Lps_out_done
    cmp w9, #TK_STR
    b.ne .Lps_out_not_str
    bl parse_string
    bl push_root
    b .Lps_out_part
.Lps_out_not_str:
    cmp w9, #TK_LBRACE
    b.ne .Lps_out_bare
    add x20, x20, #1
    bl parse_value
    mov w25, w0
    CUR
    cmp w9, #TK_RBRACE
    b.eq .Lps_out_rbrace
    SYNERR s_exp_rbrace
.Lps_out_rbrace:
    add x20, x20, #1
    mov w0, w25
    bl push_root
    b .Lps_out_part
.Lps_out_bare:
    cmp w9, #TK_INT
    b.eq .Lps_bare
    cmp w9, #TK_MINUS
    b.eq .Lps_bare
    cmp w9, #TK_TRUE
    b.eq .Lps_bare
    cmp w9, #TK_FALSE
    b.eq .Lps_bare
    cmp w9, #TK_NULL
    b.eq .Lps_bare
    cmp w9, #TK_IDENT
    b.eq .Lps_bare
    cmp w9, #TK_LPAREN
    b.eq .Lps_bare
    cmp w9, #TK_FNUM
    b.eq .Lps_bare
    SYNERR s_exp_eol
.Lps_bare:
    LDX x9, g_nroots
    cmp x9, x23
    b.eq .Lps_bare_first
    SYNERR s_wrap
.Lps_bare_first:
    mov x24, x20
    bl parse_value
    bl push_root
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_out_done
    cmp w9, #TK_EOF
    b.eq .Lps_out_done
    mov x20, x24
    SYNERR s_wrap
.Lps_out_done:
    LDX x9, g_nroots
    sub x11, x9, x23
    str w11, [x21, #S_NPARTS]

.Lps_end_line:
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_line_ok
    cmp w9, #TK_EOF
    b.eq .Lps_line_ok
    SYNERR s_exp_eol
.Lps_line_ok:
    add x21, x21, #32
    b .Lps_stmt

.Lps_unknown_type:
    mov w27, w20
    bl msg_reset
    LA x0, s_unk_type1
    bl msg_addz
    mov w0, w27
    bl msg_tok
    LA x0, s_unk_type2
    bl msg_addz
    LA x0, s_syntax
    mov w1, w27
    bl diag_error_tok

.Lps_done:
    LDX x9, g_stmts
    sub x9, x21, x9
    lsr x9, x9, #5
    STX x9, g_nstmt
    STX x22, g_nparts
    ENDF

push_root:
    LDX x9, g_nroots
    LDX x10, g_roots
    str w0, [x10, x9, lsl #2]
    add x9, x9, #1
    STX x9, g_nroots
    ret

new_node:
    LDX x10, g_parts
    add x10, x10, x22, lsl #4
    stp xzr, xzr, [x10]
    strb w0, [x10, #V_KIND]
    str w1, [x10, #V_TOK]
    mov w0, w22
    add x22, x22, #1
    ret

new_op:
    mov w4, w0
    mov w6, w1
    mov x5, x30
    mov w0, #VK_EXPR
    mov w1, w3
    bl new_node
    mov x30, x5
    strb w2, [x10, #V_NEG]
    str w4, [x10, #V_DATA]
    str w6, [x10, #V_DATA_HI]
    ret

parse_value:
    stp x29, x30, [sp, #-32]!
    stp x22, x20, [sp, #16]
    STX xzr, pr_depth
    bl parse_expr
    ldp x9, x10, [sp, #16]
    sub x11, x22, x9
    cmp x11, #MAX_NODES
    b.hi .Lpv_too_long
    ldp x29, x30, [sp], #32
    ret
.Lpv_too_long:
    mov x20, x10
    SYNERR s_too_long

parse_expr:
    stp x29, x30, [sp, #-48]!
    stp x25, x26, [sp, #16]
    str x27, [sp, #32]
    bl parse_term
    mov w25, w0
.Lpe_loop:
    CUR
    mov w26, #OP_ADD
    cmp w9, #TK_PLUS
    b.eq .Lpe_op
    mov w26, #OP_SUB
    cmp w9, #TK_MINUS
    b.eq .Lpe_op
    mov w0, w25
    ldr x27, [sp, #32]
    ldp x25, x26, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
.Lpe_op:
    mov w27, w20
    add x20, x20, #1
    bl parse_term
    mov w1, w0
    mov w0, w25
    mov w2, w26
    mov w3, w27
    bl new_op
    mov w25, w0
    b .Lpe_loop

parse_term:
    stp x29, x30, [sp, #-48]!
    stp x25, x26, [sp, #16]
    str x27, [sp, #32]
    bl parse_factor
    mov w25, w0
.Lpt_loop:
    CUR
    mov w26, #OP_MUL
    cmp w9, #TK_STAR
    b.eq .Lpt_op
    mov w26, #OP_DIV
    cmp w9, #TK_SLASH
    b.eq .Lpt_op
    mov w26, #OP_MOD
    cmp w9, #TK_PERCENT
    b.eq .Lpt_op
    mov w0, w25
    ldr x27, [sp, #32]
    ldp x25, x26, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
.Lpt_op:
    mov w27, w20
    add x20, x20, #1
    bl parse_factor
    mov w1, w0
    mov w0, w25
    mov w2, w26
    mov w3, w27
    bl new_op
    mov w25, w0
    b .Lpt_loop

parse_factor:
    stp x29, x30, [sp, #-32]!
    str x25, [sp, #16]
    LDX x9, pr_depth
    add x9, x9, #1
    STX x9, pr_depth
    cmp x9, #MAX_DEPTH
    b.hi .Lpf_too_deep
    CUR
    cmp w9, #TK_MINUS
    b.eq .Lpf_minus
    cmp w9, #TK_LPAREN
    b.eq .Lpf_paren
    bl parse_primary
    b .Lpf_ret
.Lpf_minus:
    add x10, x20, #1
    add x10, x19, x10, lsl #4
    ldrh w10, [x10]
    cmp w10, #TK_INT
    b.ne .Lpf_negate
    add x20, x20, #1
    mov w0, #VK_INT
    mov w1, w20
    bl new_node
    mov w11, #1
    strb w11, [x10, #V_NEG]
    add x20, x20, #1
    b .Lpf_ret
.Lpf_negate:
    mov w25, w20
    add x20, x20, #1
    bl parse_factor
    mov w1, #-1
    mov w2, #OP_NEG
    mov w3, w25
    bl new_op
    b .Lpf_ret
.Lpf_paren:
    add x20, x20, #1
    bl parse_expr
    mov w25, w0
    CUR
    cmp w9, #TK_RPAREN
    b.eq .Lpf_paren_ok
    SYNERR s_exp_rparen
.Lpf_paren_ok:
    add x20, x20, #1
    mov w0, w25
.Lpf_ret:
    LDX x9, pr_depth
    sub x9, x9, #1
    STX x9, pr_depth
    ldr x25, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
.Lpf_too_deep:
    SYNERR s_too_deep

parse_primary:
    mov x15, x30
    CUR
    mov w0, #VK_INT
    cmp w9, #TK_INT
    b.eq .Lpp_leaf
    mov w0, #VK_STR
    cmp w9, #TK_STR
    b.eq .Lpp_leaf
    mov w0, #VK_NULL
    cmp w9, #TK_NULL
    b.eq .Lpp_leaf
    mov w0, #VK_VAR
    cmp w9, #TK_IDENT
    b.eq .Lpp_leaf
    mov w0, #VK_BOOL
    cmp w9, #TK_FALSE
    b.eq .Lpp_leaf
    cmp w9, #TK_TRUE
    b.eq .Lpp_true
    cmp w9, #TK_FNUM
    b.eq .Lpp_fnum
    SYNERR s_exp_value
.Lpp_true:
    mov w1, w20
    bl new_node
    mov w11, #1
    str w11, [x10, #V_DATA]
    add x20, x20, #1
    mov x30, x15
    ret
.Lpp_leaf:
    mov w1, w20
    bl new_node
    add x20, x20, #1
    mov x30, x15
    ret
.Lpp_fnum:
    SYNERR s_no_float

parse_string:
    mov x15, x30
    mov w0, #VK_STR
    mov w1, w20
    bl new_node
    add x20, x20, #1
    mov x30, x15
    ret

