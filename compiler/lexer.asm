%include "defs.inc"
%include "state.inc"
%include "xlat.inc"

section .rdata
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
    db 5, TK_BREAK, "break"
    db 8, TK_CONTINUE, "continue"
    db 5, TK_INPUT, "input"
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
    mov [edi + T_KIND], cx
    mov eax, dword [vr8]
    sub eax, dword [vr13]
    inc eax
    cmp eax, 65535
    jbe %%col_ok
    mov eax, 65535
%%col_ok:
    mov [edi + T_COL], ax
    push ebx
    mov ebx, dword [vr14]
    mov [edi + T_LINE], ebx
    pop ebx
    mov eax, dword [vr8]
    sub eax, ebx
    mov [edi + T_OFF], eax
    mov [edi + T_LEN], edx
    add edi, T_SIZE
    inc dword [vr15]
%endmacro

XFUNC lex
    mov ecx, [g_src_len]
    shl ecx, 1
    add ecx, 256
    shl ecx, 4
    call mem_alloc
    mov [g_tokens], eax
    mov dword [lx_depth], 0
    mov dword [lx_ind_len], 0
    mov dword [lx_paren], 0
    mov dword [lx_gn], 0
    mov dword [lx_silent], 0
    mov edi, eax
    push ebx
    mov ebx, dword [vr15]
    xor dword [vr15], ebx
    pop ebx
    mov ebx, [g_src]
    mov esi, ebx
    mov dword [vr12], ebx
    push ebx
    mov ebx, [g_src_len]
    add dword [vr12], ebx
    pop ebx
    mov dword [vr13], ebx
    mov dword [vr14], 1
    jmp .line_start

.next:
    cmp esi, dword [vr12]
    jae .eof
    movzx eax, byte [esi]
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
    lea edx, [esi + 1]
    cmp edx, dword [vr12]
    jae .single
    cmp byte [edx], '='
    jne .single
    mov ecx, TK_IS
    mov dword [vr8], esi
    mov edx, 2
    EMIT_TOK
    add esi, 2
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
    lea edx, [esi + 1]
    cmp edx, dword [vr12]
    jae .single
    cmp byte [edx], '='
    jne .not_ge
    mov ecx, TK_GE
    jmp .two
.not_ge:
    cmp byte [edx], '>'
    jne .single
    mov ecx, TK_SHR
    mov dword [vr8], esi
    mov edx, 2
    EMIT_TOK
    add esi, 2
    jmp .next

.skip:
    inc esi
    jmp .next

.lparen:
    inc dword [lx_paren]
    jmp .single

.rparen:
    cmp dword [lx_paren], 0
    je .single
    dec dword [lx_paren]
    mov eax, [lx_gn]
    test eax, eax
    jz .single
    shl eax, 4
    lea edx, [lx_gstack]
    mov edx, [edx + eax - 16]
    cmp [lx_paren], edx
    jae .single
    dec dword [lx_gn]
    jmp .single

.bang:
    lea edx, [esi + 1]
    cmp edx, dword [vr12]
    jae .unexpected
    cmp byte [edx], '='
    jne .unexpected
    mov ecx, TK_ISNOT
    jmp .two

.maybe_eq:
    push ebx
    lea ebx, [esi + 1]
    mov dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr12]
    cmp dword [vr8], ebx
    pop ebx
    jae .single
    push ebx
    mov ebx, [vr8]
    cmp byte [ebx], '='
    pop ebx
    jne .single
    mov ecx, edx

.two:
    mov dword [vr8], esi
    mov edx, 2
    EMIT_TOK
    add esi, 2
    jmp .next

.single:
    mov dword [vr8], esi
    mov edx, 1
    EMIT_TOK
    inc esi
    jmp .next

.newline:
    mov ecx, TK_NL
    mov dword [vr8], esi
    push ebx
    mov ebx, dword [vr13]
    cmp dword [vr8], ebx
    pop ebx
    jbe .nl_emit
    push ebx
    mov ebx, [vr8]
    cmp byte [ebx - 1], 13
    pop ebx
    jne .nl_emit
    dec dword [vr8]
.nl_emit:
    mov edx, 1
    EMIT_TOK
    xor edx, edx
    mov eax, [lx_gn]
    test eax, eax
    jz .group_top
    shl eax, 4
    lea ecx, [lx_gstack]
    mov edx, [ecx + eax - 16]
.group_top:
    cmp [lx_paren], edx
    jbe .group_done
    mov eax, [lx_gn]
    cmp eax, MAX_BLOCKS
    jae .group_done
    shl eax, 4
    lea ecx, [lx_gstack]
    mov edx, [lx_paren]
    mov [ecx + eax], edx
    mov edx, [lx_depth]
    mov [ecx + eax + 8], edx
    inc dword [lx_gn]
    mov dword [lx_silent], 1
.group_done:
    inc esi
    inc dword [vr14]
    mov dword [vr13], esi
    jmp .line_start

.slash:
    lea edx, [esi + 1]
    cmp edx, dword [vr12]
    jae .slash_one
    cmp byte [edx], '/'
    je .comment
.slash_one:
    mov ecx, TK_SLASH
    mov dword [vr8], esi
    mov edx, 1
    EMIT_TOK
    inc esi
    jmp .next
.comment:
    cmp esi, dword [vr12]
    jae .next
    cmp byte [esi], 10
    je .next
    inc esi
    jmp .comment

.ident:
    mov dword [vr8], esi
.ident_loop:
    inc esi
    cmp esi, dword [vr12]
    jae .ident_end
    movzx eax, byte [esi]
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
    mov edx, esi
    sub edx, dword [vr8]
    cmp edx, 64
    ja .name_long
    push ebx
    lea ebx, [keywords]
    mov dword [vr9], ebx
    pop ebx
.kw_loop:
    push ebx
    mov ebx, [vr9]
    movzx eax, byte [ebx]
    pop ebx
    test eax, eax
    jz .kw_none
    cmp eax, edx
    jne .kw_next
    push ebx
    mov ebx, dword [vr10]
    xor dword [vr10], ebx
    pop ebx
.kw_cmp:
    push ebx
    push esi
    push ecx
    mov ebx, [vr9]
    mov esi, [vr10]
    mov cl, [ebx + 2 + esi]
    mov byte [vr11], cl
    pop ecx
    pop esi
    pop ebx
    push ebx
    push esi
    push ecx
    mov ebx, [vr8]
    mov esi, [vr10]
    mov cl, [ebx + esi]
    cmp byte [vr11], cl
    pop ecx
    pop esi
    pop ebx
    jne .kw_next
    inc dword [vr10]
    cmp dword [vr10], edx
    jb .kw_cmp
    push ebx
    mov ebx, [vr9]
    movzx ecx, byte [ebx + 1]
    pop ebx
    EMIT_TOK
    jmp .next
.kw_next:
    push ebx
    push esi
    mov ebx, [vr9]
    lea esi, [ebx + 2 + eax]
    mov dword [vr9], esi
    pop esi
    pop ebx
    jmp .kw_loop
.kw_none:
    mov ecx, TK_IDENT
    EMIT_TOK
    jmp .next

.number:
    mov dword [vr8], esi
.num_loop:
    inc esi
    cmp esi, dword [vr12]
    jae .num_end
    cmp byte [esi], '0'
    jb .num_end
    cmp byte [esi], '9'
    jbe .num_loop
.num_end:
    cmp byte [esi], '.'
    jne .num_int
    lea edx, [esi + 1]
    cmp edx, dword [vr12]
    jae .num_int
    cmp byte [edx], '0'
    jb .num_int
    cmp byte [edx], '9'
    ja .num_int
    inc esi
.num_frac:
    inc esi
    cmp esi, dword [vr12]
    jae .num_float
    cmp byte [esi], '0'
    jb .num_float
    cmp byte [esi], '9'
    jbe .num_frac
.num_float:
    mov edx, esi
    sub edx, dword [vr8]
    mov ecx, TK_FNUM
    EMIT_TOK
    jmp .next
.num_int:
    mov edx, esi
    sub edx, dword [vr8]
    mov ecx, TK_INT
    EMIT_TOK
    jmp .next

.string:
    mov dword [vr8], esi
    mov byte [vr9], al
    inc esi
.str_loop:
    cmp esi, dword [vr12]
    jae .unterminated
    mov al, [esi]
    cmp al, 10
    je .unterminated
    cmp al, byte [vr9]
    je .str_end
    cmp al, '\'
    je .str_escape
    inc esi
    jmp .str_loop
.str_escape:
    lea edx, [esi + 1]
    cmp edx, dword [vr12]
    jae .unterminated
    mov al, [edx]
    cmp al, 10
    je .unterminated
    push ebx
    lea ebx, [escape_chars]
    mov dword [vr10], ebx
    pop ebx
.esc_find:
    push ebx
    push ecx
    mov ebx, [vr10]
    mov cl, [ebx]
    mov byte [vr11], cl
    pop ecx
    pop ebx
    push ebx
    mov bl, byte [vr11]
    test byte [vr11], bl
    pop ebx
    jz .bad_escape
    cmp byte [vr11], al
    je .esc_ok
    inc dword [vr10]
    jmp .esc_find
.esc_ok:
    add esi, 2
    jmp .str_loop
.str_end:
    inc esi
    mov edx, esi
    sub edx, dword [vr8]
    mov ecx, TK_STR
    EMIT_TOK
    jmp .next

.eof:
    push ebx
    mov ebx, dword [vr15]
    test dword [vr15], ebx
    pop ebx
    jz .eof_dedent
    cmp word [edi - T_SIZE + T_KIND], TK_NL
    je .eof_dedent
    mov ecx, TK_NL
    mov dword [vr8], esi
    xor edx, edx
    EMIT_TOK
.eof_dedent:
    cmp dword [lx_depth], 0
    je .eof_tok
    dec dword [lx_depth]
    mov ecx, TK_DEDENT
    mov dword [vr8], esi
    xor edx, edx
    EMIT_TOK
    jmp .eof_dedent
.eof_tok:
    mov ecx, TK_EOF
    mov dword [vr8], esi
    xor edx, edx
    EMIT_TOK
    push ebx
    mov ebx, dword [vr15]
    mov [g_ntok], ebx
    pop ebx
    XENDF

.line_start:
    mov dword [vr8], esi
.ls_scan:
    push ebx
    mov ebx, dword [vr12]
    cmp dword [vr8], ebx
    pop ebx
    jae .next
    push ebx
    mov ebx, [vr8]
    mov al, [ebx]
    pop ebx
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
    push ebx
    mov ebx, [vr8]
    lea edx, [ebx + 1]
    pop ebx
    cmp edx, dword [vr12]
    jae .ls_line
    cmp byte [edx], '/'
    je .next
    jmp .ls_line
.ls_ws:
    inc dword [vr8]
    jmp .ls_scan
.ls_line:
    push ebx
    mov ebx, dword [vr8]
    mov dword [vr9], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr13]
    sub dword [vr9], ebx
    pop ebx
    cmp dword [lx_silent], 0
    je .ls_close
    mov dword [lx_silent], 0
    mov eax, [lx_depth]
    cmp eax, MAX_BLOCKS
    jae .ls_too_deep
    inc eax
    mov [lx_depth], eax
    push ebx
    lea ebx, [lx_ind_len]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, dword [vr9]
    mov [ebx + eax * 8], esi
    pop esi
    pop ebx
    push ebx
    lea ebx, [lx_ind_ptr]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, dword [vr13]
    mov [ebx + eax * 8], esi
    pop esi
    pop ebx
    jmp .next
.ls_close:
    mov eax, [lx_gn]
    test eax, eax
    jz .ls_normal
    push ebx
    mov ebx, [vr8]
    cmp byte [ebx], ')'
    pop ebx
    jne .ls_normal
    shl eax, 4
    push ebx
    lea ebx, [lx_gstack]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    mov ebx, [vr11]
    mov edx, [ebx + eax - 16]
    pop ebx
    cmp [lx_paren], edx
    jne .ls_normal
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, [ebx + eax - 8]
    mov dword [vr10], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, dword [vr10]
    cmp [lx_depth], ebx
    pop ebx
    jbe .ls_normal
    inc dword [vr10]
.ls_close_pop:
    push ebx
    mov ebx, dword [vr10]
    cmp [lx_depth], ebx
    pop ebx
    jbe .ls_close_silent
    dec dword [lx_depth]
    mov ecx, TK_DEDENT
    xor edx, edx
    EMIT_TOK
    jmp .ls_close_pop
.ls_close_silent:
    dec dword [lx_depth]
    jmp .next
.ls_normal:
    mov eax, [lx_depth]
    push ebx
    lea ebx, [lx_ind_len]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, [ebx + eax * 8]
    mov dword [vr10], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, dword [vr10]
    cmp dword [vr9], ebx
    pop ebx
    je .ls_same
    ja .ls_push
.ls_pop:
    mov edx, [lx_gn]
    test edx, edx
    jz .ls_pop_ok
    shl edx, 4
    push ebx
    lea ebx, [lx_gstack]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    mov ebx, [vr11]
    mov edx, [ebx + edx - 8]
    pop ebx
    inc edx
    cmp [lx_depth], edx
    ja .ls_pop_ok
    lea ecx, [s_unindent]
    jmp .indent_error
.ls_pop_ok:
    dec dword [lx_depth]
    mov ecx, TK_DEDENT
    xor edx, edx
    EMIT_TOK
    mov eax, [lx_depth]
    push ebx
    lea ebx, [lx_ind_len]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, [ebx + eax * 8]
    mov dword [vr10], esi
    pop esi
    pop ebx
    push ebx
    mov ebx, dword [vr10]
    cmp dword [vr9], ebx
    pop ebx
    jb .ls_pop
    je .ls_same
    lea ecx, [s_unindent]
    jmp .indent_error
.ls_push:
    cmp eax, MAX_BLOCKS
    jae .ls_too_deep
    mov ecx, dword [vr10]
    call .prefix_same
    jne .ls_mixed
    inc dword [lx_depth]
    mov eax, [lx_depth]
    push ebx
    lea ebx, [lx_ind_len]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, dword [vr9]
    mov [ebx + eax * 8], esi
    pop esi
    pop ebx
    push ebx
    lea ebx, [lx_ind_ptr]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, dword [vr13]
    mov [ebx + eax * 8], esi
    pop esi
    pop ebx
    mov ecx, TK_INDENT
    xor edx, edx
    EMIT_TOK
    jmp .next
.ls_same:
    push ebx
    mov ebx, dword [vr9]
    test dword [vr9], ebx
    pop ebx
    jz .next
    mov ecx, dword [vr9]
    call .prefix_same
    jne .ls_mixed
    jmp .next
.ls_mixed:
    lea ecx, [s_mixed]
    jmp .indent_error
.ls_too_deep:
    lea ecx, [s_too_nest]
.indent_error:
    push ebx
    mov ebx, dword [vr13]
    mov dword [vr12], ebx
    pop ebx
    push ecx
    call msg_reset
    pop ecx
    call msg_addz
    jmp .lex_error

.prefix_same:
    mov eax, [lx_depth]
    push ebx
    lea ebx, [lx_ind_ptr]
    mov dword [vr11], ebx
    pop ebx
    push ebx
    push esi
    mov ebx, [vr11]
    mov esi, [ebx + eax * 8]
    mov dword [vr11], esi
    pop esi
    pop ebx
    xor edx, edx
.ps_loop:
    cmp edx, ecx
    jae .ps_equal
    push ebx
    mov ebx, [vr13]
    mov al, [ebx + edx]
    pop ebx
    push ebx
    mov ebx, [vr11]
    cmp al, [ebx + edx]
    pop ebx
    jne .ps_done
    inc edx
    jmp .ps_loop
.ps_equal:
    cmp eax, eax
.ps_done:
    ret

.unexpected:
    mov dword [vr12], esi
    call msg_reset
    push ebx
    mov ebx, [vr12]
    movzx eax, byte [ebx]
    pop ebx
    cmp al, 0x21
    jb .unexp_byte
    cmp al, 0x7E
    ja .unexp_byte
    lea ecx, [s_unexp_ch]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov cl, [ebx]
    pop ebx
    call msg_addc
    lea ecx, [s_quote]
    call msg_addz
    jmp .lex_error
.unexp_byte:
    lea ecx, [s_unexp_by]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    movzx eax, byte [ebx]
    pop ebx
    shr eax, 4
    lea ecx, [hex_digits]
    mov cl, [ecx + eax]
    call msg_addc
    push ebx
    mov ebx, [vr12]
    movzx eax, byte [ebx]
    pop ebx
    and eax, 15
    lea ecx, [hex_digits]
    mov cl, [ecx + eax]
    call msg_addc
    jmp .lex_error

.unterminated:
    push ebx
    mov ebx, dword [vr8]
    mov dword [vr12], ebx
    pop ebx
    call msg_reset
    lea ecx, [s_unterm]
    call msg_addz
    jmp .lex_error

.bad_escape:
    mov dword [vr12], esi
    call msg_reset
    lea ecx, [s_unk_esc]
    call msg_addz
    push ebx
    mov ebx, [vr12]
    mov cl, [ebx + 1]
    pop ebx
    call msg_addc
    lea ecx, [s_quote]
    call msg_addz
    jmp .lex_error

.name_long:
    push ebx
    mov ebx, dword [vr8]
    mov dword [vr12], ebx
    pop ebx
    call msg_reset
    lea ecx, [s_name_long]
    call msg_addz

.lex_error:
    push ebx
    mov ebx, dword [vr12]
    mov dword [vr8], ebx
    pop ebx
    push ebx
    mov ebx, dword [vr13]
    sub dword [vr8], ebx
    pop ebx
    inc dword [vr8]
    mov edx, dword [vr14]
    lea ecx, [s_lexical]
    mov eax, dword [vr8]
    call diag_error_at
