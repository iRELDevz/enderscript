#include "defs.h"

    RODATA
s_semantic:   .asciz "semantic"
s_type:       .asciz "type"
s_undef:      .asciz "undefined variable '"
s_quote:      .asciz "'"
s_var_q:      .asciz "variable '"
s_already_as: .asciz "' is already declared as "
s_an_int:     .asciz "an int variable"
s_a_str:      .asciz "a str variable"
s_a_bool:     .asciz "a bool variable"
s_already_at: .asciz "' is already declared at line "
s_latest:     .asciz ", the latest declaration claims the value"
s_cannot:     .asciz "cannot assign "
s_to:         .asciz " to "
s_variable_q: .asciz " variable '"
s_int_lit:    .asciz "int literal "
s_outside:    .asciz " is outside -2147483648..2147483647"
s_str_long:   .asciz "string is longer than 65535 bytes"
s_mode1:      .asciz "unknown print mode '."
s_mode2:      .asciz "', expected '.s'"
s_tn_int:     .asciz "int"
s_tn_str:     .asciz "str"
s_tn_bool:    .asciz "bool"
s_tn_null:    .asciz "null"
s_true:       .ascii "true"
s_false:      .ascii "false"
s_null:       .ascii "null"
s_minus:      .ascii "-"
#if defined(TARGET_WINDOWS)
s_nl:         .ascii "\r\n"
#define NL_LEN 2
#else
s_nl:         .ascii "\n"
#define NL_LEN 1
#endif

    .bss
    .p2align 3
last_slot: .zero 8
last_hash: .zero 8

    .text

LEAF tok_text
    LDX x9, g_tokens
    add x9, x9, w0, uxtw #4
    ldr w10, [x9, #T_OFF]
    ldr w1, [x9, #T_LEN]
    LDX x11, g_src
    add x0, x11, x10
    ret

LEAF tok_line
    LDX x9, g_tokens
    add x9, x9, w0, uxtw #4
    ldr w0, [x9, #T_LINE]
    ret

LEAF type_name
    cmp w0, #TY_INT
    b.ne 1f
    LA x0, s_tn_int
    ret
1:  cmp w0, #TY_STR
    b.ne 2f
    LA x0, s_tn_str
    ret
2:  cmp w0, #TY_BOOL
    b.ne 3f
    LA x0, s_tn_bool
    ret
3:  LA x0, s_tn_null
    ret

LEAF pool_add
    LDX x9, g_pool
    LDX x10, g_pool_len
    add x9, x9, x10
    add x10, x10, x1
    STX x10, g_pool_len
1:  cbz x1, 2f
    ldrb w11, [x0], #1
    strb w11, [x9], #1
    sub x1, x1, #1
    b 1b
2:  ret

LEAF new_piece
    LDX x9, g_npieces
    add x10, x9, #1
    STX x10, g_npieces
    LDX x10, g_pieces
    add x9, x10, x9, lsl #4
    str w0, [x9, #P_KIND]
    str w1, [x9, #P_A]
    str wzr, [x9, #P_B]
    mov x0, x9
    ret

LEAF value_pos
    ldrb w9, [x0, #V_NEG]
    ldr w10, [x0, #V_TOK]
    sub w0, w10, w9
    ret

FUNC var_lookup
    bl tok_text
    mov x19, x0
    mov x20, x1
    movz x21, #0x2325
    movk x21, #0x8422, lsl #16
    movk x21, #0x9ce4, lsl #32
    movk x21, #0xcbf2, lsl #48
    movz x22, #0x01b3
    movk x22, #0x0100, lsl #32
    mov x9, #0
1:  cmp x9, x20
    b.hs 2f
    ldrb w10, [x19, x9]
    eor x21, x21, x10
    mul x21, x21, x22
    add x9, x9, #1
    b 1b
2:  STX x21, last_hash
    LDX x23, g_hmask
    and x24, x21, x23
    LDX x25, g_htab
.Lvl_probe:
    add x9, x25, x24, lsl #2
    STX x9, last_slot
    ldr w26, [x9]
    cbz w26, .Lvl_missing
    sub w26, w26, #1
    LDX x9, g_vars
    add x27, x9, x26, lsl #5
    ldr x9, [x27, #VR_HASH]
    cmp x9, x21
    b.ne .Lvl_next
    ldr w0, [x27, #VR_TOK]
    bl tok_text
    cmp x1, x20
    b.ne .Lvl_next
    mov x9, #0
3:  cmp x9, x20
    b.hs .Lvl_found
    ldrb w10, [x0, x9]
    ldrb w11, [x19, x9]
    cmp w10, w11
    b.ne .Lvl_next
    add x9, x9, #1
    b 3b
.Lvl_found:
    mov w0, w26
    ENDF
.Lvl_next:
    add x24, x24, #1
    and x24, x24, x23
    b .Lvl_probe
.Lvl_missing:
    mov x0, #-1
    ENDF

FUNC var_insert
    mov w19, w0
    mov w20, w1
    bl var_lookup
    LDX x21, g_nvars
    add x9, x21, #1
    STX x9, g_nvars
    LDX x9, last_slot
    add w10, w21, #1
    str w10, [x9]
    LDX x9, g_vars
    add x22, x9, x21, lsl #5
    LDX x9, last_hash
    str x9, [x22, #VR_HASH]
    str w19, [x22, #VR_TOK]
    strh w20, [x22, #VR_TYPE]
    mov x9, #4
    mov x10, #4
    cmp w20, #TY_INT
    b.eq 1f
    mov x9, #1
    mov x10, #1
    cmp w20, #TY_BOOL
    b.eq 1f
    mov x9, #16
    mov x10, #16
1:  LDX x11, g_vars_size
    add x11, x11, x9
    sub x11, x11, #1
    neg x12, x9
    and x11, x11, x12
    str w11, [x22, #VR_OFF]
    add x11, x11, x10
    STX x11, g_vars_size
    mov w0, w21
    ENDF

FUNC check_value
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_INT
    b.eq .Lcv_int
    cmp w9, #VK_STR
    b.eq .Lcv_str
    cmp w9, #VK_VAR
    b.eq .Lcv_var
    mov w20, #TY_BOOL
    cmp w9, #VK_BOOL
    b.eq .Lcv_done
    mov w20, #TY_NULL
    b .Lcv_done

.Lcv_int:
    mov w20, #TY_INT
    ldr w0, [x19, #V_TOK]
    bl tok_text
    mov x9, #0
    mov x10, #0
    mov x11, #0xFFFFFFFF
    mov x13, #10
1:  cmp x9, x1
    b.hs 2f
    ldrb w12, [x0, x9]
    sub w12, w12, #'0'
    add x9, x9, #1
    cmp x10, x11
    b.hi 1b
    madd x10, x10, x13, x12
    b 1b
2:  ldrb w12, [x19, #V_NEG]
    cbnz w12, 3f
    MOV32 x11, 2147483647
    cmp x10, x11
    b.hi .Lcv_int_bad
    str x10, [x19, #V_DATA]
    b .Lcv_done
3:  MOV32 x11, 2147483648
    cmp x10, x11
    b.hi .Lcv_int_bad
    neg x10, x10
    str x10, [x19, #V_DATA]
    b .Lcv_done
.Lcv_int_bad:
    mov w9, #1
    strb w9, [x19, #V_BAD]
    b .Lcv_done

.Lcv_str:
    mov w20, #TY_STR
    ldr w0, [x19, #V_TOK]
    bl tok_text
    add x9, x0, #1
    add x10, x0, x1
    sub x10, x10, #1
    LDX x21, g_pool_len
    LDX x11, g_pool
    add x11, x11, x21
    mov x12, x11
4:  cmp x9, x10
    b.hs 6f
    ldrb w13, [x9], #1
    cmp w13, #'\\'
    b.ne 5f
    ldrb w13, [x9], #1
    cmp w13, #'n'
    b.ne 7f
    mov w13, #10
    b 5f
7:  cmp w13, #'t'
    b.ne 8f
    mov w13, #9
    b 5f
8:  cmp w13, #'r'
    b.ne 9f
    mov w13, #13
    b 5f
9:  cmp w13, #'0'
    b.ne 5f
    mov w13, #0
5:  strb w13, [x12], #1
    b 4b
6:  sub x12, x12, x11
    add x9, x21, x12
    STX x9, g_pool_len
    str w21, [x19, #V_DATA]
    str w12, [x19, #V_DATA_HI]
    mov x9, #65535
    cmp x12, x9
    b.ls .Lcv_done
    mov w9, #1
    strb w9, [x19, #V_BAD]
    b .Lcv_done

.Lcv_var:
    ldr w0, [x19, #V_TOK]
    bl var_lookup
    cmn x0, #1
    b.eq .Lcv_undefined
    str x0, [x19, #V_DATA]
    LDX x9, g_vars
    add x9, x9, x0, lsl #5
    ldrh w20, [x9, #VR_TYPE]
    b .Lcv_done
.Lcv_undefined:
    bl msg_reset
    LA x0, s_undef
    bl msg_addz
    ldr w0, [x19, #V_TOK]
    bl msg_tok
    LA x0, s_quote
    bl msg_addz
    LA x0, s_semantic
    ldr w1, [x19, #V_TOK]
    bl diag_error_tok

.Lcv_done:
    strb w20, [x19, #V_TYPE]
    mov w0, w20
    ENDF

FUNC value_finish
    mov x19, x0
    ldrb w9, [x19, #V_BAD]
    cbz w9, .Lvf_ok
    bl msg_reset
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Lvf_str
    LA x0, s_int_lit
    bl msg_addz
    ldrb w9, [x19, #V_NEG]
    cbz w9, 1f
    mov w0, #'-'
    bl msg_addc
1:  ldr w0, [x19, #V_TOK]
    bl msg_tok
    LA x0, s_outside
    bl msg_addz
    b .Lvf_err
.Lvf_str:
    LA x0, s_str_long
    bl msg_addz
.Lvf_err:
    mov x0, x19
    bl value_pos
    mov w1, w0
    LA x0, s_type
    bl diag_error_tok
.Lvf_ok:
    ENDF

FUNC check_assign
    mov x19, x0
    mov w20, w1
    mov w21, w2
    bl check_value
    cmp w0, w20
    b.eq .Lca_ok
    cmp w0, #TY_NULL
    b.ne .Lca_bad
    cmp w20, #TY_STR
    b.eq .Lca_ok
.Lca_bad:
    mov w22, w0
    bl msg_reset
    LA x0, s_cannot
    bl msg_addz
    mov w0, w22
    bl type_name
    bl msg_addz
    LA x0, s_to
    bl msg_addz
    mov w0, w20
    bl type_name
    bl msg_addz
    LA x0, s_variable_q
    bl msg_addz
    mov w0, w21
    bl msg_tok
    LA x0, s_quote
    bl msg_addz
    mov x0, x19
    bl value_pos
    mov w1, w0
    LA x0, s_type
    bl diag_error_tok
.Lca_ok:
    mov x0, x19
    bl value_finish
    ENDF

FUNC sema
    LDX x0, g_nstmt
    add x0, x0, #1
    lsl x0, x0, #5
    bl mem_alloc
    STX x0, g_vars
    STX xzr, g_nvars
    LDX x9, g_nstmt
    add x9, x9, #1
    lsl x9, x9, #1
    mov x10, #16
1:  cmp x10, x9
    b.hs 2f
    lsl x10, x10, #1
    b 1b
2:  sub x11, x10, #1
    STX x11, g_hmask
    lsl x0, x10, #2
    bl mem_alloc
    STX x0, g_htab
    LDX x0, g_src_len
    lsl x0, x0, #1
    add x0, x0, #4096
    bl mem_alloc
    STX x0, g_pool
    STX xzr, g_pool_len
    LDX x0, g_nparts
    LDX x9, g_nstmt
    add x0, x0, x9
    add x0, x0, #1
    lsl x0, x0, #4
    bl mem_alloc
    STX x0, g_pieces
    STX xzr, g_npieces
    STX xzr, g_vars_size

    LDX x19, g_stmts
    LDX x20, g_nstmt
    add x20, x19, x20, lsl #5
.Lsm_stmt:
    cmp x19, x20
    b.hs .Lsm_finish
    ldrh w9, [x19, #S_KIND]
    cmp w9, #SK_DECL
    b.eq .Lsm_decl
    cmp w9, #SK_ASSIGN
    b.eq .Lsm_assign
    b .Lsm_out

.Lsm_decl:
    ldr w0, [x19, #S_TOK]
    bl var_lookup
    mov x21, x0
    cmn x0, #1
    b.eq .Lsm_decl_value
    LDX x9, g_vars
    add x22, x9, x0, lsl #5
    ldrh w9, [x22, #VR_TYPE]
    ldrh w10, [x19, #S_MODE]
    cmp w9, w10
    b.ne .Lsm_redecl_type
    bl msg_reset
    LA x0, s_var_q
    bl msg_addz
    ldr w0, [x19, #S_TOK]
    bl msg_tok
    LA x0, s_already_at
    bl msg_addz
    ldr w0, [x22, #VR_LINE]
    bl msg_addu
    LA x0, s_latest
    bl msg_addz
    ldr w0, [x19, #S_TOK]
    bl diag_warn_tok
.Lsm_decl_value:
    ldr w9, [x19, #S_NPARTS]
    cbz w9, .Lsm_decl_store
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_parts
    add x0, x10, x9, lsl #4
    ldrh w1, [x19, #S_MODE]
    ldr w2, [x19, #S_TOK]
    bl check_assign
.Lsm_decl_store:
    cmn x21, #1
    b.ne .Lsm_decl_known
    ldr w0, [x19, #S_TOK]
    ldrh w1, [x19, #S_MODE]
    bl var_insert
    mov x21, x0
.Lsm_decl_known:
    str w21, [x19, #S_VAR]
    ldr w0, [x19, #S_TOK]
    bl tok_line
    LDX x9, g_vars
    add x9, x9, x21, lsl #5
    str w0, [x9, #VR_LINE]
    b .Lsm_next

.Lsm_redecl_type:
    mov w23, w9
    bl msg_reset
    LA x0, s_var_q
    bl msg_addz
    ldr w0, [x19, #S_TOK]
    bl msg_tok
    LA x0, s_already_as
    bl msg_addz
    LA x0, s_an_int
    cmp w23, #TY_INT
    b.eq 3f
    LA x0, s_a_str
    cmp w23, #TY_STR
    b.eq 3f
    LA x0, s_a_bool
3:  bl msg_addz
    LA x0, s_semantic
    ldr w1, [x19, #S_TOK]
    bl diag_error_tok

.Lsm_assign:
    ldr w0, [x19, #S_TOK]
    bl var_lookup
    cmn x0, #1
    b.ne .Lsm_assign_ok
    bl msg_reset
    LA x0, s_undef
    bl msg_addz
    ldr w0, [x19, #S_TOK]
    bl msg_tok
    LA x0, s_quote
    bl msg_addz
    LA x0, s_semantic
    ldr w1, [x19, #S_TOK]
    bl diag_error_tok
.Lsm_assign_ok:
    str w0, [x19, #S_VAR]
    LDX x9, g_vars
    add x9, x9, x0, lsl #5
    ldrh w1, [x9, #VR_TYPE]
    strh w1, [x19, #S_MODE]
    ldr w9, [x19, #S_NPARTS]
    cbz w9, .Lsm_next
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_parts
    add x0, x10, x9, lsl #4
    ldr w2, [x19, #S_TOK]
    bl check_assign
    b .Lsm_next

.Lsm_out:
    ldr w0, [x19, #S_MODETOK]
    cmn w0, #1
    b.eq .Lsm_out_parts
    bl tok_text
    cmp x1, #1
    b.ne .Lsm_bad_mode
    ldrb w9, [x0]
    cmp w9, #'s'
    b.eq .Lsm_out_parts
.Lsm_bad_mode:
    bl msg_reset
    LA x0, s_mode1
    bl msg_addz
    ldr w0, [x19, #S_MODETOK]
    bl msg_tok
    LA x0, s_mode2
    bl msg_addz
    LA x0, s_semantic
    ldr w1, [x19, #S_MODETOK]
    sub w1, w1, #1
    bl diag_error_tok

.Lsm_out_parts:
    LDX x9, g_npieces
    str w9, [x19, #S_PIECES]
    mov x24, #0
    mov w25, #0
.Lsm_part:
    ldr w9, [x19, #S_NPARTS]
    cmp w25, w9
    b.hs .Lsm_parts_done
    ldr w9, [x19, #S_PARTS]
    add w9, w9, w25
    LDX x10, g_parts
    add x22, x10, x9, lsl #4
    LDX x26, g_pool_len
    mov x0, x22
    bl check_value
    mov w23, w0
    mov x0, x22
    bl value_finish
    ldrb w9, [x22, #V_KIND]
    cmp w9, #VK_VAR
    b.eq .Lsm_part_var
    cmp w9, #VK_INT
    b.eq .Lsm_part_int
    cmp w9, #VK_BOOL
    b.eq .Lsm_part_bool
    cmp w9, #VK_NULL
    b.ne .Lsm_part_text
    LA x0, s_null
    mov x1, #4
    bl pool_add
    b .Lsm_part_text
.Lsm_part_bool:
    ldr x9, [x22, #V_DATA]
    cbz x9, 4f
    LA x0, s_true
    mov x1, #4
    bl pool_add
    b .Lsm_part_text
4:  LA x0, s_false
    mov x1, #5
    bl pool_add
    b .Lsm_part_text
.Lsm_part_int:
    ldr x27, [x22, #V_DATA]
    tbz x27, #63, 5f
    LA x0, s_minus
    mov x1, #1
    bl pool_add
    neg x27, x27
5:  mov x0, x27
    bl u64_to_dec
    bl pool_add
.Lsm_part_text:
    cbnz x24, 6f
    mov w0, #PK_TEXT
    mov w1, w26
    bl new_piece
    mov x24, x0
6:  LDX x9, g_pool_len
    ldr w10, [x24, #P_A]
    sub w9, w9, w10
    str w9, [x24, #P_B]
    b .Lsm_part_next
.Lsm_part_var:
    mov x24, #0
    ldr x9, [x22, #V_DATA]
    LDX x10, g_vars
    add x9, x10, x9, lsl #5
    ldr w1, [x9, #VR_OFF]
    mov w0, #PK_INT
    cmp w23, #TY_INT
    b.eq 7f
    mov w0, #PK_BOOL
    cmp w23, #TY_BOOL
    b.eq 7f
    mov w0, #PK_STR
7:  bl new_piece
.Lsm_part_next:
    add w25, w25, #1
    b .Lsm_part

.Lsm_parts_done:
    ldrh w9, [x19, #S_MODE]
    cbnz w9, .Lsm_out_count
    cbnz x24, 8f
    mov w0, #PK_TEXT
    LDX x1, g_pool_len
    bl new_piece
    mov x24, x0
8:  LA x0, s_nl
    mov x1, #NL_LEN
    bl pool_add
    LDX x9, g_pool_len
    ldr w10, [x24, #P_A]
    sub w9, w9, w10
    str w9, [x24, #P_B]
.Lsm_out_count:
    LDX x9, g_npieces
    ldr w10, [x19, #S_PIECES]
    sub w9, w9, w10
    str w9, [x19, #S_NPIECES]

.Lsm_next:
    add x19, x19, #32
    b .Lsm_stmt
.Lsm_finish:
    ENDF
