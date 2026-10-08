#include "defs.h"

    .bss
    .p2align 3
    .globl g_src, g_src_len, g_file, g_hout, g_herr, g_envp
    .globl g_tokens, g_ntok, g_stmts, g_nstmt, g_parts, g_nparts
    .globl g_roots, g_nroots, g_pieces, g_npieces, g_vars, g_nvars, g_htab, g_hmask
    .globl g_pool, g_pool_len, g_vars_size
g_src:       .zero 8
g_src_len:   .zero 8
g_file:      .zero 8
g_hout:      .zero 8
g_herr:      .zero 8
g_envp:      .zero 8
g_tokens:    .zero 8
g_ntok:      .zero 8
g_stmts:     .zero 8
g_nstmt:     .zero 8
g_parts:     .zero 8
g_nparts:    .zero 8
g_roots:     .zero 8
g_nroots:    .zero 8
g_pieces:    .zero 8
g_npieces:   .zero 8
g_vars:      .zero 8
g_nvars:     .zero 8
g_htab:      .zero 8
g_hmask:     .zero 8
g_pool:      .zero 8
g_pool_len:  .zero 8
g_vars_size: .zero 8

    RODATA
s_oom: .asciz "out of memory"

    .text
FUNC mem_alloc
    add x0, x0, #4095
    and x1, x0, #0xFFFFFFFFFFFFF000
#if defined(TARGET_WINDOWS)
    mov x0, #0
    mov w2, #0x3000
    mov w3, #4
    CALLAPI VirtualAlloc
    cbz x0, .Lmem_oom
#else
    mov x0, #0
    mov x2, #3
    mov x3, #0x22
    mov x4, #-1
    mov x5, #0
    mov x8, #222
    svc #0
    tbnz x0, #63, .Lmem_oom
#endif
    ENDF
.Lmem_oom:
    LA x0, s_oom
    bl fatal
