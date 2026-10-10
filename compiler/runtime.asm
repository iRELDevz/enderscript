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
    call .here
.here:
    pop eax
    add eax, rt_s_divz - .here
    mov ecx, rt_s_divz_len
rt_fail:
    mov esi, edx
    push eax
    push ecx
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
    mov ebp, [esp + 80]
    sub ecx, ebp
    push edi
    push ecx
    mov edi, ecx
    mov esi, [esp + 92]
    mov ecx, ebp
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

rt_read_line:
    push esi
    push edi
    push ebp
    sub esp, 16
    mov [esp + 12], edx
    call rt_flush
    cmp dword [ebx + RT_INLEFT], 65536
    jb .full
    mov edi, [ebx + RT_INPOS]
    xor esi, esi
    xor ebp, ebp
.next:
    mov dword [esp + 4], 0
    push 0
    lea eax, [esp + 8]
    push eax
    push 1
    lea eax, [esp + 12]
    push eax
    push dword [ebx + RT_STDIN]
    call [ebx + RT_READFILE]
    test eax, eax
    jz .eof
    cmp dword [esp + 4], 0
    je .eof
    mov ebp, 1
    mov al, [esp]
    cmp al, 10
    je .done
    cmp esi, 65535
    jae .next
    mov [edi + esi], al
    inc esi
    jmp .next
.eof:
    test ebp, ebp
    jnz .done
    xor eax, eax
    xor ecx, ecx
    jmp .ret
.done:
    test esi, esi
    jz .out
    cmp byte [edi + esi - 1], 13
    jne .out
    dec esi
.out:
    mov eax, edi
    mov ecx, esi
.ret:
    add esp, 16
    pop ebp
    pop edi
    pop esi
    ret
.full:
    mov edx, [esp + 12]
    call .here
.here:
    pop eax
    add eax, rt_s_inbig - .here
    mov ecx, rt_s_inbig_len
    jmp rt_fail

rt_input_str:
    push esi
    mov esi, ecx
    call rt_read_line
    mov [esi], eax
    mov [esi + 8], cx
    test eax, eax
    jz .r
    add [ebx + RT_INPOS], ecx
    sub [ebx + RT_INLEFT], ecx
.r:
    pop esi
    ret

rt_input_int:
    push esi
    push edi
    call rt_read_line
    xor edx, edx
    test eax, eax
    jz .r
    mov esi, eax
    lea edi, [eax + ecx]
.sp:
    cmp esi, edi
    jae .r
    cmp byte [esi], ' '
    je .sp_next
    cmp byte [esi], 9
    jne .sign
.sp_next:
    inc esi
    jmp .sp
.sign:
    xor ecx, ecx
    cmp byte [esi], '-'
    jne .plus
    mov ecx, 1
    inc esi
    jmp .dig
.plus:
    cmp byte [esi], '+'
    jne .dig
    inc esi
.dig:
    cmp esi, edi
    jae .end
    movzx eax, byte [esi]
    sub eax, '0'
    cmp eax, 9
    ja .end
    imul edx, edx, 10
    add edx, eax
    inc esi
    jmp .dig
.end:
    test ecx, ecx
    jz .r
    neg edx
.r:
    mov eax, edx
    pop edi
    pop esi
    ret

rt_s_inbig db "runtime error: too much input on line "
rt_s_inbig_len equ $ - rt_s_inbig
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
    dd rt_input_str - rt_start
    dd rt_input_int - rt_start

rt_consts:
    db "truefalsenull", 0, 0, 0
