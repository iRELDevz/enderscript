%include "defs.inc"
%define OWN_msg_reset
%define OWN_msg_add
%define OWN_msg_addz
%define OWN_msg_addu
%define OWN_msg_addc
%define OWN_msg_tok
%define OWN_u32_to_dec
%define OWN_diag_error_tok
%define OWN_diag_error_at
%define OWN_diag_warn_tok
%define OWN_fatal
%define OWN_fatal_path
%include "state.inc"

%define MSG_CAP  1024
%define LINE_CAP 2048

section .bss
alignb 4
msg_len   resd 1
line_len  resd 1
saved_a   resd 1
saved_b   resd 1
num_tmp   resb 16
msg_buf   resb MSG_CAP
line_buf  resb LINE_CAP

section .rdata
s_error_sp  db " error: ", 0
s_warning   db ": warning: ", 0
s_error_pre db "error: ", 0
s_crlf      db 13, 10, 0
s_quote     db "'", 0

section .text

global msg_reset
msg_reset:
    mov dword [msg_len], 0
    ret

buf_add:
    push ebx
    push esi
    mov esi, [eax]
.loop:
    test edx, edx
    jz .end
    cmp esi, [eax + 4]
    jae .end
    mov bl, [ecx]
    push eax
    mov eax, [eax + 8]
    mov [eax + esi], bl
    pop eax
    inc esi
    inc ecx
    dec edx
    jmp .loop
.end:
    mov [eax], esi
    pop esi
    pop ebx
    ret

section .data
msg_desc  dd 0, MSG_CAP, msg_buf
line_desc dd 0, LINE_CAP, line_buf

section .text

global msg_add
msg_add:
    mov eax, [msg_len]
    mov [msg_desc], eax
    mov eax, msg_desc
    call buf_add
    mov eax, [msg_desc]
    mov [msg_len], eax
    ret

line_add:
    mov eax, [line_len]
    mov [line_desc], eax
    mov eax, line_desc
    call buf_add
    mov eax, [line_desc]
    mov [line_len], eax
    ret

global msg_addz
msg_addz:
    call zlen
    mov edx, eax
    jmp msg_add

line_addz:
    call zlen
    mov edx, eax
    jmp line_add

global msg_addc
msg_addc:
    mov [num_tmp], cl
    mov ecx, num_tmp
    mov edx, 1
    jmp msg_add

line_addc:
    mov [num_tmp], cl
    mov ecx, num_tmp
    mov edx, 1
    jmp line_add

global u32_to_dec
u32_to_dec:
    push ebx
    mov eax, ecx
    mov ecx, num_tmp + 16
    mov ebx, 10
.loop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec ecx
    mov [ecx], dl
    test eax, eax
    jnz .loop
    mov eax, ecx
    mov edx, num_tmp + 16
    sub edx, ecx
    pop ebx
    ret

global msg_addu
msg_addu:
    call u32_to_dec
    mov ecx, eax
    jmp msg_add

line_addu:
    call u32_to_dec
    mov ecx, eax
    jmp line_add

global msg_tok
msg_tok:
    mov eax, ecx
    shl eax, 4
    add eax, [g_tokens]
    mov ecx, [eax + T_OFF]
    mov edx, [eax + T_LEN]
    add ecx, [g_src]
    jmp msg_add

tok_pos:
    mov eax, ecx
    shl eax, 4
    add eax, [g_tokens]
    mov edx, [eax + T_LINE]
    movzx eax, word [eax + T_COL]
    ret

line_head:
    mov [saved_a], edx
    mov [saved_b], eax
    mov dword [line_len], 0
    mov ecx, [g_file]
    call line_addz
    mov cl, ':'
    call line_addc
    mov ecx, [saved_a]
    call line_addu
    mov cl, ':'
    call line_addc
    mov ecx, [saved_b]
    call line_addu
    ret

line_tail_flush:
    mov ecx, msg_buf
    mov edx, [msg_len]
    call line_add
    mov ecx, s_crlf
    call line_addz
    mov ecx, line_buf
    mov edx, [line_len]
    jmp write_err

global diag_error_tok
diag_error_tok:
    push ecx
    mov ecx, edx
    call tok_pos
    pop ecx

global diag_error_at
diag_error_at:
    push ecx
    call line_head
    mov cl, ':'
    call line_addc
    mov cl, ' '
    call line_addc
    pop ecx
    call line_addz
    mov ecx, s_error_sp
    call line_addz
    call line_tail_flush
    mov ecx, 1
    call sys_exit

FUNC diag_warn_tok
    call tok_pos
    call line_head
    mov ecx, s_warning
    call line_addz
    call line_tail_flush
    ENDF

global fatal
fatal:
    push ecx
    call msg_reset
    pop ecx
    call msg_addz
    jmp fatal_msg

global fatal_path
fatal_path:
    push edx
    push ecx
    call msg_reset
    pop ecx
    call msg_addz
    pop ecx
    call msg_addz
    mov ecx, s_quote
    call msg_addz

fatal_msg:
    mov dword [line_len], 0
    mov ecx, s_error_pre
    call line_addz
    call line_tail_flush
    mov ecx, 1
    call sys_exit
