%include "defs.inc"
%include "state.inc"

extern rt_size, rt_consts

%define BASE_VA    0x400000
%define DATA_VA    0x40000000
%define HDR_SIZE   128

section .bss
global el_R_va, el_T_off, el_T_va, el_D_va, el_entry, g_image, g_image_size
alignb 4
el_R_va      resd 1
el_T_off     resd 1
el_T_va      resd 1
el_D_va      resd 1
el_entry     resd 1
el_data_vsz  resd 1
g_image      resd 1
g_image_size resd 1

section .text

FUNC elf_layout
    mov dword [el_R_va], BASE_VA + HDR_SIZE
    mov eax, [g_pool_len]
    add eax, HDR_SIZE + RC_SIZE + 15
    and eax, -16
    mov [el_T_off], eax
    lea ecx, [eax + BASE_VA]
    mov [el_T_va], ecx
    mov dword [el_D_va], DATA_VA
    mov ecx, [g_vars_size]
    add ecx, RT_VARS
    mov [el_data_vsz], ecx
    mov ecx, [g_nstmt]
    shl ecx, 8
    mov edx, [g_npieces]
    shl edx, 5
    add ecx, edx
    mov edx, [g_nparts]
    imul edx, edx, 48
    add ecx, edx
    add ecx, [rt_size]
    add ecx, 4096
    add ecx, eax
    call mem_alloc
    mov [g_image], eax
    lea edi, [eax + HDR_SIZE]
    mov esi, rt_consts
    mov ecx, RC_SIZE
    rep movsb
    mov esi, [g_pool]
    mov ecx, [g_pool_len]
    rep movsb
    ENDF

FUNC elf_finish
    mov ebx, [g_image]
    mov eax, [el_T_off]
    add eax, ecx
    mov [g_image_size], eax
    mov edx, eax

    mov dword [ebx], 0x464C457F
    mov byte [ebx + 4], 1
    mov byte [ebx + 5], 1
    mov byte [ebx + 6], 1
    mov word [ebx + 16], 2
    mov word [ebx + 18], 3
    mov dword [ebx + 20], 1
    mov eax, [el_T_va]
    add eax, [el_entry]
    mov [ebx + 24], eax
    mov dword [ebx + 28], 52
    mov word [ebx + 40], 52
    mov word [ebx + 42], 32
    mov word [ebx + 44], 2

    lea esi, [ebx + 52]
    mov dword [esi], 1
    mov dword [esi + 4], 0
    mov dword [esi + 8], BASE_VA
    mov dword [esi + 12], BASE_VA
    mov [esi + 16], edx
    mov [esi + 20], edx
    mov dword [esi + 24], 5
    mov dword [esi + 28], 0x1000

    add esi, 32
    mov dword [esi], 1
    mov dword [esi + 4], 0
    mov eax, [el_D_va]
    mov [esi + 8], eax
    mov [esi + 12], eax
    mov dword [esi + 16], 0
    mov eax, [el_data_vsz]
    mov [esi + 20], eax
    mov dword [esi + 24], 6
    mov dword [esi + 28], 0x1000
    ENDF
