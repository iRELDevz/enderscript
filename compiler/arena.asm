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

WINAPI VirtualAlloc

section .bss
global g_src, g_src_len, g_file, g_hout, g_herr
global g_tokens, g_ntok, g_stmts, g_nstmt, g_parts, g_nparts
global g_roots, g_nroots, g_pieces, g_npieces, g_vars, g_nvars, g_htab, g_hmask
global g_pool, g_pool_len, g_vars_size
alignb 8
g_src       resq 1
g_src_len   resq 1
g_file      resq 1
g_hout      resq 1
g_herr      resq 1
g_tokens    resq 1
g_ntok      resq 1
g_stmts     resq 1
g_nstmt     resq 1
g_parts     resq 1
g_nparts    resq 1
g_roots     resq 1
g_nroots    resq 1
g_pieces    resq 1
g_npieces   resq 1
g_vars      resq 1
g_nvars     resq 1
g_htab      resq 1
g_hmask     resq 1
g_pool      resq 1
g_pool_len  resq 1
g_vars_size resq 1

section .rdata
s_oom db "out of memory", 0

section .text

FUNC mem_alloc
    mov rdx, rcx
    add rdx, 4095
    and rdx, -4096
    xor ecx, ecx
    mov r8d, 0x3000
    mov r9d, 4
    CALLAPI VirtualAlloc
    test rax, rax
    jz .oom
    ENDF
.oom:
    lea rcx, [s_oom]
    call fatal
