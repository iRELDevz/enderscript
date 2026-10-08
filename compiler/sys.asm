%include "defs.inc"
%define OWN_write_out
%define OWN_write_err
%define OWN_write_outz
%define OWN_write_errz
%define OWN_zlen
%define OWN_sys_exit
%include "state.inc"

section .bss
global g_envp
alignb 4
g_envp   resd 1
argv_buf resd 2

section .text

FUNC sys_init
    ENDF

FUNC write_fd
    mov ebx, eax
    mov esi, edx
.loop:
    test esi, esi
    jz .done
    mov edx, esi
    mov eax, SYS_WRITE
    int 0x80
    test eax, eax
    jle .done
    add ecx, eax
    sub esi, eax
    jmp .loop
.done:
    ENDF

global write_out
write_out:
    mov eax, 1
    jmp write_fd

global write_err
write_err:
    mov eax, 2
    jmp write_fd

global zlen
zlen:
    mov eax, ecx
.loop:
    cmp byte [eax], 0
    je .end
    inc eax
    jmp .loop
.end:
    sub eax, ecx
    ret

FUNC write_outz
    mov ebx, ecx
    call zlen
    mov ecx, ebx
    mov edx, eax
    call write_out
    ENDF

FUNC write_errz
    mov ebx, ecx
    call zlen
    mov ecx, ebx
    mov edx, eax
    call write_err
    ENDF

global sys_exit
sys_exit:
    mov ebx, ecx
    mov eax, SYS_EXIT_GRP
    int 0x80

FUNC read_file, 16
    mov ebx, ecx
    xor ecx, ecx
    xor edx, edx
    mov eax, SYS_OPEN
    int 0x80
    test eax, eax
    js .fail
    mov [L(0)], eax
    mov ebx, eax
    xor ecx, ecx
    mov edx, 2
    mov eax, SYS_LSEEK
    int 0x80
    test eax, eax
    js .fail_close
    mov esi, eax
    cmp esi, MAX_SOURCE
    ja .too_big
    mov ebx, [L(0)]
    xor ecx, ecx
    xor edx, edx
    mov eax, SYS_LSEEK
    int 0x80
    test eax, eax
    js .fail_close
    lea ecx, [esi + 16]
    call mem_alloc
    mov edi, eax
    xor eax, eax
    mov [L(4)], eax
.read:
    mov eax, [L(4)]
    cmp eax, esi
    jae .ok
    mov ebx, [L(0)]
    lea ecx, [edi + eax]
    mov edx, esi
    sub edx, eax
    mov eax, SYS_READ
    int 0x80
    test eax, eax
    jle .fail_close
    add [L(4)], eax
    jmp .read
.ok:
    mov ebx, [L(0)]
    mov eax, SYS_CLOSE
    int 0x80
    mov eax, edi
    mov edx, esi
    ENDF
.too_big:
    mov ebx, [L(0)]
    mov eax, SYS_CLOSE
    int 0x80
    xor eax, eax
    mov edx, 1
    ENDF
.fail_close:
    mov ebx, [L(0)]
    mov eax, SYS_CLOSE
    int 0x80
.fail:
    xor eax, eax
    xor edx, edx
    ENDF

FUNC write_file, 16
    mov esi, edx
    mov edi, eax
    mov [L(0)], ecx
    mov ebx, ecx
    mov eax, SYS_UNLINK
    int 0x80
    mov ebx, [L(0)]
    mov ecx, 577
    mov edx, 0o755
    mov eax, SYS_OPEN
    int 0x80
    test eax, eax
    js .fail
    mov [L(4)], eax
    mov dword [L(8)], 1
.write:
    test edi, edi
    jz .close
    mov ebx, [L(4)]
    mov ecx, esi
    mov edx, edi
    mov eax, SYS_WRITE
    int 0x80
    test eax, eax
    jle .bad
    add esi, eax
    sub edi, eax
    jmp .write
.bad:
    mov dword [L(8)], 0
.close:
    mov ebx, [L(4)]
    mov eax, SYS_CLOSE
    int 0x80
    mov eax, [L(8)]
    ENDF
.fail:
    xor eax, eax
    ENDF

FUNC make_dir
    mov ebx, ecx
    mov ecx, 0o755
    mov eax, SYS_MKDIR
    int 0x80
    ENDF

FUNC run_process, 16
    mov esi, ecx
    mov eax, SYS_FORK
    int 0x80
    test eax, eax
    js .fail
    jnz .parent
    mov [argv_buf], esi
    mov dword [argv_buf + 4], 0
    mov ebx, esi
    mov ecx, argv_buf
    mov edx, [g_envp]
    mov eax, SYS_EXECVE
    int 0x80
    mov ebx, 127
    mov eax, SYS_EXIT_GRP
    int 0x80
.parent:
    mov ebx, eax
    lea ecx, [L(0)]
    mov dword [ecx], 0
    xor edx, edx
    mov eax, SYS_WAITPID
    int 0x80
    test eax, eax
    js .fail
    mov eax, [L(0)]
    mov ecx, eax
    and ecx, 0x7F
    jnz .signaled
    shr eax, 8
    and eax, 0xFF
    ENDF
.signaled:
    lea eax, [ecx + 128]
    ENDF
.fail:
    mov eax, -1
    ENDF
