%include "defs.inc"

section .rdata
global rt_start, rt_size, rt_offsets

align 16
rt_start:

rt_write:
    cmp rdx, 16
    ja rt_write_slow
    mov eax, [r15 + RT_OUT_LEN]
    cmp eax, RT_BUF_SIZE - 16
    ja rt_write_slow
    lea r8, [r15 + RT_BUF + rax]
    add eax, edx
    mov [r15 + RT_OUT_LEN], eax
    test edx, edx
    jz .r
.b:
    mov al, [rcx]
    mov [r8], al
    inc rcx
    inc r8
    dec edx
    jnz .b
.r:
    ret

rt_write_slow:
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
    xor r8d, r8d
rt_write_int_sfx:
    sub rsp, 72
    lea r9, [rsp + 48]
    test r8d, r8d
    jz .nosfx
    xor eax, eax
.sfx:
    mov r10b, [rdx + rax]
    mov [r9 + rax], r10b
    inc eax
    cmp eax, r8d
    jb .sfx
.nosfx:
    add r8, r9
    mov eax, ecx
    xor r10d, r10d
    test eax, eax
    jns .pos
    neg eax
    mov r10d, 1
.pos:
    mov [rsp], r10d
    mov r11d, 0x51EB851F
    lea rcx, [rt_digits2]
.pair:
    cmp eax, 100
    jb .last
    mov edx, eax
    imul rdx, r11
    shr rdx, 37
    imul r10d, edx, 100
    sub eax, r10d
    movzx eax, word [rcx + rax * 2]
    sub r9, 2
    mov [r9], ax
    mov eax, edx
    jmp .pair
.last:
    cmp eax, 10
    jb .one
    movzx eax, word [rcx + rax * 2]
    sub r9, 2
    mov [r9], ax
    jmp .sign
.one:
    add al, '0'
    dec r9
    mov [r9], al
.sign:
    mov r10d, [rsp]
    test r10d, r10d
    jz .write
    dec r9
    mov byte [r9], '-'
.write:
    mov rdx, r8
    sub rdx, r9
    mov eax, [r15 + RT_OUT_LEN]
    cmp eax, RT_BUF_SIZE - 32
    ja .slow
    movdqu xmm0, [r9]
    movdqu xmm1, [r9 + 16]
    movdqu [r15 + RT_BUF + rax], xmm0
    movdqu [r15 + RT_BUF + rax + 16], xmm1
    add eax, edx
    mov [r15 + RT_OUT_LEN], eax
    add rsp, 72
    ret
.slow:
    mov rcx, r9
    call rt_write_slow
    add rsp, 72
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
    lea rax, [rt_s_divz]
    mov r8d, rt_s_divz_len
rt_fail:
    and rsp, -16
    mov ebx, edx
    mov rsi, rax
    mov r14d, r8d
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
    sub r12, r14
    mov rdi, r12
    mov ecx, r14d
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

rt_index:
    lea rax, [rt_s_index]
    mov r8d, rt_s_index_len
    jmp rt_fail

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
    sub rsp, 48
    mov r12d, edx
    mov eax, [r15 + RT_INLEFT]
    cmp eax, 65536
    jb .full
    mov rdi, [r15 + RT_INPOS]
    lea r13, [rdi + rax]
    xor esi, esi
    xor ebx, ebx
.scan:
    mov ecx, [r13]
    mov edx, [r13 + 4]
    cmp ecx, edx
    jae .refill
    mov ebx, 1
    lea r8, [r13 + 16]
.cl:
    movzx eax, byte [r8 + rcx]
    inc ecx
    cmp al, 10
    je .nl
    cmp esi, 65535
    jae .skip
    mov [rdi + rsi], al
    inc esi
.skip:
    cmp ecx, edx
    jb .cl
    mov [r13], ecx
.refill:
    call rt_flush
    mov rcx, [r15 + RT_STDIN]
    lea rdx, [r13 + 16]
    mov r8d, 65536
    lea r9, [rsp + 40]
    mov dword [rsp + 40], 0
    mov qword [rsp + 32], 0
    call [r15 + RT_READFILE]
    test eax, eax
    jz .eof
    mov eax, [rsp + 40]
    test eax, eax
    jz .eof
    mov dword [r13], 0
    mov [r13 + 4], eax
    jmp .scan
.nl:
    mov [r13], ecx
    jmp .done
.eof:
    test ebx, ebx
    jnz .done
    xor eax, eax
    xor ecx, ecx
    jmp .ret
.done:
    test esi, esi
    jz .out
    cmp byte [rdi + rsi - 1], 13
    jne .out
    dec esi
.out:
    mov rax, rdi
    mov ecx, esi
.ret:
    add rsp, 48
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
    mov eax, [r15 + RT_INLEFT]
    mov r8, [r15 + RT_INPOS]
    add r8, rax
    mov ecx, [r8]
    mov r11d, [r8 + 4]
    mov r9d, edx
    xor edx, edx
    xor r10d, r10d
.fsp:
    cmp ecx, r11d
    jae .slow
    movzx eax, byte [r8 + rcx + 16]
    cmp al, ' '
    je .fspn
    cmp al, 9
    jne .fsign
.fspn:
    inc ecx
    jmp .fsp
.fsign:
    cmp al, '-'
    jne .fplus
    mov r10d, 1
    inc ecx
    jmp .fdig
.fplus:
    cmp al, '+'
    jne .fdig
    inc ecx
.fdig:
    cmp ecx, r11d
    jae .slow
    movzx eax, byte [r8 + rcx + 16]
    sub eax, '0'
    cmp eax, 9
    ja .frest
    lea edx, [rdx + rdx * 4]
    lea edx, [rax + rdx * 2]
    inc ecx
    jmp .fdig
.frest:
    cmp byte [r8 + rcx + 16], 10
    je .fnl
    inc ecx
    cmp ecx, r11d
    jb .frest
    jmp .slow
.fnl:
    inc ecx
    mov [r8], ecx
    mov eax, edx
    neg eax
    test r10d, r10d
    cmovz eax, edx
    ret
.slow:
    sub rsp, 40
    mov edx, r9d
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
rt_s_index db "runtime error: array index out of range on line "
rt_s_index_len equ $ - rt_s_index
rt_s_true  db "true"
rt_s_false db "false"
rt_s_null  db "null"
rt_digits2:
%assign d 0
%rep 100
    db '0' + d / 10, '0' + d % 10
%assign d d + 1
%endrep

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
    dd rt_index - rt_start
    dd rt_write_int_sfx - rt_start
