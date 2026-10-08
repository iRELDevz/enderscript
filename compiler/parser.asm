%include "defs.inc"
%include "state.inc"

section .bss
alignb 4
pr_first resd 1
pr_saved resd 1
pr_err   resd 1
pr_depth resd 1
nt_left  resd 1
nt_right resd 1
nt_op    resd 1
nt_tok   resd 1

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
    mov ecx, [g_ntok]
    inc ecx
    shl ecx, 2
    call mem_alloc
    mov [g_roots], eax
    mov dword [g_nroots], 0
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
    mov eax, [g_nroots]
    mov [edi + S_PARTS], eax
    mov dword [edi + S_NPARTS], 0
    CUR
    cmp eax, TK_NL
    je .end_line
    cmp eax, TK_EOF
    je .end_line
    call parse_value
    call push_root
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
    mov eax, [g_nroots]
    mov [edi + S_PARTS], eax
    mov [pr_first], eax
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
    inc esi
    call parse_value
    push eax
    CUR
    cmp eax, TK_RBRACE
    je .out_rbrace
    SYNERR s_exp_rbrace
.out_rbrace:
    inc esi
    pop eax
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
    mov eax, [g_nroots]
    cmp eax, [pr_first]
    je .bare_first
    SYNERR s_wrap
.bare_first:
    mov [pr_saved], esi
    call parse_value
    call push_root
    CUR
    cmp eax, TK_NL
    je .out_done
    cmp eax, TK_EOF
    je .out_done
    mov esi, [pr_saved]
    SYNERR s_wrap
.out_done:
    mov eax, [g_nroots]
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
    mov dword [pr_depth], 0
    push ebx
    push esi
    call parse_expr
    pop edx
    pop ecx
    push eax
    mov eax, ebx
    sub eax, ecx
    cmp eax, MAX_NODES
    pop eax
    ja .too_long
    ret
.too_long:
    mov esi, edx
    SYNERR s_too_long

push_root:
    mov ecx, [g_nroots]
    mov edx, [g_roots]
    mov [edx + ecx * 4], eax
    inc dword [g_nroots]
    ret

new_node:
    push ecx
    mov eax, ebx
    shl eax, 4
    add eax, [g_parts]
    mov dword [eax], 0
    mov dword [eax + 4], 0
    mov dword [eax + 8], 0
    mov dword [eax + 12], 0
    pop ecx
    mov [eax + V_KIND], cl
    mov [eax + V_TOK], edx
    mov edx, eax
    mov eax, ebx
    inc ebx
    ret

new_op:
    mov ecx, VK_EXPR
    mov edx, [nt_tok]
    call new_node
    mov ecx, [nt_op]
    mov [edx + V_NEG], cl
    mov ecx, [nt_left]
    mov [edx + V_DATA], ecx
    mov ecx, [nt_right]
    mov [edx + V_DATA + 4], ecx
    ret

parse_expr:
    call parse_term
.loop:
    push eax
    CUR
    mov ecx, OP_ADD
    cmp eax, TK_PLUS
    je .op
    mov ecx, OP_SUB
    cmp eax, TK_MINUS
    je .op
    pop eax
    ret
.op:
    push ecx
    push esi
    inc esi
    call parse_term
    mov [nt_right], eax
    pop dword [nt_tok]
    pop dword [nt_op]
    pop dword [nt_left]
    call new_op
    jmp .loop

parse_term:
    call parse_factor
.loop:
    push eax
    CUR
    mov ecx, OP_MUL
    cmp eax, TK_STAR
    je .op
    mov ecx, OP_DIV
    cmp eax, TK_SLASH
    je .op
    mov ecx, OP_MOD
    cmp eax, TK_PERCENT
    je .op
    pop eax
    ret
.op:
    push ecx
    push esi
    inc esi
    call parse_factor
    mov [nt_right], eax
    pop dword [nt_tok]
    pop dword [nt_op]
    pop dword [nt_left]
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
    mov eax, esi
    inc eax
    shl eax, 4
    add eax, [g_tokens]
    movzx eax, word [eax]
    cmp eax, TK_INT
    jne .negate
    inc esi
    mov ecx, VK_INT
    mov edx, esi
    call new_node
    mov byte [edx + V_NEG], 1
    inc esi
    dec dword [pr_depth]
    ret
.negate:
    push esi
    inc esi
    call parse_factor
    mov [nt_left], eax
    pop dword [nt_tok]
    mov dword [nt_op], OP_NEG
    mov dword [nt_right], NO_EXPR
    call new_op
    dec dword [pr_depth]
    ret
.paren:
    inc esi
    call parse_expr
    push eax
    CUR
    cmp eax, TK_RPAREN
    je .paren_ok
    SYNERR s_exp_rparen
.paren_ok:
    inc esi
    pop eax
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
    mov ecx, VK_BOOL
    cmp eax, TK_FALSE
    je .leaf
    cmp eax, TK_FNUM
    je .fnum
    SYNERR s_exp_value
.true:
    mov ecx, VK_BOOL
    mov edx, esi
    call new_node
    mov dword [edx + V_DATA], 1
    inc esi
    ret
.leaf:
    mov edx, esi
    call new_node
    inc esi
    ret
.fnum:
    SYNERR s_no_float

parse_string:
    mov ecx, VK_STR
    mov edx, esi
    call new_node
    inc esi
    ret

