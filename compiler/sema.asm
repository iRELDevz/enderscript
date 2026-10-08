%include "defs.inc"
%include "state.inc"

section .rdata
s_semantic   db "semantic", 0
s_type       db "type", 0
s_undef      db "undefined variable '", 0
s_quote      db "'", 0
s_var_q      db "variable '", 0
s_already_as db "' is already declared as ", 0
s_an_int     db "an int variable", 0
s_a_str      db "a str variable", 0
s_a_bool     db "a bool variable", 0
s_already_at db "' is already declared at line ", 0
s_latest     db ", the latest declaration claims the value", 0
s_cannot     db "cannot assign ", 0
s_to         db " to ", 0
s_variable_q db " variable '", 0
s_int_lit    db "int literal ", 0
s_outside    db " is outside -2147483648..2147483647", 0
s_str_long   db "string is longer than 65535 bytes", 0
s_mode1      db "unknown print mode '.", 0
s_mode2      db "', expected '.s'", 0
s_overflow   db "integer overflow in constant expression, the result wraps to ", 0
s_div_zero   db "division by zero", 0
s_operator   db "operator '", 0
s_needs_bin  db "' needs int operands, got ", 0
s_needs_un   db "' needs an int operand, got ", 0
op_chars     db " +-*/%-"
s_tn_int     db "int", 0
s_tn_str     db "str", 0
s_tn_bool    db "bool", 0
s_tn_null    db "null", 0
s_true       db "true"
s_false      db "false"
s_null       db "null"
s_crlf       db 13, 10
s_minus      db "-"

section .bss
alignb 4
last_slot  resd 1
last_hash  resd 1
sm_end     resd 1
sm_part    resd 1
sm_piece   resd 1
sm_before  resd 1
sm_type    resd 1
sm_idx     resd 1
sm_a       resd 1
sm_b       resd 1
sm_c       resd 1

section .text

global tok_text
tok_text:
    mov eax, ecx
    shl eax, 4
    add eax, [g_tokens]
    mov edx, [eax + T_LEN]
    mov eax, [eax + T_OFF]
    add eax, [g_src]
    ret

tok_line:
    mov eax, ecx
    shl eax, 4
    add eax, [g_tokens]
    mov eax, [eax + T_LINE]
    ret

type_name:
    mov eax, s_tn_int
    cmp ecx, TY_INT
    je .r
    mov eax, s_tn_str
    cmp ecx, TY_STR
    je .r
    mov eax, s_tn_bool
    cmp ecx, TY_BOOL
    je .r
    mov eax, s_tn_null
.r:
    ret

pool_add:
    push esi
    push edi
    mov esi, ecx
    mov edi, [g_pool]
    add edi, [g_pool_len]
    add [g_pool_len], edx
    mov ecx, edx
    rep movsb
    pop edi
    pop esi
    ret

new_piece:
    mov eax, [g_npieces]
    inc dword [g_npieces]
    shl eax, 4
    add eax, [g_pieces]
    mov [eax + P_KIND], ecx
    mov [eax + P_A], edx
    mov dword [eax + P_B], 0
    ret

value_pos:
    cmp byte [ecx + V_KIND], VK_EXPR
    jne .leaf
    cmp byte [ecx + V_NEG], OP_NEG
    je .neg
    mov eax, [ecx + V_DATA]
    shl eax, 4
    add eax, [g_parts]
    mov ecx, eax
    jmp value_pos
.neg:
    mov edx, [ecx + V_TOK]
    ret
.leaf:
    movzx eax, byte [ecx + V_NEG]
    mov edx, [ecx + V_TOK]
    sub edx, eax
    ret

node_ptr:
    mov eax, ecx
    shl eax, 4
    add eax, [g_parts]
    ret


FUNC var_lookup, 8
    call tok_text
    mov esi, eax
    mov edi, edx
    mov ebx, 2166136261
    xor ecx, ecx
.hash:
    cmp ecx, edi
    jae .hashed
    movzx eax, byte [esi + ecx]
    xor ebx, eax
    imul ebx, ebx, 16777619
    inc ecx
    jmp .hash
.hashed:
    mov [last_hash], ebx
    mov eax, ebx
    and eax, [g_hmask]
    mov [L(0)], eax
.probe:
    mov eax, [L(0)]
    shl eax, 2
    add eax, [g_htab]
    mov [last_slot], eax
    mov eax, [eax]
    test eax, eax
    jz .missing
    dec eax
    mov [L(4)], eax
    shl eax, 5
    add eax, [g_vars]
    cmp [eax + VR_HASH], ebx
    jne .next
    mov ecx, [eax + VR_TOK]
    call tok_text
    cmp edx, edi
    jne .next
    push esi
    push edi
    mov ecx, edx
    mov edi, eax
    repe cmpsb
    pop edi
    pop esi
    jne .next
    mov eax, [L(4)]
    ENDF
.next:
    mov eax, [L(0)]
    inc eax
    and eax, [g_hmask]
    mov [L(0)], eax
    jmp .probe
.missing:
    mov eax, -1
    ENDF

FUNC var_insert
    mov esi, ecx
    mov edi, edx
    call var_lookup
    mov eax, [g_nvars]
    mov ebx, eax
    inc dword [g_nvars]
    mov ecx, [last_slot]
    lea edx, [eax + 1]
    mov [ecx], edx
    shl eax, 5
    add eax, [g_vars]
    mov ecx, [last_hash]
    mov [eax + VR_HASH], ecx
    mov [eax + VR_TOK], esi
    mov [eax + VR_TYPE], di
    mov ecx, 4
    mov edx, 4
    cmp edi, TY_INT
    je .size
    mov ecx, 1
    mov edx, 1
    cmp edi, TY_BOOL
    je .size
    mov ecx, 4
    mov edx, 8
.size:
    mov esi, [g_vars_size]
    lea esi, [esi + ecx - 1]
    neg ecx
    and esi, ecx
    mov [eax + VR_OFF], esi
    add esi, edx
    mov [g_vars_size], esi
    mov eax, ebx
    ENDF

FUNC check_value
    mov ebx, ecx
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_INT
    je .int
    cmp eax, VK_STR
    je .str
    cmp eax, VK_VAR
    je .var
    cmp eax, VK_EXPR
    je .expr
    mov esi, TY_BOOL
    cmp eax, VK_BOOL
    je .done
    mov esi, TY_NULL
    jmp .done

.int:
    mov esi, TY_INT
    mov ecx, [ebx + V_TOK]
    call tok_text
    mov edi, eax
    mov ecx, edx
    xor eax, eax
    xor edx, edx
.digit:
    test ecx, ecx
    jz .digits_done
    push ecx
    movzx ecx, byte [edi]
    sub ecx, '0'
    inc edi
    test edx, edx
    jnz .digit_skip
    cmp eax, 429496729
    ja .digit_big
    imul eax, eax, 10
    add eax, ecx
    jc .digit_big
    jmp .digit_skip
.digit_big:
    mov edx, 1
.digit_skip:
    pop ecx
    dec ecx
    jmp .digit
.digits_done:
    test edx, edx
    jnz .int_bad
    cmp byte [ebx + V_NEG], 0
    jne .int_neg
    cmp eax, 2147483647
    ja .int_bad
    mov [ebx + V_DATA], eax
    jmp .done
.int_neg:
    cmp eax, 2147483648
    ja .int_bad
    neg eax
    mov [ebx + V_DATA], eax
    jmp .done
.int_bad:
    mov byte [ebx + V_BAD], 1
    jmp .done

.str:
    mov esi, TY_STR
    mov ecx, [ebx + V_TOK]
    call tok_text
    lea ecx, [eax + 1]
    lea edx, [eax + edx - 1]
    mov eax, [g_pool_len]
    mov [ebx + V_DATA], eax
    mov edi, [g_pool]
    add edi, eax
    push edi
.dec:
    cmp ecx, edx
    jae .dec_done
    mov al, [ecx]
    inc ecx
    cmp al, '\'
    jne .dec_put
    mov al, [ecx]
    inc ecx
    cmp al, 'n'
    jne .e1
    mov al, 10
    jmp .dec_put
.e1:
    cmp al, 't'
    jne .e2
    mov al, 9
    jmp .dec_put
.e2:
    cmp al, 'r'
    jne .e3
    mov al, 13
    jmp .dec_put
.e3:
    cmp al, '0'
    jne .dec_put
    xor eax, eax
.dec_put:
    mov [edi], al
    inc edi
    jmp .dec
.dec_done:
    pop eax
    sub edi, eax
    add [g_pool_len], edi
    mov [ebx + V_DATA_HI], edi
    cmp edi, 65535
    jbe .done
    mov byte [ebx + V_BAD], 1
    jmp .done

.var:
    mov ecx, [ebx + V_TOK]
    call var_lookup
    cmp eax, -1
    je .undefined
    mov [ebx + V_DATA], eax
    shl eax, 5
    add eax, [g_vars]
    movzx esi, word [eax + VR_TYPE]
    jmp .done
.undefined:
    call msg_reset
    mov ecx, s_undef
    call msg_addz
    mov ecx, [ebx + V_TOK]
    call msg_tok
    mov ecx, s_quote
    call msg_addz
    mov ecx, s_semantic
    mov edx, [ebx + V_TOK]
    call diag_error_tok

.expr:
    mov ecx, ebx
    call check_expr
    mov esi, eax

.done:
    mov eax, esi
    mov [ebx + V_TYPE], al
    ENDF

FUNC value_finish
    mov ebx, ecx
    cmp byte [ebx + V_BAD], 0
    je .ok
    call msg_reset
    cmp byte [ebx + V_KIND], VK_INT
    jne .str
    mov ecx, s_int_lit
    call msg_addz
    cmp byte [ebx + V_NEG], 0
    je .digits
    mov cl, '-'
    call msg_addc
.digits:
    mov ecx, [ebx + V_TOK]
    call msg_tok
    mov ecx, s_outside
    call msg_addz
    jmp .err
.str:
    mov ecx, s_str_long
    call msg_addz
.err:
    mov ecx, ebx
    call value_pos
    mov ecx, s_type
    call diag_error_tok
.ok:
    ENDF

FUNC check_assign
    mov ebx, ecx
    mov esi, edx
    mov edi, eax
    call check_value
    cmp eax, esi
    je .ok
    cmp eax, TY_NULL
    jne .bad
    cmp esi, TY_STR
    je .ok
.bad:
    mov [sm_c], eax
    call msg_reset
    mov ecx, s_cannot
    call msg_addz
    mov ecx, [sm_c]
    call type_name
    mov ecx, eax
    call msg_addz
    mov ecx, s_to
    call msg_addz
    mov ecx, esi
    call type_name
    mov ecx, eax
    call msg_addz
    mov ecx, s_variable_q
    call msg_addz
    mov ecx, edi
    call msg_tok
    mov ecx, s_quote
    call msg_addz
    mov ecx, ebx
    call value_pos
    mov ecx, s_type
    call diag_error_tok
.ok:
    mov ecx, ebx
    call value_finish
    ENDF

FUNC sema
    mov ecx, [g_nstmt]
    inc ecx
    shl ecx, 5
    call mem_alloc
    mov [g_vars], eax
    mov dword [g_nvars], 0
    mov ecx, [g_nstmt]
    inc ecx
    shl ecx, 1
    mov eax, 16
.cap:
    cmp eax, ecx
    jae .cap_ok
    shl eax, 1
    jmp .cap
.cap_ok:
    lea edx, [eax - 1]
    mov [g_hmask], edx
    lea ecx, [eax * 4]
    call mem_alloc
    mov [g_htab], eax
    mov ecx, [g_src_len]
    shl ecx, 1
    add ecx, 4096
    call mem_alloc
    mov [g_pool], eax
    mov dword [g_pool_len], 0
    mov ecx, [g_nparts]
    add ecx, [g_nstmt]
    inc ecx
    shl ecx, 4
    call mem_alloc
    mov [g_pieces], eax
    mov dword [g_npieces], 0
    mov dword [g_vars_size], 0

    mov esi, [g_stmts]
    mov eax, [g_nstmt]
    shl eax, 5
    add eax, esi
    mov [sm_end], eax
.stmt:
    cmp esi, [sm_end]
    jae .finish
    movzx eax, word [esi + S_KIND]
    cmp eax, SK_DECL
    je .decl
    cmp eax, SK_ASSIGN
    je .assign
    jmp .out

.decl:
    mov ecx, [esi + S_TOK]
    call var_lookup
    mov [sm_idx], eax
    cmp eax, -1
    je .decl_value
    shl eax, 5
    add eax, [g_vars]
    mov ebx, eax
    movzx eax, word [ebx + VR_TYPE]
    movzx ecx, word [esi + S_MODE]
    cmp eax, ecx
    jne .redecl_type
    call msg_reset
    mov ecx, s_var_q
    call msg_addz
    mov ecx, [esi + S_TOK]
    call msg_tok
    mov ecx, s_already_at
    call msg_addz
    mov ecx, [ebx + VR_LINE]
    call msg_addu
    mov ecx, s_latest
    call msg_addz
    mov ecx, [esi + S_TOK]
    call diag_warn_tok
.decl_value:
    cmp dword [esi + S_NPARTS], 0
    je .decl_store
    mov eax, [esi + S_PARTS]
    mov ecx, [g_roots]
    mov ecx, [ecx + eax * 4]
    shl ecx, 4
    add ecx, [g_parts]
    movzx edx, word [esi + S_MODE]
    mov eax, [esi + S_TOK]
    call check_assign
.decl_store:
    cmp dword [sm_idx], -1
    jne .decl_known
    mov ecx, [esi + S_TOK]
    movzx edx, word [esi + S_MODE]
    call var_insert
    mov [sm_idx], eax
.decl_known:
    mov eax, [sm_idx]
    mov [esi + S_VAR], eax
    mov ecx, [esi + S_TOK]
    call tok_line
    mov ecx, [sm_idx]
    shl ecx, 5
    add ecx, [g_vars]
    mov [ecx + VR_LINE], eax
    jmp .next

.redecl_type:
    mov [sm_c], eax
    call msg_reset
    mov ecx, s_var_q
    call msg_addz
    mov ecx, [esi + S_TOK]
    call msg_tok
    mov ecx, s_already_as
    call msg_addz
    mov ecx, s_an_int
    cmp dword [sm_c], TY_INT
    je .redecl_msg
    mov ecx, s_a_str
    cmp dword [sm_c], TY_STR
    je .redecl_msg
    mov ecx, s_a_bool
.redecl_msg:
    call msg_addz
    mov ecx, s_semantic
    mov edx, [esi + S_TOK]
    call diag_error_tok

.assign:
    mov ecx, [esi + S_TOK]
    call var_lookup
    cmp eax, -1
    jne .assign_ok
    call msg_reset
    mov ecx, s_undef
    call msg_addz
    mov ecx, [esi + S_TOK]
    call msg_tok
    mov ecx, s_quote
    call msg_addz
    mov ecx, s_semantic
    mov edx, [esi + S_TOK]
    call diag_error_tok
.assign_ok:
    mov [esi + S_VAR], eax
    shl eax, 5
    add eax, [g_vars]
    movzx edx, word [eax + VR_TYPE]
    mov [esi + S_MODE], dx
    cmp dword [esi + S_NPARTS], 0
    je .next
    mov eax, [esi + S_PARTS]
    mov ecx, [g_roots]
    mov ecx, [ecx + eax * 4]
    shl ecx, 4
    add ecx, [g_parts]
    mov eax, [esi + S_TOK]
    call check_assign
    jmp .next

.out:
    mov ecx, [esi + S_MODETOK]
    cmp ecx, NO_TOKEN
    je .out_parts
    call tok_text
    cmp edx, 1
    jne .bad_mode
    cmp byte [eax], 's'
    je .out_parts
.bad_mode:
    call msg_reset
    mov ecx, s_mode1
    call msg_addz
    mov ecx, [esi + S_MODETOK]
    call msg_tok
    mov ecx, s_mode2
    call msg_addz
    mov ecx, s_semantic
    mov edx, [esi + S_MODETOK]
    dec edx
    call diag_error_tok

.out_parts:
    mov eax, [g_npieces]
    mov [esi + S_PIECES], eax
    mov dword [sm_piece], 0
    mov dword [sm_part], 0
.part:
    mov eax, [sm_part]
    cmp eax, [esi + S_NPARTS]
    jae .parts_done
    add eax, [esi + S_PARTS]
    mov ecx, [g_roots]
    mov eax, [ecx + eax * 4]
    shl eax, 4
    add eax, [g_parts]
    mov ebx, eax
    mov eax, [g_pool_len]
    mov [sm_before], eax
    mov ecx, ebx
    call check_value
    mov [sm_type], eax
    mov ecx, ebx
    call value_finish
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_EXPR
    je .part_expr
    cmp eax, VK_VAR
    je .part_var
    cmp eax, VK_INT
    je .part_int
    cmp eax, VK_BOOL
    je .part_bool
    cmp eax, VK_NULL
    jne .part_text
    mov ecx, s_null
    mov edx, 4
    call pool_add
    jmp .part_text
.part_bool:
    mov ecx, s_true
    mov edx, 4
    cmp dword [ebx + V_DATA], 0
    jne .part_bool_add
    mov ecx, s_false
    mov edx, 5
.part_bool_add:
    call pool_add
    jmp .part_text
.part_int:
    mov ecx, [ebx + V_DATA]
    test ecx, ecx
    jns .part_int_dec
    mov ecx, s_minus
    mov edx, 1
    call pool_add
    mov ecx, [ebx + V_DATA]
    neg ecx
.part_int_dec:
    call u32_to_dec
    mov ecx, eax
    call pool_add
.part_text:
    cmp dword [sm_piece], 0
    jne .part_extend
    mov ecx, PK_TEXT
    mov edx, [sm_before]
    call new_piece
    mov [sm_piece], eax
.part_extend:
    mov eax, [sm_piece]
    mov ecx, [g_pool_len]
    sub ecx, [eax + P_A]
    mov [eax + P_B], ecx
    jmp .part_next
.part_var:
    mov dword [sm_piece], 0
    mov eax, [ebx + V_DATA]
    shl eax, 5
    add eax, [g_vars]
    mov edx, [eax + VR_OFF]
    mov ecx, PK_INT
    cmp dword [sm_type], TY_INT
    je .part_var_add
    mov ecx, PK_BOOL
    cmp dword [sm_type], TY_BOOL
    je .part_var_add
    mov ecx, PK_STR
.part_var_add:
    call new_piece
    jmp .part_next
.part_expr:
    mov dword [sm_piece], 0
    mov edx, ebx
    sub edx, [g_parts]
    shr edx, 4
    mov ecx, PK_EXPR
    call new_piece
.part_next:
    inc dword [sm_part]
    jmp .part

.parts_done:
    cmp word [esi + S_MODE], 0
    jne .out_count
    cmp dword [sm_piece], 0
    jne .crlf
    mov ecx, PK_TEXT
    mov edx, [g_pool_len]
    call new_piece
    mov [sm_piece], eax
.crlf:
    mov ecx, s_crlf
    mov edx, 2
    call pool_add
    mov eax, [sm_piece]
    mov ecx, [g_pool_len]
    sub ecx, [eax + P_A]
    mov [eax + P_B], ecx
.out_count:
    mov eax, [g_npieces]
    sub eax, [esi + S_PIECES]
    mov [esi + S_NPIECES], eax

.next:
    add esi, S_SIZE
    jmp .stmt
.finish:
    ENDF

set_const:
    push eax
    mov ecx, ebx
    call value_pos
    pop eax
    mov byte [ebx + V_KIND], VK_INT
    mov byte [ebx + V_NEG], 0
    mov byte [ebx + V_BAD], 0
    mov [ebx + V_TOK], edx
    mov [ebx + V_DATA], eax
    ret

copy_node:
    mov eax, [ecx]
    mov [ebx], eax
    mov eax, [ecx + 4]
    mov [ebx + 4], eax
    mov eax, [ecx + 8]
    mov [ebx + 8], eax
    mov eax, [ecx + 12]
    mov [ebx + 12], eax
    ret

FUNC check_expr, 16
    mov ebx, ecx
    movzx eax, byte [ebx + V_NEG]
    mov [L(0)], eax
    mov ecx, [ebx + V_DATA]
    call node_ptr
    mov esi, eax
    mov ecx, esi
    call check_value
    mov [L(4)], eax
    mov ecx, esi
    call value_finish
    cmp dword [L(4)], TY_INT
    jne .bad_operand
    cmp dword [L(0)], OP_NEG
    je .unary
    mov ecx, [ebx + V_DATA + 4]
    call node_ptr
    mov edi, eax
    mov ecx, edi
    call check_value
    mov [L(4)], eax
    mov ecx, edi
    call value_finish
    cmp dword [L(4)], TY_INT
    jne .bad_operand
    xor eax, eax
    cmp byte [esi + V_KIND], VK_INT
    jne .left_done
    or eax, 1
.left_done:
    cmp byte [edi + V_KIND], VK_INT
    jne .right_done
    or eax, 2
.right_done:
    mov [L(8)], eax
    test eax, 2
    jz .no_zero
    cmp dword [edi + V_DATA], 0
    jne .no_zero
    cmp dword [L(0)], OP_DIV
    je .div_zero
    cmp dword [L(0)], OP_MOD
    je .div_zero
.no_zero:
    cmp dword [L(8)], 3
    je .fold
    test dword [L(8)], 2
    jnz .right_const
    test dword [L(8)], 1
    jnz .left_const
    jmp .int_result

.right_const:
    mov ecx, [edi + V_DATA]
    mov eax, [L(0)]
    cmp eax, OP_ADD
    je .r_add_sub
    cmp eax, OP_SUB
    je .r_add_sub
    cmp eax, OP_MUL
    je .r_mul
    cmp eax, OP_DIV
    je .r_div
    jmp .r_mod
.r_add_sub:
    test ecx, ecx
    jz .take_left
    jmp .int_result
.r_mul:
    test ecx, ecx
    jnz .r_div
    cmp byte [esi + V_KIND], VK_VAR
    je .make_zero
    jmp .int_result
.r_div:
    cmp ecx, 1
    je .take_left
    cmp ecx, -1
    jne .int_result
    mov ecx, esi
    call value_pos
    mov [ebx + V_TOK], edx
    mov byte [ebx + V_NEG], OP_NEG
    mov dword [ebx + V_DATA + 4], NO_EXPR
    jmp .int_result
.r_mod:
    cmp byte [esi + V_KIND], VK_VAR
    jne .int_result
    cmp ecx, 1
    je .make_zero
    cmp ecx, -1
    je .make_zero
    jmp .int_result

.left_const:
    mov ecx, [esi + V_DATA]
    mov eax, [L(0)]
    cmp eax, OP_ADD
    je .l_add
    cmp eax, OP_SUB
    je .l_sub
    cmp eax, OP_MUL
    jne .int_result
    test ecx, ecx
    jnz .l_mul_one
    cmp byte [edi + V_KIND], VK_VAR
    je .make_zero
    jmp .int_result
.l_mul_one:
    cmp ecx, 1
    je .take_right
    jmp .int_result
.l_add:
    test ecx, ecx
    jz .take_right
    jmp .int_result
.l_sub:
    test ecx, ecx
    jnz .int_result
    mov eax, [esi + V_TOK]
    mov [ebx + V_TOK], eax
    mov eax, [ebx + V_DATA + 4]
    mov [ebx + V_DATA], eax
    mov byte [ebx + V_NEG], OP_NEG
    mov dword [ebx + V_DATA + 4], NO_EXPR
    jmp .int_result

.take_left:
    mov ecx, esi
    call copy_node
    jmp .int_result
.take_right:
    mov ecx, edi
    call copy_node
    jmp .int_result
.make_zero:
    xor eax, eax
    call set_const
    jmp .int_result

.unary:
    cmp byte [esi + V_KIND], VK_INT
    jne .int_result
    mov dword [L(12)], 0
    mov eax, [esi + V_DATA]
    neg eax
    jno .fold_store
    mov dword [L(12)], 1
    jmp .fold_store

.fold:
    mov dword [L(12)], 0
    mov eax, [esi + V_DATA]
    mov ecx, [edi + V_DATA]
    mov edx, [L(0)]
    cmp edx, OP_ADD
    jne .f_sub
    add eax, ecx
    jmp .f_flag
.f_sub:
    cmp edx, OP_SUB
    jne .f_mul
    sub eax, ecx
    jmp .f_flag
.f_mul:
    cmp edx, OP_MUL
    jne .f_div
    imul eax, ecx
    jmp .f_flag
.f_div:
    cmp ecx, -1
    jne .f_idiv
    cmp edx, OP_MOD
    je .f_zero
    neg eax
    jmp .f_flag
.f_zero:
    xor eax, eax
    jmp .fold_store
.f_idiv:
    push edx
    cdq
    idiv ecx
    pop ecx
    cmp ecx, OP_DIV
    je .fold_store
    mov eax, edx
    jmp .fold_store
.f_flag:
    jno .fold_store
    mov dword [L(12)], 1
.fold_store:
    cmp dword [L(12)], 0
    je .fold_ok
    mov [L(4)], eax
    call msg_reset
    mov ecx, s_overflow
    call msg_addz
    mov ecx, [L(4)]
    test ecx, ecx
    jns .ov_pos
    mov cl, '-'
    call msg_addc
    mov ecx, [L(4)]
    neg ecx
.ov_pos:
    call msg_addu
    mov ecx, [ebx + V_TOK]
    call diag_warn_tok
    mov eax, [L(4)]
.fold_ok:
    call set_const

.int_result:
    mov eax, TY_INT
    ENDF

.div_zero:
    call msg_reset
    mov ecx, s_div_zero
    call msg_addz
    mov ecx, s_semantic
    mov edx, [ebx + V_TOK]
    call diag_error_tok

.bad_operand:
    call msg_reset
    mov ecx, s_operator
    call msg_addz
    mov eax, [L(0)]
    mov cl, [op_chars + eax]
    call msg_addc
    mov ecx, s_needs_bin
    cmp dword [L(0)], OP_NEG
    jne .bad_msg
    mov ecx, s_needs_un
.bad_msg:
    call msg_addz
    mov ecx, [L(4)]
    call type_name
    mov ecx, eax
    call msg_addz
    mov ecx, s_type
    mov edx, [ebx + V_TOK]
    call diag_error_tok

