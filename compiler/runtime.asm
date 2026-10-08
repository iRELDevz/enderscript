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
