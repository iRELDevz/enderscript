%include "defs.inc"
%include "state.inc"

extern u64_to_dec

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
s_cmp1       db "cannot compare ", 0
s_with       db " with ", 0
s_in_if1     db "variable '", 0
s_in_if2     db "' must be declared before the if block", 0
s_str_if1    db "cannot declare str variable '", 0
s_str_if2    db "' inside an if block", 0
s_in_loop2   db "' must be declared before the loop", 0
s_str_loop2  db "' inside a loop", 0
s_count1     db "loop count must be int, got ", 0
s_in_bool    db "cannot read input into bool variable '", 0
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
s_crlf       db 13, 10

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
    shl rax, 4
    add rax, [g_tokens]
    mov edx, [rax + T_LEN]
    mov eax, [rax + T_OFF]
    add rax, [g_src]
    ret

tok_line:
    mov eax, ecx
    shl rax, 4
    add rax, [g_tokens]
    mov eax, [rax + T_LINE]
    ret

type_name:
    lea rax, [s_tn_int]
    cmp ecx, TY_INT
    je .r
    lea rax, [s_tn_str]
    cmp ecx, TY_STR
    je .r
    lea rax, [s_tn_bool]
    cmp ecx, TY_BOOL
    je .r
    lea rax, [s_tn_null]
.r:
    ret

pool_add:
    mov r8, [g_pool]
    add r8, [g_pool_len]
    add [g_pool_len], rdx
.loop:
    test rdx, rdx
    jz .end
    mov al, [rcx]
    mov [r8], al
    inc rcx
    inc r8
    dec rdx
    jmp .loop
.end:
    ret

new_piece:
    mov rax, [g_npieces]
    inc qword [g_npieces]
    shl rax, 4
    add rax, [g_pieces]
    mov [rax + P_KIND], ecx
    mov [rax + P_A], edx
    mov dword [rax + P_B], 0
    ret

value_pos:
    cmp byte [rcx + V_KIND], VK_EXPR
    jne .leaf
    cmp byte [rcx + V_NEG], OP_NEG
    je .neg
    mov eax, [rcx + V_DATA]
    shl rax, 4
    add rax, [g_parts]
    mov rcx, rax
    jmp value_pos
.neg:
    mov edx, [rcx + V_TOK]
    ret
.leaf:
    movzx eax, byte [rcx + V_NEG]
    mov edx, [rcx + V_TOK]
    sub edx, eax
    ret

node_ptr:
    mov eax, ecx
    shl rax, 4
    add rax, [g_parts]
    ret

set_const:
    mov rcx, rbx
    call value_pos
    mov byte [rbx + V_KIND], VK_INT
    mov byte [rbx + V_NEG], 0
    mov byte [rbx + V_BAD], 0
    mov [rbx + V_TOK], edx
    mov [rbx + V_DATA], r10
    ret

copy_node:
    mov rax, [rcx]
    mov [rbx], rax
    mov rax, [rcx + 8]
    mov [rbx + 8], rax
    ret

FUNC check_expr
    mov rbx, rcx
    movzx r12d, byte [rbx + V_NEG]
    mov ecx, [rbx + V_DATA]
    call node_ptr
    mov r13, rax
    mov rcx, r13
    call check_value
    mov r14d, eax
    mov rcx, r13
    call value_finish
    cmp r14d, TY_INT
    jne .bad_operand
    cmp r12d, OP_NEG
    je .unary
    mov ecx, [rbx + V_DATA + 4]
    call node_ptr
    mov r15, rax
    mov rcx, r15
    call check_value
    mov r14d, eax
    mov rcx, r15
    call value_finish
    cmp r14d, TY_INT
    jne .bad_operand
    xor esi, esi
    cmp byte [r13 + V_KIND], VK_INT
    jne .left_done
    or esi, 1
.left_done:
    cmp byte [r15 + V_KIND], VK_INT
    jne .right_done
    or esi, 2
.right_done:
    mov r8, [r13 + V_DATA]
    mov r9, [r15 + V_DATA]
    test esi, 2
    jz .no_zero_check
    test r9, r9
    jnz .no_zero_check
    cmp r12d, OP_DIV
    je .div_zero
    cmp r12d, OP_MOD
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
    cmp r12d, OP_ADD
    je .r_add_sub
    cmp r12d, OP_SUB
    je .r_add_sub
    cmp r12d, OP_MUL
    je .r_mul
    cmp r12d, OP_DIV
    je .r_div
    jmp .r_mod
.r_add_sub:
    test r9, r9
    jz .take_left
    jmp .int_result
.r_mul:
    test r9, r9
    jnz .r_div
    cmp byte [r13 + V_KIND], VK_VAR
    je .make_zero
    jmp .int_result
.r_div:
    cmp r9, 1
    je .take_left
    cmp r9, -1
    jne .int_result
    mov rcx, r13
    call value_pos
    mov [rbx + V_TOK], edx
    mov byte [rbx + V_NEG], OP_NEG
    mov dword [rbx + V_DATA + 4], NO_EXPR
    jmp .int_result
.r_mod:
    cmp byte [r13 + V_KIND], VK_VAR
    jne .int_result
    cmp r9, 1
    je .make_zero
    cmp r9, -1
    je .make_zero
    jmp .int_result

.left_const:
    cmp r12d, OP_ADD
    je .l_add
    cmp r12d, OP_SUB
    je .l_sub
    cmp r12d, OP_MUL
    jne .int_result
    test r8, r8
    jnz .l_mul_one
    cmp byte [r15 + V_KIND], VK_VAR
    je .make_zero
    jmp .int_result
.l_mul_one:
    cmp r8, 1
    je .take_right
    jmp .int_result
.l_add:
    test r8, r8
    jz .take_right
    jmp .int_result
.l_sub:
    test r8, r8
    jnz .int_result
    mov eax, [r13 + V_TOK]
    mov [rbx + V_TOK], eax
    mov eax, [rbx + V_DATA + 4]
    mov [rbx + V_DATA], eax
    mov byte [rbx + V_NEG], OP_NEG
    mov dword [rbx + V_DATA + 4], NO_EXPR
    jmp .int_result

.take_left:
    mov rcx, r13
    call copy_node
    jmp .int_result
.take_right:
    mov rcx, r15
    call copy_node
    jmp .int_result
.make_zero:
    xor r10d, r10d
    call set_const
    jmp .int_result

.unary:
    cmp byte [r13 + V_KIND], VK_INT
    jne .int_result
    mov r10, [r13 + V_DATA]
    neg r10
    jmp .fold_store

.fold:
    mov r10, r8
    cmp r12d, OP_ADD
    jne .f_sub
    add r10, r9
    jmp .fold_store
.f_sub:
    cmp r12d, OP_SUB
    jne .f_mul
    sub r10, r9
    jmp .fold_store
.f_mul:
    cmp r12d, OP_MUL
    jne .f_div
    imul r10, r9
    jmp .fold_store
.f_div:
    mov rax, r8
    cqo
    idiv r9
    mov r10, rax
    cmp r12d, OP_DIV
    je .fold_store
    mov r10, rdx
.fold_store:
    movsxd rax, r10d
    cmp rax, r10
    je .fold_ok
    mov r10, rax
    push r10
    push r10
    call msg_reset
    lea rcx, [s_overflow]
    call msg_addz
    mov r10, [rsp]
    test r10, r10
    jns .ov_pos
    mov cl, '-'
    call msg_addc
    mov r10, [rsp]
    neg r10
.ov_pos:
    mov rcx, r10
    call msg_addu
    mov ecx, [rbx + V_TOK]
    call diag_warn_tok
    pop r10
    pop r10
.fold_ok:
    call set_const

.int_result:
    mov eax, TY_INT
    ENDF

.div_zero:
    call msg_reset
    lea rcx, [s_div_zero]
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [rbx + V_TOK]
    call diag_error_tok

.bad_operand:
    call msg_reset
    lea rcx, [s_operator]
    call msg_addz
    lea rax, [op_chars]
    mov cl, [rax + r12]
    call msg_addc
    lea rcx, [s_needs_bin]
    cmp r12d, OP_NEG
    jne .bad_msg
    lea rcx, [s_needs_un]
.bad_msg:
    call msg_addz
    mov ecx, r14d
    call type_name
    mov rcx, rax
    call msg_addz
    lea rcx, [s_type]
    mov edx, [rbx + V_TOK]
    call diag_error_tok

FUNC var_lookup
    mov r12d, ecx
    call tok_text
    mov rsi, rax
    mov rdi, rdx
    mov rbx, 0xcbf29ce484222325
    mov r9, 0x100000001b3
    xor ecx, ecx
.hash:
    cmp rcx, rdi
    jae .hashed
    movzx eax, byte [rsi + rcx]
    xor rbx, rax
    imul rbx, r9
    inc rcx
    jmp .hash
.hashed:
    mov [last_hash], rbx
    mov r13, [g_hmask]
    mov r14, rbx
    and r14, r13
    mov r15, [g_htab]
.probe:
    lea rax, [r15 + r14 * 4]
    mov [last_slot], rax
    mov eax, [rax]
    test eax, eax
    jz .missing
    dec eax
    mov r10d, eax
    shl rax, 5
    add rax, [g_vars]
    cmp [rax + VR_HASH], rbx
    jne .next
    mov ecx, [rax + VR_TOK]
    call tok_text
    cmp rdx, rdi
    jne .next
    xor ecx, ecx
.cmp:
    cmp rcx, rdi
    jae .found
    mov r8b, [rax + rcx]
    cmp r8b, [rsi + rcx]
    jne .next
    inc rcx
    jmp .cmp
.found:
    mov eax, r10d
    ENDF
.next:
    inc r14
    and r14, r13
    jmp .probe
.missing:
    mov eax, -1
    ENDF

FUNC var_insert
    mov r12d, ecx
    mov r13d, edx
    call var_lookup
    mov rax, [g_nvars]
    mov r14, rax
    inc qword [g_nvars]
    mov rcx, [last_slot]
    lea edx, [eax + 1]
    mov [rcx], edx
    shl rax, 5
    add rax, [g_vars]
    mov rbx, rax
    mov rcx, [last_hash]
    mov [rbx + VR_HASH], rcx
    mov [rbx + VR_TOK], r12d
    mov [rbx + VR_TYPE], r13w
    mov ecx, 4
    mov edx, 4
    cmp r13d, TY_INT
    je .size
    mov ecx, 1
    mov edx, 1
    cmp r13d, TY_BOOL
    je .size
    mov ecx, 16
    mov edx, 16
.size:
    mov rax, [g_vars_size]
    lea rax, [rax + rcx - 1]
    neg rcx
    and rax, rcx
    mov [rbx + VR_OFF], eax
    add rax, rdx
    mov [g_vars_size], rax
    mov eax, r14d
    ENDF

FUNC check_value
    mov rbx, rcx
    movzx eax, byte [rbx + V_TYPE]
    test eax, eax
    jnz .already
    movzx eax, byte [rbx + V_KIND]
    cmp eax, VK_INT
    je .int
    cmp eax, VK_STR
    je .str
    cmp eax, VK_VAR
    je .var
    cmp eax, VK_EXPR
    je .expr
    cmp eax, VK_TAKE
    je .take
    mov r12d, TY_BOOL
    cmp eax, VK_BOOL
    je .done
    mov r12d, TY_NULL
    jmp .done

.int:
    mov r12d, TY_INT
    mov ecx, [rbx + V_TOK]
    call tok_text
    xor r8d, r8d
    xor r9d, r9d
    mov r10, 0xFFFFFFFF
.digit:
    cmp r9, rdx
    jae .digits_done
    movzx ecx, byte [rax + r9]
    sub ecx, '0'
    inc r9
    cmp r8, r10
    ja .digit
    imul r8, r8, 10
    add r8, rcx
    jmp .digit
.digits_done:
    cmp byte [rbx + V_NEG], 0
    jne .int_neg
    cmp r8, 2147483647
    ja .int_bad
    mov [rbx + V_DATA], r8
    jmp .done
.int_neg:
    mov r11, 2147483648
    cmp r8, r11
    ja .int_bad
    neg r8
    mov [rbx + V_DATA], r8
    jmp .done
.int_bad:
    mov byte [rbx + V_BAD], 1
    jmp .done

.str:
    mov r12d, TY_STR
    mov ecx, [rbx + V_TOK]
    call tok_text
    lea rsi, [rax + 1]
    lea rdi, [rax + rdx - 1]
    mov r13, [g_pool_len]
    mov r14, [g_pool]
    add r14, r13
    mov r15, r14
.dec:
    cmp rsi, rdi
    jae .dec_done
    mov al, [rsi]
    inc rsi
    cmp al, '\'
    jne .dec_put
    mov al, [rsi]
    inc rsi
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
    mov [r15], al
    inc r15
    jmp .dec
.dec_done:
    sub r15, r14
    add [g_pool_len], r15
    mov rax, r15
    shl rax, 32
    or rax, r13
    mov [rbx + V_DATA], rax
    cmp r15, 65535
    jbe .done
    mov byte [rbx + V_BAD], 1
    jmp .done

.var:
    mov ecx, [rbx + V_TOK]
    call var_lookup
    cmp eax, -1
    je .undefined
    mov [rbx + V_DATA], rax
    shl rax, 5
    add rax, [g_vars]
    movzx r12d, word [rax + VR_TYPE]
    jmp .done
.undefined:
    call msg_reset
    lea rcx, [s_undef]
    call msg_addz
    mov ecx, [rbx + V_TOK]
    call msg_tok
    lea rcx, [s_quote]
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [rbx + V_TOK]
    call diag_error_tok

.expr:
    mov rcx, rbx
    call check_expr
    mov r12d, eax
    jmp .done

.take:
    mov r12d, TY_INT
    mov eax, [rbx + V_DATA]
    cmp eax, -1
    je .take_zero
    shl rax, 5
    add rax, [g_stmts]
    mov eax, [rax + S_VAR]
    mov byte [rbx + V_KIND], VK_VAR
    mov [rbx + V_DATA], rax
    jmp .done
.take_zero:
    xor r10d, r10d
    call set_const

.done:
    mov [rbx + V_TYPE], r12b
    mov eax, r12d
    ENDF
.already:
    ENDF

FUNC value_finish
    mov rbx, rcx
    cmp byte [rbx + V_BAD], 0
    je .ok
    call msg_reset
    cmp byte [rbx + V_KIND], VK_INT
    jne .str
    lea rcx, [s_int_lit]
    call msg_addz
    cmp byte [rbx + V_NEG], 0
    je .digits
    mov cl, '-'
    call msg_addc
.digits:
    mov ecx, [rbx + V_TOK]
    call msg_tok
    lea rcx, [s_outside]
    call msg_addz
    jmp .err
.str:
    lea rcx, [s_str_long]
    call msg_addz
.err:
    mov rcx, rbx
    call value_pos
    lea rcx, [s_type]
    call diag_error_tok
.ok:
    ENDF

FUNC check_assign
    mov rbx, rcx
    mov r12d, edx
    mov r13d, r8d
    call check_value
    cmp eax, r12d
    je .ok
    cmp eax, TY_NULL
    jne .bad
    cmp r12d, TY_STR
    je .ok
.bad:
    mov r14d, eax
    call msg_reset
    lea rcx, [s_cannot]
    call msg_addz
    mov ecx, r14d
    call type_name
    mov rcx, rax
    call msg_addz
    lea rcx, [s_to]
    call msg_addz
    mov ecx, r12d
    call type_name
    mov rcx, rax
    call msg_addz
    lea rcx, [s_variable_q]
    call msg_addz
    mov ecx, r13d
    call msg_tok
    lea rcx, [s_quote]
    call msg_addz
    mov rcx, rbx
    call value_pos
    lea rcx, [s_type]
    call diag_error_tok
.ok:
    mov rcx, rbx
    call value_finish
    ENDF

FUNC sema
    mov rcx, [g_nstmt]
    inc rcx
    shl rcx, 5
    call mem_alloc
    mov [g_vars], rax
    mov qword [g_nvars], 0
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
    mov [g_hmask], rdx
    lea rcx, [rax * 4]
    call mem_alloc
    mov [g_htab], rax
    mov rcx, [g_src_len]
    shl rcx, 1
    add rcx, 4096
    call mem_alloc
    mov [g_pool], rax
    mov qword [g_pool_len], 0
    mov rcx, [g_nparts]
    add rcx, [g_nstmt]
    inc rcx
    shl rcx, 4
    call mem_alloc
    mov [g_pieces], rax
    mov qword [g_npieces], 0
    mov qword [g_vars_size], 0

    mov qword [sm_bdepth], 0
    mov r12, [g_stmts]
    mov r13, [g_nstmt]
    shl r13, 5
    add r13, r12
.stmt:
    cmp r12, r13
    jae .finish
    mov rax, r12
    sub rax, [g_stmts]
    shr rax, 5
.block_end:
    mov rcx, [sm_bdepth]
    test rcx, rcx
    jz .block_ok
    lea rdx, [sm_bstack]
    cmp [rdx + rcx * 8 - 8], rax
    jne .block_ok
    dec qword [sm_bdepth]
    mov qword [sm_carry], 0
    jmp .block_end
.block_ok:
    movzx eax, word [r12 + S_KIND]
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
    cmp eax, SK_GROUP
    je .group_stmt
    cmp eax, SK_INPUT
    je .input_stmt
    cmp eax, SK_BREAK
    je .jump_stmt
    cmp eax, SK_CONTINUE
    je .jump_stmt
    jmp .out

.jump_stmt:
    mov qword [sm_carry], 0
    jmp .next

.input_stmt:
    mov ecx, [r12 + S_TOK]
    call var_lookup
    cmp eax, -1
    je .assign
    mov [r12 + S_VAR], eax
    shl rax, 5
    add rax, [g_vars]
    movzx eax, word [rax + VR_TYPE]
    cmp eax, TY_BOOL
    jne .out_parts
    call msg_reset
    lea rcx, [s_in_bool]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_quote]
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_TOK]
    call diag_error_tok

.group_stmt:
    mov qword [sm_carry], 0
    test word [r12 + S_MODE], 1
    jz .next
    mov rax, [g_nvars]
    inc qword [g_nvars]
    mov [r12 + S_VAR], eax
    shl rax, 5
    add rax, [g_vars]
    mov qword [rax + VR_HASH], 0
    mov ecx, [r12 + S_TOK]
    mov [rax + VR_TOK], ecx
    mov word [rax + VR_TYPE], TY_INT
    mov rcx, [g_vars_size]
    add rcx, 3
    and rcx, -4
    mov [rax + VR_OFF], ecx
    add rcx, 4
    mov [g_vars_size], rcx
    jmp .next

.decl:
    mov qword [sm_carry], 0
    cmp qword [sm_bdepth], 0
    jne .decl_in_block
.decl_top:
    mov ecx, [r12 + S_TOK]
    call var_lookup
    mov r14d, eax
    cmp eax, -1
    je .decl_value
    shl rax, 5
    add rax, [g_vars]
    mov rbx, rax
    movzx eax, word [rbx + VR_TYPE]
    movzx ecx, word [r12 + S_MODE]
    cmp eax, ecx
    jne .redecl_type
    call msg_reset
    lea rcx, [s_var_q]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_already_at]
    call msg_addz
    mov ecx, [rbx + VR_LINE]
    call msg_addu
    lea rcx, [s_latest]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call diag_warn_tok
.decl_value:
    cmp dword [r12 + S_NPARTS], 0
    je .decl_store
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    shl rcx, 4
    add rcx, [g_parts]
    movzx edx, word [r12 + S_MODE]
    mov r8d, [r12 + S_TOK]
    call check_assign
.decl_store:
    cmp r14d, -1
    jne .decl_known
    mov ecx, [r12 + S_TOK]
    movzx edx, word [r12 + S_MODE]
    call var_insert
    mov r14d, eax
.decl_known:
    mov [r12 + S_VAR], r14d
    mov ecx, [r12 + S_TOK]
    call tok_line
    mov ecx, r14d
    shl rcx, 5
    add rcx, [g_vars]
    mov [rcx + VR_LINE], eax
    jmp .next

.redecl_type:
    mov r15d, eax
    call msg_reset
    lea rcx, [s_var_q]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_already_as]
    call msg_addz
    lea rcx, [s_an_int]
    cmp r15d, TY_INT
    je .redecl_msg
    lea rcx, [s_a_str]
    cmp r15d, TY_STR
    je .redecl_msg
    lea rcx, [s_a_bool]
.redecl_msg:
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_TOK]
    call diag_error_tok

.decl_in_block:
    cmp word [r12 + S_MODE], TY_STR
    je .str_in_block
    mov ecx, [r12 + S_TOK]
    call var_lookup
    cmp eax, -1
    je .undeclared_in_block
    shl rax, 5
    add rax, [g_vars]
    movzx eax, word [rax + VR_TYPE]
    movzx ecx, word [r12 + S_MODE]
    cmp eax, ecx
    jne .decl_top
    mov word [r12 + S_KIND], SK_ASSIGN
    jmp .assign
.str_in_block:
    call msg_reset
    lea rcx, [s_str_if1]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_str_if2]
    call block_is_loop
    jne .str_msg
    lea rcx, [s_str_loop2]
.str_msg:
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_TOK]
    call diag_error_tok
.undeclared_in_block:
    call msg_reset
    lea rcx, [s_in_if1]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_in_if2]
    call block_is_loop
    jne .undecl_msg
    lea rcx, [s_in_loop2]
.undecl_msg:
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_TOK]
    call diag_error_tok

.if_stmt:
    mov qword [sm_carry], 0
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    shl rcx, 4
    add rcx, [g_parts]
    call check_cond
    mov rcx, [sm_bdepth]
    lea rdx, [sm_bstack]
    mov eax, [r12 + S_PIECES]
    mov [rdx + rcx * 8], rax
    lea rdx, [sm_bkind]
    mov qword [rdx + rcx * 8], BK_IF
    inc qword [sm_bdepth]
    jmp .next

.else_stmt:
    mov qword [sm_carry], 0
    mov rcx, [sm_bdepth]
    lea rdx, [sm_bstack]
    mov eax, [r12 + S_PIECES]
    mov [rdx + rcx * 8], rax
    lea rdx, [sm_bkind]
    mov qword [rdx + rcx * 8], BK_IF
    inc qword [sm_bdepth]
    jmp .next

.loop_stmt:
    mov qword [sm_carry], 0
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    shl rcx, 4
    add rcx, [g_parts]
    mov rbx, rcx
    call check_value
    mov r14d, eax
    mov rcx, rbx
    call value_finish
    cmp r14d, TY_INT
    jne .bad_count
    mov rax, [g_vars_size]
    add rax, 3
    and rax, -4
    mov [r12 + S_NPIECES], eax
    add rax, 8
    mov [g_vars_size], rax
    cmp word [r12 + S_KIND], SK_FOR
    jne .loop_push
    mov ecx, [r12 + S_TOK]
    call var_lookup
    cmp eax, -1
    je .loop_new_var
    mov r15d, eax
    shl rax, 5
    add rax, [g_vars]
    movzx ecx, word [rax + VR_TYPE]
    cmp ecx, TY_INT
    jne .bad_loop_var
    mov [r12 + S_VAR], r15d
    jmp .loop_push
.loop_new_var:
    cmp qword [sm_bdepth], 0
    jne .undeclared_in_block
    mov ecx, [r12 + S_TOK]
    mov edx, TY_INT
    call var_insert
    mov [r12 + S_VAR], eax
    mov r15d, eax
    mov ecx, [r12 + S_TOK]
    call tok_line
    mov ecx, r15d
    shl rcx, 5
    add rcx, [g_vars]
    mov [rcx + VR_LINE], eax
.loop_push:
    mov rcx, [sm_bdepth]
    lea rdx, [sm_bstack]
    mov eax, [r12 + S_PIECES]
    mov [rdx + rcx * 8], rax
    lea rdx, [sm_bkind]
    mov qword [rdx + rcx * 8], BK_LOOP
    inc qword [sm_bdepth]
    jmp .next
.bad_count:
    call msg_reset
    lea rcx, [s_count1]
    call msg_addz
    mov ecx, r14d
    call type_name
    mov rcx, rax
    call msg_addz
    mov rcx, rbx
    call value_pos
    lea rcx, [s_type]
    call diag_error_tok
.bad_loop_var:
    mov r14d, ecx
    call msg_reset
    lea rcx, [s_lvar1]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_lvar2]
    call msg_addz
    lea rcx, [s_an_int]
    cmp r14d, TY_INT
    je .lv_msg
    lea rcx, [s_a_str]
    cmp r14d, TY_STR
    je .lv_msg
    lea rcx, [s_a_bool]
.lv_msg:
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_TOK]
    call diag_error_tok

.assign:
    mov qword [sm_carry], 0
    mov ecx, [r12 + S_TOK]
    call var_lookup
    cmp eax, -1
    jne .assign_ok
    call msg_reset
    lea rcx, [s_undef]
    call msg_addz
    mov ecx, [r12 + S_TOK]
    call msg_tok
    lea rcx, [s_quote]
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_TOK]
    call diag_error_tok
.assign_ok:
    mov [r12 + S_VAR], eax
    shl rax, 5
    add rax, [g_vars]
    movzx edx, word [rax + VR_TYPE]
    mov [r12 + S_MODE], dx
    cmp dword [r12 + S_NPARTS], 0
    je .next
    mov r14d, edx
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov ecx, [rdx + rax * 4]
    shl rcx, 4
    add rcx, [g_parts]
    mov edx, r14d
    mov r8d, [r12 + S_TOK]
    call check_assign
    jmp .next

.out:
    mov ecx, [r12 + S_MODETOK]
    cmp ecx, NO_TOKEN
    je .out_parts
    call tok_text
    cmp edx, 1
    jne .bad_mode
    cmp byte [rax], 's'
    je .out_parts
.bad_mode:
    call msg_reset
    lea rcx, [s_mode1]
    call msg_addz
    mov ecx, [r12 + S_MODETOK]
    call msg_tok
    lea rcx, [s_mode2]
    call msg_addz
    lea rcx, [s_semantic]
    mov edx, [r12 + S_MODETOK]
    dec edx
    call diag_error_tok

.out_parts:
    mov rax, [g_npieces]
    mov [r12 + S_PIECES], eax
    mov r15, [sm_carry]
    xor r14d, r14d
.part:
    cmp r14d, [r12 + S_NPARTS]
    jae .parts_done
    mov eax, [r12 + S_PARTS]
    add eax, r14d
    mov rdx, [g_roots]
    mov ebx, [rdx + rax * 4]
    shl rbx, 4
    add rbx, [g_parts]
    mov rsi, [g_pool_len]
    mov rcx, rbx
    call check_value
    mov edi, eax
    mov rcx, rbx
    call value_finish
    movzx eax, byte [rbx + V_KIND]
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
    lea rcx, [s_null]
    mov edx, 4
    call pool_add
    jmp .part_text
.part_bool:
    lea rcx, [s_true]
    mov edx, 4
    cmp qword [rbx + V_DATA], 0
    jne .part_bool_add
    lea rcx, [s_false]
    mov edx, 5
.part_bool_add:
    call pool_add
    jmp .part_text
.part_int:
    mov rax, [rbx + V_DATA]
    test rax, rax
    jns .part_int_pos
    lea rcx, [s_minus_char]
    mov edx, 1
    call pool_add
    mov rcx, [rbx + V_DATA]
    neg rcx
    jmp .part_int_dec
.part_int_pos:
    mov rcx, rax
.part_int_dec:
    call u64_to_dec
    mov rcx, rax
    call pool_add
.part_text:
    test r15, r15
    jnz .part_extend
    mov ecx, PK_TEXT
    mov edx, esi
    call new_piece
    mov r15, rax
.part_extend:
    mov rax, [g_pool_len]
    sub eax, [r15 + P_A]
    mov [r15 + P_B], eax
    jmp .part_next
.part_var:
    xor r15d, r15d
    mov rax, [rbx + V_DATA]
    shl rax, 5
    add rax, [g_vars]
    mov edx, [rax + VR_OFF]
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
    xor r15d, r15d
    mov rdx, rbx
    sub rdx, [g_parts]
    shr rdx, 4
    mov ecx, PK_EXPR
    call new_piece
.part_next:
    inc r14d
    jmp .part

.parts_done:
    cmp word [r12 + S_MODE], 0
    jne .out_count
    test r15, r15
    jnz .crlf
    mov ecx, PK_TEXT
    mov rdx, [g_pool_len]
    call new_piece
    mov r15, rax
.crlf:
    lea rcx, [s_crlf]
    mov edx, 2
    call pool_add
    mov rax, [g_pool_len]
    sub eax, [r15 + P_A]
    mov [r15 + P_B], eax
.out_count:
    cmp word [r12 + S_KIND], SK_INPUT
    jne .carry_keep
    xor r15d, r15d
.carry_keep:
    mov [sm_carry], r15
    mov rax, [g_npieces]
    sub eax, [r12 + S_PIECES]
    mov [r12 + S_NPIECES], eax

.next:
    add r12, S_SIZE
    jmp .stmt
.finish:
    ENDF

section .rdata
s_minus_char db "-"

section .bss
alignb 8
pc_new  resq 1
pc_len  resq 1
pc_tab  resq 1
pc_mask resq 1

section .text

FUNC pool_compact
    mov rcx, [g_pool_len]
    add rcx, 16
    call mem_alloc
    mov [pc_new], rax
    mov qword [pc_len], 0
    mov rcx, [g_npieces]
    add rcx, [g_nstmt]
    shl rcx, 1
    mov eax, 16
.cap:
    cmp rax, rcx
    jae .cap_ok
    shl rax, 1
    jmp .cap
.cap_ok:
    lea rdx, [rax - 1]
    mov [pc_mask], rdx
    shl rax, 4
    mov rcx, rax
    call mem_alloc
    mov [pc_tab], rax

    mov r12, [g_pieces]
    mov r13, [g_npieces]
    shl r13, 4
    add r13, r12
.pieces:
    cmp r12, r13
    jae .stmts
    cmp dword [r12 + P_KIND], PK_TEXT
    jne .piece_next
    mov ecx, [r12 + P_A]
    mov edx, [r12 + P_B]
    call intern
    mov [r12 + P_A], eax
.piece_next:
    add r12, P_SIZE
    jmp .pieces

.stmts:
    mov r12, [g_stmts]
    mov r13, [g_nstmt]
    shl r13, 5
    add r13, r12
.stmt:
    cmp r12, r13
    jae .done
    cmp word [r12 + S_KIND], SK_OUT
    je .stmt_next
    cmp word [r12 + S_KIND], SK_INPUT
    je .stmt_next
    cmp word [r12 + S_KIND], SK_IF
    je .stmt_if
    cmp dword [r12 + S_NPARTS], 0
    je .stmt_next
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov eax, [rdx + rax * 4]
    shl rax, 4
    add rax, [g_parts]
    mov r14, rax
    mov rcx, r14
    call intern_tree
    jmp .stmt_next
.stmt_if:
    mov eax, [r12 + S_PARTS]
    mov rdx, [g_roots]
    mov eax, [rdx + rax * 4]
    shl rax, 4
    add rax, [g_parts]
    mov rcx, rax
    call intern_tree
.stmt_next:
    add r12, S_SIZE
    jmp .stmt
.done:
    mov rax, [pc_new]
    mov [g_pool], rax
    mov rax, [pc_len]
    mov [g_pool_len], rax
    ENDF

FUNC intern
    mov r12d, ecx
    mov r13d, edx
    mov rsi, [g_pool]
    add rsi, r12
    mov r9, 0x100000001b3
    mov rbx, r13
    imul rbx, r9
    xor ecx, ecx
.hash:
    cmp rcx, r13
    jae .hashed
    mov rax, [rsi + rcx]
    mov rdx, r13
    sub rdx, rcx
    cmp rdx, 8
    jae .hash_full
    push rcx
    lea ecx, [edx * 8]
    mov rdx, -1
    shl rdx, cl
    not rdx
    and rax, rdx
    pop rcx
.hash_full:
    xor rbx, rax
    imul rbx, r9
    add rcx, 8
    jmp .hash
.hashed:
    mov r14, rbx
    and r14, [pc_mask]
.probe:
    mov r15, r14
    shl r15, 4
    add r15, [pc_tab]
    mov eax, [r15 + 8]
    test eax, eax
    jz .insert
    cmp [r15], rbx
    jne .next
    cmp [r15 + 12], r13d
    jne .next
    lea rdi, [rax - 1]
    add rdi, [pc_new]
    xor ecx, ecx
.cmp_loop:
    cmp rcx, r13
    jae .cmp_equal
    mov rax, [rsi + rcx]
    xor rax, [rdi + rcx]
    mov rdx, r13
    sub rdx, rcx
    cmp rdx, 8
    jae .cmp_full
    push rcx
    lea ecx, [edx * 8]
    mov rdx, -1
    shl rdx, cl
    not rdx
    and rax, rdx
    pop rcx
.cmp_full:
    test rax, rax
    jnz .next
    add rcx, 8
    jmp .cmp_loop
.cmp_equal:
    mov eax, [r15 + 8]
    dec eax
    ENDF
.next:
    inc r14
    and r14, [pc_mask]
    jmp .probe
.insert:
    mov rdi, [pc_new]
    add rdi, [pc_len]
    mov rcx, r13
    rep movsb
    mov rax, [pc_len]
    mov [r15], rbx
    lea edx, [eax + 1]
    mov [r15 + 8], edx
    mov [r15 + 12], r13d
    add [pc_len], r13
    ENDF

make_bool_const:
    mov byte [rbx + V_KIND], VK_BOOL
    mov byte [rbx + V_TYPE], TY_BOOL
    mov byte [rbx + V_NEG], 0
    mov byte [rbx + V_BAD], 0
    mov [rbx + V_DATA], rax
    ret

pool_equal:
    mov eax, [rcx + V_DATA + 4]
    cmp eax, [rdx + V_DATA + 4]
    jne .no
    mov r8d, [rcx + V_DATA]
    mov r9d, [rdx + V_DATA]
    add r8, [g_pool]
    add r9, [g_pool]
    xor r10d, r10d
.loop:
    cmp r10d, eax
    jae .yes
    mov r11b, [r8 + r10]
    cmp r11b, [r9 + r10]
    jne .no
    inc r10d
    jmp .loop
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

FUNC check_cond
    mov rbx, rcx
    cmp byte [rbx + V_KIND], VK_OR
    je .or
    cmp byte [rbx + V_KIND], VK_AND
    je .and
    movzx r12d, byte [rbx + V_NEG]
    mov ecx, [rbx + V_DATA]
    call node_ptr
    mov r13, rax
    mov rcx, r13
    call check_value
    mov r14d, eax
    mov rcx, r13
    call value_finish
    mov ecx, [rbx + V_DATA + 4]
    call node_ptr
    mov r15, rax
    mov rcx, r15
    call check_value
    mov esi, eax
    mov rcx, r15
    call value_finish
    cmp r12d, CMP_LT
    jae .ordered
    cmp r14d, esi
    je .types_ok
    mov eax, r14d
    or eax, esi
    cmp r14d, TY_NULL
    je .one_null
    cmp esi, TY_NULL
    jne .bad_compare
.one_null:
    cmp r14d, TY_STR
    je .types_ok
    cmp esi, TY_STR
    je .types_ok
    jmp .bad_compare
.ordered:
    cmp r14d, TY_INT
    jne .bad_ordered_left
    cmp esi, TY_INT
    jne .bad_ordered_right
.types_ok:
    mov eax, r14d
    cmp eax, TY_NULL
    jne .store_type
    mov eax, esi
.store_type:
    mov [rbx + V_TYPE], al
    movzx edi, byte [r13 + V_KIND]
    movzx ecx, byte [r15 + V_KIND]
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
    mov r8, [r13 + V_DATA]
    mov r9, [r15 + V_DATA]
    xor eax, eax
    cmp r12d, CMP_IS
    je .f_is
    cmp r12d, CMP_ISNOT
    je .f_isnot
    cmp r12d, CMP_LT
    je .f_lt
    cmp r12d, CMP_LE
    je .f_le
    cmp r12d, CMP_GE
    je .f_ge
    cmp r8, r9
    setg al
    jmp .fold_set
.f_is:
    cmp r8, r9
    sete al
    jmp .fold_set
.f_isnot:
    cmp r8, r9
    setne al
    jmp .fold_set
.f_lt:
    cmp r8, r9
    setl al
    jmp .fold_set
.f_le:
    cmp r8, r9
    setle al
    jmp .fold_set
.f_ge:
    cmp r8, r9
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
    mov rcx, r13
    mov rdx, r15
    call pool_equal
    jmp .fold_eq
.fold_same:
    mov eax, 1
    jmp .fold_eq
.fold_diff:
    xor eax, eax
.fold_eq:
    cmp r12d, CMP_ISNOT
    jne .fold_set
    xor eax, 1
.fold_set:
    movzx eax, al
    call make_bool_const
.done:
    ENDF

.or:
    mov ecx, [rbx + V_DATA]
    call node_ptr
    mov r13, rax
    mov rcx, r13
    call check_cond
    mov ecx, [rbx + V_DATA + 4]
    call node_ptr
    mov r15, rax
    mov rcx, r15
    call check_cond
    cmp byte [r13 + V_KIND], VK_BOOL
    jne .or_right
    cmp qword [r13 + V_DATA], 0
    jne .or_true
    mov rcx, r15
    call copy_node
    ENDF
.or_right:
    cmp byte [r15 + V_KIND], VK_BOOL
    jne .or_done
    cmp qword [r15 + V_DATA], 0
    jne .or_true
    mov rcx, r13
    call copy_node
    ENDF
.or_true:
    mov eax, 1
    call make_bool_const
.or_done:
    ENDF

.and:
    mov ecx, [rbx + V_DATA]
    call node_ptr
    mov r13, rax
    mov rcx, r13
    call check_cond
    mov ecx, [rbx + V_DATA + 4]
    call node_ptr
    mov r15, rax
    mov rcx, r15
    call check_cond
    cmp byte [r13 + V_KIND], VK_BOOL
    jne .and_right
    cmp qword [r13 + V_DATA], 0
    je .and_false
    mov rcx, r15
    call copy_node
    ENDF
.and_right:
    cmp byte [r15 + V_KIND], VK_BOOL
    jne .and_done
    cmp qword [r15 + V_DATA], 0
    je .and_false
    mov rcx, r13
    call copy_node
    ENDF
.and_false:
    xor eax, eax
    call make_bool_const
.and_done:
    ENDF

.bad_ordered_left:
    mov esi, r14d
.bad_ordered_right:
    call msg_reset
    lea rcx, [s_operator]
    call msg_addz
    lea rax, [cmp_chars]
    mov cl, [rax + r12]
    call msg_addc
    cmp r12d, CMP_LE
    jb .op_done
    mov cl, '='
    call msg_addc
.op_done:
    lea rcx, [s_needs_bin]
    call msg_addz
    mov ecx, esi
    call type_name
    mov rcx, rax
    call msg_addz
    lea rcx, [s_type]
    mov edx, [rbx + V_TOK]
    call diag_error_tok

.bad_compare:
    call msg_reset
    lea rcx, [s_cmp1]
    call msg_addz
    mov ecx, r14d
    call type_name
    mov rcx, rax
    call msg_addz
    lea rcx, [s_with]
    call msg_addz
    mov ecx, esi
    call type_name
    mov rcx, rax
    call msg_addz
    lea rcx, [s_type]
    mov edx, [rbx + V_TOK]
    call diag_error_tok

FUNC intern_tree
    mov rbx, rcx
    movzx eax, byte [rbx + V_KIND]
    cmp eax, VK_CMP
    je .pair
    cmp eax, VK_OR
    je .pair
    cmp eax, VK_AND
    je .pair
    cmp eax, VK_STR
    jne .done
    cmp byte [rbx + V_NEG], 0
    jne .done
    mov ecx, [rbx + V_DATA]
    mov edx, [rbx + V_DATA + 4]
    call intern
    mov [rbx + V_DATA], eax
    mov byte [rbx + V_NEG], 1
    jmp .done
.pair:
    mov ecx, [rbx + V_DATA]
    call node_ptr
    mov rcx, rax
    call intern_tree
    mov ecx, [rbx + V_DATA + 4]
    call node_ptr
    mov rcx, rax
    call intern_tree
.done:
    ENDF

block_is_loop:
    mov rax, [sm_bdepth]
    lea rdx, [sm_bkind]
    cmp qword [rdx + rax * 8 - 8], BK_LOOP
    ret
