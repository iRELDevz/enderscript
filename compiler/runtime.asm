%include "defs.inc"

section .rdata
global rt_start, rt_size, rt_offsets

align 16
rt_start:

rt_write:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rsi, rcx
    mov rbx, rdx
.loop:
    test rbx, rbx
    jz .done
    mov eax, [r15 + RT_OUT_LEN]
    mov ecx, RT_BUF_SIZE
    sub ecx, eax
    jnz .copy
    call rt_flush
    jmp .loop
.copy:
    cmp rcx, rbx
    jbe .count
    mov rcx, rbx
.count:
    lea rdi, [r15 + RT_BUF + rax]
    sub rbx, rcx
    add eax, ecx
    mov [r15 + RT_OUT_LEN], eax
    rep movsb
    jmp .loop
.done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

rt_write_int:
    sub rsp, 56
    movsxd rax, ecx
    lea r8, [rsp + 52]
    mov r9, r8
    xor r10d, r10d
    test rax, rax
    jns .pos
    neg rax
    mov r10d, 1
.pos:
    mov ecx, 10
.digit:
    xor edx, edx
    div rcx
    add dl, '0'
    dec r9
    mov [r9], dl
    test rax, rax
    jnz .digit
    test r10d, r10d
    jz .write
    dec r9
    mov byte [r9], '-'
.write:
    mov rcx, r9
    mov rdx, r8
    sub rdx, r9
    call rt_write
    add rsp, 56
    ret

rt_write_bool:
    test cl, cl
    jz .false
    lea rcx, [rt_s_true]
    mov edx, 4
    jmp rt_write
.false:
    lea rcx, [rt_s_false]
    mov edx, 5
    jmp rt_write

rt_write_str:
    mov rax, [rcx]
    test rax, rax
    jz .null
    movzx edx, word [rcx + 8]
    mov rcx, rax
    jmp rt_write
.null:
    lea rcx, [rt_s_null]
    mov edx, 4
    jmp rt_write

rt_flush:
    sub rsp, 56
    mov r8d, [r15 + RT_OUT_LEN]
    test r8d, r8d
    jz .done
    mov rcx, [r15 + RT_STDOUT]
    lea rdx, [r15 + RT_BUF]
    lea r9, [rsp + 40]
    mov qword [rsp + 32], 0
    call [r15 + RT_WRITEFILE]
    mov dword [r15 + RT_OUT_LEN], 0
.done:
    add rsp, 56
    ret

rt_div_zero:
    and rsp, -16
    mov ebx, edx
    call rt_flush
    sub rsp, 128
    lea r13, [rsp + 128]
    mov word [r13 - 2], 0x0A0D
    lea r12, [r13 - 2]
    mov eax, ebx
    mov ecx, 10
.digit:
    xor edx, edx
    div ecx
    add dl, '0'
    dec r12
    mov [r12], dl
    test eax, eax
    jnz .digit
    sub r12, rt_s_divz_len
    mov rdi, r12
    lea rsi, [rt_s_divz]
    mov ecx, rt_s_divz_len
    rep movsb
    mov ecx, -12
    call [r15 + RT_GETSTD]
    mov rcx, rax
    mov rdx, r12
    mov r8, r13
    sub r8, r12
    lea r9, [rsp + 40]
    mov qword [rsp + 32], 0
    call [r15 + RT_WRITEFILE]
    mov ecx, 1
    call [r15 + RT_EXIT]

rt_str_eq:
    test rcx, rcx
    jz .a_null
    test r8, r8
    jz .no
    cmp rdx, r9
    jne .no
    push rsi
    push rdi
    mov rsi, rcx
    mov rdi, r8
    mov rcx, rdx
    repe cmpsb
    pop rdi
    pop rsi
    jne .no
    mov eax, 1
    ret
.a_null:
    test r8, r8
    jnz .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

rt_s_divz db "runtime error: division by zero on line "
rt_s_divz_len equ $ - rt_s_divz
rt_s_true  db "true"
rt_s_false db "false"
rt_s_null  db "null"

rt_end:

align 4
rt_size dd rt_end - rt_start
rt_offsets:
    dd rt_write - rt_start
    dd rt_write_int - rt_start
    dd rt_write_bool - rt_start
    dd rt_write_str - rt_start
    dd rt_flush - rt_start
    dd rt_div_zero - rt_start
    dd rt_str_eq - rt_start
