%include "defs.inc"
%include "state.inc"

section .rodata
s_syntax      db "syntax", 0
s_exp_stmt    db "expected statement", 0
s_exp_eol     db "expected end of line", 0
s_exp_type    db "expected type after '.'", 0
s_unk_type1   db "unknown type '", 0
s_unk_type2   db "', expected int, str, or bool", 0
s_exp_eq_type db "expected '=' after variable type", 0
s_exp_after_n db "expected '.' or '=' after variable name", 0
s_exp_mode    db "expected print mode after '.'", 0
s_exp_shr_p   db "expected '>>' after 'print'", 0
s_exp_shr_s   db "expected '>>' after 'show'", 0
s_exp_out     db "expected value after '>>'", 0
s_exp_rbrace  db "expected '}'", 0
s_exp_rparen  db "expected ')'", 0
s_too_deep    db "expression is nested more than 1000 levels deep", 0
s_too_long    db "expression has more than 2000 values and operators", 0
s_no_float    db "decimal numbers are not supported yet, use int", 0
s_wrap        db "values next to text must be wrapped in '{ }'", 0
s_exp_value   db "expected value", 0
s_exp_number  db "expected number after '-'", 0

section .bss
alignb 4
pr_depth resd 1

section .text

%macro CUR 0
    mov rax, r13
    shl rax, 4
    movzx eax, word [r12 + rax]
%endmacro

%macro SYNERR 1
    lea rcx, [%1]
    mov edx, r13d
    jmp syn_error
%endmacro

syn_error:
    mov ebx, edx
    mov rsi, rcx
    call msg_reset
    mov rcx, rsi
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, ebx
    call diag_error_tok

FUNC parse
    mov rcx, [g_ntok]
    inc rcx
    shl rcx, 5
    call mem_alloc
    mov [g_stmts], rax
    mov r14, rax
    mov rcx, [g_ntok]
    inc rcx
    shl rcx, 4
    call mem_alloc
    mov [g_parts], rax
    mov rcx, [g_ntok]
    inc rcx
    shl rcx, 2
    call mem_alloc
    mov [g_roots], rax
    mov qword [g_nroots], 0
    mov r12, [g_tokens]
    xor r13d, r13d
    xor r15d, r15d

.stmt:
    CUR
    cmp eax, TK_NL
    jne .not_nl
    inc r13
    jmp .stmt
.not_nl:
    cmp eax, TK_EOF
    je .done
    cmp eax, TK_IDENT
    je .var_stmt
    cmp eax, TK_PRINT
    je .print_stmt
    cmp eax, TK_SHOW
    je .show_stmt
    SYNERR s_exp_stmt

.var_stmt:
    mov [r14 + S_TOK], r13d
    inc r13
    CUR
    cmp eax, TK_DOT
    je .decl
    cmp eax, TK_EQ
    je .assign
    SYNERR s_exp_after_n
.decl:
    inc r13
    CUR
    mov ecx, TY_INT
    cmp eax, TK_KINT
    je .have_type
    mov ecx, TY_STR
    cmp eax, TK_KSTR
    je .have_type
    mov ecx, TY_BOOL
    cmp eax, TK_KBOOL
    je .have_type
    cmp eax, TK_IDENT
    je .unknown_type
    SYNERR s_exp_type
.have_type:
    mov word [r14 + S_KIND], SK_DECL
    mov [r14 + S_MODE], cx
    inc r13
    CUR
    cmp eax, TK_EQ
    je .decl_eq
    SYNERR s_exp_eq_type
.decl_eq:
    inc r13
    jmp .value_opt
.assign:
    mov word [r14 + S_KIND], SK_ASSIGN
    inc r13
.value_opt:
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_NPARTS], 0
    CUR
    cmp eax, TK_NL
    je .end_line
    cmp eax, TK_EOF
    je .end_line
    call parse_value
    call push_root
    mov dword [r14 + S_NPARTS], 1
    jmp .end_line

.print_stmt:
    mov word [r14 + S_KIND], SK_OUT
    mov word [r14 + S_MODE], 0
    mov [r14 + S_TOK], r13d
    mov dword [r14 + S_MODETOK], NO_TOKEN
    inc r13
    CUR
    cmp eax, TK_DOT
    jne .print_shr
    inc r13
    CUR
    cmp eax, TK_IDENT
    je .print_mode
    SYNERR s_exp_mode
.print_mode:
    mov [r14 + S_MODETOK], r13d
    inc r13
    CUR
.print_shr:
    cmp eax, TK_SHR
    je .out_body
    SYNERR s_exp_shr_p

.show_stmt:
    mov word [r14 + S_KIND], SK_OUT
    mov word [r14 + S_MODE], 1
    mov [r14 + S_TOK], r13d
    mov dword [r14 + S_MODETOK], NO_TOKEN
    inc r13
    CUR
    cmp eax, TK_SHR
    je .out_body
    SYNERR s_exp_shr_s

.out_body:
    inc r13
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov rbx, [g_nroots]
    CUR
    cmp eax, TK_NL
    je .out_empty
    cmp eax, TK_EOF
    jne .out_part
.out_empty:
    SYNERR s_exp_out
.out_part:
    CUR
    cmp eax, TK_NL
    je .out_done
    cmp eax, TK_EOF
    je .out_done
    cmp eax, TK_STR
    jne .out_not_str
    call parse_string
    call push_root
    jmp .out_part
.out_not_str:
    cmp eax, TK_LBRACE
    jne .out_bare
    inc r13
    call parse_value
    mov edi, eax
    CUR
    cmp eax, TK_RBRACE
    je .out_rbrace_ok
    SYNERR s_exp_rbrace
.out_rbrace_ok:
    inc r13
    mov eax, edi
    call push_root
    jmp .out_part
.out_bare:
    cmp eax, TK_INT
    je .bare
    cmp eax, TK_MINUS
    je .bare
    cmp eax, TK_TRUE
    je .bare
    cmp eax, TK_FALSE
    je .bare
    cmp eax, TK_NULL
    je .bare
    cmp eax, TK_IDENT
    je .bare
    cmp eax, TK_LPAREN
    je .bare
    cmp eax, TK_FNUM
    je .bare
    SYNERR s_exp_eol
.bare:
    mov rax, [g_nroots]
    cmp rax, rbx
    je .bare_first
    SYNERR s_wrap
.bare_first:
    mov rsi, r13
    call parse_value
    call push_root
    CUR
    cmp eax, TK_NL
    je .out_done
    cmp eax, TK_EOF
    je .out_done
    mov r13, rsi
    SYNERR s_wrap
.out_done:
    mov rax, [g_nroots]
    sub rax, rbx
    mov [r14 + S_NPARTS], eax

.end_line:
    CUR
    cmp eax, TK_NL
    je .line_ok
    cmp eax, TK_EOF
    je .line_ok
    SYNERR s_exp_eol
.line_ok:
    add r14, S_SIZE
    jmp .stmt

.unknown_type:
    mov ebx, r13d
    call msg_reset
    lea rcx, [s_unk_type1]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_unk_type2]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, ebx
    call diag_error_tok

.done:
    mov rax, r14
    sub rax, [g_stmts]
    shr rax, 5
    mov [g_nstmt], rax
    mov [g_nparts], r15
    ENDF

parse_value:
    mov dword [pr_depth], 0
    push r15
    push r13
    call parse_expr
    pop rdx
    pop rcx
    mov r8, r15
    sub r8, rcx
    cmp r8, MAX_NODES
    ja .too_long
    ret
.too_long:
    mov r13, rdx
    SYNERR s_too_long

push_root:
    mov rcx, [g_nroots]
    mov rdx, [g_roots]
    mov [rdx + rcx * 4], eax
    inc qword [g_nroots]
    ret

new_node:
    mov r10, r15
    shl r10, 4
    add r10, [g_parts]
    mov qword [r10], 0
    mov qword [r10 + 8], 0
    mov [r10 + V_KIND], cl
    mov [r10 + V_TOK], edx
    mov eax, r15d
    inc r15
    ret

new_op:
    push rax
    mov ecx, VK_EXPR
    mov edx, r11d
    call new_node
    pop rdx
    mov [r10 + V_NEG], r9b
    mov [r10 + V_DATA], edx
    mov [r10 + V_DATA + 4], r8d
    ret

parse_expr:
    call parse_term
.loop:
    mov r8d, eax
    CUR
    mov r9d, OP_ADD
    cmp eax, TK_PLUS
    je .op
    mov r9d, OP_SUB
    cmp eax, TK_MINUS
    je .op
    mov eax, r8d
    ret
.op:
    push r8
    push r9
    push r13
    inc r13
    call parse_term
    mov r8d, eax
    pop r11
    pop r9
    pop rax
    call new_op
    jmp .loop

parse_term:
    call parse_factor
.loop:
    mov r8d, eax
    CUR
    mov r9d, OP_MUL
    cmp eax, TK_STAR
    je .op
    mov r9d, OP_DIV
    cmp eax, TK_SLASH
    je .op
    mov r9d, OP_MOD
    cmp eax, TK_PERCENT
    je .op
    mov eax, r8d
    ret
.op:
    push r8
    push r9
    push r13
    inc r13
    call parse_factor
    mov r8d, eax
    pop r11
    pop r9
    pop rax
    call new_op
    jmp .loop

parse_factor:
    inc dword [pr_depth]
    cmp dword [pr_depth], MAX_DEPTH
    ja .too_deep
    CUR
    cmp eax, TK_MINUS
    je .minus
    cmp eax, TK_LPAREN
    je .paren
    call parse_primary
    dec dword [pr_depth]
    ret
.minus:
    mov rax, r13
    inc rax
    shl rax, 4
    add rax, r12
    movzx eax, word [rax]
    cmp eax, TK_INT
    jne .negate
    inc r13
    mov ecx, VK_INT
    mov edx, r13d
    call new_node
    mov byte [r10 + V_NEG], 1
    inc r13
    dec dword [pr_depth]
    ret
.negate:
    push r13
    inc r13
    call parse_factor
    pop r11
    mov r9d, OP_NEG
    mov r8d, NO_EXPR
    call new_op
    dec dword [pr_depth]
    ret
.paren:
    inc r13
    call parse_expr
    mov r8d, eax
    CUR
    cmp eax, TK_RPAREN
    je .paren_ok
    SYNERR s_exp_rparen
.paren_ok:
    inc r13
    mov eax, r8d
    dec dword [pr_depth]
    ret
.too_deep:
    SYNERR s_too_deep

parse_primary:
    CUR
    mov ecx, VK_INT
    cmp eax, TK_INT
    je .leaf
    mov ecx, VK_STR
    cmp eax, TK_STR
    je .leaf
    mov ecx, VK_NULL
    cmp eax, TK_NULL
    je .leaf
    mov ecx, VK_VAR
    cmp eax, TK_IDENT
    je .leaf
    cmp eax, TK_TRUE
    je .true
    cmp eax, TK_FALSE
    je .false
    cmp eax, TK_FNUM
    je .fnum
    SYNERR s_exp_value
.true:
    mov ecx, VK_BOOL
    mov edx, r13d
    call new_node
    mov dword [r10 + V_DATA], 1
    inc r13
    ret
.false:
    mov ecx, VK_BOOL
.leaf:
    mov edx, r13d
    call new_node
    inc r13
    ret
.fnum:
    SYNERR s_no_float

parse_string:
    mov ecx, VK_STR
    mov edx, r13d
    call new_node
    inc r13
    ret
