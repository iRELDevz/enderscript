%include "defs.inc"

section .rodata
global rt_start, rt_size, rt_offsets, rt_consts

align 16
rt_start:

rt_write:
    push esi
    push edi
    push ebp
    mov esi, ecx
    mov ebp, edx
.loop:
    test ebp, ebp
    jz .done
    mov eax, [ebx + RT_OUT_LEN]
    mov ecx, RT_BUF_SIZE
    sub ecx, eax
    jnz .copy
    call rt_flush
    jmp .loop
.copy:
    cmp ecx, ebp
    jbe .count
    mov ecx, ebp
.count:
    lea edi, [ebx + RT_BUF + eax]
    sub ebp, ecx
    add eax, ecx
    mov [ebx + RT_OUT_LEN], eax
    rep movsb
    jmp .loop
.done:
    pop ebp
    pop edi
    pop esi
    ret

rt_write_int:
    push esi
    push edi
    sub esp, 16
    mov eax, ecx
    lea edi, [esp + 16]
    mov esi, edi
    xor ecx, ecx
    test eax, eax
    jns .pos
    neg eax
    mov ecx, 1
.pos:
    push ecx
    mov ecx, 10
.digit:
    xor edx, edx
    div ecx
    add dl, '0'
    dec esi
    mov [esi], dl
    test eax, eax
    jnz .digit
    pop ecx
    test ecx, ecx
    jz .write
    dec esi
    mov byte [esi], '-'
.write:
    mov ecx, esi
    mov edx, edi
    sub edx, esi
    call rt_write
    add esp, 16
    pop edi
    pop esi
    ret

rt_write_bool:
    test cl, cl
    mov ecx, [ebx + RT_CONST]
    jz .false
    mov edx, 4
    jmp rt_write
.false:
    add ecx, RC_FALSE
    mov edx, 5
    jmp rt_write

rt_write_str:
    mov eax, [ecx]
    test eax, eax
    jz .null
    movzx edx, word [ecx + 8]
    mov ecx, eax
    jmp rt_write
.null:
    mov ecx, [ebx + RT_CONST]
    add ecx, RC_NULL
    mov edx, 4
    jmp rt_write

rt_flush:
    mov eax, [ebx + RT_OUT_LEN]
    test eax, eax
    jz .done
    push ebx
    push esi
    push edi
    mov esi, ebx
    lea ecx, [ebx + RT_BUF]
    mov edx, eax
.loop:
    mov eax, SYS_WRITE
    mov ebx, 1
    int 0x80
    test eax, eax
    jle .reset
    add ecx, eax
    sub edx, eax
    jnz .loop
.reset:
    mov ebx, esi
    mov dword [ebx + RT_OUT_LEN], 0
    pop edi
    pop esi
    pop ebx
.done:
    ret

rt_div_zero:
    mov esi, edx
    call rt_flush
    sub esp, 80
    lea edi, [esp + 80]
    mov byte [edi - 1], 10
    lea ecx, [edi - 1]
    mov eax, esi
    mov ebp, 10
.digit:
    xor edx, edx
    div ebp
    add dl, '0'
    dec ecx
    mov [ecx], dl
    test eax, eax
    jnz .digit
    sub ecx, rt_s_divz_len
    push edi
    push ecx
    mov edi, ecx
    call .here
.here:
    pop esi
    add esi, rt_s_divz - .here
    mov ecx, rt_s_divz_len
    rep movsb
    pop ecx
    pop edx
    sub edx, ecx
    mov eax, 4
    mov ebx, 2
    int 0x80
    mov eax, 252
    mov ebx, 1
    int 0x80

rt_str_eq:
    push esi
    push edi
    mov esi, ecx
    mov edi, eax
    mov eax, [esp + 12]
    test esi, esi
    jz .a_null
    test edi, edi
    jz .no
    cmp edx, eax
    jne .no
    mov ecx, edx
    repe cmpsb
    jne .no
    mov eax, 1
    pop edi
    pop esi
    ret 4
.a_null:
    test edi, edi
    jnz .no
    mov eax, 1
    pop edi
    pop esi
    ret 4
.no:
    xor eax, eax
    pop edi
    pop esi
    ret 4

rt_s_divz db "runtime error: division by zero on line "
rt_s_divz_len equ $ - rt_s_divz

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

rt_consts:
    db "truefalsenull", 0, 0, 0
