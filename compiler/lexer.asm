%include "defs.inc"
%include "state.inc"

section .bss
alignb 4
lx_base  resd 1
lx_end   resd 1
lx_line  resd 1
lx_start resd 1
lx_err   resd 1

section .rdata
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

escape_chars db "nt0r\", 34, 39, 96, 0

section .text

%macro EMIT_TOK 0
    mov [edi + T_KIND], cx
    mov [edi + T_LEN], edx
    mov ecx, eax
    sub ecx, ebx
    inc ecx
    cmp ecx, 65535
    jbe %%col_ok
    mov ecx, 65535
%%col_ok:
    mov [edi + T_COL], cx
    sub eax, [lx_base]
    mov [edi + T_OFF], eax
    mov eax, [lx_line]
    mov [edi + T_LINE], eax
    add edi, T_SIZE
%endmacro

FUNC lex
    mov ecx, [g_src_len]
    add ecx, 2
    shl ecx, 4
    call mem_alloc
    mov [g_tokens], eax
    mov edi, eax
    mov esi, [g_src]
    mov [lx_base], esi
    mov eax, esi
    add eax, [g_src_len]
    mov [lx_end], eax
    mov ebx, esi
    mov dword [lx_line], 1

.next:
    cmp esi, [lx_end]
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
    je .single
    mov ecx, TK_MINUS
    cmp al, '-'
    je .single
    mov ecx, TK_LBRACE
    cmp al, '{'
    je .single
    mov ecx, TK_RBRACE
    cmp al, '}'
    je .single
    cmp al, '>'
    jne .unexpected
    lea edx, [esi + 1]
    cmp edx, [lx_end]
    jae .unexpected
    cmp byte [edx], '>'
    jne .unexpected
    mov ecx, TK_SHR
    mov eax, esi
    mov edx, 2
    EMIT_TOK
    add esi, 2
    jmp .next

.skip:
    inc esi
    jmp .next

.single:
    mov eax, esi
    mov edx, 1
    EMIT_TOK
    inc esi
    jmp .next

.newline:
    mov ecx, TK_NL
    mov eax, esi
    mov edx, 1
    EMIT_TOK
    inc esi
    inc dword [lx_line]
    mov ebx, esi
    jmp .next

.slash:
    lea edx, [esi + 1]
    cmp edx, [lx_end]
    jae .unexpected
    cmp byte [edx], '/'
    jne .unexpected
.comment:
    cmp esi, [lx_end]
    jae .next
    cmp byte [esi], 10
    je .next
    inc esi
    jmp .comment

.ident:
    mov [lx_start], esi
.ident_loop:
    inc esi
    cmp esi, [lx_end]
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
    sub edx, [lx_start]
    cmp edx, 64
    ja .name_long
    push esi
    push edi
    mov ecx, keywords
.kw_loop:
    movzx eax, byte [ecx]
    test eax, eax
    jz .kw_none
    cmp eax, edx
    jne .kw_next
    lea esi, [ecx + 2]
    mov edi, [lx_start]
    push ecx
    mov ecx, edx
    repe cmpsb
    pop ecx
    je .kw_hit
.kw_next:
    lea ecx, [ecx + 2 + eax]
    jmp .kw_loop
.kw_hit:
    movzx ecx, byte [ecx + 1]
    jmp .kw_emit
.kw_none:
    mov ecx, TK_IDENT
.kw_emit:
    pop edi
    pop esi
    mov eax, [lx_start]
    EMIT_TOK
    jmp .next

.number:
    mov [lx_start], esi
.num_loop:
    inc esi
    cmp esi, [lx_end]
    jae .num_end
    cmp byte [esi], '0'
    jb .num_end
    cmp byte [esi], '9'
    jbe .num_loop
.num_end:
    mov edx, esi
    mov eax, [lx_start]
    sub edx, eax
    mov ecx, TK_INT
    EMIT_TOK
    jmp .next

.string:
    mov [lx_start], esi
    mov ah, al
    inc esi
.str_loop:
    cmp esi, [lx_end]
    jae .unterminated
    mov al, [esi]
    cmp al, 10
    je .unterminated
    cmp al, ah
    je .str_end
    cmp al, '\'
    je .str_escape
    inc esi
    jmp .str_loop
.str_escape:
    lea edx, [esi + 1]
    cmp edx, [lx_end]
    jae .unterminated
    mov al, [edx]
    cmp al, 10
    je .unterminated
    mov ecx, escape_chars
.esc_find:
    mov dl, [ecx]
    test dl, dl
    jz .bad_escape
    cmp dl, al
    je .esc_ok
    inc ecx
    jmp .esc_find
.esc_ok:
    add esi, 2
    jmp .str_loop
.str_end:
    inc esi
    mov eax, [lx_start]
    mov edx, esi
    sub edx, eax
    mov ecx, TK_STR
    EMIT_TOK
    jmp .next

.eof:
    mov ecx, TK_EOF
    mov eax, esi
    xor edx, edx
    EMIT_TOK
    mov eax, edi
    sub eax, [g_tokens]
    shr eax, 4
    mov [g_ntok], eax
    ENDF

.unexpected:
    mov [lx_err], esi
    call msg_reset
    mov eax, [lx_err]
    movzx eax, byte [eax]
    cmp al, 0x21
    jb .unexp_byte
    cmp al, 0x7E
    ja .unexp_byte
    mov ecx, s_unexp_ch
    call msg_addz
    mov eax, [lx_err]
    mov cl, [eax]
    call msg_addc
    mov ecx, s_quote
    call msg_addz
    jmp .lex_error
.unexp_byte:
    mov ecx, s_unexp_by
    call msg_addz
    mov eax, [lx_err]
    movzx eax, byte [eax]
    shr eax, 4
    mov cl, [hex_digits + eax]
    call msg_addc
    mov eax, [lx_err]
    movzx eax, byte [eax]
    and eax, 15
    mov cl, [hex_digits + eax]
    call msg_addc
    jmp .lex_error

.unterminated:
    mov eax, [lx_start]
    mov [lx_err], eax
    call msg_reset
    mov ecx, s_unterm
    call msg_addz
    jmp .lex_error

.bad_escape:
    mov [lx_err], esi
    call msg_reset
    mov ecx, s_unk_esc
    call msg_addz
    mov eax, [lx_err]
    mov cl, [eax + 1]
    call msg_addc
    mov ecx, s_quote
    call msg_addz
    jmp .lex_error

.name_long:
    mov eax, [lx_start]
    mov [lx_err], eax
    call msg_reset
    mov ecx, s_name_long
    call msg_addz

.lex_error:
    mov eax, [lx_err]
    sub eax, ebx
    inc eax
    mov edx, [lx_line]
    mov ecx, s_lexical
    call diag_error_at
