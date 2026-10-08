%include "defs.inc"
%define OWN_g_src
%define OWN_g_src_len
%define OWN_g_file
%define OWN_g_hout
%define OWN_g_herr
%define OWN_g_tokens
%define OWN_g_ntok
%define OWN_g_stmts
%define OWN_g_nstmt
%define OWN_g_parts
%define OWN_g_nparts
%define OWN_g_roots
%define OWN_g_nroots
%define OWN_g_pieces
%define OWN_g_npieces
%define OWN_g_vars
%define OWN_g_nvars
%define OWN_g_htab
%define OWN_g_hmask
%define OWN_g_pool
%define OWN_g_pool_len
%define OWN_g_vars_size
%define OWN_mem_alloc
%include "state.inc"

section .bss
global g_src
global g_src_len
global g_file
global g_hout
global g_herr
global g_tokens
global g_ntok
global g_stmts
global g_nstmt
global g_parts
global g_nparts
global g_roots
global g_nroots
global g_pieces
global g_npieces
global g_vars
global g_nvars
global g_htab
global g_hmask
global g_pool
global g_pool_len
global g_vars_size
alignb 4
g_src        resd 1
g_src_len    resd 1
g_file       resd 1
g_hout       resd 1
g_herr       resd 1
g_tokens     resd 1
g_ntok       resd 1
g_stmts      resd 1
g_nstmt      resd 1
g_parts      resd 1
g_nparts     resd 1
g_roots      resd 1
g_nroots     resd 1
g_pieces     resd 1
g_npieces    resd 1
g_vars       resd 1
g_nvars      resd 1
g_htab       resd 1
g_hmask      resd 1
g_pool       resd 1
g_pool_len   resd 1
g_vars_size  resd 1

section .rodata
s_oom db "out of memory", 0

section .text

FUNC mem_alloc
    push ebp
    add ecx, 4095
    and ecx, -4096
    xor ebx, ebx
    mov edx, 3
    mov esi, 0x22
    mov edi, -1
    xor ebp, ebp
    mov eax, SYS_MMAP2
    int 0x80
    pop ebp
    cmp eax, -4096
    ja .oom
    ENDF
.oom:
    mov ecx, s_oom
    call fatal
