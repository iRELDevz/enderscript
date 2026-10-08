%include "defs.inc"
%include "state.inc"

section .bss
alignb 4
pr_first resd 1
pr_saved resd 1
pr_err   resd 1

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
    mov eax, esi
    shl eax, 4
    add eax, [g_tokens]
    movzx eax, word [eax]
%endmacro

%macro SYNERR 1
    mov ecx, %1
    mov edx, esi
    jmp syn_error
%endmacro

syn_error:
    mov [pr_err], edx
    push ecx
    call msg_reset
    pop ecx
    call msg_addz
    mov ecx, s_syntax
    mov edx, [pr_err]
    call diag_error_tok

FUNC parse
    mov ecx, [g_ntok]
    inc ecx
    shl ecx, 5
    call mem_alloc
    mov [g_stmts], eax
    mov edi, eax
    mov ecx, [g_ntok]
    inc ecx
    shl ecx, 4
    call mem_alloc
    mov [g_parts], eax
    xor esi, esi
    xor ebx, ebx

.stmt:
    CUR
    cmp eax, TK_NL
    jne .not_nl
    inc esi
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
    mov [edi + S_TOK], esi
    inc esi
    CUR
    cmp eax, TK_DOT
    je .decl
    cmp eax, TK_EQ
    je .assign
    SYNERR s_exp_after_n
.decl:
    inc esi
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
    mov word [edi + S_KIND], SK_DECL
    mov [edi + S_MODE], cx
    inc esi
    CUR
    cmp eax, TK_EQ
    je .decl_eq
    SYNERR s_exp_eq_type
.decl_eq:
    inc esi
    jmp .value_opt
.assign:
    mov word [edi + S_KIND], SK_ASSIGN
    inc esi
.value_opt:
    mov [edi + S_PARTS], ebx
    mov dword [edi + S_NPARTS], 0
    CUR
    cmp eax, TK_NL
    je .end_line
    cmp eax, TK_EOF
    je .end_line
    call parse_value
    mov dword [edi + S_NPARTS], 1
    jmp .end_line

.print_stmt:
    mov word [edi + S_KIND], SK_OUT
    mov word [edi + S_MODE], 0
    mov [edi + S_TOK], esi
    mov dword [edi + S_MODETOK], NO_TOKEN
    inc esi
    CUR
    cmp eax, TK_DOT
    jne .print_shr
    inc esi
    CUR
    cmp eax, TK_IDENT
    je .print_mode
    SYNERR s_exp_mode
.print_mode:
    mov [edi + S_MODETOK], esi
    inc esi
    CUR
.print_shr:
    cmp eax, TK_SHR
    je .out_body
    SYNERR s_exp_shr_p

.show_stmt:
    mov word [edi + S_KIND], SK_OUT
    mov word [edi + S_MODE], 1
    mov [edi + S_TOK], esi
    mov dword [edi + S_MODETOK], NO_TOKEN
    inc esi
    CUR
    cmp eax, TK_SHR
    je .out_body
    SYNERR s_exp_shr_s

.out_body:
    inc esi
    mov [edi + S_PARTS], ebx
    mov [pr_first], ebx
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
    inc esi
    call parse_value
    CUR
    cmp eax, TK_RBRACE
    je .out_rbrace
    SYNERR s_exp_rbrace
.out_rbrace:
    inc esi
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
    cmp ebx, [pr_first]
    je .bare_first
    SYNERR s_wrap
.bare_first:
    mov [pr_saved], esi
    call parse_value
    CUR
    cmp eax, TK_NL
    je .out_done
    cmp eax, TK_EOF
    je .out_done
    mov esi, [pr_saved]
    SYNERR s_wrap
.out_done:
    mov eax, ebx
    sub eax, [pr_first]
    mov [edi + S_NPARTS], eax

.end_line:
    CUR
    cmp eax, TK_NL
    je .line_ok
    cmp eax, TK_EOF
    je .line_ok
    SYNERR s_exp_eol
.line_ok:
    add edi, S_SIZE
    jmp .stmt

.unknown_type:
    mov [pr_err], esi
    call msg_reset
    mov ecx, s_unk_type1
    call msg_addz
    mov ecx, [pr_err]
    call msg_tok
    mov ecx, s_unk_type2
    call msg_addz
    mov ecx, s_syntax
    mov edx, [pr_err]
    call diag_error_tok

.done:
    mov eax, edi
    sub eax, [g_stmts]
    shr eax, 5
    mov [g_nstmt], eax
    mov [g_nparts], ebx
    ENDF

parse_value:
    mov edx, ebx
    shl edx, 4
    add edx, [g_parts]
    mov dword [edx], 0
    mov dword [edx + 4], 0
    mov dword [edx + 8], 0
    mov dword [edx + 12], 0
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
    mov dword [edx + V_DATA], 1
.false:
    mov ecx, VK_BOOL
    jmp .simple
.minus:
    inc esi
    CUR
    cmp eax, TK_INT
    je .neg_ok
    SYNERR s_exp_number
.neg_ok:
    mov byte [edx + V_NEG], 1
    mov ecx, VK_INT
.simple:
    mov [edx + V_KIND], cl
    mov [edx + V_TOK], esi
    inc esi
    inc ebx
    ret
