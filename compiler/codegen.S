#include "defs.h"

#define RT_FN_WRITE      0
#define RT_FN_WRITE_INT  4
#define RT_FN_WRITE_BOOL 8
#define RT_FN_WRITE_STR  12
#define RT_FN_FLUSH      16
#define RT_FN_DIV_ZERO   20
#define RT_FN_STR_EQ     24
#define RT_FN_INPUT_STR  28
#define RT_FN_INPUT_INT  32

#define OP_STR_W   0xB9000000
#define OP_LDR_W   0xB9400000
#define OP_STR_X   0xF9000000
#define OP_LDR_X   0xF9400000
#define OP_STRB    0x39000000
#define OP_LDRB    0x39400000
#define OP_STRH    0x79000000
#define OP_LDRH    0x79400000

#define NOREG      0xFF
#define B_END      0
#define B_KIND     4
#define B_TOP      8
#define B_REG      12
#define B_SLOT     16
#define B_DYN      20
#define B_LIMIT    24
#define B_INIT     28
#define B_ALIAS    32
#define B_IFIDX    36
#define B_LABEL    40
#define B_TAKE     44
#define B_GIDX     48
#define B_SIZE     64

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
cg_ldepth:  .zero 8
cg_bdepth:  .zero 8
cg_patch:   .zero 8
cg_npatch:  .zero 8
cg_lp:      .zero 8
cg_lpl:     .zero 8
cg_nlp:     .zero 8
cg_label:   .zero 8
cg_inoff:   .zero 8
cg_vreg:    .zero 8
cg_cur:     .zero 8
cg_end:     .zero 8
cg_op:      .zero 8
cg_blk:     .zero 8
cg_blvar:   .zero 8
cg_bldata:  .zero 8
cg_bland:   .zero 8
cg_blacc:   .zero 8
mg_m:       .zero 8
mg_k:       .zero 8
cg_bstack:  .zero B_SIZE * (MAX_NEST + 1)

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

.macro ENTER
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
.endm

.macro LEAVE
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x29, x30, [sp], #64
    ret
.endm

FUNC codegen
    STX xzr, cg_inoff
    LDX x9, g_stmts
    LDX x10, g_nstmt
    add x10, x9, x10, lsl #5
62: cmp x9, x10
    b.hs 64f
    ldrh w11, [x9, #S_KIND]
    cmp w11, #SK_INPUT
    b.eq 63f
    add x9, x9, #32
    b 62b
63: LDX x9, g_vars_size
    add x9, x9, #15
    and x9, x9, #~15
    add x10, x9, #RT_VARS
    STX x10, cg_inoff
    MOV32 w11, IN_SIZE
    add x9, x9, x11
    STX x9, g_vars_size
64: bl img_layout
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
2:  LDX x0, g_nparts
    add x0, x0, #16
    lsl x0, x0, #2
    bl mem_alloc
    STX x0, cg_patch
    LDX x0, g_nparts
    LDX x9, g_nstmt
    add x0, x0, x9
    add x0, x0, #16
    lsl x0, x0, #3
    bl mem_alloc
    STX x0, cg_lp
    LDX x9, g_nparts
    LDX x10, g_nstmt
    add x9, x9, x10
    add x9, x9, #16
    add x0, x0, x9, lsl #2
    STX x0, cg_lpl
    LDX x0, g_nvars
    add x0, x0, #16
    bl mem_alloc
    STX x0, cg_vreg
    STX xzr, cg_npatch
    STX xzr, cg_nlp
    mov x9, #1
    STX x9, cg_label
    STX xzr, cg_bdepth
    STX xzr, cg_ldepth
    STX xzr, cg_depth
3:  bl e_text_offset
    tst x0, #15
    b.eq 4f
    WORD 0xD503201F
    b 3b
4:  STX x0, img_entry

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
    LDX x9, cg_inoff
    cbz x9, 61f
#if defined(TARGET_WINDOWS)
    WORD 0x12800120
    mov w0, #16
    LDX x1, img_iat_va
    bl e_ldr_va
    WORD 0xD63F0200
    LDST OP_STR_X, 0, 28, 9
    mov w0, #16
    LDX x1, img_iat_va
    add x1, x1, #24
    bl e_ldr_va
    LDST OP_STR_X, 16, 28, 8
#endif
    mov w0, #9
    LDX x1, cg_inoff
    bl e_addr
    LDST OP_STR_X, 9, 28, 10
    mov w0, #9
    MOV32 w1, IN_SIZE
    bl e_mov32
    LDST OP_STR_W, 9, 28, 22
61:

    LDX x19, g_stmts
    LDX x20, g_nstmt
    add x20, x19, x20, lsl #5
    STX x20, cg_end
.Lcg_stmt:
    STX x19, cg_cur
    LDX x9, g_stmts
    sub x0, x19, x9
    lsr x0, x0, #5
    bl close_blocks
    LDX x19, cg_cur
    LDX x20, cg_end
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
    cmp w9, #SK_IF
    b.eq .Lcg_if
    cmp w9, #SK_FOR
    b.eq .Lcg_loop
    cmp w9, #SK_LOOPS
    b.eq .Lcg_loop
    cmp w9, #SK_ELSE
    b.eq .Lcg_next
    cmp w9, #SK_BREAK
    b.eq .Lcg_jump
    cmp w9, #SK_CONTINUE
    b.eq .Lcg_jump
    cmp w9, #SK_GROUP
    b.eq .Lcg_group
    cmp w9, #SK_INPUT
    b.eq .Lcg_input
    bl emit_store
    b .Lcg_next
.Lcg_input:
    bl emit_out_body
    bl emit_input
    b .Lcg_next
.Lcg_jump:
    bl emit_jump
    b .Lcg_next
.Lcg_group:
    bl group_open
    b .Lcg_next
.Lcg_out:
    bl emit_out_body
    b .Lcg_next
.Lcg_if:
    bl try_branchless
    cbz w0, .Lcg_if_branch
    LDX x19, cg_cur
    add x19, x19, #32
    STX x19, cg_cur
    b .Lcg_next
.Lcg_if_branch:
    LDX x19, cg_cur
    LDX x9, cg_bdepth
    mov x10, #B_SIZE
    LA x11, cg_bstack
    madd x11, x9, x10, x11
    ldr w12, [x19, #S_PIECES]
    str w12, [x11, #B_END]
    mov w12, #BK_IF
    str w12, [x11, #B_KIND]
    LDX x12, cg_npatch
    str w12, [x11, #B_TOP]
    LDX x12, g_stmts
    sub x12, x19, x12
    lsr x12, x12, #5
    str w12, [x11, #B_IFIDX]
    add x9, x9, #1
    STX x9, cg_bdepth
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_roots
    ldr w0, [x10, x9, lsl #2]
    mov w1, #0
    mov w2, #0
    bl emit_cond
    b .Lcg_next
.Lcg_loop:
    bl emit_loop_head
.Lcg_next:
    LDX x19, cg_cur
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

cg_var_off:
    LDX x10, g_vars
    add x9, x10, x0, lsl #5
    ldr w0, [x9, #VR_OFF]
    add w0, w0, #RT_VARS
    ret

cg_stmt_ptr:
    LDX x9, g_stmts
    add x0, x9, x0, lsl #5
    ret

cg_var_reg:
    LDX x9, cg_vreg
    ldrb w0, [x9, w0, uxtw]
    and w0, w0, #0x1F
    sub w0, w0, #1
    ret

e_rrr:
    orr w0, w0, w3, lsl #16
    orr w0, w0, w2, lsl #5
    orr w0, w0, w1
    b e_word

emit_var_addr:
    stp x29, x30, [sp, #-16]!
    bl cg_var_off
    mov w1, w0
    mov w0, #10
    bl e_addr
    ldp x29, x30, [sp], #16
    ret

emit_store:
    ENTER
    LDX x19, cg_cur
    ldr w0, [x19, #S_VAR]
    bl cg_var_off
    mov w21, w0
    ldrh w22, [x19, #S_MODE]
    ldr w9, [x19, #S_NPARTS]
    cbz w9, .Les_default
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_roots
    ldr w24, [x10, x9, lsl #2]
    mov w0, w24
    bl cg_node_addr
    mov x23, x0
    ldrb w9, [x23, #V_KIND]
    cmp w9, #VK_EXPR
    b.eq .Les_expr
    cmp w9, #VK_VAR
    b.eq .Les_copy
    cmp w9, #VK_NULL
    b.eq .Les_default
    cmp w9, #VK_STR
    b.eq .Les_str
    mov w0, #9
    ldr w1, [x23, #V_DATA]
    bl e_mov32
    mov w0, #10
    mov w1, w21
    bl e_addr
    cmp w22, #TY_BOOL
    b.eq 1f
    LDST OP_STR_W, 9, 10, 0
    b .Les_done
1:  LDST OP_STRB, 9, 10, 0
    b .Les_done
.Les_expr:
    mov w0, w24
    bl emit_expr
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_W, 0, 10, 0
    b .Les_done
.Les_str:
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
    b .Les_done
.Les_default:
    mov w0, #10
    mov w1, w21
    bl e_addr
    cmp w22, #TY_INT
    b.ne 2f
    LDST OP_STR_W, 31, 10, 0
    b .Les_done
2:  cmp w22, #TY_BOOL
    b.ne 3f
    LDST OP_STRB, 31, 10, 0
    b .Les_done
3:  LDST OP_STR_X, 31, 10, 0
    LDST OP_STRH, 31, 10, 4
    b .Les_done
.Les_copy:
    ldr w20, [x23, #V_DATA]
    cmp w22, #TY_INT
    b.ne .Les_copy_mem
    mov w0, w20
    bl cg_var_reg
    tbnz w0, #31, .Les_copy_mem
    mov w3, w0
    MOV32 w0, 0x2A0003E9
    mov w1, #0
    mov w2, #0
    orr w0, w0, w3, lsl #16
    bl e_word
    b .Les_copy_st
.Les_copy_mem:
    mov w0, w20
    bl cg_var_off
    mov w1, w0
    mov w0, #10
    bl e_addr
    cmp w22, #TY_INT
    b.ne 4f
    LDST OP_LDR_W, 9, 10, 0
.Les_copy_st:
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_W, 9, 10, 0
    b .Les_done
4:  cmp w22, #TY_BOOL
    b.ne 5f
    LDST OP_LDRB, 9, 10, 0
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STRB, 9, 10, 0
    b .Les_done
5:  LDST OP_LDR_X, 9, 10, 0
    LDST OP_LDRH, 11, 10, 4
    mov w0, #10
    mov w1, w21
    bl e_addr
    LDST OP_STR_X, 9, 10, 0
    LDST OP_STRH, 11, 10, 4
.Les_done:
    LEAVE

emit_out_body:
    ENTER
    LDX x19, cg_cur
    ldr w21, [x19, #S_PIECES]
    ldr w22, [x19, #S_NPIECES]
    add w22, w22, w21
.Lob_piece:
    cmp w21, w22
    b.hs .Lob_done
    LDX x9, g_pieces
    add x23, x9, x21, lsl #4
    add w21, w21, #1
    ldr w9, [x23, #P_KIND]
    cmp w9, #PK_TEXT
    b.ne .Lob_var
    ldr w9, [x23, #P_B]
    cbz w9, .Lob_piece
    mov w0, #0
    LDX x1, cg_pool_va
    ldr w9, [x23, #P_A]
    add x1, x1, x9
    bl e_adr_va
    mov w0, #1
    ldr w1, [x23, #P_B]
    bl e_mov32
    CALL_RT RT_FN_WRITE
    b .Lob_piece
.Lob_var:
    cmp w9, #PK_EXPR
    b.ne .Lob_plain
    ldr w0, [x23, #P_A]
    bl emit_expr
    CALL_RT RT_FN_WRITE_INT
    b .Lob_piece
.Lob_plain:
    ldr w24, [x23, #P_A]
    add w24, w24, #RT_VARS
    cmp w9, #PK_STR
    b.eq .Lob_str
    mov w20, w9
    mov w0, #10
    mov w1, w24
    bl e_addr
    cmp w20, #PK_INT
    b.ne 1f
    LDST OP_LDR_W, 0, 10, 0
    CALL_RT RT_FN_WRITE_INT
    b .Lob_piece
1:  LDST OP_LDRB, 0, 10, 0
    CALL_RT RT_FN_WRITE_BOOL
    b .Lob_piece
.Lob_str:
    mov w0, #0
    mov w1, w24
    bl e_addr
    CALL_RT RT_FN_WRITE_STR
    b .Lob_piece
.Lob_done:
    LEAVE

emit_expr:
    ENTER
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
    ldr w0, [x19, #V_DATA]
    bl cg_var_reg
    tbnz w0, #31, 5f
    MOV32 w9, 0x2A0003E0
    orr w0, w9, w0, lsl #16
    bl e_word
    b .Lee_done
5:  ldr w0, [x19, #V_DATA]
    bl emit_var_addr
    MOV32 w0, 0xB9400140
    bl e_word
.Lee_done:
    LEAVE

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
    ENTER
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
    cmp w21, #1
    b.eq .Las_done
    cmn w21, #1
    b.ne 6f
    MOV32 w0, 0x4B0003E0
    bl e_word
    b .Las_done
6:  mov w23, #0
    cmp w21, #0
    b.ge 7f
    neg w9, w21
    sub w10, w9, #1
    tst w10, w9
    b.ne 7f
    cmp w9, #2
    b.lt 7f
    mov w21, w9
    mov w23, #1
7:  bl pow2_shift
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
    cbz w23, .Las_done
    MOV32 w0, 0x4B0003E0
    bl e_word
    b .Las_done
3:  bl magic_quot
    cbz w0, 8f
    tbz w21, #31, 9f
    MOV32 w0, 0x4B0103E0
    bl e_word
    b .Las_done
9:  MOV32 w0, 0x2A0103E0
    bl e_word
    b .Las_done
8:  mov w0, #1
    mov w1, w21
    bl e_mov32
    MOV32 w0, 0x1AC10C00
    bl e_word
    b .Las_done
.Las_mod:
    add w9, w21, #1
    cmp w9, #2
    b.hi 10f
    MOV32 w0, 0x2A1F03E0
    bl e_word
    b .Las_done
10: cmp w21, #0
    b.ge 11f
    neg w9, w21
    sub w10, w9, #1
    tst w10, w9
    b.ne 11f
    mov w21, w9
11: bl pow2_shift
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
4:  bl magic_quot
    cbz w0, 12f
    mov w0, #2
    cmp w21, #0
    cneg w1, w21, lt
    bl e_mov32
    MOV32 w0, 0x1B028020
    bl e_word
    b .Las_done
12: mov w0, #1
    mov w1, w21
    bl e_mov32
    MOV32 w0, 0x1AC10C02
    bl e_word
    MOV32 w0, 0x1B018040
    bl e_word
    b .Las_done
.Las_var:
    mov x22, x0
    ldr w0, [x22, #V_DATA]
    bl cg_var_reg
    tbnz w0, #31, 13f
    MOV32 w9, 0x2A0003E1
    orr w0, w9, w0, lsl #16
    bl e_word
    b 14f
13: ldr w0, [x22, #V_DATA]
    bl emit_var_addr
    MOV32 w0, 0xB9400141
    bl e_word
14: bl apply_reg
.Las_done:
    LEAVE

magic_quot:
    ENTER
    mov w0, #0
    LDX x9, cg_ldepth
    cbz x9, .Lmq_done
    cmp w21, #0
    cneg w10, w21, lt
    cmp w10, #2
    b.lo .Lmq_fail
    mov w9, #0x80000000
    cmp w21, w9
    b.eq .Lmq_fail
    mov x19, x10
    mov x20, #0
.Lmq_try:
    mov x11, #1
    add x12, x20, #32
    lsl x11, x11, x12
    sub x13, x11, #1
    udiv x13, x13, x19
    add x13, x13, #1
    mul x14, x13, x19
    sub x14, x14, x11
    mov x15, #2
    lsl x15, x15, x20
    cmp x14, x15
    b.hi .Lmq_next
    lsr x15, x13, #32
    cbnz x15, .Lmq_next
    b .Lmq_found
.Lmq_next:
    add x20, x20, #1
    cmp x20, #32
    b.lo .Lmq_try
.Lmq_fail:
    mov w0, #0
    b .Lmq_done
.Lmq_found:
    add x20, x20, #32
    STX x13, mg_m
    STX x20, mg_k
    mov w0, #2
    mov w1, w13
    bl e_mov32
    WORD 0x93407C03
    WORD 0x9B027C61
    LDX x9, mg_k
    MOV32 w0, 0x9340FC21
    orr w0, w0, w9, lsl #16
    bl e_word
    WORD 0x4B807C21
    mov w0, #1
.Lmq_done:
    LEAVE

apply_reg:
    stp x29, x30, [sp, #-16]!
    cmp w20, #OP_ADD
    b.ne 1f
    WORD 0x0B010000
    b 9f
1:  cmp w20, #OP_SUB
    b.ne 2f
    WORD 0x4B010000
    b 9f
2:  cmp w20, #OP_MUL
    b.ne 3f
    WORD 0x1B017C00
    b 9f
3:  bl checked_div
9:  ldp x29, x30, [sp], #16
    ret

checked_div:
    stp x29, x30, [sp, #-16]!
    WORD 0x35000081
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
    WORD 0x1AC10C00
    b 2f
1:  WORD 0x1AC10C02
    WORD 0x1B018040
2:  ldp x29, x30, [sp], #16
    ret

record_patch:
    stp x29, x30, [sp, #-16]!
    bl e_text_offset
    LDX x9, cg_npatch
    LDX x10, cg_patch
    str w0, [x10, x9, lsl #2]
    add x9, x9, #1
    STX x9, cg_npatch
    ldp x29, x30, [sp], #16
    ret

patch_word:
    LDX x9, enc_text_base
    ldr w10, [x9, x0]
    sub x11, x1, x0
    asr x11, x11, #2
    lsr w12, w10, #26
    cmp w12, #0x05
    b.eq 1f
    and w11, w11, #0x7FFFF
    and w10, w10, #0xFF00001F
    orr w10, w10, w11, lsl #5
    str w10, [x9, x0]
    ret
1:  and w11, w11, #0x3FFFFFF
    and w10, w10, #0xFC000000
    orr w10, w10, w11
    str w10, [x9, x0]
    ret

patch_range:
    ENTER
    mov w19, w0
    mov w20, w1
    bl e_text_offset
    mov x21, x0
1:  cmp w19, w20
    b.hs 2f
    LDX x9, cg_patch
    ldr w0, [x9, w19, uxtw #2]
    mov x1, x21
    bl patch_word
    add w19, w19, #1
    b 1b
2:  LEAVE

jump_to_label:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    mov w19, w0
    cbnz w19, 1f
    bl record_patch
    b 2f
1:  bl e_text_offset
    LDX x9, cg_nlp
    LDX x10, cg_lp
    str w0, [x10, x9, lsl #2]
    LDX x10, cg_lpl
    str w19, [x10, x9, lsl #2]
    add x9, x9, #1
    STX x9, cg_nlp
2:  ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

place_label:
    ENTER
    mov w19, w0
    bl e_text_offset
    mov x20, x0
    mov w21, #0
    mov w22, #0
1:  LDX x9, cg_nlp
    cmp x21, x9
    b.hs 3f
    LDX x9, cg_lpl
    ldr w23, [x9, x21, lsl #2]
    LDX x9, cg_lp
    ldr w24, [x9, x21, lsl #2]
    cmp w23, w19
    b.ne 2f
    mov w0, w24
    mov x1, x20
    bl patch_word
    b 4f
2:  LDX x9, cg_lp
    str w24, [x9, x22, lsl #2]
    LDX x9, cg_lpl
    str w23, [x9, x22, lsl #2]
    add w22, w22, #1
4:  add w21, w21, #1
    b 1b
3:  STX x22, cg_nlp
    LEAVE

emit_cond:
    ENTER
    mov w20, w1
    mov w21, w2
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_BOOL
    b.eq .Lec_const
    cmp w9, #VK_OR
    b.eq .Lec_or
    cmp w9, #VK_AND
    b.eq .Lec_and
    mov x0, x19
    bl emit_compare
    cbnz w20, 1f
    eor w0, w0, #1
1:  MOV32 w9, 0x54000000
    orr w0, w0, w9
    bl e_word
    b .Lec_record
.Lec_const:
    ldr w9, [x19, #V_DATA]
    cmp w9, #0
    cset w9, ne
    cmp w9, w20
    b.ne .Lec_done
    WORD 0x14000000
.Lec_record:
    bl e_text_offset
    sub x0, x0, #4
    mov w22, w0
    cbnz w21, 2f
    LDX x9, cg_npatch
    LDX x10, cg_patch
    str w22, [x10, x9, lsl #2]
    add x9, x9, #1
    STX x9, cg_npatch
    b .Lec_done
2:  LDX x9, cg_nlp
    LDX x10, cg_lp
    str w22, [x10, x9, lsl #2]
    LDX x10, cg_lpl
    str w21, [x10, x9, lsl #2]
    add x9, x9, #1
    STX x9, cg_nlp
    b .Lec_done
.Lec_or:
    mov w22, #1
    b .Lec_pair
.Lec_and:
    mov w22, #0
.Lec_pair:
    cmp w22, w20
    b.ne .Lec_split
    ldr w0, [x19, #V_DATA]
    mov w1, w20
    mov w2, w21
    bl emit_cond
    ldr w0, [x19, #V_DATA_HI]
    mov w1, w20
    mov w2, w21
    bl emit_cond
    b .Lec_done
.Lec_split:
    LDX x23, cg_label
    add x9, x23, #1
    STX x9, cg_label
    ldr w0, [x19, #V_DATA]
    mov w1, w22
    mov w2, w23
    bl emit_cond
    ldr w0, [x19, #V_DATA_HI]
    mov w1, w20
    mov w2, w21
    bl emit_cond
    mov w0, w23
    bl place_label
.Lec_done:
    LEAVE

cc_of_op:
    mov w0, #0
    cmp w1, #CMP_IS
    b.eq 1f
    mov w0, #1
    cmp w1, #CMP_ISNOT
    b.eq 1f
    mov w0, #11
    cmp w1, #CMP_LT
    b.eq 1f
    mov w0, #13
    cmp w1, #CMP_LE
    b.eq 1f
    mov w0, #10
    cmp w1, #CMP_GE
    b.eq 1f
    mov w0, #12
1:  ret

emit_compare:
    ENTER
    mov x19, x0
    ldrb w9, [x19, #V_NEG]
    LDX x10, cg_op
    stp x10, xzr, [sp, #-16]!
    STX x9, cg_op
    ldr w20, [x19, #V_DATA]
    ldr w21, [x19, #V_DATA_HI]
    ldrb w9, [x19, #V_TYPE]
    cmp w9, #TY_STR
    b.eq .Lcm_str
    cmp w9, #TY_BOOL
    b.eq .Lcm_bool
    mov w0, w20
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Lcm_order_ok
    mov w0, w21
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.eq .Lcm_order_ok
    mov w9, w20
    mov w20, w21
    mov w21, w9
    LDX x9, cg_op
    mov w10, #CMP_GT
    cmp w9, #CMP_LT
    b.eq 1f
    mov w10, #CMP_LT
    cmp w9, #CMP_GT
    b.eq 1f
    mov w10, #CMP_GE
    cmp w9, #CMP_LE
    b.eq 1f
    mov w10, #CMP_LE
    cmp w9, #CMP_GE
    b.ne .Lcm_order_ok
1:  STX x10, cg_op
.Lcm_order_ok:
    bl try_divisible
    cmn w0, #1
    b.ne .Lcm_ret
    mov w0, w20
    bl emit_expr
    mov w0, w21
    bl cg_node_addr
    mov x22, x0
    ldrb w9, [x22, #V_KIND]
    cmp w9, #VK_INT
    b.eq .Lcm_imm
    cmp w9, #VK_VAR
    b.eq .Lcm_var
    LDX x23, cg_depth
    cmp x23, #6
    b.hs .Lcm_spill
    add x9, x23, #1
    STX x9, cg_depth
    add w24, w23, #19
    MOV32 w0, 0x2A0003E0
    orr w0, w0, w24
    bl e_word
    mov w0, w21
    bl emit_expr
    STX x23, cg_depth
    MOV32 w0, 0x6B00001F
    orr w0, w0, w24, lsl #5
    bl e_word
    b .Lcm_int_cc
.Lcm_spill:
    WORD 0xB81F0FE0
    mov w0, w21
    bl emit_expr
    WORD 0x2A0003E1
    WORD 0xB84107E0
    WORD 0x6B01001F
    b .Lcm_int_cc
.Lcm_imm:
    ldr w1, [x22, #V_DATA]
    cmp w1, #0
    b.lt 2f
    cmp w1, #4095
    b.gt 3f
    MOV32 w0, 0x7100001F
    orr w0, w0, w1, lsl #10
    bl e_word
    b .Lcm_int_cc
2:  neg w9, w1
    cmp w9, #4095
    b.hi 3f
    MOV32 w0, 0x3100001F
    orr w0, w0, w9, lsl #10
    bl e_word
    b .Lcm_int_cc
3:  mov w0, #1
    bl e_mov32
    WORD 0x6B01001F
    b .Lcm_int_cc
.Lcm_var:
    ldr w0, [x22, #V_DATA]
    bl cg_var_reg
    tbnz w0, #31, 4f
    MOV32 w9, 0x6B00001F
    orr w0, w9, w0, lsl #16
    bl e_word
    b .Lcm_int_cc
4:  ldr w0, [x22, #V_DATA]
    bl emit_var_addr
    WORD 0xB9400141
    WORD 0x6B01001F
.Lcm_int_cc:
    LDX x1, cg_op
    bl cc_of_op
    b .Lcm_ret
.Lcm_bool:
    mov w0, w20
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_VAR
    b.eq 5f
    ldr w1, [x0, #V_DATA]
    mov w0, #0
    bl e_mov32
    b 6f
5:  ldr w0, [x0, #V_DATA]
    bl emit_var_addr
    WORD 0x39400140
6:  mov w0, w21
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_VAR
    b.eq 7f
    ldr w1, [x0, #V_DATA]
    mov w0, #1
    bl e_mov32
    b 8f
7:  ldr w0, [x0, #V_DATA]
    bl emit_var_addr
    WORD 0x39400141
8:  WORD 0x6B01001F
    b .Lcm_int_cc
.Lcm_str:
    mov w0, w20
    mov w1, #0
    bl emit_str_args
    mov w0, w21
    mov w1, #2
    bl emit_str_args
    CALL_RT RT_FN_STR_EQ
    WORD 0x7100001F
    mov w0, #1
    LDX x9, cg_op
    cmp w9, #CMP_IS
    b.eq .Lcm_ret
    mov w0, #0
.Lcm_ret:
    ldp x10, xzr, [sp], #16
    STX x10, cg_op
    LEAVE

emit_str_args:
    ENTER
    mov w20, w1
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_VAR
    b.eq 1f
    cmp w9, #VK_STR
    b.eq 2f
    MOV32 w0, 0xD2800000
    orr w0, w0, w20
    bl e_word
    MOV32 w0, 0xD2800000
    add w9, w20, #1
    orr w0, w0, w9
    bl e_word
    b 3f
1:  ldr w0, [x19, #V_DATA]
    bl emit_var_addr
    MOV32 w0, OP_LDR_X | (10 << 5)
    orr w0, w0, w20
    bl e_word
    MOV32 w0, OP_LDRH | (4 << 10) | (10 << 5)
    add w9, w20, #1
    orr w0, w0, w9
    bl e_word
    b 3f
2:  mov w0, w20
    LDX x1, cg_pool_va
    ldr w9, [x19, #V_DATA]
    add x1, x1, x9
    bl e_adr_va
    add w0, w20, #1
    ldr w1, [x19, #V_DATA_HI]
    bl e_mov32
3:  LEAVE

try_divisible:
    ENTER
    mov w0, #-1
    LDX x9, cg_ldepth
    cbz x9, .Ltd_done
    LDX x9, cg_op
    cmp w9, #CMP_LT
    b.hs .Ltd_no
    mov w0, w21
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Ltd_no
    ldr w9, [x0, #V_DATA]
    cbnz w9, .Ltd_no
    mov w0, w20
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_EXPR
    b.ne .Ltd_no
    ldrb w9, [x0, #V_NEG]
    cmp w9, #OP_MOD
    b.ne .Ltd_no
    mov x22, x0
    ldr w0, [x22, #V_DATA_HI]
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Ltd_no
    ldr w23, [x0, #V_DATA]
    mov w9, #0x80000000
    cmp w23, w9
    b.eq .Ltd_no
    cmp w23, #0
    cneg w23, w23, lt
    cmp w23, #2
    b.lo .Ltd_no
    ldr w0, [x22, #V_DATA]
    bl emit_expr
    sub w9, w23, #1
    tst w9, w23
    b.ne .Ltd_gm
    mov w0, #1
    mov w1, w9
    bl e_mov32
    WORD 0x6A01001F
    LDX x1, cg_op
    bl cc_of_op
    b .Ltd_done
.Ltd_gm:
    WORD 0x7100001F
    WORD 0x5A805400
    rbit w24, w23
    clz w24, w24
    lsr w9, w23, w24
    mov w10, w9
    mov w11, #4
1:  mul w12, w9, w10
    mov w13, #2
    sub w12, w13, w12
    mul w10, w10, w12
    subs w11, w11, #1
    b.ne 1b
    mov w0, #1
    mov w1, w10
    bl e_mov32
    WORD 0x1B017C00
    cbz w24, 2f
    MOV32 w0, 0x13800000
    orr w0, w0, w24, lsl #10
    bl e_word
2:  mov w9, #-1
    udiv w1, w9, w23
    mov w0, #1
    bl e_mov32
    WORD 0x6B01001F
    mov w0, #9
    LDX x9, cg_op
    cmp w9, #CMP_IS
    b.eq .Ltd_done
    mov w0, #8
    b .Ltd_done
.Ltd_no:
    mov w0, #-1
.Ltd_done:
    LEAVE

close_blocks:
    ENTER
    mov w19, w0
.Lcb_loop:
    LDX x9, cg_bdepth
    cbz x9, .Lcb_done
    sub x9, x9, #1
    mov x10, #B_SIZE
    LA x11, cg_bstack
    madd x20, x9, x10, x11
    ldr w9, [x20, #B_END]
    cmp w9, w19
    b.ne .Lcb_done
    ldr w9, [x20, #B_KIND]
    cmp w9, #BK_GROUP
    b.eq .Lcb_group
    cmp w9, #BK_IF
    b.ne .Lcb_loop_close
    mov w0, w19
    LDX x9, g_nstmt
    cmp x0, x9
    b.hs .Lcb_plain
    bl cg_stmt_ptr
    mov x21, x0
    ldrh w9, [x21, #S_KIND]
    cmp w9, #SK_ELSE
    b.ne .Lcb_plain
    ldr w9, [x21, #S_VAR]
    ldr w10, [x20, #B_IFIDX]
    cmp w9, w10
    b.ne .Lcb_plain
    WORD 0x14000000
    bl e_text_offset
    sub x22, x0, #4
    ldr w0, [x20, #B_TOP]
    LDX x1, cg_npatch
    bl patch_range
    ldr w9, [x20, #B_TOP]
    LDX x10, cg_patch
    str w22, [x10, x9, lsl #2]
    add x9, x9, #1
    STX x9, cg_npatch
    ldr w9, [x21, #S_PIECES]
    str w9, [x20, #B_END]
    mov w9, #-1
    str w9, [x20, #B_IFIDX]
    b .Lcb_loop
.Lcb_plain:
    ldr w0, [x20, #B_TOP]
    LDX x1, cg_npatch
    bl patch_range
    ldr w9, [x20, #B_TOP]
    STX x9, cg_npatch
    LDX x9, cg_bdepth
    sub x9, x9, #1
    STX x9, cg_bdepth
    b .Lcb_loop
.Lcb_group:
    ldr w0, [x20, #B_LABEL]
    bl place_label
    mov x0, x20
    bl take_clear
    LDX x9, cg_bdepth
    sub x9, x9, #1
    STX x9, cg_bdepth
    b .Lcb_loop
.Lcb_loop_close:
    mov x0, x20
    bl emit_loop_tail
    ldr w0, [x20, #B_LABEL]
    cbz w0, 30f
    bl place_label
30: mov x0, x20
    bl take_clear
    LDX x9, cg_bdepth
    sub x9, x9, #1
    STX x9, cg_bdepth
    LDX x9, cg_ldepth
    sub x9, x9, #1
    STX x9, cg_ldepth
    b .Lcb_loop
.Lcb_done:
    LEAVE

emit_jump:
    ENTER
    LDX x19, cg_cur
    LDX x9, cg_bdepth
    mov x10, #B_SIZE
    LA x11, cg_bstack
    madd x20, x9, x10, x11
.Lej_find:
    sub x20, x20, #B_SIZE
    ldrh w9, [x19, #S_MODE]
    ldr w10, [x20, #B_KIND]
    cbnz w9, .Lej_group
    cmp w10, #BK_FOR
    b.eq .Lej_found
    cmp w10, #BK_LOOPS
    b.eq .Lej_found
    b .Lej_find
.Lej_group:
    cmp w10, #BK_GROUP
    b.ne .Lej_find
    ldr w9, [x19, #S_VAR]
    ldr w10, [x20, #B_GIDX]
    cmp w9, w10
    b.ne .Lej_find
.Lej_found:
    ldr w0, [x20, #B_LABEL]
    ldrh w9, [x19, #S_KIND]
    cmp w9, #SK_CONTINUE
    b.ne 1f
    add w0, w0, #1
1:  bl jump_to_label
    WORD 0x14000000
    LEAVE

emit_input:
    ENTER
    LDX x19, cg_cur
    ldr w0, [x19, #S_VAR]
    LDX x10, g_vars
    add x9, x10, x0, lsl #5
    ldrh w20, [x9, #VR_TYPE]
    bl cg_var_off
    mov w21, w0
    cmp w20, #TY_INT
    b.eq 1f
    mov w0, #0
    mov w1, w21
    bl e_addr
    mov w0, #1
    LDX x1, cg_line
    bl e_mov32
    CALL_RT RT_FN_INPUT_STR
    b 2f
1:  mov w0, #0
    LDX x1, cg_line
    bl e_mov32
    CALL_RT RT_FN_INPUT_INT
    mov w0, #10
    mov w1, w21
    bl e_addr
    WORD 0xB9000140
2:  LEAVE

group_open:
    ENTER
    LDX x19, cg_cur
    ldrh w9, [x19, #S_MODE]
    cbz w9, .Lgo_done
    LDX x9, cg_bdepth
    mov x10, #B_SIZE
    LA x11, cg_bstack
    madd x20, x9, x10, x11
    add x9, x9, #1
    STX x9, cg_bdepth
    ldr w9, [x19, #S_PIECES]
    str w9, [x20, #B_END]
    mov w9, #BK_GROUP
    str w9, [x20, #B_KIND]
    LDX x9, g_stmts
    sub x9, x19, x9
    lsr x9, x9, #5
    str w9, [x20, #B_GIDX]
    LDX x9, cg_label
    str w9, [x20, #B_LABEL]
    add x9, x9, #1
    STX x9, cg_label
    str wzr, [x20, #B_TAKE]
    ldrh w9, [x19, #S_MODE]
    tbz w9, #0, .Lgo_done
    ldr w0, [x19, #S_VAR]
    bl cg_var_off
    str w0, [x20, #B_TAKE]
.Lgo_done:
    LEAVE

take_store:
    ENTER
    mov x20, x0
    ldr w1, [x20, #B_TAKE]
    cbz w1, .Lts_done
    mov w0, #10
    bl e_addr
    ldr w9, [x20, #B_DYN]
    cbnz w9, 1f
    mov w0, #9
    ldr w1, [x20, #B_LIMIT]
    bl e_mov32
    WORD 0xB9000149
    b .Lts_done
1:  WORD 0xB9000140
.Lts_done:
    LEAVE

take_clear:
    ENTER
    mov x20, x0
    ldr w1, [x20, #B_TAKE]
    cbz w1, 1f
    mov w0, #10
    bl e_addr
    WORD 0xB900015F
1:  LEAVE

for_aliasable:
    stp x29, x30, [sp, #-16]!
    LDX x9, cg_cur
    LDX x10, g_stmts
    sub x11, x9, x10
    lsr x11, x11, #5
    add w11, w11, #1
    ldr w12, [x9, #S_PIECES]
1:  cmp w11, w12
    b.hs 3f
    add x13, x10, x11, lsl #5
    add w11, w11, #1
    ldrh w14, [x13, #S_KIND]
    cmp w14, #SK_DECL
    b.eq 2f
    cmp w14, #SK_ASSIGN
    b.eq 2f
    cmp w14, #SK_INPUT
    b.eq 2f
    cmp w14, #SK_FOR
    b.ne 1b
2:  ldr w14, [x13, #S_VAR]
    cmp w14, w0
    b.ne 1b
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
3:  mov w0, #1
    ldp x29, x30, [sp], #16
    ret

emit_rel_back:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]
    mov w19, w0
    mov w20, w1
    bl e_text_offset
    sub x9, x20, x0
    asr x9, x9, #2
    cmp w19, #0x14
    b.eq 1f
    and w9, w9, #0x7FFFF
    MOV32 w10, 0x54000000
    orr w10, w10, w9, lsl #5
    orr w0, w10, w19
    bl e_word
    b 2f
1:  and w9, w9, #0x3FFFFFF
    MOV32 w10, 0x14000000
    orr w0, w10, w9
    bl e_word
2:  ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

emit_slot_addr:
    stp x29, x30, [sp, #-16]!
    mov w1, w0
    mov w0, #10
    bl e_addr
    ldp x29, x30, [sp], #16
    ret

emit_loop_head:
    ENTER
    LDX x19, cg_cur
    LDX x9, cg_bdepth
    mov x10, #B_SIZE
    LA x11, cg_bstack
    madd x20, x9, x10, x11
    add x9, x9, #1
    STX x9, cg_bdepth
    ldr w9, [x19, #S_PIECES]
    str w9, [x20, #B_END]
    mov w9, #-1
    str w9, [x20, #B_INIT]
    str w9, [x20, #B_ALIAS]
    str wzr, [x20, #B_LABEL]
    str wzr, [x20, #B_TAKE]
    ldrh w9, [x19, #S_MODE]
    tbz w9, #0, 21f
    LDX x9, cg_label
    str w9, [x20, #B_LABEL]
    add x9, x9, #2
    STX x9, cg_label
21: ldr w9, [x19, #S_MODETOK]
    cbz w9, 22f
    sub w9, w9, #1
    LDX x10, g_stmts
    add x10, x10, x9, lsl #5
    ldrh w11, [x10, #S_MODE]
    tbz w11, #0, 22f
    ldr w0, [x10, #S_VAR]
    bl cg_var_off
    str w0, [x20, #B_TAKE]
22: mov w9, #BK_LOOPS
    ldrh w10, [x19, #S_KIND]
    cmp w10, #SK_FOR
    b.ne 1f
    mov w9, #BK_FOR
1:  str w9, [x20, #B_KIND]
    LDX x9, cg_ldepth
    add x10, x9, #1
    STX x10, cg_ldepth
    mov w10, #NOREG
    cmp x9, #3
    b.hs 2f
    add w10, w9, #25
2:  str w10, [x20, #B_REG]
    ldr w9, [x19, #S_NPIECES]
    add w9, w9, #RT_VARS
    str w9, [x20, #B_LIMIT]
    add w9, w9, #4
    str w9, [x20, #B_SLOT]
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_roots
    ldr w21, [x10, x9, lsl #2]
    mov w0, w21
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne 3f
    str wzr, [x20, #B_DYN]
    ldr w9, [x0, #V_DATA]
    str w9, [x20, #B_LIMIT]
    b 4f
3:  mov w9, #1
    str w9, [x20, #B_DYN]
    mov w0, w21
    bl emit_expr
4:  mov x0, x20
    bl take_store
    ldr w9, [x20, #B_KIND]
    cmp w9, #BK_FOR
    b.eq .Llh_for
    ldr w22, [x20, #B_REG]
    ldr w9, [x20, #B_DYN]
    cbnz w9, 5f
    cmp w22, #NOREG
    b.eq 6f
    mov w0, w22
    ldr w1, [x20, #B_LIMIT]
    bl e_mov32
    b .Llh_loops_test
6:  mov w0, #9
    ldr w1, [x20, #B_LIMIT]
    bl e_mov32
    ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9000149
    b .Llh_loops_test
5:  cmp w22, #NOREG
    b.eq 7f
    MOV32 w0, 0x2A0003E0
    orr w0, w0, w22
    bl e_word
    b .Llh_loops_test
7:  ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9000140
.Llh_loops_test:
    ldr w9, [x20, #B_DYN]
    cbnz w9, 8f
    ldr w9, [x20, #B_LIMIT]
    cmp w9, #0
    b.gt .Llh_loops_top
8:  cmp w22, #NOREG
    b.eq 9f
    MOV32 w0, 0x7100001F
    orr w0, w0, w22, lsl #5
    bl e_word
    b 10f
9:  ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9400149
    WORD 0x7100013F
10: WORD 0x5400000D
    bl e_text_offset
    sub x0, x0, #4
    str w0, [x20, #B_INIT]
.Llh_loops_top:
    bl e_text_offset
    str w0, [x20, #B_TOP]
    b .Llh_done

.Llh_for:
    ldr w22, [x20, #B_REG]
    ldr w9, [x20, #B_DYN]
    cbz w9, 11f
    ldr w0, [x20, #B_LIMIT]
    bl emit_slot_addr
    WORD 0xB9000140
11: cmp w22, #NOREG
    b.eq 12f
    MOV32 w0, 0x2A1F03E0
    orr w0, w0, w22
    bl e_word
    b 13f
12: ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB900015F
13: ldr w9, [x20, #B_DYN]
    cbnz w9, 14f
    ldr w9, [x20, #B_LIMIT]
    cmp w9, #0
    b.gt .Llh_for_top
14: WORD 0x14000000
    bl e_text_offset
    sub x0, x0, #4
    str w0, [x20, #B_INIT]
.Llh_for_top:
    bl e_text_offset
    str w0, [x20, #B_TOP]
    ldr w0, [x19, #S_VAR]
    bl cg_var_off
    mov w23, w0
    cmp w22, #NOREG
    b.eq 15f
    mov w0, #10
    mov w1, w23
    bl e_addr
    MOV32 w0, 0xB9000140
    orr w0, w0, w22
    bl e_word
    ldr w0, [x19, #S_VAR]
    bl for_aliasable
    cbz w0, .Llh_done
    ldr w9, [x19, #S_VAR]
    str w9, [x20, #B_ALIAS]
    LDX x10, cg_vreg
    add w11, w22, #1
    orr w11, w11, #0x40
    strb w11, [x10, w9, uxtw]
    b .Llh_done
15: ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9400149
    mov w0, #10
    mov w1, w23
    bl e_addr
    WORD 0xB9000149
.Llh_done:
    LEAVE

patch_initial:
    stp x29, x30, [sp, #-32]!
    ldr w9, [x0, #B_INIT]
    cmn w9, #1
    b.eq 1f
    str x9, [sp, #16]
    bl e_text_offset
    mov x1, x0
    ldr x0, [sp, #16]
    bl patch_word
1:  ldp x29, x30, [sp], #32
    ret

emit_loop_tail:
    ENTER
    mov x20, x0
    ldr w9, [x20, #B_ALIAS]
    cmn w9, #1
    b.eq 1f
    LDX x10, cg_vreg
    strb wzr, [x10, w9, uxtw]
1:  ldr w0, [x20, #B_LABEL]
    cbz w0, 20f
    add w0, w0, #1
    bl place_label
20: ldr w22, [x20, #B_REG]
    ldr w9, [x20, #B_KIND]
    cmp w9, #BK_FOR
    b.ne .Llt_loops
    cmp w22, #NOREG
    b.eq 2f
    MOV32 w0, 0x11000400
    orr w0, w0, w22
    orr w0, w0, w22, lsl #5
    bl e_word
    b 3f
2:  ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9400149
    WORD 0x11000529
    WORD 0xB9000149
3:  mov x0, x20
    bl patch_initial
    cmp w22, #NOREG
    b.ne 4f
    ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9400149
    mov w22, #9
4:  ldr w9, [x20, #B_DYN]
    cbnz w9, 5f
    ldr w1, [x20, #B_LIMIT]
    mov w0, #11
    bl e_mov32
    b 6f
5:  ldr w0, [x20, #B_LIMIT]
    bl emit_slot_addr
    WORD 0xB940014B
6:  MOV32 w0, 0x6B0B001F
    orr w0, w0, w22, lsl #5
    bl e_word
    mov w0, #11
    ldr w1, [x20, #B_TOP]
    bl emit_rel_back
    b .Llt_done
.Llt_loops:
    cmp w22, #NOREG
    b.eq 7f
    MOV32 w0, 0x71000400
    orr w0, w0, w22
    orr w0, w0, w22, lsl #5
    bl e_word
    b 8f
7:  ldr w0, [x20, #B_SLOT]
    bl emit_slot_addr
    WORD 0xB9400149
    WORD 0x71000529
    WORD 0xB9000149
8:  mov w0, #1
    ldr w1, [x20, #B_TOP]
    bl emit_rel_back
    mov x0, x20
    bl patch_initial
.Llt_done:
    LEAVE

expr_safe:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_INT
    b.eq .Lxs_yes
    cmp w9, #VK_VAR
    b.eq .Lxs_var
    cmp w9, #VK_EXPR
    b.ne .Lxs_no
    ldrb w9, [x19, #V_NEG]
    cmp w9, #OP_NEG
    b.eq .Lxs_left
    cmp w9, #OP_DIV
    b.eq 1f
    cmp w9, #OP_MOD
    b.ne .Lxs_both
1:  ldr w0, [x19, #V_DATA_HI]
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Lxs_no
    ldr w9, [x0, #V_DATA]
    add w9, w9, #1
    cmp w9, #2
    b.ls .Lxs_no
.Lxs_both:
    ldr w0, [x19, #V_DATA_HI]
    bl expr_safe
    cbz w0, .Lxs_no
.Lxs_left:
    ldr w0, [x19, #V_DATA]
    bl expr_safe
    b .Lxs_ret
.Lxs_var:
    ldr w9, [x19, #V_DATA]
    LDX x10, cg_vreg
    ldrb w9, [x10, w9, uxtw]
    tbnz w9, #6, .Lxs_yes
    mov x9, #1
    STX x9, cg_bldata
.Lxs_yes:
    mov w0, #1
    b .Lxs_ret
.Lxs_no:
    mov w0, #0
.Lxs_ret:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

cond_leaves:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_OR
    b.eq .Lcl_or
    cmp w9, #VK_AND
    b.eq .Lcl_and
    cmp w9, #VK_CMP
    b.ne .Lcl_bad
    ldrb w9, [x19, #V_TYPE]
    cmp w9, #TY_INT
    b.eq 1f
    cmp w9, #TY_BOOL
    b.ne .Lcl_bad
1:  ldr w0, [x19, #V_DATA]
    bl expr_safe
    cbz w0, .Lcl_bad
    ldr w0, [x19, #V_DATA_HI]
    bl expr_safe
    cbz w0, .Lcl_bad
    mov w0, #1
    b .Lcl_ret
.Lcl_and:
    mov x9, #1
    STX x9, cg_bland
.Lcl_or:
    ldr w0, [x19, #V_DATA]
    bl cond_leaves
    tbnz w0, #31, .Lcl_ret
    mov w20, w0
    ldr w0, [x19, #V_DATA_HI]
    bl cond_leaves
    tbnz w0, #31, .Lcl_ret
    add w0, w0, w20
    b .Lcl_ret
.Lcl_bad:
    mov w0, #-1
.Lcl_ret:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

bl_emit:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_OR
    b.ne 1f
    ldr w0, [x19, #V_DATA]
    bl bl_emit
    ldr w0, [x19, #V_DATA_HI]
    bl bl_emit
    b 2f
1:  mov x0, x19
    bl emit_compare
    eor w9, w0, #1
    MOV32 w0, 0x1A9F07E1
    orr w0, w0, w9, lsl #12
    bl e_word
    LDX x9, cg_blacc
    MOV32 w0, 0x2A010000
    orr w0, w0, w9
    orr w0, w0, w9, lsl #5
    bl e_word
2:  ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

bl_sign:
    ENTER
    bl cg_node_addr
    mov x19, x0
    ldrb w9, [x19, #V_KIND]
    cmp w9, #VK_CMP
    b.ne .Lbs_no
    ldrb w9, [x19, #V_NEG]
    ldr w20, [x19, #V_DATA]
    ldr w21, [x19, #V_DATA_HI]
    cmp w9, #CMP_LT
    b.eq 1f
    cmp w9, #CMP_GT
    b.ne .Lbs_no
    mov w9, w20
    mov w20, w21
    mov w21, w9
1:  mov w0, w21
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Lbs_no
    ldr w9, [x0, #V_DATA]
    cbnz w9, .Lbs_no
    mov w0, w20
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.eq .Lbs_no
    mov w0, w20
    bl emit_expr
    mov w0, #1
    b .Lbs_ret
.Lbs_no:
    mov w0, #0
.Lbs_ret:
    LEAVE

try_branchless:
    ENTER
    LDX x19, cg_cur
    LDX x9, cg_depth
    cmp x9, #5
    b.hs .Ltb_no
    LDX x9, g_stmts
    sub x9, x19, x9
    lsr x9, x9, #5
    add w9, w9, #2
    ldr w10, [x19, #S_PIECES]
    cmp w10, w9
    b.ne .Ltb_no
    LDX x10, g_nstmt
    cmp x9, x10
    b.hs 1f
    mov w0, w9
    bl cg_stmt_ptr
    ldrh w9, [x0, #S_KIND]
    cmp w9, #SK_ELSE
    b.eq .Ltb_no
1:  add x20, x19, #32
    ldrh w9, [x20, #S_KIND]
    cmp w9, #SK_DECL
    b.eq 2f
    cmp w9, #SK_ASSIGN
    b.ne .Ltb_no
2:  ldrh w9, [x20, #S_MODE]
    cmp w9, #TY_INT
    b.ne .Ltb_no
    ldr w9, [x20, #S_NPARTS]
    cbz w9, .Ltb_no
    ldr w9, [x20, #S_PARTS]
    LDX x10, g_roots
    ldr w0, [x10, x9, lsl #2]
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_EXPR
    b.ne .Ltb_no
    ldrb w21, [x0, #V_NEG]
    ldr w22, [x0, #V_DATA]
    ldr w23, [x0, #V_DATA_HI]
    cmp w21, #OP_SUB
    b.eq 3f
    cmp w21, #OP_ADD
    b.ne .Ltb_no
    mov w0, w23
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.eq 3f
    mov w9, w22
    mov w22, w23
    mov w23, w9
3:  mov w0, w22
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_VAR
    b.ne .Ltb_no
    ldr w9, [x0, #V_DATA]
    ldr w10, [x20, #S_VAR]
    cmp w9, w10
    b.ne .Ltb_no
    STX x9, cg_blvar
    mov w0, w23
    bl cg_node_addr
    ldrb w9, [x0, #V_KIND]
    cmp w9, #VK_INT
    b.ne .Ltb_no
    ldr w9, [x0, #V_DATA]
    cmp w21, #OP_SUB
    b.ne 4f
    neg w9, w9
4:  sxtw x9, w9
    STX x9, cg_blk
    ldr w9, [x19, #S_PARTS]
    LDX x10, g_roots
    ldr w24, [x10, x9, lsl #2]
    STX xzr, cg_bldata
    STX xzr, cg_bland
    mov w0, w24
    bl cond_leaves
    cmp w0, #1
    b.lt .Ltb_no
    cmp w0, #4
    b.gt .Ltb_no
    LDX x9, cg_bldata
    cbz x9, .Ltb_no
    LDX x9, cg_bland
    cbnz x9, .Ltb_no
    LDX x9, cg_blk
    add x10, x9, #1
    cmp x10, #2
    b.hi .Ltb_generic
    cbz x9, .Ltb_generic
    mov w0, w24
    bl bl_sign
    cbz w0, .Ltb_generic
    LDX x0, cg_blvar
    bl emit_var_addr
    WORD 0xB9400141
    LDX x9, cg_blk
    MOV32 w0, 0x0B407C21
    cmp x9, #1
    b.eq 5f
    MOV32 w0, 0x4B407C21
5:  bl e_word
    WORD 0xB9000141
    b .Ltb_yes
.Ltb_generic:
    LDX x9, cg_depth
    add x10, x9, #19
    STX x10, cg_blacc
    add x9, x9, #1
    STX x9, cg_depth
    MOV32 w0, 0x2A1F03E0
    orr w0, w0, w10
    bl e_word
    mov w0, w24
    bl bl_emit
    LDX x9, cg_depth
    sub x9, x9, #1
    STX x9, cg_depth
    LDX x0, cg_blvar
    bl emit_var_addr
    WORD 0xB9400141
    LDX x9, cg_blk
    LDX x22, cg_blacc
    cmp x9, #1
    b.eq 6f
    cmn x9, #1
    b.eq 7f
    mov w0, #2
    mov w1, w9
    bl e_mov32
    MOV32 w0, 0x1B020421
    orr w0, w0, w22, lsl #5
    bl e_word
    b 8f
6:  MOV32 w0, 0x0B000021
    orr w0, w0, w22, lsl #16
    bl e_word
    b 8f
7:  MOV32 w0, 0x4B000021
    orr w0, w0, w22, lsl #16
    bl e_word
8:  WORD 0xB9000141
.Ltb_yes:
    mov w0, #1
    b .Ltb_ret
.Ltb_no:
    mov w0, #0
.Ltb_ret:
    LEAVE
