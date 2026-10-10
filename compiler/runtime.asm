%include "defs.inc"

section .rodata
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
    push rsi
    push rdi
    mov edx, [r15 + RT_OUT_LEN]
    test edx, edx
    jz .done
    lea rsi, [r15 + RT_BUF]
.loop:
    mov eax, 1
    mov edi, 1
    syscall
    test rax, rax
    jle .reset
    add rsi, rax
    sub rdx, rax
    jnz .loop
.reset:
    mov dword [r15 + RT_OUT_LEN], 0
.done:
    pop rdi
    pop rsi
    ret

rt_div_zero:
    lea rax, [rt_s_divz]
    mov r8d, rt_s_divz_len
rt_fail:
    and rsp, -16
    mov ebx, edx
    mov r14, rax
    mov ebp, r8d
    call rt_flush
    sub rsp, 128
    lea r13, [rsp + 128]
    mov byte [r13 - 1], 10
    lea r12, [r13 - 1]
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
    sub r12, rbp
    mov rdi, r12
    mov rsi, r14
    mov ecx, ebp
    rep movsb
    mov eax, 1
    mov edi, 2
    mov rsi, r12
    mov rdx, r13
    sub rdx, r12
    syscall
    mov eax, 231
    mov edi, 1
    syscall

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

rt_read_line:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 16
    mov r12d, edx
    call rt_flush
    cmp dword [r15 + RT_INLEFT], 65536
    jb .full
    mov r13, [r15 + RT_INPOS]
    xor ebx, ebx
    mov byte [rsp + 8], 0
.next:
    xor eax, eax
    xor edi, edi
    mov rsi, rsp
    mov edx, 1
    syscall
    cmp rax, 1
    jne .eof
    mov byte [rsp + 8], 1
    mov al, [rsp]
    cmp al, 10
    je .done
    cmp ebx, 65535
    jae .next
    mov [r13 + rbx], al
    inc ebx
    jmp .next
.eof:
    cmp byte [rsp + 8], 0
    jne .done
    xor eax, eax
    xor ecx, ecx
    jmp .ret
.done:
    test ebx, ebx
    jz .out
    cmp byte [r13 + rbx - 1], 13
    jne .out
    dec ebx
.out:
    mov rax, r13
    mov ecx, ebx
.ret:
    add rsp, 16
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.full:
    mov edx, r12d
    lea rax, [rt_s_inbig]
    mov r8d, rt_s_inbig_len
    jmp rt_fail

rt_input_str:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    call rt_read_line
    mov [rbx], rax
    mov [rbx + 8], cx
    test rax, rax
    jz .r
    add [r15 + RT_INPOS], rcx
    sub [r15 + RT_INLEFT], ecx
.r:
    add rsp, 32
    pop rbx
    ret

rt_input_int:
    sub rsp, 40
    call rt_read_line
    xor edx, edx
    test rax, rax
    jz .r
    mov r8, rax
    lea r9, [rax + rcx]
.sp:
    cmp r8, r9
    jae .r
    cmp byte [r8], ' '
    je .sp_next
    cmp byte [r8], 9
    jne .sign
.sp_next:
    inc r8
    jmp .sp
.sign:
    xor r10d, r10d
    cmp byte [r8], '-'
    jne .plus
    mov r10d, 1
    inc r8
    jmp .dig
.plus:
    cmp byte [r8], '+'
    jne .dig
    inc r8
.dig:
    cmp r8, r9
    jae .end
    movzx eax, byte [r8]
    sub eax, '0'
    cmp eax, 9
    ja .end
    imul edx, edx, 10
    add edx, eax
    inc r8
    jmp .dig
.end:
    test r10d, r10d
    jz .r
    neg edx
.r:
    mov eax, edx
    add rsp, 40
    ret

rt_s_inbig db "runtime error: too much input on line "
rt_s_inbig_len equ $ - rt_s_inbig
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
    dd rt_input_str - rt_start
    dd rt_input_int - rt_start
