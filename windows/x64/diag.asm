%include "defs.inc"
%define OWN_msg_reset
%define OWN_msg_add
%define OWN_msg_addz
%define OWN_msg_addu
%define OWN_msg_addc
%define OWN_msg_tok
%define OWN_diag_error_tok
%define OWN_diag_error_at
%define OWN_diag_warn_tok
%define OWN_fatal
%define OWN_fatal_path
%include "state.inc"

%define MSG_CAP  1024
%define LINE_CAP 2048

section .bss
alignb 8
msg_len   resq 1
line_len  resq 1
num_tmp   resb 32
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
    mov qword [msg_len], 0
    ret

global msg_add
msg_add:
    mov rax, [msg_len]
    lea r8, [msg_buf]
.loop:
    test rdx, rdx
    jz .end
    cmp rax, MSG_CAP
    jae .end
    mov r9b, [rcx]
    mov [r8 + rax], r9b
    inc rax
    inc rcx
    dec rdx
    jmp .loop
.end:
    mov [msg_len], rax
    ret

global msg_addz
msg_addz:
    mov rdx, rcx
.len:
    cmp byte [rdx], 0
    je .go
    inc rdx
    jmp .len
.go:
    sub rdx, rcx
    jmp msg_add

global msg_addc
msg_addc:
    mov rax, [msg_len]
    cmp rax, MSG_CAP
    jae .end
    lea rdx, [msg_buf]
    mov [rdx + rax], cl
    inc rax
    mov [msg_len], rax
.end:
    ret

global u64_to_dec
u64_to_dec:
    mov rax, rcx
    lea r8, [num_tmp + 32]
    mov r9, r8
    mov r10d, 10
.loop:
    xor edx, edx
    div r10
    add dl, '0'
    dec r9
    mov [r9], dl
    test rax, rax
    jnz .loop
    mov rax, r9
    mov rdx, r8
    sub rdx, r9
    ret

global msg_addu
msg_addu:
    call u64_to_dec
    mov rcx, rax
    jmp msg_add

global msg_tok
msg_tok:
    mov eax, ecx
    shl rax, 4
    add rax, [g_tokens]
    mov ecx, [rax + T_OFF]
    mov edx, [rax + T_LEN]
    add rcx, [g_src]
    jmp msg_add

line_add:
    mov rax, [line_len]
    lea r8, [line_buf]
.loop:
    test rdx, rdx
    jz .end
    cmp rax, LINE_CAP
    jae .end
    mov r9b, [rcx]
    mov [r8 + rax], r9b
    inc rax
    inc rcx
    dec rdx
    jmp .loop
.end:
    mov [line_len], rax
    ret

line_addz:
    mov rdx, rcx
.len:
    cmp byte [rdx], 0
    je .go
    inc rdx
    jmp .len
.go:
    sub rdx, rcx
    jmp line_add

line_addu:
    call u64_to_dec
    mov rcx, rax
    jmp line_add

line_addc:
    mov [num_tmp], cl
    lea rcx, [num_tmp]
    mov edx, 1
    jmp line_add

line_head:
    push rbx
    push rsi
    mov rbx, rdx
    mov rsi, r8
    mov qword [line_len], 0
    mov rcx, [g_file]
    call line_addz
    mov cl, ':'
    call line_addc
    mov rcx, rbx
    call line_addu
    mov cl, ':'
    call line_addc
    mov rcx, rsi
    call line_addu
    pop rsi
    pop rbx
    ret

line_tail_flush:
    lea rcx, [msg_buf]
    mov rdx, [msg_len]
    call line_add
    lea rcx, [s_crlf]
    call line_addz
    lea rcx, [line_buf]
    mov rdx, [line_len]
    jmp write_err

tok_pos:
    mov eax, ecx
    shl rax, 4
    add rax, [g_tokens]
    mov edx, [rax + T_LINE]
    movzx r8d, word [rax + T_COL]
    ret

global diag_error_tok
diag_error_tok:
    mov r9, rcx
    mov ecx, edx
    call tok_pos
    mov rcx, r9

global diag_error_at
diag_error_at:
    and rsp, -16
    sub rsp, 48
    mov [rsp + 32], rcx
    call line_head
    mov cl, ':'
    call line_addc
    mov cl, ' '
    call line_addc
    mov rcx, [rsp + 32]
    call line_addz
    lea rcx, [s_error_sp]
    call line_addz
    call line_tail_flush
    mov ecx, 1
    call sys_exit

FUNC diag_warn_tok
    call tok_pos
    call line_head
    lea rcx, [s_warning]
    call line_addz
    call line_tail_flush
    ENDF

global fatal
fatal:
    and rsp, -16
    sub rsp, 48
    mov [rsp + 32], rcx
    call msg_reset
    mov rcx, [rsp + 32]
    call msg_addz
    jmp fatal_msg

global fatal_path
fatal_path:
    and rsp, -16
    sub rsp, 48
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    call msg_reset
    mov rcx, [rsp + 32]
    call msg_addz
    mov rcx, [rsp + 40]
    call msg_addz
    lea rcx, [s_quote]
    call msg_addz

fatal_msg:
    mov qword [line_len], 0
    lea rcx, [s_error_pre]
    call line_addz
    call line_tail_flush
    mov ecx, 1
    call sys_exit
