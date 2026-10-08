#include "defs.h"

#define MAX_ARGS 64

    .bss
    .p2align 3
argc:     .zero 8
argv:     .zero (8 * MAX_ARGS)
out_path: .zero 8

    RODATA
#if defined(TARGET_WINDOWS)
#define NL "\r\n"
s_version: .asciz "EnderScript 0.1.1 (Windows ARM64)\r\n"
s_help:    .ascii "EnderScript 0.1.1 (Windows ARM64)\r\n\r\n"
           .ascii "Usage:\r\n"
           .ascii "  ender check <file.es>            Check syntax, semantics, and types\r\n"
           .ascii "  ender check --syntax <file.es>   Check syntax only\r\n"
           .ascii "  ender build <file.es>            Build <file>.exe\r\n"
           .ascii "  ender build <file.es> -o <out>   Build the selected output path\r\n"
           .ascii "  ender run <file.es>              Build into .ender\\ and run\r\n"
           .ascii "  ender --version\r\n"
           .asciz "  ender --help\r\n"
s_crlf:      .asciz "\r\n"
s_ender_pre: .asciz ".ender\\"
s_exe:       .asciz ".exe"
#else
s_version: .asciz "EnderScript 0.1.1 (Linux ARM64)\n"
s_help:    .ascii "EnderScript 0.1.1 (Linux ARM64)\n\n"
           .ascii "Usage:\n"
           .ascii "  ender check <file.es>            Check syntax, semantics, and types\n"
           .ascii "  ender check --syntax <file.es>   Check syntax only\n"
           .ascii "  ender build <file.es>            Build <file>\n"
           .ascii "  ender build <file.es> -o <out>   Build the selected output path\n"
           .ascii "  ender run <file.es>              Build into .ender/ and run\n"
           .ascii "  ender --version\n"
           .asciz "  ender --help\n"
s_crlf:      .asciz "\n"
s_ender_pre: .asciz ".ender/"
s_exe:       .asciz ""
#endif
a_version:   .asciz "--version"
a_help:      .asciz "--help"
a_check:     .asciz "check"
a_syntax:    .asciz "--syntax"
a_build:     .asciz "build"
a_run:       .asciz "run"
a_o:         .asciz "-o"
s_unknown:   .asciz "unknown command '"
s_unexpect:  .asciz "unexpected argument '"
s_missing:   .asciz "missing input file"
s_missing_o: .asciz "missing output path after -o"
s_ext:       .asciz "input file must use the .es extension"
s_big:       .asciz "source file is larger than 16 MB"
s_cant_read: .asciz "cannot read '"
s_cant_wr:   .asciz "cannot write '"
s_cant_run:  .asciz "cannot run '"
s_ok:        .asciz "ok "
s_built:     .asciz "built "
s_ender_dir: .asciz ".ender"
s_empty:     .asciz ""

    .text

LEAF streq
1:  ldrb w9, [x0], #1
    ldrb w10, [x1], #1
    cmp w9, w10
    b.ne 2f
    cbnz w9, 1b
    mov x0, #1
    ret
2:  mov x0, #0
    ret

.macro ARGEQ idx, str
    LA x9, argv
    ldr x0, [x9, #(\idx * 8)]
    LA x1, \str
    bl streq
.endm

#if defined(TARGET_WINDOWS)
FUNC parse_args
    CALLAPI GetCommandLineA
    mov x19, x0
    bl zlen
    add x0, x0, #64
    bl mem_alloc
    mov x20, x0
    mov x21, #0
    LA x22, argv
    ldrb w9, [x19]
    cmp w9, #'"'
    b.ne .Lpa_skip0
    add x19, x19, #1
.Lpa_skip0q:
    ldrb w9, [x19]
    cbz w9, .Lpa_done
    add x19, x19, #1
    cmp w9, #'"'
    b.ne .Lpa_skip0q
    b .Lpa_args
.Lpa_skip0:
    ldrb w9, [x19]
    cbz w9, .Lpa_done
    cmp w9, #' '
    b.eq .Lpa_args
    cmp w9, #9
    b.eq .Lpa_args
    add x19, x19, #1
    b .Lpa_skip0
.Lpa_args:
    ldrb w9, [x19]
    cbz w9, .Lpa_done
    cmp w9, #' '
    b.eq .Lpa_ws
    cmp w9, #9
    b.eq .Lpa_ws
    cmp x21, #MAX_ARGS
    b.hs .Lpa_done
    str x20, [x22, x21, lsl #3]
    add x21, x21, #1
    mov w23, #0
.Lpa_char:
    ldrb w9, [x19]
    cbz w9, .Lpa_end
    cmp w9, #'"'
    b.ne .Lpa_nq
    eor w23, w23, #1
    add x19, x19, #1
    b .Lpa_char
.Lpa_nq:
    cbnz w23, .Lpa_copy
    cmp w9, #' '
    b.eq .Lpa_end
    cmp w9, #9
    b.eq .Lpa_end
.Lpa_copy:
    strb w9, [x20], #1
    add x19, x19, #1
    b .Lpa_char
.Lpa_end:
    strb wzr, [x20], #1
    b .Lpa_args
.Lpa_ws:
    add x19, x19, #1
    b .Lpa_args
.Lpa_done:
    STX x21, argc
    ENDF
#endif

FUNC frontend
    mov x19, x0
    mov w20, w1
    bl zlen
    cmp x0, #3
    b.lo .Lfe_bad_ext
    add x9, x19, x0
    ldrb w10, [x9, #-3]
    cmp w10, #'.'
    b.ne .Lfe_bad_ext
    ldrb w10, [x9, #-2]
    cmp w10, #'e'
    b.ne .Lfe_bad_ext
    ldrb w10, [x9, #-1]
    cmp w10, #'s'
    b.ne .Lfe_bad_ext
    mov x0, x19
    bl read_file
    cbnz x0, .Lfe_loaded
    cbnz x1, .Lfe_too_big
    LA x0, s_cant_read
    mov x1, x19
    bl fatal_path
.Lfe_too_big:
    LA x0, s_big
    bl fatal
.Lfe_bad_ext:
    LA x0, s_ext
    bl fatal
.Lfe_loaded:
    STX x0, g_src
    STX x1, g_src_len
    STX x19, g_file
    bl lex
    bl parse
    cbnz w20, 1f
    bl sema
1:  ENDF

FUNC join_stem
    mov x19, x0
    mov x20, x1
    mov x21, x2
    mov x22, x3
    mov x0, x21
    bl zlen
    mov x23, x0
    mov x0, x22
    bl zlen
    mov x24, x0
    add x0, x23, x24
    add x0, x0, x20
    add x0, x0, #16
    bl mem_alloc
    mov x25, x0
    mov x9, x0
    mov x10, #0
1:  cmp x10, x23
    b.hs 2f
    ldrb w11, [x21, x10]
    strb w11, [x9], #1
    add x10, x10, #1
    b 1b
2:  mov x10, #0
3:  cmp x10, x20
    b.hs 4f
    ldrb w11, [x19, x10]
    strb w11, [x9], #1
    add x10, x10, #1
    b 3b
4:  mov x10, #0
5:  ldrb w11, [x22, x10]
    strb w11, [x9], #1
    add x10, x10, #1
    cbnz w11, 5b
    mov x0, x25
    ENDF

FUNC emit_and_write
    mov x19, x0
    bl codegen
    mov x0, x19
    LDX x1, g_image
    LDX x2, g_image_size
    bl write_file
    cbnz x0, 1f
    LA x0, s_cant_wr
    mov x1, x19
    bl fatal_path
1:  ENDF

extra_arg:
    LA x9, argv
    ldr x1, [x9, x0, lsl #3]
    LA x0, s_unexpect
    bl fatal_path

missing:
    LA x0, s_missing
    bl fatal

    .globl start
    .p2align 2
start:
#if !defined(TARGET_WINDOWS)
    ldr x9, [sp]
    add x10, sp, #16
    add x11, sp, x9, lsl #3
    add x11, x11, #16
    STX x11, g_envp
    sub x9, x9, #1
    cmp x9, #MAX_ARGS
    mov x12, #MAX_ARGS
    csel x9, x9, x12, ls
    STX x9, argc
    LA x11, argv
    mov x12, #0
1:  cmp x12, x9
    b.hs 2f
    ldr x13, [x10, x12, lsl #3]
    str x13, [x11, x12, lsl #3]
    add x12, x12, #1
    b 1b
2:
#endif
    bl sys_init
#if defined(TARGET_WINDOWS)
    bl parse_args
#endif
    LDX x19, argc
    cbz x19, .Lst_help_fail
    ARGEQ 0, a_version
    cbnz x0, .Lst_version
    ARGEQ 0, a_help
    cbnz x0, .Lst_help
    ARGEQ 0, a_check
    cbnz x0, .Lst_check
    ARGEQ 0, a_build
    cbnz x0, .Lst_build
    ARGEQ 0, a_run
    cbnz x0, .Lst_run
    LA x0, s_unknown
    LA x9, argv
    ldr x1, [x9]
    bl fatal_path

.Lst_version:
    mov x0, #1
    cmp x19, #1
    b.ne extra_arg
    LA x0, s_version
    bl write_outz
    mov w0, #0
    bl sys_exit

.Lst_help:
    mov x0, #1
    cmp x19, #1
    b.ne extra_arg
    LA x0, s_help
    bl write_outz
    mov w0, #0
    bl sys_exit

.Lst_help_fail:
    LA x0, s_help
    bl write_errz
    mov w0, #1
    bl sys_exit

.Lst_check:
    mov w20, #0
    mov x21, #1
    cmp x19, #2
    b.lo missing
    ARGEQ 1, a_syntax
    cbz x0, 3f
    mov w20, #1
    mov x21, #2
3:  cmp x19, x21
    b.ls missing
    add x0, x21, #1
    cmp x19, x0
    b.hi extra_arg
    LA x9, argv
    ldr x22, [x9, x21, lsl #3]
    mov x0, x22
    mov w1, w20
    bl frontend
    LA x0, s_ok
    bl write_outz
    mov x0, x22
    bl write_outz
    LA x0, s_crlf
    bl write_outz
    mov w0, #0
    bl sys_exit

.Lst_build:
    cmp x19, #2
    b.lo missing
    LA x9, argv
    ldr x22, [x9, #8]
    b.eq .Lst_build_default
    ARGEQ 2, a_o
    cbnz x0, 4f
    mov x0, #2
    b extra_arg
4:  cmp x19, #4
    b.lo .Lst_missing_o
    mov x0, #4
    b.hi extra_arg
    LA x9, argv
    ldr x23, [x9, #24]
    b .Lst_build_go
.Lst_missing_o:
    LA x0, s_missing_o
    bl fatal
.Lst_build_default:
    mov x0, x22
    bl zlen
    sub x1, x0, #3
    mov x0, x22
    LA x2, s_empty
    LA x3, s_exe
    bl join_stem
    mov x23, x0
.Lst_build_go:
    mov x0, x22
    mov w1, #0
    bl frontend
    mov x0, x23
    bl emit_and_write
    LA x0, s_built
    bl write_outz
    mov x0, x23
    bl write_outz
    LA x0, s_crlf
    bl write_outz
    mov w0, #0
    bl sys_exit

.Lst_run:
    cmp x19, #2
    b.lo missing
    mov x0, #2
    b.hi extra_arg
    LA x9, argv
    ldr x22, [x9, #8]
    mov x0, x22
    mov w1, #0
    bl frontend
    mov x0, x22
    bl zlen
    add x24, x22, x0
    sub x24, x24, #3
    mov x25, x24
5:  cmp x25, x22
    b.ls 6f
    ldrb w9, [x25, #-1]
    cmp w9, #'/'
    b.eq 6f
#if defined(TARGET_WINDOWS)
    cmp w9, #'\\'
    b.eq 6f
    cmp w9, #':'
    b.eq 6f
#endif
    sub x25, x25, #1
    b 5b
6:  mov x0, x25
    sub x1, x24, x25
    LA x2, s_ender_pre
    LA x3, s_exe
    bl join_stem
    mov x23, x0
    LA x0, s_ender_dir
    bl make_dir
    mov x0, x23
    bl emit_and_write
    mov x0, x23
    bl run_process
    cmn x0, #1
    b.ne 7f
    LA x0, s_cant_run
    mov x1, x23
    bl fatal_path
7:  bl sys_exit
