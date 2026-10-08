#include "defs.h"

#define RT_FN_WRITE      0
#define RT_FN_WRITE_INT  4
#define RT_FN_WRITE_BOOL 8
#define RT_FN_WRITE_STR  12
#define RT_FN_FLUSH      16

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
#endif

    LDX x19, g_stmts
    LDX x20, g_nstmt
    add x20, x19, x20, lsl #5
.Lcg_stmt:
    cmp x19, x20
    b.hs .Lcg_epilogue
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
    LDX x10, g_parts
    add x23, x10, x9, lsl #4
    ldrb w9, [x23, #V_KIND]
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
