%include "defs.inc"
%define OWN_write_out
%define OWN_write_err
%define OWN_write_outz
%define OWN_write_errz
%define OWN_zlen
%define OWN_sys_exit
%include "state.inc"

WINAPI GetStdHandle
WINAPI WriteFile
WINAPI ReadFile
WINAPI CreateFileA
WINAPI GetFileSizeEx
WINAPI CloseHandle
WINAPI ExitProcess
WINAPI CreateProcessA
WINAPI WaitForSingleObject
WINAPI GetExitCodeProcess
WINAPI CreateDirectoryA

section .text

FUNC sys_init
    mov ecx, -11
    CALLAPI GetStdHandle
    mov [g_hout], rax
    mov ecx, -12
    CALLAPI GetStdHandle
    mov [g_herr], rax
    ENDF

FUNC write_handle, 16
    mov r8, rdx
    mov rdx, rcx
    mov rcx, rax
    test r8, r8
    jz .done
    lea r9, [L(0)]
    mov qword [rsp + 32], 0
    CALLAPI WriteFile
.done:
    ENDF

global write_out
write_out:
    mov rax, [g_hout]
    jmp write_handle

global write_err
write_err:
    mov rax, [g_herr]
    jmp write_handle

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
    and rsp, -16
    sub rsp, 32
    CALLAPI ExitProcess

FUNC read_file, 16
    mov qword [L(0)], 0
    mov r12, rcx
    mov edx, 0x80000000
    mov r8d, 1
    xor r9d, r9d
    mov qword [rsp + 32], 3
    mov qword [rsp + 40], 0x80
    mov qword [rsp + 48], 0
    CALLAPI CreateFileA
    cmp rax, -1
    je .fail
    mov r13, rax
    mov rcx, r13
    lea rdx, [L(0)]
    CALLAPI GetFileSizeEx
    test eax, eax
    jz .fail_close
    mov r14, [L(0)]
    cmp r14, MAX_SOURCE
    ja .too_big
    lea rcx, [r14 + 16]
    call mem_alloc
    mov r15, rax
    test r14, r14
    jz .ok
    mov rcx, r13
    mov rdx, r15
    mov r8, r14
    lea r9, [L(8)]
    mov qword [rsp + 32], 0
    CALLAPI ReadFile
    test eax, eax
    jz .fail_close
    mov eax, [L(8)]
    cmp rax, r14
    jne .fail_close
.ok:
    mov rcx, r13
    CALLAPI CloseHandle
    mov rax, r15
    mov rdx, r14
    ENDF
.too_big:
    mov rcx, r13
    CALLAPI CloseHandle
    xor eax, eax
    mov edx, 1
    ENDF
.fail_close:
    mov rcx, r13
    CALLAPI CloseHandle
.fail:
    xor eax, eax
    xor edx, edx
    ENDF

FUNC write_file, 16
    mov r12, rdx
    mov r13, r8
    mov edx, 0x40000000
    xor r8d, r8d
    xor r9d, r9d
    mov qword [rsp + 32], 2
    mov qword [rsp + 40], 0x80
    mov qword [rsp + 48], 0
    CALLAPI CreateFileA
    cmp rax, -1
    je .fail
    mov r14, rax
    mov rcx, r14
    mov rdx, r12
    mov r8, r13
    lea r9, [L(0)]
    mov qword [rsp + 32], 0
    CALLAPI WriteFile
    mov r15d, eax
    mov rcx, r14
    CALLAPI CloseHandle
    test r15d, r15d
    jz .fail
    mov eax, [L(0)]
    cmp rax, r13
    jne .fail
    mov eax, 1
    ENDF
.fail:
    xor eax, eax
    ENDF

FUNC make_dir
    xor edx, edx
    CALLAPI CreateDirectoryA
    ENDF

FUNC run_process, 176
    mov r12, rcx
    call zlen
    mov r13, rax
    lea rcx, [rax + 8]
    call mem_alloc
    mov r14, rax
    mov byte [r14], '"'
    lea rdi, [r14 + 1]
    mov rsi, r12
    mov rcx, r13
    rep movsb
    mov byte [rdi], '"'
    mov byte [rdi + 1], 0
    lea rdi, [L(16)]
    xor eax, eax
    mov ecx, 144
    rep stosb
    mov dword [L(16)], 104
    xor ecx, ecx
    mov rdx, r14
    xor r8d, r8d
    xor r9d, r9d
    mov qword [rsp + 32], 1
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    lea rax, [L(16)]
    mov [rsp + 64], rax
    lea rax, [L(128)]
    mov [rsp + 72], rax
    CALLAPI CreateProcessA
    test eax, eax
    jz .fail
    mov rcx, [L(128)]
    mov edx, 0xFFFFFFFF
    CALLAPI WaitForSingleObject
    mov dword [L(160)], 1
    mov rcx, [L(128)]
    lea rdx, [L(160)]
    CALLAPI GetExitCodeProcess
    mov rcx, [L(128) + 8]
    CALLAPI CloseHandle
    mov rcx, [L(128)]
    CALLAPI CloseHandle
    mov eax, [L(160)]
    ENDF
.fail:
    mov eax, -1
    ENDF
