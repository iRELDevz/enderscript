%include "defs.inc"
%include "state.inc"

section .rdata
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
s_wrap        db "values next to text must be wrapped in '{ }'", 0
s_exp_value   db "expected value", 0
s_exp_number  db "expected number after '-'", 0

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
    mov [r14 + S_PARTS], r15d
    mov dword [r14 + S_NPARTS], 0
    CUR
    cmp eax, TK_NL
    je .end_line
    cmp eax, TK_EOF
    je .end_line
    call parse_value
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
    mov [r14 + S_PARTS], r15d
    mov rbx, r15
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
    call parse_value
    jmp .out_part
.out_not_str:
    cmp eax, TK_LBRACE
    jne .out_bare
    inc r13
    call parse_value
    CUR
    cmp eax, TK_RBRACE
    je .out_rbrace
    SYNERR s_exp_rbrace
.out_rbrace:
    inc r13
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
    SYNERR s_exp_eol
.bare:
    cmp r15, rbx
    je .bare_first
    SYNERR s_wrap
.bare_first:
    mov rsi, r13
    call parse_value
    CUR
    cmp eax, TK_NL
    je .out_done
    cmp eax, TK_EOF
    je .out_done
    mov r13, rsi
    SYNERR s_wrap
.out_done:
    mov rax, r15
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
    mov r10, r15
    shl r10, 4
    add r10, [g_parts]
    mov qword [r10], 0
    mov qword [r10 + 8], 0
    CUR
    mov ecx, VK_INT
    cmp eax, TK_INT
    je .simple
    mov ecx, VK_STR
    cmp eax, TK_STR
    je .simple
    mov ecx, VK_NULL
    cmp eax, TK_NULL
    je .simple
    mov ecx, VK_VAR
    cmp eax, TK_IDENT
    je .simple
    cmp eax, TK_TRUE
    je .true
    cmp eax, TK_FALSE
    je .false
    cmp eax, TK_MINUS
    je .minus
    SYNERR s_exp_value
.true:
    mov qword [r10 + V_DATA], 1
.false:
    mov ecx, VK_BOOL
    jmp .simple
.minus:
    inc r13
    CUR
    cmp eax, TK_INT
    je .neg_ok
    SYNERR s_exp_number
.neg_ok:
    mov byte [r10 + V_NEG], 1
    mov ecx, VK_INT
.simple:
    mov [r10 + V_KIND], cl
    mov [r10 + V_TOK], r13d
    inc r13
    inc r15
    ret
