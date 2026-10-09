#include "defs.h"



    RODATA
s_semantic:
    .ascii "semantic"
    .byte 0
s_type:
    .ascii "type"
    .byte 0
s_undef:
    .ascii "undefined variable '"
    .byte 0
s_quote:
    .ascii "'"
    .byte 0
s_var_q:
    .ascii "variable '"
    .byte 0
s_already_as:
    .ascii "' is already declared as "
    .byte 0
s_an_int:
    .ascii "an int variable"
    .byte 0
s_a_str:
    .ascii "a str variable"
    .byte 0
s_a_bool:
    .ascii "a bool variable"
    .byte 0
s_already_at:
    .ascii "' is already declared at line "
    .byte 0
s_latest:
    .ascii ", the latest declaration claims the value"
    .byte 0
s_cannot:
    .ascii "cannot assign "
    .byte 0
s_to:
    .ascii " to "
    .byte 0
s_variable_q:
    .ascii " variable '"
    .byte 0
s_int_lit:
    .ascii "int literal "
    .byte 0
s_outside:
    .ascii " is outside -2147483648..2147483647"
    .byte 0
s_str_long:
    .ascii "string is longer than 65535 bytes"
    .byte 0
s_mode1:
    .ascii "unknown print mode '."
    .byte 0
s_mode2:
    .ascii "', expected '.s'"
    .byte 0
s_overflow:
    .ascii "integer overflow in constant expression, the result wraps to "
    .byte 0
s_div_zero:
    .ascii "division by zero"
    .byte 0
s_operator:
    .ascii "operator '"
    .byte 0
s_needs_bin:
    .ascii "' needs int operands, got "
    .byte 0
s_needs_un:
    .ascii "' needs an int operand, got "
    .byte 0
op_chars:
    .ascii " +-*/%-"
s_cmp1:
    .ascii "cannot compare "
    .byte 0
s_with:
    .ascii " with "
    .byte 0
s_in_if1:
    .ascii "variable '"
    .byte 0
s_in_if2:
    .ascii "' must be declared before the if block"
    .byte 0
s_str_if1:
    .ascii "cannot declare str variable '"
    .byte 0
s_str_if2:
    .ascii "' inside an if block"
    .byte 0
s_in_loop2:
    .ascii "' must be declared before the loop"
    .byte 0
s_str_loop2:
    .ascii "' inside a loop"
    .byte 0
s_count1:
    .ascii "loop count must be int, got "
    .byte 0
s_lvar1:
    .ascii "loop variable '"
    .byte 0
s_lvar2:
    .ascii "' must be int, it is declared as "
    .byte 0
cmp_chars:
    .ascii "   <><>"
s_tn_int:
    .ascii "int"
    .byte 0
s_tn_str:
    .ascii "str"
    .byte 0
s_tn_bool:
    .ascii "bool"
    .byte 0
s_tn_null:
    .ascii "null"
    .byte 0
s_true:
    .ascii "true"
s_false:
    .ascii "false"
s_null:
    .ascii "null"
s_crlf:
    .byte 13, 10

    .bss
    .p2align 3
last_slot:
    .zero (1) * 8
last_hash:
    .zero (1) * 8
sm_carry:
    .zero (1) * 8
sm_bdepth:
    .zero (1) * 8
sm_bstack:
    .zero (MAX_NEST + 1) * 8
sm_bkind:
    .zero (MAX_NEST + 1) * 8

    .text

    .globl tok_text
tok_text:
    stp x29, x30, [sp, #-16]!
    mov w9, w10
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    ldr x16, [x8]
    adds x9, x9, x16
    ldur w16, [x9, #12]
    mov w11, w16
    ldur w16, [x9, #8]
    mov w9, w16
    adrp x8, g_src
    add x8, x8, :lo12:g_src
    ldr x16, [x8]
    adds x9, x9, x16
    ldp x29, x30, [sp], #16
    ret

tok_line:
    stp x29, x30, [sp, #-16]!
    mov w9, w10
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_tokens
    add x8, x8, :lo12:g_tokens
    ldr x16, [x8]
    adds x9, x9, x16
    ldur w16, [x9, #4]
    mov w9, w16
    ldp x29, x30, [sp], #16
    ret

type_name:
    stp x29, x30, [sp, #-16]!
    adrp x8, s_tn_int
    add x8, x8, :lo12:s_tn_int
    add x9, x8, #0
    cmp w10, #1
    b.eq .Ltype_name_r
    adrp x8, s_tn_str
    add x8, x8, :lo12:s_tn_str
    add x9, x8, #0
    cmp w10, #2
    b.eq .Ltype_name_r
    adrp x8, s_tn_bool
    add x8, x8, :lo12:s_tn_bool
    add x9, x8, #0
    cmp w10, #3
    b.eq .Ltype_name_r
    adrp x8, s_tn_null
    add x8, x8, :lo12:s_tn_null
    add x9, x8, #0
.Ltype_name_r:
    ldp x29, x30, [sp], #16
    ret

pool_add:
    stp x29, x30, [sp, #-16]!
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    ldr x16, [x8]
    mov x12, x16
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    adds x12, x12, x16
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x17, [x8]
    adds x17, x17, x11
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    str x17, [x8]
.Lpool_add_loop:
    tst x11, x11
    b.eq .Lpool_add_end
    ldur w17, [x10, #0]
    bfi x9, x17, #0, #8
    and w17, w9, #0xff
    sturb w17, [x12, #0]
    adds x10, x10, #1
    adds x12, x12, #1
    subs x11, x11, #1
    b .Lpool_add_loop
.Lpool_add_end:
    ldp x29, x30, [sp], #16
    ret

new_piece:
    stp x29, x30, [sp, #-16]!
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    ldr x16, [x8]
    mov x9, x16
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    str x17, [x8]
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_pieces
    add x8, x8, :lo12:g_pieces
    ldr x16, [x8]
    adds x9, x9, x16
    stur w10, [x9, #0]
    stur w11, [x9, #4]
    mov w17, #0
    stur w17, [x9, #8]
    ldp x29, x30, [sp], #16
    ret

value_pos:
    stp x29, x30, [sp, #-16]!
    ldurb w16, [x10, #0]
    cmp w16, #6
    b.ne .Lvalue_pos_leaf
    ldurb w16, [x10, #1]
    cmp w16, #6
    b.eq .Lvalue_pos_neg
    ldur w16, [x10, #8]
    mov w9, w16
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x10, x9
    ldp x29, x30, [sp], #16
    b value_pos
.Lvalue_pos_neg:
    ldur w16, [x10, #4]
    mov w11, w16
    ldp x29, x30, [sp], #16
    ret
.Lvalue_pos_leaf:
    ldurb w9, [x10, #1]
    ldur w16, [x10, #4]
    mov w11, w16
    subs w11, w11, w9
    ldp x29, x30, [sp], #16
    ret

node_ptr:
    stp x29, x30, [sp, #-16]!
    mov w9, w10
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x9, x9, x16
    ldp x29, x30, [sp], #16
    ret

set_const:
    stp x29, x30, [sp, #-16]!
    mov x10, x19
    bl value_pos
    mov w17, #1
    sturb w17, [x19, #0]
    mov w17, #0
    sturb w17, [x19, #1]
    mov w17, #0
    sturb w17, [x19, #3]
    stur w11, [x19, #4]
    stur x14, [x19, #8]
    ldp x29, x30, [sp], #16
    ret

copy_node:
    stp x29, x30, [sp, #-16]!
    ldur x16, [x10, #0]
    mov x9, x16
    stur x9, [x19, #0]
    ldur x16, [x10, #8]
    mov x9, x16
    stur x9, [x19, #8]
    ldp x29, x30, [sp], #16
    ret

FUNC check_expr
    mov x19, x10
    ldurb w23, [x19, #1]
    ldur w16, [x19, #8]
    mov w10, w16
    bl node_ptr
    mov x24, x9
    mov x10, x24
    bl check_value
    mov w25, w9
    mov x10, x24
    bl value_finish
    cmp w25, #1
    b.ne .Lcheck_expr_bad_operand
    cmp w23, #6
    b.eq .Lcheck_expr_unary
    ldur w16, [x19, #12]
    mov w10, w16
    bl node_ptr
    mov x26, x9
    mov x10, x26
    bl check_value
    mov w25, w9
    mov x10, x26
    bl value_finish
    cmp w25, #1
    b.ne .Lcheck_expr_bad_operand
    eor w20, w20, w20
    ldurb w16, [x24, #0]
    cmp w16, #1
    b.ne .Lcheck_expr_left_done
    mov w16, #1
    orr w20, w20, w16
.Lcheck_expr_left_done:
    ldurb w16, [x26, #0]
    cmp w16, #1
    b.ne .Lcheck_expr_right_done
    mov w16, #2
    orr w20, w20, w16
.Lcheck_expr_right_done:
    ldur x16, [x24, #8]
    mov x12, x16
    ldur x16, [x26, #8]
    mov x13, x16
    mov w17, #2
    tst w20, w17
    b.eq .Lcheck_expr_no_zero_check
    tst x13, x13
    b.ne .Lcheck_expr_no_zero_check
    cmp w23, #4
    b.eq .Lcheck_expr_div_zero
    cmp w23, #5
    b.eq .Lcheck_expr_div_zero
.Lcheck_expr_no_zero_check:
    cmp w20, #3
    b.eq .Lcheck_expr_fold
    mov w17, #2
    tst w20, w17
    b.ne .Lcheck_expr_right_const
    mov w17, #1
    tst w20, w17
    b.ne .Lcheck_expr_left_const
    b .Lcheck_expr_int_result

.Lcheck_expr_right_const:
    cmp w23, #1
    b.eq .Lcheck_expr_r_add_sub
    cmp w23, #2
    b.eq .Lcheck_expr_r_add_sub
    cmp w23, #3
    b.eq .Lcheck_expr_r_mul
    cmp w23, #4
    b.eq .Lcheck_expr_r_div
    b .Lcheck_expr_r_mod
.Lcheck_expr_r_add_sub:
    tst x13, x13
    b.eq .Lcheck_expr_take_left
    b .Lcheck_expr_int_result
.Lcheck_expr_r_mul:
    tst x13, x13
    b.ne .Lcheck_expr_r_div
    ldurb w16, [x24, #0]
    cmp w16, #5
    b.eq .Lcheck_expr_make_zero
    b .Lcheck_expr_int_result
.Lcheck_expr_r_div:
    cmp x13, #1
    b.eq .Lcheck_expr_take_left
    cmn x13, #1
    b.ne .Lcheck_expr_int_result
    mov x10, x24
    bl value_pos
    stur w11, [x19, #4]
    mov w17, #6
    sturb w17, [x19, #1]
    ldr w17, =4294967295
    stur w17, [x19, #12]
    b .Lcheck_expr_int_result
.Lcheck_expr_r_mod:
    ldurb w16, [x24, #0]
    cmp w16, #5
    b.ne .Lcheck_expr_int_result
    cmp x13, #1
    b.eq .Lcheck_expr_make_zero
    cmn x13, #1
    b.eq .Lcheck_expr_make_zero
    b .Lcheck_expr_int_result

.Lcheck_expr_left_const:
    cmp w23, #1
    b.eq .Lcheck_expr_l_add
    cmp w23, #2
    b.eq .Lcheck_expr_l_sub
    cmp w23, #3
    b.ne .Lcheck_expr_int_result
    tst x12, x12
    b.ne .Lcheck_expr_l_mul_one
    ldurb w16, [x26, #0]
    cmp w16, #5
    b.eq .Lcheck_expr_make_zero
    b .Lcheck_expr_int_result
.Lcheck_expr_l_mul_one:
    cmp x12, #1
    b.eq .Lcheck_expr_take_right
    b .Lcheck_expr_int_result
.Lcheck_expr_l_add:
    tst x12, x12
    b.eq .Lcheck_expr_take_right
    b .Lcheck_expr_int_result
.Lcheck_expr_l_sub:
    tst x12, x12
    b.ne .Lcheck_expr_int_result
    ldur w16, [x24, #4]
    mov w9, w16
    stur w9, [x19, #4]
    ldur w16, [x19, #12]
    mov w9, w16
    stur w9, [x19, #8]
    mov w17, #6
    sturb w17, [x19, #1]
    ldr w17, =4294967295
    stur w17, [x19, #12]
    b .Lcheck_expr_int_result

.Lcheck_expr_take_left:
    mov x10, x24
    bl copy_node
    b .Lcheck_expr_int_result
.Lcheck_expr_take_right:
    mov x10, x26
    bl copy_node
    b .Lcheck_expr_int_result
.Lcheck_expr_make_zero:
    eor w14, w14, w14
    bl set_const
    b .Lcheck_expr_int_result

.Lcheck_expr_unary:
    ldurb w16, [x24, #0]
    cmp w16, #1
    b.ne .Lcheck_expr_int_result
    ldur x16, [x24, #8]
    mov x14, x16
    negs x17, x14
    mov x14, x17
    b .Lcheck_expr_fold_store

.Lcheck_expr_fold:
    mov x14, x12
    cmp w23, #1
    b.ne .Lcheck_expr_f_sub
    adds x14, x14, x13
    b .Lcheck_expr_fold_store
.Lcheck_expr_f_sub:
    cmp w23, #2
    b.ne .Lcheck_expr_f_mul
    subs x14, x14, x13
    b .Lcheck_expr_fold_store
.Lcheck_expr_f_mul:
    cmp w23, #3
    b.ne .Lcheck_expr_f_div
    mul x17, x14, x13
    mov x14, x17
    b .Lcheck_expr_fold_store
.Lcheck_expr_f_div:
    mov x9, x12
    sdiv x17, x9, x13
    msub x11, x17, x13, x9
    mov x9, x17
    mov x14, x9
    cmp w23, #4
    b.eq .Lcheck_expr_fold_store
    mov x14, x11
.Lcheck_expr_fold_store:
    sxtw x9, w14
    cmp x9, x14
    b.eq .Lcheck_expr_fold_ok
    mov x14, x9
    str x14, [sp, #-16]!
    str x14, [sp, #-16]!
    bl msg_reset
    adrp x8, s_overflow
    add x8, x8, :lo12:s_overflow
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldr x16, [sp, #0]
    mov x14, x16
    tst x14, x14
    b.pl .Lcheck_expr_ov_pos
    mov w17, #45
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    ldr x16, [sp, #0]
    mov x14, x16
    negs x17, x14
    mov x14, x17
.Lcheck_expr_ov_pos:
    mov x10, x14
    mov x0, x10
    bl msg_addu
    ldur w16, [x19, #4]
    mov w10, w16
    mov x0, x10
    bl diag_warn_tok
    ldr x14, [sp], #16
    ldr x14, [sp], #16
.Lcheck_expr_fold_ok:
    bl set_const

.Lcheck_expr_int_result:
    mov w9, #1
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

.Lcheck_expr_div_zero:
    bl msg_reset
    adrp x8, s_div_zero
    add x8, x8, :lo12:s_div_zero
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x19, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lcheck_expr_bad_operand:
    bl msg_reset
    adrp x8, s_operator
    add x8, x8, :lo12:s_operator
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, op_chars
    add x8, x8, :lo12:op_chars
    add x9, x8, #0
    mov x8, x9
    add x8, x8, x23, lsl #0
    ldr w17, [x8]
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    adrp x8, s_needs_bin
    add x8, x8, :lo12:s_needs_bin
    add x10, x8, #0
    cmp w23, #6
    b.ne .Lcheck_expr_bad_msg
    adrp x8, s_needs_un
    add x8, x8, :lo12:s_needs_un
    add x10, x8, #0
.Lcheck_expr_bad_msg:
    mov x0, x10
    bl msg_addz
    mov w10, w25
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    adrp x8, s_type
    add x8, x8, :lo12:s_type
    add x10, x8, #0
    ldur w16, [x19, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

FUNC var_lookup
    mov w23, w10
    bl tok_text
    mov x20, x9
    mov x21, x11
    ldr x19, =14695981039346656037
    ldr x13, =1099511628211
    eor w10, w10, w10
.Lvar_lookup_hash:
    cmp x10, x21
    b.hs .Lvar_lookup_hashed
    mov x8, x20
    add x8, x8, x10, lsl #0
    ldrb w9, [x8]
    eor x19, x19, x9
    mul x17, x19, x13
    mov x19, x17
    adds x10, x10, #1
    b .Lvar_lookup_hash
.Lvar_lookup_hashed:
    adrp x8, last_hash
    add x8, x8, :lo12:last_hash
    str x19, [x8]
    adrp x8, g_hmask
    add x8, x8, :lo12:g_hmask
    ldr x16, [x8]
    mov x24, x16
    mov x25, x19
    ands x25, x25, x24
    adrp x8, g_htab
    add x8, x8, :lo12:g_htab
    ldr x16, [x8]
    mov x26, x16
.Lvar_lookup_probe:
    mov x8, x26
    add x8, x8, x25, lsl #2
    add x9, x8, #0
    adrp x8, last_slot
    add x8, x8, :lo12:last_slot
    str x9, [x8]
    ldur w16, [x9, #0]
    mov w9, w16
    tst w9, w9
    b.eq .Lvar_lookup_missing
    subs w9, w9, #1
    mov w14, w9
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    ldur x16, [x9, #0]
    cmp x16, x19
    b.ne .Lvar_lookup_next
    ldur w16, [x9, #8]
    mov w10, w16
    bl tok_text
    cmp x11, x21
    b.ne .Lvar_lookup_next
    eor w10, w10, w10
.Lvar_lookup_cmp:
    cmp x10, x21
    b.hs .Lvar_lookup_found
    mov x8, x9
    add x8, x8, x10, lsl #0
    ldr w17, [x8]
    bfi x12, x17, #0, #8
    and w16, w12, #0xff
    mov x8, x20
    add x8, x8, x10, lsl #0
    ldr w17, [x8]
    cmp w16, w17
    b.ne .Lvar_lookup_next
    adds x10, x10, #1
    b .Lvar_lookup_cmp
.Lvar_lookup_found:
    mov w9, w14
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lvar_lookup_next:
    adds x25, x25, #1
    ands x25, x25, x24
    b .Lvar_lookup_probe
.Lvar_lookup_missing:
    ldr w9, =4294967295
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

FUNC var_insert
    mov w23, w10
    mov w24, w11
    bl var_lookup
    adrp x8, g_nvars
    add x8, x8, :lo12:g_nvars
    ldr x16, [x8]
    mov x9, x16
    mov x25, x9
    adrp x8, g_nvars
    add x8, x8, :lo12:g_nvars
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, g_nvars
    add x8, x8, :lo12:g_nvars
    str x17, [x8]
    adrp x8, last_slot
    add x8, x8, :lo12:last_slot
    ldr x16, [x8]
    mov x10, x16
    add x11, x9, #1
    mov w11, w11
    stur w11, [x10, #0]
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    mov x19, x9
    adrp x8, last_hash
    add x8, x8, :lo12:last_hash
    ldr x16, [x8]
    mov x10, x16
    stur x10, [x19, #0]
    stur w23, [x19, #8]
    and w17, w24, #0xffff
    sturh w17, [x19, #12]
    mov w10, #4
    mov w11, #4
    cmp w24, #1
    b.eq .Lvar_insert_size
    mov w10, #1
    mov w11, #1
    cmp w24, #3
    b.eq .Lvar_insert_size
    mov w10, #16
    mov w11, #16
.Lvar_insert_size:
    adrp x8, g_vars_size
    add x8, x8, :lo12:g_vars_size
    ldr x16, [x8]
    mov x9, x16
    mov x8, x9
    add x8, x8, x10, lsl #0
    sub x8, x8, #1
    add x9, x8, #0
    negs x17, x10
    mov x10, x17
    ands x9, x9, x10
    stur w9, [x19, #16]
    adds x9, x9, x11
    adrp x8, g_vars_size
    add x8, x8, :lo12:g_vars_size
    str x9, [x8]
    mov w9, w25
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

FUNC check_value
    mov x19, x10
    ldurb w9, [x19, #2]
    tst w9, w9
    b.ne .Lcheck_value_already
    ldurb w9, [x19, #0]
    cmp w9, #1
    b.eq .Lcheck_value_int
    cmp w9, #2
    b.eq .Lcheck_value_str
    cmp w9, #5
    b.eq .Lcheck_value_var
    cmp w9, #6
    b.eq .Lcheck_value_expr
    mov w23, #3
    cmp w9, #3
    b.eq .Lcheck_value_done
    mov w23, #4
    b .Lcheck_value_done

.Lcheck_value_int:
    mov w23, #1
    ldur w16, [x19, #4]
    mov w10, w16
    bl tok_text
    eor w12, w12, w12
    eor w13, w13, w13
    ldr x14, =4294967295
.Lcheck_value_digit:
    cmp x13, x11
    b.hs .Lcheck_value_digits_done
    mov x8, x9
    add x8, x8, x13, lsl #0
    ldrb w10, [x8]
    subs w10, w10, #48
    adds x13, x13, #1
    cmp x12, x14
    b.hi .Lcheck_value_digit
    mov x17, #10
    mul x17, x12, x17
    mov x12, x17
    adds x12, x12, x10
    b .Lcheck_value_digit
.Lcheck_value_digits_done:
    ldurb w16, [x19, #1]
    cmp w16, #0
    b.ne .Lcheck_value_int_neg
    ldr x17, =2147483647
    cmp x12, x17
    b.hi .Lcheck_value_int_bad
    stur x12, [x19, #8]
    b .Lcheck_value_done
.Lcheck_value_int_neg:
    ldr x15, =2147483648
    cmp x12, x15
    b.hi .Lcheck_value_int_bad
    negs x17, x12
    mov x12, x17
    stur x12, [x19, #8]
    b .Lcheck_value_done
.Lcheck_value_int_bad:
    mov w17, #1
    sturb w17, [x19, #3]
    b .Lcheck_value_done

.Lcheck_value_str:
    mov w23, #2
    ldur w16, [x19, #4]
    mov w10, w16
    bl tok_text
    add x20, x9, #1
    mov x8, x9
    add x8, x8, x11, lsl #0
    sub x8, x8, #1
    add x21, x8, #0
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    mov x24, x16
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    ldr x16, [x8]
    mov x25, x16
    adds x25, x25, x24
    mov x26, x25
.Lcheck_value_dec:
    cmp x20, x21
    b.hs .Lcheck_value_dec_done
    ldur w17, [x20, #0]
    bfi x9, x17, #0, #8
    adds x20, x20, #1
    and w16, w9, #0xff
    cmp w16, #92
    b.ne .Lcheck_value_dec_put
    ldur w17, [x20, #0]
    bfi x9, x17, #0, #8
    adds x20, x20, #1
    and w16, w9, #0xff
    cmp w16, #110
    b.ne .Lcheck_value_e1
    mov w17, #10
    bfi x9, x17, #0, #8
    b .Lcheck_value_dec_put
.Lcheck_value_e1:
    and w16, w9, #0xff
    cmp w16, #116
    b.ne .Lcheck_value_e2
    mov w17, #9
    bfi x9, x17, #0, #8
    b .Lcheck_value_dec_put
.Lcheck_value_e2:
    and w16, w9, #0xff
    cmp w16, #114
    b.ne .Lcheck_value_e3
    mov w17, #13
    bfi x9, x17, #0, #8
    b .Lcheck_value_dec_put
.Lcheck_value_e3:
    and w16, w9, #0xff
    cmp w16, #48
    b.ne .Lcheck_value_dec_put
    eor w9, w9, w9
.Lcheck_value_dec_put:
    and w17, w9, #0xff
    sturb w17, [x26, #0]
    adds x26, x26, #1
    b .Lcheck_value_dec
.Lcheck_value_dec_done:
    subs x26, x26, x25
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x17, [x8]
    adds x17, x17, x26
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    str x17, [x8]
    mov x9, x26
    lsl x17, x9, #32
    mov x9, x17
    orr x9, x9, x24
    stur x9, [x19, #8]
    mov x17, #65535
    cmp x26, x17
    b.ls .Lcheck_value_done
    mov w17, #1
    sturb w17, [x19, #3]
    b .Lcheck_value_done

.Lcheck_value_var:
    ldur w16, [x19, #4]
    mov w10, w16
    bl var_lookup
    cmn w9, #1
    b.eq .Lcheck_value_undefined
    stur x9, [x19, #8]
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w23, [x9, #12]
    b .Lcheck_value_done
.Lcheck_value_undefined:
    bl msg_reset
    adrp x8, s_undef
    add x8, x8, :lo12:s_undef
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x19, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_quote
    add x8, x8, :lo12:s_quote
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x19, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lcheck_value_expr:
    mov x10, x19
    bl check_expr
    mov w23, w9

.Lcheck_value_done:
    and w17, w23, #0xff
    sturb w17, [x19, #2]
    mov w9, w23
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lcheck_value_already:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

FUNC value_finish
    mov x19, x10
    ldurb w16, [x19, #3]
    cmp w16, #0
    b.eq .Lvalue_finish_ok
    bl msg_reset
    ldurb w16, [x19, #0]
    cmp w16, #1
    b.ne .Lvalue_finish_str
    adrp x8, s_int_lit
    add x8, x8, :lo12:s_int_lit
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldurb w16, [x19, #1]
    cmp w16, #0
    b.eq .Lvalue_finish_digits
    mov w17, #45
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
.Lvalue_finish_digits:
    ldur w16, [x19, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_outside
    add x8, x8, :lo12:s_outside
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    b .Lvalue_finish_err
.Lvalue_finish_str:
    adrp x8, s_str_long
    add x8, x8, :lo12:s_str_long
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
.Lvalue_finish_err:
    mov x10, x19
    bl value_pos
    adrp x8, s_type
    add x8, x8, :lo12:s_type
    add x10, x8, #0
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lvalue_finish_ok:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

FUNC check_assign
    mov x19, x10
    mov w23, w11
    mov w24, w12
    bl check_value
    cmp w9, w23
    b.eq .Lcheck_assign_ok
    cmp w9, #4
    b.ne .Lcheck_assign_bad
    cmp w23, #2
    b.eq .Lcheck_assign_ok
.Lcheck_assign_bad:
    mov w25, w9
    bl msg_reset
    adrp x8, s_cannot
    add x8, x8, :lo12:s_cannot
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w25
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    adrp x8, s_to
    add x8, x8, :lo12:s_to
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w23
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    adrp x8, s_variable_q
    add x8, x8, :lo12:s_variable_q
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w24
    mov x0, x10
    bl msg_tok
    adrp x8, s_quote
    add x8, x8, :lo12:s_quote
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov x10, x19
    bl value_pos
    adrp x8, s_type
    add x8, x8, :lo12:s_type
    add x10, x8, #0
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lcheck_assign_ok:
    mov x10, x19
    bl value_finish
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

FUNC sema
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    ldr x16, [x8]
    mov x10, x16
    adds x10, x10, #1
    lsl x17, x10, #5
    mov x10, x17
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    str x9, [x8]
    mov x17, #0
    adrp x8, g_nvars
    add x8, x8, :lo12:g_nvars
    str x17, [x8]
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    ldr x16, [x8]
    mov x10, x16
    adds x10, x10, #1
    lsl x17, x10, #1
    mov x10, x17
    mov w9, #16
.Lsema_cap:
    cmp x9, x10
    b.hs .Lsema_cap_ok
    lsl x17, x9, #1
    mov x9, x17
    b .Lsema_cap
.Lsema_cap_ok:
    sub x11, x9, #1
    adrp x8, g_hmask
    add x8, x8, :lo12:g_hmask
    str x11, [x8]
    lsl x8, x9, #2
    add x10, x8, #0
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_htab
    add x8, x8, :lo12:g_htab
    str x9, [x8]
    adrp x8, g_src_len
    add x8, x8, :lo12:g_src_len
    ldr x16, [x8]
    mov x10, x16
    lsl x17, x10, #1
    mov x10, x17
    mov x16, #4096
    adds x10, x10, x16
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    str x9, [x8]
    mov x17, #0
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    str x17, [x8]
    adrp x8, g_nparts
    add x8, x8, :lo12:g_nparts
    ldr x16, [x8]
    mov x10, x16
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    ldr x16, [x8]
    adds x10, x10, x16
    adds x10, x10, #1
    lsl x17, x10, #4
    mov x10, x17
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, g_pieces
    add x8, x8, :lo12:g_pieces
    str x9, [x8]
    mov x17, #0
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    str x17, [x8]
    mov x17, #0
    adrp x8, g_vars_size
    add x8, x8, :lo12:g_vars_size
    str x17, [x8]

    mov x17, #0
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    str x17, [x8]
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    mov x23, x16
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    ldr x16, [x8]
    mov x24, x16
    lsl x17, x24, #5
    mov x24, x17
    adds x24, x24, x23
.Lsema_stmt:
    cmp x23, x24
    b.hs .Lsema_finish
    mov x9, x23
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    subs x9, x9, x16
    lsr x17, x9, #5
    mov x9, x17
.Lsema_block_end:
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    mov x10, x16
    tst x10, x10
    b.eq .Lsema_block_ok
    adrp x8, sm_bstack
    add x8, x8, :lo12:sm_bstack
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x10, lsl #3
    sub x8, x8, #8
    ldr x16, [x8]
    cmp x16, x9
    b.ne .Lsema_block_ok
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x17, [x8]
    subs x17, x17, #1
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    str x17, [x8]
    mov x17, #0
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x17, [x8]
    b .Lsema_block_end
.Lsema_block_ok:
    ldurh w9, [x23, #0]
    cmp w9, #4
    b.eq .Lsema_if_stmt
    cmp w9, #7
    b.eq .Lsema_else_stmt
    cmp w9, #5
    b.eq .Lsema_loop_stmt
    cmp w9, #6
    b.eq .Lsema_loop_stmt
    cmp w9, #1
    b.eq .Lsema_decl
    cmp w9, #2
    b.eq .Lsema_assign
    b .Lsema_out

.Lsema_decl:
    mov x17, #0
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x17, [x8]
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    cmp x16, #0
    b.ne .Lsema_decl_in_block
.Lsema_decl_top:
    ldur w16, [x23, #4]
    mov w10, w16
    bl var_lookup
    mov w25, w9
    cmn w9, #1
    b.eq .Lsema_decl_value
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    mov x19, x9
    ldurh w9, [x19, #12]
    ldurh w10, [x23, #2]
    cmp w9, w10
    b.ne .Lsema_redecl_type
    bl msg_reset
    adrp x8, s_var_q
    add x8, x8, :lo12:s_var_q
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_already_at
    add x8, x8, :lo12:s_already_at
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x19, #20]
    mov w10, w16
    mov x0, x10
    bl msg_addu
    adrp x8, s_latest
    add x8, x8, :lo12:s_latest
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl diag_warn_tok
.Lsema_decl_value:
    ldur w16, [x23, #12]
    cmp w16, #0
    b.eq .Lsema_decl_store
    ldur w16, [x23, #16]
    mov w9, w16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w10, w16
    lsl x17, x10, #4
    mov x10, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x10, x10, x16
    ldurh w11, [x23, #2]
    ldur w16, [x23, #4]
    mov w12, w16
    bl check_assign
.Lsema_decl_store:
    cmn w25, #1
    b.ne .Lsema_decl_known
    ldur w16, [x23, #4]
    mov w10, w16
    ldurh w11, [x23, #2]
    bl var_insert
    mov w25, w9
.Lsema_decl_known:
    stur w25, [x23, #8]
    ldur w16, [x23, #4]
    mov w10, w16
    bl tok_line
    mov w10, w25
    lsl x17, x10, #5
    mov x10, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x10, x10, x16
    stur w9, [x10, #20]
    b .Lsema_next

.Lsema_redecl_type:
    mov w26, w9
    bl msg_reset
    adrp x8, s_var_q
    add x8, x8, :lo12:s_var_q
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_already_as
    add x8, x8, :lo12:s_already_as
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_an_int
    add x8, x8, :lo12:s_an_int
    add x10, x8, #0
    cmp w26, #1
    b.eq .Lsema_redecl_msg
    adrp x8, s_a_str
    add x8, x8, :lo12:s_a_str
    add x10, x8, #0
    cmp w26, #2
    b.eq .Lsema_redecl_msg
    adrp x8, s_a_bool
    add x8, x8, :lo12:s_a_bool
    add x10, x8, #0
.Lsema_redecl_msg:
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x23, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lsema_decl_in_block:
    ldurh w16, [x23, #2]
    cmp w16, #2
    b.eq .Lsema_str_in_block
    ldur w16, [x23, #4]
    mov w10, w16
    bl var_lookup
    cmn w9, #1
    b.eq .Lsema_undeclared_in_block
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w9, [x9, #12]
    ldurh w10, [x23, #2]
    cmp w9, w10
    b.ne .Lsema_decl_top
    mov w17, #2
    sturh w17, [x23, #0]
    b .Lsema_assign
.Lsema_str_in_block:
    bl msg_reset
    adrp x8, s_str_if1
    add x8, x8, :lo12:s_str_if1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_str_if2
    add x8, x8, :lo12:s_str_if2
    add x10, x8, #0
    bl block_is_loop
    b.ne .Lsema_str_msg
    adrp x8, s_str_loop2
    add x8, x8, :lo12:s_str_loop2
    add x10, x8, #0
.Lsema_str_msg:
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x23, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lsema_undeclared_in_block:
    bl msg_reset
    adrp x8, s_in_if1
    add x8, x8, :lo12:s_in_if1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_in_if2
    add x8, x8, :lo12:s_in_if2
    add x10, x8, #0
    bl block_is_loop
    b.ne .Lsema_undecl_msg
    adrp x8, s_in_loop2
    add x8, x8, :lo12:s_in_loop2
    add x10, x8, #0
.Lsema_undecl_msg:
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x23, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lsema_if_stmt:
    mov x17, #0
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x17, [x8]
    ldur w16, [x23, #16]
    mov w9, w16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w10, w16
    lsl x17, x10, #4
    mov x10, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x10, x10, x16
    bl check_cond
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    mov x10, x16
    adrp x8, sm_bstack
    add x8, x8, :lo12:sm_bstack
    add x11, x8, #0
    ldur w16, [x23, #28]
    mov w9, w16
    mov x8, x11
    add x8, x8, x10, lsl #3
    str x9, [x8]
    adrp x8, sm_bkind
    add x8, x8, :lo12:sm_bkind
    add x11, x8, #0
    mov x17, #1
    mov x8, x11
    add x8, x8, x10, lsl #3
    str x17, [x8]
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    str x17, [x8]
    b .Lsema_next

.Lsema_else_stmt:
    mov x17, #0
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x17, [x8]
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    mov x10, x16
    adrp x8, sm_bstack
    add x8, x8, :lo12:sm_bstack
    add x11, x8, #0
    ldur w16, [x23, #28]
    mov w9, w16
    mov x8, x11
    add x8, x8, x10, lsl #3
    str x9, [x8]
    adrp x8, sm_bkind
    add x8, x8, :lo12:sm_bkind
    add x11, x8, #0
    mov x17, #1
    mov x8, x11
    add x8, x8, x10, lsl #3
    str x17, [x8]
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    str x17, [x8]
    b .Lsema_next

.Lsema_loop_stmt:
    mov x17, #0
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x17, [x8]
    ldur w16, [x23, #16]
    mov w9, w16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w10, w16
    lsl x17, x10, #4
    mov x10, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x10, x10, x16
    mov x19, x10
    bl check_value
    mov w25, w9
    mov x10, x19
    bl value_finish
    cmp w25, #1
    b.ne .Lsema_bad_count
    adrp x8, g_vars_size
    add x8, x8, :lo12:g_vars_size
    ldr x16, [x8]
    mov x9, x16
    adds x9, x9, #3
    ldr x16, =18446744073709551612
    ands x9, x9, x16
    stur w9, [x23, #24]
    adds x9, x9, #8
    adrp x8, g_vars_size
    add x8, x8, :lo12:g_vars_size
    str x9, [x8]
    ldurh w16, [x23, #0]
    cmp w16, #5
    b.ne .Lsema_loop_push
    ldur w16, [x23, #4]
    mov w10, w16
    bl var_lookup
    cmn w9, #1
    b.eq .Lsema_loop_new_var
    mov w26, w9
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w10, [x9, #12]
    cmp w10, #1
    b.ne .Lsema_bad_loop_var
    stur w26, [x23, #8]
    b .Lsema_loop_push
.Lsema_loop_new_var:
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    cmp x16, #0
    b.ne .Lsema_undeclared_in_block
    ldur w16, [x23, #4]
    mov w10, w16
    mov w11, #1
    bl var_insert
    stur w9, [x23, #8]
    mov w26, w9
    ldur w16, [x23, #4]
    mov w10, w16
    bl tok_line
    mov w10, w26
    lsl x17, x10, #5
    mov x10, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x10, x10, x16
    stur w9, [x10, #20]
.Lsema_loop_push:
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    mov x10, x16
    adrp x8, sm_bstack
    add x8, x8, :lo12:sm_bstack
    add x11, x8, #0
    ldur w16, [x23, #28]
    mov w9, w16
    mov x8, x11
    add x8, x8, x10, lsl #3
    str x9, [x8]
    adrp x8, sm_bkind
    add x8, x8, :lo12:sm_bkind
    add x11, x8, #0
    mov x17, #2
    mov x8, x11
    add x8, x8, x10, lsl #3
    str x17, [x8]
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x17, [x8]
    adds x17, x17, #1
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    str x17, [x8]
    b .Lsema_next
.Lsema_bad_count:
    bl msg_reset
    adrp x8, s_count1
    add x8, x8, :lo12:s_count1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w25
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    mov x10, x19
    bl value_pos
    adrp x8, s_type
    add x8, x8, :lo12:s_type
    add x10, x8, #0
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lsema_bad_loop_var:
    mov w25, w10
    bl msg_reset
    adrp x8, s_lvar1
    add x8, x8, :lo12:s_lvar1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_lvar2
    add x8, x8, :lo12:s_lvar2
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_an_int
    add x8, x8, :lo12:s_an_int
    add x10, x8, #0
    cmp w25, #1
    b.eq .Lsema_lv_msg
    adrp x8, s_a_str
    add x8, x8, :lo12:s_a_str
    add x10, x8, #0
    cmp w25, #2
    b.eq .Lsema_lv_msg
    adrp x8, s_a_bool
    add x8, x8, :lo12:s_a_bool
    add x10, x8, #0
.Lsema_lv_msg:
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x23, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lsema_assign:
    mov x17, #0
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x17, [x8]
    ldur w16, [x23, #4]
    mov w10, w16
    bl var_lookup
    cmn w9, #1
    b.ne .Lsema_assign_ok
    bl msg_reset
    adrp x8, s_undef
    add x8, x8, :lo12:s_undef
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #4]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_quote
    add x8, x8, :lo12:s_quote
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x23, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok
.Lsema_assign_ok:
    stur w9, [x23, #8]
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    ldurh w11, [x9, #12]
    and w17, w11, #0xffff
    sturh w17, [x23, #2]
    ldur w16, [x23, #12]
    cmp w16, #0
    b.eq .Lsema_next
    mov w25, w11
    ldur w16, [x23, #16]
    mov w9, w16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w10, w16
    lsl x17, x10, #4
    mov x10, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x10, x10, x16
    mov w11, w25
    ldur w16, [x23, #4]
    mov w12, w16
    bl check_assign
    b .Lsema_next

.Lsema_out:
    ldur w16, [x23, #20]
    mov w10, w16
    ldr w17, =4294967295
    cmp w10, w17
    b.eq .Lsema_out_parts
    bl tok_text
    cmp w11, #1
    b.ne .Lsema_bad_mode
    ldurb w16, [x9, #0]
    cmp w16, #115
    b.eq .Lsema_out_parts
.Lsema_bad_mode:
    bl msg_reset
    adrp x8, s_mode1
    add x8, x8, :lo12:s_mode1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    ldur w16, [x23, #20]
    mov w10, w16
    mov x0, x10
    bl msg_tok
    adrp x8, s_mode2
    add x8, x8, :lo12:s_mode2
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, s_semantic
    add x8, x8, :lo12:s_semantic
    add x10, x8, #0
    ldur w16, [x23, #20]
    mov w11, w16
    subs w11, w11, #1
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lsema_out_parts:
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    ldr x16, [x8]
    mov x9, x16
    stur w9, [x23, #28]
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    ldr x16, [x8]
    mov x26, x16
    eor w25, w25, w25
.Lsema_part:
    ldur w17, [x23, #12]
    cmp w25, w17
    b.hs .Lsema_parts_done
    ldur w16, [x23, #16]
    mov w9, w16
    adds w9, w9, w25
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w19, w16
    lsl x17, x19, #4
    mov x19, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x19, x19, x16
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    mov x20, x16
    mov x10, x19
    bl check_value
    mov w21, w9
    mov x10, x19
    bl value_finish
    ldurb w9, [x19, #0]
    cmp w9, #6
    b.eq .Lsema_part_expr
    cmp w9, #5
    b.eq .Lsema_part_var
    cmp w9, #1
    b.eq .Lsema_part_int
    cmp w9, #3
    b.eq .Lsema_part_bool
    cmp w9, #4
    b.ne .Lsema_part_text
    adrp x8, s_null
    add x8, x8, :lo12:s_null
    add x10, x8, #0
    mov w11, #4
    bl pool_add
    b .Lsema_part_text
.Lsema_part_bool:
    adrp x8, s_true
    add x8, x8, :lo12:s_true
    add x10, x8, #0
    mov w11, #4
    ldur x16, [x19, #8]
    cmp x16, #0
    b.ne .Lsema_part_bool_add
    adrp x8, s_false
    add x8, x8, :lo12:s_false
    add x10, x8, #0
    mov w11, #5
.Lsema_part_bool_add:
    bl pool_add
    b .Lsema_part_text
.Lsema_part_int:
    ldur x16, [x19, #8]
    mov x9, x16
    tst x9, x9
    b.pl .Lsema_part_int_pos
    adrp x8, s_minus_char
    add x8, x8, :lo12:s_minus_char
    add x10, x8, #0
    mov w11, #1
    bl pool_add
    ldur x16, [x19, #8]
    mov x10, x16
    negs x17, x10
    mov x10, x17
    b .Lsema_part_int_dec
.Lsema_part_int_pos:
    mov x10, x9
.Lsema_part_int_dec:
    mov x0, x10
    bl u64_to_dec
    mov x9, x0
    mov x11, x1
    mov x10, x9
    bl pool_add
.Lsema_part_text:
    tst x26, x26
    b.ne .Lsema_part_extend
    mov w10, #1
    mov w11, w20
    bl new_piece
    mov x26, x9
.Lsema_part_extend:
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    mov x9, x16
    ldur w16, [x26, #4]
    subs w9, w9, w16
    stur w9, [x26, #8]
    b .Lsema_part_next
.Lsema_part_var:
    eor w26, w26, w26
    ldur x16, [x19, #8]
    mov x9, x16
    lsl x17, x9, #5
    mov x9, x17
    adrp x8, g_vars
    add x8, x8, :lo12:g_vars
    ldr x16, [x8]
    adds x9, x9, x16
    ldur w16, [x9, #16]
    mov w11, w16
    mov w10, #2
    cmp w21, #1
    b.eq .Lsema_part_var_add
    mov w10, #3
    cmp w21, #3
    b.eq .Lsema_part_var_add
    mov w10, #4
.Lsema_part_var_add:
    bl new_piece
    b .Lsema_part_next
.Lsema_part_expr:
    eor w26, w26, w26
    mov x11, x19
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    subs x11, x11, x16
    lsr x17, x11, #4
    mov x11, x17
    mov w10, #5
    bl new_piece
.Lsema_part_next:
    adds w25, w25, #1
    b .Lsema_part

.Lsema_parts_done:
    ldurh w16, [x23, #2]
    cmp w16, #0
    b.ne .Lsema_out_count
    tst x26, x26
    b.ne .Lsema_crlf
    mov w10, #1
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    mov x11, x16
    bl new_piece
    mov x26, x9
.Lsema_crlf:
    adrp x8, s_crlf
    add x8, x8, :lo12:s_crlf
    add x10, x8, #0
    mov w11, #2
    bl pool_add
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    mov x9, x16
    ldur w16, [x26, #4]
    subs w9, w9, w16
    stur w9, [x26, #8]
.Lsema_out_count:
    adrp x8, sm_carry
    add x8, x8, :lo12:sm_carry
    str x26, [x8]
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    ldr x16, [x8]
    mov x9, x16
    ldur w16, [x23, #28]
    subs w9, w9, w16
    stur w9, [x23, #24]

.Lsema_next:
    adds x23, x23, #32
    b .Lsema_stmt
.Lsema_finish:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

    RODATA
s_minus_char:
    .ascii "-"

    .bss
    .p2align 3
pc_new:
    .zero (1) * 8
pc_len:
    .zero (1) * 8
pc_tab:
    .zero (1) * 8
pc_mask:
    .zero (1) * 8

    .text

FUNC pool_compact
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    ldr x16, [x8]
    mov x10, x16
    adds x10, x10, #16
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, pc_new
    add x8, x8, :lo12:pc_new
    str x9, [x8]
    mov x17, #0
    adrp x8, pc_len
    add x8, x8, :lo12:pc_len
    str x17, [x8]
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    ldr x16, [x8]
    mov x10, x16
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    ldr x16, [x8]
    adds x10, x10, x16
    lsl x17, x10, #1
    mov x10, x17
    mov w9, #16
.Lpool_compact_cap:
    cmp x9, x10
    b.hs .Lpool_compact_cap_ok
    lsl x17, x9, #1
    mov x9, x17
    b .Lpool_compact_cap
.Lpool_compact_cap_ok:
    sub x11, x9, #1
    adrp x8, pc_mask
    add x8, x8, :lo12:pc_mask
    str x11, [x8]
    lsl x17, x9, #4
    mov x9, x17
    mov x10, x9
    mov x0, x10
    bl mem_alloc
    mov x9, x0
    adrp x8, pc_tab
    add x8, x8, :lo12:pc_tab
    str x9, [x8]

    adrp x8, g_pieces
    add x8, x8, :lo12:g_pieces
    ldr x16, [x8]
    mov x23, x16
    adrp x8, g_npieces
    add x8, x8, :lo12:g_npieces
    ldr x16, [x8]
    mov x24, x16
    lsl x17, x24, #4
    mov x24, x17
    adds x24, x24, x23
.Lpool_compact_pieces:
    cmp x23, x24
    b.hs .Lpool_compact_stmts
    ldur w16, [x23, #0]
    cmp w16, #1
    b.ne .Lpool_compact_piece_next
    ldur w16, [x23, #4]
    mov w10, w16
    ldur w16, [x23, #8]
    mov w11, w16
    bl intern
    stur w9, [x23, #4]
.Lpool_compact_piece_next:
    adds x23, x23, #16
    b .Lpool_compact_pieces

.Lpool_compact_stmts:
    adrp x8, g_stmts
    add x8, x8, :lo12:g_stmts
    ldr x16, [x8]
    mov x23, x16
    adrp x8, g_nstmt
    add x8, x8, :lo12:g_nstmt
    ldr x16, [x8]
    mov x24, x16
    lsl x17, x24, #5
    mov x24, x17
    adds x24, x24, x23
.Lpool_compact_stmt:
    cmp x23, x24
    b.hs .Lpool_compact_done
    ldurh w16, [x23, #0]
    cmp w16, #3
    b.eq .Lpool_compact_stmt_next
    ldurh w16, [x23, #0]
    cmp w16, #4
    b.eq .Lpool_compact_stmt_if
    ldur w16, [x23, #12]
    cmp w16, #0
    b.eq .Lpool_compact_stmt_next
    ldur w16, [x23, #16]
    mov w9, w16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w9, w16
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x25, x9
    mov x10, x25
    bl intern_tree
    b .Lpool_compact_stmt_next
.Lpool_compact_stmt_if:
    ldur w16, [x23, #16]
    mov w9, w16
    adrp x8, g_roots
    add x8, x8, :lo12:g_roots
    ldr x16, [x8]
    mov x11, x16
    mov x8, x11
    add x8, x8, x9, lsl #2
    ldr w16, [x8]
    mov w9, w16
    lsl x17, x9, #4
    mov x9, x17
    adrp x8, g_parts
    add x8, x8, :lo12:g_parts
    ldr x16, [x8]
    adds x9, x9, x16
    mov x10, x9
    bl intern_tree
.Lpool_compact_stmt_next:
    adds x23, x23, #32
    b .Lpool_compact_stmt
.Lpool_compact_done:
    adrp x8, pc_new
    add x8, x8, :lo12:pc_new
    ldr x16, [x8]
    mov x9, x16
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    str x9, [x8]
    adrp x8, pc_len
    add x8, x8, :lo12:pc_len
    ldr x16, [x8]
    mov x9, x16
    adrp x8, g_pool_len
    add x8, x8, :lo12:g_pool_len
    str x9, [x8]
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

FUNC intern
    mov w23, w10
    mov w24, w11
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    ldr x16, [x8]
    mov x20, x16
    adds x20, x20, x23
    ldr x13, =1099511628211
    mov x19, x24
    mul x17, x19, x13
    mov x19, x17
    eor w10, w10, w10
.Lintern_hash:
    cmp x10, x24
    b.hs .Lintern_hashed
    mov x8, x20
    add x8, x8, x10, lsl #0
    ldr x16, [x8]
    mov x9, x16
    mov x11, x24
    subs x11, x11, x10
    cmp x11, #8
    b.hs .Lintern_hash_full
    str x10, [sp, #-16]!
    ubfiz x8, x11, #3, #32
    add x10, x8, #0
    mov w10, w10
    ldr x11, =18446744073709551615
    lsl x17, x11, x10
    mov x11, x17
    mvn x17, x11
    mov x11, x17
    ands x9, x9, x11
    ldr x10, [sp], #16
.Lintern_hash_full:
    eor x19, x19, x9
    mul x17, x19, x13
    mov x19, x17
    adds x10, x10, #8
    b .Lintern_hash
.Lintern_hashed:
    mov x25, x19
    adrp x8, pc_mask
    add x8, x8, :lo12:pc_mask
    ldr x16, [x8]
    ands x25, x25, x16
.Lintern_probe:
    mov x26, x25
    lsl x17, x26, #4
    mov x26, x17
    adrp x8, pc_tab
    add x8, x8, :lo12:pc_tab
    ldr x16, [x8]
    adds x26, x26, x16
    ldur w16, [x26, #8]
    mov w9, w16
    tst w9, w9
    b.eq .Lintern_insert
    ldur x16, [x26, #0]
    cmp x16, x19
    b.ne .Lintern_next
    ldur w16, [x26, #12]
    cmp w16, w24
    b.ne .Lintern_next
    sub x21, x9, #1
    adrp x8, pc_new
    add x8, x8, :lo12:pc_new
    ldr x16, [x8]
    adds x21, x21, x16
    eor w10, w10, w10
.Lintern_cmp_loop:
    cmp x10, x24
    b.hs .Lintern_cmp_equal
    mov x8, x20
    add x8, x8, x10, lsl #0
    ldr x16, [x8]
    mov x9, x16
    mov x8, x21
    add x8, x8, x10, lsl #0
    ldr x16, [x8]
    eor x9, x9, x16
    mov x11, x24
    subs x11, x11, x10
    cmp x11, #8
    b.hs .Lintern_cmp_full
    str x10, [sp, #-16]!
    ubfiz x8, x11, #3, #32
    add x10, x8, #0
    mov w10, w10
    ldr x11, =18446744073709551615
    lsl x17, x11, x10
    mov x11, x17
    mvn x17, x11
    mov x11, x17
    ands x9, x9, x11
    ldr x10, [sp], #16
.Lintern_cmp_full:
    tst x9, x9
    b.ne .Lintern_next
    adds x10, x10, #8
    b .Lintern_cmp_loop
.Lintern_cmp_equal:
    ldur w16, [x26, #8]
    mov w9, w16
    subs w9, w9, #1
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lintern_next:
    adds x25, x25, #1
    adrp x8, pc_mask
    add x8, x8, :lo12:pc_mask
    ldr x16, [x8]
    ands x25, x25, x16
    b .Lintern_probe
.Lintern_insert:
    adrp x8, pc_new
    add x8, x8, :lo12:pc_new
    ldr x16, [x8]
    mov x21, x16
    adrp x8, pc_len
    add x8, x8, :lo12:pc_len
    ldr x16, [x8]
    adds x21, x21, x16
    mov x10, x24
    cbz x10, .Lrep_intern_1e
.Lrep_intern_1:
    ldrb w16, [x20], #1
    strb w16, [x21], #1
    subs x10, x10, #1
    b.ne .Lrep_intern_1
.Lrep_intern_1e:
    adrp x8, pc_len
    add x8, x8, :lo12:pc_len
    ldr x16, [x8]
    mov x9, x16
    stur x19, [x26, #0]
    add x11, x9, #1
    mov w11, w11
    stur w11, [x26, #8]
    stur w24, [x26, #12]
    adrp x8, pc_len
    add x8, x8, :lo12:pc_len
    ldr x17, [x8]
    adds x17, x17, x24
    adrp x8, pc_len
    add x8, x8, :lo12:pc_len
    str x17, [x8]
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

make_bool_const:
    stp x29, x30, [sp, #-16]!
    mov w17, #3
    sturb w17, [x19, #0]
    mov w17, #3
    sturb w17, [x19, #2]
    mov w17, #0
    sturb w17, [x19, #1]
    mov w17, #0
    sturb w17, [x19, #3]
    stur x9, [x19, #8]
    ldp x29, x30, [sp], #16
    ret

pool_equal:
    stp x29, x30, [sp, #-16]!
    ldur w16, [x10, #12]
    mov w9, w16
    ldur w17, [x11, #12]
    cmp w9, w17
    b.ne .Lpool_equal_no
    ldur w16, [x10, #8]
    mov w12, w16
    ldur w16, [x11, #8]
    mov w13, w16
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    ldr x16, [x8]
    adds x12, x12, x16
    adrp x8, g_pool
    add x8, x8, :lo12:g_pool
    ldr x16, [x8]
    adds x13, x13, x16
    eor w14, w14, w14
.Lpool_equal_loop:
    cmp w14, w9
    b.hs .Lpool_equal_yes
    mov x8, x12
    add x8, x8, x14, lsl #0
    ldr w17, [x8]
    bfi x15, x17, #0, #8
    and w16, w15, #0xff
    mov x8, x13
    add x8, x8, x14, lsl #0
    ldr w17, [x8]
    cmp w16, w17
    b.ne .Lpool_equal_no
    adds w14, w14, #1
    b .Lpool_equal_loop
.Lpool_equal_yes:
    mov w9, #1
    ldp x29, x30, [sp], #16
    ret
.Lpool_equal_no:
    eor w9, w9, w9
    ldp x29, x30, [sp], #16
    ret

FUNC check_cond
    mov x19, x10
    ldurb w16, [x19, #0]
    cmp w16, #8
    b.eq .Lcheck_cond_or
    ldurb w16, [x19, #0]
    cmp w16, #9
    b.eq .Lcheck_cond_and
    ldurb w23, [x19, #1]
    ldur w16, [x19, #8]
    mov w10, w16
    bl node_ptr
    mov x24, x9
    mov x10, x24
    bl check_value
    mov w25, w9
    mov x10, x24
    bl value_finish
    ldur w16, [x19, #12]
    mov w10, w16
    bl node_ptr
    mov x26, x9
    mov x10, x26
    bl check_value
    mov w20, w9
    mov x10, x26
    bl value_finish
    cmp w23, #3
    b.hs .Lcheck_cond_ordered
    cmp w25, w20
    b.eq .Lcheck_cond_types_ok
    mov w9, w25
    orr w9, w9, w20
    cmp w25, #4
    b.eq .Lcheck_cond_one_null
    cmp w20, #4
    b.ne .Lcheck_cond_bad_compare
.Lcheck_cond_one_null:
    cmp w25, #2
    b.eq .Lcheck_cond_types_ok
    cmp w20, #2
    b.eq .Lcheck_cond_types_ok
    b .Lcheck_cond_bad_compare
.Lcheck_cond_ordered:
    cmp w25, #1
    b.ne .Lcheck_cond_bad_ordered_left
    cmp w20, #1
    b.ne .Lcheck_cond_bad_ordered_right
.Lcheck_cond_types_ok:
    mov w9, w25
    cmp w9, #4
    b.ne .Lcheck_cond_store_type
    mov w9, w20
.Lcheck_cond_store_type:
    and w17, w9, #0xff
    sturb w17, [x19, #2]
    ldurb w21, [x24, #0]
    ldurb w10, [x26, #0]
    cmp w9, #2
    b.eq .Lcheck_cond_fold_str
    cmp w9, #4
    b.eq .Lcheck_cond_fold_null_null
    cmp w21, w10
    b.ne .Lcheck_cond_done
    cmp w21, #1
    b.eq .Lcheck_cond_fold_num
    cmp w21, #3
    b.eq .Lcheck_cond_fold_num
    b .Lcheck_cond_done
.Lcheck_cond_fold_num:
    ldur x16, [x24, #8]
    mov x12, x16
    ldur x16, [x26, #8]
    mov x13, x16
    eor w9, w9, w9
    cmp w23, #1
    b.eq .Lcheck_cond_f_is
    cmp w23, #2
    b.eq .Lcheck_cond_f_isnot
    cmp w23, #3
    b.eq .Lcheck_cond_f_lt
    cmp w23, #5
    b.eq .Lcheck_cond_f_le
    cmp w23, #6
    b.eq .Lcheck_cond_f_ge
    cmp x12, x13
    cset w16, gt
    bfi x9, x16, #0, #8
    b .Lcheck_cond_fold_set
.Lcheck_cond_f_is:
    cmp x12, x13
    cset w16, eq
    bfi x9, x16, #0, #8
    b .Lcheck_cond_fold_set
.Lcheck_cond_f_isnot:
    cmp x12, x13
    cset w16, ne
    bfi x9, x16, #0, #8
    b .Lcheck_cond_fold_set
.Lcheck_cond_f_lt:
    cmp x12, x13
    cset w16, lt
    bfi x9, x16, #0, #8
    b .Lcheck_cond_fold_set
.Lcheck_cond_f_le:
    cmp x12, x13
    cset w16, le
    bfi x9, x16, #0, #8
    b .Lcheck_cond_fold_set
.Lcheck_cond_f_ge:
    cmp x12, x13
    cset w16, ge
    bfi x9, x16, #0, #8
    b .Lcheck_cond_fold_set
.Lcheck_cond_fold_null_null:
    mov w9, #1
    b .Lcheck_cond_fold_eq
.Lcheck_cond_fold_str:
    cmp w21, #5
    b.eq .Lcheck_cond_done
    cmp w10, #5
    b.eq .Lcheck_cond_done
    cmp w21, w10
    b.ne .Lcheck_cond_fold_diff
    cmp w21, #4
    b.eq .Lcheck_cond_fold_same
    mov x10, x24
    mov x11, x26
    bl pool_equal
    b .Lcheck_cond_fold_eq
.Lcheck_cond_fold_same:
    mov w9, #1
    b .Lcheck_cond_fold_eq
.Lcheck_cond_fold_diff:
    eor w9, w9, w9
.Lcheck_cond_fold_eq:
    cmp w23, #2
    b.ne .Lcheck_cond_fold_set
    mov w16, #1
    eor w9, w9, w16
.Lcheck_cond_fold_set:
    uxtb w9, w9
    bl make_bool_const
.Lcheck_cond_done:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

.Lcheck_cond_or:
    ldur w16, [x19, #8]
    mov w10, w16
    bl node_ptr
    mov x24, x9
    mov x10, x24
    bl check_cond
    ldur w16, [x19, #12]
    mov w10, w16
    bl node_ptr
    mov x26, x9
    mov x10, x26
    bl check_cond
    ldurb w16, [x24, #0]
    cmp w16, #3
    b.ne .Lcheck_cond_or_right
    ldur x16, [x24, #8]
    cmp x16, #0
    b.ne .Lcheck_cond_or_true
    mov x10, x26
    bl copy_node
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lcheck_cond_or_right:
    ldurb w16, [x26, #0]
    cmp w16, #3
    b.ne .Lcheck_cond_or_done
    ldur x16, [x26, #8]
    cmp x16, #0
    b.ne .Lcheck_cond_or_true
    mov x10, x24
    bl copy_node
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lcheck_cond_or_true:
    mov w9, #1
    bl make_bool_const
.Lcheck_cond_or_done:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

.Lcheck_cond_and:
    ldur w16, [x19, #8]
    mov w10, w16
    bl node_ptr
    mov x24, x9
    mov x10, x24
    bl check_cond
    ldur w16, [x19, #12]
    mov w10, w16
    bl node_ptr
    mov x26, x9
    mov x10, x26
    bl check_cond
    ldurb w16, [x24, #0]
    cmp w16, #3
    b.ne .Lcheck_cond_and_right
    ldur x16, [x24, #8]
    cmp x16, #0
    b.eq .Lcheck_cond_and_false
    mov x10, x26
    bl copy_node
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lcheck_cond_and_right:
    ldurb w16, [x26, #0]
    cmp w16, #3
    b.ne .Lcheck_cond_and_done
    ldur x16, [x26, #8]
    cmp x16, #0
    b.eq .Lcheck_cond_and_false
    mov x10, x24
    bl copy_node
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret
.Lcheck_cond_and_false:
    eor w9, w9, w9
    bl make_bool_const
.Lcheck_cond_and_done:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

.Lcheck_cond_bad_ordered_left:
    mov w20, w25
.Lcheck_cond_bad_ordered_right:
    bl msg_reset
    adrp x8, s_operator
    add x8, x8, :lo12:s_operator
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    adrp x8, cmp_chars
    add x8, x8, :lo12:cmp_chars
    add x9, x8, #0
    mov x8, x9
    add x8, x8, x23, lsl #0
    ldr w17, [x8]
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
    cmp w23, #5
    b.lo .Lcheck_cond_op_done
    mov w17, #61
    bfi x10, x17, #0, #8
    mov x0, x10
    bl msg_addc
.Lcheck_cond_op_done:
    adrp x8, s_needs_bin
    add x8, x8, :lo12:s_needs_bin
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w20
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    adrp x8, s_type
    add x8, x8, :lo12:s_type
    add x10, x8, #0
    ldur w16, [x19, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

.Lcheck_cond_bad_compare:
    bl msg_reset
    adrp x8, s_cmp1
    add x8, x8, :lo12:s_cmp1
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w25
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    adrp x8, s_with
    add x8, x8, :lo12:s_with
    add x10, x8, #0
    mov x0, x10
    bl msg_addz
    mov w10, w20
    bl type_name
    mov x10, x9
    mov x0, x10
    bl msg_addz
    adrp x8, s_type
    add x8, x8, :lo12:s_type
    add x10, x8, #0
    ldur w16, [x19, #4]
    mov w11, w16
    mov x0, x10
    mov x1, x11
    bl diag_error_tok

FUNC intern_tree
    mov x19, x10
    ldurb w9, [x19, #0]
    cmp w9, #7
    b.eq .Lintern_tree_pair
    cmp w9, #8
    b.eq .Lintern_tree_pair
    cmp w9, #9
    b.eq .Lintern_tree_pair
    cmp w9, #2
    b.ne .Lintern_tree_done
    ldurb w16, [x19, #1]
    cmp w16, #0
    b.ne .Lintern_tree_done
    ldur w16, [x19, #8]
    mov w10, w16
    ldur w16, [x19, #12]
    mov w11, w16
    bl intern
    stur w9, [x19, #8]
    mov w17, #1
    sturb w17, [x19, #1]
    b .Lintern_tree_done
.Lintern_tree_pair:
    ldur w16, [x19, #8]
    mov w10, w16
    bl node_ptr
    mov x10, x9
    bl intern_tree
    ldur w16, [x19, #12]
    mov w10, w16
    bl node_ptr
    mov x10, x9
    bl intern_tree
.Lintern_tree_done:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #96
    ret

block_is_loop:
    stp x29, x30, [sp, #-16]!
    adrp x8, sm_bdepth
    add x8, x8, :lo12:sm_bdepth
    ldr x16, [x8]
    mov x9, x16
    adrp x8, sm_bkind
    add x8, x8, :lo12:sm_bkind
    add x11, x8, #0
    mov x8, x11
    add x8, x8, x9, lsl #3
    sub x8, x8, #8
    ldr x16, [x8]
    cmp x16, #2
    ldp x29, x30, [sp], #16
    ret

