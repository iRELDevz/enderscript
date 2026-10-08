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
s_wrap:        .asciz "values next to text must be wrapped in '{ }'"
s_exp_value:   .asciz "expected value"
s_exp_number:  .asciz "expected number after '-'"

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
    str w22, [x21, #S_PARTS]
    str wzr, [x21, #S_NPARTS]
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_end_line
    cmp w9, #TK_EOF
    b.eq .Lps_end_line
    bl parse_value
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
    str w22, [x21, #S_PARTS]
    mov x23, x22
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
    bl parse_value
    b .Lps_out_part
.Lps_out_not_str:
    cmp w9, #TK_LBRACE
    b.ne .Lps_out_bare
    add x20, x20, #1
    bl parse_value
    CUR
    cmp w9, #TK_RBRACE
    b.eq .Lps_out_rbrace
    SYNERR s_exp_rbrace
.Lps_out_rbrace:
    add x20, x20, #1
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
    SYNERR s_exp_eol
.Lps_bare:
    cmp x22, x23
    b.eq .Lps_bare_first
    SYNERR s_wrap
.Lps_bare_first:
    mov x24, x20
    bl parse_value
    CUR
    cmp w9, #TK_NL
    b.eq .Lps_out_done
    cmp w9, #TK_EOF
    b.eq .Lps_out_done
    mov x20, x24
    SYNERR s_wrap
.Lps_out_done:
    sub x11, x22, x23
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

parse_value:
    LDX x10, g_parts
    add x10, x10, x22, lsl #4
    stp xzr, xzr, [x10]
    CUR
    mov w11, #VK_INT
    cmp w9, #TK_INT
    b.eq .Lpv_simple
    mov w11, #VK_STR
    cmp w9, #TK_STR
    b.eq .Lpv_simple
    mov w11, #VK_NULL
    cmp w9, #TK_NULL
    b.eq .Lpv_simple
    mov w11, #VK_VAR
    cmp w9, #TK_IDENT
    b.eq .Lpv_simple
    cmp w9, #TK_TRUE
    b.eq .Lpv_true
    cmp w9, #TK_FALSE
    b.eq .Lpv_false
    cmp w9, #TK_MINUS
    b.eq .Lpv_minus
    SYNERR s_exp_value
.Lpv_true:
    mov w12, #1
    str w12, [x10, #V_DATA]
.Lpv_false:
    mov w11, #VK_BOOL
    b .Lpv_simple
.Lpv_minus:
    add x20, x20, #1
    CUR
    cmp w9, #TK_INT
    b.eq .Lpv_neg_ok
    SYNERR s_exp_number
.Lpv_neg_ok:
    mov w12, #1
    strb w12, [x10, #V_NEG]
    mov w11, #VK_INT
.Lpv_simple:
    strb w11, [x10, #V_KIND]
    str w20, [x10, #V_TOK]
    add x20, x20, #1
    add x22, x22, #1
    ret
