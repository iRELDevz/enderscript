%include "defs.inc"
%include "state.inc"

extern rt_size, rt_consts

%define FILE_ALIGN  0x200
%define SECT_ALIGN  0x1000
%define IDATA_SIZE  128
%define IMAGE_BASE  0x400000

section .bss
global pe_R, pe_D, pe_I, pe_T, pe_text_file, pe_entry, g_image, g_image_size
alignb 4
pe_R          resd 1
pe_D          resd 1
pe_I          resd 1
pe_T          resd 1
pe_rdata_vsz  resd 1
pe_rdata_raw  resd 1
pe_data_vsz   resd 1
pe_idata_file resd 1
pe_text_file  resd 1
pe_entry      resd 1
g_image       resd 1
g_image_size  resd 1

section .rdata
idata_tpl:
    times 72 db 0
    dw 0
    db "GetStdHandle", 0
    db 0
    dw 0
    db "WriteFile", 0
    dw 0
    db "ExitProcess", 0
    db "kernel32.dll", 0
    db 0

section .text

%macro ALIGN_UP 2
    add %1, %2 - 1
    and %1, -(%2)
%endmacro

FUNC pe_layout
    mov eax, [g_pool_len]
    add eax, RC_SIZE
    mov [pe_rdata_vsz], eax
    mov ecx, eax
    ALIGN_UP ecx, FILE_ALIGN
    mov [pe_rdata_raw], ecx
    mov dword [pe_R], SECT_ALIGN
    add eax, SECT_ALIGN
    ALIGN_UP eax, SECT_ALIGN
    mov [pe_D], eax
    mov ecx, [g_vars_size]
    add ecx, RT_VARS
    mov [pe_data_vsz], ecx
    add eax, ecx
    ALIGN_UP eax, SECT_ALIGN
    mov [pe_I], eax
    add eax, IDATA_SIZE
    ALIGN_UP eax, SECT_ALIGN
    mov [pe_T], eax
    mov eax, [pe_rdata_raw]
    add eax, FILE_ALIGN
    mov [pe_idata_file], eax
    add eax, FILE_ALIGN
    mov [pe_text_file], eax
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
    lea edi, [eax + FILE_ALIGN]
    mov esi, rt_consts
    mov ecx, RC_SIZE
    rep movsb
    mov esi, [g_pool]
    mov ecx, [g_pool_len]
    rep movsb
    ENDF

FUNC pe_finish, 8
    mov [L(0)], ecx
    mov ebx, [g_image]
    ALIGN_UP ecx, FILE_ALIGN
    mov [L(4)], ecx
    mov eax, [pe_text_file]
    add eax, ecx
    mov [g_image_size], eax

    mov word [ebx], 0x5A4D
    mov dword [ebx + 0x3C], 0x40
    mov dword [ebx + 0x40], 0x00004550
    mov word [ebx + 0x44], 0x014C
    mov word [ebx + 0x46], 4
    mov word [ebx + 0x54], 0xE0
    mov word [ebx + 0x56], 0x0103

    lea esi, [ebx + 0x58]
    mov word [esi], 0x10B
    mov byte [esi + 2], 1
    mov eax, [L(4)]
    mov [esi + 4], eax
    mov eax, [pe_rdata_raw]
    add eax, FILE_ALIGN
    mov [esi + 8], eax
    mov eax, [pe_data_vsz]
    ALIGN_UP eax, FILE_ALIGN
    mov [esi + 12], eax
    mov eax, [pe_T]
    add eax, [pe_entry]
    mov [esi + 16], eax
    mov eax, [pe_T]
    mov [esi + 20], eax
    mov eax, [pe_R]
    mov [esi + 24], eax
    mov dword [esi + 28], IMAGE_BASE
    mov dword [esi + 32], SECT_ALIGN
    mov dword [esi + 36], FILE_ALIGN
    mov word [esi + 40], 6
    mov word [esi + 48], 6
    mov eax, [pe_T]
    add eax, [L(0)]
    ALIGN_UP eax, SECT_ALIGN
    mov [esi + 56], eax
    mov dword [esi + 60], FILE_ALIGN
    mov word [esi + 68], 3
    mov word [esi + 70], 0x8100
    mov dword [esi + 72], 0x100000
    mov dword [esi + 76], 0x1000
    mov dword [esi + 80], 0x100000
    mov dword [esi + 84], 0x1000
    mov dword [esi + 92], 16
    mov eax, [pe_I]
    mov [esi + 104], eax
    mov dword [esi + 108], 40
    add eax, 56
    mov [esi + 192], eax
    mov dword [esi + 196], 16

    lea esi, [ebx + 0x138]
    mov dword [esi], 0x6164722E
    mov dword [esi + 4], 0x6174
    mov eax, [pe_rdata_vsz]
    mov [esi + 8], eax
    mov eax, [pe_R]
    mov [esi + 12], eax
    mov eax, [pe_rdata_raw]
    mov [esi + 16], eax
    mov dword [esi + 20], FILE_ALIGN
    mov dword [esi + 36], 0x40000040

    add esi, 40
    mov dword [esi], 0x7461642E
    mov dword [esi + 4], 0x61
    mov eax, [pe_data_vsz]
    mov [esi + 8], eax
    mov eax, [pe_D]
    mov [esi + 12], eax
    mov dword [esi + 36], 0xC0000080

    add esi, 40
    mov dword [esi], 0x6164692E
    mov dword [esi + 4], 0x6174
    mov dword [esi + 8], IDATA_SIZE
    mov eax, [pe_I]
    mov [esi + 12], eax
    mov dword [esi + 16], FILE_ALIGN
    mov eax, [pe_idata_file]
    mov [esi + 20], eax
    mov dword [esi + 36], 0xC0000040

    add esi, 40
    mov dword [esi], 0x7865742E
    mov dword [esi + 4], 0x74
    mov eax, [L(0)]
    mov [esi + 8], eax
    mov eax, [pe_T]
    mov [esi + 12], eax
    mov eax, [L(4)]
    mov [esi + 16], eax
    mov eax, [pe_text_file]
    mov [esi + 20], eax
    mov dword [esi + 36], 0x60000020

    mov edi, ebx
    add edi, [pe_idata_file]
    mov edx, edi
    mov esi, idata_tpl
    mov ecx, IDATA_SIZE
    rep movsb
    mov eax, [pe_I]
    lea ecx, [eax + 40]
    mov [edx], ecx
    lea ecx, [eax + 114]
    mov [edx + 12], ecx
    lea ecx, [eax + 56]
    mov [edx + 16], ecx
    lea ecx, [eax + 72]
    mov [edx + 40], ecx
    mov [edx + 56], ecx
    lea ecx, [eax + 88]
    mov [edx + 44], ecx
    mov [edx + 60], ecx
    lea ecx, [eax + 100]
    mov [edx + 48], ecx
    mov [edx + 64], ecx
    ENDF
