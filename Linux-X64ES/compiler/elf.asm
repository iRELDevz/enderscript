%include "defs.inc"
%include "state.inc"

extern rt_size

%define BASE_VA    0x400000
%define DATA_VA    0x40000000
%define HDR_SIZE   176

section .bss
global el_R_va, el_T_off, el_T_va, el_D_va, el_entry, g_image, g_image_size
alignb 8
el_R_va      resq 1
el_T_off     resq 1
el_T_va      resq 1
el_D_va      resq 1
el_entry     resq 1
el_data_vsz  resq 1
g_image      resq 1
g_image_size resq 1

section .text

FUNC elf_layout
    mov qword [el_R_va], BASE_VA + HDR_SIZE
    mov rax, [g_pool_len]
    add rax, HDR_SIZE + 15
    and rax, -16
    mov [el_T_off], rax
    lea rcx, [rax + BASE_VA]
    mov [el_T_va], rcx
    mov qword [el_D_va], DATA_VA
    mov rcx, [g_vars_size]
    add rcx, RT_VARS
    mov [el_data_vsz], rcx
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
    lea rdi, [rax + HDR_SIZE]
    mov rsi, [g_pool]
    mov rcx, [g_pool_len]
    rep movsb
    ENDF

FUNC elf_finish
    mov rbx, [g_image]
    mov rax, [el_T_off]
    add rax, rcx
    mov [g_image_size], rax
    mov r12, rax

    mov dword [rbx], 0x464C457F
    mov byte [rbx + 4], 2
    mov byte [rbx + 5], 1
    mov byte [rbx + 6], 1
    mov word [rbx + 16], 2
    mov word [rbx + 18], 0x3E
    mov dword [rbx + 20], 1
    mov rax, [el_T_va]
    add rax, [el_entry]
    mov [rbx + 24], rax
    mov qword [rbx + 32], 64
    mov word [rbx + 52], 64
    mov word [rbx + 54], 56
    mov word [rbx + 56], 2

    lea rsi, [rbx + 64]
    mov dword [rsi], 1
    mov dword [rsi + 4], 5
    mov qword [rsi + 8], 0
    mov qword [rsi + 16], BASE_VA
    mov qword [rsi + 24], BASE_VA
    mov [rsi + 32], r12
    mov [rsi + 40], r12
    mov qword [rsi + 48], 0x1000

    add rsi, 56
    mov dword [rsi], 1
    mov dword [rsi + 4], 6
    mov qword [rsi + 8], 0
    mov rax, [el_D_va]
    mov [rsi + 16], rax
    mov [rsi + 24], rax
    mov qword [rsi + 32], 0
    mov rax, [el_data_vsz]
    mov [rsi + 40], rax
    mov qword [rsi + 48], 0x1000
    ENDF
