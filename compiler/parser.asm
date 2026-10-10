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
s_brk_out     db "'break' outside a loop", 0
s_cont_out    db "'continue' outside a loop", 0
s_exp_bname   db "expected a loop name after 'break.'", 0
s_no_group    db "no staged loop named '", 0
s_no_group2   db "' around this 'break'", 0
w_takedata    db "takedata", 0

section .bss
alignb 4
pr_depth resd 1
alignb 8
ps_depth resq 1
ps_lastif resq 1
ps_gn     resq 1
ps_gstack resq 2 * (MAX_BLOCKS + 1)
ps_gstmt  resq MAX_BLOCKS + 1
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
    mov qword [ps_depth], 0
    mov qword [ps_lastif], -1
    mov qword [ps_vn], 0
    mov qword [ps_gn], 0
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
    cmp eax, TK_DEDENT
    je .dedent
    cmp eax, TK_INDENT
    je .unexpected_indent
    cmp eax, TK_ELSE
    je .else_stmt
    cmp eax, TK_ELIF
    je .elif_stmt
    push rax
    mov rcx, [ps_depth]
    call close_virtual
    pop rax
    cmp eax, TK_RPAREN
    je .rparen_stmt
    mov rcx, [ps_gn]
    test rcx, rcx
    jz .no_group
    shl rcx, 4
    lea rdx, [ps_gstack]
    mov rcx, [rdx + rcx - 8]
    cmp rcx, [ps_depth]
    je .group_level
.no_group:
    mov qword [ps_lastif], -1
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
    cmp eax, TK_BREAK
    je .break_stmt
    cmp eax, TK_CONTINUE
    je .continue_stmt
    SYNERR s_exp_stmt

.continue_stmt:
    mov word [r14 + S_KIND], SK_CONTINUE
    lea rsi, [s_cont_out]
    jmp .jump_stmt
.break_stmt:
    mov word [r14 + S_KIND], SK_BREAK
    lea rsi, [s_brk_out]
.jump_stmt:
    mov [r14 + S_TOK], r13d
    mov word [r14 + S_MODE], 0
    mov dword [r14 + S_NPARTS], 0
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_PIECES], 0
    inc r13
    cmp word [r14 + S_KIND], SK_BREAK
    jne .jump_inner
    CUR
    cmp eax, TK_DOT
    je .break_group
.jump_inner:
    mov rcx, [ps_depth]
.jump_find:
    test rcx, rcx
    jz .jump_none
    dec rcx
    lea rdx, [ps_stack]
    mov rax, [rdx + rcx * 8]
    mov rdx, rax
    shl rdx, 5
    add rdx, [g_stmts]
    cmp word [rdx + S_KIND], SK_FOR
    je .jump_found
    cmp word [rdx + S_KIND], SK_LOOPS
    jne .jump_find
.jump_found:
    mov [r14 + S_VAR], eax
    or word [rdx + S_MODE], 1
    jmp .end_line
.jump_none:
    mov rcx, rsi
    mov edx, [r14 + S_TOK]
    jmp syn_error
.break_group:
    inc r13
    CUR
    cmp eax, TK_IDENT
    je .bg_name
    SYNERR s_exp_bname
.bg_name:
    mov rsi, [ps_gn]
.bg_find:
    test rsi, rsi
    jz .bg_none
    dec rsi
    mov rax, rsi
    shl rax, 4
    lea rcx, [ps_gstack]
    mov rcx, [rcx + rax]
    mov edx, r13d
    call tok_same
    jne .bg_find
    mov word [r14 + S_MODE], 1
    lea rcx, [ps_gstmt]
    mov rax, [rcx + rsi * 8]
    mov [r14 + S_VAR], eax
    shl rax, 5
    add rax, [g_stmts]
    or word [rax + S_MODE], 2
    shl rsi, 4
    lea rcx, [ps_gstack]
    mov rcx, [rcx + rsi + 8]
.bg_flag:
    cmp rcx, [ps_depth]
    jae .bg_done
    lea rdx, [ps_stack]
    mov rax, [rdx + rcx * 8]
    shl rax, 5
    add rax, [g_stmts]
    cmp word [rax + S_KIND], SK_FOR
    je .bg_mark
    cmp word [rax + S_KIND], SK_LOOPS
    jne .bg_next
.bg_mark:
    or word [rax + S_MODE], 1
.bg_next:
    inc rcx
    jmp .bg_flag
.bg_done:
    inc r13
    jmp .end_line
.bg_none:
    mov ebx, r13d
    call msg_reset
    lea rcx, [s_no_group]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_no_group2]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, ebx
    call diag_error_tok

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

.dedent:
    mov rcx, [ps_depth]
    call close_virtual
    mov rcx, [ps_gn]
    test rcx, rcx
    jz .dedent_nogroup
    shl rcx, 4
    lea rdx, [ps_gstack]
    mov rcx, [rdx + rcx - 8]
    cmp rcx, [ps_depth]
    je .done
.dedent_nogroup:
    mov rax, [ps_depth]
    lea rcx, [ps_pflag]
    cmp byte [rcx + rax - 1], 0
    je .dedent_plain
    SYNERR s_open_block
.dedent_plain:
    dec qword [ps_depth]
    mov rax, [ps_depth]
    lea rcx, [ps_stack]
    mov rax, [rcx + rax * 8]
    mov qword [ps_lastif], -1
    mov rdx, rax
    shl rdx, 5
    add rdx, [g_stmts]
    cmp word [rdx + S_KIND], SK_IF
    jne .dedent_kind
    mov [ps_lastif], rax
.dedent_kind:
    shl rax, 5
    add rax, [g_stmts]
    mov rcx, r14
    sub rcx, [g_stmts]
    shr rcx, 5
    mov [rax + S_PIECES], ecx
    inc r13
    jmp .stmt

.unexpected_indent:
    SYNERR s_unexp_ind

.group_start:
    lea ebx, [r13d + 1]
    add r13, 3
.gs_nl:
    CUR
    cmp eax, TK_NL
    jne .gs_start
    inc r13
    jmp .gs_nl
.gs_start:
    mov ecx, r13d
    lea rdx, [w_start]
    mov r8d, 5
    call tok_word
    jne .gs_bad
    lea rax, [r13 + 1]
    shl rax, 4
    cmp word [r12 + rax], TK_DOT
    jne .gs_bad
    lea ecx, [r13d + 2]
    mov edx, ebx
    call tok_same
    jne .gs_bad
    add r13, 3
    CUR
    cmp eax, TK_NL
    je .gs_ok
    SYNERR s_exp_eol
.gs_bad:
    lea rsi, [s_exp_start]
    lea rdi, [s_after_open]
    jmp .name_error
.gs_ok:
    inc r13
    mov rax, [ps_gn]
    cmp rax, MAX_BLOCKS
    jb .gs_room
    SYNERR s_too_many_or
.gs_room:
    mov word [r14 + S_KIND], SK_GROUP
    mov word [r14 + S_MODE], 0
    mov [r14 + S_TOK], ebx
    mov dword [r14 + S_VAR], 0
    mov dword [r14 + S_NPARTS], 0
    mov rdx, [g_nroots]
    mov [r14 + S_PARTS], edx
    mov dword [r14 + S_PIECES], 0
    mov dword [r14 + S_MODETOK], 0
    mov dword [r14 + S_NPIECES], 0
    lea rcx, [ps_gstmt]
    mov rdx, r14
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rcx + rax * 8], rdx
    add r14, S_SIZE
    shl rax, 4
    lea rcx, [ps_gstack]
    mov [rcx + rax], rbx
    mov rdx, [ps_depth]
    mov [rcx + rax + 8], rdx
    inc qword [ps_gn]
    jmp .stmt

.group_name:
    mov rax, [ps_gn]
    shl rax, 4
    lea rcx, [ps_gstack]
    mov ebx, [rcx + rax - 16]
    ret

.name_error:
    push rdi
    call msg_reset
    mov rcx, rsi
    call msg_addz
    mov ecx, ebx
    call msg_tok
    pop rcx
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_comma_q]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, r13d
    call diag_error_tok

.group_level:
    call .group_name
    mov ecx, r13d
    lea rdx, [w_stop]
    mov r8d, 4
    call tok_word
    jne .count_block
    lea rax, [r13 + 1]
    shl rax, 4
    cmp word [r12 + rax], TK_DOT
    jne .count_block
    lea ecx, [r13d + 2]
    mov edx, ebx
    call tok_same
    je .stop_ok
    add r13, 2
    jmp .stop_mismatch
.stop_ok:
    add r13, 3
.stop_nl:
    CUR
    cmp eax, TK_NL
    jne .stop_paren
    inc r13
    jmp .stop_nl
.stop_paren:
    cmp eax, TK_RPAREN
    je .stop_close
    call msg_reset
    lea rcx, [s_exp_grp_rp]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_q_close]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, r13d
    call diag_error_tok
.stop_close:
    inc r13
    dec qword [ps_gn]
    mov rax, [ps_gn]
    lea rcx, [ps_gstmt]
    mov rax, [rcx + rax * 8]
    shl rax, 5
    add rax, [g_stmts]
    mov rcx, r14
    sub rcx, [g_stmts]
    shr rcx, 5
    mov [rax + S_PIECES], ecx
    CUR
    cmp eax, TK_NL
    je .stmt
    cmp eax, TK_EOF
    je .stmt
    SYNERR s_exp_eol
.stop_mismatch:
    call msg_reset
    lea rcx, [s_stop_q]
    call msg_addz
    mov ecx, r13d
    call msg_tok
    lea rcx, [s_stop_match]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_comma_q]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, r13d
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
    lea rcx, [s_exp_count]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_q_close]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, r13d
    call diag_error_tok
.count_ok:
    mov qword [ps_lastif], -1
    mov word [r14 + S_KIND], SK_LOOPS
    mov word [r14 + S_MODE], 0
    mov dword [r14 + S_PIECES], 0
    mov [r14 + S_TOK], r13d
    mov rax, [ps_gn]
    lea rcx, [ps_gstmt]
    mov rax, [rcx + rax * 8 - 8]
    inc eax
    mov [r14 + S_MODETOK], eax
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_NPARTS], 1
    call parse_value
    call push_root
    CUR
    cmp eax, TK_LPAREN
    je .count_paren
    SYNERR s_exp_cnt_lp
.count_paren:
    inc r13
    CUR
    cmp eax, TK_NL
    je .count_nl
    SYNERR s_exp_eol
.count_nl:
    inc r13
    mov rax, [ps_depth]
    cmp rax, MAX_BLOCKS
    jb .count_room
    SYNERR s_too_many_or
.count_room:
    lea rcx, [ps_pflag]
    mov byte [rcx + rax], 1
    lea rcx, [ps_stack]
    mov rdx, r14
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rcx + rax * 8], rdx
    inc qword [ps_depth]
    add r14, S_SIZE
    jmp .stmt

.rparen_stmt:
    mov rax, [ps_depth]
    test rax, rax
    jz .rparen_bad
    lea rcx, [ps_pflag]
    cmp byte [rcx + rax - 1], 0
    jne .rparen_close
.rparen_bad:
    SYNERR s_unexp_rp
.rparen_close:
    dec rax
    mov [ps_depth], rax
    lea rcx, [ps_stack]
    mov rax, [rcx + rax * 8]
    mov qword [ps_lastif], -1
    shl rax, 5
    add rax, [g_stmts]
    mov rcx, r14
    sub rcx, [g_stmts]
    shr rcx, 5
    mov [rax + S_PIECES], ecx
    inc r13
    CUR
    cmp eax, TK_NL
    je .stmt
    cmp eax, TK_EOF
    je .stmt
    SYNERR s_exp_eol

.elif_stmt:
    mov rax, [ps_lastif]
    cmp rax, -1
    jne .elif_ok
    SYNERR s_elif_no_if
.elif_ok:
    cmp qword [ps_vn], MAX_ELIF
    jb .elif_room
    SYNERR s_many_elif
.elif_room:
    mov qword [ps_lastif], -1
    mov word [r14 + S_KIND], SK_ELSE
    mov [r14 + S_TOK], r13d
    mov [r14 + S_VAR], eax
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_NPARTS], 0
    mov dword [r14 + S_PIECES], 0
    mov rax, [ps_vn]
    lea rcx, [ps_vstack]
    shl rax, 4
    mov rdx, r14
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rcx + rax], rdx
    mov rdx, [ps_depth]
    mov [rcx + rax + 8], rdx
    inc qword [ps_vn]
    add r14, S_SIZE
    jmp .if_stmt

.else_stmt:
    mov rax, [ps_lastif]
    cmp rax, -1
    jne .else_ok
    SYNERR s_else_no_if
.else_ok:
    mov qword [ps_lastif], -1
    lea rcx, [s_exp_blk_els]
    mov [pr_bmsg], rcx
    mov word [r14 + S_KIND], SK_ELSE
    mov [r14 + S_TOK], r13d
    mov [r14 + S_VAR], eax
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_NPARTS], 0
    mov dword [r14 + S_PIECES], 0
    inc r13
    CUR
    cmp eax, TK_COLON
    je .if_colon
    SYNERR s_exp_colon_e

.if_stmt:
    lea rax, [s_exp_block]
    mov [pr_bmsg], rax
    mov word [r14 + S_KIND], SK_IF
    mov [r14 + S_TOK], r13d
    inc r13
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_NPARTS], 1
    mov dword [r14 + S_PIECES], 0
    call parse_cond
    call push_root
    CUR
    cmp eax, TK_COLON
    je .if_colon
    SYNERR s_exp_colon
.if_colon:
    inc r13
    CUR
    cmp eax, TK_NL
    je .if_nl
    cmp eax, TK_EOF
    je .if_no_block
    SYNERR s_exp_eol
.if_nl:
    inc r13
    CUR
    cmp eax, TK_NL
    je .if_nl
    cmp eax, TK_INDENT
    je .if_block
.if_no_block:
    mov rcx, [pr_bmsg]
    mov edx, r13d
    jmp syn_error
.if_block:
    inc r13
    mov rax, [ps_depth]
    lea rcx, [ps_pflag]
    mov byte [rcx + rax], 0
    lea rcx, [ps_stack]
    mov rdx, r14
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rcx + rax * 8], rdx
    inc qword [ps_depth]
    add r14, S_SIZE
    jmp .stmt

.for_stmt:
    lea rax, [s_exp_blk_for]
    mov [pr_bmsg], rax
    mov word [r14 + S_KIND], SK_FOR
    mov word [r14 + S_MODE], 0
    mov dword [r14 + S_MODETOK], 0
    mov dword [r14 + S_PIECES], 0
    inc r13
    CUR
    cmp eax, TK_IDENT
    je .for_var
    SYNERR s_exp_loopvar
.for_var:
    mov [r14 + S_TOK], r13d
    inc r13
    CUR
    cmp eax, TK_IN
    je .for_in
    SYNERR s_exp_in
.for_in:
    inc r13
    CUR
    cmp eax, TK_RANGE
    je .for_range
    SYNERR s_exp_range
.for_range:
    inc r13
    CUR
    cmp eax, TK_LPAREN
    je .loop_count
    SYNERR s_exp_lp_r

.loops_stmt:
    lea rax, [s_exp_blk_lps]
    mov [pr_bmsg], rax
    mov word [r14 + S_KIND], SK_LOOPS
    mov word [r14 + S_MODE], 0
    mov dword [r14 + S_MODETOK], 0
    mov dword [r14 + S_PIECES], 0
    mov [r14 + S_TOK], r13d
    inc r13
    CUR
    cmp eax, TK_LPAREN
    je .loops_paren
    SYNERR s_exp_lp_l
.loops_paren:
    lea rax, [r13 + 2]
    shl rax, 4
    cmp word [r12 + rax - 16], TK_IDENT
    jne .loop_count
    cmp word [r12 + rax], TK_COMMA
    jne .loop_count
    jmp .group_start

.loop_count:
    inc r13
    mov rax, [g_nroots]
    mov [r14 + S_PARTS], eax
    mov dword [r14 + S_NPARTS], 1
    call parse_value
    call push_root
    CUR
    cmp eax, TK_RPAREN
    je .loop_rparen
    SYNERR s_exp_rparen
.loop_rparen:
    inc r13
    CUR
    cmp eax, TK_COLON
    je .if_colon
    SYNERR s_exp_colon_l

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
    cmp qword [ps_gn], 0
    je .done_groups
    call .group_name
    call msg_reset
    lea rcx, [s_missing_stop]
    call msg_addz
    mov ecx, ebx
    call msg_tok
    lea rcx, [s_q_close]
    call msg_addz
    lea rcx, [s_syntax]
    mov edx, r13d
    call diag_error_tok
.done_groups:
    xor ecx, ecx
    call close_virtual
    mov rax, r14
    sub rax, [g_stmts]
    shr rax, 5
    mov [g_nstmt], rax
    mov [g_nparts], r15
    ENDF

tok_word:
    mov rax, rcx
    shl rax, 4
    add rax, [g_tokens]
    cmp word [rax + T_KIND], TK_IDENT
    jne .r
    cmp [rax + T_LEN], r8d
    jne .r
    mov r9d, [rax + T_OFF]
    add r9, [g_src]
    xor r10d, r10d
.l:
    cmp r10d, r8d
    jae .eq
    mov al, [r9 + r10]
    cmp al, [rdx + r10]
    jne .r
    inc r10d
    jmp .l
.eq:
    cmp eax, eax
.r:
    ret

tok_same:
    mov rax, rcx
    shl rax, 4
    add rax, [g_tokens]
    mov r8, rdx
    shl r8, 4
    add r8, [g_tokens]
    cmp word [rax + T_KIND], TK_IDENT
    jne .r
    mov r9d, [rax + T_LEN]
    cmp r9d, [r8 + T_LEN]
    jne .r
    mov r10d, [rax + T_OFF]
    add r10, [g_src]
    mov r11d, [r8 + T_OFF]
    add r11, [g_src]
    xor ecx, ecx
.l:
    cmp ecx, r9d
    jae .eq
    mov al, [r10 + rcx]
    cmp al, [r11 + rcx]
    jne .r
    inc ecx
    jmp .l
.eq:
    cmp eax, eax
.r:
    ret

close_virtual:
    mov rax, [ps_vn]
    test rax, rax
    jz .r
    dec rax
    shl rax, 4
    lea rdx, [ps_vstack]
    cmp [rdx + rax + 8], rcx
    jb .r
    mov rax, [rdx + rax]
    shl rax, 5
    add rax, [g_stmts]
    mov rdx, r14
    sub rdx, [g_stmts]
    shr rdx, 5
    mov [rax + S_PIECES], edx
    dec qword [ps_vn]
    jmp close_virtual
.r:
    ret

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
    je .ident
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
.ident:
    lea rax, [r13 + 1]
    shl rax, 4
    cmp word [r12 + rax], TK_DOT
    jne .leaf
    cmp word [r12 + rax + 16], TK_IDENT
    jne .leaf
    lea ecx, [r13d + 2]
    lea rdx, [w_takedata]
    mov r8d, 8
    call tok_word
    mov ecx, VK_VAR
    jne .leaf
    push rsi
    mov rsi, [ps_gn]
.take_find:
    mov eax, -1
    test rsi, rsi
    jz .take_set
    dec rsi
    mov rax, rsi
    shl rax, 4
    lea rcx, [ps_gstack]
    mov rcx, [rcx + rax]
    mov edx, r13d
    call tok_same
    jne .take_find
    lea rcx, [ps_gstmt]
    mov rax, [rcx + rsi * 8]
.take_set:
    pop rsi
    mov r9d, eax
    mov ecx, VK_TAKE
    mov edx, r13d
    call new_node
    mov [r10 + V_DATA], r9d
    cmp r9d, -1
    je .take_done
    mov r8d, r9d
    shl r8, 5
    add r8, [g_stmts]
    or word [r8 + S_MODE], 1
.take_done:
    add r13, 3
    ret

parse_string:
    mov ecx, VK_STR
    mov edx, r13d
    call new_node
    inc r13
    ret

new_pair:
    push rax
    call new_node
    pop rdx
    mov [r10 + V_NEG], r9b
    mov [r10 + V_DATA], edx
    mov [r10 + V_DATA + 4], r8d
    ret

parse_cond:
    call parse_and
.loop:
    push rax
    CUR
    cmp eax, TK_OR
    jne .done
    push r13
    inc r13
    call parse_and
    mov r8d, eax
    pop rdx
    pop rax
    mov ecx, VK_OR
    xor r9d, r9d
    call new_pair
    jmp .loop
.done:
    pop rax
    ret

parse_and:
    call parse_group
.loop:
    push rax
    CUR
    cmp eax, TK_AND
    jne .done
    push r13
    inc r13
    call parse_group
    mov r8d, eax
    pop rdx
    pop rax
    mov ecx, VK_AND
    xor r9d, r9d
    call new_pair
    jmp .loop
.done:
    pop rax
    ret

parse_group:
    mov qword [pg_nops], 0
.operand:
    mov rax, [pg_nops]
    cmp rax, MAX_OR
    jae .too_many
    push rax
    call parse_value
    pop rcx
    lea rdx, [pg_ops]
    mov [rdx + rcx * 4], eax
    inc qword [pg_nops]
    CUR
    mov ecx, VK_OR
    cmp eax, TK_OR
    je .connector
    mov ecx, VK_AND
    cmp eax, TK_AND
    jne .compare
.connector:
    mov rax, [pg_nops]
    cmp rax, MAX_OR
    jae .too_many
    lea rdx, [pg_conn]
    mov [rdx + rax * 4], ecx
    inc r13
    jmp .operand
.compare:
    mov r9d, CMP_IS
    cmp eax, TK_IS
    je .have_op
    mov r9d, CMP_ISNOT
    cmp eax, TK_ISNOT
    je .have_op
    mov r9d, CMP_LT
    cmp eax, TK_LT
    je .have_op
    mov r9d, CMP_GT
    cmp eax, TK_GT
    je .have_op
    mov r9d, CMP_LE
    cmp eax, TK_LE
    je .have_op
    mov r9d, CMP_GE
    cmp eax, TK_GE
    je .have_op
    SYNERR s_exp_cmp
.have_op:
    mov [pg_op], r9d
    mov [pg_tok], r13d
    inc r13
    call parse_value
    mov [pg_rhs], eax
    xor esi, esi
.cmps:
    cmp rsi, [pg_nops]
    jae .cmps_done
    lea rdx, [pg_ops]
    mov eax, [rdx + rsi * 4]
    mov r8d, [pg_rhs]
    mov r9d, [pg_op]
    mov edx, [pg_tok]
    mov ecx, VK_CMP
    call new_pair
    lea rdx, [pg_ops]
    mov [rdx + rsi * 4], eax
    inc rsi
    jmp .cmps
.cmps_done:
    mov dword [pg_oracc], -1
    mov eax, [pg_ops]
    mov [pg_and], eax
    mov esi, 1
.chain:
    cmp rsi, [pg_nops]
    jae .chain_done
    lea rdx, [pg_conn]
    cmp dword [rdx + rsi * 4], VK_AND
    jne .chain_or
    mov eax, [pg_and]
    lea rdx, [pg_ops]
    mov r8d, [rdx + rsi * 4]
    mov edx, [pg_tok]
    mov ecx, VK_AND
    xor r9d, r9d
    call new_pair
    mov [pg_and], eax
    jmp .chain_next
.chain_or:
    call .flush_and
    lea rdx, [pg_ops]
    mov eax, [rdx + rsi * 4]
    mov [pg_and], eax
.chain_next:
    inc rsi
    jmp .chain
.chain_done:
    call .flush_and
    mov eax, [pg_oracc]
    ret
.flush_and:
    mov eax, [pg_and]
    cmp dword [pg_oracc], -1
    je .flush_set
    mov r8d, eax
    mov eax, [pg_oracc]
    mov edx, [pg_tok]
    mov ecx, VK_OR
    xor r9d, r9d
    call new_pair
.flush_set:
    mov [pg_oracc], eax
    ret
.too_many:
    SYNERR s_too_many_or
