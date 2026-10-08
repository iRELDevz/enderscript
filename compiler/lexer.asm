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
    db 0

global escape_chars
escape_chars db "nt0r\", 34, 39, 96, 0

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
    add rcx, 2
    shl rcx, 4
    call mem_alloc
    mov [g_tokens], rax
    mov rdi, rax
    xor r15d, r15d
    mov rbx, [g_src]
    mov rsi, rbx
    mov r12, rbx
    add r12, [g_src_len]
    mov r13, rbx
    mov r14d, 1

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
    je .single
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
    je .single
    mov ecx, TK_RPAREN
    cmp al, ')'
    je .single
    mov ecx, TK_LBRACE
    cmp al, '{'
    je .single
    mov ecx, TK_RBRACE
    cmp al, '}'
    je .single
    cmp al, '>'
    jne .unexpected
    lea rdx, [rsi + 1]
    cmp rdx, r12
    jae .unexpected
    cmp byte [rdx], '>'
    jne .unexpected
    mov ecx, TK_SHR
    mov r8, rsi
    mov edx, 2
    EMIT_TOK
    add rsi, 2
    jmp .next

.skip:
    inc rsi
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
    inc rsi
    inc r14d
    mov r13, rsi
    jmp .next

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
    mov ecx, TK_EOF
    mov r8, rsi
    xor edx, edx
    EMIT_TOK
    mov [g_ntok], r15
    ENDF

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
