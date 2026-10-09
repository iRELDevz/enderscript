%include "defs.inc"
%include "state.inc"
%include "xlat.inc"

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
s_exp_rparen  db "expected ')'", 0
s_too_deep    db "expression is nested more than 1000 levels deep", 0
s_too_long    db "expression has more than 2000 values and operators", 0
s_exp_colon   db "expected ':' after the if condition", 0
s_exp_block   db "expected an indented block after 'if'", 0
s_unexp_ind   db "unexpected indentation", 0
s_exp_cmp     db "expected 'is', '==', 'isnot', '!=', '<', '>', '<=' or '>=' in the if condition", 0
s_elif_no_if  db "'elif' must follow an 'if' block", 0
s_many_elif   db "more than 2000 'elif' in one chain", 0
s_exp_start   db "expected 'start.", 0
s_after_open  db "' on the line after 'loops(", 0
s_exp_count   db "expected a repeat block like '100(' or 'stop.", 0
s_q_close     db "'", 0
s_exp_cnt_lp  db "expected '(' after the repeat count", 0
s_exp_grp_rp  db "expected ')' after 'stop.", 0
s_unexp_rp    db "unexpected ')'", 0
s_open_block  db "expected ')' to close the repeat block", 0
s_missing_stop db "expected 'stop.", 0
s_stop_match  db "' does not match 'loops(", 0
s_stop_q      db "'stop.", 0
s_comma_q     db ",'", 0
w_start       db "start", 0
w_stop        db "stop", 0
s_exp_colon_e db "expected ':' after 'else'", 0
s_exp_blk_els db "expected an indented block after 'else'", 0
s_else_no_if  db "'else' must follow an 'if' block", 0
s_too_many_or db "more than 64 values joined with 'or' or 'and'", 0
s_exp_loopvar db "expected a variable name after 'for'", 0
s_exp_in      db "expected 'in' after the loop variable", 0
s_exp_range   db "expected 'range' after 'in'", 0
s_exp_lp_r    db "expected '(' after 'range'", 0
s_exp_lp_l    db "expected '(' after 'loops'", 0
s_exp_colon_l db "expected ':' after the loop header", 0
s_exp_blk_for db "expected an indented block after 'for'", 0
s_exp_blk_lps db "expected an indented block after 'loops'", 0
s_no_float    db "decimal numbers are not supported yet, use int", 0
s_wrap        db "values next to text must be wrapped in '{ }'", 0
s_exp_value   db "expected value", 0
s_exp_number  db "expected number after '-'", 0

section .bss
alignb 4
pr_depth resd 1
alignb 8
ps_depth resq 1
ps_lastif resq 1
ps_gn     resq 1
ps_gstack resq 2 * (MAX_BLOCKS + 1)
ps_pflag  resb MAX_BLOCKS + 1
ps_vn     resq 1
ps_vstack resq 2 * (MAX_ELIF + 1)
pr_bmsg  resq 1
ps_stack resq MAX_BLOCKS + 1
pg_nops  resq 1
pg_ops   resd MAX_OR
pg_conn  resd MAX_OR
pg_oracc resd 1
pg_and   resd 1
pg_op    resd 1
pg_tok   resd 1
pg_rhs   resd 1

section .text

%macro CUR 0
    mov eax, dword [vr13]
    shl eax, 4
    push ebx
    mov ebx, [vr12]
    movzx eax, word [ebx + eax]
    pop ebx
%endmacro

%macro SYNERR 1
    lea ecx, [%1]
    mov edx, dword [vr13]
    jmp syn_error
%endmacro

syn_error:
    mov ebx, edx
    mov esi, ecx
    call msg_reset
    mov ecx, esi
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, ebx
    call diag_error_tok

XFUNC parse
    mov ecx, [g_ntok]
    inc ecx
    shl ecx, 5
    call mem_alloc
    mov [g_stmts], eax
    mov dword [vr14], eax
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
    mov dword [ps_depth], 0
    mov dword [ps_lastif], -1
    mov dword [ps_vn], 0
    mov dword [ps_gn], 0
    push ebx
    mov ebx, [g_tokens]
    mov dword [vr12], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr13]
    xor dword [vr13], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr15]
    xor dword [vr15], ebx
    pop ebx

.stmt:
    CUR
    cmp eax, TK_NL
    jne .not_nl
    inc dword [vr13]
    jmp .stmt
.not_nl:
    cmp eax, TK_EOF
    je .done
    cmp eax, TK_DEDENT
    je .dedent
    cmp eax, TK_INDENT
    je .unexpected_indent
    cmp eax, TK_ELSE
    je .else_stmt
    cmp eax, TK_ELIF
    je .elif_stmt
    push eax
    mov ecx, [ps_depth]
    call close_virtual
    pop eax
    cmp eax, TK_RPAREN
    je .rparen_stmt
    mov ecx, [ps_gn]
    test ecx, ecx
    jz .no_group
    shl ecx, 4
    lea edx, [ps_gstack]
    mov ecx, [edx + ecx - 8]
    cmp ecx, [ps_depth]
    je .group_level
.no_group:
    mov dword [ps_lastif], -1
    cmp eax, TK_IF
    je .if_stmt
    cmp eax, TK_FOR
    je .for_stmt
    cmp eax, TK_LOOPS
    je .loops_stmt
    cmp eax, TK_IDENT
    je .var_stmt
    cmp eax, TK_PRINT
    je .print_stmt
    cmp eax, TK_SHOW
    je .show_stmt
    SYNERR s_exp_stmt

.var_stmt:
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_DOT
    je .decl
    cmp eax, TK_EQ
    je .assign
    SYNERR s_exp_after_n
.decl:
    inc dword [vr13]
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
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_DECL
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_MODE], cx
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_EQ
    je .decl_eq
    SYNERR s_exp_eq_type
.decl_eq:
    inc dword [vr13]
    jmp .value_opt
.assign:
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_ASSIGN
    pop ebx
    inc dword [vr13]
.value_opt:
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 0
    pop ebx
    CUR
    cmp eax, TK_NL
    je .end_line
    cmp eax, TK_EOF
    je .end_line
    call parse_value
    call push_root
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 1
    pop ebx
    jmp .end_line

.print_stmt:
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_OUT
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_MODE], 0
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_MODETOK], NO_TOKEN
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_DOT
    jne .print_shr
    inc dword [vr13]
    CUR
    cmp eax, TK_IDENT
    je .print_mode
    SYNERR s_exp_mode
.print_mode:
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_MODETOK], esi
    pop esi
    pop ebx
    inc dword [vr13]
    CUR
.print_shr:
    cmp eax, TK_SHR
    je .out_body
    SYNERR s_exp_shr_p

.show_stmt:
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_OUT
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_MODE], 1
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_MODETOK], NO_TOKEN
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_SHR
    je .out_body
    SYNERR s_exp_shr_s

.out_body:
    inc dword [vr13]
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    mov ebx, [g_nroots]
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
    inc dword [vr13]
    call parse_value
    mov edi, eax
    CUR
    cmp eax, TK_RBRACE
    je .out_rbrace_ok
    SYNERR s_exp_rbrace
.out_rbrace_ok:
    inc dword [vr13]
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
    mov eax, [g_nroots]
    cmp eax, ebx
    je .bare_first
    SYNERR s_wrap
.bare_first:
    mov esi, dword [vr13]
    call parse_value
    call push_root
    CUR
    cmp eax, TK_NL
    je .out_done
    cmp eax, TK_EOF
    je .out_done
    mov dword [vr13], esi
    SYNERR s_wrap
.out_done:
    mov eax, [g_nroots]
    sub eax, ebx
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_NPARTS], eax
    pop ebx

.end_line:
    CUR
    cmp eax, TK_NL
    je .line_ok
    cmp eax, TK_EOF
    je .line_ok
    SYNERR s_exp_eol
.line_ok:
    add dword [vr14], S_SIZE
    jmp .stmt

.dedent:
    mov ecx, [ps_depth]
    call close_virtual
    mov ecx, [ps_gn]
    test ecx, ecx
    jz .dedent_nogroup
    shl ecx, 4
    lea edx, [ps_gstack]
    mov ecx, [edx + ecx - 8]
    cmp ecx, [ps_depth]
    je .done
.dedent_nogroup:
    mov eax, [ps_depth]
    lea ecx, [ps_pflag]
    cmp byte [ecx + eax - 1], 0
    je .dedent_plain
    SYNERR s_open_block
.dedent_plain:
    dec dword [ps_depth]
    mov eax, [ps_depth]
    lea ecx, [ps_stack]
    mov eax, [ecx + eax * 8]
    mov dword [ps_lastif], -1
    mov edx, eax
    shl edx, 5
    add edx, [g_stmts]
    cmp word [edx + S_KIND], SK_IF
    jne .dedent_kind
    mov [ps_lastif], eax
.dedent_kind:
    shl eax, 5
    add eax, [g_stmts]
    mov ecx, dword [vr14]
    sub ecx, [g_stmts]
    shr ecx, 5
    mov [eax + S_PIECES], ecx
    inc dword [vr13]
    jmp .stmt

.unexpected_indent:
    SYNERR s_unexp_ind

.group_start:
    push esi
    mov esi, [vr13]
    lea ebx, [esi + 1]
    pop esi
    add dword [vr13], 3
.gs_nl:
    CUR
    cmp eax, TK_NL
    jne .gs_start
    inc dword [vr13]
    jmp .gs_nl
.gs_start:
    mov ecx, dword [vr13]
    lea edx, [w_start]
    mov dword [vr8], 5
    call tok_word
    jne .gs_bad
    push ebx
    mov ebx, [vr13]
    lea eax, [ebx + 1]
    pop ebx
    shl eax, 4
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + eax], TK_DOT
    pop ebx
    jne .gs_bad
    push ebx
    mov ebx, [vr13]
    lea ecx, [ebx + 2]
    pop ebx
    mov edx, ebx
    call tok_same
    jne .gs_bad
    add dword [vr13], 3
    CUR
    cmp eax, TK_NL
    je .gs_ok
    SYNERR s_exp_eol
.gs_bad:
    lea esi, [s_exp_start]
    lea edi, [s_after_open]
    jmp .name_error
.gs_ok:
    inc dword [vr13]
    mov eax, [ps_gn]
    cmp eax, MAX_BLOCKS
    jb .gs_room
    SYNERR s_too_many_or
.gs_room:
    shl eax, 4
    lea ecx, [ps_gstack]
    mov [ecx + eax], ebx
    mov edx, [ps_depth]
    mov [ecx + eax + 8], edx
    inc dword [ps_gn]
    jmp .stmt

.group_name:
    mov eax, [ps_gn]
    shl eax, 4
    lea ecx, [ps_gstack]
    mov ebx, [ecx + eax - 16]
    ret

.name_error:
    push edi
    call msg_reset
    mov ecx, esi
    call msg_addz
    mov ecx, ebx
    call msg_tok
    pop ecx
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea ecx, [s_comma_q]
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, dword [vr13]
    call diag_error_tok

.group_level:
    call .group_name
    mov ecx, dword [vr13]
    lea edx, [w_stop]
    mov dword [vr8], 4
    call tok_word
    jne .count_block
    push ebx
    mov ebx, [vr13]
    lea eax, [ebx + 1]
    pop ebx
    shl eax, 4
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + eax], TK_DOT
    pop ebx
    jne .count_block
    push ebx
    mov ebx, [vr13]
    lea ecx, [ebx + 2]
    pop ebx
    mov edx, ebx
    call tok_same
    je .stop_ok
    add dword [vr13], 2
    jmp .stop_mismatch
.stop_ok:
    add dword [vr13], 3
.stop_nl:
    CUR
    cmp eax, TK_NL
    jne .stop_paren
    inc dword [vr13]
    jmp .stop_nl
.stop_paren:
    cmp eax, TK_RPAREN
    je .stop_close
    call msg_reset
    lea ecx, [s_exp_grp_rp]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea ecx, [s_q_close]
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, dword [vr13]
    call diag_error_tok
.stop_close:
    inc dword [vr13]
    dec dword [ps_gn]
    CUR
    cmp eax, TK_NL
    je .stmt
    cmp eax, TK_EOF
    je .stmt
    SYNERR s_exp_eol
.stop_mismatch:
    call msg_reset
    lea ecx, [s_stop_q]
    call msg_addz
    mov ecx, dword [vr13]
    call msg_tok
    lea ecx, [s_stop_match]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea ecx, [s_comma_q]
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, dword [vr13]
    call diag_error_tok

.count_block:
    CUR
    cmp eax, TK_INT
    je .count_ok
    cmp eax, TK_IDENT
    je .count_ok
    cmp eax, TK_LPAREN
    je .count_ok
    cmp eax, TK_MINUS
    je .count_ok
    call msg_reset
    lea ecx, [s_exp_count]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea ecx, [s_q_close]
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, dword [vr13]
    call diag_error_tok
.count_ok:
    mov dword [ps_lastif], -1
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_LOOPS
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_PIECES], 0
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 1
    pop ebx
    call parse_value
    call push_root
    CUR
    cmp eax, TK_LPAREN
    je .count_paren
    SYNERR s_exp_cnt_lp
.count_paren:
    inc dword [vr13]
    CUR
    cmp eax, TK_NL
    je .count_nl
    SYNERR s_exp_eol
.count_nl:
    inc dword [vr13]
    mov eax, [ps_depth]
    cmp eax, MAX_BLOCKS
    jb .count_room
    SYNERR s_too_many_or
.count_room:
    lea ecx, [ps_pflag]
    mov byte [ecx + eax], 1
    lea ecx, [ps_stack]
    mov edx, dword [vr14]
    sub edx, [g_stmts]
    shr edx, 5
    mov [ecx + eax * 8], edx
    inc dword [ps_depth]
    add dword [vr14], S_SIZE
    jmp .stmt

.rparen_stmt:
    mov eax, [ps_depth]
    test eax, eax
    jz .rparen_bad
    lea ecx, [ps_pflag]
    cmp byte [ecx + eax - 1], 0
    jne .rparen_close
.rparen_bad:
    SYNERR s_unexp_rp
.rparen_close:
    dec eax
    mov [ps_depth], eax
    lea ecx, [ps_stack]
    mov eax, [ecx + eax * 8]
    mov dword [ps_lastif], -1
    shl eax, 5
    add eax, [g_stmts]
    mov ecx, dword [vr14]
    sub ecx, [g_stmts]
    shr ecx, 5
    mov [eax + S_PIECES], ecx
    inc dword [vr13]
    CUR
    cmp eax, TK_NL
    je .stmt
    cmp eax, TK_EOF
    je .stmt
    SYNERR s_exp_eol

.elif_stmt:
    mov eax, [ps_lastif]
    cmp eax, -1
    jne .elif_ok
    SYNERR s_elif_no_if
.elif_ok:
    cmp dword [ps_vn], MAX_ELIF
    jb .elif_room
    SYNERR s_many_elif
.elif_room:
    mov dword [ps_lastif], -1
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_ELSE
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_VAR], eax
    pop ebx
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 0
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_PIECES], 0
    pop ebx
    mov eax, [ps_vn]
    lea ecx, [ps_vstack]
    shl eax, 4
    mov edx, dword [vr14]
    sub edx, [g_stmts]
    shr edx, 5
    mov [ecx + eax], edx
    mov edx, [ps_depth]
    mov [ecx + eax + 8], edx
    inc dword [ps_vn]
    add dword [vr14], S_SIZE
    jmp .if_stmt

.else_stmt:
    mov eax, [ps_lastif]
    cmp eax, -1
    jne .else_ok
    SYNERR s_else_no_if
.else_ok:
    mov dword [ps_lastif], -1
    lea ecx, [s_exp_blk_els]
    mov [pr_bmsg], ecx
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_ELSE
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_VAR], eax
    pop ebx
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 0
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_PIECES], 0
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_COLON
    je .if_colon
    SYNERR s_exp_colon_e

.if_stmt:
    lea eax, [s_exp_block]
    mov [pr_bmsg], eax
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_IF
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    inc dword [vr13]
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 1
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_PIECES], 0
    pop ebx
    call parse_cond
    call push_root
    CUR
    cmp eax, TK_COLON
    je .if_colon
    SYNERR s_exp_colon
.if_colon:
    inc dword [vr13]
    CUR
    cmp eax, TK_NL
    je .if_nl
    cmp eax, TK_EOF
    je .if_no_block
    SYNERR s_exp_eol
.if_nl:
    inc dword [vr13]
    CUR
    cmp eax, TK_NL
    je .if_nl
    cmp eax, TK_INDENT
    je .if_block
.if_no_block:
    mov ecx, [pr_bmsg]
    mov edx, dword [vr13]
    jmp syn_error
.if_block:
    inc dword [vr13]
    mov eax, [ps_depth]
    lea ecx, [ps_pflag]
    mov byte [ecx + eax], 0
    lea ecx, [ps_stack]
    mov edx, dword [vr14]
    sub edx, [g_stmts]
    shr edx, 5
    mov [ecx + eax * 8], edx
    inc dword [ps_depth]
    add dword [vr14], S_SIZE
    jmp .stmt

.for_stmt:
    lea eax, [s_exp_blk_for]
    mov [pr_bmsg], eax
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_FOR
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_PIECES], 0
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_IDENT
    je .for_var
    SYNERR s_exp_loopvar
.for_var:
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_IN
    je .for_in
    SYNERR s_exp_in
.for_in:
    inc dword [vr13]
    CUR
    cmp eax, TK_RANGE
    je .for_range
    SYNERR s_exp_range
.for_range:
    inc dword [vr13]
    CUR
    cmp eax, TK_LPAREN
    je .loop_count
    SYNERR s_exp_lp_r

.loops_stmt:
    lea eax, [s_exp_blk_lps]
    mov [pr_bmsg], eax
    push ebx
    mov ebx, [vr14]
    mov word [ebx + S_KIND], SK_LOOPS
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_PIECES], 0
    pop ebx
    push ebx
    push esi
    mov ebx, [vr14]
    mov esi, dword [vr13]
    mov [ebx + S_TOK], esi
    pop esi
    pop ebx
    inc dword [vr13]
    CUR
    cmp eax, TK_LPAREN
    je .loops_paren
    SYNERR s_exp_lp_l
.loops_paren:
    push ebx
    mov ebx, [vr13]
    lea eax, [ebx + 2]
    pop ebx
    shl eax, 4
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + eax - 16], TK_IDENT
    pop ebx
    jne .loop_count
    push ebx
    mov ebx, [vr12]
    cmp word [ebx + eax], TK_COMMA
    pop ebx
    jne .loop_count
    jmp .group_start

.loop_count:
    inc dword [vr13]
    mov eax, [g_nroots]
    push ebx
    mov ebx, [vr14]
    mov [ebx + S_PARTS], eax
    pop ebx
    push ebx
    mov ebx, [vr14]
    mov dword [ebx + S_NPARTS], 1
    pop ebx
    call parse_value
    call push_root
    CUR
    cmp eax, TK_RPAREN
    je .loop_rparen
    SYNERR s_exp_rparen
.loop_rparen:
    inc dword [vr13]
    CUR
    cmp eax, TK_COLON
    je .if_colon
    SYNERR s_exp_colon_l

.unknown_type:
    mov ebx, dword [vr13]
    call msg_reset
    lea ecx, [s_unk_type1]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea ecx, [s_unk_type2]
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, ebx
    call diag_error_tok

.done:
    cmp dword [ps_gn], 0
    je .done_groups
    call .group_name
    call msg_reset
    lea ecx, [s_missing_stop]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea ecx, [s_q_close]
    call msg_addz
    lea ecx, [s_syntax]
    mov edx, dword [vr13]
    call diag_error_tok
.done_groups:
    xor ecx, ecx
    call close_virtual
    mov eax, dword [vr14]
    sub eax, [g_stmts]
    shr eax, 5
    mov [g_nstmt], eax
    push ebx
    mov ebx, dword [vr15]
    mov [g_nparts], ebx
    pop ebx
    XENDF

tok_word:
    mov eax, ecx
    shl eax, 4
    add eax, [g_tokens]
    cmp word [eax + T_KIND], TK_IDENT
    jne .r
    push ebx
    mov ebx, dword [vr8]
    cmp [eax + T_LEN], ebx
    pop ebx
    jne .r
    push ebx
    mov ebx, [eax + T_OFF]
    mov dword [vr9], ebx
    pop ebx
    push ebx
    mov ebx, [g_src]
    add dword [vr9], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr10]
    xor dword [vr10], ebx
    pop ebx
.l:
    push ebx
    mov ebx, dword [vr8]
    cmp dword [vr10], ebx
    pop ebx
    jae .eq
    push ebx
    push esi
    mov ebx, [vr9]
    mov esi, [vr10]
    mov al, [ebx + esi]
    pop esi
    pop ebx
    push ebx
    mov ebx, [vr10]
    cmp al, [edx + ebx]
    pop ebx
    jne .r
    inc dword [vr10]
    jmp .l
.eq:
    cmp eax, eax
.r:
    ret

tok_same:
    mov eax, ecx
    shl eax, 4
    add eax, [g_tokens]
    mov dword [vr8], edx
    shl dword [vr8], 4
    push ebx
    mov ebx, [g_tokens]
    add dword [vr8], ebx
    pop ebx
    cmp word [eax + T_KIND], TK_IDENT
    jne .r
    push ebx
    mov ebx, [eax + T_LEN]
    mov dword [vr9], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr8]
    mov esi, [ebx + T_LEN]
    cmp dword [vr9], esi
    pop esi
    pop ebx
    jne .r
    push ebx
    mov ebx, [eax + T_OFF]
    mov dword [vr10], ebx
    pop ebx
    push ebx
    mov ebx, [g_src]
    add dword [vr10], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr8]
    mov esi, [ebx + T_OFF]
    mov dword [vr11], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, [g_src]
    add dword [vr11], ebx
    pop ebx
    xor ecx, ecx
.l:
    cmp ecx, dword [vr9]
    jae .eq
    push ebx
    mov ebx, [vr10]
    mov al, [ebx + ecx]
    pop ebx
    push ebx
    mov ebx, [vr11]
    cmp al, [ebx + ecx]
    pop ebx
    jne .r
    inc ecx
    jmp .l
.eq:
    cmp eax, eax
.r:
    ret

close_virtual:
    mov eax, [ps_vn]
    test eax, eax
    jz .r
    dec eax
    shl eax, 4
    lea edx, [ps_vstack]
    cmp [edx + eax + 8], ecx
    jb .r
    mov eax, [edx + eax]
    shl eax, 5
    add eax, [g_stmts]
    mov edx, dword [vr14]
    sub edx, [g_stmts]
    shr edx, 5
    mov [eax + S_PIECES], edx
    dec dword [ps_vn]
    jmp close_virtual
.r:
    ret

parse_value:
    mov dword [pr_depth], 0
    push dword [vr15]
    push dword [vr13]
    call parse_expr
    pop edx
    pop ecx
    push ebx
    mov ebx, dword [vr15]
    mov dword [vr8], ebx
    pop ebx
    sub dword [vr8], ecx
    cmp dword [vr8], MAX_NODES
    ja .too_long
    ret
.too_long:
    mov dword [vr13], edx
    SYNERR s_too_long

push_root:
    mov ecx, [g_nroots]
    mov edx, [g_roots]
    mov [edx + ecx * 4], eax
    inc dword [g_nroots]
    ret

new_node:
    push ebx
    mov ebx, dword [vr15]
    mov dword [vr10], ebx
    pop ebx
    shl dword [vr10], 4
    push ebx
    mov ebx, [g_parts]
    add dword [vr10], ebx
    pop ebx
    push ebx
    mov ebx, [vr10]
    mov dword [ebx], 0
    pop ebx
    push ebx
    mov ebx, [vr10]
    mov dword [ebx + 8], 0
    pop ebx
    push ebx
    mov ebx, [vr10]
    mov [ebx + V_KIND], cl
    pop ebx
    push ebx
    mov ebx, [vr10]
    mov [ebx + V_TOK], edx
    pop ebx
    mov eax, dword [vr15]
    inc dword [vr15]
    ret

new_op:
    push eax
    mov ecx, VK_EXPR
    mov edx, dword [vr11]
    call new_node
    pop edx
    push ebx
    push ecx
    mov ebx, [vr10]
    mov cl, byte [vr9]
    mov [ebx + V_NEG], cl
    pop ecx
    pop ebx
    push ebx
    mov ebx, [vr10]
    mov [ebx + V_DATA], edx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr10]
    mov esi, dword [vr8]
    mov [ebx + V_DATA + 4], esi
    pop esi
    pop ebx
    ret

parse_expr:
    call parse_term
.loop:
    mov dword [vr8], eax
    CUR
    mov dword [vr9], OP_ADD
    cmp eax, TK_PLUS
    je .op
    mov dword [vr9], OP_SUB
    cmp eax, TK_MINUS
    je .op
    mov eax, dword [vr8]
    ret
.op:
    push dword [vr8]
    push dword [vr9]
    push dword [vr13]
    inc dword [vr13]
    call parse_term
    mov dword [vr8], eax
    pop dword [vr11]
    pop dword [vr9]
    pop eax
    call new_op
    jmp .loop

parse_term:
    call parse_factor
.loop:
    mov dword [vr8], eax
    CUR
    mov dword [vr9], OP_MUL
    cmp eax, TK_STAR
    je .op
    mov dword [vr9], OP_DIV
    cmp eax, TK_SLASH
    je .op
    mov dword [vr9], OP_MOD
    cmp eax, TK_PERCENT
    je .op
    mov eax, dword [vr8]
    ret
.op:
    push dword [vr8]
    push dword [vr9]
    push dword [vr13]
    inc dword [vr13]
    call parse_factor
    mov dword [vr8], eax
    pop dword [vr11]
    pop dword [vr9]
    pop eax
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
    mov eax, dword [vr13]
    inc eax
    shl eax, 4
    add eax, dword [vr12]
    movzx eax, word [eax]
    cmp eax, TK_INT
    jne .negate
    inc dword [vr13]
    mov ecx, VK_INT
    mov edx, dword [vr13]
    call new_node
    push ebx
    mov ebx, [vr10]
    mov byte [ebx + V_NEG], 1
    pop ebx
    inc dword [vr13]
    dec dword [pr_depth]
    ret
.negate:
    push dword [vr13]
    inc dword [vr13]
    call parse_factor
    pop dword [vr11]
    mov dword [vr9], OP_NEG
    mov dword [vr8], NO_EXPR
    call new_op
    dec dword [pr_depth]
    ret
.paren:
    inc dword [vr13]
    call parse_expr
    mov dword [vr8], eax
    CUR
    cmp eax, TK_RPAREN
    je .paren_ok
    SYNERR s_exp_rparen
.paren_ok:
    inc dword [vr13]
    mov eax, dword [vr8]
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
    mov edx, dword [vr13]
    call new_node
    push ebx
    mov ebx, [vr10]
    mov dword [ebx + V_DATA], 1
    pop ebx
    inc dword [vr13]
    ret
.false:
    mov ecx, VK_BOOL
.leaf:
    mov edx, dword [vr13]
    call new_node
    inc dword [vr13]
    ret
.fnum:
    SYNERR s_no_float

parse_string:
    mov ecx, VK_STR
    mov edx, dword [vr13]
    call new_node
    inc dword [vr13]
    ret

new_pair:
    push eax
    call new_node
    pop edx
    push ebx
    push ecx
    mov ebx, [vr10]
    mov cl, byte [vr9]
    mov [ebx + V_NEG], cl
    pop ecx
    pop ebx
    push ebx
    mov ebx, [vr10]
    mov [ebx + V_DATA], edx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr10]
    mov esi, dword [vr8]
    mov [ebx + V_DATA + 4], esi
    pop esi
    pop ebx
    ret

parse_cond:
    call parse_and
.loop:
    push eax
    CUR
    cmp eax, TK_OR
    jne .done
    push dword [vr13]
    inc dword [vr13]
    call parse_and
    mov dword [vr8], eax
    pop edx
    pop eax
    mov ecx, VK_OR
    push ebx
    mov ebx, dword [vr9]
    xor dword [vr9], ebx
    pop ebx
    call new_pair
    jmp .loop
.done:
    pop eax
    ret

parse_and:
    call parse_group
.loop:
    push eax
    CUR
    cmp eax, TK_AND
    jne .done
    push dword [vr13]
    inc dword [vr13]
    call parse_group
    mov dword [vr8], eax
    pop edx
    pop eax
    mov ecx, VK_AND
    push ebx
    mov ebx, dword [vr9]
    xor dword [vr9], ebx
    pop ebx
    call new_pair
    jmp .loop
.done:
    pop eax
    ret

parse_group:
    mov dword [pg_nops], 0
.operand:
    mov eax, [pg_nops]
    cmp eax, MAX_OR
    jae .too_many
    push eax
    call parse_value
    pop ecx
    lea edx, [pg_ops]
    mov [edx + ecx * 4], eax
    inc dword [pg_nops]
    CUR
    mov ecx, VK_OR
    cmp eax, TK_OR
    je .connector
    mov ecx, VK_AND
    cmp eax, TK_AND
    jne .compare
.connector:
    mov eax, [pg_nops]
    cmp eax, MAX_OR
    jae .too_many
    lea edx, [pg_conn]
    mov [edx + eax * 4], ecx
    inc dword [vr13]
    jmp .operand
.compare:
    mov dword [vr9], CMP_IS
    cmp eax, TK_IS
    je .have_op
    mov dword [vr9], CMP_ISNOT
    cmp eax, TK_ISNOT
    je .have_op
    mov dword [vr9], CMP_LT
    cmp eax, TK_LT
    je .have_op
    mov dword [vr9], CMP_GT
    cmp eax, TK_GT
    je .have_op
    mov dword [vr9], CMP_LE
    cmp eax, TK_LE
    je .have_op
    mov dword [vr9], CMP_GE
    cmp eax, TK_GE
    je .have_op
    SYNERR s_exp_cmp
.have_op:
    push ebx
    mov ebx, dword [vr9]
    mov [pg_op], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr13]
    mov [pg_tok], ebx
    pop ebx
    inc dword [vr13]
    call parse_value
    mov [pg_rhs], eax
    xor esi, esi
.cmps:
    cmp esi, [pg_nops]
    jae .cmps_done
    lea edx, [pg_ops]
    mov eax, [edx + esi * 4]
    push ebx
    mov ebx, [pg_rhs]
    mov dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, [pg_op]
    mov dword [vr9], ebx
    pop ebx
    mov edx, [pg_tok]
    mov ecx, VK_CMP
    call new_pair
    lea edx, [pg_ops]
    mov [edx + esi * 4], eax
    inc esi
    jmp .cmps
.cmps_done:
    mov dword [pg_oracc], -1
    mov eax, [pg_ops]
    mov [pg_and], eax
    mov esi, 1
.chain:
    cmp esi, [pg_nops]
    jae .chain_done
    lea edx, [pg_conn]
    cmp dword [edx + esi * 4], VK_AND
    jne .chain_or
    mov eax, [pg_and]
    lea edx, [pg_ops]
    push ebx
    mov ebx, [edx + esi * 4]
    mov dword [vr8], ebx
    pop ebx
    mov edx, [pg_tok]
    mov ecx, VK_AND
    push ebx
    mov ebx, dword [vr9]
    xor dword [vr9], ebx
    pop ebx
    call new_pair
    mov [pg_and], eax
    jmp .chain_next
.chain_or:
    call .flush_and
    lea edx, [pg_ops]
    mov eax, [edx + esi * 4]
    mov [pg_and], eax
.chain_next:
    inc esi
    jmp .chain
.chain_done:
    call .flush_and
    mov eax, [pg_oracc]
    ret
.flush_and:
    mov eax, [pg_and]
    cmp dword [pg_oracc], -1
    je .flush_set
    mov dword [vr8], eax
    mov eax, [pg_oracc]
    mov edx, [pg_tok]
    mov ecx, VK_OR
    push ebx
    mov ebx, dword [vr9]
    xor dword [vr9], ebx
    pop ebx
    call new_pair
.flush_set:
    mov [pg_oracc], eax
    ret
.too_many:
    SYNERR s_too_many_or
