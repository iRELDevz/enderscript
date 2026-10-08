#include "defs.h"

    RODATA
s_lexical:   .asciz "lexical"
s_unexp_ch:  .asciz "unexpected character '"
s_unexp_by:  .asciz "unexpected byte 0x"
s_unterm:    .asciz "unterminated string"
s_unk_esc:   .asciz "unknown escape '\\"
s_name_long: .asciz "variable name is longer than 64 characters"
s_quote:     .asciz "'"
hex_digits:  .ascii "0123456789ABCDEF"
keywords:
    .byte 5, TK_PRINT
    .ascii "print"
    .byte 4, TK_SHOW
    .ascii "show"
    .byte 3, TK_KINT
    .ascii "int"
    .byte 3, TK_KSTR
    .ascii "str"
    .byte 4, TK_KBOOL
    .ascii "bool"
    .byte 4, TK_TRUE
    .ascii "true"
    .byte 5, TK_FALSE
    .ascii "false"
    .byte 4, TK_NULL
    .ascii "null"
    .byte 0
escape_chars: .asciz "nt0r\\\"'`"

    .text

.macro EMIT_TOK
    strh w9, [x24, #T_KIND]
    sub x12, x10, x22
    add x12, x12, #1
    mov x13, #65535
    cmp x12, x13
    csel x12, x12, x13, ls
    strh w12, [x24, #T_COL]
    str w23, [x24, #T_LINE]
    sub x12, x10, x19
    str w12, [x24, #T_OFF]
    str w11, [x24, #T_LEN]
    add x24, x24, #16
.endm

FUNC lex
    LDX x0, g_src_len
    add x0, x0, #2
    lsl x0, x0, #4
    bl mem_alloc
    STX x0, g_tokens
    mov x24, x0
    LDX x19, g_src
    mov x20, x19
    LDX x9, g_src_len
    add x21, x19, x9
    mov x22, x19
    mov w23, #1

.Llx_next:
    cmp x20, x21
    b.hs .Llx_eof
    ldrb w0, [x20]
    cmp w0, #' '
    b.eq .Llx_skip
    cmp w0, #9
    b.eq .Llx_skip
    cmp w0, #13
    b.eq .Llx_skip
    cmp w0, #10
    b.eq .Llx_newline
    cmp w0, #'/'
    b.eq .Llx_slash
    cmp w0, #'_'
    b.eq .Llx_ident
    orr w1, w0, #0x20
    cmp w1, #'a'
    b.lo .Llx_not_alpha
    cmp w1, #'z'
    b.ls .Llx_ident
.Llx_not_alpha:
    cmp w0, #'0'
    b.lo .Llx_not_digit
    cmp w0, #'9'
    b.ls .Llx_number
.Llx_not_digit:
    cmp w0, #'"'
    b.eq .Llx_string
    cmp w0, #39
    b.eq .Llx_string
    cmp w0, #96
    b.eq .Llx_string
    mov w9, #TK_DOT
    cmp w0, #'.'
    b.eq .Llx_single
    mov w9, #TK_EQ
    cmp w0, #'='
    b.eq .Llx_single
    mov w9, #TK_MINUS
    cmp w0, #'-'
    b.eq .Llx_single
    mov w9, #TK_PLUS
    cmp w0, #'+'
    b.eq .Llx_single
    mov w9, #TK_STAR
    cmp w0, #'*'
    b.eq .Llx_single
    mov w9, #TK_PERCENT
    cmp w0, #'%'
    b.eq .Llx_single
    mov w9, #TK_LPAREN
    cmp w0, #'('
    b.eq .Llx_single
    mov w9, #TK_RPAREN
    cmp w0, #')'
    b.eq .Llx_single
    mov w9, #TK_LBRACE
    cmp w0, #'{'
    b.eq .Llx_single
    mov w9, #TK_RBRACE
    cmp w0, #'}'
    b.eq .Llx_single
    cmp w0, #'>'
    b.ne .Llx_unexpected
    add x1, x20, #1
    cmp x1, x21
    b.hs .Llx_unexpected
    ldrb w1, [x1]
    cmp w1, #'>'
    b.ne .Llx_unexpected
    mov w9, #TK_SHR
    mov x10, x20
    mov w11, #2
    EMIT_TOK
    add x20, x20, #2
    b .Llx_next

.Llx_skip:
    add x20, x20, #1
    b .Llx_next

.Llx_single:
    mov x10, x20
    mov w11, #1
    EMIT_TOK
    add x20, x20, #1
    b .Llx_next

.Llx_newline:
    mov w9, #TK_NL
    mov x10, x20
    mov w11, #1
    EMIT_TOK
    add x20, x20, #1
    add w23, w23, #1
    mov x22, x20
    b .Llx_next

.Llx_slash:
    add x1, x20, #1
    cmp x1, x21
    b.hs .Llx_slash_one
    ldrb w1, [x1]
    cmp w1, #'/'
    b.eq .Llx_comment
.Llx_slash_one:
    mov w9, #TK_SLASH
    mov x10, x20
    mov w11, #1
    EMIT_TOK
    add x20, x20, #1
    b .Llx_next
.Llx_comment:
    cmp x20, x21
    b.hs .Llx_next
    ldrb w1, [x20]
    cmp w1, #10
    b.eq .Llx_next
    add x20, x20, #1
    b .Llx_comment

.Llx_ident:
    mov x25, x20
.Llx_ident_loop:
    add x20, x20, #1
    cmp x20, x21
    b.hs .Llx_ident_end
    ldrb w0, [x20]
    cmp w0, #'_'
    b.eq .Llx_ident_loop
    cmp w0, #'0'
    b.lo .Llx_ident_alpha
    cmp w0, #'9'
    b.ls .Llx_ident_loop
.Llx_ident_alpha:
    orr w0, w0, #0x20
    cmp w0, #'a'
    b.lo .Llx_ident_end
    cmp w0, #'z'
    b.ls .Llx_ident_loop
.Llx_ident_end:
    sub x11, x20, x25
    cmp x11, #64
    b.hi .Llx_name_long
    LA x1, keywords
.Llx_kw_loop:
    ldrb w2, [x1]
    cbz w2, .Llx_kw_none
    cmp w2, w11
    b.ne .Llx_kw_next
    mov x3, #0
.Llx_kw_cmp:
    add x4, x1, #2
    ldrb w5, [x4, x3]
    ldrb w6, [x25, x3]
    cmp w5, w6
    b.ne .Llx_kw_next
    add x3, x3, #1
    cmp x3, x11
    b.lo .Llx_kw_cmp
    ldrb w9, [x1, #1]
    b .Llx_kw_emit
.Llx_kw_next:
    add x1, x1, #2
    add x1, x1, x2
    b .Llx_kw_loop
.Llx_kw_none:
    mov w9, #TK_IDENT
.Llx_kw_emit:
    mov x10, x25
    EMIT_TOK
    b .Llx_next

.Llx_number:
    mov x25, x20
.Llx_num_loop:
    add x20, x20, #1
    cmp x20, x21
    b.hs .Llx_num_end
    ldrb w0, [x20]
    cmp w0, #'0'
    b.lo .Llx_num_end
    cmp w0, #'9'
    b.ls .Llx_num_loop
.Llx_num_end:
    mov w9, #TK_INT
    cmp x20, x21
    b.hs .Llx_num_emit
    ldrb w0, [x20]
    cmp w0, #'.'
    b.ne .Llx_num_emit
    add x1, x20, #1
    cmp x1, x21
    b.hs .Llx_num_emit
    ldrb w0, [x1]
    cmp w0, #'0'
    b.lo .Llx_num_emit
    cmp w0, #'9'
    b.hi .Llx_num_emit
    add x20, x20, #1
.Llx_num_frac:
    add x20, x20, #1
    cmp x20, x21
    b.hs .Llx_num_float
    ldrb w0, [x20]
    cmp w0, #'0'
    b.lo .Llx_num_float
    cmp w0, #'9'
    b.ls .Llx_num_frac
.Llx_num_float:
    mov w9, #TK_FNUM
.Llx_num_emit:
    mov x10, x25
    sub x11, x20, x25
    EMIT_TOK
    b .Llx_next

.Llx_string:
    mov x25, x20
    mov w26, w0
    add x20, x20, #1
.Llx_str_loop:
    cmp x20, x21
    b.hs .Llx_unterminated
    ldrb w0, [x20]
    cmp w0, #10
    b.eq .Llx_unterminated
    cmp w0, w26
    b.eq .Llx_str_end
    cmp w0, #'\\'
    b.eq .Llx_str_escape
    add x20, x20, #1
    b .Llx_str_loop
.Llx_str_escape:
    add x1, x20, #1
    cmp x1, x21
    b.hs .Llx_unterminated
    ldrb w0, [x1]
    cmp w0, #10
    b.eq .Llx_unterminated
    LA x2, escape_chars
.Llx_esc_find:
    ldrb w3, [x2], #1
    cbz w3, .Llx_bad_escape
    cmp w3, w0
    b.ne .Llx_esc_find
    add x20, x20, #2
    b .Llx_str_loop
.Llx_str_end:
    add x20, x20, #1
    mov w9, #TK_STR
    mov x10, x25
    sub x11, x20, x25
    EMIT_TOK
    b .Llx_next

.Llx_eof:
    mov w9, #TK_EOF
    mov x10, x20
    mov w11, #0
    EMIT_TOK
    LDX x9, g_tokens
    sub x9, x24, x9
    lsr x9, x9, #4
    STX x9, g_ntok
    ENDF

.Llx_unexpected:
    mov x27, x20
    bl msg_reset
    ldrb w0, [x27]
    cmp w0, #0x21
    b.lo .Llx_unexp_byte
    cmp w0, #0x7E
    b.hi .Llx_unexp_byte
    LA x0, s_unexp_ch
    bl msg_addz
    ldrb w0, [x27]
    bl msg_addc
    LA x0, s_quote
    bl msg_addz
    b .Llx_error
.Llx_unexp_byte:
    LA x0, s_unexp_by
    bl msg_addz
    ldrb w0, [x27]
    lsr w0, w0, #4
    LA x9, hex_digits
    ldrb w0, [x9, x0]
    bl msg_addc
    ldrb w0, [x27]
    and w0, w0, #15
    LA x9, hex_digits
    ldrb w0, [x9, x0]
    bl msg_addc
    b .Llx_error

.Llx_unterminated:
    mov x27, x25
    bl msg_reset
    LA x0, s_unterm
    bl msg_addz
    b .Llx_error

.Llx_bad_escape:
    mov x27, x20
    bl msg_reset
    LA x0, s_unk_esc
    bl msg_addz
    ldrb w0, [x27, #1]
    bl msg_addc
    LA x0, s_quote
    bl msg_addz
    b .Llx_error

.Llx_name_long:
    mov x27, x25
    bl msg_reset
    LA x0, s_name_long
    bl msg_addz

.Llx_error:
    sub x2, x27, x22
    add x2, x2, #1
    mov w1, w23
    LA x0, s_lexical
    bl diag_error_at
