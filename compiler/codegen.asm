%include "defs.inc"
%include "state.inc"

extern rt_start, rt_size, rt_offsets
extern x86_text_base, x86_bytes, x86_imm32, x86_imm16, x86_imm8, x86_op_abs
extern x86_call_rel, x86_text_offset
extern pe_layout, pe_finish
extern pe_R, pe_D, pe_I, pe_T, pe_entry, pe_text_file, g_image

%define IMAGE_BASE       0x400000
%define RT_FN_WRITE      0
%define RT_FN_WRITE_INT  4
%define RT_FN_WRITE_BOOL 8
%define RT_FN_WRITE_STR  12
%define RT_FN_FLUSH      16

%define IAT_GETSTDHANDLE 56
%define IAT_WRITEFILE    60
%define IAT_EXITPROCESS  64

section .bss
alignb 4
cg_end    resd 1
cg_vars   resd 1
cg_pool   resd 1
cg_dst    resd 1
cg_type   resd 1
cg_piece  resd 1
cg_plast  resd 1

section .text

%macro OPA 3
    mov eax, %1
    mov ecx, %2
    mov edx, %3
    call x86_op_abs
%endmacro

%macro BYTES 2
    mov eax, %1
    mov ecx, %2
    call x86_bytes
%endmacro

%macro CALL_RT 1
    mov ecx, [rt_offsets + %1]
    call x86_call_rel
%endmacro

FUNC codegen
    call pe_layout
    mov edi, [g_image]
    add edi, [pe_text_file]
    mov [x86_text_base], edi
    mov esi, rt_start
    mov ecx, [rt_size]
    rep movsb
.pad:
    call x86_text_offset
    test eax, 15
    jz .entry
    mov byte [edi], 0xCC
    inc edi
    jmp .pad
.entry:
    mov [pe_entry], eax

    mov eax, [pe_D]
    add eax, IMAGE_BASE
    mov ebx, eax
    lea ecx, [eax + RT_VARS]
    mov [cg_vars], ecx
    mov eax, [pe_R]
    add eax, IMAGE_BASE + RC_SIZE
    mov [cg_pool], eax

    BYTES 0xBB, 1
    mov edx, ebx
    call x86_imm32
    BYTES 0xF56A, 2
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_GETSTDHANDLE
    OPA 0x15FF, 2, edx
    BYTES 0x044389, 3
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_WRITEFILE
    OPA 0xA1, 1, edx
    BYTES 0x084389, 3
    BYTES 0x1043C7, 3
    mov edx, [pe_R]
    add edx, IMAGE_BASE
    call x86_imm32

    mov esi, [g_stmts]
    mov eax, [g_nstmt]
    shl eax, 5
    add eax, esi
    mov [cg_end], eax
.stmt:
    cmp esi, [cg_end]
    jae .epilogue
    cmp word [esi + S_KIND], SK_OUT
    je .out

    mov eax, [esi + S_VAR]
    shl eax, 5
    add eax, [g_vars]
    mov eax, [eax + VR_OFF]
    add eax, [cg_vars]
    mov [cg_dst], eax
    movzx eax, word [esi + S_MODE]
    mov [cg_type], eax
    cmp dword [esi + S_NPARTS], 0
    je .store_default
    mov ebx, [esi + S_PARTS]
    shl ebx, 4
    add ebx, [g_parts]
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_VAR
    je .copy_var
    cmp eax, VK_NULL
    je .store_default
    cmp eax, VK_STR
    je .store_str
    cmp dword [cg_type], TY_BOOL
    je .store_bool
    OPA 0x05C7, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    call x86_imm32
    jmp .next
.store_bool:
    OPA 0x05C6, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    call x86_imm8
    jmp .next
.store_str:
    OPA 0x05C7, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
    mov edx, [cg_dst]
    add edx, 4
    OPA 0x05C766, 3, edx
    mov edx, [ebx + V_DATA_HI]
    call x86_imm16
    jmp .next

.store_default:
    cmp dword [cg_type], TY_INT
    jne .def_not_int
    OPA 0x05C7, 2, [cg_dst]
    xor edx, edx
    call x86_imm32
    jmp .next
.def_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .def_str
    OPA 0x05C6, 2, [cg_dst]
    xor edx, edx
    call x86_imm8
    jmp .next
.def_str:
    OPA 0x05C7, 2, [cg_dst]
    xor edx, edx
    call x86_imm32
    mov edx, [cg_dst]
    add edx, 4
    OPA 0x05C766, 3, edx
    xor edx, edx
    call x86_imm16
    jmp .next

.copy_var:
    mov eax, [ebx + V_DATA]
    shl eax, 5
    add eax, [g_vars]
    mov ebx, [eax + VR_OFF]
    add ebx, [cg_vars]
    cmp dword [cg_type], TY_INT
    jne .copy_not_int
    OPA 0xA1, 1, ebx
    OPA 0xA3, 1, [cg_dst]
    jmp .next
.copy_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .copy_str
    OPA 0xA0, 1, ebx
    OPA 0xA2, 1, [cg_dst]
    jmp .next
.copy_str:
    OPA 0xA1, 1, ebx
    OPA 0xA3, 1, [cg_dst]
    lea edx, [ebx + 4]
    OPA 0xA166, 2, edx
    mov edx, [cg_dst]
    add edx, 4
    OPA 0xA366, 2, edx
    jmp .next

.out:
    mov eax, [esi + S_PIECES]
    mov [cg_piece], eax
    add eax, [esi + S_NPIECES]
    mov [cg_plast], eax
.piece:
    mov eax, [cg_piece]
    cmp eax, [cg_plast]
    jae .next
    inc dword [cg_piece]
    shl eax, 4
    add eax, [g_pieces]
    mov ebx, eax
    mov eax, [ebx + P_KIND]
    cmp eax, PK_TEXT
    jne .piece_var
    cmp dword [ebx + P_B], 0
    je .piece
    BYTES 0xB9, 1
    mov edx, [ebx + P_A]
    add edx, [cg_pool]
    call x86_imm32
    BYTES 0xBA, 1
    mov edx, [ebx + P_B]
    call x86_imm32
    CALL_RT RT_FN_WRITE
    jmp .piece
.piece_var:
    mov edx, [ebx + P_A]
    add edx, [cg_vars]
    cmp eax, PK_INT
    jne .piece_not_int
    OPA 0x0D8B, 2, edx
    CALL_RT RT_FN_WRITE_INT
    jmp .piece
.piece_not_int:
    cmp eax, PK_BOOL
    jne .piece_str
    OPA 0x0DB60F, 3, edx
    CALL_RT RT_FN_WRITE_BOOL
    jmp .piece
.piece_str:
    BYTES 0xB9, 1
    call x86_imm32
    CALL_RT RT_FN_WRITE_STR
    jmp .piece

.next:
    add esi, S_SIZE
    jmp .stmt

.epilogue:
    CALL_RT RT_FN_FLUSH
    BYTES 0x006A, 2
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_EXITPROCESS
    OPA 0x15FF, 2, edx
    call x86_text_offset
    mov ecx, eax
    call pe_finish
    ENDF
