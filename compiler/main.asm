%include "defs.inc"
%include "state.inc"

extern sys_init, read_file, write_file, make_dir, run_process, g_envp
extern lex, parse, sema, codegen
extern g_image, g_image_size

%define MAX_ARGS 64

section .bss
alignb 4
argc     resd 1
argv     resd MAX_ARGS
in_path  resd 1
out_path resd 1
syn_only resd 1
file_idx resd 1

section .rodata
s_version   db "EnderScript 0.1.1 (Linux x32)", 10, 0
s_help      db "EnderScript 0.1.1 (Linux x32)", 10, 10
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
s_err_q     db "error: '", 0
s_not_built db "' is not built yet, run 'ender ", 0
s_first     db "' first", 10, 0
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
    push ebx
    xor eax, eax
.loop:
    mov bl, [ecx]
    cmp bl, [edx]
    jne .no
    test bl, bl
    jz .yes
    inc ecx
    inc edx
    jmp .loop
.yes:
    mov eax, 1
.no:
    pop ebx
    ret

%macro ARGEQ 2
    mov ecx, [argv + %1 * 4]
    mov edx, %2
    call streq
    test eax, eax
%endmacro

FUNC frontend
    mov esi, ecx
    mov edi, edx
    call zlen
    cmp eax, 3
    jb .bad_ext
    lea edx, [esi + eax - 3]
    cmp byte [edx], '.'
    jne .bad_ext
    cmp byte [edx + 1], 'e'
    jne .bad_ext
    cmp byte [edx + 2], 's'
    jne .bad_ext
    mov ecx, esi
    call read_file
    test eax, eax
    jnz .loaded
    test edx, edx
    jnz .too_big
    mov ecx, s_cant_read
    mov edx, esi
    call fatal_path
.too_big:
    mov ecx, s_big
    call fatal
.bad_ext:
    mov ecx, s_ext
    call fatal
.loaded:
    mov [g_src], eax
    mov [g_src_len], edx
    mov [g_file], esi
    call lex
    call parse
    test edi, edi
    jnz .done
    call sema
.done:
    ENDF

FUNC join_stem
    mov esi, ecx
    mov edi, edx
    mov ebx, eax
    mov ecx, eax
    call zlen
    push eax
    lea ecx, [eax + edi + 16]
    call mem_alloc
    pop ecx
    push eax
    push esi
    mov esi, ebx
    mov edx, edi
    mov edi, eax
    rep movsb
    pop esi
    mov ecx, edx
    rep movsb
    mov byte [edi], 0
    pop eax
    ENDF

FUNC emit_and_write
    mov esi, ecx
    call codegen
    mov ecx, esi
    mov edx, [g_image]
    mov eax, [g_image_size]
    call write_file
    test eax, eax
    jnz .ok
    mov ecx, s_cant_wr
    mov edx, esi
    call fatal_path
.ok:
    ENDF

extra_arg:
    mov edx, [argv + eax * 4]
    mov ecx, s_unexpect
    call fatal_path

missing:
    mov ecx, s_missing
    call fatal

global start
start:
    mov ecx, [esp]
    lea esi, [esp + 8]
    lea eax, [esp + ecx * 4 + 8]
    mov [g_envp], eax
    dec ecx
    cmp ecx, MAX_ARGS
    jbe .argc_ok
    mov ecx, MAX_ARGS
.argc_ok:
    mov [argc], ecx
    mov edi, argv
    rep movsd
    call sys_init
    mov ebx, [argc]
    test ebx, ebx
    jz .help_fail
    ARGEQ 0, a_version
    jnz .version
    ARGEQ 0, a_help
    jnz .help
    ARGEQ 0, a_examine
    jnz .examine
    ARGEQ 0, a_run
    jnz .run
    mov ecx, [argv]
    call is_es
    test eax, eax
    jnz .build_run
    mov ecx, s_unknown
    mov edx, [argv]
    call fatal_path

.version:
    mov eax, 1
    cmp ebx, 1
    jne extra_arg
    mov ecx, s_version
    call write_outz
    xor ecx, ecx
    call sys_exit

.help:
    mov eax, 1
    cmp ebx, 1
    jne extra_arg
    mov ecx, s_help
    call write_outz
    xor ecx, ecx
    call sys_exit

.help_fail:
    mov ecx, s_help
    call write_errz
    mov ecx, 1
    call sys_exit

.examine:
    cmp ebx, 2
    jb missing
    mov eax, 2
    ja extra_arg
    mov esi, [argv + 4]
    mov ecx, esi
    xor edx, edx
    call frontend
    call codegen
    mov ecx, s_ok
    call write_outz
    mov ecx, esi
    call write_outz
    mov ecx, s_crlf
    call write_outz
    xor ecx, ecx
    call sys_exit

.run:
    cmp ebx, 2
    jb missing
    mov eax, 2
    ja extra_arg
    mov esi, [argv + 4]
    mov ecx, esi
    call is_es
    test eax, eax
    jnz .run_ok
    mov ecx, s_ext
    call fatal
.run_ok:
    mov ecx, esi
    call exe_path
    mov [out_path], eax
    mov ecx, eax
    call read_file
    test eax, eax
    jz .not_built
    mov ecx, [out_path]
    call run_process
    cmp eax, -1
    jne .run_exit
.not_built:
    mov ecx, s_err_q
    call write_errz
    mov ecx, [out_path]
    call write_errz
    mov ecx, s_not_built
    call write_errz
    mov ecx, esi
    call write_errz
    mov ecx, s_first
    call write_errz
    mov ecx, 1
    call sys_exit

.build_run:
    mov eax, 1
    cmp ebx, 1
    ja extra_arg
    mov esi, [argv]
    mov ecx, esi
    xor edx, edx
    call frontend
    mov ecx, esi
    call exe_path
    mov [out_path], eax
    mov ecx, s_ender_dir
    call make_dir
    mov ecx, [out_path]
    call emit_and_write
    mov ecx, [out_path]
    call run_process
    cmp eax, -1
    jne .run_exit
    mov ecx, s_cant_run
    mov edx, [out_path]
    call fatal_path
.run_exit:
    mov ecx, eax
    call sys_exit

is_es:
    push ecx
    call zlen
    pop ecx
    mov edx, eax
    xor eax, eax
    cmp edx, 3
    jb .r
    cmp byte [ecx + edx - 3], '.'
    jne .r
    cmp byte [ecx + edx - 2], 'e'
    jne .r
    cmp byte [ecx + edx - 1], 's'
    jne .r
    mov eax, 1
.r:
    ret

FUNC exe_path
    mov esi, ecx
    call zlen
    lea edx, [esi + eax - 3]
    mov edi, edx
.base:
    cmp edi, esi
    jbe .base_done
    mov al, [edi - 1]
    cmp al, 92
    je .base_done
    cmp al, '/'
    je .base_done
    cmp al, ':'
    je .base_done
    dec edi
    jmp .base
.base_done:
    mov ecx, edi
    sub edx, edi
    mov eax, s_ender_pre
    call join_stem
    ENDF
