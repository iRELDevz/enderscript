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
alignb 8
g_envp   resq 1
stat_buf resb 144
argv_buf resq 2

section .text

FUNC sys_init
    ENDF

write_fd:
    push rsi
    push rdi
    mov rsi, rcx
.loop:
    test rdx, rdx
    jz .done
    mov edi, eax
    push rax
    push rdx
    mov eax, SYS_WRITE
    syscall
    mov rcx, rax
    pop rdx
    pop rax
    test rcx, rcx
    jle .done
    add rsi, rcx
    sub rdx, rcx
    jmp .loop
.done:
    pop rdi
    pop rsi
    ret

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
    mov rax, rcx
.loop:
    cmp byte [rax], 0
    je .end
    inc rax
    jmp .loop
.end:
    sub rax, rcx
    ret

FUNC write_outz
    mov rbx, rcx
    call zlen
    mov rcx, rbx
    mov rdx, rax
    call write_out
    ENDF

FUNC write_errz
    mov rbx, rcx
    call zlen
    mov rcx, rbx
    mov rdx, rax
    call write_err
    ENDF

global sys_exit
sys_exit:
    mov edi, ecx
    mov eax, SYS_EXIT
    syscall

FUNC read_file
    mov rdi, rcx
    xor esi, esi
    xor edx, edx
    mov eax, SYS_OPEN
    syscall
    test rax, rax
    js .fail
    mov r12, rax
    mov rdi, r12
    lea rsi, [stat_buf]
    mov eax, SYS_FSTAT
    syscall
    test rax, rax
    js .fail_close
    mov r14, [stat_buf + 48]
    cmp r14, MAX_SOURCE
    ja .too_big
    lea rcx, [r14 + 16]
    call mem_alloc
    mov r15, rax
    xor r13d, r13d
.read:
    cmp r13, r14
    jae .ok
    mov rdi, r12
    lea rsi, [r15 + r13]
    mov rdx, r14
    sub rdx, r13
    mov eax, SYS_READ
    syscall
    test rax, rax
    jle .fail_close
    add r13, rax
    jmp .read
.ok:
    mov rdi, r12
    mov eax, SYS_CLOSE
    syscall
    mov rax, r15
    mov rdx, r14
    ENDF
.too_big:
    mov rdi, r12
    mov eax, SYS_CLOSE
    syscall
    xor eax, eax
    mov edx, 1
    ENDF
.fail_close:
    mov rdi, r12
    mov eax, SYS_CLOSE
    syscall
.fail:
    xor eax, eax
    xor edx, edx
    ENDF

FUNC write_file
    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov rdi, r12
    mov eax, SYS_UNLINK
    syscall
    mov rdi, r12
    mov esi, 577
    mov edx, 0o755
    mov eax, SYS_OPEN
    syscall
    test rax, rax
    js .fail
    mov r15, rax
    mov rbx, 1
.write:
    test r14, r14
    jz .close
    mov rdi, r15
    mov rsi, r13
    mov rdx, r14
    mov eax, SYS_WRITE
    syscall
    test rax, rax
    jle .bad
    add r13, rax
    sub r14, rax
    jmp .write
.bad:
    xor ebx, ebx
.close:
    mov rdi, r15
    mov eax, SYS_CLOSE
    syscall
    mov rax, rbx
    ENDF
.fail:
    xor eax, eax
    ENDF

FUNC make_dir
    mov rdi, rcx
    mov esi, 0o755
    mov eax, SYS_MKDIR
    syscall
    ENDF

FUNC run_process, 16
    mov r12, rcx
    mov eax, SYS_FORK
    syscall
    test rax, rax
    js .fail
    jnz .parent
    lea rsi, [argv_buf]
    mov [rsi], r12
    mov qword [rsi + 8], 0
    mov rdi, r12
    mov rdx, [g_envp]
    mov eax, SYS_EXECVE
    syscall
    mov edi, 127
    mov eax, SYS_EXIT
    syscall
.parent:
    mov rdi, rax
    lea rsi, [L(0)]
    mov dword [rsi], 0
    xor edx, edx
    xor r10d, r10d
    mov eax, SYS_WAIT4
    syscall
    test rax, rax
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
