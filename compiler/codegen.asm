%include "defs.inc"
%include "state.inc"

extern rt_start, rt_size, rt_offsets
extern x64_text_base, x64_op_disp, x64_bytes, x64_imm8, x64_imm16, x64_imm32
extern x64_call_rel, x64_text_offset
extern elf_layout, elf_finish
extern el_R_va, el_T_off, el_T_va, el_D_va, el_entry, g_image

%define RT_FN_WRITE      0
%define RT_FN_WRITE_INT  4
%define RT_FN_WRITE_BOOL 8
%define RT_FN_WRITE_STR  12
%define RT_FN_FLUSH      16


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
    call elf_layout
    mov rdi, [g_image]
    add rdi, [el_T_off]
    mov [x64_text_base], rdi
    lea rsi, [rt_start]
    mov ecx, [rt_size]
    rep movsb
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

    mov rbx, [el_R_va]
    sub rbx, [el_D_va]
    mov r12, [g_stmts]
    mov r13, [g_nstmt]
    shl r13, 5
    add r13, r12
.stmt:
    cmp r12, r13
    jae .epilogue
    cmp word [r12 + S_KIND], SK_OUT
    je .out

    mov eax, [r12 + S_VAR]
    shl rax, 5
    add rax, [g_vars]
    mov r14d, [rax + VR_OFF]
    add r14d, RT_VARS
    movzx r15d, word [r12 + S_MODE]
    cmp dword [r12 + S_NPARTS], 0
    je .store_default
    mov esi, [r12 + S_PARTS]
    shl rsi, 4
    add rsi, [g_parts]
    movzx eax, byte [rsi + V_KIND]
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
    mov r14d, [r12 + S_PIECES]
    mov r15d, [r12 + S_NPIECES]
    add r15d, r14d
.piece:
    cmp r14d, r15d
    jae .next
    mov esi, r14d
    shl rsi, 4
    add rsi, [g_pieces]
    inc r14d
    mov eax, [rsi + P_KIND]
    cmp eax, PK_TEXT
    jne .piece_var
    cmp dword [rsi + P_B], 0
    je .piece
    mov eax, [rsi + P_A]
    lea ecx, [ebx + eax]
    OPD 0x8F8D49, 3, ecx
    BYTES 0xBA, 1
    mov edx, [rsi + P_B]
    call x64_imm32
    CALL_RT RT_FN_WRITE
    jmp .piece
.piece_var:
    mov ecx, [rsi + P_A]
    add ecx, RT_VARS
    cmp eax, PK_INT
    jne .piece_not_int
    OPD 0x8F8B41, 3, ecx
    CALL_RT RT_FN_WRITE_INT
    jmp .piece
.piece_not_int:
    cmp eax, PK_BOOL
    jne .piece_str
    OPD 0x8FB60F41, 4, ecx
    CALL_RT RT_FN_WRITE_BOOL
    jmp .piece
.piece_str:
    OPD 0x8F8D49, 3, ecx
    CALL_RT RT_FN_WRITE_STR
    jmp .piece

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
