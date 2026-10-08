#include "defs.h"

#define RT_FN_WRITE      0
#define RT_FN_WRITE_INT  4
#define RT_FN_WRITE_BOOL 8
#define RT_FN_WRITE_STR  12
#define RT_FN_FLUSH      16
#define RT_FN_DIV_ZERO   20

#define OP_STR_W   0xB9000000
#define OP_LDR_W   0xB9400000
#define OP_STR_X   0xF9000000
#define OP_LDR_X   0xF9400000
#define OP_STRB    0x39000000
#define OP_LDRB    0x39400000
#define OP_STRH    0x79000000
#define OP_LDRH    0x79400000

    .globl img_R_va, img_D_va, img_T_va, img_T_off, img_entry, img_bufoff, img_iat_va
    .bss
    .p2align 3
img_R_va:   .zero 8
img_D_va:   .zero 8
img_T_va:   .zero 8
img_T_off:  .zero 8
img_entry:  .zero 8
img_bufoff: .zero 8
img_iat_va: .zero 8
cg_pool_va: .zero 8
cg_line:    .zero 8
cg_depth:   .zero 8

    .text

.macro WORD imm
    MOV32 w0, \imm
    bl e_word
.endm

.macro LDST op, rt, rn, imm
    MOV32 w0, (\op) | ((\imm) << 10) | ((\rn) << 5) | (\rt)
    bl e_word
.endm

.macro CALL_RT idx
    LA x9, rt_offsets
    ldr w0, [x9, #\idx]
    bl e_bl
.endm

FUNC codegen
    bl img_layout
    LDX x27, g_image
    LDX x9, img_T_off
    add x27, x27, x9
    STX x27, enc_text_base
    LDX x9, img_T_va
    STX x9, enc_text_va
    LA x9, rt_start
    LA x10, rt_size
    ldr w10, [x10]
1:  cbz w10, 2f
    ldrb w11, [x9], #1
    strb w11, [x27], #1
    sub w10, w10, #1
    b 1b
2:  bl e_text_offset
    tst x0, #15
    b.eq 3f
    WORD 0xD503201F
    b 2b
3:  STX x0, img_entry

    LDX x9, img_R_va
    add x9, x9, #RC_SIZE
    STX x9, cg_pool_va

    mov w0, #28
    LDX x1, img_D_va
    bl e_adr_va
    mov w0, #9
    LDX x1, img_bufoff
    bl e_addr
    LDST OP_STR_X, 9, 28, 1
    mov w0, #9
    LDX x1, img_R_va
    bl e_adr_va
    LDST OP_STR_X, 9, 28, 4
#if defined(TARGET_WINDOWS)
    WORD 0x12800140
    mov w0, #16
    LDX x1, img_iat_va
    bl e_ldr_va
    WORD 0xD63F0200
    LDST OP_STR_X, 0, 28, 2
    mov w0, #16
    LDX x1, img_iat_va
    add x1, x1, #8
    bl e_ldr_va
    LDST OP_STR_X, 16, 28, 3
    mov w0, #16
    LDX x1, img_iat_va
    bl e_ldr_va
    LDST OP_STR_X, 16, 28, 6
    mov w0, #16
    LDX x1, img_iat_va
    add x1, x1, #16
    bl e_ldr_va
    LDST OP_STR_X, 16, 28, 7
#endif

    LDX x19, g_stmts
    LDX x20, g_nstmt
    add x20, x19, x20, lsl #5
.Lcg_stmt:
    cmp x19, x20
    b.hs .Lcg_epilogue
    ldr w9, [x19, #S_TOK]
    LDX x10, g_tokens
    add x9, x10, x9, lsl #4
    ldr w9, [x9, #T_LINE]
    STX x9, cg_line
    ldrh w9, [x19, #S_KIND]
    cmp w9, #SK_OUT
    b.eq .Lcg_out

    ldr w9, [x19, #S_VAR]
    LDX x10, g_vars
    add x9, x10, x9, lsl #5
    ldr w21, [x9, #VR_OFF]
    add w21, w21, #RT_VARS
    ldrh w22, [x19, #S_MODE]
    ldr w9, [x19, #S_NPARTS]
    cbz w9, .Lcg_default
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_roots
    ldr w9, [x10, x9, lsl #2]
    mov w24, w9
    LDX x10, g_parts
    add x23, x10, x9, lsl #4
    ldrb w9, [x23, #V_KIND]
    cmp w9, #VK_EXPR
    b.eq .Lcg_store_expr
    cmp w9, #VK_VAR
    b.eq .Lcg_copy
    cmp w9, #VK_NULL
    b.eq .Lcg_default
    cmp w9, #VK_STR
    b.eq .Lcg_store_str
    mov w0, #9
    ldr w1, [x23, #V_DATA]
    bl e_mov32
    mov w0, #10
    mov w1, w21
    bl e_addr
    cmp w22, #TY_BOOL
    b.eq 4f
    LDST OP_STR_W, 9, 10, 0
    b .Lcg_next
4:  LDST OP_STRB, 9, 10, 0
    b .Lcg_next

.Lcg_store_expr:
    mov w0, w24
    bl emit_expr
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_W, 0, 10, 0
    b .Lcg_next

.Lcg_store_str:
    mov w0, #9
    LDX x1, cg_pool_va
    ldr w9, [x23, #V_DATA]
    add x1, x1, x9
    bl e_adr_va
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_X, 9, 10, 0
    mov w0, #9
    ldr w1, [x23, #V_DATA_HI]
    bl e_mov32
    LDST OP_STRH, 9, 10, 4
    b .Lcg_next

.Lcg_default:
    mov w0, #10
    mov w1, w21
    bl e_addr
    cmp w22, #TY_INT
    b.ne 5f
    LDST OP_STR_W, 31, 10, 0
    b .Lcg_next
5:  cmp w22, #TY_BOOL
    b.ne 6f
    LDST OP_STRB, 31, 10, 0
    b .Lcg_next
6:  LDST OP_STR_X, 31, 10, 0
    LDST OP_STRH, 31, 10, 4
    b .Lcg_next

.Lcg_copy:
    ldr w9, [x23, #V_DATA]
    LDX x10, g_vars
    add x9, x10, x9, lsl #5
    ldr w24, [x9, #VR_OFF]
    add w24, w24, #RT_VARS
    mov w0, #10
    mov w1, w24
    bl e_addr
    cmp w22, #TY_INT
    b.ne 7f
    LDST OP_LDR_W, 9, 10, 0
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_W, 9, 10, 0
    b .Lcg_next
7:  cmp w22, #TY_BOOL
    b.ne 8f
    LDST OP_LDRB, 9, 10, 0
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STRB, 9, 10, 0
    b .Lcg_next
8:  LDST OP_LDR_X, 9, 10, 0
    LDST OP_LDRH, 11, 10, 4
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_X, 9, 10, 0
    LDST OP_STRH, 11, 10, 4
    b .Lcg_next

.Lcg_out:
    ldr w21, [x19, #S_PIECES]
    ldr w22, [x19, #S_NPIECES]
    add w22, w22, w21
.Lcg_piece:
    cmp w21, w22
    b.hs .Lcg_next
    LDX x9, g_pieces
    add x23, x9, x21, lsl #4
    add w21, w21, #1
    ldr w9, [x23, #P_KIND]
    cmp w9, #PK_TEXT
    b.ne .Lcg_piece_var
    ldr w9, [x23, #P_B]
    cbz w9, .Lcg_piece
    mov w0, #0
    LDX x1, cg_pool_va
    ldr w9, [x23, #P_A]
    add x1, x1, x9
    bl e_adr_va
    mov w0, #1
    ldr w1, [x23, #P_B]
    bl e_mov32
    CALL_RT RT_FN_WRITE
    b .Lcg_piece
.Lcg_piece_var:
    cmp w9, #PK_EXPR
    b.ne .Lcg_piece_plain
    ldr w0, [x23, #P_A]
    bl emit_expr
    CALL_RT RT_FN_WRITE_INT
    b .Lcg_piece
.Lcg_piece_plain:
    ldr w24, [x23, #P_A]
    add w24, w24, #RT_VARS
    cmp w9, #PK_STR
    b.eq .Lcg_piece_str
    mov w25, w9
    mov w0, #10
    mov w1, w24
    bl e_addr
    cmp w25, #PK_INT
    b.ne 9f
    LDST OP_LDR_W, 0, 10, 0
    CALL_RT RT_FN_WRITE_INT
    b .Lcg_piece
9:  LDST OP_LDRB, 0, 10, 0
    CALL_RT RT_FN_WRITE_BOOL
    b .Lcg_piece
.Lcg_piece_str:
    mov w0, #0
    mov w1, w24
    bl e_addr
    CALL_RT RT_FN_WRITE_STR
    b .Lcg_piece

.Lcg_next:
    add x19, x19, #32
    b .Lcg_stmt

.Lcg_epilogue:
    CALL_RT RT_FN_FLUSH
#if defined(TARGET_WINDOWS)
    WORD 0x52800000
    mov w0, #16
    LDX x1, img_iat_va
    add x1, x1, #16
    bl e_ldr_va
    WORD 0xD63F0200
#else
    WORD 0xD2800000
    WORD 0xD2800BC8
    WORD 0xD4000001
#endif
    bl e_text_offset
    bl img_finish
    ENDF


cg_node_addr:
    LDX x9, g_parts
    add x0, x9, w0, uxtw #4
    ret

cg_var_disp:
    ldr x9, [x0, #V_DATA]
    LDX x10, g_vars
    add x9, x10, x9, lsl #5
    ldr w0, [x9, #VR_OFF]
    add w0, w0, #RT_VARS
    ret

emit_load_var:
    mov x15, x30
    bl cg_var_disp
    mov w1, w0
    mov w0, #10
    bl e_addr
    mov x30, x15
    ret

emit_expr:
    stp x29, x30, [sp, #-48]!
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_INT
    b.eq .Lee_const
    cmp w9, #VK_VAR
    b.eq .Lee_var
    ldrb w20, [x19, #V_NEG]
    cmp w20, #OP_NEG
    b.eq .Lee_neg
    ldr w0, [x19, #V_DATA_HI]
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_EXPR
    b.ne .Lee_right_simple
    cmp w20, #OP_ADD
    b.eq 1f
    cmp w20, #OP_MUL
    b.ne .Lee_general
1:  ldr w0, [x19, #V_DATA]
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_EXPR
    b.ne .Lee_left_simple
.Lee_general:
    ldr w0, [x19, #V_DATA]
    bl emit_expr
    LDX x21, cg_depth
    cmp x21, #6
    b.hs .Lee_spill
    add x9, x21, #1
    STX x9, cg_depth
    add w22, w21, #19
    MOV32 w0, 0x2A0003E0
    orr w0, w0, w22
    bl e_word
    ldr w0, [x19, #V_DATA_HI]
    bl emit_expr
    STX x21, cg_depth
    cmp w20, #OP_ADD
    b.ne 2f
    MOV32 w0, 0x0B000000
    orr w0, w0, w22, lsl #5
    bl e_word
    b .Lee_done
2:  cmp w20, #OP_SUB
    b.ne 3f
    MOV32 w0, 0x4B000000
    orr w0, w0, w22, lsl #5
    bl e_word
    b .Lee_done
3:  cmp w20, #OP_MUL
    b.ne 4f
    MOV32 w0, 0x1B007C00
    orr w0, w0, w22, lsl #5
    bl e_word
    b .Lee_done
4:  MOV32 w0, 0x2A0003E1
    bl e_word
    MOV32 w0, 0x2A0003E0
    orr w0, w0, w22, lsl #16
    bl e_word
    bl checked_div
    b .Lee_done
.Lee_spill:
    MOV32 w0, 0xB81F0FE0
    bl e_word
    ldr w0, [x19, #V_DATA_HI]
    bl emit_expr
    MOV32 w0, 0x2A0003E1
    bl e_word
    MOV32 w0, 0xB84107E0
    bl e_word
    bl apply_reg
    b .Lee_done
.Lee_right_simple:
    ldr w0, [x19, #V_DATA]
    bl emit_expr
    ldr w0, [x19, #V_DATA_HI]
    bl apply_simple
    b .Lee_done
.Lee_left_simple:
    ldr w0, [x19, #V_DATA_HI]
    bl emit_expr
    ldr w0, [x19, #V_DATA]
    bl apply_simple
    b .Lee_done
.Lee_neg:
    ldr w0, [x19, #V_DATA]
    bl emit_expr
    MOV32 w0, 0x4B0003E0
    bl e_word
    b .Lee_done
.Lee_const:
    mov w0, #0
    ldr w1, [x19, #V_DATA]
    bl e_mov32
    b .Lee_done
.Lee_var:
    mov x0, x19
    bl emit_load_var
    MOV32 w0, 0xB9400140
    bl e_word
.Lee_done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

pow2_shift:
    mov w0, #0
    cmp w21, #2
    b.lt 1f
    sub w9, w21, #1
    tst w9, w21
    b.ne 1f
    rbit w0, w21
    clz w0, w0
1:  ret

apply_simple:
    stp x29, x30, [sp, #-32]!
    stp x21, x22, [sp, #16]
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_VAR
    b.eq .Las_var
    ldr w21, [x0, #V_DATA]
    cmp w20, #OP_ADD
    b.eq .Las_add
    cmp w20, #OP_SUB
    b.eq .Las_sub
    cmp w20, #OP_MUL
    b.eq .Las_mul
    cmp w20, #OP_DIV
    b.eq .Las_div
    b .Las_mod
.Las_sub:
    neg w21, w21
.Las_add:
    cmp w21, #0
    b.le 1f
    cmp w21, #4095
    b.gt .Las_add_reg
    MOV32 w0, 0x11000000
    orr w0, w0, w21, lsl #10
    bl e_word
    b .Las_done
1:  neg w9, w21
    cmp w9, #0
    b.le .Las_add_reg
    cmp w9, #4095
    b.gt .Las_add_reg
    MOV32 w0, 0x51000000
    orr w0, w0, w9, lsl #10
    bl e_word
    b .Las_done
.Las_add_reg:
    mov w0, #1
    mov w1, w21
    bl e_mov32
    MOV32 w0, 0x0B010000
    bl e_word
    b .Las_done
.Las_mul:
    bl pow2_shift
    cbz w0, 2f
    mov w9, #32
    sub w9, w9, w0
    and w9, w9, #31
    mov w10, #31
    sub w10, w10, w0
    MOV32 w0, 0x53000000
    orr w0, w0, w9, lsl #16
    orr w0, w0, w10, lsl #10
    bl e_word
    b .Las_done
2:  mov w0, #1
    mov w1, w21
    bl e_mov32
    MOV32 w0, 0x1B017C00
    bl e_word
    b .Las_done
.Las_div:
    bl pow2_shift
    cbz w0, 3f
    mov w22, w0
    MOV32 w0, 0x131F7C01
    bl e_word
    mov w9, #32
    sub w9, w9, w22
    MOV32 w0, 0x53007C21
    orr w0, w0, w9, lsl #16
    bl e_word
    MOV32 w0, 0x0B010000
    bl e_word
    MOV32 w0, 0x13007C00
    orr w0, w0, w22, lsl #16
    bl e_word
    b .Las_done
3:  mov w0, #1
    mov w1, w21
    bl e_mov32
    MOV32 w0, 0x1AC10C00
    bl e_word
    b .Las_done
.Las_mod:
    bl pow2_shift
    cbz w0, 4f
    mov w22, w0
    MOV32 w0, 0x131F7C01
    bl e_word
    mov w9, #32
    sub w9, w9, w22
    MOV32 w0, 0x53007C21
    orr w0, w0, w9, lsl #16
    bl e_word
    MOV32 w0, 0x0B010001
    bl e_word
    MOV32 w0, 0x13007C21
    orr w0, w0, w22, lsl #16
    bl e_word
    mov w9, #32
    sub w9, w9, w22
    and w9, w9, #31
    mov w10, #31
    sub w10, w10, w22
    MOV32 w0, 0x53000021
    orr w0, w0, w9, lsl #16
    orr w0, w0, w10, lsl #10
    bl e_word
    MOV32 w0, 0x4B010000
    bl e_word
    b .Las_done
4:  mov w0, #1
    mov w1, w21
    bl e_mov32
    MOV32 w0, 0x1AC10C02
    bl e_word
    MOV32 w0, 0x1B018040
    bl e_word
    b .Las_done
.Las_var:
    bl emit_load_var
    MOV32 w0, 0xB9400141
    bl e_word
    bl apply_reg
.Las_done:
    ldp x21, x22, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

apply_reg:
    mov x14, x30
    cmp w20, #OP_ADD
    b.ne 1f
    MOV32 w0, 0x0B010000
    bl e_word
    mov x30, x14
    ret
1:  cmp w20, #OP_SUB
    b.ne 2f
    MOV32 w0, 0x4B010000
    bl e_word
    mov x30, x14
    ret
2:  cmp w20, #OP_MUL
    b.ne 3f
    MOV32 w0, 0x1B017C00
    bl e_word
    mov x30, x14
    ret
3:  mov x30, x14

checked_div:
    stp x29, x30, [sp, #-16]!
    MOV32 w0, 0x35000081
    bl e_word
    LDX x9, cg_line
    and w10, w9, #0xFFFF
    MOV32 w0, 0x52800000
    orr w0, w0, w10, lsl #5
    bl e_word
    LDX x9, cg_line
    lsr w10, w9, #16
    MOV32 w0, 0x72A00000
    orr w0, w0, w10, lsl #5
    bl e_word
    LA x9, rt_offsets
    ldr w0, [x9, #RT_FN_DIV_ZERO]
    bl e_bl
    cmp w20, #OP_DIV
    b.ne 1f
    MOV32 w0, 0x1AC10C00
    bl e_word
    b 2f
1:  MOV32 w0, 0x1AC10C02
    bl e_word
    MOV32 w0, 0x1B018040
    bl e_word
2:  ldp x29, x30, [sp], #16
    ret

