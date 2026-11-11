%include "defs.inc"
%define OWN_write_out
%define OWN_write_err
%define OWN_write_outz
%define OWN_write_errz
%define OWN_zlen
%define OWN_sys_exit
%include "state.inc"

WINAPI GetStdHandle, 4
WINAPI WriteFile, 20
WINAPI ReadFile, 20
WINAPI CreateFileA, 28
WINAPI GetFileSizeEx, 8
WINAPI CloseHandle, 4
WINAPI ExitProcess, 4
WINAPI CreateProcessA, 40
WINAPI WaitForSingleObject, 8
WINAPI GetExitCodeProcess, 8
WINAPI CreateDirectoryA, 8
WINAPI DeleteFileA, 4

section .text

FUNC sys_init
    push -11
    CALLAPI GetStdHandle
    mov [g_hout], eax
    push -12
    CALLAPI GetStdHandle
    mov [g_herr], eax
    ENDF

FUNC write_handle, 4
    test edx, edx
    jz .done
    push 0
    lea ebx, [L(0)]
    push ebx
    push edx
    push ecx
    push eax
    CALLAPI WriteFile
.done:
    ENDF

global write_out
write_out:
    mov eax, [g_hout]
    jmp write_handle

global write_err
write_err:
    mov eax, [g_herr]
    jmp write_handle

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
    push ecx
    CALLAPI ExitProcess

FUNC read_file, 16
    mov dword [L(0)], 0
    mov dword [L(4)], 0
    push 0
    push 0x80
    push 3
    push 0
    push 1
    push 0x80000000
    push ecx
    CALLAPI CreateFileA
    cmp eax, -1
    je .fail
    mov ebx, eax
    lea eax, [L(0)]
    push eax
    push ebx
    CALLAPI GetFileSizeEx
    test eax, eax
    jz .fail_close
    cmp dword [L(4)], 0
    jne .too_big
    mov esi, [L(0)]
    cmp esi, MAX_SOURCE
    ja .too_big
    lea ecx, [esi + 16]
    call mem_alloc
    mov edi, eax
    test esi, esi
    jz .ok
    push 0
    lea eax, [L(8)]
    push eax
    push esi
    push edi
    push ebx
    CALLAPI ReadFile
    test eax, eax
    jz .fail_close
    cmp [L(8)], esi
    jne .fail_close
.ok:
    push ebx
    CALLAPI CloseHandle
    mov eax, edi
    mov edx, esi
    ENDF
.too_big:
    push ebx
    CALLAPI CloseHandle
    xor eax, eax
    mov edx, 1
    ENDF
.fail_close:
    push ebx
    CALLAPI CloseHandle
.fail:
    xor eax, eax
    xor edx, edx
    ENDF

FUNC write_file, 16
    mov esi, edx
    mov edi, eax
    mov ebx, ecx
    push ecx
    CALLAPI DeleteFileA
    mov ecx, ebx
    push 0
    push 0x80
    push 2
    push 0
    push 0
    push 0x40000000
    push ecx
    CALLAPI CreateFileA
    cmp eax, -1
    je .fail
    mov ebx, eax
    push 0
    lea eax, [L(0)]
    push eax
    push edi
    push esi
    push ebx
    CALLAPI WriteFile
    mov [L(4)], eax
    push ebx
    CALLAPI CloseHandle
    cmp dword [L(4)], 0
    je .fail
    cmp [L(0)], edi
    jne .fail
    mov eax, 1
    ENDF
.fail:
    xor eax, eax
    ENDF

FUNC make_dir
    push 0
    push ecx
    CALLAPI CreateDirectoryA
    ENDF

FUNC run_process, 112
    mov esi, ecx
    call zlen
    mov ebx, eax
    lea ecx, [eax + 8]
    call mem_alloc
    mov edx, eax
    mov byte [edx], '"'
    lea edi, [edx + 1]
    push esi
    mov ecx, ebx
    rep movsb
    pop esi
    mov byte [edi], '"'
    mov byte [edi + 1], 0
    mov esi, edx
    lea edi, [L(0)]
    xor eax, eax
    mov ecx, 112
    rep stosb
    mov dword [L(0)], 68
    lea eax, [L(80)]
    push eax
    lea eax, [L(0)]
    push eax
    push 0
    push 0
    push 0
    push 1
    push 0
    push 0
    push esi
    push 0
    CALLAPI CreateProcessA
    test eax, eax
    jz .fail
    push 0xFFFFFFFF
    push dword [L(80)]
    CALLAPI WaitForSingleObject
    mov dword [L(96)], 1
    lea eax, [L(96)]
    push eax
    push dword [L(80)]
    CALLAPI GetExitCodeProcess
    push dword [L(84)]
    CALLAPI CloseHandle
    push dword [L(80)]
    CALLAPI CloseHandle
    mov eax, [L(96)]
    ENDF
.fail:
    mov eax, -1
    ENDF
