#include "defs.h"


    RODATA
s_lexical:
    .ascii "lexical"
    .byte 0
s_unexp_ch:
    .ascii "unexpected character '"
    .byte 0
s_unexp_by:
    .ascii "unexpected byte 0x"
    .byte 0
s_unterm:
    .ascii "unterminated string"
    .byte 0
s_unk_esc:
    .ascii "unknown escape '\\"
    .byte 0
s_name_long:
    .ascii "variable name is longer than 64 characters"
    .byte 0
s_quote:
    .ascii "'"
    .byte 0
s_mixed:
    .ascii "inconsistent use of tabs and spaces in indentation"
    .byte 0
s_unindent:
    .ascii "unindent does not match any outer indentation level"
    .byte 0
s_too_nest:
    .ascii "blocks are nested more than 100 levels deep"
    .byte 0
hex_digits:
    .ascii "0123456789ABCDEF"

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
    .byte 2, TK_IF
    .ascii "if"
    .byte 2, TK_IS
    .ascii "is"
    .byte 5, TK_ISNOT
    .ascii "isnot"
    .byte 2, TK_OR
    .ascii "or"
    .byte 3, TK_AND
    .ascii "and"
    .byte 3, TK_FOR
    .ascii "for"
    .byte 2, TK_IN
    .ascii "in"
    .byte 5, TK_RANGE
    .ascii "range"
    .byte 5, TK_LOOPS
    .ascii "loops"
    .byte 4, TK_ELSE
    .ascii "else"
    .byte 4, TK_ELIF
    .ascii "elif"
    .byte 5, TK_BREAK
    .ascii "break"
    .byte 8, TK_CONTINUE
    .ascii "continue"
    .byte 5, TK_INPUT
    .ascii "input"
    .byte 0

    .globl escape_chars
escape_chars:
    .ascii "nt0r\\"
    .byte 34, 39, 96, 0

    .bss
    .p2align 3
lx_depth:
    .zero (1) * 8
lx_paren:
    .zero (1) * 8
lx_gn:
    .zero (1) * 8
lx_silent:
    .zero (1) * 8
lx_gstack:
    .zero (2 * (MAX_BLOCKS + 1)) * 8
lx_ind_len:
    .zero (MAX_BLOCKS + 1) * 8
lx_ind_ptr:
    .zero (MAX_BLOCKS + 1) * 8

    .text


FUNC lex
    adrp x8, g_src_len
    add x8, x8, :lo12:g_src_len
    ldr x16, [x8]
    mov x10, x16
    lsl x17, x10, #1
    mov x10, x17
    adds x10, x10, #256
    lsl x17, x10, #4
    mov x10, x17
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    str x9, [x8]
    mov x17, #0
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x17, [x8]
    mov x17, #0
    adrp x8, lx_ind_len
    add x8, x8, :lo12:lx_ind_len
    str x17, [x8]
    mov x17, #0
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    str x17, [x8]
    mov x17, #0
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    str x17, [x8]
    mov x17, #0
    adrp x8, lx_silent
    add x8, x8, :lo12:lx_silent
    str x17, [x8]
    mov x21, x9
    eor w26, w26, w26
    adrp x8, g_src
    add x8, x8, :lo12:g_src
    ldr x16, [x8]
    mov x19, x16
    mov x20, x19
    mov x23, x19
    adrp x8, g_src_len
    add x8, x8, :lo12:g_src_len
    ldr x16, [x8]
    adds x23, x23, x16
    mov x24, x19
    mov w25, #1
    b .Llex_line_start

.Llex_next:
    cmp x20, x23
    b.hs .Llex_eof
    ldurb w9, [x20, #0]
    and w16, w9, #0xff
    cmp w16, #32
    b.eq .Llex_skip
    and w16, w9, #0xff
    cmp w16, #9
    b.eq .Llex_skip
    and w16, w9, #0xff
    cmp w16, #13
    b.eq .Llex_skip
    and w16, w9, #0xff
    cmp w16, #10
    b.eq .Llex_newline
    and w16, w9, #0xff
    cmp w16, #47
    b.eq .Llex_slash
    and w16, w9, #0xff
    cmp w16, #95
    b.eq .Llex_ident
    mov w10, w9
    mov w16, #32
    orr w10, w10, w16
    cmp w10, #97
    b.lo .Llex_not_alpha
    cmp w10, #122
    b.ls .Llex_ident
.Llex_not_alpha:
    and w16, w9, #0xff
    cmp w16, #48
    b.lo .Llex_not_digit
    and w16, w9, #0xff
    cmp w16, #57
    b.ls .Llex_number
.Llex_not_digit:
    and w16, w9, #0xff
    cmp w16, #34
    b.eq .Llex_string
    and w16, w9, #0xff
    cmp w16, #39
    b.eq .Llex_string
    and w16, w9, #0xff
    cmp w16, #96
    b.eq .Llex_string
    mov w10, #5
    and w16, w9, #0xff
    cmp w16, #46
    b.eq .Llex_single
    mov w10, #6
    and w16, w9, #0xff
    cmp w16, #61
    b.ne .Llex_not_eq
    add x11, x20, #1
    cmp x11, x23
    b.hs .Llex_single
    ldurb w16, [x11, #0]
    cmp w16, #61
    b.ne .Llex_single
    mov w10, #27
    mov x12, x20
    mov w11, #2
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m1_col_ok
    mov w9, #65535
.Llex_m1_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adds x20, x20, #2
    b .Llex_next
.Llex_not_eq:
    mov w10, #7
    and w16, w9, #0xff
    cmp w16, #45
    b.eq .Llex_single
    mov w10, #19
    and w16, w9, #0xff
    cmp w16, #43
    b.eq .Llex_single
    mov w10, #20
    and w16, w9, #0xff
    cmp w16, #42
    b.eq .Llex_single
    mov w10, #22
    and w16, w9, #0xff
    cmp w16, #37
    b.eq .Llex_single
    mov w10, #23
    and w16, w9, #0xff
    cmp w16, #40
    b.eq .Llex_lparen
    mov w10, #24
    and w16, w9, #0xff
    cmp w16, #41
    b.eq .Llex_rparen
    mov w10, #44
    and w16, w9, #0xff
    cmp w16, #44
    b.eq .Llex_single
    mov w10, #9
    and w16, w9, #0xff
    cmp w16, #123
    b.eq .Llex_single
    mov w10, #10
    and w16, w9, #0xff
    cmp w16, #125
    b.eq .Llex_single
    mov w10, #32
    and w16, w9, #0xff
    cmp w16, #58
    b.eq .Llex_single
    and w16, w9, #0xff
    cmp w16, #33
    b.eq .Llex_bang
    mov w10, #30
    and w16, w9, #0xff
    cmp w16, #60
    b.ne .Llex_not_lt
    mov w11, #41
    b .Llex_maybe_eq
.Llex_not_lt:
    and w16, w9, #0xff
    cmp w16, #62
    b.ne .Llex_unexpected
    mov w10, #31
    add x11, x20, #1
    cmp x11, x23
    b.hs .Llex_single
    ldurb w16, [x11, #0]
    cmp w16, #61
    b.ne .Llex_not_ge
    mov w10, #42
    b .Llex_two
.Llex_not_ge:
    ldurb w16, [x11, #0]
    cmp w16, #62
    b.ne .Llex_single
    mov w10, #8
    mov x12, x20
    mov w11, #2
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m2_col_ok
    mov w9, #65535
.Llex_m2_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adds x20, x20, #2
    b .Llex_next

.Llex_skip:
    adds x20, x20, #1
    b .Llex_next

.Llex_lparen:
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    str x17, [x8]
    b .Llex_single

.Llex_rparen:
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x16, [x8]
    cmp x16, #0
    b.eq .Llex_single
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    str x17, [x8]
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x16, [x8]
    mov x9, x16
    tst x9, x9
    b.eq .Llex_single
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, lx_gstack
    add x8, x8, :lo12:lx_gstack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x9, lsl #0
    sub x8, x8, #16
    ldr x16, [x8]
    mov x11, x16
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x16, [x8]
    cmp x16, x11
    b.hs .Llex_single
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    str x17, [x8]
    b .Llex_single

.Llex_bang:
    add x11, x20, #1
    cmp x11, x23
    b.hs .Llex_unexpected
    ldurb w16, [x11, #0]
    cmp w16, #61
    b.ne .Llex_unexpected
    mov w10, #28
    b .Llex_two

.Llex_maybe_eq:
    add x12, x20, #1
    cmp x12, x23
    b.hs .Llex_single
    ldurb w16, [x12, #0]
    cmp w16, #61
    b.ne .Llex_single
    mov w10, w11

.Llex_two:
    mov x12, x20
    mov w11, #2
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m3_col_ok
    mov w9, #65535
.Llex_m3_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adds x20, x20, #2
    b .Llex_next

.Llex_single:
    mov x12, x20
    mov w11, #1
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m4_col_ok
    mov w9, #65535
.Llex_m4_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adds x20, x20, #1
    b .Llex_next

.Llex_newline:
    mov w10, #1
    mov x12, x20
    cmp x12, x24
    b.ls .Llex_nl_emit
    ldurb w16, [x12, #-1]
    cmp w16, #13
    b.ne .Llex_nl_emit
    subs x12, x12, #1
.Llex_nl_emit:
    mov w11, #1
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m5_col_ok
    mov w9, #65535
.Llex_m5_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    eor w11, w11, w11
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x16, [x8]
    mov x9, x16
    tst x9, x9
    b.eq .Llex_group_top
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, lx_gstack
    add x8, x8, :lo12:lx_gstack
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    sub x8, x8, #16
    ldr x16, [x8]
    mov x11, x16
.Llex_group_top:
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x16, [x8]
    cmp x16, x11
    b.ls .Llex_group_done
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x16, [x8]
    mov x9, x16
    cmp x9, #100
    b.hs .Llex_group_done
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, lx_gstack
    add x8, x8, :lo12:lx_gstack
    add x10, x8, #0
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x16, [x8]
    mov x11, x16
    mov x8, x10
    add x8, x8, x9, lsl #0
    str x11, [x8]
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    mov x11, x16
    mov x8, x10
    add x8, x8, x9, lsl #0
    add x8, x8, #8
    str x11, [x8]
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    str x17, [x8]
    mov x17, #1
    adrp x8, lx_silent
    add x8, x8, :lo12:lx_silent
    str x17, [x8]
.Llex_group_done:
    adds x20, x20, #1
    adds w25, w25, #1
    mov x24, x20
    b .Llex_line_start

.Llex_slash:
    add x11, x20, #1
    cmp x11, x23
    b.hs .Llex_slash_one
    ldurb w16, [x11, #0]
    cmp w16, #47
    b.eq .Llex_comment
.Llex_slash_one:
    mov w10, #21
    mov x12, x20
    mov w11, #1
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m6_col_ok
    mov w9, #65535
.Llex_m6_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adds x20, x20, #1
    b .Llex_next
.Llex_comment:
    cmp x20, x23
    b.hs .Llex_next
    ldurb w16, [x20, #0]
    cmp w16, #10
    b.eq .Llex_next
    adds x20, x20, #1
    b .Llex_comment

.Llex_ident:
    mov x12, x20
.Llex_ident_loop:
    adds x20, x20, #1
    cmp x20, x23
    b.hs .Llex_ident_end
    ldurb w9, [x20, #0]
    and w16, w9, #0xff
    cmp w16, #95
    b.eq .Llex_ident_loop
    and w16, w9, #0xff
    cmp w16, #48
    b.lo .Llex_ident_alpha
    and w16, w9, #0xff
    cmp w16, #57
    b.ls .Llex_ident_loop
.Llex_ident_alpha:
    and w17, w9, #0xff
    mov w16, #32
    orr w17, w17, w16
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    cmp w16, #97
    b.lo .Llex_ident_end
    and w16, w9, #0xff
    cmp w16, #122
    b.ls .Llex_ident_loop
.Llex_ident_end:
    mov x11, x20
    subs x11, x11, x12
    cmp x11, #64
    b.hi .Llex_name_long
    adrp x8, keywords
    add x8, x8, :lo12:keywords
    add x13, x8, #0
.Llex_kw_loop:
    ldurb w9, [x13, #0]
    tst w9, w9
    b.eq .Llex_kw_none
    cmp w9, w11
    b.ne .Llex_kw_next
    eor w14, w14, w14
.Llex_kw_cmp:
    mov x8, x13
    add x8, x8, x14, lsl #0
    add x8, x8, #2
    ldrb w17, [x8]
    bfi x15, x17, #0, #8
    and w16, w15, #0xff
    mov x8, x12
    add x8, x8, x14, lsl #0
    ldrb w17, [x8]
    cmp w16, w17
    b.ne .Llex_kw_next
    adds w14, w14, #1
    cmp w14, w11
    b.lo .Llex_kw_cmp
    ldurb w10, [x13, #1]
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m7_col_ok
    mov w9, #65535
.Llex_m7_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_next
.Llex_kw_next:
    mov x8, x13
    add x8, x8, x9, lsl #0
    add x8, x8, #2
    add x13, x8, #0
    b .Llex_kw_loop
.Llex_kw_none:
    mov w10, #2
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m8_col_ok
    mov w9, #65535
.Llex_m8_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_next

.Llex_number:
    mov x12, x20
.Llex_num_loop:
    adds x20, x20, #1
    cmp x20, x23
    b.hs .Llex_num_end
    ldurb w16, [x20, #0]
    cmp w16, #48
    b.lo .Llex_num_end
    ldurb w16, [x20, #0]
    cmp w16, #57
    b.ls .Llex_num_loop
.Llex_num_end:
    ldurb w16, [x20, #0]
    cmp w16, #46
    b.ne .Llex_num_int
    add x11, x20, #1
    cmp x11, x23
    b.hs .Llex_num_int
    ldurb w16, [x11, #0]
    cmp w16, #48
    b.lo .Llex_num_int
    ldurb w16, [x11, #0]
    cmp w16, #57
    b.hi .Llex_num_int
    adds x20, x20, #1
.Llex_num_frac:
    adds x20, x20, #1
    cmp x20, x23
    b.hs .Llex_num_float
    ldurb w16, [x20, #0]
    cmp w16, #48
    b.lo .Llex_num_float
    ldurb w16, [x20, #0]
    cmp w16, #57
    b.ls .Llex_num_frac
.Llex_num_float:
    mov x11, x20
    subs x11, x11, x12
    mov w10, #25
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m9_col_ok
    mov w9, #65535
.Llex_m9_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_next
.Llex_num_int:
    mov x11, x20
    subs x11, x11, x12
    mov w10, #3
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m10_col_ok
    mov w9, #65535
.Llex_m10_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_next

.Llex_string:
    mov x12, x20
    and w17, w9, #0xff
    bfi x13, x17, #0, #8
    adds x20, x20, #1
.Llex_str_loop:
    cmp x20, x23
    b.hs .Llex_unterminated
    ldurb w17, [x20, #0]
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    cmp w16, #10
    b.eq .Llex_unterminated
    and w16, w9, #0xff
    and w17, w13, #0xff
    cmp w16, w17
    b.eq .Llex_str_end
    and w16, w9, #0xff
    cmp w16, #92
    b.eq .Llex_str_escape
    adds x20, x20, #1
    b .Llex_str_loop
.Llex_str_escape:
    add x11, x20, #1
    cmp x11, x23
    b.hs .Llex_unterminated
    ldurb w17, [x11, #0]
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    cmp w16, #10
    b.eq .Llex_unterminated
    adrp x8, escape_chars
    add x8, x8, :lo12:escape_chars
    add x14, x8, #0
.Llex_esc_find:
    ldurb w17, [x14, #0]
    bfi x15, x17, #0, #8
    and w16, w15, #0xff
    and w17, w15, #0xff
    tst w16, w17
    b.eq .Llex_bad_escape
    and w16, w15, #0xff
    and w17, w9, #0xff
    cmp w16, w17
    b.eq .Llex_esc_ok
    adds x14, x14, #1
    b .Llex_esc_find
.Llex_esc_ok:
    adds x20, x20, #2
    b .Llex_str_loop
.Llex_str_end:
    adds x20, x20, #1
    mov x11, x20
    subs x11, x11, x12
    mov w10, #4
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m11_col_ok
    mov w9, #65535
.Llex_m11_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_next

.Llex_eof:
    tst x26, x26
    b.eq .Llex_eof_dedent
    ldurh w16, [x21, #-16]
    cmp w16, #1
    b.eq .Llex_eof_dedent
    mov w10, #1
    mov x12, x20
    eor w11, w11, w11
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m12_col_ok
    mov w9, #65535
.Llex_m12_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
.Llex_eof_dedent:
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    cmp x16, #0
    b.eq .Llex_eof_tok
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x17, [x8]
    mov w10, #34
    mov x12, x20
    eor w11, w11, w11
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m13_col_ok
    mov w9, #65535
.Llex_m13_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_eof_dedent
.Llex_eof_tok:
    mov w10, #0
    mov x12, x20
    eor w11, w11, w11
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m14_col_ok
    mov w9, #65535
.Llex_m14_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adrp x8, g_ntok
    add x8, x8, :lo12:g_ntok
    str x26, [x8]
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

.Llex_line_start:
    mov x12, x20
.Llex_ls_scan:
    cmp x12, x23
    b.hs .Llex_next
    ldurb w17, [x12, #0]
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    cmp w16, #32
    b.eq .Llex_ls_ws
    and w16, w9, #0xff
    cmp w16, #9
    b.eq .Llex_ls_ws
    and w16, w9, #0xff
    cmp w16, #10
    b.eq .Llex_next
    and w16, w9, #0xff
    cmp w16, #13
    b.eq .Llex_next
    and w16, w9, #0xff
    cmp w16, #47
    b.ne .Llex_ls_line
    add x11, x12, #1
    cmp x11, x23
    b.hs .Llex_ls_line
    ldurb w16, [x11, #0]
    cmp w16, #47
    b.eq .Llex_next
    b .Llex_ls_line
.Llex_ls_ws:
    adds x12, x12, #1
    b .Llex_ls_scan
.Llex_ls_line:
    mov x13, x12
    subs x13, x13, x24
    adrp x8, lx_silent
    add x8, x8, :lo12:lx_silent
    ldr x16, [x8]
    cmp x16, #0
    b.eq .Llex_ls_close
    mov x17, #0
    adrp x8, lx_silent
    add x8, x8, :lo12:lx_silent
    str x17, [x8]
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    mov x9, x16
    cmp x9, #100
    b.hs .Llex_ls_too_deep
    adds x9, x9, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x9, [x8]
    adrp x8, lx_ind_len
    add x8, x8, :lo12:lx_ind_len
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    str x13, [x8]
    adrp x8, lx_ind_ptr
    add x8, x8, :lo12:lx_ind_ptr
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    str x24, [x8]
    b .Llex_next
.Llex_ls_close:
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x16, [x8]
    mov x9, x16
    tst x9, x9
    b.eq .Llex_ls_normal
    ldurb w16, [x12, #0]
    cmp w16, #41
    b.ne .Llex_ls_normal
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, lx_gstack
    add x8, x8, :lo12:lx_gstack
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #0
    sub x8, x8, #16
    ldr x16, [x8]
    mov x11, x16
    adrp x8, lx_paren
    add x8, x8, :lo12:lx_paren
    ldr x16, [x8]
    cmp x16, x11
    b.ne .Llex_ls_normal
    mov x8, x15
    add x8, x8, x9, lsl #0
    sub x8, x8, #8
    ldr x16, [x8]
    mov x14, x16
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    cmp x16, x14
    b.ls .Llex_ls_normal
    adds x14, x14, #1
.Llex_ls_close_pop:
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    cmp x16, x14
    b.ls .Llex_ls_close_silent
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x17, [x8]
    mov w10, #34
    eor w11, w11, w11
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m15_col_ok
    mov w9, #65535
.Llex_m15_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_ls_close_pop
.Llex_ls_close_silent:
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x17, [x8]
    b .Llex_next
.Llex_ls_normal:
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, lx_ind_len
    add x8, x8, :lo12:lx_ind_len
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    ldr x16, [x8]
    mov x14, x16
    cmp x13, x14
    b.eq .Llex_ls_same
    b.hi .Llex_ls_push
.Llex_ls_pop:
    adrp x8, lx_gn
    add x8, x8, :lo12:lx_gn
    ldr x16, [x8]
    mov x11, x16
    tst x11, x11
    b.eq .Llex_ls_pop_ok
    lsl x17, x11, #4
    mov x11, x17
    adrp x8, lx_gstack
    add x8, x8, :lo12:lx_gstack
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x11, lsl #0
    sub x8, x8, #8
    ldr x16, [x8]
    mov x11, x16
    adds x11, x11, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    cmp x16, x11
    b.hi .Llex_ls_pop_ok
    adrp x8, s_unindent
    add x8, x8, :lo12:s_unindent
    add x10, x8, #0
    b .Llex_indent_error
.Llex_ls_pop_ok:
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x17, [x8]
    mov w10, #34
    eor w11, w11, w11
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m16_col_ok
    mov w9, #65535
.Llex_m16_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, lx_ind_len
    add x8, x8, :lo12:lx_ind_len
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    ldr x16, [x8]
    mov x14, x16
    cmp x13, x14
    b.lo .Llex_ls_pop
    b.eq .Llex_ls_same
    adrp x8, s_unindent
    add x8, x8, :lo12:s_unindent
    add x10, x8, #0
    b .Llex_indent_error
.Llex_ls_push:
    cmp x9, #100
    b.hs .Llex_ls_too_deep
    mov x10, x14
    bl .Llex_prefix_same
    b.ne .Llex_ls_mixed
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    str x17, [x8]
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, lx_ind_len
    add x8, x8, :lo12:lx_ind_len
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    str x13, [x8]
    adrp x8, lx_ind_ptr
    add x8, x8, :lo12:lx_ind_ptr
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    str x24, [x8]
    mov w10, #33
    eor w11, w11, w11
    and w17, w10, #0xffff
    sturh w17, [x21, #0]
    mov x9, x12
    subs x9, x9, x24
    adds x9, x9, #1
    mov x17, #65535
    cmp x9, x17
    b.ls .Llex_m17_col_ok
    mov w9, #65535
.Llex_m17_col_ok:
    and w17, w9, #0xffff
    sturh w17, [x21, #2]
    stur w25, [x21, #4]
    mov x9, x12
    subs x9, x9, x19
    stur w9, [x21, #8]
    stur w11, [x21, #12]
    adds x21, x21, #16
    adds x26, x26, #1
    b .Llex_next
.Llex_ls_same:
    tst x13, x13
    b.eq .Llex_next
    mov x10, x13
    bl .Llex_prefix_same
    b.ne .Llex_ls_mixed
    b .Llex_next
.Llex_ls_mixed:
    adrp x8, s_mixed
    add x8, x8, :lo12:s_mixed
    add x10, x8, #0
    b .Llex_indent_error
.Llex_ls_too_deep:
    adrp x8, s_too_nest
    add x8, x8, :lo12:s_too_nest
    add x10, x8, #0
.Llex_indent_error:
    mov x23, x24
    str x10, [sp, #-16]!
    bl msg_reset
    ldr x10, [sp], #16
    mov x0, x10
    bl msg_addz
    b .Llex_lex_error

.Llex_prefix_same:
    str x30, [sp, #-16]!
    adrp x8, lx_depth
    add x8, x8, :lo12:lx_depth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, lx_ind_ptr
    add x8, x8, :lo12:lx_ind_ptr
    add x15, x8, #0
    mov x8, x15
    add x8, x8, x9, lsl #3
    ldr x16, [x8]
    mov x15, x16
    eor w11, w11, w11
.Llex_ps_loop:
    cmp x11, x10
    b.hs .Llex_ps_equal
    mov x8, x24
    add x8, x8, x11, lsl #0
    ldrb w17, [x8]
    bfi x9, x17, #0, #8
    and w16, w9, #0xff
    mov x8, x15
    add x8, x8, x11, lsl #0
    ldrb w17, [x8]
    cmp w16, w17
    b.ne .Llex_ps_done
    adds x11, x11, #1
    b .Llex_ps_loop
.Llex_ps_equal:
    cmp w9, w9
.Llex_ps_done:
    ldr x30, [sp], #16
    ret

.Llex_unexpected:
    mov x23, x20
    bl msg_reset
    ldurb w9, [x23, #0]
    and w16, w9, #0xff
    cmp w16, #33
    b.lo .Llex_unexp_byte
    and w16, w9, #0xff
    cmp w16, #126
    b.hi .Llex_unexp_byte
    adrp x8, s_unexp_ch
    add x8, x8, :lo12:s_unexp_ch
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldurb w17, [x23, #0]
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    adrp x8, s_quote
    add x8, x8, :lo12:s_quote
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    b .Llex_lex_error
.Llex_unexp_byte:
    adrp x8, s_unexp_by
    add x8, x8, :lo12:s_unexp_by
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldurb w9, [x23, #0]
    lsr w17, w9, #4
    mov w9, w17
    adrp x8, hex_digits
    add x8, x8, :lo12:hex_digits
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    ldrb w17, [x8]
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    ldurb w9, [x23, #0]
    mov w16, #15
    ands w9, w9, w16
    adrp x8, hex_digits
    add x8, x8, :lo12:hex_digits
    add x10, x8, #0
    mov x8, x10
    add x8, x8, x9, lsl #0
    ldrb w17, [x8]
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    b .Llex_lex_error

.Llex_unterminated:
    mov x23, x12
    bl msg_reset
    adrp x8, s_unterm
    add x8, x8, :lo12:s_unterm
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    b .Llex_lex_error

.Llex_bad_escape:
    mov x23, x20
    bl msg_reset
    adrp x8, s_unk_esc
    add x8, x8, :lo12:s_unk_esc
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldurb w17, [x23, #1]
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    adrp x8, s_quote
    add x8, x8, :lo12:s_quote
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    b .Llex_lex_error

.Llex_name_long:
    mov x23, x12
    bl msg_reset
    adrp x8, s_name_long
    add x8, x8, :lo12:s_name_long
    add x10, x8, #0
    mov x0, x10
    bl msg_addz

.Llex_lex_error:
    mov x12, x23
    subs x12, x12, x24
    adds x12, x12, #1
    mov w11, w25
    adrp x8, s_lexical
    add x8, x8, :lo12:s_lexical
    add x10, x8, #0
    mov x0, x10
    mov x1, x11
    mov x2, x12
    bl diag_error_at

