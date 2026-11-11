%include "defs.inc"

section .rdata
global rt_start, rt_size, rt_offsets, rt_consts

align 16
rt_start:

rt_write:
    cmp edx, 16
    ja rt_write_slow
    mov eax, [RT_BASE + RT_OUT_LEN]
    cmp eax, RT_BUF_SIZE - 16
    ja rt_write_slow
    push esi
    lea esi, [RT_BASE + RT_BUF + eax]
    add eax, edx
    mov [RT_BASE + RT_OUT_LEN], eax
    test edx, edx
    jz .r
.b:
    mov al, [ecx]
    mov [esi], al
    inc ecx
    inc esi
    dec edx
    jnz .b
.r:
    pop esi
    ret

rt_write_slow:
    push esi
    push edi
    push ebp
    mov esi, ecx
    mov ebp, edx
.loop:
    test ebp, ebp
    jz .done
    mov eax, [RT_BASE + RT_OUT_LEN]
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
    lea edi, [RT_BASE + RT_BUF + eax]
    sub ebp, ecx
    add eax, ecx
    mov [RT_BASE + RT_OUT_LEN], eax
    rep movsb
    jmp .loop
.done:
    pop ebp
    pop edi
    pop esi
    ret

rt_write_int:
    xor eax, eax
rt_write_int_sfx:
    push esi
    push edi
    push ebx
    push ebp
    mov esi, edx
    mov ebx, eax
    mov edi, [RT_BASE + RT_OUT_LEN]
    cmp edi, RT_BUF_SIZE - 32
    jbe .room
    push ecx
    call rt_flush
    pop ecx
    xor edi, edi
.room:
    add edi, RT_BASE + RT_BUF
    test ecx, ecx
    jns .pos
    mov byte [edi], '-'
    inc edi
    neg ecx
.pos:
    cmp ecx, 100000
    jae .big
    mov eax, 1
    cmp ecx, 10
    jb .n
    inc eax
    cmp ecx, 100
    jb .n
    inc eax
    cmp ecx, 1000
    jb .n
    inc eax
    cmp ecx, 10000
    jb .n
    inc eax
    jmp .n
.big:
    mov eax, 6
    cmp ecx, 1000000
    jb .n
    inc eax
    cmp ecx, 10000000
    jb .n
    inc eax
    cmp ecx, 100000000
    jb .n
    inc eax
    cmp ecx, 1000000000
    jb .n
    inc eax
.n:
    lea ebp, [edi + eax]
    lea edx, [ebp + ebx - (RT_BASE + RT_BUF)]
    mov [RT_BASE + RT_OUT_LEN], edx
    xor edx, edx
.sfx:
    cmp edx, ebx
    jae .sfx_done
    mov al, [esi + edx]
    mov [ebp + edx], al
    inc edx
    jmp .sfx
.sfx_done:
    mov esi, [RT_BASE + RT_CONST]
.pair:
    cmp ecx, 100
    jb .last
    mov eax, ecx
    mov edx, 0x51EB851F
    mul edx
    shr edx, 5
    imul eax, edx, 100
    sub ecx, eax
    movzx eax, word [esi + ecx * 2 + RC_DIG]
    sub ebp, 2
    mov [ebp], ax
    mov ecx, edx
    jmp .pair
.last:
    cmp ecx, 10
    jb .one
    movzx eax, word [esi + ecx * 2 + RC_DIG]
    mov [ebp - 2], ax
    jmp .done
.one:
    add cl, '0'
    mov [ebp - 1], cl
.done:
    pop ebp
    pop ebx
    pop edi
    pop esi
    ret

rt_write_bool:
    test cl, cl
    mov ecx, [RT_BASE + RT_CONST]
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
    mov ecx, [RT_BASE + RT_CONST]
    add ecx, RC_NULL
    mov edx, 4
    jmp rt_write

rt_flush:
    mov eax, [RT_BASE + RT_OUT_LEN]
    test eax, eax
    jz .done
    push 0
    lea ecx, [RT_BASE + RT_WRITTEN]
    push ecx
    push eax
    lea ecx, [RT_BASE + RT_BUF]
    push ecx
    push dword [RT_BASE + RT_STDOUT]
    call [RT_BASE + RT_WRITEFILE]
    mov dword [RT_BASE + RT_OUT_LEN], 0
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
    call [RT_BASE + RT_GETSTD]
    push 0
    lea edx, [RT_BASE + RT_WRITTEN]
    push edx
    mov edx, edi
    sub edx, esi
    push edx
    push esi
    push eax
    call [RT_BASE + RT_WRITEFILE]
    push 1
    call [RT_BASE + RT_EXIT]

rt_index:
    call .here
.here:
    pop eax
    add eax, rt_s_index - .here
    mov ecx, rt_s_index_len
    jmp rt_fail

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
    mov eax, [RT_BASE + RT_INLEFT]
    cmp eax, 65536
    jae .room
    push 4
    push 0x3000
    push IN_SIZE
    push 0
    call [RT_BASE + RT_VALLOC]
    test eax, eax
    jz .full
    mov [RT_BASE + RT_INPOS], eax
    mov dword [RT_BASE + RT_INLEFT], IN_SIZE
.room:
    mov edi, [RT_BASE + RT_INPOS]
    mov ebp, [RT_BASE + RT_RDBUF]
    xor esi, esi
    mov dword [esp + 8], 0
.scan:
    mov ecx, [ebp]
    mov edx, [ebp + 4]
    cmp ecx, edx
    jae .refill
    mov dword [esp + 8], 1
.cl:
    movzx eax, byte [ebp + ecx + 16]
    inc ecx
    cmp al, 10
    je .nl
    cmp esi, 65535
    jae .skip
    mov [edi + esi], al
    inc esi
.skip:
    cmp ecx, edx
    jb .cl
    mov [ebp], ecx
.refill:
    call rt_flush
    mov dword [esp + 4], 0
    push 0
    lea eax, [esp + 8]
    push eax
    push RD_SIZE
    lea eax, [ebp + 16]
    push eax
    push dword [RT_BASE + RT_STDIN]
    call [RT_BASE + RT_READFILE]
    test eax, eax
    jz .eof
    mov eax, [esp + 4]
    test eax, eax
    jz .eof
    mov dword [ebp], 0
    mov [ebp + 4], eax
    jmp .scan
.nl:
    mov [ebp], ecx
    jmp .done
.eof:
    cmp dword [esp + 8], 0
    jne .done
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
    add [RT_BASE + RT_INPOS], ecx
    sub [RT_BASE + RT_INLEFT], ecx
.r:
    pop esi
    ret

rt_input_int:
    push esi
    push edi
    push ebp
    push edx
    mov esi, [RT_BASE + RT_RDBUF]
    mov ecx, [esi]
    mov edi, [esi + 4]
    xor edx, edx
    xor ebp, ebp
.fsp:
    cmp ecx, edi
    jae .slow
    movzx eax, byte [esi + ecx + 16]
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
    mov ebp, 1
    inc ecx
    jmp .fdig
.fplus:
    cmp al, '+'
    jne .fdig
    inc ecx
.fdig:
    cmp ecx, edi
    jae .slow
    movzx eax, byte [esi + ecx + 16]
    sub eax, '0'
    cmp eax, 9
    ja .frest
    lea edx, [edx + edx * 4]
    lea edx, [eax + edx * 2]
    inc ecx
    jmp .fdig
.frest:
    cmp byte [esi + ecx + 16], 10
    je .fnl
    inc ecx
    cmp ecx, edi
    jb .frest
    jmp .slow
.fnl:
    mov eax, ecx
    sub eax, [esi]
    cmp eax, 65535
    ja .slow
    inc ecx
    mov [esi], ecx
    mov eax, edx
    neg eax
    test ebp, ebp
    cmovz eax, edx
    add esp, 4
    pop ebp
    pop edi
    pop esi
    ret
.slow:
    pop edx
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
    pop ebp
    pop edi
    pop esi
    ret

rt_s_inbig db "runtime error: too much input on line "
rt_s_inbig_len equ $ - rt_s_inbig
rt_s_divz db "runtime error: division by zero on line "
rt_s_divz_len equ $ - rt_s_divz
rt_s_index db "runtime error: array index out of range on line "
rt_s_index_len equ $ - rt_s_index


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

rt_consts:
    db "truefalsenull", 0, 0, 0
    db "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899"
