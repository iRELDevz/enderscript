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
%define RT_FN_STR_EQ     24

%define IAT_GETSTDHANDLE 56
%define IAT_WRITEFILE    60
%define IAT_EXITPROCESS  64

%define R_EAX 0
%define R_ECX 1
%define R_EDX 2
%define R_ESI 6
%define R_EDI 7
%define NOREG 0xFF

%define B_END    0
%define B_KIND   4
%define B_TOP    8
%define B_REG    12
%define B_SLOT   16
%define B_DYN    20
%define B_LIMIT  24
%define B_INIT   28
%define B_ALIAS  32
%define B_IFIDX  36
%define B_SIZE   64

section .bss
alignb 4
cg_end    resd 1
cg_cur    resd 1
cg_vars   resd 1
cg_pool   resd 1
cg_dst    resd 1
cg_type   resd 1
cg_piece  resd 1
cg_plast  resd 1
cg_line   resd 1
cg_target resd 1
cg_depth  resd 1
cg_ldepth resd 1
cg_bdepth resd 1
cg_patch  resd 1
cg_npatch resd 1
cg_lp     resd 1
cg_lpl    resd 1
cg_nlp    resd 1
cg_label  resd 1
cg_vreg   resd 1
cg_blfirst resd 1
cg_blacc  resd 1
cg_blk    resd 1
cg_blvar  resd 1
cg_bldata resd 1
cg_bland  resd 1
cg_tmp    resd 4
mg_tmp    resd 4
mg_m      resd 1
mg_s      resd 1
cg_bstack resb B_SIZE * (MAX_NEST + 1)

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
    push edi
    mov ecx, [g_nparts]
    add ecx, 16
    shl ecx, 2
    call mem_alloc
    mov [cg_patch], eax
    mov ecx, [g_nparts]
    add ecx, 16
    shl ecx, 3
    call mem_alloc
    mov [cg_lp], eax
    mov ecx, [g_nparts]
    add ecx, 16
    lea eax, [eax + ecx * 4]
    mov [cg_lpl], eax
    mov ecx, [g_nvars]
    add ecx, 16
    call mem_alloc
    mov [cg_vreg], eax
    pop edi
    mov dword [cg_npatch], 0
    mov dword [cg_nlp], 0
    mov dword [cg_label], 1
    mov dword [cg_bdepth], 0
    mov dword [cg_ldepth], 0
    mov dword [cg_depth], 0
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
    mov [cg_cur], esi
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    call close_blocks
    mov esi, [cg_cur]
    cmp esi, [cg_end]
    jae .epilogue
    mov eax, [esi + S_TOK]
    shl eax, 4
    add eax, [g_tokens]
    mov eax, [eax + T_LINE]
    mov [cg_line], eax
    movzx eax, word [esi + S_KIND]
    cmp eax, SK_OUT
    je .out
    cmp eax, SK_IF
    je .if
    cmp eax, SK_FOR
    je .loop
    cmp eax, SK_LOOPS
    je .loop
    cmp eax, SK_ELSE
    je .next
    call emit_store
    jmp .next
.out:
    call emit_out_body
    jmp .next
.if:
    call try_branchless
    test eax, eax
    jz .if_branch
    add dword [cg_cur], S_SIZE
    jmp .next
.if_branch:
    mov eax, [cg_bdepth]
    imul eax, eax, B_SIZE
    lea ecx, [cg_bstack + eax]
    mov edx, [esi + S_PIECES]
    mov [ecx + B_END], edx
    mov dword [ecx + B_KIND], BK_IF
    mov edx, [cg_npatch]
    mov [ecx + B_TOP], edx
    mov edx, esi
    sub edx, [g_stmts]
    shr edx, 5
    mov [ecx + B_IFIDX], edx
    inc dword [cg_bdepth]
    mov eax, [esi + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    xor edx, edx
    xor eax, eax
    call emit_cond
    jmp .next
.loop:
    call emit_loop_head
.next:
    mov esi, [cg_cur]
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

var_abs_idx:
    shl eax, 5
    add eax, [g_vars]
    mov eax, [eax + VR_OFF]
    add eax, [cg_vars]
    ret

var_abs:
    mov eax, [eax + V_DATA]
    jmp var_abs_idx

var_reg:
    mov eax, [cg_vreg]
    movzx eax, byte [eax + ecx]
    and eax, 0x1F
    dec eax
    ret

stmt_ptr:
    mov eax, ecx
    shl eax, 5
    add eax, [g_stmts]
    ret

stmt_root:
    mov eax, [eax + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    ret

e_rr:
    push edx
    push ecx
    call .op
    pop ecx
    pop edx
    shl ecx, 3
    or ecx, edx
    or ecx, 0xC0
    mov [edi], cl
    inc edi
    ret
.op:
    mov [edi], al
    inc edi
    ret

e_rr2:
    mov [edi], ax
    add edi, 2
    shl ecx, 3
    or ecx, edx
    or ecx, 0xC0
    mov [edi], cl
    inc edi
    ret

e_mr:
    mov [edi], al
    inc edi
    shl ecx, 3
    or ecx, 5
    mov [edi], cl
    mov [edi + 1], edx
    add edi, 5
    ret

temp_limit:
    mov eax, [cg_ldepth]
    cmp eax, 2
    jbe .ok
    mov eax, 2
.ok:
    neg eax
    add eax, 3
    ret

temp_reg:
    mov eax, [cg_depth]
    movzx eax, byte [temp_codes + eax]
    ret

emit_store:
    push esi
    push ebx
    mov esi, [cg_cur]
    mov eax, [esi + S_VAR]
    call var_abs_idx
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
    jmp .done
.store_expr:
    mov eax, [esi + S_VAR]
    call try_update_in_place
    test eax, eax
    jnz .done
    mov ecx, [cg_target]
    call emit_expr
    OPA 0xA3, 1, [cg_dst]
    jmp .done
.store_bool:
    OPA 0x05C6, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    call x86_imm8
    jmp .done
.store_str:
    OPA 0x05C7, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
    mov edx, [cg_dst]
    add edx, 8
    OPA 0x05C766, 3, edx
    mov edx, [ebx + V_DATA_HI]
    call x86_imm16
    jmp .done
.store_default:
    cmp dword [cg_type], TY_INT
    jne .def_not_int
    OPA 0x05C7, 2, [cg_dst]
    xor edx, edx
    call x86_imm32
    jmp .done
.def_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .def_str
    OPA 0x05C6, 2, [cg_dst]
    xor edx, edx
    call x86_imm8
    jmp .done
.def_str:
    OPA 0x05C7, 2, [cg_dst]
    xor edx, edx
    call x86_imm32
    mov edx, [cg_dst]
    add edx, 8
    OPA 0x05C766, 3, edx
    xor edx, edx
    call x86_imm16
    jmp .done
.copy_var:
    mov ecx, [ebx + V_DATA]
    mov eax, ecx
    call var_abs_idx
    mov ebx, eax
    cmp dword [cg_type], TY_INT
    jne .copy_not_int
    call var_reg
    test eax, eax
    js .copy_mem
    mov ecx, eax
    mov eax, 0x89
    xor edx, edx
    call e_rr
    jmp .copy_store
.copy_mem:
    OPA 0xA1, 1, ebx
.copy_store:
    OPA 0xA3, 1, [cg_dst]
    jmp .done
.copy_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .copy_str
    OPA 0xA0, 1, ebx
    OPA 0xA2, 1, [cg_dst]
    jmp .done
.copy_str:
    OPA 0xA1, 1, ebx
    OPA 0xA3, 1, [cg_dst]
    lea edx, [ebx + 8]
    OPA 0xA166, 2, edx
    mov edx, [cg_dst]
    add edx, 8
    OPA 0xA366, 2, edx
.done:
    pop ebx
    pop esi
    ret

emit_out_body:
    push esi
    push ebx
    mov esi, [cg_cur]
    mov eax, [esi + S_PIECES]
    mov [cg_piece], eax
    add eax, [esi + S_NPIECES]
    mov [cg_plast], eax
.piece:
    mov eax, [cg_piece]
    cmp eax, [cg_plast]
    jae .done
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
.done:
    pop ebx
    pop esi
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
    call temp_limit
    cmp [cg_depth], eax
    jae .spill
    call temp_reg
    push eax
    inc dword [cg_depth]
    mov ecx, R_EAX
    mov edx, eax
    mov eax, 0x89
    call e_rr
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
    pop ecx
    mov edx, R_EAX
    mov eax, 0x89
    call e_rr
    call apply_reg
    jmp .done
.reg_add:
    mov ecx, eax
    mov edx, R_EAX
    mov eax, 0x01
    call e_rr
    jmp .done
.reg_mul:
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0xAF0F
    call e_rr2
    jmp .done
.reg_sub:
    push eax
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0x29
    call e_rr
    pop ecx
    mov edx, R_EAX
    mov eax, 0x89
    call e_rr
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
    mov ecx, [esi + V_DATA]
    call var_reg
    test eax, eax
    js .var_mem
    mov ecx, eax
    xor edx, edx
    mov eax, 0x89
    call e_rr
    jmp .done
.var_mem:
    mov eax, esi
    call var_abs
    mov edx, eax
    OPA 0xA1, 1, edx
.done:
    pop ebx
    pop esi
    ret

apply_simple:
    push esi
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
    call x86_imm32
    jmp .ret
.sub_imm:
    cmp esi, 1
    je .dec
    cmp esi, -1
    je .inc
    BYTES 0x2D, 1
    mov edx, esi
    call x86_imm32
    jmp .ret
.inc:
    BYTES 0x40, 1
    jmp .ret
.dec:
    BYTES 0x48, 1
    jmp .ret
.mul_imm:
    call pow2_shift
    test eax, eax
    jz .mul_lea
    push eax
    BYTES 0xE0C1, 2
    pop edx
    call x86_imm8
    jmp .ret
.mul_lea:
    cmp esi, 3
    je .lea2
    cmp esi, 5
    je .lea4
    cmp esi, 9
    je .lea8
    BYTES 0xC069, 2
    mov edx, esi
    call x86_imm32
    jmp .ret
.lea2:
    BYTES 0x40048D, 3
    jmp .ret
.lea4:
    BYTES 0x80048D, 3
    jmp .ret
.lea8:
    BYTES 0xC0048D, 3
    jmp .ret
.div_imm:
    cmp esi, 1
    je .ret
    cmp esi, -1
    jne .div_any
    BYTES 0xD8F7, 2
    jmp .ret
.div_any:
    xor eax, eax
    test esi, esi
    jns .div_sign
    cmp esi, 0x80000000
    je .div_sign
    mov ecx, esi
    neg ecx
    lea edx, [ecx - 1]
    test edx, ecx
    jnz .div_sign
    neg esi
    mov eax, 1
.div_sign:
    push eax
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
    call x86_imm8
    pop eax
    test eax, eax
    jz .ret
    BYTES 0xD8F7, 2
    jmp .ret
.div_plain:
    pop eax
    test eax, eax
    jz .div_magic
    neg esi
.div_magic:
    call magic_quot
    test eax, eax
    jz .div_idiv
    BYTES 0xD089, 2
    jmp .ret
.div_idiv:
    BYTES 0xB9, 1
    mov edx, esi
    call x86_imm32
    BYTES 0xF9F799, 3
    jmp .ret
.mod_imm:
    lea eax, [esi + 1]
    cmp eax, 2
    ja .mod_any
    BYTES 0xC031, 2
    jmp .ret
.mod_any:
    test esi, esi
    jns .mod_pos
    cmp esi, 0x80000000
    je .mod_pos
    mov ecx, esi
    neg ecx
    lea edx, [ecx - 1]
    test edx, ecx
    jnz .mod_pos
    neg esi
.mod_pos:
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
    jmp .ret
.mod_plain:
    call magic_quot
    test eax, eax
    jz .mod_idiv
    BYTES 0xD269, 2
    mov edx, esi
    call x86_imm32
    BYTES 0xC889, 2
    BYTES 0xD029, 2
    jmp .ret
.mod_idiv:
    BYTES 0xB9, 1
    mov edx, esi
    call x86_imm32
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    jmp .ret
.var:
    mov ecx, [eax + V_DATA]
    push eax
    call var_reg
    mov ecx, eax
    pop eax
    test ecx, ecx
    js .var_mem
    mov edx, R_EAX
    mov eax, 0x01
    cmp ebx, OP_ADD
    je .var_rr
    mov eax, 0x29
    cmp ebx, OP_SUB
    je .var_rr
    cmp ebx, OP_MUL
    je .var_mul
    mov edx, R_ECX
    mov eax, 0x89
    call e_rr
    pop esi
    jmp checked_div
.var_rr:
    call e_rr
    jmp .ret
.var_mul:
    mov edx, ecx
    mov ecx, R_EAX
    mov eax, 0xAF0F
    call e_rr2
    jmp .ret
.var_mem:
    call var_abs
    mov esi, eax
    cmp ebx, OP_ADD
    je .add_mem
    cmp ebx, OP_SUB
    je .sub_mem
    cmp ebx, OP_MUL
    je .mul_mem
    OPA 0x0D8B, 2, esi
    pop esi
    jmp checked_div
.add_mem:
    OPA 0x0503, 2, esi
    jmp .ret
.sub_mem:
    OPA 0x052B, 2, esi
    jmp .ret
.mul_mem:
    OPA 0x05AF0F, 3, esi
.ret:
    pop esi
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

magic_of:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, esi
    cmp eax, 0x80000000
    je .fail
    mov ecx, eax
    neg ecx
    cmovs ecx, eax
    cmp ecx, 2
    jb .fail
    mov [mg_tmp], ecx
    mov [mg_tmp + 4], eax
    shr eax, 31
    add eax, 0x80000000
    xor edx, edx
    div ecx
    mov eax, [mg_tmp + 4]
    shr eax, 31
    add eax, 0x80000000
    sub eax, edx
    dec eax
    mov ebp, eax
    mov ebx, 31
    mov eax, 0x80000000
    xor edx, edx
    div ebp
    mov esi, eax
    imul eax, ebp
    mov edi, 0x80000000
    sub edi, eax
    mov eax, 0x80000000
    xor edx, edx
    div dword [mg_tmp]
    mov [mg_tmp + 8], eax
    imul eax, [mg_tmp]
    mov edx, 0x80000000
    sub edx, eax
    mov [mg_tmp + 12], edx
.loop:
    inc ebx
    add esi, esi
    add edi, edi
    cmp edi, ebp
    jb .r1
    inc esi
    sub edi, ebp
.r1:
    mov eax, [mg_tmp + 8]
    add eax, eax
    mov [mg_tmp + 8], eax
    mov edx, [mg_tmp + 12]
    add edx, edx
    cmp edx, [mg_tmp]
    jb .r2
    inc dword [mg_tmp + 8]
    sub edx, [mg_tmp]
.r2:
    mov [mg_tmp + 12], edx
    mov ecx, [mg_tmp]
    sub ecx, edx
    cmp esi, ecx
    jb .loop
    jne .done
    test edi, edi
    jz .loop
.done:
    mov eax, [mg_tmp + 8]
    inc eax
    cmp dword [mg_tmp + 4], 0
    jns .pos
    neg eax
.pos:
    mov [mg_m], eax
    lea eax, [ebx - 32]
    mov [mg_s], eax
    mov eax, 1
    jmp .out
.fail:
    xor eax, eax
.out:
    pop ebp
    pop edi
    pop esi
    pop ebx
    ret

magic_quot:
    xor eax, eax
    cmp dword [cg_ldepth], 0
    je .r
    call magic_of
    test eax, eax
    jz .r
    BYTES 0xC189, 2
    BYTES 0xB8, 1
    mov edx, [mg_m]
    call x86_imm32
    BYTES 0xE9F7, 2
    cmp esi, 0
    jle .neg_d
    cmp dword [mg_m], 0
    jge .shift
    BYTES 0xCA01, 2
    jmp .shift
.neg_d:
    cmp dword [mg_m], 0
    jle .shift
    BYTES 0xCA29, 2
.shift:
    cmp dword [mg_s], 0
    je .sign
    BYTES 0xFAC1, 2
    mov edx, [mg_s]
    call x86_imm8
.sign:
    BYTES 0xD089, 2
    BYTES 0x1FE8C1, 3
    BYTES 0xC201, 2
    mov eax, 1
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

record_patch:
    push eax
    call x86_text_offset
    mov ecx, [cg_npatch]
    mov edx, [cg_patch]
    mov [edx + ecx * 4], eax
    inc dword [cg_npatch]
    mov dword [edi], 0
    add edi, 4
    pop eax
    ret

patch_range:
    push esi
    push ebx
    mov esi, ecx
    mov ebx, edx
    call x86_text_offset
.loop:
    cmp esi, ebx
    jae .done
    mov ecx, [cg_patch]
    mov ecx, [ecx + esi * 4]
    mov edx, eax
    sub edx, ecx
    sub edx, 4
    add ecx, [x86_text_base]
    mov [ecx], edx
    inc esi
    jmp .loop
.done:
    pop ebx
    pop esi
    ret

jump_to_label:
    test ecx, ecx
    jz record_patch
    push ecx
    call x86_text_offset
    pop ecx
    mov edx, [cg_nlp]
    push ebx
    mov ebx, [cg_lp]
    mov [ebx + edx * 4], eax
    mov ebx, [cg_lpl]
    mov [ebx + edx * 4], ecx
    pop ebx
    inc dword [cg_nlp]
    mov dword [edi], 0
    add edi, 4
    ret

place_label:
    push esi
    push ebx
    push ebp
    mov ebp, ecx
    call x86_text_offset
    mov [cg_tmp], eax
    xor esi, esi
    xor ebx, ebx
.l:
    cmp esi, [cg_nlp]
    jae .done
    mov eax, [cg_lpl]
    mov ecx, [eax + esi * 4]
    mov eax, [cg_lp]
    mov edx, [eax + esi * 4]
    cmp ecx, ebp
    jne .keep
    mov eax, [cg_tmp]
    sub eax, edx
    sub eax, 4
    add edx, [x86_text_base]
    mov [edx], eax
    jmp .n
.keep:
    mov eax, [cg_lp]
    mov [eax + ebx * 4], edx
    mov eax, [cg_lpl]
    mov [eax + ebx * 4], ecx
    inc ebx
.n:
    inc esi
    jmp .l
.done:
    mov [cg_nlp], ebx
    pop ebp
    pop ebx
    pop esi
    ret

emit_cond:
    push esi
    push ebx
    push ebp
    mov ebx, edx
    mov ebp, eax
    call node_addr
    mov esi, eax
    movzx eax, byte [esi + V_KIND]
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
    mov ecx, 2
    call x86_bytes
    jmp .record
.const:
    xor eax, eax
    cmp dword [esi + V_DATA], 0
    setne al
    cmp eax, ebx
    jne .done
    BYTES 0xE9, 1
.record:
    mov ecx, ebp
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
    mov ecx, [esi + V_DATA]
    mov edx, ebx
    mov eax, ebp
    call emit_cond
    mov ecx, [esi + V_DATA + 4]
    mov edx, ebx
    mov eax, ebp
    call emit_cond
    jmp .done
.split:
    mov edx, eax
    mov eax, [cg_label]
    inc dword [cg_label]
    push eax
    mov ecx, [esi + V_DATA]
    call emit_cond
    mov ecx, [esi + V_DATA + 4]
    mov edx, ebx
    mov eax, ebp
    call emit_cond
    pop ecx
    call place_label
.done:
    pop ebp
    pop ebx
    pop esi
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
    push ebx
    push ebp
    push dword [cg_tmp + 8]
    movzx eax, byte [esi + V_NEG]
    mov [cg_tmp + 8], eax
    mov ebx, [esi + V_DATA]
    mov ebp, [esi + V_DATA + 4]
    movzx eax, byte [esi + V_TYPE]
    cmp eax, TY_STR
    je .str
    cmp eax, TY_BOOL
    je .bool
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .order_ok
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    je .order_ok
    xchg ebx, ebp
    mov eax, [cg_tmp + 8]
    mov ecx, CMP_GT
    cmp eax, CMP_LT
    je .mirror
    mov ecx, CMP_LT
    cmp eax, CMP_GT
    je .mirror
    mov ecx, CMP_GE
    cmp eax, CMP_LE
    je .mirror
    mov ecx, CMP_LE
    cmp eax, CMP_GE
    jne .order_ok
.mirror:
    mov [cg_tmp + 8], ecx
.order_ok:
    call try_divisible
    test eax, eax
    jnz .ret
    mov ecx, ebx
    call emit_expr
    mov ecx, ebp
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_INT
    je .int_imm
    cmp edx, VK_VAR
    je .int_var
    call temp_limit
    cmp [cg_depth], eax
    jae .int_spill
    call temp_reg
    push eax
    inc dword [cg_depth]
    mov ecx, R_EAX
    mov edx, eax
    mov eax, 0x89
    call e_rr
    mov ecx, ebp
    call emit_expr
    dec dword [cg_depth]
    pop edx
    mov ecx, R_EAX
    mov eax, 0x39
    call e_rr
    jmp .int_cc
.int_spill:
    BYTES 0x50, 1
    mov ecx, ebp
    call emit_expr
    BYTES 0x58C189, 3
    BYTES 0xC839, 2
    jmp .int_cc
.int_imm:
    mov edx, [eax + V_DATA]
    test edx, edx
    jnz .imm_cmp
    BYTES 0xC085, 2
    jmp .int_cc
.imm_cmp:
    push edx
    BYTES 0x3D, 1
    pop edx
    call x86_imm32
    jmp .int_cc
.int_var:
    push eax
    mov ecx, [eax + V_DATA]
    call var_reg
    mov ecx, eax
    pop eax
    test ecx, ecx
    js .int_mem
    xor edx, edx
    mov eax, 0x39
    call e_rr
    jmp .int_cc
.int_mem:
    call var_abs
    mov edx, eax
    OPA 0x053B, 2, edx
.int_cc:
    mov ecx, [cg_tmp + 8]
    call cc_of_op
    jmp .ret
.bool:
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    je .bool_left_var
    mov edx, [eax + V_DATA]
    push edx
    BYTES 0xB8, 1
    pop edx
    call x86_imm32
    jmp .bool_right
.bool_left_var:
    call var_abs
    mov edx, eax
    OPA 0x05B60F, 3, edx
.bool_right:
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    je .bool_right_var
    mov edx, [eax + V_DATA]
    push edx
    BYTES 0x3D, 1
    pop edx
    call x86_imm32
    jmp .bool_cc
.bool_right_var:
    call var_abs
    mov edx, eax
    OPA 0x0DB60F, 3, edx
    BYTES 0xC839, 2
.bool_cc:
    mov ecx, [cg_tmp + 8]
    call cc_of_op
    jmp .ret
.str:
    mov ecx, ebp
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_VAR
    je .b_var
    cmp edx, VK_STR
    je .b_lit
    BYTES 0xC031006A, 4
    jmp .a
.b_var:
    call var_abs
    push eax
    lea edx, [eax + 8]
    OPA 0x05B70F, 3, edx
    BYTES 0x50, 1
    pop edx
    OPA 0xA1, 1, edx
    jmp .a
.b_lit:
    push eax
    BYTES 0x68, 1
    mov eax, [esp]
    mov edx, [eax + V_DATA_HI]
    call x86_imm32
    BYTES 0xB8, 1
    pop eax
    mov edx, [eax + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
.a:
    mov ecx, ebx
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_VAR
    je .a_var
    cmp edx, VK_STR
    je .a_lit
    BYTES 0xD231C931, 4
    jmp .call
.a_var:
    call var_abs
    push eax
    mov edx, eax
    OPA 0x0D8B, 2, edx
    pop edx
    add edx, 8
    OPA 0x15B70F, 3, edx
    jmp .call
.a_lit:
    push eax
    BYTES 0xB9, 1
    mov eax, [esp]
    mov edx, [eax + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
    BYTES 0xBA, 1
    pop eax
    mov edx, [eax + V_DATA_HI]
    call x86_imm32
.call:
    CALL_RT RT_FN_STR_EQ
    BYTES 0xC085, 2
    mov eax, 5
    cmp dword [cg_tmp + 8], CMP_IS
    je .ret
    mov eax, 4
.ret:
    pop dword [cg_tmp + 8]
    pop ebp
    pop ebx
    ret

try_divisible:
    xor eax, eax
    cmp dword [cg_ldepth], 0
    je .r
    cmp dword [cg_tmp + 8], CMP_LT
    jae .no
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_MOD
    jne .no
    push eax
    mov ecx, [eax + V_DATA + 4]
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov edx, [eax + V_DATA]
    cmp edx, 0x80000000
    je .no
    mov eax, edx
    neg eax
    cmovs eax, edx
    cmp eax, 2
    jb .no
    push esi
    mov esi, eax
    push ecx
    mov ecx, [ecx + V_DATA]
    push ecx
    call node_addr
    pop ecx
    lea edx, [esi - 1]
    test edx, esi
    jz .gen
    cmp byte [eax + V_KIND], VK_VAR
    jne .gen
    push ecx
    mov ecx, [eax + V_DATA]
    mov eax, [cg_vreg]
    movzx eax, byte [eax + ecx]
    pop ecx
    test eax, 0x40
    jz .gen
    and eax, 0x1F
    dec eax
    mov ecx, eax
    mov edx, R_ECX
    mov eax, 0x89
    call e_rr
    pop ecx
    jmp .gm_mul
.gen:
    call emit_expr
    pop ecx
    lea edx, [esi - 1]
    test edx, esi
    jnz .gm_abs
    cmp edx, 0xFF
    ja .test32
    BYTES 0xA8, 1
    call x86_imm8
    jmp .zf
.test32:
    BYTES 0xA9, 1
    call x86_imm32
.zf:
    pop esi
    mov ecx, [cg_tmp + 8]
    call cc_of_op
    ret
.gm_abs:
    BYTES 0xD9F7C189, 4
    BYTES 0xC8480F, 3
.gm_mul:
    mov ecx, esi
    bsf ecx, esi
    mov edx, esi
    shr edx, cl
    mov [cg_tmp], ecx
    mov eax, edx
    mov ecx, 4
.newton:
    push ecx
    mov ecx, edx
    imul ecx, eax
    neg ecx
    add ecx, 2
    imul eax, ecx
    pop ecx
    dec ecx
    jnz .newton
    push eax
    BYTES 0xC969, 2
    pop edx
    call x86_imm32
    cmp dword [cg_tmp], 0
    je .no_ror
    BYTES 0xC9C1, 2
    mov edx, [cg_tmp]
    call x86_imm8
.no_ror:
    BYTES 0xF981, 2
    mov eax, 0xFFFFFFFF
    xor edx, edx
    div esi
    mov edx, eax
    call x86_imm32
    pop esi
    mov eax, 6
    cmp dword [cg_tmp + 8], CMP_IS
    je .r
    mov eax, 7
.r:
    ret
.no:
    xor eax, eax
    ret

close_blocks:
    push esi
    push ebx
    mov ebx, eax
.loop:
    mov eax, [cg_bdepth]
    test eax, eax
    jz .done
    dec eax
    imul eax, eax, B_SIZE
    lea esi, [cg_bstack + eax]
    cmp [esi + B_END], ebx
    jne .done
    cmp dword [esi + B_KIND], BK_IF
    jne .close_loop
    call else_of
    test eax, eax
    jz .plain_if
    push eax
    BYTES 0xE9, 1
    call x86_text_offset
    push eax
    mov dword [edi], 0
    add edi, 4
    mov ecx, [esi + B_TOP]
    mov edx, [cg_npatch]
    call patch_range
    pop eax
    mov ecx, [esi + B_TOP]
    mov edx, [cg_patch]
    mov [edx + ecx * 4], eax
    inc ecx
    mov [cg_npatch], ecx
    pop eax
    mov edx, [eax + S_PIECES]
    mov [esi + B_END], edx
    mov dword [esi + B_IFIDX], -1
    jmp .loop
.plain_if:
    mov ecx, [esi + B_TOP]
    mov edx, [cg_npatch]
    call patch_range
    mov ecx, [esi + B_TOP]
    mov [cg_npatch], ecx
    dec dword [cg_bdepth]
    jmp .loop
.close_loop:
    call emit_loop_tail
    dec dword [cg_bdepth]
    dec dword [cg_ldepth]
    jmp .loop
.done:
    pop ebx
    pop esi
    ret

else_of:
    xor eax, eax
    mov ecx, ebx
    mov edx, [g_nstmt]
    cmp ecx, edx
    jae .r
    call stmt_ptr
    cmp word [eax + S_KIND], SK_ELSE
    jne .no
    mov ecx, [eax + S_VAR]
    cmp ecx, [esi + B_IFIDX]
    jne .no
    ret
.no:
    xor eax, eax
.r:
    ret

for_aliasable:
    push esi
    push ebx
    mov ebx, ecx
    mov esi, [cg_cur]
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    lea ecx, [eax + 1]
    mov edx, [esi + S_PIECES]
.l:
    cmp ecx, edx
    jae .yes
    push ecx
    call stmt_ptr
    pop ecx
    inc ecx
    movzx esi, word [eax + S_KIND]
    cmp esi, SK_DECL
    je .chk
    cmp esi, SK_ASSIGN
    je .chk
    cmp esi, SK_FOR
    jne .l
.chk:
    cmp [eax + S_VAR], ebx
    jne .l
    xor eax, eax
    jmp .r
.yes:
    mov eax, 1
.r:
    pop ebx
    pop esi
    ret

emit_reg1:
    add eax, ecx
    mov [edi], al
    inc edi
    ret

emit_loop_head:
    push esi
    push ebx
    mov ebx, [cg_cur]
    mov eax, [cg_bdepth]
    imul eax, eax, B_SIZE
    lea esi, [cg_bstack + eax]
    inc dword [cg_bdepth]
    mov edx, [ebx + S_PIECES]
    mov [esi + B_END], edx
    mov dword [esi + B_INIT], -1
    mov dword [esi + B_ALIAS], -1
    mov dword [esi + B_KIND], BK_LOOPS
    cmp word [ebx + S_KIND], SK_FOR
    jne .kind_set
    mov dword [esi + B_KIND], BK_FOR
.kind_set:
    mov eax, [cg_ldepth]
    inc dword [cg_ldepth]
    mov ecx, NOREG
    cmp eax, 2
    jae .reg_set
    movzx ecx, byte [loop_regs + eax]
.reg_set:
    mov [esi + B_REG], ecx
    mov eax, [ebx + S_NPIECES]
    add eax, [cg_vars]
    mov [esi + B_LIMIT], eax
    add eax, 4
    mov [esi + B_SLOT], eax
    mov eax, [ebx + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    push ecx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .dynamic
    mov dword [esi + B_DYN], 0
    mov edx, [eax + V_DATA]
    mov [esi + B_LIMIT], edx
    jmp .count_ready
.dynamic:
    mov dword [esi + B_DYN], 1
    call emit_expr
.count_ready:
    cmp dword [esi + B_KIND], BK_FOR
    je .for_head
    cmp dword [esi + B_DYN], 0
    jne .loops_dyn
    cmp dword [esi + B_REG], NOREG
    je .loops_const_mem
    mov eax, 0xB8
    mov ecx, [esi + B_REG]
    call emit_reg1
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .loops_test
.loops_const_mem:
    OPA 0x05C7, 2, [esi + B_SLOT]
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .loops_test
.loops_dyn:
    cmp dword [esi + B_REG], NOREG
    je .loops_dyn_mem
    mov ecx, R_EAX
    mov edx, [esi + B_REG]
    mov eax, 0x89
    call e_rr
    jmp .loops_test
.loops_dyn_mem:
    OPA 0xA3, 1, [esi + B_SLOT]
.loops_test:
    cmp dword [esi + B_DYN], 0
    jne .loops_need_test
    cmp dword [esi + B_LIMIT], 0
    jg .loops_top
.loops_need_test:
    cmp dword [esi + B_REG], NOREG
    je .loops_test_mem
    mov ecx, [esi + B_REG]
    mov edx, ecx
    mov eax, 0x85
    call e_rr
    jmp .loops_jle
.loops_test_mem:
    OPA 0x3D83, 2, [esi + B_SLOT]
    xor edx, edx
    call x86_imm8
.loops_jle:
    BYTES 0x8E0F, 2
    call x86_text_offset
    mov [esi + B_INIT], eax
    mov dword [edi], 0
    add edi, 4
.loops_top:
    call x86_text_offset
    mov [esi + B_TOP], eax
    jmp .done

.for_head:
    cmp dword [esi + B_DYN], 0
    je .for_init
    OPA 0xA3, 1, [esi + B_LIMIT]
.for_init:
    cmp dword [esi + B_REG], NOREG
    je .for_init_mem
    mov ecx, [esi + B_REG]
    mov edx, ecx
    mov eax, 0x31
    call e_rr
    jmp .for_jump
.for_init_mem:
    OPA 0x05C7, 2, [esi + B_SLOT]
    xor edx, edx
    call x86_imm32
.for_jump:
    cmp dword [esi + B_DYN], 0
    jne .for_need_jump
    cmp dword [esi + B_LIMIT], 0
    jg .for_top
.for_need_jump:
    BYTES 0xE9, 1
    call x86_text_offset
    mov [esi + B_INIT], eax
    mov dword [edi], 0
    add edi, 4
.for_top:
    call x86_text_offset
    mov [esi + B_TOP], eax
    mov eax, [ebx + S_VAR]
    call var_abs_idx
    mov edx, eax
    cmp dword [esi + B_REG], NOREG
    je .for_store_mem
    mov ecx, [esi + B_REG]
    mov eax, 0x89
    call e_mr
    mov ecx, [ebx + S_VAR]
    call for_aliasable
    test eax, eax
    jz .done
    mov ecx, [ebx + S_VAR]
    mov [esi + B_ALIAS], ecx
    mov eax, [cg_vreg]
    mov edx, [esi + B_REG]
    inc edx
    or edx, 0x40
    mov [eax + ecx], dl
    jmp .done
.for_store_mem:
    push edx
    OPA 0xA1, 1, [esi + B_SLOT]
    pop edx
    OPA 0xA3, 1, edx
.done:
    pop ebx
    pop esi
    ret

patch_initial:
    mov eax, [esi + B_INIT]
    cmp eax, -1
    je .none
    push eax
    call x86_text_offset
    mov edx, eax
    pop eax
    sub edx, eax
    sub edx, 4
    add eax, [x86_text_base]
    mov [eax], edx
.none:
    ret

emit_rel32_back:
    call x86_text_offset
    add eax, 4
    sub ecx, eax
    mov [edi], ecx
    add edi, 4
    ret

emit_loop_tail:
    mov ecx, [esi + B_ALIAS]
    cmp ecx, -1
    je .no_alias
    mov eax, [cg_vreg]
    mov byte [eax + ecx], 0
.no_alias:
    cmp dword [esi + B_KIND], BK_FOR
    jne .loops_tail
    cmp dword [esi + B_REG], NOREG
    je .for_inc_mem
    mov eax, 0x40
    mov ecx, [esi + B_REG]
    call emit_reg1
    jmp .for_check
.for_inc_mem:
    OPA 0x05FF, 2, [esi + B_SLOT]
.for_check:
    call patch_initial
    cmp dword [esi + B_REG], NOREG
    je .for_cmp_mem
    cmp dword [esi + B_DYN], 0
    jne .for_cmp_reg_slot
    mov ecx, 7
    mov edx, [esi + B_REG]
    mov eax, 0x81
    call e_rr
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .jl_back
.for_cmp_reg_slot:
    mov ecx, [esi + B_REG]
    mov edx, [esi + B_LIMIT]
    mov eax, 0x3B
    call e_mr
    jmp .jl_back
.for_cmp_mem:
    OPA 0xA1, 1, [esi + B_SLOT]
    cmp dword [esi + B_DYN], 0
    jne .for_cmp_mem_slot
    BYTES 0x3D, 1
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .jl_back
.for_cmp_mem_slot:
    OPA 0x053B, 2, [esi + B_LIMIT]
.jl_back:
    BYTES 0x8C0F, 2
    mov ecx, [esi + B_TOP]
    jmp emit_rel32_back
.loops_tail:
    cmp dword [esi + B_REG], NOREG
    je .loops_dec_mem
    mov eax, 0x48
    mov ecx, [esi + B_REG]
    call emit_reg1
    jmp .loops_jnz
.loops_dec_mem:
    OPA 0x0DFF, 2, [esi + B_SLOT]
.loops_jnz:
    BYTES 0x850F, 2
    mov ecx, [esi + B_TOP]
    call emit_rel32_back
    jmp patch_initial

expr_safe:
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_INT
    je .yes
    cmp edx, VK_VAR
    je .var
    cmp edx, VK_EXPR
    jne .no
    movzx edx, byte [eax + V_NEG]
    cmp edx, OP_NEG
    je .left
    cmp edx, OP_DIV
    je .div
    cmp edx, OP_MOD
    jne .both
.div:
    push eax
    mov ecx, [eax + V_DATA + 4]
    call node_addr
    mov ecx, eax
    pop eax
    cmp byte [ecx + V_KIND], VK_INT
    jne .no
    mov edx, [ecx + V_DATA]
    add edx, 1
    cmp edx, 2
    jbe .no
.both:
    push eax
    mov ecx, [eax + V_DATA + 4]
    call expr_safe
    pop ecx
    test eax, eax
    jz .no
    mov eax, ecx
.left:
    mov ecx, [eax + V_DATA]
    jmp expr_safe
.var:
    mov edx, [eax + V_DATA]
    mov eax, [cg_vreg]
    test byte [eax + edx], 0x40
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
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_OR
    je .or
    cmp edx, VK_AND
    je .and
    cmp edx, VK_CMP
    jne .bad
    movzx edx, byte [eax + V_TYPE]
    cmp edx, TY_INT
    je .typed
    cmp edx, TY_BOOL
    jne .bad
.typed:
    push eax
    mov ecx, [eax + V_DATA]
    call expr_safe
    pop ecx
    test eax, eax
    jz .bad
    mov ecx, [ecx + V_DATA + 4]
    call expr_safe
    test eax, eax
    jz .bad
    mov eax, 1
    ret
.and:
    mov dword [cg_bland], 1
.or:
    push eax
    mov ecx, [eax + V_DATA]
    call cond_leaves
    pop ecx
    test eax, eax
    js .r
    push eax
    mov ecx, [ecx + V_DATA + 4]
    call cond_leaves
    pop ecx
    test eax, eax
    js .r
    add eax, ecx
.r:
    ret
.bad:
    mov eax, -1
    ret

bl_emit:
    push esi
    call node_addr
    mov esi, eax
    cmp byte [esi + V_KIND], VK_OR
    jne .leaf
    mov ecx, [esi + V_DATA]
    call bl_emit
    mov ecx, [esi + V_DATA + 4]
    call bl_emit
    pop esi
    ret
.leaf:
    call emit_compare
    add eax, 0x90
    shl eax, 8
    or eax, 0xC1000F
    mov ecx, 3
    call x86_bytes
    BYTES 0xC9B60F, 3
    mov eax, 0x09
    mov ecx, R_ECX
    mov edx, [cg_blacc]
    call e_rr
    pop esi
    ret

bl_sign:
    call node_addr
    cmp byte [eax + V_KIND], VK_CMP
    jne .no
    movzx edx, byte [eax + V_NEG]
    mov ecx, [eax + V_DATA]
    push ecx
    mov ecx, [eax + V_DATA + 4]
    pop eax
    cmp edx, CMP_LT
    je .lt
    cmp edx, CMP_GT
    jne .no
    xchg eax, ecx
.lt:
    mov [cg_tmp], eax
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    mov ecx, [cg_tmp]
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    je .no
    cmp byte [eax + V_KIND], VK_VAR
    jne .expr
    push eax
    mov ecx, [eax + V_DATA]
    call var_reg
    mov ecx, eax
    pop eax
    test ecx, ecx
    js .mem
    lea eax, [ecx + 0xE0]
    shl eax, 16
    or eax, 0x1F00BA0F
    mov ecx, 4
    call x86_bytes
    mov eax, 1
    ret
.mem:
    call var_abs
    mov edx, eax
    OPA 0x25BA0F, 3, edx
    BYTES 0x1F, 1
    mov eax, 1
    ret
.expr:
    mov ecx, [cg_tmp]
    call emit_expr
    BYTES 0x1FE0BA0F, 4
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

try_branchless:
    push esi
    push ebx
    mov esi, [cg_cur]
    call temp_limit
    cmp [cg_depth], eax
    jae .no
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    add eax, 2
    cmp [esi + S_PIECES], eax
    jne .no
    cmp eax, [g_nstmt]
    jae .no_else
    mov ecx, eax
    call stmt_ptr
    cmp word [eax + S_KIND], SK_ELSE
    je .no
.no_else:
    lea ebx, [esi + S_SIZE]
    movzx eax, word [ebx + S_KIND]
    cmp eax, SK_DECL
    je .body_kind
    cmp eax, SK_ASSIGN
    jne .no
.body_kind:
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    cmp dword [ebx + S_NPARTS], 0
    je .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    movzx edx, byte [eax + V_NEG]
    mov [cg_tmp + 4], edx
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    cmp dword [cg_tmp + 4], OP_SUB
    je .order_ok
    cmp dword [cg_tmp + 4], OP_ADD
    jne .no
    push ecx
    mov ecx, edx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    je .order_ok
    xchg ecx, edx
.order_ok:
    push edx
    call node_addr
    pop edx
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    mov eax, [eax + V_DATA]
    cmp eax, [ebx + S_VAR]
    jne .no
    mov [cg_blvar], eax
    mov ecx, edx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    cmp dword [cg_tmp + 4], OP_SUB
    jne .k_ok
    neg eax
.k_ok:
    mov [cg_blk], eax
    mov eax, esi
    call stmt_root
    mov dword [cg_bldata], 0
    mov dword [cg_bland], 0
    push ecx
    call cond_leaves
    pop ecx
    test eax, eax
    jle .no
    cmp eax, 4
    ja .no
    cmp dword [cg_bldata], 0
    je .no
    cmp dword [cg_bland], 0
    jne .no
    mov eax, [cg_blvar]
    call var_abs_idx
    mov ebx, eax
    mov eax, [cg_blk]
    lea edx, [eax + 1]
    cmp edx, 2
    ja .generic
    test eax, eax
    jz .generic
    push ecx
    call bl_sign
    pop ecx
    test eax, eax
    jz .generic
    mov eax, 0x1583
    cmp dword [cg_blk], 1
    je .carry
    mov eax, 0x1D83
.carry:
    mov ecx, 2
    mov edx, ebx
    call x86_op_abs
    xor edx, edx
    call x86_imm8
    jmp .yes
.generic:
    call temp_reg
    mov [cg_blacc], eax
    push ecx
    mov ecx, eax
    mov edx, eax
    mov eax, 0x31
    call e_rr
    pop ecx
    inc dword [cg_depth]
    call bl_emit
    dec dword [cg_depth]
    mov eax, [cg_blk]
    cmp eax, 1
    je .add_acc
    cmp eax, -1
    je .sub_acc
    mov ecx, [cg_blacc]
    mov edx, ecx
    mov eax, 0x69
    call e_rr
    mov edx, [cg_blk]
    call x86_imm32
.add_acc:
    mov eax, 0x01
    jmp .apply
.sub_acc:
    mov eax, 0x29
.apply:
    mov ecx, [cg_blacc]
    mov edx, ebx
    call e_mr
.yes:
    mov eax, 1
    pop ebx
    pop esi
    ret
.no:
    xor eax, eax
    pop ebx
    pop esi
    ret

section .rdata
temp_codes db 5, 7, 6
loop_regs  db 6, 7
section .text
