%include "defs.inc"

section .rdata
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
    movzx edx, word [ecx + 4]
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
    push 0
    lea ecx, [ebx + RT_WRITTEN]
    push ecx
    push eax
    lea ecx, [ebx + RT_BUF]
    push ecx
    push dword [ebx + RT_STDOUT]
    call [ebx + RT_WRITEFILE]
    mov dword [ebx + RT_OUT_LEN], 0
.done:
    ret

rt_div_zero:
    mov esi, edx
    call rt_flush
    sub esp, 80
    lea edi, [esp + 80]
    mov word [edi - 2], 0x0A0D
    lea ecx, [edi - 2]
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
    pop esi
    pop edi
    push -12
    call [ebx + RT_GETSTD]
    push 0
    lea edx, [ebx + RT_WRITTEN]
    push edx
    mov edx, edi
    sub edx, esi
    push edx
    push esi
    push eax
    call [ebx + RT_WRITEFILE]
    push 1
    call [ebx + RT_EXIT]

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

rt_consts:
    db "truefalsenull", 0, 0, 0
