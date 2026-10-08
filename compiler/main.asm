%include "defs.inc"
%include "state.inc"

WINAPI GetCommandLineA

extern sys_init, read_file, write_file, make_dir, run_process
extern lex, parse, sema, codegen
extern g_image, g_image_size

%define MAX_ARGS 64

section .bss
alignb 8
argc resq 1
argv resq MAX_ARGS

section .rdata
s_version   db "EnderScript 0.1.1", 13, 10, 0
s_help      db "EnderScript 0.1.1", 13, 10, 13, 10
            db "Usage:", 13, 10
            db "  ender check <file.es>            Check syntax, semantics, and types", 13, 10
            db "  ender check --syntax <file.es>   Check syntax only", 13, 10
            db "  ender build <file.es>            Build <file>.exe", 13, 10
            db "  ender build <file.es> -o <out>   Build the selected output path", 13, 10
            db "  ender run <file.es>              Build into .ender\ and run", 13, 10
            db "  ender --version", 13, 10
            db "  ender --help", 13, 10, 0
a_version   db "--version", 0
a_help      db "--help", 0
a_check     db "check", 0
a_syntax    db "--syntax", 0
a_build     db "build", 0
a_run       db "run", 0
a_o         db "-o", 0
s_unknown   db "unknown command '", 0
s_unexpect  db "unexpected argument '", 0
s_missing   db "missing input file", 0
s_missing_o db "missing output path after -o", 0
s_ext       db "input file must use the .es extension", 0
s_big       db "source file is larger than 16 MB", 0
s_cant_read db "cannot read '", 0
s_cant_wr   db "cannot write '", 0
s_cant_run  db "cannot run '", 0
s_ok        db "ok ", 0
s_built     db "built ", 0
s_crlf      db 13, 10, 0
s_ender_dir db ".ender", 0
s_ender_pre db ".ender\", 0
s_exe       db ".exe", 0
s_empty     db 0

section .text

streq:
    xor eax, eax
.loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .no
    test r8b, r8b
    jz .yes
    inc rcx
    inc rdx
    jmp .loop
.yes:
    mov eax, 1
.no:
    ret

FUNC parse_args
    CALLAPI GetCommandLineA
    mov rsi, rax
    mov rcx, rax
    call zlen
    lea rcx, [rax + 64]
    call mem_alloc
    mov rdi, rax
    xor ebx, ebx
    cmp byte [rsi], '"'
    jne .skip0
    inc rsi
.skip0q:
    mov al, [rsi]
    test al, al
    jz .done
    inc rsi
    cmp al, '"'
    jne .skip0q
    jmp .args
.skip0:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, ' '
    je .args
    cmp al, 9
    je .args
    inc rsi
    jmp .skip0
.args:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, ' '
    je .ws
    cmp al, 9
    je .ws
    cmp ebx, MAX_ARGS
    jae .done
    lea rcx, [argv]
    mov [rcx + rbx * 8], rdi
    inc ebx
    xor r12d, r12d
.arg_char:
    mov al, [rsi]
    test al, al
    jz .arg_end
    cmp al, '"'
    jne .not_quote
    xor r12d, 1
    inc rsi
    jmp .arg_char
.not_quote:
    test r12d, r12d
    jnz .copy
    cmp al, ' '
    je .arg_end
    cmp al, 9
    je .arg_end
.copy:
    mov [rdi], al
    inc rdi
    inc rsi
    jmp .arg_char
.arg_end:
    mov byte [rdi], 0
    inc rdi
    jmp .args
.ws:
    inc rsi
    jmp .args
.done:
    mov [argc], rbx
    ENDF

FUNC frontend
    mov r12, rcx
    mov r13d, edx
    call zlen
    cmp rax, 3
    jb .bad_ext
    lea rdx, [r12 + rax - 3]
    cmp byte [rdx], '.'
    jne .bad_ext
    cmp byte [rdx + 1], 'e'
    jne .bad_ext
    cmp byte [rdx + 2], 's'
    jne .bad_ext
    mov rcx, r12
    call read_file
    test rax, rax
    jnz .loaded
    test rdx, rdx
    jnz .too_big
    lea rcx, [s_cant_read]
    mov rdx, r12
    call fatal_path
.too_big:
    lea rcx, [s_big]
    call fatal
.bad_ext:
    lea rcx, [s_ext]
    call fatal
.loaded:
    mov [g_src], rax
    mov [g_src_len], rdx
    mov [g_file], r12
    call lex
    call parse
    test r13d, r13d
    jnz .done
    call sema
.done:
    ENDF

FUNC emit_and_write
    mov r12, rcx
    call codegen
    mov rcx, r12
    mov rdx, [g_image]
    mov r8, [g_image_size]
    call write_file
    test eax, eax
    jnz .ok
    lea rcx, [s_cant_wr]
    mov rdx, r12
    call fatal_path
.ok:
    ENDF

global start
start:
    sub rsp, 40
    call sys_init
    call parse_args
    mov rbx, [argc]
    lea r12, [argv]
    test rbx, rbx
    jz .help_fail

    mov rcx, [r12]
    lea rdx, [a_version]
    call streq
    test eax, eax
    jnz .version
    mov rcx, [r12]
    lea rdx, [a_help]
    call streq
    test eax, eax
    jnz .help
    mov rcx, [r12]
    lea rdx, [a_check]
    call streq
    test eax, eax
    jnz .check
    mov rcx, [r12]
    lea rdx, [a_build]
    call streq
    test eax, eax
    jnz .build
    mov rcx, [r12]
    lea rdx, [a_run]
    call streq
    test eax, eax
    jnz .run
    lea rcx, [s_unknown]
    mov rdx, [r12]
    call fatal_path

.version:
    cmp rbx, 1
    jne .extra1
    lea rcx, [s_version]
    call write_outz
    xor ecx, ecx
    call sys_exit

.help:
    cmp rbx, 1
    jne .extra1
    lea rcx, [s_help]
    call write_outz
    xor ecx, ecx
    call sys_exit

.help_fail:
    lea rcx, [s_help]
    call write_errz
    mov ecx, 1
    call sys_exit

.extra1:
    lea rcx, [s_unexpect]
    mov rdx, [r12 + 8]
    call fatal_path

.check:
    xor r13d, r13d
    mov r14d, 1
    cmp rbx, 2
    jb .missing
    mov rcx, [r12 + 8]
    lea rdx, [a_syntax]
    call streq
    test eax, eax
    jz .check_file
    mov r13d, 1
    mov r14d, 2
.check_file:
    lea eax, [r14d + 1]
    cmp rbx, rax
    jb .missing
    ja .extra_at
    mov r15, [r12 + r14 * 8]
    mov rcx, r15
    mov edx, r13d
    call frontend
    lea rcx, [s_ok]
    call write_outz
    mov rcx, r15
    call write_outz
    lea rcx, [s_crlf]
    call write_outz
    xor ecx, ecx
    call sys_exit

.extra_at:
    lea rcx, [s_unexpect]
    mov rdx, [r12 + r14 * 8 + 8]
    call fatal_path

.missing:
    lea rcx, [s_missing]
    call fatal

.build:
    cmp rbx, 2
    jb .missing
    mov r15, [r12 + 8]
    cmp rbx, 2
    je .build_default
    mov r14d, 2
    mov rcx, [r12 + 16]
    lea rdx, [a_o]
    call streq
    test eax, eax
    jz .extra_at_build
    cmp rbx, 4
    jb .missing_o
    mov r14d, 3
    ja .extra_at
    mov r13, [r12 + 24]
    jmp .build_go
.extra_at_build:
    lea rcx, [s_unexpect]
    mov rdx, [r12 + 16]
    call fatal_path
.missing_o:
    lea rcx, [s_missing_o]
    call fatal
.build_default:
    mov rcx, r15
    call zlen
    lea rdx, [rax - 3]
    mov rcx, r15
    lea r8, [s_empty]
    lea r9, [s_exe]
    call join_stem
    mov r13, rax
.build_go:
    mov rcx, r15
    xor edx, edx
    call frontend
    mov rcx, r13
    call emit_and_write
    lea rcx, [s_built]
    call write_outz
    mov rcx, r13
    call write_outz
    lea rcx, [s_crlf]
    call write_outz
    xor ecx, ecx
    call sys_exit

.run:
    cmp rbx, 2
    jb .missing
    mov r14d, 1
    ja .extra_at
    mov r15, [r12 + 8]
    mov rcx, r15
    xor edx, edx
    call frontend
    mov rcx, r15
    call zlen
    lea rsi, [r15 + rax - 3]
    mov rdi, rsi
.base:
    cmp rdi, r15
    jbe .base_done
    mov al, [rdi - 1]
    cmp al, '\'
    je .base_done
    cmp al, '/'
    je .base_done
    cmp al, ':'
    je .base_done
    dec rdi
    jmp .base
.base_done:
    mov rcx, rdi
    mov rdx, rsi
    sub rdx, rdi
    lea r8, [s_ender_pre]
    lea r9, [s_exe]
    call join_stem
    mov r13, rax
    lea rcx, [s_ender_dir]
    call make_dir
    mov rcx, r13
    call emit_and_write
    mov rcx, r13
    call run_process
    cmp eax, -1
    jne .run_exit
    lea rcx, [s_cant_run]
    mov rdx, r13
    call fatal_path
.run_exit:
    mov ecx, eax
    call sys_exit

FUNC join_stem, 16
    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9
    mov rcx, r8
    call zlen
    mov rbx, rax
    mov rcx, r15
    call zlen
    mov rsi, rax
    lea rcx, [rbx + rsi + 16]
    add rcx, r13
    call mem_alloc
    mov [L(0)], rax
    mov rdi, rax
    mov rcx, rbx
    mov rbx, rsi
    mov rsi, r14
    rep movsb
    mov rsi, r12
    mov rcx, r13
    rep movsb
    mov rsi, r15
    mov rcx, rbx
    rep movsb
    mov byte [rdi], 0
    mov rax, [L(0)]
    ENDF
