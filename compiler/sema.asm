%include "defs.inc"
%include "state.inc"
%include "xlat.inc"


section .rodata
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
s_cmp1       db "cannot compare ", 0
s_with       db " with ", 0
s_in_if1     db "variable '", 0
s_in_if2     db "' must be declared before the if block", 0
s_str_if1    db "cannot declare str variable '", 0
s_str_if2    db "' inside an if block", 0
s_in_loop2   db "' must be declared before the loop", 0
s_str_loop2  db "' inside a loop", 0
s_count1     db "loop count must be int, got ", 0
s_lvar1      db "loop variable '", 0
s_lvar2      db "' must be int, it is declared as ", 0
cmp_chars    db "   <><>"
s_tn_int     db "int", 0
s_tn_str     db "str", 0
s_tn_bool    db "bool", 0
s_tn_null    db "null", 0
s_true       db "true"
s_false      db "false"
s_null       db "null"
s_crlf       db 10

section .bss
alignb 8
last_slot resq 1
last_hash resq 1
sm_carry  resq 1
sm_bdepth resq 1
sm_bstack resq MAX_NEST + 1
sm_bkind  resq MAX_NEST + 1

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
    lea eax, [s_tn_int]
    cmp ecx, TY_INT
    je .r
    lea eax, [s_tn_str]
    cmp ecx, TY_STR
    je .r
    lea eax, [s_tn_bool]
    cmp ecx, TY_BOOL
    je .r
    lea eax, [s_tn_null]
.r:
    ret

pool_add:
    push ebx
    mov ebx, [g_pool]
    mov dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, [g_pool_len]
    add dword [vr8], ebx
    pop ebx
    add [g_pool_len], edx
.loop:
    test edx, edx
    jz .end
    mov al, [ecx]
    push ebx
    mov ebx, [vr8]
    mov [ebx], al
    pop ebx
    inc ecx
    inc dword [vr8]
    dec edx
    jmp .loop
.end:
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

set_const:
    mov ecx, ebx
    call value_pos
    mov byte [ebx + V_KIND], VK_INT
    mov byte [ebx + V_NEG], 0
    mov byte [ebx + V_BAD], 0
    mov [ebx + V_TOK], edx
    push esi
    mov esi, dword [vr10]
    mov [ebx + V_DATA], esi
    pop esi
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

XFUNC check_expr
    mov ebx, ecx
    push esi
    movzx esi, byte [ebx + V_NEG]
    mov dword [vr12], esi
    pop esi
    mov ecx, [ebx + V_DATA]
    call node_ptr
    mov dword [vr13], eax
    mov ecx, dword [vr13]
    call check_value
    mov dword [vr14], eax
    mov ecx, dword [vr13]
    call value_finish
    cmp dword [vr14], TY_INT
    jne .bad_operand
    cmp dword [vr12], OP_NEG
    je .unary
    mov ecx, [ebx + V_DATA + 4]
    call node_ptr
    mov dword [vr15], eax
    mov ecx, dword [vr15]
    call check_value
    mov dword [vr14], eax
    mov ecx, dword [vr15]
    call value_finish
    cmp dword [vr14], TY_INT
    jne .bad_operand
    xor esi, esi
    push ebx
    mov ebx, [vr13]
    cmp byte [ebx + V_KIND], VK_INT
    pop ebx
    jne .left_done
    or esi, 1
.left_done:
    push ebx
    mov ebx, [vr15]
    cmp byte [ebx + V_KIND], VK_INT
    pop ebx
    jne .right_done
    or esi, 2
.right_done:
    push ebx
    push esi
    mov ebx, [vr13]
    mov esi, [ebx + V_DATA]
    mov dword [vr8], esi
    pop esi
    pop ebx
    push ebx
    push esi
    mov ebx, [vr15]
    mov esi, [ebx + V_DATA]
    mov dword [vr9], esi
    pop esi
    pop ebx
    test esi, 2
    jz .no_zero_check
    push ebx
    mov ebx, dword [vr9]
    test dword [vr9], ebx
    pop ebx
    jnz .no_zero_check
    cmp dword [vr12], OP_DIV
    je .div_zero
    cmp dword [vr12], OP_MOD
    je .div_zero
.no_zero_check:
    cmp esi, 3
    je .fold
    test esi, 2
    jnz .right_const
    test esi, 1
    jnz .left_const
    jmp .int_result

.right_const:
    cmp dword [vr12], OP_ADD
    je .r_add_sub
    cmp dword [vr12], OP_SUB
    je .r_add_sub
    cmp dword [vr12], OP_MUL
    je .r_mul
    cmp dword [vr12], OP_DIV
    je .r_div
    jmp .r_mod
.r_add_sub:
    push ebx
    mov ebx, dword [vr9]
    test dword [vr9], ebx
    pop ebx
    jz .take_left
    jmp .int_result
.r_mul:
    push ebx
    mov ebx, dword [vr9]
    test dword [vr9], ebx
    pop ebx
    jnz .r_div
    push ebx
    mov ebx, [vr13]
    cmp byte [ebx + V_KIND], VK_VAR
    pop ebx
    je .make_zero
    jmp .int_result
.r_div:
    cmp dword [vr9], 1
    je .take_left
    cmp dword [vr9], -1
    jne .int_result
    mov ecx, dword [vr13]
    call value_pos
    mov [ebx + V_TOK], edx
    mov byte [ebx + V_NEG], OP_NEG
    mov dword [ebx + V_DATA + 4], NO_EXPR
    jmp .int_result
.r_mod:
    push ebx
    mov ebx, [vr13]
    cmp byte [ebx + V_KIND], VK_VAR
    pop ebx
    jne .int_result
    cmp dword [vr9], 1
    je .make_zero
    cmp dword [vr9], -1
    je .make_zero
    jmp .int_result

.left_const:
    cmp dword [vr12], OP_ADD
    je .l_add
    cmp dword [vr12], OP_SUB
    je .l_sub
    cmp dword [vr12], OP_MUL
    jne .int_result
    push ebx
    mov ebx, dword [vr8]
    test dword [vr8], ebx
    pop ebx
    jnz .l_mul_one
    push ebx
    mov ebx, [vr15]
    cmp byte [ebx + V_KIND], VK_VAR
    pop ebx
    je .make_zero
    jmp .int_result
.l_mul_one:
    cmp dword [vr8], 1
    je .take_right
    jmp .int_result
.l_add:
    push ebx
    mov ebx, dword [vr8]
    test dword [vr8], ebx
    pop ebx
    jz .take_right
    jmp .int_result
.l_sub:
    push ebx
    mov ebx, dword [vr8]
    test dword [vr8], ebx
    pop ebx
    jnz .int_result
    push ebx
    mov ebx, [vr13]
    mov eax, [ebx + V_TOK]
    pop ebx
    mov [ebx + V_TOK], eax
    mov eax, [ebx + V_DATA + 4]
    mov [ebx + V_DATA], eax
    mov byte [ebx + V_NEG], OP_NEG
    mov dword [ebx + V_DATA + 4], NO_EXPR
    jmp .int_result

.take_left:
    mov ecx, dword [vr13]
    call copy_node
    jmp .int_result
.take_right:
    mov ecx, dword [vr15]
    call copy_node
    jmp .int_result
.make_zero:
    push ebx
    mov ebx, dword [vr10]
    xor dword [vr10], ebx
    pop ebx
    call set_const
    jmp .int_result

.unary:
    push ebx
    mov ebx, [vr13]
    cmp byte [ebx + V_KIND], VK_INT
    pop ebx
    jne .int_result
    push ebx
    push esi
    mov ebx, [vr13]
    mov esi, [ebx + V_DATA]
    mov dword [vr10], esi
    pop esi
    pop ebx
    neg dword [vr10]
    jo .f_over
    jmp .fold_ok

.fold:
    push ebx
    mov ebx, dword [vr8]
    mov dword [vr10], ebx
    pop ebx
    cmp dword [vr12], OP_ADD
    jne .f_sub
    push ebx
    mov ebx, dword [vr9]
    add dword [vr10], ebx
    pop ebx
    jo .f_over
    jmp .fold_ok
.f_sub:
    cmp dword [vr12], OP_SUB
    jne .f_mul
    push ebx
    mov ebx, dword [vr9]
    sub dword [vr10], ebx
    pop ebx
    jo .f_over
    jmp .fold_ok
.f_mul:
    cmp dword [vr12], OP_MUL
    jne .f_div
    push ebx
    mov ebx, dword [vr10]
    imul ebx, dword [vr9]
    mov dword [vr10], ebx
    pop ebx
    jo .f_over
    jmp .fold_ok
.f_div:
    cmp dword [vr8], 0x80000000
    jne .f_div_ok
    cmp dword [vr9], -1
    jne .f_div_ok
    mov dword [vr10], 0x80000000
    cmp dword [vr12], OP_DIV
    je .f_over
    push ebx
    mov ebx, dword [vr10]
    xor dword [vr10], ebx
    pop ebx
    jmp .fold_ok
.f_div_ok:
    mov eax, dword [vr8]
    cdq
    idiv dword [vr9]
    mov dword [vr10], eax
    cmp dword [vr12], OP_DIV
    je .fold_ok
    mov dword [vr10], edx
    jmp .fold_ok
.f_over:
    push dword [vr10]
    push dword [vr10]
    call msg_reset
    lea ecx, [s_overflow]
    call msg_addz
    push ebx
    mov ebx, [esp + 4]
    mov dword [vr10], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr10]
    test dword [vr10], ebx
    pop ebx
    jns .ov_pos
    mov cl, '-'
    call msg_addc
    push ebx
    mov ebx, [esp + 4]
    mov dword [vr10], ebx
    pop ebx
    neg dword [vr10]
.ov_pos:
    mov ecx, dword [vr10]
    call msg_addu
    mov ecx, [ebx + V_TOK]
    call diag_warn_tok
    pop dword [vr10]
    pop dword [vr10]
.fold_ok:
    call set_const

.int_result:
    mov eax, TY_INT
    XENDF

.div_zero:
    call msg_reset
    lea ecx, [s_div_zero]
    call msg_addz
    lea ecx, [s_semantic]
    mov edx, [ebx + V_TOK]
    call diag_error_tok

.bad_operand:
    call msg_reset
    lea ecx, [s_operator]
    call msg_addz
    lea eax, [op_chars]
    push ebx
    mov ebx, [vr12]
    mov cl, [eax + ebx]
    pop ebx
    call msg_addc
    lea ecx, [s_needs_bin]
    cmp dword [vr12], OP_NEG
    jne .bad_msg
    lea ecx, [s_needs_un]
.bad_msg:
    call msg_addz
    mov ecx, dword [vr14]
    call type_name
    mov ecx, eax
    call msg_addz
    lea ecx, [s_type]
    mov edx, [ebx + V_TOK]
    call diag_error_tok

XFUNC var_lookup
    mov dword [vr12], ecx
    call tok_text
    mov esi, eax
    mov edi, edx
    mov ebx, 0x811c9dc5
    mov dword [vr9], 0x01000193
    xor ecx, ecx
.hash:
    cmp ecx, edi
    jae .hashed
    movzx eax, byte [esi + ecx]
    xor ebx, eax
    imul ebx, dword [vr9]
    inc ecx
    jmp .hash
.hashed:
    mov [last_hash], ebx
    push ebx
    mov ebx, [g_hmask]
    mov dword [vr13], ebx
    pop ebx
    mov dword [vr14], ebx
    push ebx
    mov ebx, dword [vr13]
    and dword [vr14], ebx
    pop ebx
    push ebx
    mov ebx, [g_htab]
    mov dword [vr15], ebx
    pop ebx
.probe:
    push ebx
    push esi
    mov ebx, [vr15]
    mov esi, [vr14]
    lea eax, [ebx + esi * 4]
    pop esi
    pop ebx
    mov [last_slot], eax
    mov eax, [eax]
    test eax, eax
    jz .missing
    dec eax
    mov dword [vr10], eax
    shl eax, 5
    add eax, [g_vars]
    cmp [eax + VR_HASH], ebx
    jne .next
    mov ecx, [eax + VR_TOK]
    call tok_text
    cmp edx, edi
    jne .next
    xor ecx, ecx
.cmp:
    cmp ecx, edi
    jae .found
    push ebx
    mov bl, [eax + ecx]
    mov byte [vr8], bl
    pop ebx
    push ebx
    mov bl, [esi + ecx]
    cmp byte [vr8], bl
    pop ebx
    jne .next
    inc ecx
    jmp .cmp
.found:
    mov eax, dword [vr10]
    XENDF
.next:
    inc dword [vr14]
    push ebx
    mov ebx, dword [vr13]
    and dword [vr14], ebx
    pop ebx
    jmp .probe
.missing:
    mov eax, -1
    XENDF

XFUNC var_insert
    mov dword [vr12], ecx
    mov dword [vr13], edx
    call var_lookup
    mov eax, [g_nvars]
    mov dword [vr14], eax
    inc dword [g_nvars]
    mov ecx, [last_slot]
    lea edx, [eax + 1]
    mov [ecx], edx
    shl eax, 5
    add eax, [g_vars]
    mov ebx, eax
    mov ecx, [last_hash]
    mov [ebx + VR_HASH], ecx
    push esi
    mov esi, dword [vr12]
    mov [ebx + VR_TOK], esi
    pop esi
    push esi
    mov si, word [vr13]
    mov [ebx + VR_TYPE], si
    pop esi
    mov ecx, 4
    mov edx, 4
    cmp dword [vr13], TY_INT
    je .size
    mov ecx, 1
    mov edx, 1
    cmp dword [vr13], TY_BOOL
    je .size
    mov ecx, 16
    mov edx, 16
.size:
    mov eax, [g_vars_size]
    lea eax, [eax + ecx - 1]
    neg ecx
    and eax, ecx
    mov [ebx + VR_OFF], eax
    add eax, edx
    mov [g_vars_size], eax
    mov eax, dword [vr14]
    XENDF

XFUNC check_value
    mov ebx, ecx
    movzx eax, byte [ebx + V_TYPE]
    test eax, eax
    jnz .already
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_INT
    je .int
    cmp eax, VK_STR
    je .str
    cmp eax, VK_VAR
    je .var
    cmp eax, VK_EXPR
    je .expr
    mov dword [vr12], TY_BOOL
    cmp eax, VK_BOOL
    je .done
    mov dword [vr12], TY_NULL
    jmp .done

.int:
    mov dword [vr12], TY_INT
    mov ecx, [ebx + V_TOK]
    call tok_text
    push ebx
    mov ebx, dword [vr8]
    xor dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr9]
    xor dword [vr9], ebx
    pop ebx
    mov dword [vr10], 0xFFFFFFFF
.digit:
    cmp dword [vr9], edx
    jae .digits_done
    push ebx
    mov ebx, [vr9]
    movzx ecx, byte [eax + ebx]
    pop ebx
    sub ecx, '0'
    inc dword [vr9]
    cmp dword [vr8], 429496729
    ja .int_sat
    push ebx
    imul ebx, dword [vr8], 10
    mov dword [vr8], ebx
    pop ebx
    add dword [vr8], ecx
    jc .int_sat
    jmp .digit
.int_sat:
    mov dword [vr8], 0xFFFFFFFF
    jmp .digit
.digits_done:
    cmp byte [ebx + V_NEG], 0
    jne .int_neg
    cmp dword [vr8], 2147483647
    ja .int_bad
    push esi
    mov esi, dword [vr8]
    mov [ebx + V_DATA], esi
    pop esi
    jmp .done
.int_neg:
    mov dword [vr11], 2147483648
    push ebx
    mov ebx, dword [vr11]
    cmp dword [vr8], ebx
    pop ebx
    ja .int_bad
    neg dword [vr8]
    push esi
    mov esi, dword [vr8]
    mov [ebx + V_DATA], esi
    pop esi
    jmp .done
.int_bad:
    mov byte [ebx + V_BAD], 1
    jmp .done

.str:
    mov dword [vr12], TY_STR
    mov ecx, [ebx + V_TOK]
    call tok_text
    lea esi, [eax + 1]
    lea edi, [eax + edx - 1]
    push ebx
    mov ebx, [g_pool_len]
    mov dword [vr13], ebx
    pop ebx
    push ebx
    mov ebx, [g_pool]
    mov dword [vr14], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr13]
    add dword [vr14], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr14]
    mov dword [vr15], ebx
    pop ebx
.dec:
    cmp esi, edi
    jae .dec_done
    mov al, [esi]
    inc esi
    cmp al, '\'
    jne .dec_put
    mov al, [esi]
    inc esi
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
    push ebx
    mov ebx, [vr15]
    mov [ebx], al
    pop ebx
    inc dword [vr15]
    jmp .dec
.dec_done:
    push ebx
    mov ebx, dword [vr14]
    sub dword [vr15], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr15]
    add [g_pool_len], ebx
    pop ebx
    push esi
    mov esi, dword [vr13]
    mov [ebx + V_DATA], esi
    pop esi
    push esi
    mov esi, dword [vr15]
    mov [ebx + V_DATA + 4], esi
    pop esi
    cmp dword [vr15], 65535
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
    push ebx
    movzx ebx, word [eax + VR_TYPE]
    mov dword [vr12], ebx
    pop ebx
    jmp .done
.undefined:
    call msg_reset
    lea ecx, [s_undef]
    call msg_addz
    mov ecx, [ebx + V_TOK]
    call msg_tok
    lea ecx, [s_quote]
    call msg_addz
    lea ecx, [s_semantic]
    mov edx, [ebx + V_TOK]
    call diag_error_tok

.expr:
    mov ecx, ebx
    call check_expr
    mov dword [vr12], eax

.done:
    push ecx
    mov cl, byte [vr12]
    mov [ebx + V_TYPE], cl
    pop ecx
    mov eax, dword [vr12]
    XENDF
.already:
    XENDF

XFUNC value_finish
    mov ebx, ecx
    cmp byte [ebx + V_BAD], 0
    je .ok
    call msg_reset
    cmp byte [ebx + V_KIND], VK_INT
    jne .str
    lea ecx, [s_int_lit]
    call msg_addz
    cmp byte [ebx + V_NEG], 0
    je .digits
    mov cl, '-'
    call msg_addc
.digits:
    mov ecx, [ebx + V_TOK]
    call msg_tok
    lea ecx, [s_outside]
    call msg_addz
    jmp .err
.str:
    lea ecx, [s_str_long]
    call msg_addz
.err:
    mov ecx, ebx
    call value_pos
    lea ecx, [s_type]
    call diag_error_tok
.ok:
    XENDF

XFUNC check_assign
    mov ebx, ecx
    mov dword [vr12], edx
    push ebx
    mov ebx, dword [vr8]
    mov dword [vr13], ebx
    pop ebx
    call check_value
    cmp eax, dword [vr12]
    je .ok
    cmp eax, TY_NULL
    jne .bad
    cmp dword [vr12], TY_STR
    je .ok
.bad:
    mov dword [vr14], eax
    call msg_reset
    lea ecx, [s_cannot]
    call msg_addz
    mov ecx, dword [vr14]
    call type_name
    mov ecx, eax
    call msg_addz
    lea ecx, [s_to]
    call msg_addz
    mov ecx, dword [vr12]
    call type_name
    mov ecx, eax
    call msg_addz
    lea ecx, [s_variable_q]
    call msg_addz
    mov ecx, dword [vr13]
    call msg_tok
    lea ecx, [s_quote]
    call msg_addz
    mov ecx, ebx
    call value_pos
    lea ecx, [s_type]
    call diag_error_tok
.ok:
    mov ecx, ebx
    call value_finish
    XENDF

XFUNC sema
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

    mov dword [sm_bdepth], 0
    push ebx
    mov ebx, [g_stmts]
    mov dword [vr12], ebx
    pop ebx
    push ebx
    mov ebx, [g_nstmt]
    mov dword [vr13], ebx
    pop ebx
    shl dword [vr13], 5
    push ebx
    mov ebx, dword [vr12]
    add dword [vr13], ebx
    pop ebx
.stmt:
    push ebx
    mov ebx, dword [vr13]
    cmp dword [vr12], ebx
    pop ebx
    jae .finish
    mov eax, dword [vr12]
    sub eax, [g_stmts]
    shr eax, 5
.block_end:
    mov ecx, [sm_bdepth]
    test ecx, ecx
    jz .block_ok
    lea edx, [sm_bstack]
    cmp [edx + ecx * 8 - 8], eax
    jne .block_ok
    dec dword [sm_bdepth]
    mov dword [sm_carry], 0
    jmp .block_end
.block_ok:
    push ebx
    mov ebx, [vr12]
    movzx eax, word [ebx + S_KIND]
    pop ebx
    cmp eax, SK_IF
    je .if_stmt
    cmp eax, SK_ELSE
    je .else_stmt
    cmp eax, SK_FOR
    je .loop_stmt
    cmp eax, SK_LOOPS
    je .loop_stmt
    cmp eax, SK_DECL
    je .decl
    cmp eax, SK_ASSIGN
    je .assign
    jmp .out

.decl:
    mov dword [sm_carry], 0
    cmp dword [sm_bdepth], 0
    jne .decl_in_block
.decl_top:
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call var_lookup
    mov dword [vr14], eax
    cmp eax, -1
    je .decl_value
    shl eax, 5
    add eax, [g_vars]
    mov ebx, eax
    movzx eax, word [ebx + VR_TYPE]
    push ebx
    mov ebx, [vr12]
    movzx ecx, word [ebx + S_MODE]
    pop ebx
    cmp eax, ecx
    jne .redecl_type
    call msg_reset
    lea ecx, [s_var_q]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call msg_tok
    lea ecx, [s_already_at]
    call msg_addz
    mov ecx, [ebx + VR_LINE]
    call msg_addu
    lea ecx, [s_latest]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call diag_warn_tok
.decl_value:
    push ebx
    mov ebx, [vr12]
    cmp dword [ebx + S_NPARTS], 0
    pop ebx
    je .decl_store
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    shl ecx, 4
    add ecx, [g_parts]
    push ebx
    mov ebx, [vr12]
    movzx edx, word [ebx + S_MODE]
    pop ebx
    push ebx
    push esi
    mov ebx, [vr12]
    mov esi, [ebx + S_TOK]
    mov dword [vr8], esi
    pop esi
    pop ebx
    call check_assign
.decl_store:
    cmp dword [vr14], -1
    jne .decl_known
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    push ebx
    mov ebx, [vr12]
    movzx edx, word [ebx + S_MODE]
    pop ebx
    call var_insert
    mov dword [vr14], eax
.decl_known:
    push ebx
    push esi
    mov ebx, [vr12]
    mov esi, dword [vr14]
    mov [ebx + S_VAR], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call tok_line
    mov ecx, dword [vr14]
    shl ecx, 5
    add ecx, [g_vars]
    mov [ecx + VR_LINE], eax
    jmp .next

.redecl_type:
    mov dword [vr15], eax
    call msg_reset
    lea ecx, [s_var_q]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call msg_tok
    lea ecx, [s_already_as]
    call msg_addz
    lea ecx, [s_an_int]
    cmp dword [vr15], TY_INT
    je .redecl_msg
    lea ecx, [s_a_str]
    cmp dword [vr15], TY_STR
    je .redecl_msg
    lea ecx, [s_a_bool]
.redecl_msg:
    call msg_addz
    lea ecx, [s_semantic]
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + S_TOK]
    pop ebx
    call diag_error_tok

.decl_in_block:
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + S_MODE], TY_STR
    pop ebx
    je .str_in_block
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call var_lookup
    cmp eax, -1
    je .undeclared_in_block
    shl eax, 5
    add eax, [g_vars]
    movzx eax, word [eax + VR_TYPE]
    push ebx
    mov ebx, [vr12]
    movzx ecx, word [ebx + S_MODE]
    pop ebx
    cmp eax, ecx
    jne .decl_top
    push ebx
    mov ebx, [vr12]
    mov word [ebx + S_KIND], SK_ASSIGN
    pop ebx
    jmp .assign
.str_in_block:
    call msg_reset
    lea ecx, [s_str_if1]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call msg_tok
    lea ecx, [s_str_if2]
    call block_is_loop
    jne .str_msg
    lea ecx, [s_str_loop2]
.str_msg:
    call msg_addz
    lea ecx, [s_semantic]
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + S_TOK]
    pop ebx
    call diag_error_tok
.undeclared_in_block:
    call msg_reset
    lea ecx, [s_in_if1]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call msg_tok
    lea ecx, [s_in_if2]
    call block_is_loop
    jne .undecl_msg
    lea ecx, [s_in_loop2]
.undecl_msg:
    call msg_addz
    lea ecx, [s_semantic]
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + S_TOK]
    pop ebx
    call diag_error_tok

.if_stmt:
    mov dword [sm_carry], 0
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    shl ecx, 4
    add ecx, [g_parts]
    call check_cond
    mov ecx, [sm_bdepth]
    lea edx, [sm_bstack]
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PIECES]
    pop ebx
    mov [edx + ecx * 8], eax
    lea edx, [sm_bkind]
    mov dword [edx + ecx * 8], BK_IF
    inc dword [sm_bdepth]
    jmp .next

.else_stmt:
    mov dword [sm_carry], 0
    mov ecx, [sm_bdepth]
    lea edx, [sm_bstack]
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PIECES]
    pop ebx
    mov [edx + ecx * 8], eax
    lea edx, [sm_bkind]
    mov dword [edx + ecx * 8], BK_IF
    inc dword [sm_bdepth]
    jmp .next

.loop_stmt:
    mov dword [sm_carry], 0
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    shl ecx, 4
    add ecx, [g_parts]
    mov ebx, ecx
    call check_value
    mov dword [vr14], eax
    mov ecx, ebx
    call value_finish
    cmp dword [vr14], TY_INT
    jne .bad_count
    mov eax, [g_vars_size]
    add eax, 3
    and eax, -4
    push ebx
    mov ebx, [vr12]
    mov [ebx + S_NPIECES], eax
    pop ebx
    add eax, 8
    mov [g_vars_size], eax
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + S_KIND], SK_FOR
    pop ebx
    jne .loop_push
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call var_lookup
    cmp eax, -1
    je .loop_new_var
    mov dword [vr15], eax
    shl eax, 5
    add eax, [g_vars]
    movzx ecx, word [eax + VR_TYPE]
    cmp ecx, TY_INT
    jne .bad_loop_var
    push ebx
    push esi
    mov ebx, [vr12]
    mov esi, dword [vr15]
    mov [ebx + S_VAR], esi
    pop esi
    pop ebx
    jmp .loop_push
.loop_new_var:
    cmp dword [sm_bdepth], 0
    jne .undeclared_in_block
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    mov edx, TY_INT
    call var_insert
    push ebx
    mov ebx, [vr12]
    mov [ebx + S_VAR], eax
    pop ebx
    mov dword [vr15], eax
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call tok_line
    mov ecx, dword [vr15]
    shl ecx, 5
    add ecx, [g_vars]
    mov [ecx + VR_LINE], eax
.loop_push:
    mov ecx, [sm_bdepth]
    lea edx, [sm_bstack]
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PIECES]
    pop ebx
    mov [edx + ecx * 8], eax
    lea edx, [sm_bkind]
    mov dword [edx + ecx * 8], BK_LOOP
    inc dword [sm_bdepth]
    jmp .next
.bad_count:
    call msg_reset
    lea ecx, [s_count1]
    call msg_addz
    mov ecx, dword [vr14]
    call type_name
    mov ecx, eax
    call msg_addz
    mov ecx, ebx
    call value_pos
    lea ecx, [s_type]
    call diag_error_tok
.bad_loop_var:
    mov dword [vr14], ecx
    call msg_reset
    lea ecx, [s_lvar1]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call msg_tok
    lea ecx, [s_lvar2]
    call msg_addz
    lea ecx, [s_an_int]
    cmp dword [vr14], TY_INT
    je .lv_msg
    lea ecx, [s_a_str]
    cmp dword [vr14], TY_STR
    je .lv_msg
    lea ecx, [s_a_bool]
.lv_msg:
    call msg_addz
    lea ecx, [s_semantic]
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + S_TOK]
    pop ebx
    call diag_error_tok

.assign:
    mov dword [sm_carry], 0
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call var_lookup
    cmp eax, -1
    jne .assign_ok
    call msg_reset
    lea ecx, [s_undef]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_TOK]
    pop ebx
    call msg_tok
    lea ecx, [s_quote]
    call msg_addz
    lea ecx, [s_semantic]
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + S_TOK]
    pop ebx
    call diag_error_tok
.assign_ok:
    push ebx
    mov ebx, [vr12]
    mov [ebx + S_VAR], eax
    pop ebx
    shl eax, 5
    add eax, [g_vars]
    movzx edx, word [eax + VR_TYPE]
    push ebx
    mov ebx, [vr12]
    mov [ebx + S_MODE], dx
    pop ebx
    push ebx
    mov ebx, [vr12]
    cmp dword [ebx + S_NPARTS], 0
    pop ebx
    je .next
    mov dword [vr14], edx
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    shl ecx, 4
    add ecx, [g_parts]
    mov edx, dword [vr14]
    push ebx
    push esi
    mov ebx, [vr12]
    mov esi, [ebx + S_TOK]
    mov dword [vr8], esi
    pop esi
    pop ebx
    call check_assign
    jmp .next

.out:
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_MODETOK]
    pop ebx
    cmp ecx, NO_TOKEN
    je .out_parts
    call tok_text
    cmp edx, 1
    jne .bad_mode
    cmp byte [eax], 's'
    je .out_parts
.bad_mode:
    call msg_reset
    lea ecx, [s_mode1]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + S_MODETOK]
    pop ebx
    call msg_tok
    lea ecx, [s_mode2]
    call msg_addz
    lea ecx, [s_semantic]
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + S_MODETOK]
    pop ebx
    dec edx
    call diag_error_tok

.out_parts:
    mov eax, [g_npieces]
    push ebx
    mov ebx, [vr12]
    mov [ebx + S_PIECES], eax
    pop ebx
    push ebx
    mov ebx, [sm_carry]
    mov dword [vr15], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr14]
    xor dword [vr14], ebx
    pop ebx
.part:
    push ebx
    push esi
    mov ebx, [vr12]
    mov esi, [ebx + S_NPARTS]
    cmp dword [vr14], esi
    pop esi
    pop ebx
    jae .parts_done
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    add eax, dword [vr14]
    mov edx, [g_roots]
    mov ebx, [edx + eax * 4]
    shl ebx, 4
    add ebx, [g_parts]
    mov esi, [g_pool_len]
    mov ecx, ebx
    call check_value
    mov edi, eax
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
    lea ecx, [s_null]
    mov edx, 4
    call pool_add
    jmp .part_text
.part_bool:
    lea ecx, [s_true]
    mov edx, 4
    cmp dword [ebx + V_DATA], 0
    jne .part_bool_add
    lea ecx, [s_false]
    mov edx, 5
.part_bool_add:
    call pool_add
    jmp .part_text
.part_int:
    mov eax, [ebx + V_DATA]
    test eax, eax
    jns .part_int_pos
    lea ecx, [s_minus_char]
    mov edx, 1
    call pool_add
    mov ecx, [ebx + V_DATA]
    neg ecx
    jmp .part_int_dec
.part_int_pos:
    mov ecx, eax
.part_int_dec:
    call u32_to_dec
    mov ecx, eax
    call pool_add
.part_text:
    push ebx
    mov ebx, dword [vr15]
    test dword [vr15], ebx
    pop ebx
    jnz .part_extend
    mov ecx, PK_TEXT
    mov edx, esi
    call new_piece
    mov dword [vr15], eax
.part_extend:
    mov eax, [g_pool_len]
    push ebx
    mov ebx, [vr15]
    sub eax, [ebx + P_A]
    pop ebx
    push ebx
    mov ebx, [vr15]
    mov [ebx + P_B], eax
    pop ebx
    jmp .part_next
.part_var:
    push ebx
    mov ebx, dword [vr15]
    xor dword [vr15], ebx
    pop ebx
    mov eax, [ebx + V_DATA]
    shl eax, 5
    add eax, [g_vars]
    mov edx, [eax + VR_OFF]
    mov ecx, PK_INT
    cmp edi, TY_INT
    je .part_var_add
    mov ecx, PK_BOOL
    cmp edi, TY_BOOL
    je .part_var_add
    mov ecx, PK_STR
.part_var_add:
    call new_piece
    jmp .part_next
.part_expr:
    push ebx
    mov ebx, dword [vr15]
    xor dword [vr15], ebx
    pop ebx
    mov edx, ebx
    sub edx, [g_parts]
    shr edx, 4
    mov ecx, PK_EXPR
    call new_piece
.part_next:
    inc dword [vr14]
    jmp .part

.parts_done:
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + S_MODE], 0
    pop ebx
    jne .out_count
    push ebx
    mov ebx, dword [vr15]
    test dword [vr15], ebx
    pop ebx
    jnz .crlf
    mov ecx, PK_TEXT
    mov edx, [g_pool_len]
    call new_piece
    mov dword [vr15], eax
.crlf:
    lea ecx, [s_crlf]
    mov edx, 1
    call pool_add
    mov eax, [g_pool_len]
    push ebx
    mov ebx, [vr15]
    sub eax, [ebx + P_A]
    pop ebx
    push ebx
    mov ebx, [vr15]
    mov [ebx + P_B], eax
    pop ebx
.out_count:
    push ebx
    mov ebx, dword [vr15]
    mov [sm_carry], ebx
    pop ebx
    mov eax, [g_npieces]
    push ebx
    mov ebx, [vr12]
    sub eax, [ebx + S_PIECES]
    pop ebx
    push ebx
    mov ebx, [vr12]
    mov [ebx + S_NPIECES], eax
    pop ebx

.next:
    add dword [vr12], S_SIZE
    jmp .stmt
.finish:
    XENDF

section .rodata
s_minus_char db "-"

section .bss
alignb 8
pc_new  resq 1
pc_len  resq 1
pc_tab  resq 1
pc_mask resq 1

section .text

XFUNC pool_compact
    mov ecx, [g_pool_len]
    add ecx, 16
    call mem_alloc
    mov [pc_new], eax
    mov dword [pc_len], 0
    mov ecx, [g_npieces]
    add ecx, [g_nstmt]
    shl ecx, 1
    mov eax, 16
.cap:
    cmp eax, ecx
    jae .cap_ok
    shl eax, 1
    jmp .cap
.cap_ok:
    lea edx, [eax - 1]
    mov [pc_mask], edx
    shl eax, 4
    mov ecx, eax
    call mem_alloc
    mov [pc_tab], eax

    push ebx
    mov ebx, [g_pieces]
    mov dword [vr12], ebx
    pop ebx
    push ebx
    mov ebx, [g_npieces]
    mov dword [vr13], ebx
    pop ebx
    shl dword [vr13], 4
    push ebx
    mov ebx, dword [vr12]
    add dword [vr13], ebx
    pop ebx
.pieces:
    push ebx
    mov ebx, dword [vr13]
    cmp dword [vr12], ebx
    pop ebx
    jae .stmts
    push ebx
    mov ebx, [vr12]
    cmp dword [ebx + P_KIND], PK_TEXT
    pop ebx
    jne .piece_next
    push ebx
    mov ebx, [vr12]
    mov ecx, [ebx + P_A]
    pop ebx
    push ebx
    mov ebx, [vr12]
    mov edx, [ebx + P_B]
    pop ebx
    call intern
    push ebx
    mov ebx, [vr12]
    mov [ebx + P_A], eax
    pop ebx
.piece_next:
    add dword [vr12], P_SIZE
    jmp .pieces

.stmts:
    push ebx
    mov ebx, [g_stmts]
    mov dword [vr12], ebx
    pop ebx
    push ebx
    mov ebx, [g_nstmt]
    mov dword [vr13], ebx
    pop ebx
    shl dword [vr13], 5
    push ebx
    mov ebx, dword [vr12]
    add dword [vr13], ebx
    pop ebx
.stmt:
    push ebx
    mov ebx, dword [vr13]
    cmp dword [vr12], ebx
    pop ebx
    jae .done
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + S_KIND], SK_OUT
    pop ebx
    je .stmt_next
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + S_KIND], SK_IF
    pop ebx
    je .stmt_if
    push ebx
    mov ebx, [vr12]
    cmp dword [ebx + S_NPARTS], 0
    pop ebx
    je .stmt_next
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    mov edx, [g_roots]
    mov eax, [edx + eax * 4]
    shl eax, 4
    add eax, [g_parts]
    mov dword [vr14], eax
    mov ecx, dword [vr14]
    call intern_tree
    jmp .stmt_next
.stmt_if:
    push ebx
    mov ebx, [vr12]
    mov eax, [ebx + S_PARTS]
    pop ebx
    mov edx, [g_roots]
    mov eax, [edx + eax * 4]
    shl eax, 4
    add eax, [g_parts]
    mov ecx, eax
    call intern_tree
.stmt_next:
    add dword [vr12], S_SIZE
    jmp .stmt
.done:
    mov eax, [pc_new]
    mov [g_pool], eax
    mov eax, [pc_len]
    mov [g_pool_len], eax
    XENDF

XFUNC intern
    mov dword [vr12], ecx
    mov dword [vr13], edx
    mov esi, [g_pool]
    add esi, dword [vr12]
    mov dword [vr9], 0x01000193
    mov ebx, dword [vr13]
    imul ebx, dword [vr9]
    xor ecx, ecx
.hash:
    cmp ecx, dword [vr13]
    jae .hashed
    mov eax, [esi + ecx]
    mov edx, dword [vr13]
    sub edx, ecx
    cmp edx, 8
    jae .hash_full
    push ecx
    lea ecx, [edx * 8]
    mov edx, -1
    shl edx, cl
    not edx
    and eax, edx
    pop ecx
.hash_full:
    xor ebx, eax
    imul ebx, dword [vr9]
    add ecx, 8
    jmp .hash
.hashed:
    mov dword [vr14], ebx
    push ebx
    mov ebx, [pc_mask]
    and dword [vr14], ebx
    pop ebx
.probe:
    push ebx
    mov ebx, dword [vr14]
    mov dword [vr15], ebx
    pop ebx
    shl dword [vr15], 4
    push ebx
    mov ebx, [pc_tab]
    add dword [vr15], ebx
    pop ebx
    push ebx
    mov ebx, [vr15]
    mov eax, [ebx + 8]
    pop ebx
    test eax, eax
    jz .insert
    push esi
    mov esi, [vr15]
    cmp [esi], ebx
    pop esi
    jne .next
    push ebx
    push esi
    mov ebx, [vr15]
    mov esi, dword [vr13]
    cmp [ebx + 12], esi
    pop esi
    pop ebx
    jne .next
    lea edi, [eax - 1]
    add edi, [pc_new]
    xor ecx, ecx
.cmp_loop:
    cmp ecx, dword [vr13]
    jae .cmp_equal
    mov eax, [esi + ecx]
    xor eax, [edi + ecx]
    mov edx, dword [vr13]
    sub edx, ecx
    cmp edx, 8
    jae .cmp_full
    push ecx
    lea ecx, [edx * 8]
    mov edx, -1
    shl edx, cl
    not edx
    and eax, edx
    pop ecx
.cmp_full:
    test eax, eax
    jnz .next
    add ecx, 8
    jmp .cmp_loop
.cmp_equal:
    push ebx
    mov ebx, [vr15]
    mov eax, [ebx + 8]
    pop ebx
    dec eax
    XENDF
.next:
    inc dword [vr14]
    push ebx
    mov ebx, [pc_mask]
    and dword [vr14], ebx
    pop ebx
    jmp .probe
.insert:
    mov edi, [pc_new]
    add edi, [pc_len]
    mov ecx, dword [vr13]
    rep movsb
    mov eax, [pc_len]
    push esi
    mov esi, [vr15]
    mov [esi], ebx
    pop esi
    lea edx, [eax + 1]
    push ebx
    mov ebx, [vr15]
    mov [ebx + 8], edx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr15]
    mov esi, dword [vr13]
    mov [ebx + 12], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, dword [vr13]
    add [pc_len], ebx
    pop ebx
    XENDF

make_bool_const:
    mov byte [ebx + V_KIND], VK_BOOL
    mov byte [ebx + V_TYPE], TY_BOOL
    mov byte [ebx + V_NEG], 0
    mov byte [ebx + V_BAD], 0
    mov [ebx + V_DATA], eax
    ret

pool_equal:
    mov eax, [ecx + V_DATA + 4]
    cmp eax, [edx + V_DATA + 4]
    jne .no
    push ebx
    mov ebx, [ecx + V_DATA]
    mov dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, [edx + V_DATA]
    mov dword [vr9], ebx
    pop ebx
    push ebx
    mov ebx, [g_pool]
    add dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, [g_pool]
    add dword [vr9], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr10]
    xor dword [vr10], ebx
    pop ebx
.loop:
    cmp dword [vr10], eax
    jae .yes
    push ebx
    push esi
    push ecx
    mov ebx, [vr8]
    mov esi, [vr10]
    mov cl, [ebx + esi]
    mov byte [vr11], cl
    pop ecx
    pop esi
    pop ebx
    push ebx
    push esi
    push ecx
    mov ebx, [vr9]
    mov esi, [vr10]
    mov cl, [ebx + esi]
    cmp byte [vr11], cl
    pop ecx
    pop esi
    pop ebx
    jne .no
    inc dword [vr10]
    jmp .loop
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

XFUNC check_cond
    mov ebx, ecx
    cmp byte [ebx + V_KIND], VK_OR
    je .or
    cmp byte [ebx + V_KIND], VK_AND
    je .and
    push esi
    movzx esi, byte [ebx + V_NEG]
    mov dword [vr12], esi
    pop esi
    mov ecx, [ebx + V_DATA]
    call node_ptr
    mov dword [vr13], eax
    mov ecx, dword [vr13]
    call check_value
    mov dword [vr14], eax
    mov ecx, dword [vr13]
    call value_finish
    mov ecx, [ebx + V_DATA + 4]
    call node_ptr
    mov dword [vr15], eax
    mov ecx, dword [vr15]
    call check_value
    mov esi, eax
    mov ecx, dword [vr15]
    call value_finish
    cmp dword [vr12], CMP_LT
    jae .ordered
    cmp dword [vr14], esi
    je .types_ok
    mov eax, dword [vr14]
    or eax, esi
    cmp dword [vr14], TY_NULL
    je .one_null
    cmp esi, TY_NULL
    jne .bad_compare
.one_null:
    cmp dword [vr14], TY_STR
    je .types_ok
    cmp esi, TY_STR
    je .types_ok
    jmp .bad_compare
.ordered:
    cmp dword [vr14], TY_INT
    jne .bad_ordered_left
    cmp esi, TY_INT
    jne .bad_ordered_right
.types_ok:
    mov eax, dword [vr14]
    cmp eax, TY_NULL
    jne .store_type
    mov eax, esi
.store_type:
    mov [ebx + V_TYPE], al
    push ebx
    mov ebx, [vr13]
    movzx edi, byte [ebx + V_KIND]
    pop ebx
    push ebx
    mov ebx, [vr15]
    movzx ecx, byte [ebx + V_KIND]
    pop ebx
    cmp eax, TY_STR
    je .fold_str
    cmp eax, TY_NULL
    je .fold_null_null
    cmp edi, ecx
    jne .done
    cmp edi, VK_INT
    je .fold_num
    cmp edi, VK_BOOL
    je .fold_num
    jmp .done
.fold_num:
    push ebx
    push esi
    mov ebx, [vr13]
    mov esi, [ebx + V_DATA]
    mov dword [vr8], esi
    pop esi
    pop ebx
    push ebx
    push esi
    mov ebx, [vr15]
    mov esi, [ebx + V_DATA]
    mov dword [vr9], esi
    pop esi
    pop ebx
    xor eax, eax
    cmp dword [vr12], CMP_IS
    je .f_is
    cmp dword [vr12], CMP_ISNOT
    je .f_isnot
    cmp dword [vr12], CMP_LT
    je .f_lt
    cmp dword [vr12], CMP_LE
    je .f_le
    cmp dword [vr12], CMP_GE
    je .f_ge
    push ebx
    mov ebx, dword [vr9]
    cmp dword [vr8], ebx
    pop ebx
    setg al
    jmp .fold_set
.f_is:
    push ebx
    mov ebx, dword [vr9]
    cmp dword [vr8], ebx
    pop ebx
    sete al
    jmp .fold_set
.f_isnot:
    push ebx
    mov ebx, dword [vr9]
    cmp dword [vr8], ebx
    pop ebx
    setne al
    jmp .fold_set
.f_lt:
    push ebx
    mov ebx, dword [vr9]
    cmp dword [vr8], ebx
    pop ebx
    setl al
    jmp .fold_set
.f_le:
    push ebx
    mov ebx, dword [vr9]
    cmp dword [vr8], ebx
    pop ebx
    setle al
    jmp .fold_set
.f_ge:
    push ebx
    mov ebx, dword [vr9]
    cmp dword [vr8], ebx
    pop ebx
    setge al
    jmp .fold_set
.fold_null_null:
    mov eax, 1
    jmp .fold_eq
.fold_str:
    cmp edi, VK_VAR
    je .done
    cmp ecx, VK_VAR
    je .done
    cmp edi, ecx
    jne .fold_diff
    cmp edi, VK_NULL
    je .fold_same
    mov ecx, dword [vr13]
    mov edx, dword [vr15]
    call pool_equal
    jmp .fold_eq
.fold_same:
    mov eax, 1
    jmp .fold_eq
.fold_diff:
    xor eax, eax
.fold_eq:
    cmp dword [vr12], CMP_ISNOT
    jne .fold_set
    xor eax, 1
.fold_set:
    movzx eax, al
    call make_bool_const
.done:
    XENDF

.or:
    mov ecx, [ebx + V_DATA]
    call node_ptr
    mov dword [vr13], eax
    mov ecx, dword [vr13]
    call check_cond
    mov ecx, [ebx + V_DATA + 4]
    call node_ptr
    mov dword [vr15], eax
    mov ecx, dword [vr15]
    call check_cond
    push ebx
    mov ebx, [vr13]
    cmp byte [ebx + V_KIND], VK_BOOL
    pop ebx
    jne .or_right
    push ebx
    mov ebx, [vr13]
    cmp dword [ebx + V_DATA], 0
    pop ebx
    jne .or_true
    mov ecx, dword [vr15]
    call copy_node
    XENDF
.or_right:
    push ebx
    mov ebx, [vr15]
    cmp byte [ebx + V_KIND], VK_BOOL
    pop ebx
    jne .or_done
    push ebx
    mov ebx, [vr15]
    cmp dword [ebx + V_DATA], 0
    pop ebx
    jne .or_true
    mov ecx, dword [vr13]
    call copy_node
    XENDF
.or_true:
    mov eax, 1
    call make_bool_const
.or_done:
    XENDF

.and:
    mov ecx, [ebx + V_DATA]
    call node_ptr
    mov dword [vr13], eax
    mov ecx, dword [vr13]
    call check_cond
    mov ecx, [ebx + V_DATA + 4]
    call node_ptr
    mov dword [vr15], eax
    mov ecx, dword [vr15]
    call check_cond
    push ebx
    mov ebx, [vr13]
    cmp byte [ebx + V_KIND], VK_BOOL
    pop ebx
    jne .and_right
    push ebx
    mov ebx, [vr13]
    cmp dword [ebx + V_DATA], 0
    pop ebx
    je .and_false
    mov ecx, dword [vr15]
    call copy_node
    XENDF
.and_right:
    push ebx
    mov ebx, [vr15]
    cmp byte [ebx + V_KIND], VK_BOOL
    pop ebx
    jne .and_done
    push ebx
    mov ebx, [vr15]
    cmp dword [ebx + V_DATA], 0
    pop ebx
    je .and_false
    mov ecx, dword [vr13]
    call copy_node
    XENDF
.and_false:
    xor eax, eax
    call make_bool_const
.and_done:
    XENDF

.bad_ordered_left:
    mov esi, dword [vr14]
.bad_ordered_right:
    call msg_reset
    lea ecx, [s_operator]
    call msg_addz
    lea eax, [cmp_chars]
    push ebx
    mov ebx, [vr12]
    mov cl, [eax + ebx]
    pop ebx
    call msg_addc
    cmp dword [vr12], CMP_LE
    jb .op_done
    mov cl, '='
    call msg_addc
.op_done:
    lea ecx, [s_needs_bin]
    call msg_addz
    mov ecx, esi
    call type_name
    mov ecx, eax
    call msg_addz
    lea ecx, [s_type]
    mov edx, [ebx + V_TOK]
    call diag_error_tok

.bad_compare:
    call msg_reset
    lea ecx, [s_cmp1]
    call msg_addz
    mov ecx, dword [vr14]
    call type_name
    mov ecx, eax
    call msg_addz
    lea ecx, [s_with]
    call msg_addz
    mov ecx, esi
    call type_name
    mov ecx, eax
    call msg_addz
    lea ecx, [s_type]
    mov edx, [ebx + V_TOK]
    call diag_error_tok

XFUNC intern_tree
    mov ebx, ecx
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_CMP
    je .pair
    cmp eax, VK_OR
    je .pair
    cmp eax, VK_AND
    je .pair
    cmp eax, VK_STR
    jne .done
    cmp byte [ebx + V_NEG], 0
    jne .done
    mov ecx, [ebx + V_DATA]
    mov edx, [ebx + V_DATA + 4]
    call intern
    mov [ebx + V_DATA], eax
    mov byte [ebx + V_NEG], 1
    jmp .done
.pair:
    mov ecx, [ebx + V_DATA]
    call node_ptr
    mov ecx, eax
    call intern_tree
    mov ecx, [ebx + V_DATA + 4]
    call node_ptr
    mov ecx, eax
    call intern_tree
.done:
    XENDF

block_is_loop:
    mov eax, [sm_bdepth]
    lea edx, [sm_bkind]
    cmp dword [edx + eax * 8 - 8], BK_LOOP
    ret
