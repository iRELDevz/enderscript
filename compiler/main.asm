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
            db "  ender check <file.es>            Check syntax, semantics, and types", 10
            db "  ender check --syntax <file.es>   Check syntax only", 10
            db "  ender build <file.es>            Build <file>", 10
            db "  ender build <file.es> -o <out>   Build the selected output path", 10
            db "  ender run <file.es>              Build into .ender/ and run", 10
            db "  ender --version", 10
            db "  ender --help", 10, 0
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
    ARGEQ 0, a_check
    jnz .check
    ARGEQ 0, a_build
    jnz .build
    ARGEQ 0, a_run
    jnz .run
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

.check:
    mov dword [syn_only], 0
    mov dword [file_idx], 1
    cmp ebx, 2
    jb missing
    ARGEQ 1, a_syntax
    jz .check_file
    mov dword [syn_only], 1
    mov dword [file_idx], 2
.check_file:
    mov eax, [file_idx]
    cmp ebx, eax
    jbe missing
    inc eax
    cmp ebx, eax
    ja extra_arg
    mov eax, [file_idx]
    mov esi, [argv + eax * 4]
    mov ecx, esi
    mov edx, [syn_only]
    call frontend
    mov ecx, s_ok
    call write_outz
    mov ecx, esi
    call write_outz
    mov ecx, s_crlf
    call write_outz
    xor ecx, ecx
    call sys_exit

.build:
    cmp ebx, 2
    jb missing
    mov esi, [argv + 4]
    je .build_default
    ARGEQ 2, a_o
    jnz .build_o
    mov eax, 2
    jmp extra_arg
.build_o:
    cmp ebx, 4
    jb .missing_o
    mov eax, 4
    ja extra_arg
    mov eax, [argv + 12]
    mov [out_path], eax
    jmp .build_go
.missing_o:
    mov ecx, s_missing_o
    call fatal
.build_default:
    mov ecx, esi
    call zlen
    lea edx, [eax - 3]
    mov ecx, esi
    mov eax, s_empty
    call join_stem
    mov [out_path], eax
.build_go:
    mov ecx, esi
    xor edx, edx
    call frontend
    mov ecx, [out_path]
    call emit_and_write
    mov ecx, s_built
    call write_outz
    mov ecx, [out_path]
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
    xor edx, edx
    call frontend
    mov ecx, esi
    call zlen
    lea edx, [esi + eax - 3]
    mov edi, edx
.base:
    cmp edi, esi
    jbe .base_done
    mov al, [edi - 1]
    cmp al, '\'
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
