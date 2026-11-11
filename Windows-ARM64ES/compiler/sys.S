#include "defs.h"

    .bss
    .p2align 3
argv_buf: .zero 16

    .text

LEAF zlen
    mov x9, x0
1:  ldrb w10, [x9]
    cbz w10, 2f
    add x9, x9, #1
    b 1b
2:  sub x0, x9, x0
    ret

#if defined(TARGET_WINDOWS)

FUNC sys_init
    mov w0, #-11
    CALLAPI GetStdHandle
    STX x0, g_hout
    mov w0, #-12
    CALLAPI GetStdHandle
    STX x0, g_herr
    ENDF

FUNC write_handle, 16
    cbz x2, 1f
    add x3, sp, #0
    mov x4, #0
    CALLAPI WriteFile
1:  ENDF

LEAF write_out
    mov x2, x1
    mov x1, x0
    LDX x0, g_hout
    b write_handle

LEAF write_err
    mov x2, x1
    mov x1, x0
    LDX x0, g_herr
    b write_handle

LEAF sys_exit
    CALLAPI ExitProcess

FUNC read_file, 32
    mov x19, x0
    str xzr, [sp, #0]
    mov w1, #0x80000000
    mov w2, #1
    mov x3, #0
    mov w4, #3
    mov w5, #0x80
    mov x6, #0
    CALLAPI CreateFileA
    cmn x0, #1
    b.eq .Lrf_fail
    mov x20, x0
    mov x1, sp
    CALLAPI GetFileSizeEx
    cbz w0, .Lrf_fail_close
    ldr x21, [sp, #0]
    MOV32 x9, MAX_SOURCE
    cmp x21, x9
    b.hi .Lrf_too_big
    add x0, x21, #16
    bl mem_alloc
    mov x22, x0
    cbz x21, .Lrf_ok
    mov x0, x20
    mov x1, x22
    mov x2, x21
    add x3, sp, #8
    str xzr, [sp, #8]
    mov x4, #0
    CALLAPI ReadFile
    cbz w0, .Lrf_fail_close
    ldr w9, [sp, #8]
    cmp x9, x21
    b.ne .Lrf_fail_close
.Lrf_ok:
    mov x0, x20
    CALLAPI CloseHandle
    mov x0, x22
    mov x1, x21
    ENDF
.Lrf_too_big:
    mov x0, x20
    CALLAPI CloseHandle
    mov x0, #0
    mov x1, #1
    ENDF
.Lrf_fail_close:
    mov x0, x20
    CALLAPI CloseHandle
.Lrf_fail:
    mov x0, #0
    mov x1, #0
    ENDF

FUNC write_file, 16
    mov x19, x0
    mov x20, x1
    mov x21, x2
    CALLAPI DeleteFileA
    mov x0, x19
    mov w1, #0x40000000
    mov w2, #0
    mov x3, #0
    mov w4, #2
    mov w5, #0x80
    mov x6, #0
    CALLAPI CreateFileA
    cmn x0, #1
    b.eq .Lwf_fail
    mov x22, x0
    mov x1, x20
    mov x2, x21
    add x3, sp, #0
    str xzr, [sp, #0]
    mov x4, #0
    CALLAPI WriteFile
    mov w23, w0
    mov x0, x22
    CALLAPI CloseHandle
    cbz w23, .Lwf_fail
    ldr w9, [sp, #0]
    cmp x9, x21
    b.ne .Lwf_fail
    mov x0, #1
    ENDF
.Lwf_fail:
    mov x0, #0
    ENDF

FUNC make_dir
    mov x1, #0
    CALLAPI CreateDirectoryA
    ENDF

FUNC run_process, 176
    mov x19, x0
    bl zlen
    mov x20, x0
    add x0, x0, #8
    bl mem_alloc
    mov x21, x0
    mov w9, #'"'
    strb w9, [x21]
    mov x10, #0
1:  cmp x10, x20
    b.hs 2f
    ldrb w11, [x19, x10]
    add x12, x10, #1
    strb w11, [x21, x12]
    add x10, x10, #1
    b 1b
2:  add x12, x20, #1
    strb w9, [x21, x12]
    add x12, x12, #1
    strb wzr, [x21, x12]
    add x9, sp, #16
    mov x10, #0
3:  str xzr, [x9, x10]
    add x10, x10, #8
    cmp x10, #144
    b.lo 3b
    mov w9, #104
    str w9, [sp, #16]
    add x9, sp, #16
    str x9, [sp, #0]
    add x9, sp, #128
    str x9, [sp, #8]
    mov x0, #0
    mov x1, x21
    mov x2, #0
    mov x3, #0
    mov w4, #1
    mov w5, #0
    mov x6, #0
    mov x7, #0
    CALLAPI CreateProcessA
    cbz w0, .Lrp_fail
    ldr x0, [sp, #128]
    mov w1, #-1
    CALLAPI WaitForSingleObject
    mov w9, #1
    str w9, [sp, #160]
    ldr x0, [sp, #128]
    add x1, sp, #160
    CALLAPI GetExitCodeProcess
    ldr x0, [sp, #136]
    CALLAPI CloseHandle
    ldr x0, [sp, #128]
    CALLAPI CloseHandle
    ldr w0, [sp, #160]
    ENDF
.Lrp_fail:
    mov x0, #-1
    ENDF

#else

FUNC sys_init
    ENDF

FUNC write_fd
    mov x19, x0
    mov x20, x1
    mov x21, x2
1:  cbz x21, 2f
    mov x0, x19
    mov x1, x20
    mov x2, x21
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 2f
    add x20, x20, x0
    sub x21, x21, x0
    b 1b
2:  ENDF

LEAF write_out
    mov x2, x1
    mov x1, x0
    mov x0, #1
    b write_fd

LEAF write_err
    mov x2, x1
    mov x1, x0
    mov x0, #2
    b write_fd

LEAF sys_exit
    mov x8, #94
    svc #0

FUNC read_file
    mov x1, x0
    mov x0, #-100
    mov x2, #0
    mov x3, #0
    mov x8, #56
    svc #0
    tbnz x0, #63, .Lrf_fail
    mov x19, x0
    mov x1, #0
    mov x2, #2
    mov x8, #62
    svc #0
    tbnz x0, #63, .Lrf_fail_close
    mov x21, x0
    MOV32 x9, MAX_SOURCE
    cmp x21, x9
    b.hi .Lrf_too_big
    mov x0, x19
    mov x1, #0
    mov x2, #0
    mov x8, #62
    svc #0
    add x0, x21, #16
    bl mem_alloc
    mov x22, x0
    mov x23, #0
1:  cmp x23, x21
    b.hs .Lrf_ok
    mov x0, x19
    add x1, x22, x23
    sub x2, x21, x23
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le .Lrf_fail_close
    add x23, x23, x0
    b 1b
.Lrf_ok:
    mov x0, x19
    mov x8, #57
    svc #0
    mov x0, x22
    mov x1, x21
    ENDF
.Lrf_too_big:
    mov x0, x19
    mov x8, #57
    svc #0
    mov x0, #0
    mov x1, #1
    ENDF
.Lrf_fail_close:
    mov x0, x19
    mov x8, #57
    svc #0
.Lrf_fail:
    mov x0, #0
    mov x1, #0
    ENDF

FUNC write_file
    mov x19, x0
    mov x20, x1
    mov x21, x2
    mov x1, x19
    mov x0, #-100
    mov x2, #0
    mov x8, #35
    svc #0
    mov x0, #-100
    mov x1, x19
    mov x2, #577
    mov x3, #0755
    mov x8, #56
    svc #0
    tbnz x0, #63, .Lwf_fail
    mov x22, x0
    mov x23, #1
1:  cbz x21, 2f
    mov x0, x22
    mov x1, x20
    mov x2, x21
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 3f
    add x20, x20, x0
    sub x21, x21, x0
    b 1b
3:  mov x23, #0
2:  mov x0, x22
    mov x8, #57
    svc #0
    mov x0, x23
    ENDF
.Lwf_fail:
    mov x0, #0
    ENDF

FUNC make_dir
    mov x1, x0
    mov x0, #-100
    mov x2, #0755
    mov x8, #34
    svc #0
    ENDF

FUNC run_process, 16
    mov x19, x0
    mov x0, #17
    mov x1, #0
    mov x2, #0
    mov x3, #0
    mov x4, #0
    mov x8, #220
    svc #0
    tbnz x0, #63, .Lrp_fail
    cbnz x0, .Lrp_parent
    LA x1, argv_buf
    str x19, [x1]
    str xzr, [x1, #8]
    mov x0, x19
    LDX x2, g_envp
    mov x8, #221
    svc #0
    mov x0, #127
    mov x8, #94
    svc #0
.Lrp_parent:
    str wzr, [sp, #0]
    mov x1, sp
    mov x2, #0
    mov x3, #0
    mov x8, #260
    svc #0
    tbnz x0, #63, .Lrp_fail
    ldr w0, [sp, #0]
    and w9, w0, #0x7F
    cbnz w9, .Lrp_signal
    lsr w0, w0, #8
    and w0, w0, #0xFF
    ENDF
.Lrp_signal:
    add w0, w9, #128
    ENDF
.Lrp_fail:
    mov x0, #-1
    ENDF

#endif

FUNC write_outz
    mov x19, x0
    bl zlen
    mov x1, x0
    mov x0, x19
    bl write_out
    ENDF

FUNC write_errz
    mov x19, x0
    bl zlen
    mov x1, x0
    mov x0, x19
    bl write_err
    ENDF
