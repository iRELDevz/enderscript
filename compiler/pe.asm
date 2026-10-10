%include "defs.inc"
%include "state.inc"

extern rt_size

%define FILE_ALIGN  0x200
%define SECT_ALIGN  0x1000
%define IDATA_SIZE  192
%define IMAGE_BASE  0x140000000

section .bss
global pe_R, pe_D, pe_I, pe_T, pe_text_file, pe_entry, g_image, g_image_size
alignb 8
pe_R          resq 1
pe_D          resq 1
pe_I          resq 1
pe_T          resq 1
pe_rdata_vsz  resq 1
pe_rdata_raw  resq 1
pe_data_vsz   resq 1
pe_idata_file resq 1
pe_text_file  resq 1
pe_entry      resq 1
g_image       resq 1
g_image_size  resq 1

section .rdata
idata_tpl:
    times 120 db 0
    dw 0
    db "GetStdHandle", 0
    db 0
    dw 0
    db "WriteFile", 0
    dw 0
    db "ExitProcess", 0
    dw 0
    db "ReadFile", 0
    db 0
    db "kernel32.dll", 0
    db 0
    times 4 db 0

section .text

%macro ALIGN_UP 2
    add %1, %2 - 1
    and %1, -(%2)
%endmacro

FUNC pe_layout
    mov rax, [g_pool_len]
    cmp rax, 16
    jae .rsz
    mov eax, 16
.rsz:
    mov [pe_rdata_vsz], rax
    mov rcx, rax
    ALIGN_UP rcx, FILE_ALIGN
    mov [pe_rdata_raw], rcx
    mov qword [pe_R], SECT_ALIGN
    add rax, SECT_ALIGN
    ALIGN_UP rax, SECT_ALIGN
    mov [pe_D], rax
    mov rcx, [g_vars_size]
    add rcx, RT_VARS
    mov [pe_data_vsz], rcx
    add rax, rcx
    ALIGN_UP rax, SECT_ALIGN
    mov [pe_I], rax
    add rax, IDATA_SIZE
    ALIGN_UP rax, SECT_ALIGN
    mov [pe_T], rax
    mov rax, [pe_rdata_raw]
    add rax, FILE_ALIGN
    mov [pe_idata_file], rax
    add rax, FILE_ALIGN
    mov [pe_text_file], rax
    mov rcx, [g_nstmt]
    imul rcx, rcx, 384
    mov rdx, [g_npieces]
    shl rdx, 5
    add rcx, rdx
    mov rdx, [g_nparts]
    imul rdx, rdx, 48
    add rcx, rdx
    mov edx, [rt_size]
    add rcx, rdx
    add rcx, 4096 + 65536
    add rcx, rax
    call mem_alloc
    mov [g_image], rax
    lea rdi, [rax + FILE_ALIGN]
    mov rsi, [g_pool]
    mov rcx, [g_pool_len]
    rep movsb
    ENDF

FUNC pe_finish
    mov r12, rcx
    mov rbx, [g_image]
    mov r13, rcx
    ALIGN_UP r13, FILE_ALIGN
    mov rax, [pe_text_file]
    add rax, r13
    mov [g_image_size], rax

    mov word [rbx], 0x5A4D
    mov dword [rbx + 0x3C], 0x40
    mov dword [rbx + 0x40], 0x00004550
    mov word [rbx + 0x44], 0x8664
    mov word [rbx + 0x46], 4
    mov word [rbx + 0x54], 0xF0
    mov word [rbx + 0x56], 0x0023

    lea rsi, [rbx + 0x58]
    mov word [rsi], 0x20B
    mov byte [rsi + 2], 1
    mov [rsi + 4], r13d
    mov rax, [pe_rdata_raw]
    add rax, FILE_ALIGN
    mov [rsi + 8], eax
    mov rax, [pe_data_vsz]
    ALIGN_UP rax, FILE_ALIGN
    mov [rsi + 12], eax
    mov rax, [pe_T]
    add rax, [pe_entry]
    mov [rsi + 16], eax
    mov rax, [pe_T]
    mov [rsi + 20], eax
    mov rax, IMAGE_BASE
    mov [rsi + 24], rax
    mov dword [rsi + 32], SECT_ALIGN
    mov dword [rsi + 36], FILE_ALIGN
    mov word [rsi + 40], 6
    mov word [rsi + 48], 6
    mov rax, [pe_T]
    add rax, r12
    ALIGN_UP rax, SECT_ALIGN
    mov [rsi + 56], eax
    mov dword [rsi + 60], FILE_ALIGN
    mov word [rsi + 68], 3
    mov word [rsi + 70], 0x8100
    mov qword [rsi + 72], 0x100000
    mov qword [rsi + 80], 0x1000
    mov qword [rsi + 88], 0x100000
    mov qword [rsi + 96], 0x1000
    mov dword [rsi + 108], 16
    mov rax, [pe_I]
    mov [rsi + 120], eax
    mov dword [rsi + 124], 40
    add eax, 80
    mov [rsi + 208], eax
    mov dword [rsi + 212], 40

    lea rsi, [rbx + 0x148]
    mov rax, 0x61746164722E
    mov [rsi], rax
    mov rax, [pe_rdata_vsz]
    mov [rsi + 8], eax
    mov rax, [pe_R]
    mov [rsi + 12], eax
    mov rax, [pe_rdata_raw]
    mov [rsi + 16], eax
    mov dword [rsi + 20], FILE_ALIGN
    mov dword [rsi + 36], 0x40000040

    add rsi, 40
    mov rax, 0x617461642E
    mov [rsi], rax
    mov rax, [pe_data_vsz]
    mov [rsi + 8], eax
    mov rax, [pe_D]
    mov [rsi + 12], eax
    mov dword [rsi + 36], 0xC0000080

    add rsi, 40
    mov rax, 0x61746164692E
    mov [rsi], rax
    mov dword [rsi + 8], IDATA_SIZE
    mov rax, [pe_I]
    mov [rsi + 12], eax
    mov dword [rsi + 16], FILE_ALIGN
    mov rax, [pe_idata_file]
    mov [rsi + 20], eax
    mov dword [rsi + 36], 0xC0000040

    add rsi, 40
    mov rax, 0x747865742E
    mov [rsi], rax
    mov [rsi + 8], r12d
    mov rax, [pe_T]
    mov [rsi + 12], eax
    mov [rsi + 16], r13d
    mov rax, [pe_text_file]
    mov [rsi + 20], eax
    mov dword [rsi + 36], 0x60000020

    mov rdi, rbx
    add rdi, [pe_idata_file]
    mov r14, rdi
    lea rsi, [idata_tpl]
    mov ecx, IDATA_SIZE
    rep movsb
    mov rax, [pe_I]
    lea ecx, [eax + 40]
    mov [r14], ecx
    lea ecx, [eax + 174]
    mov [r14 + 12], ecx
    lea ecx, [eax + 80]
    mov [r14 + 16], ecx
    lea ecx, [eax + 120]
    mov [r14 + 40], rcx
    mov [r14 + 80], rcx
    lea ecx, [eax + 136]
    mov [r14 + 48], rcx
    mov [r14 + 88], rcx
    lea ecx, [eax + 148]
    mov [r14 + 56], rcx
    mov [r14 + 96], rcx
    lea ecx, [eax + 162]
    mov [r14 + 64], rcx
    mov [r14 + 104], rcx
    ENDF
