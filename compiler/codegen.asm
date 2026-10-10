%include "defs.inc"
%include "state.inc"

extern rt_start, rt_size, rt_offsets
extern x64_text_base, x64_op_disp, x64_bytes, x64_imm8, x64_imm16, x64_imm32
extern x64_call_rel, x64_text_offset
extern elf_layout, elf_finish
extern pool_compact
extern el_R_va, el_T_off, el_T_va, el_D_va, el_entry, g_image

%define RT_FN_WRITE      0
%define RT_FN_WRITE_INT  4
%define RT_FN_WRITE_BOOL 8
%define RT_FN_WRITE_STR  12
%define RT_FN_FLUSH      16
%define RT_FN_DIV_ZERO   20
%define RT_FN_STR_EQ     24
%define RT_FN_INPUT_STR  28
%define RT_FN_INPUT_INT  32


section .bss
alignb 4
cg_line resd 1
cg_target resd 1
cg_depth resd 1

alignb 8
cg_otab   resq 1
cg_omask  resq 1
cg_rdelta resq 1
cg_patch  resq 1
cg_npatch resq 1
cg_lp     resq 1
cg_lpl    resq 1
cg_nlp    resq 1
cg_label  resq 1
cg_bdepth resq 1
cg_bstack resq 16 * (MAX_NEST + 1)
cg_ldepth resq 1
cg_vreg    resq 1
cg_vcount  resq 1
cg_touched resq 1
cg_nprom   resq 1
cg_tsp     resq 1
cg_prom    resd 8
cg_tstack  resd MAX_BLOCKS + 4
cg_md      resd 1
cg_treg    resd 1
cg_blfirst resd 1
cg_blacc   resd 1
cg_blk     resd 1
cg_blvar   resd 1
cg_bldata  resd 1
cg_bland   resd 1
cg_bldry   resd 1
cg_poolnext resd 1
ja_x       resd 1
ja_rx      resd 1
ja_r0      resd 1
ja_a       resd 1
ja_b       resd 1
ja_u       resd 1
ja_step    resd 1
ja_first   resd 1
ja_end     resd 1
ja_start   resq 1
ja_A       resd 1
ja_B       resd 1
ja_k       resd 1
ja_lv      resd 1
ja_hoist   resd 1
ja_t       resd 1
ja_tok     resd 1
ja_p       resd 1
ja_split   resd 1
ja_tbyte   resd 1
jv_t       resd 1
jv_k       resd 1
jv_A       resd 8
jv_B       resd 8
bs_mode    resd 1
cg_skip    resq 1
cg_kv      resq 1
cg_kvok    resq 1
cg_vhi     resq 1
rg_state   resq 1
rg_list    resq 1
rg_n       resq 1
cg_dleft   resd 1
cg_nonneg  resd 1
cg_extra   resq 1
cg_inoff   resq 1
sv_t       resd 1
sv_sign    resd 1
sv_tkind   resd 1
sv_k       resd 1
sv_cond    resd 1
sv_nleaf   resd 1
sv_ndiv    resd 1
sv_nslot   resd 1
sv_iv      resd 1
sv_kslot   resd 1
sv_ld      resd 4
sv_lop     resd 4
sv_lc      resd 4
sv_lslot   resd 4
sv_lxmm    resd 4
sv_div     resd 4
sv_dslot   resd 4
sv_ldiv    resd 4
sv_V       resd 1
sv_lanes   resd 1
sv_xnext   resd 1
sv_stepr   resd 1
sv_ivr     resd 4
sv_res     resd 16

section .text

%macro OPD 3
    mov rax, %1
    mov r8d, %2
    mov ecx, %3
    call x64_op_disp
%endmacro

%macro BYTES 2
    mov rax, %1
    mov r8d, %2
    call x64_bytes
%endmacro

%macro CALL_RT 1
    mov ecx, [rt_offsets + %1]
    call x64_call_rel
%endmacro

FUNC codegen
    call pool_compact
    mov qword [cg_inoff], 0
    mov rax, [g_stmts]
    mov rcx, [g_nstmt]
    shl rcx, 5
    add rcx, rax
.in_scan:
    cmp rax, rcx
    jae .in_done
    cmp word [rax + S_KIND], SK_INPUT
    je .in_found
    add rax, S_SIZE
    jmp .in_scan
.in_found:
    mov rax, [g_vars_size]
    add rax, 15
    and rax, -16
    lea rcx, [rax + RT_VARS]
    mov [cg_inoff], rcx
    add rax, IN_SIZE
    mov [g_vars_size], rax
.in_done:
    call elf_layout
    mov rdi, [g_image]
    add rdi, [el_T_off]
    mov [x64_text_base], rdi
    lea rsi, [rt_start]
    mov ecx, [rt_size]
    rep movsb
    mov rbx, [el_R_va]
    sub rbx, [el_D_va]
    mov [cg_rdelta], rbx
    push rdi
    mov rcx, [g_nparts]
    add rcx, 16
    shl rcx, 2
    call mem_alloc
    mov [cg_patch], rax
    mov rcx, [g_nparts]
    add rcx, [g_nstmt]
    add rcx, 16
    shl rcx, 3
    call mem_alloc
    mov [cg_lp], rax
    mov rcx, [g_nparts]
    add rcx, [g_nstmt]
    add rcx, 16
    shl rcx, 2
    add rax, rcx
    mov [cg_lpl], rax
    mov rcx, [g_nvars]
    add rcx, 16
    call mem_alloc
    mov [cg_vreg], rax
    mov rcx, [g_nvars]
    add rcx, 16
    shl rcx, 3
    call mem_alloc
    mov [cg_vcount], rax
    mov rcx, [g_nvars]
    add rcx, 16
    shl rcx, 2
    add rax, rcx
    mov [cg_touched], rax
    mov qword [cg_nprom], 0
    mov rcx, [g_nvars]
    add rcx, 16
    shl rcx, 4
    call mem_alloc
    mov [cg_kv], rax
    mov rcx, [g_nvars]
    add rcx, 16
    lea rdx, [rax + rcx * 4]
    mov [cg_vhi], rdx
    lea rdx, [rdx + rcx * 4]
    mov [rg_state], rdx
    lea rdx, [rdx + rcx * 4]
    mov [rg_list], rdx
    mov rcx, [g_nvars]
    add rcx, 16
    call mem_alloc
    mov [cg_kvok], rax
    mov rdx, [cg_vhi]
    mov rcx, [g_nvars]
    add rcx, 16
.vhi_init:
    mov dword [rdx + rcx * 4 - 4], -1
    dec rcx
    jnz .vhi_init
    mov qword [rg_n], 0
    pop rdi
    mov qword [cg_npatch], 0
    mov qword [cg_nlp], 0
    mov qword [cg_label], 1
    mov qword [cg_skip], 0
    mov dword [cg_poolnext], 7
    mov dword [cg_bldry], 0
    mov qword [cg_bdepth], 0
    mov qword [cg_ldepth], 0
    call outline_pass
.pad:
    call x64_text_offset
    test eax, 15
    jz .entry
    mov byte [rdi], 0xCC
    inc rdi
    jmp .pad
.entry:
    mov [el_entry], rax

    BYTES 0x3D8D4C, 3
    call x64_text_offset
    add rax, 4
    add rax, [el_T_va]
    mov rcx, [el_D_va]
    sub rcx, rax
    mov [rdi], ecx
    add rdi, 4
    cmp qword [cg_inoff], 0
    je .no_input
    mov r13, [cg_inoff]
    OPD 0x878D49, 3, r13d
    BYTES 0x38478949, 4
    BYTES 0x0447C741, 4
    mov edx, IN_SIZE
    call x64_imm32
.no_input:

    mov rbx, [el_R_va]
    sub rbx, [el_D_va]
    mov r12, [g_stmts]
    mov r13, [g_nstmt]
    shl r13, 5
    add r13, r12
.stmt:
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    call close_blocks
    cmp r12, r13
    jae .epilogue
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    cmp rax, [cg_skip]
    jb .next
    mov eax, [r12 + S_TOK]
    shl rax, 4
    add rax, [g_tokens]
    mov eax, [rax + T_LINE]
    mov [cg_line], eax
    cmp word [r12 + S_KIND], SK_OUT
    je .out
    cmp word [r12 + S_KIND], SK_IF
    je .if
    cmp word [r12 + S_KIND], SK_FOR
    je .loop
    cmp word [r12 + S_KIND], SK_LOOPS
    je .loop
    cmp word [r12 + S_KIND], SK_ELSE
    je .else
    cmp word [r12 + S_KIND], SK_BREAK
    je .jump
    cmp word [r12 + S_KIND], SK_CONTINUE
    je .jump
    cmp word [r12 + S_KIND], SK_GROUP
    je .group
    cmp word [r12 + S_KIND], SK_INPUT
    je .input

    call emit_store
    jmp .next

.input:
    call sync_out
    call emit_out_body
    call emit_input
    jmp .next

.jump:
    call emit_jump
    jmp .next

.group:
    call group_open
    jmp .next

.out:
    call sync_out
    mov eax, [r12 + S_VAR]
    test eax, eax
    jz .out_inline
    dec eax
    shl rax, 5
    add rax, [cg_otab]
    cmp dword [rax + 16], 2
    jb .out_inline
    mov ecx, [rax + 20]
    call x64_call_rel
    jmp .next
.out_inline:
    call emit_out_body
    jmp .next

.if:
    cmp qword [cg_bdepth], 0
    jne .if_kv_done
    call kv_invalidate
.if_kv_done:
    call try_branchless
    test eax, eax
    jz .if_branch
    add r12, S_SIZE
    jmp .next
.if_branch:
    mov rax, [cg_bdepth]
    shl rax, 7
    lea rcx, [cg_bstack]
    mov edx, [r12 + S_PIECES]
    mov [rcx + rax], rdx
    mov qword [rcx + rax + 8], BK_IF
    mov rdx, [cg_npatch]
    mov [rcx + rax + 16], rdx
    mov rdx, r12
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rcx + rax + 24], rdx
    inc qword [cg_bdepth]
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    xor edx, edx
    xor r8d, r8d
    call emit_cond
    jmp .next

.else:
    call kv_invalidate
    jmp .next

.loop:
    cmp qword [cg_ldepth], 0
    jne .loop_head
    call range_setup
    call promote_region
.loop_head:
    cmp qword [cg_bdepth], 0
    jne .loop_kv_done
    call kv_invalidate
.loop_kv_done:
    call emit_loop_head
    jmp .next

.next:
    add r12, S_SIZE
    jmp .stmt

.epilogue:
    CALL_RT RT_FN_FLUSH
    BYTES 0x000000E7B8, 5
    BYTES 0xFF31, 2
    BYTES 0x050F, 2
    call x64_text_offset
    mov rcx, rax
    call elf_finish
    ENDF

emit_store:
    push r14
    push r15
    push rsi
    call kv_record
    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov r14d, [rax + VR_OFF]
    add r14d, RT_VARS
    movzx r15d, word [r12 + S_MODE]
    mov dword [cg_treg], -1
    cmp r15d, TY_INT
    jne .treg_done
    mov ecx, [r12 + S_VAR]
    call var_reg
    mov [cg_treg], eax
.treg_done:
    cmp dword [r12 + S_NPARTS], 0
    je .store_default
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov esi, [rdx + rax * 4]
    mov [cg_target], esi
    shl rsi, 4
    add rsi, [g_parts]
    movzx eax, byte [rsi + V_KIND]
    cmp eax, VK_EXPR
    je .store_expr
    cmp eax, VK_VAR
    je .copy_var
    cmp eax, VK_NULL
    je .store_default
    cmp eax, VK_STR
    je .store_str
    cmp r15d, TY_BOOL
    je .store_bool
    mov ecx, [cg_treg]
    test ecx, ecx
    js .store_imm_mem
    mov edx, [rsi + V_DATA]
    call emit_mov_reg_imm
    jmp .ret
.store_imm_mem:
    OPD 0x87C741, 3, r14d
    mov edx, [rsi + V_DATA]
    call x64_imm32
    jmp .ret
.store_expr:
    mov ecx, [r12 + S_VAR]
    mov edx, r14d
    call try_update_in_place
    test eax, eax
    jnz .ret
    mov ecx, [cg_target]
    call emit_expr
    mov edx, [cg_treg]
    test edx, edx
    js .store_expr_mem
    xor ecx, ecx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    jmp .ret
.store_expr_mem:
    OPD 0x878941, 3, r14d
    jmp .ret
.store_bool:
    OPD 0x87C641, 3, r14d
    mov edx, [rsi + V_DATA]
    call x64_imm8
    jmp .ret
.store_str:
    mov eax, [rsi + V_DATA]
    mov ecx, [cg_rdelta]
    add ecx, eax
    OPD 0x878D49, 3, ecx
    OPD 0x878949, 3, r14d
    lea ecx, [r14d + 8]
    OPD 0x87C74166, 4, ecx
    mov edx, [rsi + V_DATA + 4]
    call x64_imm16
    jmp .ret

.store_default:
    cmp r15d, TY_INT
    jne .def_not_int
    mov ecx, [cg_treg]
    test ecx, ecx
    js .def_int_mem
    mov r9d, 0x31
    call emit_rr
    jmp .ret
.def_int_mem:
    OPD 0x87C741, 3, r14d
    xor edx, edx
    call x64_imm32
    jmp .ret
.def_not_int:
    cmp r15d, TY_BOOL
    jne .def_str
    OPD 0x87C641, 3, r14d
    xor edx, edx
    call x64_imm8
    jmp .ret
.def_str:
    OPD 0x87C749, 3, r14d
    xor edx, edx
    call x64_imm32
    lea ecx, [r14d + 8]
    OPD 0x87C74166, 4, ecx
    xor edx, edx
    call x64_imm16
    jmp .ret

.copy_var:
    mov eax, [rsi + V_DATA]
    push rax
    shl rax, 5
    add rax, [g_vars]
    mov esi, [rax + VR_OFF]
    add esi, RT_VARS
    pop rcx
    cmp r15d, TY_INT
    jne .copy_not_int
    call var_reg
    test eax, eax
    js .copy_src_mem
    mov ecx, eax
    xor edx, edx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    jmp .copy_dst
.copy_src_mem:
    OPD 0x878B41, 3, esi
.copy_dst:
    mov edx, [cg_treg]
    test edx, edx
    js .copy_dst_mem
    xor ecx, ecx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    jmp .ret
.copy_dst_mem:
    OPD 0x878941, 3, r14d
    jmp .ret
.copy_not_int:
    cmp r15d, TY_BOOL
    jne .copy_str
    OPD 0x878A41, 3, esi
    OPD 0x878841, 3, r14d
    jmp .ret
.copy_str:
    OPD 0x878B49, 3, esi
    OPD 0x878949, 3, r14d
    lea ecx, [esi + 8]
    OPD 0x878B4166, 4, ecx
    lea ecx, [r14d + 8]
    OPD 0x87894166, 4, ecx
    jmp .ret
.ret:
    pop rsi
    pop r15
    pop r14
    ret

node_addr:
    mov eax, ecx
    shl rax, 4
    add rax, [g_parts]
    ret

var_disp:
    mov eax, [rax + V_DATA]
    shl rax, 5
    add rax, [g_vars]
    mov eax, [rax + VR_OFF]
    add eax, RT_VARS
    ret

try_update_in_place:
    push rsi
    push rbx
    mov ebx, ecx
    mov esi, edx
    mov ecx, [cg_target]
    call node_addr
    mov r9, rax
    movzx eax, byte [r9 + V_NEG]
    mov r10d, eax
    mov ecx, [r9 + V_DATA]
    mov edx, [r9 + V_DATA + 4]
    cmp eax, OP_SUB
    je .check
    cmp eax, OP_ADD
    jne .no
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .check
    xchg ecx, edx
.check:
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .no
    cmp [rax + V_DATA], ebx
    jne .no
    mov ecx, edx
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .no
    mov r11d, [rax + V_DATA]
    cmp r10d, OP_SUB
    jne .add
    neg r11d
.add:
    mov ecx, [cg_treg]
    test ecx, ecx
    js .add_mem
    mov r9d, 0xFF
    mov edx, 0xC0
    cmp r11d, 1
    je .reg_short
    mov edx, 0xC8
    cmp r11d, -1
    je .reg_short
    mov r9d, 0x81
    mov edx, 0xC0
    push r11
    call emit_reg_short
    pop rdx
    call x64_imm32
    jmp .yes
.reg_short:
    call emit_reg_short
    jmp .yes
.add_mem:
    cmp r11d, 1
    je .inc
    cmp r11d, -1
    je .dec
    OPD 0x878141, 3, esi
    mov edx, r11d
    call x64_imm32
    jmp .yes
.inc:
    OPD 0x87FF41, 3, esi
    jmp .yes
.dec:
    OPD 0x8FFF41, 3, esi
.yes:
    mov eax, 1
    pop rbx
    pop rsi
    ret
.no:
    xor eax, eax
    pop rbx
    pop rsi
    ret

emit_expr:
    push rsi
    push rbx
    call node_addr
    mov rsi, rax
    movzx eax, byte [rsi + V_KIND]
    cmp eax, VK_INT
    je .const
    cmp eax, VK_VAR
    je .var
    movzx ebx, byte [rsi + V_NEG]
    cmp ebx, OP_NEG
    je .neg
    cmp ebx, OP_ADD
    jne .plain
    call try_reassoc
    test eax, eax
    jnz .done
.plain:
    mov ecx, [rsi + V_DATA + 4]
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .right_simple
    cmp ebx, OP_ADD
    je .try_left
    cmp ebx, OP_MUL
    jne .general
.try_left:
    mov ecx, [rsi + V_DATA]
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .left_simple
.general:
    mov ecx, [rsi + V_DATA]
    call emit_expr
    mov eax, [cg_depth]
    cmp eax, 4
    jae .spill
    inc dword [cg_depth]
    push rax
    shl eax, 16
    add eax, 0xC08941
    mov r8d, 3
    call x64_bytes
    mov ecx, [rsi + V_DATA + 4]
    call emit_expr
    pop rax
    dec dword [cg_depth]
    cmp ebx, OP_ADD
    je .reg_add
    cmp ebx, OP_MUL
    je .reg_mul
    cmp ebx, OP_SUB
    je .reg_sub
    push rax
    BYTES 0xC189, 2
    pop rax
    shl eax, 19
    add eax, 0xC08944
    mov r8d, 3
    call x64_bytes
    call apply_reg
    jmp .done
.reg_add:
    shl eax, 19
    add eax, 0xC00144
    mov r8d, 3
    call x64_bytes
    jmp .done
.reg_mul:
    shl eax, 24
    add eax, 0xC0AF0F41
    mov r8d, 4
    call x64_bytes
    jmp .done
.reg_sub:
    push rax
    shl eax, 16
    add eax, 0xC02941
    mov r8d, 3
    call x64_bytes
    pop rax
    shl eax, 19
    add eax, 0xC08944
    mov r8d, 3
    call x64_bytes
    jmp .done
.spill:
    BYTES 0x50, 1
    mov ecx, [rsi + V_DATA + 4]
    call emit_expr
    BYTES 0xC189, 2
    BYTES 0x58, 1
    call apply_reg
    jmp .done
.right_simple:
    mov ecx, [rsi + V_DATA]
    call emit_expr
    mov eax, [rsi + V_DATA]
    mov [cg_dleft], eax
    mov ecx, [rsi + V_DATA + 4]
    call apply_simple
    jmp .done
.left_simple:
    mov ecx, [rsi + V_DATA + 4]
    call emit_expr
    mov dword [cg_dleft], -1
    mov ecx, [rsi + V_DATA]
    call apply_simple
    jmp .done
.neg:
    mov ecx, [rsi + V_DATA]
    call emit_expr
    BYTES 0xD8F7, 2
    jmp .done
.const:
    mov edx, [rsi + V_DATA]
    test edx, edx
    jnz .const_mov
    BYTES 0xC031, 2
    jmp .done
.const_mov:
    BYTES 0xB8, 1
    mov edx, [rsi + V_DATA]
    call x64_imm32
    jmp .done
.var:
    mov ecx, [rsi + V_DATA]
    call var_reg
    test eax, eax
    js .var_mem
    mov ecx, eax
    xor edx, edx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    jmp .done
.var_mem:
    mov rax, rsi
    call var_disp
    mov r9d, eax
    OPD 0x878B41, 3, r9d
.done:
    pop rbx
    pop rsi
    ret

apply_simple:
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    je .var
    mov r9d, [rax + V_DATA]
    cmp ebx, OP_ADD
    je .add_imm
    cmp ebx, OP_SUB
    je .sub_imm
    cmp ebx, OP_MUL
    je .mul_imm
    cmp ebx, OP_DIV
    je .div_imm
    jmp .mod_imm
.add_imm:
    cmp r9d, 1
    je .inc
    cmp r9d, -1
    je .dec
    BYTES 0x05, 1
    mov edx, r9d
    jmp x64_imm32
.sub_imm:
    cmp r9d, 1
    je .dec
    cmp r9d, -1
    je .inc
    BYTES 0x2D, 1
    mov edx, r9d
    jmp x64_imm32
.inc:
    BYTES 0xC0FF, 2
    ret
.dec:
    BYTES 0xC8FF, 2
    ret
.mul_imm:
    call pow2_shift
    test eax, eax
    jz .mul_plain
    mov r9d, eax
    BYTES 0xE0C1, 2
    mov edx, r9d
    jmp x64_imm8
.mul_plain:
    cmp r9d, 3
    je .mul_lea2
    cmp r9d, 5
    je .mul_lea4
    cmp r9d, 9
    je .mul_lea8
    cmp qword [cg_ldepth], 0
    je .mul_imul
    cmp r9d, 3
    jl .mul_imul
    lea eax, [r9d + 1]
    test eax, r9d
    jz .mul_sub
    lea edx, [r9d - 1]
    lea eax, [r9d - 2]
    test eax, edx
    jz .mul_add
.mul_imul:
    BYTES 0xC069, 2
    mov edx, r9d
    jmp x64_imm32
.mul_lea2:
    BYTES 0x40048D, 3
    ret
.mul_lea4:
    BYTES 0x80048D, 3
    ret
.mul_lea8:
    BYTES 0xC0048D, 3
    ret
.mul_sub:
    bsf edx, eax
    mov r9d, 0x29
    jmp .mul_shift
.mul_add:
    bsf edx, edx
    mov r9d, 0x01
.mul_shift:
    push r9
    push rdx
    call dleft_reg
    pop rdx
    pop r9
    test eax, eax
    js .mul_copy
    push rax
    push r9
    push rdx
    BYTES 0xE0C1, 2
    pop rdx
    call x64_imm8
    pop r9
    pop rcx
    xor edx, edx
    mov r10d, 1
    jmp emit_rrop
.mul_copy:
    push r9
    push rdx
    BYTES 0xE0C1C189, 4
    pop rdx
    call x64_imm8
    pop r9
    mov eax, r9d
    or eax, 0xC800
    mov r8d, 2
    jmp x64_bytes
.div_imm:
    cmp r9d, 1
    je .div_one
    cmp r9d, -1
    jne .div_any
    BYTES 0xD8F7, 2
.div_one:
    ret
.div_any:
    call left_nonneg
    call neg_pow2
    push rax
    call pow2_shift
    test eax, eax
    jz .div_plain_pop
    cmp dword [cg_nonneg], 0
    je .div_pow2_signed
    push rax
    BYTES 0xE8C1, 2
    pop rdx
    call x64_imm8
    jmp .div_pow2_sign
.div_pow2_signed:
    push rax
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [r9d - 1]
    call x64_imm32
    BYTES 0xD001, 2
    BYTES 0xF8C1, 2
    pop rdx
    call x64_imm8
.div_pow2_sign:
    pop rax
    test eax, eax
    jz .div_done
    BYTES 0xD8F7, 2
.div_done:
    ret
.div_plain_pop:
    pop rax
.div_plain:
    call magic_quot
    test eax, eax
    jz .div_idiv
    test r9d, r9d
    jns .div_pos
    BYTES 0xDAF7, 2
.div_pos:
    BYTES 0xD089, 2
    ret
.div_idiv:
    BYTES 0xB9, 1
    mov edx, r9d
    call x64_imm32
    BYTES 0xF9F799, 3
    ret
.mod_imm:
    lea eax, [r9d + 1]
    cmp eax, 2
    ja .mod_any
    BYTES 0xC031, 2
    ret
.mod_any:
    call left_nonneg
    call neg_pow2
    call pow2_shift
    test eax, eax
    jz .mod_plain
    cmp dword [cg_nonneg], 0
    je .mod_pow2_signed
    BYTES 0x25, 1
    lea edx, [r9d - 1]
    jmp x64_imm32
.mod_pow2_signed:
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [r9d - 1]
    call x64_imm32
    BYTES 0x100C8D, 3
    BYTES 0xE181, 2
    mov edx, r9d
    neg edx
    call x64_imm32
    BYTES 0xC829, 2
    ret
.mod_plain:
    call magic_quot
    test eax, eax
    jz .mod_idiv
    BYTES 0xD269, 2
    mov edx, r9d
    neg edx
    cmovs edx, r9d
    call x64_imm32
    BYTES 0xD029, 2
    ret
.mod_idiv:
    BYTES 0xB9, 1
    mov edx, r9d
    call x64_imm32
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    ret
.var:
    push rax
    mov ecx, [rax + V_DATA]
    call var_reg
    mov ecx, eax
    pop rax
    test ecx, ecx
    js .var_mem
    xor edx, edx
    mov r10d, 1
    mov r9d, 0x01
    cmp ebx, OP_ADD
    je emit_rrop
    mov r9d, 0x29
    cmp ebx, OP_SUB
    je emit_rrop
    cmp ebx, OP_MUL
    je .mul_reg
    mov edx, 1
    mov r9d, 0x89
    call emit_rrop
    jmp checked_div
.mul_reg:
    mov edx, ecx
    xor ecx, ecx
    mov r9d, 0xAF0F
    mov r10d, 2
    jmp emit_rrop
.var_mem:
    call var_disp
    mov r9d, eax
    cmp ebx, OP_ADD
    je .add_mem
    cmp ebx, OP_SUB
    je .sub_mem
    cmp ebx, OP_MUL
    je .mul_mem
    OPD 0x8F8B41, 3, r9d
    jmp checked_div
.add_mem:
    OPD 0x870341, 3, r9d
    ret
.sub_mem:
    OPD 0x872B41, 3, r9d
    ret
.mul_mem:
    OPD 0x87AF0F41, 4, r9d
    ret

neg_pow2:
    xor eax, eax
    test r9d, r9d
    jns .r
    cmp r9d, -2
    jg .r
    cmp r9d, 0x80000000
    je .r
    mov edx, r9d
    neg edx
    lea eax, [rdx - 1]
    test eax, edx
    mov eax, 0
    jnz .r
    neg r9d
    mov eax, 1
.r:
    ret

abs_div:
    mov eax, r9d
    neg eax
    cmovs eax, r9d
    ret

magic_of:
    push r10
    push r11
    push rcx
    xor eax, eax
    cmp r9d, 0x80000000
    je .fail
    call abs_div
    cmp eax, 2
    jb .fail
    mov r10d, eax
    xor ecx, ecx
.try:
    mov r11d, 1
    add ecx, 32
    shl r11, cl
    sub ecx, 32
    lea rax, [r11 - 1]
    xor edx, edx
    div r10
    inc rax
    mov rdx, rax
    imul rdx, r10
    sub rdx, r11
    mov r11d, 2
    shl r11, cl
    cmp rdx, r11
    ja .next
    mov r11, rax
    shr r11, 32
    jnz .next
    lea edx, [ecx + 32]
    jmp .out
.next:
    inc ecx
    cmp ecx, 32
    jb .try
.fail:
    xor eax, eax
.out:
    pop rcx
    pop r11
    pop r10
    ret

magic_quot:
    xor eax, eax
    cmp qword [cg_ldepth], 0
    je .r
    call magic_of
    test eax, eax
    jz .r
    push rdx
    push rax
    cmp dword [cg_nonneg], 0
    je .signed
    BYTES 0xBA, 1
    pop rdx
    call x64_imm32
    BYTES 0xEAC148D0AF0F48, 7
    pop rdx
    call x64_imm8
    mov eax, 1
    ret
.signed:
    BYTES 0xC86348, 3
    BYTES 0xBA, 1
    pop rdx
    call x64_imm32
    BYTES 0xFAC148D1AF0F48, 7
    pop rdx
    call x64_imm8
    BYTES 0xCA291FF9C1, 5
    mov eax, 1
.r:
    ret

pow2_shift:
    xor eax, eax
    cmp r9d, 2
    jl .r
    lea edx, [r9d - 1]
    test edx, r9d
    jnz .r
    bsf eax, r9d
.r:
    ret

apply_reg:
    cmp ebx, OP_ADD
    je .add
    cmp ebx, OP_SUB
    je .sub
    cmp ebx, OP_MUL
    je .mul
    jmp checked_div
.add:
    BYTES 0xC801, 2
    ret
.sub:
    BYTES 0xC829, 2
    ret
.mul:
    BYTES 0xC1AF0F, 3
    ret

checked_div:
    BYTES 0x0A75C985, 4
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x64_imm32
    mov ecx, [rt_offsets + RT_FN_DIV_ZERO]
    call x64_call_rel
    BYTES 0x0475FFF983, 5
    cmp ebx, OP_DIV
    jne .mod
    BYTES 0x03EBD8F7, 4
    BYTES 0xF9F799, 3
    ret
.mod:
    BYTES 0x05EBC031, 4
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    ret

emit_out_body:
    push r14
    push r15
    push rsi
    mov r14d, [r12 + S_PIECES]
    mov r15d, [r12 + S_NPIECES]
    add r15d, r14d
.bpiece:
    cmp r14d, r15d
    jae .body_done
    mov esi, r14d
    shl rsi, 4
    add rsi, [g_pieces]
    inc r14d
    mov eax, [rsi + P_KIND]
    cmp eax, PK_TEXT
    jne .bpiece_var
    cmp dword [rsi + P_B], 0
    je .bpiece
    mov eax, [rsi + P_A]
    lea ecx, [ebx + eax]
    OPD 0x8F8D49, 3, ecx
    BYTES 0xBA, 1
    mov edx, [rsi + P_B]
    call x64_imm32
    CALL_RT RT_FN_WRITE
    jmp .bpiece
.bpiece_var:
    cmp eax, PK_EXPR
    jne .bpiece_plain
    mov ecx, [rsi + P_A]
    call emit_expr
    BYTES 0xC189, 2
    CALL_RT RT_FN_WRITE_INT
    jmp .bpiece
.bpiece_plain:
    mov ecx, [rsi + P_A]
    add ecx, RT_VARS
    cmp eax, PK_INT
    jne .bpiece_not_int
    OPD 0x8F8B41, 3, ecx
    CALL_RT RT_FN_WRITE_INT
    jmp .bpiece
.bpiece_not_int:
    cmp eax, PK_BOOL
    jne .bpiece_str
    OPD 0x8FB60F41, 4, ecx
    CALL_RT RT_FN_WRITE_BOOL
    jmp .bpiece
.bpiece_str:
    OPD 0x8F8D49, 3, ecx
    CALL_RT RT_FN_WRITE_STR
    jmp .bpiece
.body_done:
    pop rsi
    pop r15
    pop r14
    ret


outline_pass:
    mov rcx, [g_nstmt]
    inc rcx
    shl rcx, 1
    mov eax, 16
.cap:
    cmp rax, rcx
    jae .cap_ok
    shl rax, 1
    jmp .cap
.cap_ok:
    lea rdx, [rax - 1]
    mov [cg_omask], rdx
    shl rax, 5
    mov rcx, rax
    push rdi
    call mem_alloc
    pop rdi
    mov [cg_otab], rax

    mov r12, [g_stmts]
    mov r13, [g_nstmt]
    shl r13, 5
    add r13, r12
.scan:
    cmp r12, r13
    jae .emit
    cmp word [r12 + S_KIND], SK_OUT
    jne .scan_next
    mov dword [r12 + S_VAR], 0
    mov ecx, [r12 + S_NPIECES]
    test ecx, ecx
    jz .scan_next
    mov esi, [r12 + S_PIECES]
    shl rsi, 4
    add rsi, [g_pieces]
    mov r14d, ecx
    shl r14, 4
    xor ecx, ecx
.kinds:
    cmp rcx, r14
    jae .kinds_ok
    cmp dword [rsi + rcx + P_KIND], PK_EXPR
    je .scan_next
    add rcx, P_SIZE
    jmp .kinds
.kinds_ok:
    mov rax, 0xcbf29ce484222325
    mov r9, 0x100000001b3
    xor ecx, ecx
.hash:
    cmp rcx, r14
    jae .hashed
    xor rax, [rsi + rcx]
    imul rax, r9
    add rcx, 8
    jmp .hash
.hashed:
    mov r10, rax
    mov r11, rax
    and r11, [cg_omask]
.probe:
    mov r15, r11
    shl r15, 5
    add r15, [cg_otab]
    cmp qword [r15 + 8], 0
    je .insert
    cmp [r15], r10
    jne .probe_next
    mov eax, [r12 + S_NPIECES]
    cmp [r15 + 24], eax
    jne .probe_next
    mov rax, [r15 + 8]
    mov eax, [rax + S_PIECES]
    shl rax, 4
    add rax, [g_pieces]
    xor ecx, ecx
.cmp_loop:
    cmp rcx, r14
    jae .cmp_equal
    mov rdx, [rsi + rcx]
    cmp rdx, [rax + rcx]
    jne .probe_next
    add rcx, 8
    jmp .cmp_loop
.cmp_equal:
    inc dword [r15 + 16]
    jmp .mark
.probe_next:
    inc r11
    and r11, [cg_omask]
    jmp .probe
.insert:
    mov [r15], r10
    mov [r15 + 8], r12
    mov dword [r15 + 16], 1
    mov eax, [r12 + S_NPIECES]
    mov [r15 + 24], eax
.mark:
    lea eax, [r11d + 1]
    mov [r12 + S_VAR], eax
.scan_next:
    add r12, S_SIZE
    jmp .scan

.emit:
    xor r14d, r14d
    mov r13, [cg_omask]
    inc r13
.emit_loop:
    cmp r14, r13
    jae .emit_done
    mov r15, r14
    shl r15, 5
    add r15, [cg_otab]
    cmp qword [r15 + 8], 0
    je .emit_next
    cmp dword [r15 + 16], 2
    jb .emit_next
    call x64_text_offset
    mov [r15 + 20], eax
    BYTES 0x50, 1
    mov r12, [r15 + 8]
    call emit_out_body
    BYTES 0xC359, 2
.emit_next:
    inc r14
    jmp .emit_loop
.emit_done:
    ret

else_of:
    xor eax, eax
    cmp rbx, [g_nstmt]
    jae .r
    mov rdx, rbx
    shl rdx, 5
    add rdx, [g_stmts]
    cmp word [rdx + S_KIND], SK_ELSE
    jne .r
    mov ecx, [rdx + S_VAR]
    cmp rcx, [rsi + 24]
    jne .r
    mov rax, rdx
.r:
    ret

record_patch:
    call x64_text_offset
    mov r9, [r8]
    mov [rcx + r9 * 4], eax
    inc qword [r8]
    mov dword [rdi], 0
    add rdi, 4
    ret

patch_list:
    call x64_text_offset
    mov r8, rax
.loop:
    cmp r9, r10
    jae .done
    mov edx, [rcx + r9 * 4]
    mov r11d, r8d
    sub r11d, edx
    sub r11d, 4
    mov rax, [x64_text_base]
    mov [rax + rdx], r11d
    inc r9
    jmp .loop
.done:
    ret

close_blocks:
    push rbx
    push rsi
    mov rbx, rax
.loop:
    mov rax, [cg_bdepth]
    test rax, rax
    jz .done
    dec rax
    shl rax, 7
    lea rsi, [cg_bstack]
    add rsi, rax
    cmp [rsi], rbx
    jne .done
    cmp qword [rsi + 8], BK_GROUP
    je .close_group
    cmp qword [rsi + 8], BK_IF
    jne .close_loop
    call else_of
    test rax, rax
    jz .plain_if
    push rax
    BYTES 0xE9, 1
    call emit_rel32_fwd
    push rax
    mov r9, [rsi + 16]
    mov rcx, [cg_patch]
    mov r10, [cg_npatch]
    push r9
    call patch_list
    pop r9
    pop rax
    mov rcx, [cg_patch]
    mov [rcx + r9 * 4], eax
    lea rdx, [r9 + 1]
    mov [cg_npatch], rdx
    pop rax
    mov edx, [rax + S_PIECES]
    mov [rsi], rdx
    mov qword [rsi + 24], -1
    jmp .loop
.plain_if:
    mov r9, [rsi + 16]
    mov rcx, [cg_patch]
    mov r10, [cg_npatch]
    push r9
    call patch_list
    pop r9
    mov [cg_npatch], r9
    dec qword [cg_bdepth]
    jmp .loop
.close_group:
    mov ecx, [rsi + 120]
    call place_label
    call take_clear
    dec qword [cg_bdepth]
    jmp .loop
.close_loop:
    call emit_loop_tail
    mov ecx, [rsi + 120]
    test ecx, ecx
    jz .no_exit
    call place_label
.no_exit:
    call take_clear
    call emit_loop_merge
    dec qword [cg_bdepth]
    dec qword [cg_ldepth]
    jnz .loop
    call unpromote
    jmp .loop
.done:
    pop rsi
    pop rbx
    ret

emit_jump:
    push rsi
    mov rax, [cg_bdepth]
    shl rax, 7
    lea rsi, [cg_bstack]
    add rsi, rax
.find:
    sub rsi, 128
    cmp word [r12 + S_MODE], 0
    jne .group
    cmp qword [rsi + 8], BK_FOR
    je .found
    cmp qword [rsi + 8], BK_LOOPS
    je .found
    jmp .find
.group:
    cmp qword [rsi + 8], BK_GROUP
    jne .find
    mov eax, [r12 + S_VAR]
    cmp [rsi + 24], rax
    jne .find
    cmp qword [rsi + 32], 0
    jne .found
    call flush_prom
.found:
    BYTES 0xE9, 1
    mov ecx, [rsi + 120]
    cmp word [r12 + S_KIND], SK_CONTINUE
    jne .emit
    inc ecx
.emit:
    call jump_to_label
    pop rsi
    ret

emit_input:
    push rbx
    push rsi
    mov ecx, [r12 + S_VAR]
    mov rdx, [cg_kvok]
    mov byte [rdx + rcx], 0
    mov rax, rcx
    shl rax, 5
    add rax, [g_vars]
    mov ebx, [rax + VR_OFF]
    add ebx, RT_VARS
    movzx esi, word [rax + VR_TYPE]
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x64_imm32
    cmp esi, TY_INT
    je .int
    OPD 0x8F8D49, 3, ebx
    CALL_RT RT_FN_INPUT_STR
    jmp .r
.int:
    CALL_RT RT_FN_INPUT_INT
    mov ecx, [r12 + S_VAR]
    call var_reg
    test eax, eax
    js .mem
    mov edx, eax
    xor ecx, ecx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    jmp .r
.mem:
    OPD 0x878941, 3, ebx
.r:
    pop rsi
    pop rbx
    ret

group_open:
    cmp word [r12 + S_MODE], 0
    je .r
    cmp qword [cg_bdepth], 0
    jne .kv_done
    call kv_invalidate
.kv_done:
    mov rax, [cg_bdepth]
    shl rax, 7
    lea rcx, [cg_bstack]
    add rcx, rax
    inc qword [cg_bdepth]
    mov edx, [r12 + S_PIECES]
    mov [rcx], rdx
    mov qword [rcx + 8], BK_GROUP
    mov rdx, r12
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rcx + 24], rdx
    mov rdx, [cg_ldepth]
    mov [rcx + 32], rdx
    mov rax, [cg_label]
    mov [rcx + 120], eax
    inc qword [cg_label]
    mov dword [rcx + 124], 0
    test word [r12 + S_MODE], 1
    jz .r
    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov eax, [rax + VR_OFF]
    add eax, RT_VARS
    mov [rcx + 124], eax
.r:
    ret

take_store:
    mov ecx, [rsi + 124]
    test ecx, ecx
    jz .r
    cmp qword [rsi + 40], 0
    jne .dyn
    OPD 0x87C741, 3, ecx
    mov rdx, [rsi + 48]
    jmp x64_imm32
.dyn:
    OPD 0x878941, 3, ecx
.r:
    ret

take_clear:
    mov ecx, [rsi + 124]
    test ecx, ecx
    jz .r
    OPD 0x87C741, 3, ecx
    xor edx, edx
    jmp x64_imm32
.r:
    ret

jump_to_end:
    mov rcx, [cg_patch]
    lea r8, [cg_npatch]
    jmp record_patch

jump_to_label:
    test ecx, ecx
    jz jump_to_end
    call x64_text_offset
    mov rdx, [cg_nlp]
    mov r8, [cg_lp]
    mov [r8 + rdx * 4], eax
    mov r8, [cg_lpl]
    mov [r8 + rdx * 4], ecx
    inc qword [cg_nlp]
    mov dword [rdi], 0
    add rdi, 4
    ret

place_label:
    call x64_text_offset
    mov r9, rax
    xor r10d, r10d
    xor r11d, r11d
.l:
    cmp r10, [cg_nlp]
    jae .done
    mov r8, [cg_lpl]
    mov edx, [r8 + r10 * 4]
    mov r8, [cg_lp]
    mov eax, [r8 + r10 * 4]
    cmp edx, ecx
    jne .keep
    mov edx, r9d
    sub edx, eax
    sub edx, 4
    mov r8, [x64_text_base]
    mov [r8 + rax], edx
    jmp .n
.keep:
    mov [r8 + r11 * 4], eax
    mov r8, [cg_lpl]
    mov [r8 + r11 * 4], edx
    inc r11
.n:
    inc r10
    jmp .l
.done:
    mov [cg_nlp], r11
    ret

emit_cond:
    push rsi
    push rbx
    push r12
    mov ebx, edx
    mov r12d, r8d
    call node_addr
    mov rsi, rax
    movzx eax, byte [rsi + V_KIND]
    cmp eax, VK_BOOL
    je .const
    cmp eax, VK_OR
    je .or
    cmp eax, VK_AND
    je .and
    call emit_compare
    test ebx, ebx
    jnz .jcc
    xor eax, 1
.jcc:
    shl eax, 8
    or eax, 0x800F
    mov r8d, 2
    call x64_bytes
    jmp .record
.const:
    xor eax, eax
    cmp qword [rsi + V_DATA], 0
    setne al
    cmp eax, ebx
    jne .done
    BYTES 0xE9, 1
.record:
    mov ecx, r12d
    call jump_to_label
    jmp .done
.or:
    mov eax, 1
    jmp .pair
.and:
    xor eax, eax
.pair:
    cmp eax, ebx
    jne .split
    mov ecx, [rsi + V_DATA]
    mov edx, ebx
    mov r8d, r12d
    call emit_cond
    mov ecx, [rsi + V_DATA + 4]
    mov edx, ebx
    mov r8d, r12d
    call emit_cond
    jmp .done
.split:
    mov r8, [cg_label]
    inc qword [cg_label]
    push r8
    push r8
    mov edx, eax
    mov ecx, [rsi + V_DATA]
    call emit_cond
    mov ecx, [rsi + V_DATA + 4]
    mov edx, ebx
    mov r8d, r12d
    call emit_cond
    pop rcx
    pop rcx
    call place_label
.done:
    pop r12
    pop rbx
    pop rsi
    ret

try_divisible:
    xor eax, eax
    cmp qword [cg_ldepth], 0
    je .no
    cmp r14d, CMP_LT
    jae .no
    mov ecx, r13d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .no
    cmp dword [rax + V_DATA], 0
    jne .no
    mov ecx, r12d
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .no
    cmp byte [rax + V_NEG], OP_MOD
    jne .no
    push rax
    mov ecx, [rax + V_DATA + 4]
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .no
    mov r9d, [rax + V_DATA]
    cmp r9d, 0x80000000
    je .no
    call abs_div
    cmp eax, 2
    jb .no
    push rax
    mov ecx, [rcx + V_DATA]
    push rcx
    call node_addr
    pop rcx
    mov r9, [rsp]
    lea edx, [r9d - 1]
    test edx, r9d
    jz .gen
    cmp byte [rax + V_KIND], VK_VAR
    jne .gen
    mov edx, [rax + V_DATA]
    mov rax, [cg_vreg]
    movzx edx, byte [rax + rdx]
    test edx, 0x40
    jz .gen
    and edx, 0x1F
    lea ecx, [edx - 1]
    mov edx, 1
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    pop r9
    jmp .lemire_mul
.gen:
    call emit_expr
    pop r9
    lea edx, [r9d - 1]
    test edx, r9d
    jnz .lemire
    cmp edx, 0x7F
    ja .test32
    BYTES 0xA8, 1
    call x64_imm8
    jmp .zf
.test32:
    BYTES 0xA9, 1
    call x64_imm32
.zf:
    mov ecx, r14d
    call cc_of_op
    ret
.lemire:
    BYTES 0xC8480FD9F7C189, 7
.lemire_mul:
    mov r10d, r9d
    bsf ecx, r10d
    mov r11d, r10d
    shr r11d, cl
    mov eax, r11d
    mov r8d, 4
.newton:
    mov edx, r11d
    imul edx, eax
    neg edx
    add edx, 2
    imul eax, edx
    dec r8d
    jnz .newton
    push rcx
    push rax
    BYTES 0xC969, 2
    pop rdx
    call x64_imm32
    pop rcx
    test ecx, ecx
    jz .no_ror
    push rcx
    BYTES 0xC9C1, 2
    pop rdx
    call x64_imm8
.no_ror:
    BYTES 0xF981, 2
    mov eax, 0xFFFFFFFF
    xor edx, edx
    div r10d
    mov edx, eax
    call x64_imm32
    mov eax, 6
    cmp r14d, CMP_IS
    je .r
    mov eax, 7
.r:
    ret
.no:
    xor eax, eax
    ret

expr_safe:
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_INT
    je .yes
    cmp edx, VK_VAR
    je .var
    cmp edx, VK_EXPR
    jne .no
    movzx edx, byte [rax + V_NEG]
    cmp edx, OP_NEG
    je .left
    cmp edx, OP_DIV
    je .div
    cmp edx, OP_MOD
    jne .both
.div:
    push rax
    mov ecx, [rax + V_DATA + 4]
    call node_addr
    mov rcx, rax
    pop rax
    cmp byte [rcx + V_KIND], VK_INT
    jne .no
    mov edx, [rcx + V_DATA]
    add edx, 1
    cmp edx, 2
    jbe .no
.both:
    push rax
    mov ecx, [rax + V_DATA + 4]
    call expr_safe
    pop rcx
    test eax, eax
    jz .no
    mov rax, rcx
.left:
    mov ecx, [rax + V_DATA]
    jmp expr_safe
.var:
    mov edx, [rax + V_DATA]
    mov rax, [cg_vreg]
    test byte [rax + rdx], 0x40
    jnz .yes
    mov dword [cg_bldata], 1
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

cond_leaves:
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_OR
    je .or
    cmp edx, VK_AND
    je .and
    cmp edx, VK_CMP
    jne .bad
    movzx edx, byte [rax + V_TYPE]
    cmp edx, TY_INT
    je .typed
    cmp edx, TY_BOOL
    jne .bad
.typed:
    push rax
    mov ecx, [rax + V_DATA]
    call expr_safe
    pop rcx
    test eax, eax
    jz .bad
    mov ecx, [rcx + V_DATA + 4]
    call expr_safe
    test eax, eax
    jz .bad
    mov eax, 1
    ret
.or:
    push rax
    mov ecx, [rax + V_DATA]
    call cond_leaves
    pop rcx
    test eax, eax
    js .r
    push rax
    mov ecx, [rcx + V_DATA + 4]
    call cond_leaves
    pop rcx
    test eax, eax
    js .r
    add eax, ecx
.r:
    ret
.bad:
    mov eax, -1
    ret
.and:
    mov dword [cg_bland], 1
    jmp .or

bl_emit:
    push rsi
    call node_addr
    mov rsi, rax
    cmp byte [rsi + V_KIND], VK_OR
    jne .leaf
    mov ecx, [rsi + V_DATA]
    call bl_emit
    mov ecx, [rsi + V_DATA + 4]
    call bl_emit
    pop rsi
    ret
.leaf:
    call emit_compare
    lea r9d, [eax + 0x90]
    cmp dword [cg_blfirst], 0
    je .later
    mov dword [cg_blfirst], 0
    shl r9d, 16
    or r9d, 0x0F41
    mov eax, [cg_blacc]
    add eax, 0xC0
    shl eax, 24
    or eax, r9d
    mov r8d, 4
    call x64_bytes
    pop rsi
    ret
.later:
    shl r9d, 8
    or r9d, 0xC0000F
    mov eax, [cg_blacc]
    add eax, 0xC0
    shl eax, 16
    or eax, 0x0841
    shl rax, 24
    or rax, r9
    mov r8d, 6
    call x64_bytes
    pop rsi
    ret

try_branchless:
    push rbx
    push rsi
    cmp dword [cg_depth], 3
    jae .no
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    add eax, 2
    cmp [r12 + S_PIECES], eax
    jne .no
    cmp rax, [g_nstmt]
    jae .no_else
    mov rdx, rax
    shl rdx, 5
    add rdx, [g_stmts]
    cmp word [rdx + S_KIND], SK_ELSE
    je .no
.no_else:
    lea rsi, [r12 + S_SIZE]
    movzx eax, word [rsi + S_KIND]
    cmp eax, SK_DECL
    je .body_kind
    cmp eax, SK_ASSIGN
    jne .no
.body_kind:
    cmp word [rsi + S_MODE], TY_INT
    jne .no
    cmp dword [rsi + S_NPARTS], 0
    je .no
    mov eax, [rsi + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .no
    movzx ebx, byte [rax + V_NEG]
    mov ecx, [rax + V_DATA]
    mov edx, [rax + V_DATA + 4]
    cmp ebx, OP_SUB
    je .order_ok
    cmp ebx, OP_ADD
    jne .no
    push rdx
    call node_addr
    pop rdx
    cmp byte [rax + V_KIND], VK_INT
    jne .order_ok
    xchg ecx, edx
.order_ok:
    push rdx
    call node_addr
    pop rdx
    cmp byte [rax + V_KIND], VK_VAR
    jne .no
    mov eax, [rax + V_DATA]
    cmp eax, [rsi + S_VAR]
    jne .no
    mov [cg_blvar], eax
    mov ecx, edx
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .no
    mov eax, [rax + V_DATA]
    cmp ebx, OP_SUB
    jne .k_ok
    neg eax
.k_ok:
    mov [cg_blk], eax
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    mov dword [cg_bldata], 0
    mov dword [cg_bland], 0
    push rcx
    call cond_leaves
    pop rcx
    test eax, eax
    jle .no
    cmp eax, 4
    ja .no
    cmp dword [cg_bldata], 0
    je .no
    cmp dword [cg_bland], 0
    jne .no
    cmp dword [cg_bldry], 0
    jne .yes
    mov edx, [cg_blk]
    lea eax, [edx + 1]
    cmp eax, 2
    ja .sign_shr
    test edx, edx
    jz .sign_shr
    mov dword [bs_mode], 1
    push rcx
    call bl_sign
    pop rcx
    test eax, eax
    jz .generic
    mov ebx, 0xD0
    cmp dword [cg_blk], 1
    je .carry
    mov ebx, 0xD8
.carry:
    mov ecx, [cg_blvar]
    call var_reg
    test eax, eax
    js .carry_mem
    mov ecx, eax
    mov edx, ebx
    mov r9d, 0x83
    call emit_reg_short
    xor edx, edx
    call x64_imm8
    jmp .yes
.carry_mem:
    mov ecx, [cg_blvar]
    shl rcx, 5
    add rcx, [g_vars]
    mov ecx, [rcx + VR_OFF]
    add ecx, RT_VARS
    sub ebx, 0xC0
    or ebx, 0x87
    shl ebx, 16
    or ebx, 0x8341
    mov eax, ebx
    mov r8d, 3
    call x64_op_disp
    xor edx, edx
    call x64_imm8
    jmp .yes
.sign_shr:
    mov dword [bs_mode], 0
    push rcx
    call bl_sign
    pop rcx
    test eax, eax
    jz .generic
    xor ebx, ebx
    jmp .k_apply
.generic:
    mov eax, [cg_depth]
    mov [cg_blacc], eax
    mov dword [cg_blfirst], 1
    push rcx
    mov eax, [cg_blacc]
    imul eax, eax, 9
    add eax, 0xC0
    shl eax, 16
    or eax, 0x3145
    mov r8d, 3
    call x64_bytes
    pop rcx
    inc dword [cg_depth]
    call bl_emit
    dec dword [cg_depth]
    mov ebx, [cg_blacc]
    add ebx, 8
.k_apply:
    mov r9d, 0x01
    mov edx, [cg_blk]
    cmp edx, 1
    je .apply
    mov r9d, 0x29
    cmp edx, -1
    je .apply
    push rdx
    xor ecx, ecx
    mov edx, ebx
    mov r9d, 0x69
    mov r10d, 1
    call emit_rrop
    pop rdx
    call x64_imm32
    xor ebx, ebx
    mov r9d, 0x01
.apply:
    mov ecx, [cg_blvar]
    push r9
    call var_reg
    pop r9
    test eax, eax
    js .apply_mem
    mov edx, eax
    mov ecx, ebx
    mov r10d, 1
    call emit_rrop
    jmp .yes
.apply_mem:
    mov ecx, [cg_blvar]
    shl rcx, 5
    add rcx, [g_vars]
    mov ecx, [rcx + VR_OFF]
    add ecx, RT_VARS
    shl r9d, 8
    or r9d, 0x870041
    cmp ebx, 8
    jb .apply_rex
    or r9d, 4
.apply_rex:
    and ebx, 7
    shl ebx, 19
    or r9d, ebx
    mov eax, r9d
    mov r8d, 3
    call x64_op_disp
.yes:
    mov eax, 1
    pop rsi
    pop rbx
    ret
.no:
    xor eax, eax
    pop rsi
    pop rbx
    ret

bl_sign:
    push rcx
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_CMP
    jne .no
    movzx edx, byte [rax + V_NEG]
    mov r8d, [rax + V_DATA]
    mov r9d, [rax + V_DATA + 4]
    cmp edx, CMP_LT
    je .lt
    cmp edx, CMP_GT
    jne .no
    xchg r8d, r9d
.lt:
    mov ecx, r9d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .no
    cmp dword [rax + V_DATA], 0
    jne .no
    mov ecx, r8d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    je .no
    cmp dword [bs_mode], 0
    je .shr
    cmp byte [rax + V_KIND], VK_VAR
    jne .bt_expr
    push rcx
    mov ecx, [rax + V_DATA]
    call var_reg
    pop rcx
    test eax, eax
    js .bt_expr
    mov ecx, eax
    call reg_rex
    test eax, eax
    jz .bt_norex
    BYTES 0x41, 1
.bt_norex:
    and ecx, 7
    lea eax, [ecx + 0xE0]
    shl eax, 16
    or eax, 0xBA0F
    or eax, 0x1F000000
    mov r8d, 4
    call x64_bytes
    mov eax, 1
    ret
.bt_expr:
    call emit_expr
    BYTES 0x1FE0BA0F, 4
    mov eax, 1
    ret
.shr:
    call emit_expr
    BYTES 0x1FE8C1, 3
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

tree_uses:
    call node_addr
    movzx r8d, byte [rax + V_KIND]
    cmp r8d, VK_VAR
    je .var
    cmp r8d, VK_EXPR
    je .expr
    cmp r8d, VK_CMP
    je .both
    cmp r8d, VK_OR
    je .both
    cmp r8d, VK_AND
    je .both
    xor eax, eax
    ret
.var:
    xor r8d, r8d
    cmp [rax + V_DATA], edx
    sete r8b
    mov eax, r8d
    ret
.expr:
    cmp byte [rax + V_NEG], OP_NEG
    jne .both
    mov ecx, [rax + V_DATA]
    jmp tree_uses
.both:
    push rax
    mov ecx, [rax + V_DATA]
    call tree_uses
    pop rcx
    test eax, eax
    jnz .r
    mov ecx, [rcx + V_DATA + 4]
    jmp tree_uses
.r:
    ret

stmt_ptr:
    mov rax, rcx
    shl rax, 5
    add rax, [g_stmts]
    ret

stmt_root:
    mov eax, [rax + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    ret

ja_affine:
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .no
    mov dword [ja_b], 0
    movzx edx, byte [rax + V_NEG]
    cmp edx, OP_MUL
    je .mul
    cmp edx, OP_ADD
    je .add
    cmp edx, OP_SUB
    jne .no
    push rax
    mov ecx, [rax + V_DATA + 4]
    call node_addr
    mov rcx, rax
    pop rax
    cmp byte [rcx + V_KIND], VK_INT
    jne .no
    mov edx, [rcx + V_DATA]
    neg edx
    mov [ja_b], edx
    mov ecx, [rax + V_DATA]
    jmp .mul_node
.add:
    push rax
    mov ecx, [rax + V_DATA + 4]
    call node_addr
    mov rcx, rax
    pop rax
    cmp byte [rcx + V_KIND], VK_INT
    jne .add_left
    mov edx, [rcx + V_DATA]
    mov [ja_b], edx
    mov ecx, [rax + V_DATA]
    jmp .mul_node
.add_left:
    push rax
    mov ecx, [rax + V_DATA]
    call node_addr
    mov rcx, rax
    pop rax
    cmp byte [rcx + V_KIND], VK_INT
    jne .no
    mov edx, [rcx + V_DATA]
    mov [ja_b], edx
    mov ecx, [rax + V_DATA + 4]
.mul_node:
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .no
    cmp byte [rax + V_NEG], OP_MUL
    jne .no
.mul:
    mov ecx, [rax + V_DATA]
    mov edx, [rax + V_DATA + 4]
    push rax
    call node_addr
    mov r8, rax
    mov ecx, edx
    call node_addr
    mov r9, rax
    pop rax
    cmp byte [r8 + V_KIND], VK_VAR
    je .mul_order
    xchg r8, r9
.mul_order:
    cmp byte [r8 + V_KIND], VK_VAR
    jne .no
    mov edx, [r8 + V_DATA]
    cmp edx, [ja_x]
    jne .no
    cmp byte [r9 + V_KIND], VK_INT
    jne .no
    mov edx, [r9 + V_DATA]
    cmp edx, 1
    je .no
    mov [ja_a], edx
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

ja_scan:
    push rbx
    push r12
    mov ebx, [ja_first]
    inc ebx
.l:
    cmp ebx, [ja_end]
    jae .yes
    mov ecx, ebx
    call stmt_ptr
    mov r12, rax
    movzx edx, word [r12 + S_KIND]
    cmp edx, SK_IF
    je .if
    cmp edx, SK_DECL
    je .assign
    cmp edx, SK_ASSIGN
    jne .no
.assign:
    mov edx, [r12 + S_VAR]
    cmp edx, [ja_x]
    je .no
    cmp dword [ja_step], 0
    jne .assign_next
    cmp dword [r12 + S_NPARTS], 0
    je .assign_next
    mov rax, r12
    call stmt_root
    mov edx, [ja_lv]
    call tree_uses
    or [ja_step], eax
.assign_next:
    inc ebx
    jmp .l
.if:
    lea eax, [ebx + 2]
    cmp [r12 + S_PIECES], eax
    jne .no
    cmp eax, [ja_end]
    ja .no
    lea rax, [r12 + S_SIZE]
    mov edx, [rax + S_VAR]
    cmp edx, [ja_x]
    je .no
    mov dword [cg_bldry], 1
    call try_branchless
    mov dword [cg_bldry], 0
    test eax, eax
    jz .no
    mov eax, [cg_blvar]
    cmp dword [ja_t], -1
    jne .t_known
    mov [ja_t], eax
.t_known:
    cmp [ja_t], eax
    je .t_same
    mov dword [ja_tok], 0
.t_same:
    cmp dword [ja_step], 0
    jne .if_next
    mov rax, r12
    call stmt_root
    mov edx, [ja_lv]
    call tree_uses
    or [ja_step], eax
    lea rax, [r12 + S_SIZE]
    call stmt_root
    mov edx, [ja_lv]
    call tree_uses
    or [ja_step], eax
.if_next:
    add ebx, 2
    jmp .l
.yes:
    mov eax, 1
    jmp .r
.no:
    xor eax, eax
.r:
    pop r12
    pop rbx
    ret

ja_t_check:
    push rbx
    push r12
    mov ebx, [ja_first]
    inc ebx
.l:
    cmp ebx, [ja_end]
    jae .done
    mov ecx, ebx
    call stmt_ptr
    mov r12, rax
    cmp word [r12 + S_KIND], SK_IF
    je .if
    mov eax, [r12 + S_VAR]
    cmp eax, [ja_t]
    je .bad
    cmp dword [r12 + S_NPARTS], 0
    je .next1
    mov rax, r12
    call stmt_root
    mov edx, [ja_t]
    call tree_uses
    test eax, eax
    jnz .bad
.next1:
    inc ebx
    jmp .l
.if:
    mov rax, r12
    call stmt_root
    mov edx, [ja_t]
    call tree_uses
    test eax, eax
    jnz .bad
    add ebx, 2
    jmp .l
.bad:
    mov dword [ja_tok], 0
.done:
    pop r12
    pop rbx
    ret

emit_loop_merge:
    mov rax, [rsi + 112]
    test rax, rax
    jz .scalar
    push rax
    BYTES 0xEEE8700F66, 5
    BYTES 0xC5FE0F66, 4
    BYTES 0xC07E0F66, 4
    pop rax
    push rax
    movzx edx, al
    dec edx
    mov r9d, 0x01
    test eax, 0x80000000
    jz .vec_add
    mov r9d, 0x29
.vec_add:
    xor ecx, ecx
    mov r10d, 1
    call emit_rrop
    pop rax
    movzx edx, ah
    dec edx
    shr eax, 16
    movzx ecx, al
    dec ecx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    BYTES 0x00000200C48148, 7
.scalar:
    mov rax, [rsi + 104]
    test rax, rax
    jz .r
    movzx edx, al
    dec edx
    movzx ecx, ah
    dec ecx
    mov r9d, 0x01
    mov r10d, 1
    jmp emit_rrop
.r:
    ret

jv_check:
    xor eax, eax
    test byte [ja_u], 3
    jnz .r
    cmp dword [ja_u], 8
    ja .r
    cmp qword [rsi + 8], BK_FOR
    jne .mode_ok
    cmp qword [rsi + 88], 0
    je .r
.mode_ok:
    call x64_text_offset
    cmp rax, [rsi + 16]
    jne .no
    mov eax, [ja_first]
    add eax, 3
    cmp eax, [ja_end]
    jne .no
    mov ecx, [ja_first]
    inc ecx
    call stmt_ptr
    cmp word [rax + S_KIND], SK_IF
    jne .no
    mov r8, rax
    call stmt_root
    call node_addr
    cmp byte [rax + V_KIND], VK_CMP
    jne .no
    movzx edx, byte [rax + V_NEG]
    mov ecx, [rax + V_DATA]
    mov r9d, [rax + V_DATA + 4]
    cmp edx, CMP_LT
    je .lt
    cmp edx, CMP_GT
    jne .no
    xchg ecx, r9d
.lt:
    push rcx
    mov ecx, r9d
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .no
    cmp dword [rax + V_DATA], 0
    jne .no
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .no
    mov edx, [rax + V_DATA]
    cmp edx, [ja_x]
    jne .no
    push r12
    mov r12, r8
    mov dword [cg_bldry], 1
    call try_branchless
    mov dword [cg_bldry], 0
    pop r12
    test eax, eax
    jz .no
    mov eax, [cg_blk]
    lea edx, [eax + 1]
    cmp edx, 2
    ja .no
    test eax, eax
    jz .no
    mov [jv_k], eax
    mov ecx, [cg_blvar]
    cmp ecx, [ja_x]
    je .no
    mov rdx, [cg_vreg]
    movzx edx, byte [rdx + rcx]
    test edx, 0x80
    jz .no
    and edx, 0x1F
    mov [jv_t], edx
    mov eax, 1
    ret
.no:
    xor eax, eax
.r:
    ret

jv_emit:
    push rbx
    push r13
    push r14
    mov [ja_start], rdi
    mov dword [ja_hoist], 1
    mov dword [ja_split], 0
    BYTES 0x00000200EC8148, 7
    mov dword [sv_nslot], 0
    mov eax, [ja_a]
    mov edx, [ja_b]
    xor ecx, ecx
.tab:
    lea r8, [jv_A]
    mov [r8 + rcx * 4], eax
    lea r8, [jv_B]
    mov [r8 + rcx * 4], edx
    imul eax, [ja_a]
    imul edx, [ja_a]
    add edx, [ja_b]
    inc ecx
    cmp ecx, [ja_u]
    jb .tab
    xor ebx, ebx
.consts:
    cmp ebx, [ja_u]
    jae .consts_done
    mov r13d, ebx
    shr r13d, 2
    lea r13d, [r13d * 4 + 6]
    xor r14d, r14d
.slot:
    cmp r14d, 4
    jae .slot_done
    lea rax, [jv_A]
    lea rdx, [jv_B]
    cmp r14d, 2
    cmovae rax, rdx
    mov ecx, r14d
    and ecx, 1
    add ecx, ebx
    mov r8d, [rax + rcx * 4]
    mov r10d, [rax + rcx * 4 + 8]
    xor r9d, r9d
    xor r11d, r11d
    call vec_slot
    mov eax, 0x6F
    lea ecx, [r13d + r14d]
    call sse_rm
    inc r14d
    jmp .slot
.slot_done:
    add ebx, 4
    jmp .consts
.consts_done:
    BYTES 0xC0EF0F66, 4
    mov ecx, [ja_rx]
    mov edx, [ja_r0]
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    call x64_text_offset
    mov [rsi + 16], rax
    mov eax, 0x6E
    mov ecx, 1
    mov edx, [ja_r0]
    call sse_rr
    mov eax, 0x70
    mov ecx, 1
    mov edx, 1
    call sse_rr
    xor edx, edx
    call x64_imm8
    xor ebx, ebx
.groups:
    cmp ebx, [ja_u]
    jae .groups_done
    mov r13d, ebx
    shr r13d, 2
    lea r13d, [r13d * 4 + 6]
    xor r14d, r14d
.parity:
    cmp r14d, 2
    jae .parity_done
    mov eax, 0x6F
    mov ecx, 2
    mov edx, 1
    call sse_rr
    mov eax, 0xF4
    mov ecx, 2
    lea edx, [r13d + r14d]
    call sse_rr
    mov eax, 0xFE
    mov ecx, 2
    lea edx, [r13d + r14d + 2]
    call sse_rr
    BYTES 0x1FE2720F66, 5
    mov eax, 0xFA
    xor ecx, ecx
    mov edx, 2
    call sse_rr
    inc r14d
    jmp .parity
.parity_done:
    add ebx, 4
    jmp .groups
.groups_done:
    mov ecx, [ja_r0]
    mov edx, [ja_r0]
    mov r9d, 0x69
    mov r10d, 1
    call emit_rrop
    mov eax, [ja_u]
    lea rdx, [jv_A]
    mov edx, [rdx + rax * 4 - 4]
    call x64_imm32
    mov eax, [ja_u]
    lea rdx, [jv_B]
    cmp dword [rdx + rax * 4 - 4], 0
    je .chain_done
    mov ecx, [ja_r0]
    mov edx, 0xC0
    mov r9d, 0x81
    call emit_reg_short
    mov eax, [ja_u]
    lea rdx, [jv_B]
    mov edx, [rdx + rax * 4 - 4]
    call x64_imm32
.chain_done:
    cmp qword [rsi + 8], BK_FOR
    jne .info
    mov rcx, [rsi + 24]
    mov edx, 0xC0
    mov r9d, 0x83
    call emit_reg_short
    mov edx, [ja_u]
    dec edx
    call x64_imm8
.info:
    mov eax, [jv_t]
    mov edx, [ja_rx]
    inc edx
    shl edx, 8
    or eax, edx
    mov edx, [ja_r0]
    inc edx
    shl edx, 16
    or eax, edx
    cmp dword [jv_k], 0
    jg .info_set
    or eax, 0x80000000
.info_set:
    mov [rsi + 112], rax
    pop r14
    pop r13
    pop rbx
    ret

ja_emit_rest:
    push rbx
    push r12
    mov ebx, [ja_first]
    inc ebx
.l:
    cmp ebx, [ja_end]
    jae .done
    mov ecx, ebx
    call stmt_ptr
    mov r12, rax
    mov eax, [r12 + S_TOK]
    shl rax, 4
    add rax, [g_tokens]
    mov eax, [rax + T_LINE]
    mov [cg_line], eax
    cmp word [r12 + S_KIND], SK_IF
    je .if
    call emit_store
    inc ebx
    jmp .l
.if:
    call try_branchless
    add ebx, 2
    jmp .l
.done:
    pop r12
    pop rbx
    ret

try_jump_ahead:
    test word [r12 + S_MODE], 1
    jnz .no
    cmp qword [rsi + 24], 0xFF
    je .no
    cmp qword [rsi + 40], 0
    jne .no
    cmp qword [rsi + 72], 0
    jne .no
    mov eax, [cg_poolnext]
    cmp eax, 7
    jae .no
    lea rdx, [loop_regs]
    movzx eax, byte [rdx + rax]
    mov [ja_r0], eax
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    inc eax
    mov [ja_first], eax
    mov edx, [r12 + S_PIECES]
    mov [ja_end], edx
    cmp eax, edx
    jae .no
    mov ecx, eax
    call stmt_ptr
    movzx edx, word [rax + S_KIND]
    cmp edx, SK_DECL
    je .first_kind
    cmp edx, SK_ASSIGN
    jne .no
.first_kind:
    cmp word [rax + S_MODE], TY_INT
    jne .no
    cmp dword [rax + S_NPARTS], 0
    je .no
    mov ecx, [rax + S_VAR]
    mov [ja_x], ecx
    mov rdx, [cg_vreg]
    movzx edx, byte [rdx + rcx]
    test edx, 0x80
    jz .no
    and edx, 0x1F
    dec edx
    mov [ja_rx], edx
    push rax
    call stmt_root
    call ja_affine
    pop rcx
    test eax, eax
    jz .no
    mov dword [ja_step], 0
    mov dword [ja_lv], -1
    mov dword [ja_t], -1
    mov dword [ja_tok], 1
    cmp qword [rsi + 8], BK_FOR
    jne .scan
    mov eax, [r12 + S_VAR]
    mov [ja_lv], eax
    cmp qword [rsi + 88], 0
    jne .scan
    mov dword [ja_step], 1
.scan:
    call ja_scan
    test eax, eax
    jz .no
    mov rax, [rsi + 48]
    lea rcx, [ja_factors]
.pick:
    movzx r8d, byte [rcx]
    test r8d, r8d
    jz .no
    inc rcx
    cmp rax, r8
    jb .pick
    xor edx, edx
    push rax
    div r8
    pop rax
    test edx, edx
    jnz .pick
    mov [ja_u], r8d

    call jv_check
    test eax, eax
    jz .scalar_ja
    call jv_emit
    jmp .sized
.scalar_ja:
    mov [ja_start], rdi
    mov dword [ja_hoist], 0
    mov dword [ja_split], 0
    call x64_text_offset
    cmp rax, [rsi + 16]
    jne .no_hoist
    mov dword [ja_hoist], 1
    cmp dword [ja_t], -1
    je .no_hoist
    call ja_t_check
    cmp dword [ja_tok], 0
    je .no_hoist
    test byte [ja_u], 1
    jnz .no_hoist
    mov eax, [cg_poolnext]
    inc eax
    cmp eax, 7
    jae .no_hoist
    mov ecx, [ja_t]
    mov rdx, [cg_vreg]
    movzx edx, byte [rdx + rcx]
    test edx, 0x80
    jz .no_hoist
    mov [ja_tbyte], edx
    lea rdx, [loop_regs]
    movzx eax, byte [rdx + rax]
    mov [ja_p], eax
    mov dword [ja_split], 1
    mov ecx, eax
    mov r9d, 0x31
    call emit_rr
.no_hoist:
    mov ecx, [ja_rx]
    mov edx, [ja_r0]
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    cmp dword [ja_hoist], 0
    je .start_copies
    call x64_text_offset
    mov [rsi + 16], rax
.start_copies:
    mov eax, [ja_a]
    mov [ja_A], eax
    mov eax, [ja_b]
    mov [ja_B], eax
    mov dword [ja_k], 1
.copy:
    cmp dword [ja_k], 1
    je .compute
    cmp dword [ja_step], 0
    je .compute
    mov rcx, [rsi + 24]
    mov edx, 0xC0
    mov r9d, 0xFF
    call emit_reg_short
    cmp qword [rsi + 88], 0
    jne .compute
    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov edx, [rax + VR_OFF]
    add edx, RT_VARS
    mov rcx, [rsi + 24]
    mov r9d, 0x89
    call emit_mem_reg
.compute:
    mov ecx, [ja_rx]
    cmp dword [ja_hoist], 0
    je .dest
    mov eax, [ja_k]
    cmp eax, [ja_u]
    jne .dest
    mov ecx, [ja_r0]
.dest:
    push rcx
    mov edx, [ja_r0]
    mov r9d, 0x69
    mov r10d, 1
    call emit_rrop
    mov edx, [ja_A]
    call x64_imm32
    pop rcx
    cmp dword [ja_B], 0
    je .moved
    push rcx
    mov edx, 0xC0
    mov r9d, 0x81
    call emit_reg_short
    mov edx, [ja_B]
    call x64_imm32
    pop rcx
.moved:
    cmp ecx, [ja_rx]
    je .rest
    mov edx, [ja_rx]
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
.rest:
    cmp dword [ja_split], 0
    je .rest_plain
    test byte [ja_k], 1
    jnz .rest_plain
    mov ecx, [ja_t]
    mov rdx, [cg_vreg]
    mov eax, [ja_p]
    inc eax
    or eax, 0x80
    mov [rdx + rcx], al
    call ja_emit_rest
    mov ecx, [ja_t]
    mov rdx, [cg_vreg]
    mov eax, [ja_tbyte]
    mov [rdx + rcx], al
    jmp .rest_done
.rest_plain:
    call ja_emit_rest
.rest_done:
    mov eax, [ja_A]
    imul eax, [ja_a]
    mov [ja_A], eax
    mov eax, [ja_B]
    imul eax, [ja_a]
    add eax, [ja_b]
    mov [ja_B], eax
    mov eax, [ja_k]
    inc eax
    mov [ja_k], eax
    cmp eax, [ja_u]
    jbe .copy
    cmp qword [rsi + 8], BK_FOR
    jne .sized
    cmp dword [ja_step], 0
    jne .sized
    mov rcx, [rsi + 24]
    mov edx, 0xC0
    mov r9d, 0x83
    call emit_reg_short
    mov edx, [ja_u]
    dec edx
    call x64_imm8
.sized:
    mov rax, rdi
    sub rax, [ja_start]
    add rax, [cg_extra]
    cmp rax, 65536
    ja .rewind
    mov [cg_extra], rax
    mov eax, [ja_end]
    mov [cg_skip], rax
    mov qword [rsi + 96], 1
    mov qword [rsi + 80], 1
    cmp dword [ja_split], 0
    je .merge_set
    mov eax, [ja_tbyte]
    and eax, 0x1F
    mov edx, [ja_p]
    inc edx
    shl edx, 8
    or eax, edx
    mov [rsi + 104], rax
.merge_set:
    cmp qword [rsi + 8], BK_FOR
    je .yes
    mov eax, [ja_u]
    mov [rsi + 80], rax
.yes:
    mov eax, 1
    ret
.rewind:
    mov rdi, [ja_start]
.no:
    xor eax, eax
    ret

dleft_reg:
    mov ecx, [cg_dleft]
    cmp ecx, -1
    je .no
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .no
    mov ecx, [rax + V_DATA]
    jmp var_reg
.no:
    mov eax, -1
    ret

shift_form:
    xor eax, eax
    cmp edx, 3
    jl .r
    lea ecx, [edx + 1]
    test ecx, edx
    jnz .plus
    bsf ecx, ecx
    mov eax, 0x29
    ret
.plus:
    lea ecx, [edx - 1]
    lea r8d, [edx - 2]
    test ecx, r8d
    jnz .r
    cmp ecx, 4
    jb .r
    bsf ecx, ecx
    mov eax, 0x01
.r:
    ret

try_reassoc:
    xor eax, eax
    cmp qword [cg_ldepth], 0
    je .r
    push rbx
    push r12
    push r13
    mov r12d, [rsi + V_DATA]
    mov r13d, [rsi + V_DATA + 4]
    call .mul_side
    test eax, eax
    jnz .emit
    xchg r12d, r13d
    call .mul_side
    test eax, eax
    jz .out
.emit:
    push rax
    push rcx
    mov ecx, ebx
    xor edx, edx
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    BYTES 0xE0C1, 2
    pop rdx
    call x64_imm8
    mov ecx, r13d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    je .y_const
    mov ecx, [rax + V_DATA]
    push rax
    call var_reg
    pop rcx
    test eax, eax
    js .y_mem
    mov ecx, eax
    mov edx, 1
    mov r9d, 0x89
    mov r10d, 1
    call emit_rrop
    jmp .y_done
.y_mem:
    mov rax, rcx
    call var_disp
    mov r9d, eax
    OPD 0x8F8B41, 3, r9d
    jmp .y_done
.y_const:
    mov edx, [rax + V_DATA]
    push rdx
    BYTES 0xB9, 1
    pop rdx
    call x64_imm32
.y_done:
    pop r9
    mov ecx, ebx
    mov edx, 1
    mov r10d, 1
    call emit_rrop
    BYTES 0xC801, 2
    mov eax, 1
.out:
    pop r13
    pop r12
    pop rbx
.r:
    ret
.mul_side:
    mov ecx, r12d
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .side_no
    cmp byte [rax + V_NEG], OP_MUL
    jne .side_no
    mov r8, rax
    mov ecx, r13d
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_INT
    je .y_ok
    cmp edx, VK_VAR
    jne .side_no
.y_ok:
    mov ecx, [r8 + V_DATA]
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .side_no
    mov ecx, [rax + V_DATA]
    call var_reg
    test eax, eax
    js .side_no
    mov ebx, eax
    mov ecx, [r8 + V_DATA + 4]
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .side_no
    mov edx, [rax + V_DATA]
    jmp shift_form
.side_no:
    xor eax, eax
    ret

left_nonneg:
    push r9
    mov dword [cg_nonneg], 0
    mov ecx, [cg_dleft]
    cmp ecx, -1
    je .r
    call node_range
    test eax, eax
    js .r
    mov dword [cg_nonneg], 1
.r:
    pop r9
    ret

node_range:
    push rbx
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_INT
    je .int
    cmp edx, VK_VAR
    je .var
    cmp edx, VK_EXPR
    jne .unknown
    mov rbx, rax
    movzx edx, byte [rbx + V_NEG]
    cmp edx, OP_ADD
    je .add
    cmp edx, OP_MUL
    je .mul
    cmp edx, OP_DIV
    je .div
    cmp edx, OP_MOD
    je .mod
    jmp .unknown
.int:
    mov eax, [rax + V_DATA]
    test eax, eax
    js .unknown
    pop rbx
    ret
.var:
    mov edx, [rax + V_DATA]
    mov rax, [cg_vhi]
    mov eax, [rax + rdx * 4]
    pop rbx
    ret
.add:
    call .pair
    js .unknown
    add rax, rdx
    jmp .fit
.mul:
    call .pair
    js .unknown
    imul rax, rdx
.fit:
    cmp rax, 0x7FFFFFFF
    ja .unknown
    pop rbx
    ret
.div:
    call .const_right
    jz .unknown
    test eax, eax
    jle .unknown
    push rax
    mov ecx, [rbx + V_DATA]
    call node_range
    pop rcx
    test eax, eax
    js .unknown
    xor edx, edx
    div ecx
    pop rbx
    ret
.mod:
    call .const_right
    jz .unknown
    cmp eax, 0x80000000
    je .unknown
    mov ecx, eax
    neg ecx
    cmovs ecx, eax
    dec ecx
    push rcx
    mov ecx, [rbx + V_DATA]
    call node_range
    pop rcx
    test eax, eax
    js .unknown
    cmp eax, ecx
    cmova eax, ecx
    pop rbx
    ret
.unknown:
    mov eax, -1
    pop rbx
    ret
.pair:
    mov ecx, [rbx + V_DATA]
    call node_range
    test eax, eax
    js .pair_r
    push rax
    mov ecx, [rbx + V_DATA + 4]
    call node_range
    mov edx, eax
    pop rax
    test edx, edx
.pair_r:
    ret
.const_right:
    mov ecx, [rbx + V_DATA + 4]
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .not_const
    mov eax, [rax + V_DATA]
    or ecx, 1
    ret
.not_const:
    xor ecx, ecx
    ret

kv_record:
    cmp qword [cg_bdepth], 0
    jne .r
    cmp qword [cg_ldepth], 0
    jne .r
    cmp word [r12 + S_MODE], TY_INT
    jne .r
    mov ecx, [r12 + S_VAR]
    mov rdx, [cg_kvok]
    mov byte [rdx + rcx], 0
    xor eax, eax
    cmp dword [r12 + S_NPARTS], 0
    je .known
    push rcx
    mov rax, r12
    call stmt_root
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .r
    mov eax, [rax + V_DATA]
.known:
    mov rdx, [cg_kv]
    mov [rdx + rcx * 4], eax
    mov rdx, [cg_kvok]
    mov byte [rdx + rcx], 1
.r:
    ret

kv_invalidate:
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    lea r8d, [eax + 1]
    mov r9d, [r12 + S_PIECES]
    mov r10, [cg_kvok]
    cmp word [r12 + S_KIND], SK_FOR
    jne .l
    mov ecx, [r12 + S_VAR]
    mov byte [r10 + rcx], 0
.l:
    cmp r8d, r9d
    jae .r
    mov ecx, r8d
    call stmt_ptr
    inc r8d
    movzx edx, word [rax + S_KIND]
    cmp edx, SK_DECL
    je .kill
    cmp edx, SK_ASSIGN
    je .kill
    cmp edx, SK_INPUT
    je .kill
    cmp edx, SK_FOR
    jne .l
.kill:
    mov ecx, [rax + S_VAR]
    mov byte [r10 + rcx], 0
    jmp .l
.r:
    ret

rg_add:
    mov rdx, [rg_state]
    cmp dword [rdx + rcx * 4], 0
    jne .r
    mov dword [rdx + rcx * 4], 1
    mov rdx, [rg_list]
    mov rax, [rg_n]
    mov [rdx + rax * 4], ecx
    inc qword [rg_n]
.r:
    ret

rg_mod_of:
    push rcx
    mov rax, r12
    call stmt_root
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_EXPR
    jne .bad
    cmp byte [rax + V_NEG], OP_MOD
    jne .bad
    push rcx
    mov ecx, [rax + V_DATA + 4]
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .bad
    mov eax, [rax + V_DATA]
    test eax, eax
    jz .bad
    cmp eax, 0x80000000
    je .bad
    mov edx, eax
    neg edx
    cmovs edx, eax
    mov eax, edx
    ret
.bad:
    xor eax, eax
    ret

range_setup:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r15, r12
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    lea r13d, [eax + 1]
    mov r14d, [r12 + S_PIECES]
    mov ebx, r13d
.scan:
    cmp ebx, r14d
    jae .scanned
    mov ecx, ebx
    call stmt_ptr
    mov r12, rax
    inc ebx
    movzx edx, word [r12 + S_KIND]
    cmp edx, SK_FOR
    je .bad_var
    cmp edx, SK_INPUT
    je .bad_var
    cmp edx, SK_DECL
    je .assign
    cmp edx, SK_ASSIGN
    jne .scan
.assign:
    cmp word [r12 + S_MODE], TY_INT
    jne .scan
    mov ecx, [r12 + S_VAR]
    call rg_add
    mov rdx, [rg_state]
    cmp dword [rdx + rcx * 4], -2
    je .scan
    cmp dword [r12 + S_NPARTS], 0
    je .bad_var
    call rg_mod_of
    test eax, eax
    jz .bad_var
    mov rdx, [rg_state]
    cmp [rdx + rcx * 4], eax
    jae .scan
    mov [rdx + rcx * 4], eax
    jmp .scan
.bad_var:
    mov ecx, [r12 + S_VAR]
    call rg_add
    mov rdx, [rg_state]
    mov dword [rdx + rcx * 4], -2
    jmp .scan
.scanned:
    xor ebx, ebx
.entry:
    cmp rbx, [rg_n]
    jae .entry_done
    mov rdx, [rg_list]
    mov ecx, [rdx + rbx * 4]
    inc ebx
    mov rdx, [rg_state]
    mov eax, [rdx + rcx * 4]
    cmp eax, 2
    jl .entry
    dec eax
    mov rdx, [cg_kvok]
    cmp byte [rdx + rcx], 0
    je .entry
    mov rdx, [cg_kv]
    mov edx, [rdx + rcx * 4]
    test edx, edx
    js .entry
    cmp edx, eax
    cmova eax, edx
    mov rdx, [cg_vhi]
    mov [rdx + rcx * 4], eax
    jmp .entry
.entry_done:
    mov r12, r15
    cmp word [r12 + S_KIND], SK_FOR
    jne .verify
    mov ecx, [r12 + S_VAR]
    call for_aliasable
    test eax, eax
    jz .verify
    mov ecx, [r12 + S_VAR]
    call rg_add
    mov rdx, [rg_state]
    mov dword [rdx + rcx * 4], -2
    mov r8d, 0x7FFFFFFE
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov eax, [rdx + rax * 4]
    push rcx
    mov ecx, eax
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .top_hi
    mov eax, [rax + V_DATA]
    test eax, eax
    jle .verify
    lea r8d, [eax - 1]
.top_hi:
    mov rdx, [cg_vhi]
    mov [rdx + rcx * 4], r8d
.verify:
    xor r15d, r15d
    mov ebx, r13d
.v_scan:
    cmp ebx, r14d
    jae .v_done
    mov ecx, ebx
    call stmt_ptr
    mov r12, rax
    inc ebx
    movzx edx, word [r12 + S_KIND]
    cmp edx, SK_DECL
    je .v_assign
    cmp edx, SK_ASSIGN
    jne .v_scan
.v_assign:
    cmp word [r12 + S_MODE], TY_INT
    jne .v_scan
    mov ecx, [r12 + S_VAR]
    mov rdx, [cg_vhi]
    cmp dword [rdx + rcx * 4], 0
    jl .v_scan
    push rcx
    mov rax, r12
    call stmt_root
    call node_addr
    mov ecx, [rax + V_DATA]
    call node_range
    pop rcx
    test eax, eax
    jns .v_scan
    mov rdx, [cg_vhi]
    mov dword [rdx + rcx * 4], -1
    mov r15d, 1
    jmp .v_scan
.v_done:
    test r15d, r15d
    jnz .verify
    mov r12, [rsp + 24]
    cmp word [r12 + S_KIND], SK_FOR
    jne .top_clear_done
    mov ecx, [r12 + S_VAR]
    mov rdx, [cg_vhi]
    mov dword [rdx + rcx * 4], -1
.top_clear_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

range_clear:
    mov rcx, [rg_n]
.l:
    test rcx, rcx
    jz .done
    dec rcx
    mov rdx, [rg_list]
    mov eax, [rdx + rcx * 4]
    mov rdx, [rg_state]
    mov dword [rdx + rax * 4], 0
    mov rdx, [cg_vhi]
    mov dword [rdx + rax * 4], -1
    jmp .l
.done:
    mov qword [rg_n], 0
    ret

cc_of_op:
    mov eax, 4
    cmp ecx, CMP_IS
    je .r
    mov eax, 5
    cmp ecx, CMP_ISNOT
    je .r
    mov eax, 0xC
    cmp ecx, CMP_LT
    je .r
    mov eax, 0xE
    cmp ecx, CMP_LE
    je .r
    mov eax, 0xD
    cmp ecx, CMP_GE
    je .r
    mov eax, 0xF
.r:
    ret

emit_compare:
    push r12
    push r13
    push r14
    movzx r14d, byte [rsi + V_NEG]
    mov r12d, [rsi + V_DATA]
    mov r13d, [rsi + V_DATA + 4]
    movzx eax, byte [rsi + V_TYPE]
    cmp eax, TY_STR
    je .str
    cmp eax, TY_BOOL
    je .bool
    mov ecx, r12d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .int_order_ok
    mov ecx, r13d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    je .int_order_ok
    xchg r12d, r13d
    cmp r14d, CMP_LT
    je .mirror_gt
    cmp r14d, CMP_LE
    je .mirror_ge
    cmp r14d, CMP_GE
    je .mirror_le
    cmp r14d, CMP_GT
    jne .int_order_ok
    mov r14d, CMP_LT
    jmp .int_order_ok
.mirror_le:
    mov r14d, CMP_LE
    jmp .int_order_ok
.mirror_ge:
    mov r14d, CMP_GE
    jmp .int_order_ok
.mirror_gt:
    mov r14d, CMP_GT
.int_order_ok:
    call try_divisible
    test eax, eax
    jnz .ret
    mov ecx, r12d
    call emit_expr
    mov ecx, r13d
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_INT
    je .int_imm
    cmp edx, VK_VAR
    je .int_mem
    mov eax, [cg_depth]
    push rax
    inc dword [cg_depth]
    shl eax, 16
    add eax, 0xC08941
    mov r8d, 3
    call x64_bytes
    mov ecx, r13d
    call emit_expr
    pop rax
    dec dword [cg_depth]
    shl eax, 16
    add eax, 0xC03941
    mov r8d, 3
    call x64_bytes
    jmp .int_cc
.int_imm:
    mov r9d, [rax + V_DATA]
    test r9d, r9d
    jnz .int_imm_cmp
    BYTES 0xC085, 2
    jmp .int_cc
.int_imm_cmp:
    BYTES 0x3D, 1
    mov edx, r9d
    call x64_imm32
    jmp .int_cc
.int_mem:
    push rax
    mov ecx, [rax + V_DATA]
    call var_reg
    mov ecx, eax
    pop rax
    test ecx, ecx
    js .int_mem_m
    xor edx, edx
    mov r9d, 0x39
    mov r10d, 1
    call emit_rrop
    jmp .int_cc
.int_mem_m:
    call var_disp
    mov r9d, eax
    OPD 0x873B41, 3, r9d
.int_cc:
    mov ecx, r14d
    call cc_of_op
    jmp .ret

.bool:
    mov ecx, r12d
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    je .bool_left_var
    mov r9d, [rax + V_DATA]
    BYTES 0xB8, 1
    mov edx, r9d
    call x64_imm32
    jmp .bool_right
.bool_left_var:
    call var_disp
    mov r9d, eax
    OPD 0x87B60F41, 4, r9d
.bool_right:
    mov ecx, r13d
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    je .bool_right_var
    mov r9d, [rax + V_DATA]
    BYTES 0x3D, 1
    mov edx, r9d
    call x64_imm32
    jmp .bool_cc
.bool_right_var:
    call var_disp
    mov r9d, eax
    OPD 0x8FB60F41, 4, r9d
    BYTES 0xC839, 2
.bool_cc:
    mov ecx, r14d
    call cc_of_op
    jmp .ret

.str:
    mov ecx, r12d
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_VAR
    je .a_var
    cmp edx, VK_STR
    je .a_lit
    BYTES 0xD231C931, 4
    jmp .b
.a_var:
    call var_disp
    mov r9d, eax
    OPD 0x8F8B49, 3, r9d
    add r9d, 8
    OPD 0x97B70F41, 4, r9d
    jmp .b
.a_lit:
    mov r9d, [rax + V_DATA + 4]
    mov ecx, [rax + V_DATA]
    add ecx, [cg_rdelta]
    push r9
    OPD 0x8F8D49, 3, ecx
    BYTES 0xBA, 1
    pop rdx
    call x64_imm32
.b:
    mov ecx, r13d
    call node_addr
    movzx edx, byte [rax + V_KIND]
    cmp edx, VK_VAR
    je .b_var
    cmp edx, VK_STR
    je .b_lit
    BYTES 0xC03145, 3
    BYTES 0xC93145, 3
    jmp .call
.b_var:
    call var_disp
    mov r9d, eax
    OPD 0x878B4D, 3, r9d
    add r9d, 8
    OPD 0x8FB70F45, 4, r9d
    jmp .call
.b_lit:
    mov r9d, [rax + V_DATA + 4]
    mov ecx, [rax + V_DATA]
    add ecx, [cg_rdelta]
    push r9
    OPD 0x878D4D, 3, ecx
    BYTES 0xB941, 2
    pop rdx
    call x64_imm32
.call:
    CALL_RT RT_FN_STR_EQ
    BYTES 0xC085, 2
    mov eax, 5
    cmp r14d, CMP_IS
    je .ret
    mov eax, 4
.ret:
    pop r14
    pop r13
    pop r12
    ret


var_reg:
    mov rax, [cg_vreg]
    movzx eax, byte [rax + rcx]
    and eax, 0x1F
    dec eax
    ret

emit_rrop:
    push rcx
    push rdx
    xor eax, eax
    cmp ecx, 8
    jb .rm
    or eax, 4
.rm:
    cmp edx, 8
    jb .rex
    or eax, 1
.rex:
    test eax, eax
    jz .op
    or eax, 0x40
    mov [rdi], al
    inc rdi
.op:
    mov [rdi], r9d
    add rdi, r10
    pop rdx
    pop rcx
    and ecx, 7
    and edx, 7
    lea eax, [rcx * 8 + rdx + 0xC0]
    mov [rdi], al
    inc rdi
    ret

sync_out:
    cmp qword [cg_nprom], 0
    je .r
    mov ecx, [r12 + S_NPIECES]
    mov eax, [r12 + S_PIECES]
    shl rax, 4
    add rax, [g_pieces]
.scan:
    test ecx, ecx
    jz .r
    cmp dword [rax + P_KIND], PK_INT
    je flush_prom
    add rax, P_SIZE
    dec ecx
    jmp .scan
.r:
    ret

flush_prom:
    push rbx
    xor ebx, ebx
.l:
    cmp rbx, [cg_nprom]
    jae .d
    lea rax, [cg_prom]
    mov ecx, [rax + rbx * 4]
    push rcx
    call var_reg
    pop rcx
    shl rcx, 5
    add rcx, [g_vars]
    mov edx, [rcx + VR_OFF]
    add edx, RT_VARS
    mov ecx, eax
    mov r9d, 0x89
    call emit_mem_reg
    inc rbx
    jmp .l
.d:
    pop rbx
    ret

unpromote:
    call range_clear
    mov dword [cg_poolnext], 7
    cmp qword [cg_nprom], 0
    je .r
    call flush_prom
.clr:
    mov rax, [cg_nprom]
    test rax, rax
    jz .r
    dec rax
    mov [cg_nprom], rax
    lea rdx, [cg_prom]
    mov ecx, [rdx + rax * 4]
    mov rdx, [cg_vreg]
    mov byte [rdx + rcx], 0
    jmp .clr
.r:
    ret

for_aliasable:
    push rbx
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    lea edx, [eax + 1]
    mov r8d, [r12 + S_PIECES]
.l:
    cmp edx, r8d
    jae .yes
    mov rbx, rdx
    shl rbx, 5
    add rbx, [g_stmts]
    movzx eax, word [rbx + S_KIND]
    cmp eax, SK_DECL
    je .chk
    cmp eax, SK_ASSIGN
    je .chk
    cmp eax, SK_INPUT
    je .chk
    cmp eax, SK_FOR
    jne .n
.chk:
    cmp [rbx + S_VAR], ecx
    je .no
.n:
    inc edx
    jmp .l
.yes:
    mov eax, 1
    pop rbx
    ret
.no:
    xor eax, eax
    pop rbx
    ret

touch:
    mov rax, [cg_vcount]
    lea rax, [rax + rcx * 4]
    test dword [rax], 0x40000000
    jnz .r
    or dword [rax], 0x40000000
    mov rdx, [cg_touched]
    mov [rdx + r15 * 4], ecx
    inc r15d
.r:
    ret

promote_region:
    push rbx
    push rsi
    push r13
    push r14
    push r15
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    lea esi, [eax + 1]
    mov r14d, [r12 + S_PIECES]
    xor r15d, r15d
    mov dword [cg_md], 1
    mov qword [cg_tsp], 0
    cmp word [r12 + S_KIND], SK_FOR
    jne .scan
    mov ecx, [r12 + S_VAR]
    call touch
    or dword [rax], 0x80000000
.scan:
    cmp esi, r14d
    jae .scanned
.pop:
    mov rax, [cg_tsp]
    test rax, rax
    jz .popped
    lea rdx, [cg_tstack]
    cmp [rdx + rax * 4 - 4], esi
    ja .popped
    dec qword [cg_tsp]
    jmp .pop
.popped:
    mov rbx, rsi
    shl rbx, 5
    add rbx, [g_stmts]
    movzx eax, word [rbx + S_KIND]
    cmp eax, SK_FOR
    je .loop_stmt
    cmp eax, SK_LOOPS
    je .loop_stmt
    cmp eax, SK_DECL
    je .assign
    cmp eax, SK_ASSIGN
    jne .next
.assign:
    cmp word [rbx + S_MODE], TY_INT
    jne .next
    mov ecx, [rbx + S_VAR]
    call touch
    mov ecx, [cg_tsp]
    imul ecx, ecx, 3
    cmp ecx, 24
    jbe .w
    mov ecx, 24
.w:
    mov edx, 1
    shl edx, cl
    mov ecx, [rax]
    and ecx, 0x3FFFFFFF
    add ecx, edx
    cmp ecx, 0x3FFFFFFF
    jbe .sat
    mov ecx, 0x3FFFFFFF
.sat:
    and dword [rax], 0xC0000000
    or [rax], ecx
    jmp .next
.loop_stmt:
    cmp eax, SK_FOR
    jne .push
    mov ecx, [rbx + S_VAR]
    call touch
    or dword [rax], 0x80000000
.push:
    mov rax, [cg_tsp]
    cmp rax, MAX_BLOCKS
    jae .next
    lea rdx, [cg_tstack]
    mov ecx, [rbx + S_PIECES]
    mov [rdx + rax * 4], ecx
    inc rax
    mov [cg_tsp], rax
    inc eax
    cmp eax, [cg_md]
    jbe .next
    mov [cg_md], eax
.next:
    inc esi
    jmp .scan
.scanned:
    mov ebx, [cg_md]
    cmp ebx, MAX_REG_LOOPS
    jbe .pick
    mov ebx, MAX_REG_LOOPS
.pick:
    cmp ebx, 7
    jae .picked
    xor ecx, ecx
    mov edx, -1
    xor r8d, r8d
.find:
    cmp ecx, r15d
    jae .found
    mov rax, [cg_touched]
    mov eax, [rax + rcx * 4]
    mov r9, [cg_vcount]
    mov r9d, [r9 + rax * 4]
    test r9d, 0x80000000
    jnz .fnext
    and r9d, 0x3FFFFFFF
    cmp r9d, r8d
    jbe .fnext
    mov r8d, r9d
    mov edx, ecx
.fnext:
    inc ecx
    jmp .find
.found:
    cmp edx, -1
    je .picked
    mov rax, [cg_touched]
    mov ecx, [rax + rdx * 4]
    mov rax, [cg_vcount]
    or dword [rax + rcx * 4], 0x80000000
    lea rax, [loop_regs]
    movzx eax, byte [rax + rbx]
    mov rdx, [cg_vreg]
    lea r8d, [eax + 0x81]
    mov [rdx + rcx], r8b
    mov r8, [cg_nprom]
    lea rdx, [cg_prom]
    mov [rdx + r8 * 4], ecx
    inc qword [cg_nprom]
    shl rcx, 5
    add rcx, [g_vars]
    mov edx, [rcx + VR_OFF]
    add edx, RT_VARS
    mov ecx, eax
    mov r9d, 0x8B
    call emit_mem_reg
    inc ebx
    jmp .pick
.picked:
    mov [cg_poolnext], ebx
    xor ecx, ecx
.clr:
    cmp ecx, r15d
    jae .cleared
    mov rax, [cg_touched]
    mov eax, [rax + rcx * 4]
    mov rdx, [cg_vcount]
    mov dword [rdx + rax * 4], 0
    inc ecx
    jmp .clr
.cleared:
    pop r15
    pop r14
    pop r13
    pop rsi
    pop rbx
    ret

sse_rr:
    mov byte [rdi], 0x66
    inc rdi
    shl eax, 8
    or eax, 0x0F
    mov r9d, eax
    mov r10d, 2
    jmp emit_rrop

sse_rm:
    mov byte [rdi], 0x66
    inc rdi
    cmp ecx, 8
    jb .norex
    mov byte [rdi], 0x44
    inc rdi
.norex:
    mov byte [rdi], 0x0F
    mov [rdi + 1], al
    and ecx, 7
    shl ecx, 3
    or ecx, 0x84
    mov [rdi + 2], cl
    mov byte [rdi + 3], 0x24
    mov [rdi + 4], edx
    add rdi, 8
    ret

vec_slot:
    mov edx, [sv_nslot]
    inc dword [sv_nslot]
    shl edx, 4
    push rdx
    mov eax, r8d
    call .one
    add edx, 4
    mov eax, r9d
    call .one
    add edx, 4
    mov eax, r10d
    call .one
    add edx, 4
    mov eax, r11d
    call .one
    pop rdx
    ret
.one:
    mov dword [rdi], 0x002484C7
    mov [rdi + 3], edx
    mov [rdi + 7], eax
    add rdi, 11
    ret

vec_bcast:
    mov r9d, r8d
    mov r10d, r8d
    mov r11d, r8d
    jmp vec_slot

sv_can16:
    xor eax, eax
    cmp dword [sv_iv], 0
    jne .r
    cmp dword [sv_tkind], 0
    jne .r
    cmp dword [sv_cond], -1
    je .r
    mov ecx, [sv_k]
    imul ecx, [sv_sign]
    add ecx, 32767
    cmp ecx, 65534
    ja .r
    xor ecx, ecx
.d:
    cmp ecx, [sv_ndiv]
    jae .c
    lea rdx, [sv_div]
    cmp dword [rdx + rcx * 4], 16384
    ja .r
    inc ecx
    jmp .d
.c:
    xor ecx, ecx
.cl:
    cmp ecx, [sv_nleaf]
    jae .yes
    lea rdx, [sv_lc]
    mov edx, [rdx + rcx * 4]
    add edx, 32768
    cmp edx, 65535
    ja .r
    inc ecx
    jmp .cl
.yes:
    mov eax, 1
.r:
    ret

sv_node_is_loopvar:
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .no
    mov edx, [rax + V_DATA]
    cmp edx, [r12 + S_VAR]
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

sv_leaves:
    call node_addr
    cmp byte [rax + V_KIND], VK_OR
    jne .cmp
    push rax
    mov ecx, [rax + V_DATA]
    call sv_leaves
    pop rcx
    test eax, eax
    jnz .r
    mov ecx, [rcx + V_DATA + 4]
    jmp sv_leaves
.cmp:
    cmp byte [rax + V_KIND], VK_CMP
    jne .bad
    cmp byte [rax + V_TYPE], TY_INT
    jne .bad
    mov r8d, [sv_nleaf]
    cmp r8d, 4
    jae .bad
    movzx r9d, byte [rax + V_NEG]
    mov ecx, [rax + V_DATA]
    mov edx, [rax + V_DATA + 4]
    push rcx
    mov ecx, edx
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    je .right_const
    mov r11d, edx
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .bad
    mov ecx, r11d
    cmp r9d, CMP_LT
    jne .not_lt
    mov r9d, CMP_GT
    jmp .right_const
.not_lt:
    cmp r9d, CMP_GT
    jne .not_gt
    mov r9d, CMP_LT
    jmp .right_const
.not_gt:
    cmp r9d, CMP_LE
    jne .not_le
    mov r9d, CMP_GE
    jmp .right_const
.not_le:
    cmp r9d, CMP_GE
    jne .right_const
    mov r9d, CMP_LE
.right_const:
    mov r10d, [rax + V_DATA]
    cmp r9d, CMP_LE
    jne .le_done
    cmp r10d, 0x7FFFFFFF
    je .bad
    inc r10d
    mov r9d, CMP_LT
.le_done:
    cmp r9d, CMP_GE
    jne .ge_done
    cmp r10d, 0x80000000
    je .bad
    dec r10d
    mov r9d, CMP_GT
.ge_done:
    push rcx
    call sv_node_is_loopvar
    pop rcx
    xor r11d, r11d
    test eax, eax
    jnz .store
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .bad
    cmp byte [rax + V_NEG], OP_MOD
    jne .bad
    push rax
    mov ecx, [rax + V_DATA]
    call sv_node_is_loopvar
    pop rcx
    test eax, eax
    jz .bad
    mov ecx, [rcx + V_DATA + 4]
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .bad
    mov r11d, [rax + V_DATA]
    mov eax, r11d
    neg eax
    cmovs eax, r11d
    mov r11d, eax
    test r11d, r11d
    jz .bad
    cmp r11d, 0x40000000
    ja .bad
.store:
    lea rax, [sv_ld]
    mov [rax + r8 * 4], r11d
    lea rax, [sv_lop]
    mov [rax + r8 * 4], r9d
    lea rax, [sv_lc]
    mov [rax + r8 * 4], r10d
    inc dword [sv_nleaf]
    xor eax, eax
    ret
.bad:
    mov eax, 1
.r:
    ret

simd_match:
    push rbx
    push rsi
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    mov ebx, eax
    mov edx, [r12 + S_PIECES]
    sub edx, eax
    mov dword [sv_cond], -1
    lea rsi, [r12 + S_SIZE]
    cmp edx, 2
    je .assign
    cmp edx, 3
    jne .no
    cmp word [rsi + S_KIND], SK_IF
    jne .no
    lea eax, [ebx + 3]
    cmp [rsi + S_PIECES], eax
    jne .no
    mov eax, [rsi + S_PARTS]
    mov rdx, [g_roots]
    mov eax, [rdx + rax * 4]
    mov [sv_cond], eax
    add rsi, S_SIZE
.assign:
    movzx eax, word [rsi + S_KIND]
    cmp eax, SK_DECL
    je .kind_ok
    cmp eax, SK_ASSIGN
    jne .no
.kind_ok:
    cmp word [rsi + S_MODE], TY_INT
    jne .no
    cmp dword [rsi + S_NPARTS], 0
    je .no
    mov eax, [rsi + S_VAR]
    cmp eax, [r12 + S_VAR]
    je .no
    mov [sv_t], eax
    mov eax, [rsi + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    call node_addr
    cmp byte [rax + V_KIND], VK_EXPR
    jne .no
    mov rbx, rax
    mov dword [sv_sign], 1
    cmp byte [rbx + V_NEG], OP_ADD
    je .add
    cmp byte [rbx + V_NEG], OP_SUB
    jne .no
    mov dword [sv_sign], -1
    mov ecx, [rbx + V_DATA]
    call .is_target
    jz .no
    mov ecx, [rbx + V_DATA + 4]
    jmp .term
.add:
    mov ecx, [rbx + V_DATA]
    call .is_target
    jz .add_right
    mov ecx, [rbx + V_DATA + 4]
    jmp .term
.add_right:
    mov ecx, [rbx + V_DATA + 4]
    call .is_target
    jz .no
    mov ecx, [rbx + V_DATA]
.term:
    push rcx
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .term_var
    mov dword [sv_tkind], 0
    mov eax, [rax + V_DATA]
    mov [sv_k], eax
    jmp .cond
.term_var:
    call sv_node_is_loopvar
    test eax, eax
    jz .no
    mov dword [sv_tkind], 1
.cond:
    mov dword [sv_nleaf], 0
    mov ecx, [sv_cond]
    cmp ecx, -1
    je .yes
    call sv_leaves
    test eax, eax
    jnz .no
.yes:
    mov eax, 1
    pop rsi
    pop rbx
    ret
.no:
    xor eax, eax
    pop rsi
    pop rbx
    ret
.is_target:
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .not_target
    mov eax, [rax + V_DATA]
    cmp eax, [sv_t]
    jne .not_target
    or eax, 1
    ret
.not_target:
    xor eax, eax
    ret

sv_add_target:
    mov ecx, [sv_t]
    push rdx
    call var_reg
    pop rdx
    test eax, eax
    js .mem
    mov ecx, eax
    test r9d, r9d
    jz .reg_eax
    push rdx
    mov r9d, 0x81
    mov edx, 0xC0
    call emit_reg_short
    pop rdx
    jmp x64_imm32
.reg_eax:
    mov edx, ecx
    xor ecx, ecx
    mov r9d, 0x01
    mov r10d, 1
    jmp emit_rrop
.mem:
    mov ecx, [sv_t]
    shl rcx, 5
    add rcx, [g_vars]
    mov ecx, [rcx + VR_OFF]
    add ecx, RT_VARS
    push rdx
    push r9
    mov eax, 0x870141
    mov r8d, 0x878141
    test r9d, r9d
    cmovnz eax, r8d
    mov r8d, 3
    call x64_op_disp
    pop r9
    pop rdx
    test r9d, r9d
    jz .r
    jmp x64_imm32
.r:
    ret

simd_emit:
    push rbx
    push r13
    push r14
    push r15
    mov r14, [rsi + 48]
    and r14d, -4
    cmp dword [sv_cond], -1
    jne .vector
    cmp dword [sv_tkind], 0
    jne .vector
    mov edx, [sv_k]
    imul edx, r14d
    imul edx, [sv_sign]
    mov r9d, 1
    call sv_add_target
    jmp .finish

.vector:
    mov dword [sv_ndiv], 0
    mov eax, [sv_tkind]
    mov [sv_iv], eax
    xor ebx, ebx
.collect:
    cmp ebx, [sv_nleaf]
    jae .collected
    lea rax, [sv_ld]
    mov r13d, [rax + rbx * 4]
    lea rax, [sv_ldiv]
    mov dword [rax + rbx * 4], -1
    test r13d, r13d
    jnz .find_div
    mov dword [sv_iv], 1
    jmp .collect_next
.find_div:
    xor ecx, ecx
.find_loop:
    cmp ecx, [sv_ndiv]
    jae .new_div
    lea rax, [sv_div]
    cmp [rax + rcx * 4], r13d
    je .have_div
    inc ecx
    jmp .find_loop
.new_div:
    mov ecx, [sv_ndiv]
    inc dword [sv_ndiv]
    lea rax, [sv_div]
    mov [rax + rcx * 4], r13d
.have_div:
    lea rax, [sv_ldiv]
    mov [rax + rbx * 4], ecx
.collect_next:
    inc ebx
    jmp .collect
.collected:
    call sv_can16
    test eax, eax
    jnz .vector16
    mov ebx, 4
.choose_v:
    mov eax, [sv_ndiv]
    imul eax, ebx
    cmp dword [sv_iv], 0
    je .need_ok
    lea eax, [eax + ebx + 1]
.need_ok:
    cmp eax, 12
    ja .smaller_v
    mov rax, [rsi + 48]
    lea edx, [ebx * 8]
    cmp rax, rdx
    jae .v_ok
.smaller_v:
    shr ebx, 1
    jnz .choose_v
    mov ebx, 1
.v_ok:
    mov [sv_V], ebx
    lea eax, [ebx * 4]
    mov [sv_lanes], eax
    mov dword [sv_xnext], 0
    cmp dword [sv_iv], 0
    je .alloc_res
    call .xalloc
    mov [sv_stepr], eax
    xor ecx, ecx
.alloc_iv:
    cmp ecx, [sv_V]
    jae .alloc_res
    call .xalloc
    lea rdx, [sv_ivr]
    mov [rdx + rcx * 4], eax
    inc ecx
    jmp .alloc_iv
.alloc_res:
    mov eax, [sv_ndiv]
    imul eax, [sv_V]
    xor ecx, ecx
.alloc_res_loop:
    cmp ecx, eax
    jae .allocated
    push rax
    call .xalloc
    lea rdx, [sv_res]
    mov [rdx + rcx * 4], eax
    pop rax
    inc ecx
    jmp .alloc_res_loop
.allocated:
    BYTES 0x00000200EC8148, 7
    mov dword [sv_nslot], 0
    BYTES 0xC0EF0F66, 4
    BYTES 0xDB760F66, 4
    cmp dword [sv_iv], 0
    je .init_res
    mov r8d, [sv_V]
    shl r8d, 2
    call vec_bcast
    mov eax, 0x6F
    mov ecx, [sv_stepr]
    call sse_rm
    xor ebx, ebx
.init_iv:
    cmp ebx, [sv_V]
    jae .init_res
    lea r8d, [ebx * 4]
    lea r9d, [r8d + 1]
    lea r10d, [r8d + 2]
    lea r11d, [r8d + 3]
    call vec_slot
    mov eax, 0x6F
    lea rcx, [sv_ivr]
    mov ecx, [rcx + rbx * 4]
    call sse_rm
    inc ebx
    jmp .init_iv
.init_res:
    xor ebx, ebx
.init_div:
    cmp ebx, [sv_ndiv]
    jae .init_consts
    lea rax, [sv_div]
    mov r13d, [rax + rbx * 4]
    xor r14d, r14d
.init_lane:
    cmp r14d, [sv_V]
    jae .init_step
    lea eax, [r14d * 4]
    xor edx, edx
    div r13d
    mov r8d, edx
    lea eax, [r14d * 4 + 1]
    xor edx, edx
    div r13d
    mov r9d, edx
    lea eax, [r14d * 4 + 2]
    xor edx, edx
    div r13d
    mov r10d, edx
    lea eax, [r14d * 4 + 3]
    xor edx, edx
    div r13d
    mov r11d, edx
    call vec_slot
    mov eax, ebx
    imul eax, [sv_V]
    add eax, r14d
    lea rcx, [sv_res]
    mov ecx, [rcx + rax * 4]
    mov eax, 0x6F
    call sse_rm
    inc r14d
    jmp .init_lane
.init_step:
    lea rax, [sv_dslot]
    mov dword [rax + rbx * 4], -1
    mov eax, [sv_V]
    shl eax, 2
    xor edx, edx
    div r13d
    test edx, edx
    jz .init_div_next
    mov r8d, edx
    call vec_bcast
    lea rax, [sv_dslot]
    mov [rax + rbx * 4], edx
    lea r8d, [r13d - 1]
    call vec_bcast
    mov r8d, r13d
    call vec_bcast
.init_div_next:
    inc ebx
    jmp .init_div
.init_consts:
    xor ebx, ebx
.c_leaf:
    cmp ebx, [sv_nleaf]
    jae .c_done
    lea rax, [sv_lc]
    mov r8d, [rax + rbx * 4]
    call vec_bcast
    lea rax, [sv_lslot]
    mov [rax + rbx * 4], edx
    inc ebx
    jmp .c_leaf
.c_done:
    mov eax, [sv_k]
    imul eax, [sv_sign]
    mov r13d, eax
    cmp dword [sv_cond], -1
    je .k_done
    cmp dword [sv_tkind], 0
    jne .k_done
    cmp r13d, 1
    je .k_done
    cmp r13d, -1
    je .k_done
    mov r8d, r13d
    call vec_bcast
    mov [sv_kslot], edx
.k_done:
    mov rcx, [rsi + 24]
    mov rax, [rsi + 48]
    mov ecx, [sv_V]
    shl ecx, 2
    xor edx, edx
    div rcx
    mov rdx, rax
    mov rcx, [rsi + 24]
    call emit_mov_reg_imm
    call x64_text_offset
    mov r15, rax

    xor r14d, r14d
.vec_loop:
    cmp r14d, [sv_V]
    jae .vecs_done
    cmp dword [sv_cond], -1
    je .acc_uncond
    xor ebx, ebx
.leaf_emit:
    cmp ebx, [sv_nleaf]
    jae .leaves_done
    call .leaf_reg
    mov r13d, eax
    lea rax, [sv_lslot]
    mov edx, [rax + rbx * 4]
    push rdx
    lea rax, [sv_lop]
    mov eax, [rax + rbx * 4]
    cmp eax, CMP_LT
    je .leaf_lt
    push rax
    mov ecx, 5
    mov edx, r13d
    mov eax, 0x6F
    call sse_rr
    pop rax
    pop rdx
    mov ecx, 5
    cmp eax, CMP_GT
    je .leaf_gt
    push rax
    mov eax, 0x76
    call sse_rm
    pop rax
    cmp eax, CMP_ISNOT
    jne .leaf_merge
    mov eax, 0xEF
    mov ecx, 5
    mov edx, 3
    call sse_rr
    jmp .leaf_merge
.leaf_gt:
    mov eax, 0x66
    call sse_rm
    jmp .leaf_merge
.leaf_lt:
    pop rdx
    mov eax, 0x6F
    mov ecx, 5
    call sse_rm
    mov eax, 0x66
    mov ecx, 5
    mov edx, r13d
    call sse_rr
.leaf_merge:
    mov eax, 0xEB
    test ebx, ebx
    jnz .leaf_or
    mov eax, 0x6F
.leaf_or:
    mov ecx, 4
    mov edx, 5
    call sse_rr
    inc ebx
    jmp .leaf_emit
.leaves_done:
    mov eax, [sv_k]
    imul eax, [sv_sign]
    mov r13d, eax
    cmp dword [sv_tkind], 0
    jne .acc_iv
    mov eax, 0xFA
    cmp r13d, 1
    je .acc_mask
    mov eax, 0xFE
    cmp r13d, -1
    je .acc_mask
    mov eax, 0xDB
    mov ecx, 4
    mov edx, [sv_kslot]
    call sse_rm
    mov eax, 0xFE
.acc_mask:
    xor ecx, ecx
    mov edx, 4
    call sse_rr
    jmp .acc_done
.acc_iv:
    mov eax, 0xDB
    mov ecx, 4
    lea rdx, [sv_ivr]
    mov edx, [rdx + r14 * 4]
    call sse_rr
    mov edx, 4
    jmp .acc_signed
.acc_uncond:
    lea rdx, [sv_ivr]
    mov edx, [rdx + r14 * 4]
.acc_signed:
    mov eax, 0xFE
    cmp dword [sv_sign], 0
    jg .acc_sign_ok
    mov eax, 0xFA
.acc_sign_ok:
    xor ecx, ecx
    call sse_rr
.acc_done:
    inc r14d
    jmp .vec_loop
.vecs_done:
    cmp dword [sv_iv], 0
    je .res
    xor r14d, r14d
.iv_step:
    cmp r14d, [sv_V]
    jae .res
    mov eax, 0xFE
    lea rcx, [sv_ivr]
    mov ecx, [rcx + r14 * 4]
    mov edx, [sv_stepr]
    call sse_rr
    inc r14d
    jmp .iv_step
.res:
    xor ebx, ebx
.res_loop:
    cmp ebx, [sv_ndiv]
    jae .res_done
    lea rax, [sv_dslot]
    cmp dword [rax + rbx * 4], -1
    je .res_next
    xor r14d, r14d
.res_lane:
    cmp r14d, [sv_V]
    jae .res_next
    mov eax, ebx
    imul eax, [sv_V]
    add eax, r14d
    lea rcx, [sv_res]
    mov r13d, [rcx + rax * 4]
    lea rax, [sv_dslot]
    mov edx, [rax + rbx * 4]
    mov eax, 0xFE
    mov ecx, r13d
    call sse_rm
    mov eax, 0x6F
    mov ecx, 5
    mov edx, r13d
    call sse_rr
    lea rax, [sv_dslot]
    mov edx, [rax + rbx * 4]
    add edx, 16
    mov eax, 0x66
    mov ecx, 5
    call sse_rm
    lea rax, [sv_dslot]
    mov edx, [rax + rbx * 4]
    add edx, 32
    mov eax, 0xDB
    mov ecx, 5
    call sse_rm
    mov eax, 0xFA
    mov ecx, r13d
    mov edx, 5
    call sse_rr
    inc r14d
    jmp .res_lane
.res_next:
    inc ebx
    jmp .res_loop
.res_done:
    mov rcx, [rsi + 24]
    mov edx, 0xC8
    mov r9d, 0xFF
    call emit_reg_short
    BYTES 0x850F, 2
    mov rcx, r15
    call emit_rel32_back
    BYTES 0x4EE8700F66, 5
    BYTES 0xC5FE0F66, 4
    BYTES 0xB1E8700F66, 5
    BYTES 0xC5FE0F66, 4
    BYTES 0xC07E0F66, 4
    BYTES 0x00000200C48148, 7
    xor r9d, r9d
    call sv_add_target
    mov r14, [rsi + 48]
    mov eax, [sv_lanes]
    neg eax
    and r14d, eax
    jmp .finish

.vector16:
    mov ebx, 2
    mov rax, [rsi + 48]
    cmp rax, 32
    jae .v16_ok
    mov ebx, 1
.v16_ok:
    mov [sv_V], ebx
    lea eax, [ebx * 8]
    mov [sv_lanes], eax
    mov dword [sv_xnext], 0
    mov eax, [sv_ndiv]
    imul eax, ebx
    xor ecx, ecx
.v16_alloc:
    cmp ecx, eax
    jae .v16_allocated
    push rax
    call .xalloc
    lea rdx, [sv_res]
    mov [rdx + rcx * 4], eax
    pop rax
    inc ecx
    jmp .v16_alloc
.v16_allocated:
    BYTES 0x00000200EC8148, 7
    mov dword [sv_nslot], 0
    BYTES 0xC0EF0F66, 4
    BYTES 0xDB760F66, 4
    xor ebx, ebx
.v16_div:
    cmp ebx, [sv_ndiv]
    jae .v16_consts
    lea rax, [sv_div]
    mov r13d, [rax + rbx * 4]
    xor r14d, r14d
.v16_lane:
    cmp r14d, [sv_V]
    jae .v16_step
    lea eax, [r14d * 8]
    call .pair
    mov r8d, eax
    lea eax, [r14d * 8 + 2]
    call .pair
    mov r9d, eax
    lea eax, [r14d * 8 + 4]
    call .pair
    mov r10d, eax
    lea eax, [r14d * 8 + 6]
    call .pair
    mov r11d, eax
    call vec_slot
    mov eax, ebx
    imul eax, [sv_V]
    add eax, r14d
    lea rcx, [sv_res]
    mov ecx, [rcx + rax * 4]
    mov eax, 0x6F
    call sse_rm
    inc r14d
    jmp .v16_lane
.v16_step:
    lea rax, [sv_dslot]
    mov dword [rax + rbx * 4], -1
    mov eax, [sv_V]
    shl eax, 3
    xor edx, edx
    div r13d
    test edx, edx
    jz .v16_div_next
    mov eax, edx
    call .wbcast
    lea rax, [sv_dslot]
    mov [rax + rbx * 4], edx
    lea eax, [r13d - 1]
    call .wbcast
    mov eax, r13d
    call .wbcast
.v16_div_next:
    inc ebx
    jmp .v16_div
.v16_consts:
    xor ebx, ebx
.v16_c:
    cmp ebx, [sv_nleaf]
    jae .v16_k
    lea rax, [sv_lc]
    mov eax, [rax + rbx * 4]
    call .wbcast
    lea rax, [sv_lslot]
    mov [rax + rbx * 4], edx
    inc ebx
    jmp .v16_c
.v16_k:
    mov eax, [sv_k]
    imul eax, [sv_sign]
    neg eax
    call .wbcast
    mov [sv_kslot], edx
    mov rax, [rsi + 48]
    mov ecx, [sv_V]
    shl ecx, 3
    xor edx, edx
    div rcx
    mov rdx, rax
    mov rcx, [rsi + 24]
    call emit_mov_reg_imm
    call x64_text_offset
    mov r15, rax

    xor r14d, r14d
.v16_vec:
    cmp r14d, [sv_V]
    jae .v16_res
    xor ebx, ebx
.v16_leaf:
    cmp ebx, [sv_nleaf]
    jae .v16_acc
    call .leaf_reg
    mov r13d, eax
    lea rax, [sv_lslot]
    mov edx, [rax + rbx * 4]
    push rdx
    lea rax, [sv_lop]
    mov eax, [rax + rbx * 4]
    cmp eax, CMP_LT
    je .v16_lt
    push rax
    mov ecx, 5
    mov edx, r13d
    mov eax, 0x6F
    call sse_rr
    pop rax
    pop rdx
    mov ecx, 5
    cmp eax, CMP_GT
    je .v16_gt
    push rax
    mov eax, 0x75
    call sse_rm
    pop rax
    cmp eax, CMP_ISNOT
    jne .v16_merge
    mov eax, 0xEF
    mov ecx, 5
    mov edx, 3
    call sse_rr
    jmp .v16_merge
.v16_gt:
    mov eax, 0x65
    call sse_rm
    jmp .v16_merge
.v16_lt:
    pop rdx
    mov eax, 0x6F
    mov ecx, 5
    call sse_rm
    mov eax, 0x65
    mov ecx, 5
    mov edx, r13d
    call sse_rr
.v16_merge:
    mov eax, 0xEB
    test ebx, ebx
    jnz .v16_or
    mov eax, 0x6F
.v16_or:
    mov ecx, 4
    mov edx, 5
    call sse_rr
    inc ebx
    jmp .v16_leaf
.v16_acc:
    mov eax, 0xF5
    mov ecx, 4
    mov edx, [sv_kslot]
    call sse_rm
    mov eax, 0xFE
    xor ecx, ecx
    mov edx, 4
    call sse_rr
    inc r14d
    jmp .v16_vec
.v16_res:
    xor ebx, ebx
.v16_res_div:
    cmp ebx, [sv_ndiv]
    jae .res_done16
    lea rax, [sv_dslot]
    cmp dword [rax + rbx * 4], -1
    je .v16_res_next
    xor r14d, r14d
.v16_res_lane:
    cmp r14d, [sv_V]
    jae .v16_res_next
    mov eax, ebx
    imul eax, [sv_V]
    add eax, r14d
    lea rcx, [sv_res]
    mov r13d, [rcx + rax * 4]
    lea rax, [sv_dslot]
    mov edx, [rax + rbx * 4]
    mov eax, 0xFD
    mov ecx, r13d
    call sse_rm
    mov eax, 0x6F
    mov ecx, 5
    mov edx, r13d
    call sse_rr
    lea rax, [sv_dslot]
    mov edx, [rax + rbx * 4]
    add edx, 16
    mov eax, 0x65
    mov ecx, 5
    call sse_rm
    lea rax, [sv_dslot]
    mov edx, [rax + rbx * 4]
    add edx, 32
    mov eax, 0xDB
    mov ecx, 5
    call sse_rm
    mov eax, 0xF9
    mov ecx, r13d
    mov edx, 5
    call sse_rr
    inc r14d
    jmp .v16_res_lane
.v16_res_next:
    inc ebx
    jmp .v16_res_div
.res_done16:
    jmp .res_done

.pair:
    push rax
    xor edx, edx
    div r13d
    mov ecx, edx
    pop rax
    inc eax
    xor edx, edx
    div r13d
    shl edx, 16
    or edx, ecx
    mov eax, edx
    ret

.wbcast:
    movzx r8d, ax
    shl eax, 16
    or r8d, eax
    jmp vec_bcast

.xalloc:
    mov eax, [sv_xnext]
    inc dword [sv_xnext]
    lea rdx, [sv_xfree]
    movzx eax, byte [rdx + rax]
    ret

.leaf_reg:
    lea rax, [sv_ldiv]
    mov eax, [rax + rbx * 4]
    cmp eax, -1
    je .leaf_iv
    imul eax, [sv_V]
    add eax, r14d
    lea rdx, [sv_res]
    mov eax, [rdx + rax * 4]
    ret
.leaf_iv:
    lea rdx, [sv_ivr]
    mov eax, [rdx + r14 * 4]
    ret

.finish:
    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov ecx, [rax + VR_OFF]
    add ecx, RT_VARS
    OPD 0x87C741, 3, ecx
    lea edx, [r14d - 1]
    call x64_imm32
    mov [rsi + 72], r14
    pop r15
    pop r14
    pop r13
    pop rbx
    ret

loops_closed:
    cmp qword [rsi + 40], 0
    jne .r
    cmp qword [rsi + 48], 0
    jle .r
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    add eax, 2
    cmp [r12 + S_PIECES], eax
    jne .r
    lea rdx, [r12 + S_SIZE]
    movzx eax, word [rdx + S_KIND]
    cmp eax, SK_DECL
    je .kind
    cmp eax, SK_ASSIGN
    jne .r
.kind:
    cmp word [rdx + S_MODE], TY_INT
    jne .r
    cmp dword [rdx + S_NPARTS], 0
    je .r
    mov ecx, [rdx + S_VAR]
    mov [sv_t], ecx
    push rdx
    mov rax, rdx
    call stmt_root
    call node_addr
    pop rdx
    cmp byte [rax + V_KIND], VK_EXPR
    jne .r
    movzx r8d, byte [rax + V_NEG]
    mov r9d, [rax + V_DATA]
    mov r10d, [rax + V_DATA + 4]
    cmp r8d, OP_SUB
    je .order
    cmp r8d, OP_ADD
    jne .r
    mov ecx, r10d
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .order
    xchg r9d, r10d
.order:
    mov ecx, r9d
    call node_addr
    cmp byte [rax + V_KIND], VK_VAR
    jne .r
    mov ecx, [rax + V_DATA]
    cmp ecx, [sv_t]
    jne .r
    mov ecx, r10d
    call node_addr
    cmp byte [rax + V_KIND], VK_INT
    jne .r
    mov edx, [rax + V_DATA]
    cmp r8d, OP_SUB
    jne .k_ok
    neg edx
.k_ok:
    imul edx, [rsi + 48]
    mov r9d, 1
    call sv_add_target
    mov qword [rsi + 48], 0
    mov qword [rsi + 80], 1
    mov eax, [r12 + S_PIECES]
    mov [cg_skip], rax
.r:
    ret

body_callfree:
    push rbx
    push r13
    push r14
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
    lea r13d, [eax + 1]
    mov r14d, [r12 + S_PIECES]
.l:
    cmp r13d, r14d
    jae .yes
    mov rbx, r13
    shl rbx, 5
    add rbx, [g_stmts]
    inc r13d
    movzx eax, word [rbx + S_KIND]
    cmp eax, SK_OUT
    je .no
    cmp eax, SK_INPUT
    je .no
    mov ecx, [rbx + S_PARTS]
    mov rdx, [g_roots]
    cmp eax, SK_IF
    je .cond
    cmp eax, SK_FOR
    je .expr
    cmp eax, SK_LOOPS
    je .expr
    cmp dword [rbx + S_NPARTS], 0
    je .l
    cmp word [rbx + S_MODE], TY_INT
    jne .l
.expr:
    mov ecx, [rdx + rcx * 4]
    call expr_safe
    test eax, eax
    jz .no
    jmp .l
.cond:
    mov ecx, [rdx + rcx * 4]
    call cond_leaves
    test eax, eax
    js .no
    jmp .l
.yes:
    mov eax, 1
    jmp .r
.no:
    xor eax, eax
.r:
    pop r14
    pop r13
    pop rbx
    ret

unroll_plan:
    mov qword [rsi + 80], 1
    test word [r12 + S_MODE], 1
    jnz .r
    cmp qword [rsi + 24], 0xFF
    je .r
    cmp qword [rsi + 40], 0
    jne .r
    mov rax, [rsi + 48]
    cmp rax, 8
    jl .r
    mov r8d, 4
    test al, 3
    jz .f
    mov r8d, 2
    test al, 1
    jnz .r
.f:
    push r8
    call body_callfree
    pop r8
    test eax, eax
    jz .r
    mov [rsi + 80], r8
.r:
    ret

unroll_body:
    cmp qword [rsi + 96], 0
    jne .r
    mov r8, [rsi + 80]
    cmp r8, 1
    jbe .r
    cmp qword [rsi + 72], 0
    jne .no
    call x64_text_offset
    sub rax, [rsi + 16]
    cmp r8, 4
    jne .size2
    cmp rax, 96
    jbe .sized
    mov r8d, 2
.size2:
    cmp rax, 256
    ja .no
.sized:
    lea rdx, [rax + 3]
    lea rcx, [r8 - 1]
    imul rdx, rcx
    add rdx, [cg_extra]
    cmp rdx, 65536
    ja .no
    mov [cg_extra], rdx
    mov [rsi + 80], r8
    push rbx
    push r12
    mov r12, rax
    lea rbx, [r8 - 1]
.copy:
    cmp qword [rsi + 8], BK_FOR
    jne .raw
    mov rcx, [rsi + 24]
    mov edx, 0xC0
    mov r9d, 0xFF
    call emit_reg_short
.raw:
    push rsi
    mov rax, [rsi + 16]
    mov rsi, [x64_text_base]
    add rsi, rax
    mov rcx, r12
    rep movsb
    pop rsi
    dec rbx
    jnz .copy
    pop r12
    pop rbx
.r:
    ret
.no:
    mov qword [rsi + 80], 1
    ret

reg_rex:
    xor eax, eax
    cmp ecx, 8
    jb .r
    mov eax, 1
.r:
    ret

emit_reg_short:
    push rcx
    call reg_rex
    test eax, eax
    jz .no_rex
    push rdx
    BYTES 0x41, 1
    pop rdx
.no_rex:
    pop rcx
    and ecx, 7
    or ecx, edx
    mov eax, ecx
    shl eax, 8
    or eax, r9d
    mov r8d, 2
    jmp x64_bytes

emit_mov_reg_imm:
    push rdx
    push rcx
    call reg_rex
    test eax, eax
    jz .no_rex
    BYTES 0x41, 1
.no_rex:
    pop rcx
    and ecx, 7
    lea eax, [ecx + 0xB8]
    mov r8d, 1
    call x64_bytes
    pop rdx
    jmp x64_imm32

emit_rr:
    push rcx
    call reg_rex
    test eax, eax
    jz .no_rex
    push r9
    BYTES 0x45, 1
    pop r9
.no_rex:
    pop rcx
    and ecx, 7
    mov eax, ecx
    shl eax, 3
    or eax, ecx
    or eax, 0xC0
    shl eax, 8
    or eax, r9d
    mov r8d, 2
    jmp x64_bytes

emit_mem_reg:
    push rdx
    push rcx
    call reg_rex
    shl eax, 2
    or eax, 0x41
    pop rcx
    and ecx, 7
    shl ecx, 3
    or ecx, 0x87
    shl ecx, 16
    or eax, ecx
    shl r9d, 8
    or eax, r9d
    mov r8d, 3
    call x64_bytes
    pop rdx
    jmp x64_imm32

emit_rel32_back:
    call x64_text_offset
    add eax, 4
    sub ecx, eax
    mov [rdi], ecx
    add rdi, 4
    ret

emit_rel32_fwd:
    call x64_text_offset
    mov dword [rdi], 0
    add rdi, 4
    ret

patch_initial:
    mov rax, [rsi + 56]
    cmp rax, -1
    je .none
    push rax
    call x64_text_offset
    mov edx, eax
    pop rax
    sub edx, eax
    sub edx, 4
    mov rcx, [x64_text_base]
    mov [rcx + rax], edx
.none:
    ret

emit_loop_head:
    push rsi
    push rbx
    mov rax, [cg_bdepth]
    shl rax, 7
    lea rsi, [cg_bstack]
    add rsi, rax
    inc qword [cg_bdepth]
    mov edx, [r12 + S_PIECES]
    mov [rsi], rdx
    mov qword [rsi + 56], -1
    mov qword [rsi + 64], -1
    mov qword [rsi + 72], 0
    mov qword [rsi + 88], 0
    mov qword [rsi + 96], 0
    mov qword [rsi + 104], 0
    mov qword [rsi + 112], 0
    mov qword [rsi + 120], 0
    test word [r12 + S_MODE], 1
    jz .no_label
    mov rax, [cg_label]
    mov [rsi + 120], eax
    add qword [cg_label], 2
.no_label:
    mov eax, [r12 + S_MODETOK]
    test eax, eax
    jz .no_take
    dec eax
    shl rax, 5
    add rax, [g_stmts]
    test word [rax + S_MODE], 1
    jz .no_take
    mov eax, [rax + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov eax, [rax + VR_OFF]
    add eax, RT_VARS
    mov [rsi + 124], eax
.no_take:
    mov qword [rsi + 8], BK_LOOPS
    cmp word [r12 + S_KIND], SK_FOR
    jne .kind_set
    mov qword [rsi + 8], BK_FOR
.kind_set:
    mov rax, [cg_ldepth]
    inc qword [cg_ldepth]
    mov ecx, 0xFF
    cmp rax, MAX_REG_LOOPS
    jae .reg_set
    lea rcx, [loop_regs]
    movzx ecx, byte [rcx + rax]
.reg_set:
    mov [rsi + 24], rcx
    mov eax, [r12 + S_NPIECES]
    add eax, RT_VARS
    mov [rsi + 48], rax
    add eax, 4
    mov [rsi + 32], rax
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    push rcx
    call node_addr
    pop rcx
    cmp byte [rax + V_KIND], VK_INT
    jne .dynamic
    mov qword [rsi + 40], 0
    movsxd rdx, dword [rax + V_DATA]
    mov [rsi + 48], rdx
    jmp .count_ready
.dynamic:
    mov qword [rsi + 40], 1
    call emit_expr
.count_ready:
    call take_store
    call unroll_plan
    cmp qword [rsi + 8], BK_FOR
    je .for_head
    call loops_closed

    cmp qword [rsi + 40], 0
    jne .loops_dyn
    mov rdx, [rsi + 48]
    cmp qword [rsi + 24], 0xFF
    je .loops_const_mem
    mov rcx, [rsi + 24]
    call emit_mov_reg_imm
    jmp .loops_test
.loops_const_mem:
    mov ecx, [rsi + 32]
    OPD 0x87C741, 3, ecx
    mov rdx, [rsi + 48]
    call x64_imm32
    jmp .loops_test
.loops_dyn:
    cmp qword [rsi + 24], 0xFF
    je .loops_dyn_mem
    mov rcx, [rsi + 24]
    mov edx, 0xC0
    mov r9d, 0x89
    call emit_reg_short
    jmp .loops_test
.loops_dyn_mem:
    mov ecx, [rsi + 32]
    OPD 0x878941, 3, ecx
.loops_test:
    cmp qword [rsi + 40], 0
    jne .loops_need_test
    cmp qword [rsi + 48], 0
    jg .loops_top
.loops_need_test:
    cmp qword [rsi + 24], 0xFF
    je .loops_test_mem
    mov rcx, [rsi + 24]
    mov r9d, 0x85
    call emit_rr
    jmp .loops_jle
.loops_test_mem:
    mov ecx, [rsi + 32]
    OPD 0xBF8341, 3, ecx
    BYTES 0x00, 1
.loops_jle:
    BYTES 0x8E0F, 2
    call emit_rel32_fwd
    mov [rsi + 56], rax
.loops_top:
    call x64_text_offset
    mov [rsi + 16], rax
    jmp .done

.for_head:
    cmp qword [rsi + 40], 0
    je .for_simd
    mov ecx, [rsi + 48]
    OPD 0x878941, 3, ecx
    jmp .for_init
.for_simd:
    test word [r12 + S_MODE], 1
    jnz .for_init
    cmp qword [rsi + 24], 0xFF
    je .for_init
    cmp qword [rsi + 48], 8
    jl .for_init
    call simd_match
    test eax, eax
    jz .for_init
    call simd_emit
.for_init:
    cmp qword [rsi + 24], 0xFF
    je .for_init_mem
    mov rcx, [rsi + 24]
    cmp qword [rsi + 72], 0
    jne .for_init_start
    mov r9d, 0x31
    call emit_rr
    jmp .for_jump
.for_init_start:
    mov rdx, [rsi + 72]
    call emit_mov_reg_imm
    jmp .for_need_jump
.for_init_mem:
    mov ecx, [rsi + 32]
    OPD 0x87C741, 3, ecx
    xor edx, edx
    call x64_imm32
.for_jump:
    cmp qword [rsi + 40], 0
    jne .for_need_jump
    cmp qword [rsi + 48], 0
    jg .for_top
.for_need_jump:
    BYTES 0xE9, 1
    call emit_rel32_fwd
    mov [rsi + 56], rax
.for_top:
    call x64_text_offset
    mov [rsi + 16], rax
    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov edx, [rax + VR_OFF]
    add edx, RT_VARS
    cmp qword [rsi + 24], 0xFF
    je .for_store_mem
    test word [r12 + S_MODE], 1
    jnz .for_store_reg
    push rdx
    mov ecx, [r12 + S_VAR]
    call for_aliasable
    pop rdx
    test eax, eax
    jz .for_store_reg
    mov ecx, [r12 + S_VAR]
    mov [rsi + 64], rcx
    mov rax, [cg_vreg]
    mov r8, [rsi + 24]
    inc r8d
    or r8d, 0x40
    mov [rax + rcx], r8b
    mov r8d, 0x7FFFFFFE
    cmp qword [rsi + 40], 0
    jne .alias_hi
    mov r8, [rsi + 48]
    dec r8d
.alias_hi:
    mov rax, [cg_vhi]
    mov [rax + rcx * 4], r8d
    cmp qword [rsi + 40], 0
    jne .for_store_reg
    cmp qword [rsi + 48], 0
    jle .for_store_reg
    push rdx
    call body_callfree
    pop rdx
    test eax, eax
    jz .for_store_reg
    mov [rsi + 88], rdx
    jmp .done
.for_store_reg:
    mov rcx, [rsi + 24]
    mov r9d, 0x89
    call emit_mem_reg
    jmp .done
.for_store_mem:
    push rdx
    mov ecx, [rsi + 32]
    OPD 0x878B41, 3, ecx
    pop r9
    OPD 0x878941, 3, r9d
.done:
    call try_jump_ahead
    pop rbx
    pop rsi
    ret

emit_loop_tail:
    mov rcx, [rsi + 64]
    cmp rcx, -1
    je .no_alias
    mov rax, [cg_vreg]
    mov byte [rax + rcx], 0
    mov rax, [cg_vhi]
    mov dword [rax + rcx * 4], -1
.no_alias:
    call unroll_body
    mov ecx, [rsi + 120]
    test ecx, ecx
    jz .no_cont
    inc ecx
    call place_label
.no_cont:
    cmp qword [rsi + 8], BK_FOR
    jne .loops_tail
    cmp qword [rsi + 24], 0xFF
    je .for_inc_mem
    mov rcx, [rsi + 24]
    mov edx, 0xC0
    mov r9d, 0xFF
    call emit_reg_short
    jmp .for_check
.for_inc_mem:
    mov ecx, [rsi + 32]
    OPD 0x87FF41, 3, ecx
.for_check:
    call patch_initial
    cmp qword [rsi + 24], 0xFF
    je .for_cmp_mem
    cmp qword [rsi + 40], 0
    jne .for_cmp_reg_slot
    mov rcx, [rsi + 24]
    call reg_rex
    test eax, eax
    jz .cmp_norex
    BYTES 0x41, 1
.cmp_norex:
    mov rcx, [rsi + 24]
    and ecx, 7
    lea eax, [ecx + 0xF8]
    shl eax, 8
    or eax, 0x81
    mov r8d, 2
    call x64_bytes
    mov rdx, [rsi + 48]
    call x64_imm32
    jmp .jl_back
.for_cmp_reg_slot:
    mov rcx, [rsi + 24]
    mov rdx, [rsi + 48]
    mov r9d, 0x3B
    call emit_mem_reg
    jmp .jl_back
.for_cmp_mem:
    cmp qword [rsi + 40], 0
    jne .for_cmp_mem_slot
    mov ecx, [rsi + 32]
    OPD 0xBF8141, 3, ecx
    mov rdx, [rsi + 48]
    call x64_imm32
    jmp .jl_back
.for_cmp_mem_slot:
    mov ecx, [rsi + 32]
    OPD 0x878B41, 3, ecx
    mov ecx, [rsi + 48]
    OPD 0x873B41, 3, ecx
.jl_back:
    BYTES 0x8C0F, 2
    mov rcx, [rsi + 16]
    call emit_rel32_back
    mov ecx, [rsi + 88]
    test ecx, ecx
    jz .r
    OPD 0x87C741, 3, ecx
    mov rdx, [rsi + 48]
    dec edx
    jmp x64_imm32
.r:
    ret

.loops_tail:
    cmp qword [rsi + 24], 0xFF
    je .loops_dec_mem
    mov rcx, [rsi + 24]
    cmp qword [rsi + 80], 1
    ja .loops_sub
    mov edx, 0xC8
    mov r9d, 0xFF
    call emit_reg_short
    jmp .loops_jnz
.loops_sub:
    mov edx, 0xE8
    mov r9d, 0x83
    call emit_reg_short
    mov rdx, [rsi + 80]
    call x64_imm8
    jmp .loops_jnz
.loops_dec_mem:
    mov ecx, [rsi + 32]
    OPD 0x8FFF41, 3, ecx
.loops_jnz:
    BYTES 0x850F, 2
    mov rcx, [rsi + 16]
    call emit_rel32_back
    jmp patch_initial

section .rodata
loop_regs db 3, 6, 7, 12, 13, 14, 5
ja_factors db 8, 4, 6, 5, 3, 2, 0
sv_xfree   db 1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
section .text
