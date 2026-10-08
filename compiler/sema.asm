%include "defs.inc"
%include "state.inc"

extern u64_to_dec

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
    movzx eax, byte [rcx + V_NEG]
    mov edx, [rcx + V_TOK]
    sub edx, eax
    ret

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
    movzx eax, byte [rbx + V_KIND]
    cmp eax, VK_INT
    je .int
    cmp eax, VK_STR
    je .str
    cmp eax, VK_VAR
    je .var
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

.done:
    mov [rbx + V_TYPE], r12b
    mov eax, r12d
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

    mov r12, [g_stmts]
    mov r13, [g_nstmt]
    shl r13, 5
    add r13, r12
.stmt:
    cmp r12, r13
    jae .finish
    movzx eax, word [r12 + S_KIND]
    cmp eax, SK_DECL
    je .decl
    cmp eax, SK_ASSIGN
    je .assign
    jmp .out

.decl:
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
    mov ecx, [r12 + S_PARTS]
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

.assign:
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
    mov ecx, [r12 + S_PARTS]
    shl rcx, 4
    add rcx, [g_parts]
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
    xor r15d, r15d
    xor r14d, r14d
.part:
    cmp r14d, [r12 + S_NPARTS]
    jae .parts_done
    mov ebx, [r12 + S_PARTS]
    add ebx, r14d
    shl rbx, 4
    add rbx, [g_parts]
    mov rsi, [g_pool_len]
    mov rcx, rbx
    call check_value
    mov edi, eax
    mov rcx, rbx
    call value_finish
    movzx eax, byte [rbx + V_KIND]
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
    mov edx, 1
    call pool_add
    mov rax, [g_pool_len]
    sub eax, [r15 + P_A]
    mov [r15 + P_B], eax
.out_count:
    mov rax, [g_npieces]
    sub eax, [r12 + S_PIECES]
    mov [r12 + S_NPIECES], eax

.next:
    add r12, S_SIZE
    jmp .stmt
.finish:
    ENDF

section .rodata
s_minus_char db "-"
