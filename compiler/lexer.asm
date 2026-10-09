%include "defs.inc"
%include "state.inc"

section .rodata
s_lexical   db "lexical", 0
s_unexp_ch  db "unexpected character '", 0
s_unexp_by  db "unexpected byte 0x", 0
s_unterm    db "unterminated string", 0
s_unk_esc   db "unknown escape '\", 0
s_name_long db "variable name is longer than 64 characters", 0
s_quote     db "'", 0
s_mixed     db "inconsistent use of tabs and spaces in indentation", 0
s_unindent  db "unindent does not match any outer indentation level", 0
s_too_nest  db "blocks are nested more than 100 levels deep", 0
hex_digits  db "0123456789ABCDEF"

keywords:
    db 5, TK_PRINT, "print"
    db 4, TK_SHOW,  "show"
    db 3, TK_KINT,  "int"
    db 3, TK_KSTR,  "str"
    db 4, TK_KBOOL, "bool"
    db 4, TK_TRUE,  "true"
    db 5, TK_FALSE, "false"
    db 4, TK_NULL,  "null"
    db 2, TK_IF,    "if"
    db 2, TK_IS,    "is"
    db 5, TK_ISNOT, "isnot"
    db 2, TK_OR,    "or"
    db 3, TK_AND,   "and"
    db 3, TK_FOR,   "for"
    db 2, TK_IN,    "in"
    db 5, TK_RANGE, "range"
    db 5, TK_LOOPS, "loops"
    db 4, TK_ELSE,  "else"
    db 4, TK_ELIF,  "elif"
    db 0

global escape_chars
escape_chars db "nt0r\", 34, 39, 96, 0

section .bss
alignb 8
lx_depth   resq 1
lx_paren   resq 1
lx_gn      resq 1
lx_silent  resq 1
lx_gstack  resq 2 * (MAX_BLOCKS + 1)
lx_ind_len resq MAX_BLOCKS + 1
lx_ind_ptr resq MAX_BLOCKS + 1

section .text

%macro EMIT_TOK 0
    mov [rdi + T_KIND], cx
    mov rax, r8
    sub rax, r13
    inc rax
    cmp rax, 65535
    jbe %%col_ok
    mov eax, 65535
%%col_ok:
    mov [rdi + T_COL], ax
    mov [rdi + T_LINE], r14d
    mov rax, r8
    sub rax, rbx
    mov [rdi + T_OFF], eax
    mov [rdi + T_LEN], edx
    add rdi, T_SIZE
    inc r15
%endmacro

FUNC lex
    mov rcx, [g_src_len]
    shl rcx, 1
    add rcx, 256
    shl rcx, 4
    call mem_alloc
    mov [g_tokens], rax
    mov qword [lx_depth], 0
    mov qword [lx_ind_len], 0
    mov qword [lx_paren], 0
    mov qword [lx_gn], 0
    mov qword [lx_silent], 0
    mov rdi, rax
    xor r15d, r15d
    mov rbx, [g_src]
    mov rsi, rbx
    mov r12, rbx
    add r12, [g_src_len]
    mov r13, rbx
    mov r14d, 1
    jmp .line_start

.next:
    cmp rsi, r12
    jae .eof
    movzx eax, byte [rsi]
    cmp al, ' '
    je .skip
    cmp al, 9
    je .skip
    cmp al, 13
    je .skip
    cmp al, 10
    je .newline
    cmp al, '/'
    je .slash
    cmp al, '_'
    je .ident
    mov ecx, eax
    or ecx, 0x20
    cmp ecx, 'a'
    jb .not_alpha
    cmp ecx, 'z'
    jbe .ident
.not_alpha:
    cmp al, '0'
    jb .not_digit
    cmp al, '9'
    jbe .number
.not_digit:
    cmp al, '"'
    je .string
    cmp al, 39
    je .string
    cmp al, 96
    je .string
    mov ecx, TK_DOT
    cmp al, '.'
    je .single
    mov ecx, TK_EQ
    cmp al, '='
    jne .not_eq
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .single
    cmp byte [rdx], '='
    jne .single
    mov ecx, TK_IS
    mov r8, rsi
    mov edx, 2
    EMIT_TOK
    add rsi, 2
    jmp .next
.not_eq:
    mov ecx, TK_MINUS
    cmp al, '-'
    je .single
    mov ecx, TK_PLUS
    cmp al, '+'
    je .single
    mov ecx, TK_STAR
    cmp al, '*'
    je .single
    mov ecx, TK_PERCENT
    cmp al, '%'
    je .single
    mov ecx, TK_LPAREN
    cmp al, '('
    je .lparen
    mov ecx, TK_RPAREN
    cmp al, ')'
    je .rparen
    mov ecx, TK_COMMA
    cmp al, ','
    je .single
    mov ecx, TK_LBRACE
    cmp al, '{'
    je .single
    mov ecx, TK_RBRACE
    cmp al, '}'
    je .single
    mov ecx, TK_COLON
    cmp al, ':'
    je .single
    cmp al, '!'
    je .bang
    mov ecx, TK_LT
    cmp al, '<'
    jne .not_lt
    mov edx, TK_LE
    jmp .maybe_eq
.not_lt:
    cmp al, '>'
    jne .unexpected
    mov ecx, TK_GT
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .single
    cmp byte [rdx], '='
    jne .not_ge
    mov ecx, TK_GE
    jmp .two
.not_ge:
    cmp byte [rdx], '>'
    jne .single
    mov ecx, TK_SHR
    mov r8, rsi
    mov edx, 2
    EMIT_TOK
    add rsi, 2
    jmp .next

.skip:
    inc rsi
    jmp .next

.lparen:
    inc qword [lx_paren]
    jmp .single

.rparen:
    cmp qword [lx_paren], 0
    je .single
    dec qword [lx_paren]
    mov rax, [lx_gn]
    test rax, rax
    jz .single
    shl rax, 4
    lea rdx, [lx_gstack]
    mov rdx, [rdx + rax - 16]
    cmp [lx_paren], rdx
    jae .single
    dec qword [lx_gn]
    jmp .single

.bang:
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .unexpected
    cmp byte [rdx], '='
    jne .unexpected
    mov ecx, TK_ISNOT
    jmp .two

.maybe_eq:
    lea r8, [rsi + 1]
    cmp r8, r12
    jae .single
    cmp byte [r8], '='
    jne .single
    mov ecx, edx

.two:
    mov r8, rsi
    mov edx, 2
    EMIT_TOK
    add rsi, 2
    jmp .next

.single:
    mov r8, rsi
    mov edx, 1
    EMIT_TOK
    inc rsi
    jmp .next

.newline:
    mov ecx, TK_NL
    mov r8, rsi
    cmp r8, r13
    jbe .nl_emit
    cmp byte [r8 - 1], 13
    jne .nl_emit
    dec r8
.nl_emit:
    mov edx, 1
    EMIT_TOK
    xor edx, edx
    mov rax, [lx_gn]
    test rax, rax
    jz .group_top
    shl rax, 4
    lea rcx, [lx_gstack]
    mov rdx, [rcx + rax - 16]
.group_top:
    cmp [lx_paren], rdx
    jbe .group_done
    mov rax, [lx_gn]
    cmp rax, MAX_BLOCKS
    jae .group_done
    shl rax, 4
    lea rcx, [lx_gstack]
    mov rdx, [lx_paren]
    mov [rcx + rax], rdx
    mov rdx, [lx_depth]
    mov [rcx + rax + 8], rdx
    inc qword [lx_gn]
    mov qword [lx_silent], 1
.group_done:
    inc rsi
    inc r14d
    mov r13, rsi
    jmp .line_start

.slash:
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .slash_one
    cmp byte [rdx], '/'
    je .comment
.slash_one:
    mov ecx, TK_SLASH
    mov r8, rsi
    mov edx, 1
    EMIT_TOK
    inc rsi
    jmp .next
.comment:
    cmp rsi, r12
    jae .next
    cmp byte [rsi], 10
    je .next
    inc rsi
    jmp .comment

.ident:
    mov r8, rsi
.ident_loop:
    inc rsi
    cmp rsi, r12
    jae .ident_end
    movzx eax, byte [rsi]
    cmp al, '_'
    je .ident_loop
    cmp al, '0'
    jb .ident_alpha
    cmp al, '9'
    jbe .ident_loop
.ident_alpha:
    or al, 0x20
    cmp al, 'a'
    jb .ident_end
    cmp al, 'z'
    jbe .ident_loop
.ident_end:
    mov rdx, rsi
    sub rdx, r8
    cmp rdx, 64
    ja .name_long
    lea r9, [keywords]
.kw_loop:
    movzx eax, byte [r9]
    test eax, eax
    jz .kw_none
    cmp eax, edx
    jne .kw_next
    xor r10d, r10d
.kw_cmp:
    mov r11b, [r9 + 2 + r10]
    cmp r11b, [r8 + r10]
    jne .kw_next
    inc r10d
    cmp r10d, edx
    jb .kw_cmp
    movzx ecx, byte [r9 + 1]
    EMIT_TOK
    jmp .next
.kw_next:
    lea r9, [r9 + 2 + rax]
    jmp .kw_loop
.kw_none:
    mov ecx, TK_IDENT
    EMIT_TOK
    jmp .next

.number:
    mov r8, rsi
.num_loop:
    inc rsi
    cmp rsi, r12
    jae .num_end
    cmp byte [rsi], '0'
    jb .num_end
    cmp byte [rsi], '9'
    jbe .num_loop
.num_end:
    cmp byte [rsi], '.'
    jne .num_int
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .num_int
    cmp byte [rdx], '0'
    jb .num_int
    cmp byte [rdx], '9'
    ja .num_int
    inc rsi
.num_frac:
    inc rsi
    cmp rsi, r12
    jae .num_float
    cmp byte [rsi], '0'
    jb .num_float
    cmp byte [rsi], '9'
    jbe .num_frac
.num_float:
    mov rdx, rsi
    sub rdx, r8
    mov ecx, TK_FNUM
    EMIT_TOK
    jmp .next
.num_int:
    mov rdx, rsi
    sub rdx, r8
    mov ecx, TK_INT
    EMIT_TOK
    jmp .next

.string:
    mov r8, rsi
    mov r9b, al
    inc rsi
.str_loop:
    cmp rsi, r12
    jae .unterminated
    mov al, [rsi]
    cmp al, 10
    je .unterminated
    cmp al, r9b
    je .str_end
    cmp al, '\'
    je .str_escape
    inc rsi
    jmp .str_loop
.str_escape:
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .unterminated
    mov al, [rdx]
    cmp al, 10
    je .unterminated
    lea r10, [escape_chars]
.esc_find:
    mov r11b, [r10]
    test r11b, r11b
    jz .bad_escape
    cmp r11b, al
    je .esc_ok
    inc r10
    jmp .esc_find
.esc_ok:
    add rsi, 2
    jmp .str_loop
.str_end:
    inc rsi
    mov rdx, rsi
    sub rdx, r8
    mov ecx, TK_STR
    EMIT_TOK
    jmp .next

.eof:
    test r15, r15
    jz .eof_dedent
    cmp word [rdi - T_SIZE + T_KIND], TK_NL
    je .eof_dedent
    mov ecx, TK_NL
    mov r8, rsi
    xor edx, edx
    EMIT_TOK
.eof_dedent:
    cmp qword [lx_depth], 0
    je .eof_tok
    dec qword [lx_depth]
    mov ecx, TK_DEDENT
    mov r8, rsi
    xor edx, edx
    EMIT_TOK
    jmp .eof_dedent
.eof_tok:
    mov ecx, TK_EOF
    mov r8, rsi
    xor edx, edx
    EMIT_TOK
    mov [g_ntok], r15
    ENDF

.line_start:
    mov r8, rsi
.ls_scan:
    cmp r8, r12
    jae .next
    mov al, [r8]
    cmp al, ' '
    je .ls_ws
    cmp al, 9
    je .ls_ws
    cmp al, 10
    je .next
    cmp al, 13
    je .next
    cmp al, '/'
    jne .ls_line
    lea rdx, [r8 + 1]
    cmp rdx, r12
    jae .ls_line
    cmp byte [rdx], '/'
    je .next
    jmp .ls_line
.ls_ws:
    inc r8
    jmp .ls_scan
.ls_line:
    mov r9, r8
    sub r9, r13
    cmp qword [lx_silent], 0
    je .ls_close
    mov qword [lx_silent], 0
    mov rax, [lx_depth]
    cmp rax, MAX_BLOCKS
    jae .ls_too_deep
    inc rax
    mov [lx_depth], rax
    lea r11, [lx_ind_len]
    mov [r11 + rax * 8], r9
    lea r11, [lx_ind_ptr]
    mov [r11 + rax * 8], r13
    jmp .next
.ls_close:
    mov rax, [lx_gn]
    test rax, rax
    jz .ls_normal
    cmp byte [r8], ')'
    jne .ls_normal
    shl rax, 4
    lea r11, [lx_gstack]
    mov rdx, [r11 + rax - 16]
    cmp [lx_paren], rdx
    jne .ls_normal
    mov r10, [r11 + rax - 8]
    cmp [lx_depth], r10
    jbe .ls_normal
    inc r10
.ls_close_pop:
    cmp [lx_depth], r10
    jbe .ls_close_silent
    dec qword [lx_depth]
    mov ecx, TK_DEDENT
    xor edx, edx
    EMIT_TOK
    jmp .ls_close_pop
.ls_close_silent:
    dec qword [lx_depth]
    jmp .next
.ls_normal:
    mov rax, [lx_depth]
    lea r11, [lx_ind_len]
    mov r10, [r11 + rax * 8]
    cmp r9, r10
    je .ls_same
    ja .ls_push
.ls_pop:
    mov rdx, [lx_gn]
    test rdx, rdx
    jz .ls_pop_ok
    shl rdx, 4
    lea r11, [lx_gstack]
    mov rdx, [r11 + rdx - 8]
    inc rdx
    cmp [lx_depth], rdx
    ja .ls_pop_ok
    lea rcx, [s_unindent]
    jmp .indent_error
.ls_pop_ok:
    dec qword [lx_depth]
    mov ecx, TK_DEDENT
    xor edx, edx
    EMIT_TOK
    mov rax, [lx_depth]
    lea r11, [lx_ind_len]
    mov r10, [r11 + rax * 8]
    cmp r9, r10
    jb .ls_pop
    je .ls_same
    lea rcx, [s_unindent]
    jmp .indent_error
.ls_push:
    cmp rax, MAX_BLOCKS
    jae .ls_too_deep
    mov rcx, r10
    call .prefix_same
    jne .ls_mixed
    inc qword [lx_depth]
    mov rax, [lx_depth]
    lea r11, [lx_ind_len]
    mov [r11 + rax * 8], r9
    lea r11, [lx_ind_ptr]
    mov [r11 + rax * 8], r13
    mov ecx, TK_INDENT
    xor edx, edx
    EMIT_TOK
    jmp .next
.ls_same:
    test r9, r9
    jz .next
    mov rcx, r9
    call .prefix_same
    jne .ls_mixed
    jmp .next
.ls_mixed:
    lea rcx, [s_mixed]
    jmp .indent_error
.ls_too_deep:
    lea rcx, [s_too_nest]
.indent_error:
    mov r12, r13
    push rcx
    call msg_reset
    pop rcx
    call msg_addz
    jmp .lex_error

.prefix_same:
    mov rax, [lx_depth]
    lea r11, [lx_ind_ptr]
    mov r11, [r11 + rax * 8]
    xor edx, edx
.ps_loop:
    cmp rdx, rcx
    jae .ps_equal
    mov al, [r13 + rdx]
    cmp al, [r11 + rdx]
    jne .ps_done
    inc rdx
    jmp .ps_loop
.ps_equal:
    cmp eax, eax
.ps_done:
    ret

.unexpected:
    mov r12, rsi
    call msg_reset
    movzx eax, byte [r12]
    cmp al, 0x21
    jb .unexp_byte
    cmp al, 0x7E
    ja .unexp_byte
    lea rcx, [s_unexp_ch]
    call msg_addz
    mov cl, [r12]
    call msg_addc
    lea rcx, [s_quote]
    call msg_addz
    jmp .lex_error
.unexp_byte:
    lea rcx, [s_unexp_by]
    call msg_addz
    movzx eax, byte [r12]
    shr eax, 4
    lea rcx, [hex_digits]
    mov cl, [rcx + rax]
    call msg_addc
    movzx eax, byte [r12]
    and eax, 15
    lea rcx, [hex_digits]
    mov cl, [rcx + rax]
    call msg_addc
    jmp .lex_error

.unterminated:
    mov r12, r8
    call msg_reset
    lea rcx, [s_unterm]
    call msg_addz
    jmp .lex_error

.bad_escape:
    mov r12, rsi
    call msg_reset
    lea rcx, [s_unk_esc]
    call msg_addz
    mov cl, [r12 + 1]
    call msg_addc
    lea rcx, [s_quote]
    call msg_addz
    jmp .lex_error

.name_long:
    mov r12, r8
    call msg_reset
    lea rcx, [s_name_long]
    call msg_addz

.lex_error:
    mov r8, r12
    sub r8, r13
    inc r8
    mov edx, r14d
    lea rcx, [s_lexical]
    call diag_error_at
