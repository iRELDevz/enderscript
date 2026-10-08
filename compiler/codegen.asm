%include "defs.inc"
%include "state.inc"

extern rt_start, rt_size, rt_offsets
extern x64_text_base, x64_op_disp, x64_bytes, x64_imm8, x64_imm16, x64_imm32
extern x64_call_rel, x64_text_offset
extern pe_layout, pe_finish
extern pool_compact
extern pe_R, pe_D, pe_I, pe_T, pe_text_file, pe_entry, g_image

%define RT_FN_WRITE      0
%define RT_FN_WRITE_INT  4
%define RT_FN_WRITE_BOOL 8
%define RT_FN_WRITE_STR  12
%define RT_FN_FLUSH      16
%define RT_FN_DIV_ZERO   20
%define RT_FN_STR_EQ     24

%define IAT_GETSTDHANDLE 72
%define IAT_WRITEFILE    80
%define IAT_EXITPROCESS  88

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
cg_bpatch resq 1
cg_nbody  resq 1
cg_bdepth resq 1
cg_bstack resq 2 * (MAX_BLOCKS + 1)

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
    call pe_layout
    mov rdi, [g_image]
    add rdi, [pe_text_file]
    mov [x64_text_base], rdi
    lea rsi, [rt_start]
    mov ecx, [rt_size]
    rep movsb
    mov rbx, [pe_R]
    sub rbx, [pe_D]
    mov [cg_rdelta], rbx
    push rdi
    mov rcx, [g_nparts]
    add rcx, 16
    shl rcx, 2
    call mem_alloc
    mov [cg_patch], rax
    mov rcx, [g_nparts]
    add rcx, 16
    shl rcx, 2
    call mem_alloc
    mov [cg_bpatch], rax
    pop rdi
    mov qword [cg_npatch], 0
    mov qword [cg_nbody], 0
    mov qword [cg_bdepth], 0
    call outline_pass
.pad:
    call x64_text_offset
    test eax, 15
    jz .entry
    mov byte [rdi], 0xCC
    inc rdi
    jmp .pad
.entry:
    mov [pe_entry], rax

    BYTES 0x28EC8348, 4
    BYTES 0x3D8D4C, 3
    call x64_text_offset
    add rax, 4
    add rax, [pe_T]
    mov rcx, [pe_D]
    sub rcx, rax
    mov [rdi], ecx
    add rdi, 4
    BYTES 0xFFFFFFF5B9, 5
    mov r12, [pe_I]
    sub r12, [pe_D]
    lea r13d, [r12d + IAT_GETSTDHANDLE]
    OPD 0x97FF41, 3, r13d
    BYTES 0x08478949, 4
    lea r13d, [r12d + IAT_WRITEFILE]
    OPD 0x878B49, 3, r13d
    BYTES 0x10478949, 4
    lea r13d, [r12d + IAT_GETSTDHANDLE]
    OPD 0x878B49, 3, r13d
    BYTES 0x18478949, 4
    lea r13d, [r12d + IAT_EXITPROCESS]
    OPD 0x878B49, 3, r13d
    BYTES 0x20478949, 4

    mov rbx, [pe_R]
    sub rbx, [pe_D]
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
    mov eax, [r12 + S_TOK]
    shl rax, 4
    add rax, [g_tokens]
    mov eax, [rax + T_LINE]
    mov [cg_line], eax
    cmp word [r12 + S_KIND], SK_OUT
    je .out
    cmp word [r12 + S_KIND], SK_IF
    je .if

    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov r14d, [rax + VR_OFF]
    add r14d, RT_VARS
    movzx r15d, word [r12 + S_MODE]
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
    OPD 0x87C741, 3, r14d
    mov edx, [rsi + V_DATA]
    call x64_imm32
    jmp .next
.store_expr:
    mov ecx, [r12 + S_VAR]
    mov edx, r14d
    call try_update_in_place
    test eax, eax
    jnz .next
    mov ecx, [cg_target]
    call emit_expr
    OPD 0x878941, 3, r14d
    jmp .next
.store_bool:
    OPD 0x87C641, 3, r14d
    mov edx, [rsi + V_DATA]
    call x64_imm8
    jmp .next
.store_str:
    mov eax, [rsi + V_DATA]
    lea ecx, [ebx + eax]
    OPD 0x878D49, 3, ecx
    OPD 0x878949, 3, r14d
    lea ecx, [r14d + 8]
    OPD 0x87C74166, 4, ecx
    mov edx, [rsi + V_DATA + 4]
    call x64_imm16
    jmp .next

.store_default:
    cmp r15d, TY_INT
    jne .def_not_int
    OPD 0x87C741, 3, r14d
    xor edx, edx
    call x64_imm32
    jmp .next
.def_not_int:
    cmp r15d, TY_BOOL
    jne .def_str
    OPD 0x87C641, 3, r14d
    xor edx, edx
    call x64_imm8
    jmp .next
.def_str:
    OPD 0x87C749, 3, r14d
    xor edx, edx
    call x64_imm32
    lea ecx, [r14d + 8]
    OPD 0x87C74166, 4, ecx
    xor edx, edx
    call x64_imm16
    jmp .next

.copy_var:
    mov eax, [rsi + V_DATA]
    shl rax, 5
    add rax, [g_vars]
    mov esi, [rax + VR_OFF]
    add esi, RT_VARS
    cmp r15d, TY_INT
    jne .copy_not_int
    OPD 0x878B41, 3, esi
    OPD 0x878941, 3, r14d
    jmp .next
.copy_not_int:
    cmp r15d, TY_BOOL
    jne .copy_str
    OPD 0x878A41, 3, esi
    OPD 0x878841, 3, r14d
    jmp .next
.copy_str:
    OPD 0x878B49, 3, esi
    OPD 0x878949, 3, r14d
    lea ecx, [esi + 8]
    OPD 0x878B4166, 4, ecx
    lea ecx, [r14d + 8]
    OPD 0x87894166, 4, ecx
    jmp .next

.out:
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
    mov rax, [cg_bdepth]
    shl rax, 4
    lea rcx, [cg_bstack]
    mov edx, [r12 + S_PIECES]
    mov [rcx + rax], rdx
    mov rdx, [cg_npatch]
    mov [rcx + rax + 8], rdx
    inc qword [cg_bdepth]
    mov qword [cg_nbody], 0
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    mov edx, 1
    call emit_cond
    call patch_body
    jmp .next

.next:
    add r12, S_SIZE
    jmp .stmt

.epilogue:
    CALL_RT RT_FN_FLUSH
    BYTES 0xC931, 2
    mov r12, [pe_I]
    sub r12, [pe_D]
    lea r13d, [r12d + IAT_EXITPROCESS]
    OPD 0x97FF41, 3, r13d
    call x64_text_offset
    mov rcx, rax
    call pe_finish
    ENDF

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
    mov ecx, [rsi + V_DATA + 4]
    call apply_simple
    jmp .done
.left_simple:
    mov ecx, [rsi + V_DATA + 4]
    call emit_expr
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
    BYTES 0xC069, 2
    mov edx, r9d
    jmp x64_imm32
.div_imm:
    call pow2_shift
    test eax, eax
    jz .div_plain
    push rax
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [r9d - 1]
    call x64_imm32
    BYTES 0xD001, 2
    BYTES 0xF8C1, 2
    pop rdx
    jmp x64_imm8
.div_plain:
    BYTES 0xB9, 1
    mov edx, r9d
    call x64_imm32
    BYTES 0xF9F799, 3
    ret
.mod_imm:
    call pow2_shift
    test eax, eax
    jz .mod_plain
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
    BYTES 0xB9, 1
    mov edx, r9d
    call x64_imm32
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    ret
.var:
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

patch_body:
    mov rcx, [cg_bpatch]
    xor r9d, r9d
    mov r10, [cg_nbody]
    call patch_list
    mov qword [cg_nbody], 0
    ret

close_blocks:
    push rbx
    mov rbx, rax
.loop:
    mov rax, [cg_bdepth]
    test rax, rax
    jz .done
    dec rax
    shl rax, 4
    lea rcx, [cg_bstack]
    cmp [rcx + rax], rbx
    jne .done
    mov r9, [rcx + rax + 8]
    mov rcx, [cg_patch]
    mov r10, [cg_npatch]
    push r9
    call patch_list
    pop r9
    mov [cg_npatch], r9
    dec qword [cg_bdepth]
    jmp .loop
.done:
    pop rbx
    ret

jump_to_end:
    mov rcx, [cg_patch]
    lea r8, [cg_npatch]
    jmp record_patch

jump_to_body:
    mov rcx, [cg_bpatch]
    lea r8, [cg_nbody]
    jmp record_patch

emit_jcc:
    shl eax, 8
    or eax, 0x800F
    push rdx
    mov r8d, 2
    call x64_bytes
    pop rdx
    test edx, edx
    jnz jump_to_body
    jmp jump_to_end

emit_cond:
    push rsi
    push rbx
    mov ebx, edx
    call node_addr
    mov rsi, rax
    movzx eax, byte [rsi + V_KIND]
    cmp eax, VK_BOOL
    je .const
    cmp eax, VK_OR
    je .or
    call emit_compare
    test ebx, ebx
    jz .to_body
    xor eax, 1
    xor edx, edx
    call emit_jcc
    jmp .done
.to_body:
    mov edx, 1
    call emit_jcc
    jmp .done
.const:
    cmp qword [rsi + V_DATA], 0
    jne .const_true
    test ebx, ebx
    jz .done
    BYTES 0xE9, 1
    call jump_to_end
    jmp .done
.const_true:
    test ebx, ebx
    jnz .done
    BYTES 0xE9, 1
    call jump_to_body
    jmp .done
.or:
    mov ecx, [rsi + V_DATA]
    xor edx, edx
    call emit_cond
    mov ecx, [rsi + V_DATA + 4]
    mov edx, ebx
    call emit_cond
.done:
    pop rbx
    pop rsi
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
    cmp r14d, CMP_GT
    jne .int_order_ok
    mov r14d, CMP_LT
    jmp .int_order_ok
.mirror_gt:
    mov r14d, CMP_GT
.int_order_ok:
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
    BYTES 0x3D, 1
    mov edx, r9d
    call x64_imm32
    jmp .int_cc
.int_mem:
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
