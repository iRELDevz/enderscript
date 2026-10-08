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
%define RT_FN_DIV_ZERO   20

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
cg_line   resd 1
cg_target resd 1
cg_depth  resd 1

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
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_GETSTDHANDLE
    OPA 0xA1, 1, edx
    BYTES 0x184389, 3
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_EXITPROCESS
    OPA 0xA1, 1, edx
    BYTES 0x1C4389, 3
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
    mov eax, [esi + S_TOK]
    shl eax, 4
    add eax, [g_tokens]
    mov eax, [eax + T_LINE]
    mov [cg_line], eax
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
    mov eax, [esi + S_PARTS]
    mov ebx, [g_roots]
    mov ebx, [ebx + eax * 4]
    mov [cg_target], ebx
    shl ebx, 4
    add ebx, [g_parts]
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_EXPR
    je .store_expr
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
.store_expr:
    mov eax, [esi + S_VAR]
    call try_update_in_place
    test eax, eax
    jnz .next
    mov ecx, [cg_target]
    call emit_expr
    OPA 0xA3, 1, [cg_dst]
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
    cmp eax, PK_EXPR
    jne .piece_plain
    mov ecx, [ebx + P_A]
    call emit_expr
    BYTES 0xC189, 2
    CALL_RT RT_FN_WRITE_INT
    jmp .piece
.piece_plain:
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

node_addr:
    mov eax, ecx
    shl eax, 4
    add eax, [g_parts]
    ret

var_abs:
    mov eax, [eax + V_DATA]
    shl eax, 5
    add eax, [g_vars]
    mov eax, [eax + VR_OFF]
    add eax, [cg_vars]
    ret

try_update_in_place:
    push esi
    push ebx
    mov ebx, eax
    mov ecx, [cg_target]
    call node_addr
    mov esi, eax
    movzx eax, byte [esi + V_NEG]
    push eax
    mov ecx, [esi + V_DATA]
    mov edx, [esi + V_DATA + 4]
    cmp eax, OP_SUB
    je .check
    cmp eax, OP_ADD
    jne .no
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .check
    xchg ecx, edx
.check:
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    cmp [eax + V_DATA], ebx
    jne .no
    mov ecx, edx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov esi, [eax + V_DATA]
    pop eax
    push eax
    cmp eax, OP_SUB
    jne .add
    neg esi
.add:
    cmp esi, 1
    je .inc
    cmp esi, -1
    je .dec
    OPA 0x0581, 2, [cg_dst]
    mov edx, esi
    call x86_imm32
    jmp .yes
.inc:
    OPA 0x05FF, 2, [cg_dst]
    jmp .yes
.dec:
    OPA 0x0DFF, 2, [cg_dst]
.yes:
    pop eax
    mov eax, 1
    pop ebx
    pop esi
    ret
.no:
    pop eax
    xor eax, eax
    pop ebx
    pop esi
    ret

temp_reg:
    mov eax, [cg_depth]
    movzx eax, byte [temp_codes + eax]
    ret

emit_expr:
    push esi
    push ebx
    call node_addr
    mov esi, eax
    movzx eax, byte [esi + V_KIND]
    cmp eax, VK_INT
    je .const
    cmp eax, VK_VAR
    je .var
    movzx ebx, byte [esi + V_NEG]
    cmp ebx, OP_NEG
    je .neg
    mov ecx, [esi + V_DATA + 4]
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .right_simple
    cmp ebx, OP_ADD
    je .try_left
    cmp ebx, OP_MUL
    jne .general
.try_left:
    mov ecx, [esi + V_DATA]
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .left_simple
.general:
    mov ecx, [esi + V_DATA]
    call emit_expr
    cmp dword [cg_depth], 3
    jae .spill
    call temp_reg
    push eax
    inc dword [cg_depth]
    shl eax, 8
    or eax, 0xC089
    mov ecx, 2
    call x86_bytes
    mov ecx, [esi + V_DATA + 4]
    call emit_expr
    dec dword [cg_depth]
    pop eax
    cmp ebx, OP_ADD
    je .reg_add
    cmp ebx, OP_MUL
    je .reg_mul
    cmp ebx, OP_SUB
    je .reg_sub
    push eax
    BYTES 0xC189, 2
    pop eax
    shl eax, 11
    or eax, 0xC089
    mov ecx, 2
    call x86_bytes
    call apply_reg
    jmp .done
.reg_add:
    shl eax, 11
    or eax, 0xC001
    mov ecx, 2
    call x86_bytes
    jmp .done
.reg_mul:
    shl eax, 16
    or eax, 0xC0AF0F
    mov ecx, 3
    call x86_bytes
    jmp .done
.reg_sub:
    push eax
    shl eax, 8
    or eax, 0xC029
    mov ecx, 2
    call x86_bytes
    pop eax
    shl eax, 11
    or eax, 0xC089
    mov ecx, 2
    call x86_bytes
    jmp .done
.spill:
    BYTES 0x50, 1
    mov ecx, [esi + V_DATA + 4]
    call emit_expr
    BYTES 0xC189, 2
    BYTES 0x58, 1
    call apply_reg
    jmp .done
.right_simple:
    mov ecx, [esi + V_DATA]
    call emit_expr
    mov ecx, [esi + V_DATA + 4]
    call apply_simple
    jmp .done
.left_simple:
    mov ecx, [esi + V_DATA + 4]
    call emit_expr
    mov ecx, [esi + V_DATA]
    call apply_simple
    jmp .done
.neg:
    mov ecx, [esi + V_DATA]
    call emit_expr
    BYTES 0xD8F7, 2
    jmp .done
.const:
    cmp dword [esi + V_DATA], 0
    jne .const_mov
    BYTES 0xC031, 2
    jmp .done
.const_mov:
    BYTES 0xB8, 1
    mov edx, [esi + V_DATA]
    call x86_imm32
    jmp .done
.var:
    mov eax, esi
    call var_abs
    mov edx, eax
    OPA 0xA1, 1, edx
.done:
    pop ebx
    pop esi
    ret

apply_simple:
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    je .var
    mov esi, [eax + V_DATA]
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
    cmp esi, 1
    je .inc
    cmp esi, -1
    je .dec
    BYTES 0x05, 1
    mov edx, esi
    jmp x86_imm32
.sub_imm:
    cmp esi, 1
    je .dec
    cmp esi, -1
    je .inc
    BYTES 0x2D, 1
    mov edx, esi
    jmp x86_imm32
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
    push eax
    BYTES 0xE0C1, 2
    pop edx
    jmp x86_imm8
.mul_plain:
    BYTES 0xC069, 2
    mov edx, esi
    jmp x86_imm32
.div_imm:
    call pow2_shift
    test eax, eax
    jz .div_plain
    push eax
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [esi - 1]
    call x86_imm32
    BYTES 0xD001, 2
    BYTES 0xF8C1, 2
    pop edx
    jmp x86_imm8
.div_plain:
    BYTES 0xB9, 1
    mov edx, esi
    call x86_imm32
    BYTES 0xF9F799, 3
    ret
.mod_imm:
    call pow2_shift
    test eax, eax
    jz .mod_plain
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [esi - 1]
    call x86_imm32
    BYTES 0x100C8D, 3
    BYTES 0xE181, 2
    mov edx, esi
    neg edx
    call x86_imm32
    BYTES 0xC829, 2
    ret
.mod_plain:
    BYTES 0xB9, 1
    mov edx, esi
    call x86_imm32
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    ret
.var:
    call var_abs
    mov esi, eax
    cmp ebx, OP_ADD
    je .add_mem
    cmp ebx, OP_SUB
    je .sub_mem
    cmp ebx, OP_MUL
    je .mul_mem
    OPA 0x0D8B, 2, esi
    jmp checked_div
.add_mem:
    OPA 0x0503, 2, esi
    ret
.sub_mem:
    OPA 0x052B, 2, esi
    ret
.mul_mem:
    OPA 0x05AF0F, 3, esi
    ret

pow2_shift:
    xor eax, eax
    cmp esi, 2
    jl .r
    lea edx, [esi - 1]
    test edx, esi
    jnz .r
    bsf eax, esi
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
    call x86_imm32
    mov ecx, [rt_offsets + RT_FN_DIV_ZERO]
    call x86_call_rel
    BYTES 0x75FFF983, 4
    BYTES 0x04, 1
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

section .rdata
temp_codes db 6, 7, 5
section .text

