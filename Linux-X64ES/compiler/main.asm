%include "defs.inc"
%include "state.inc"

extern sys_init, read_file, write_file, make_dir, run_process, g_envp
extern lex, parse, sema, codegen
extern g_image, g_image_size

%define MAX_ARGS 64

section .bss
alignb 8
argc resq 1
argv resq MAX_ARGS

section .rodata
s_version   db "EnderScript 0.1.1 (Linux x64)", 10, 0
s_help      db "EnderScript 0.1.1 (Linux x64)", 10, 10
            db "Usage:", 10
            db "  ender <file.es>             Build into .ender/ and run", 10
            db "  ender examine <file.es>     Check the whole program, including code generation, without writing an exe", 10
            db "  ender run <file.es>         Run the program built earlier in .ender/", 10
            db "  ender --version", 10
            db "  ender --help", 10, 0
a_version   db "--version", 0
a_help      db "--help", 0
a_examine   db "examine", 0
a_run       db "run", 0
s_unknown   db "unknown command '", 0
s_unexpect  db "unexpected argument '", 0
s_missing   db "missing input file", 0
s_not_built db "' is not built yet, run 'ender ", 0
s_first     db "' first", 0
s_quote1    db "'", 0
s_ext       db "input file must use the .es extension", 0
s_big       db "source file is larger than 16 MB", 0
s_cant_read db "cannot read '", 0
s_cant_wr   db "cannot write '", 0
s_cant_run  db "cannot run '", 0
s_ok        db "ok ", 0
s_crlf      db 10, 0
s_ender_dir db ".ender", 0
s_ender_pre db ".ender/", 0
s_exe       db 0
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

FUNC exe_path
    mov r15, rcx
    call zlen
    lea rsi, [r15 + rax - 3]
    mov rdi, rsi
.base:
    cmp rdi, r15
    jbe .base_done
    mov al, [rdi - 1]
    cmp al, 92
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
    ENDF

check_ext:
    push rcx
    call zlen
    pop rcx
    cmp rax, 3
    jb .bad
    cmp byte [rcx + rax - 3], '.'
    jne .bad
    cmp byte [rcx + rax - 2], 'e'
    jne .bad
    cmp byte [rcx + rax - 1], 's'
    jne .bad
    ret
.bad:
    lea rcx, [s_ext]
    call fatal

global start
start:
    mov rcx, [rsp]
    lea rsi, [rsp + 16]
    lea rax, [rsp + rcx * 8 + 16]
    mov [g_envp], rax
    dec rcx
    cmp rcx, MAX_ARGS
    jbe .argc_ok
    mov ecx, MAX_ARGS
.argc_ok:
    mov [argc], rcx
    lea rdi, [argv]
    rep movsq
    and rsp, -16
    sub rsp, 40
    call sys_init
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
    lea rdx, [a_examine]
    call streq
    test eax, eax
    jnz .examine
    mov rcx, [r12]
    lea rdx, [a_run]
    call streq
    test eax, eax
    jnz .run
    mov rcx, [r12]
    call zlen
    cmp rax, 3
    jb .unknown
    mov rcx, [r12]
    cmp byte [rcx + rax - 3], '.'
    jne .unknown
    cmp byte [rcx + rax - 2], 'e'
    jne .unknown
    cmp byte [rcx + rax - 1], 's'
    je .build_run
.unknown:
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

.extra2:
    lea rcx, [s_unexpect]
    mov rdx, [r12 + 16]
    call fatal_path

.missing:
    lea rcx, [s_missing]
    call fatal

.examine:
    cmp rbx, 2
    jb .missing
    ja .extra2
    mov r15, [r12 + 8]
    mov rcx, r15
    xor edx, edx
    call frontend
    call codegen
    lea rcx, [s_ok]
    call write_outz
    mov rcx, r15
    call write_outz
    lea rcx, [s_crlf]
    call write_outz
    xor ecx, ecx
    call sys_exit

.run:
    cmp rbx, 2
    jb .missing
    ja .extra2
    mov r15, [r12 + 8]
    mov rcx, r15
    call check_ext
    mov rcx, r15
    call exe_path
    mov r13, rax
    mov rcx, r13
    call read_file
    test rax, rax
    jz .not_built
    mov rcx, r13
    call run_process
    cmp eax, -1
    jne .run_exit
.not_built:
    mov rcx, r13
    call zlen
    mov rdx, rax
    mov rcx, r13
    lea r8, [s_quote1]
    lea r9, [s_not_built]
    call join_stem
    mov r14, rax
    mov rcx, r15
    call zlen
    mov rdx, rax
    mov rcx, r15
    mov r8, r14
    lea r9, [s_first]
    call join_stem
    mov rcx, rax
    call fatal

.build_run:
    cmp rbx, 1
    ja .extra1
    mov r15, [r12]
    mov rcx, r15
    xor edx, edx
    call frontend
    mov rcx, r15
    call exe_path
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
