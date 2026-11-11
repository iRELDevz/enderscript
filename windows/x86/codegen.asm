%include "defs.inc"
%include "state.inc"

extern rt_start, rt_size, rt_offsets
extern x86_text_base, x86_bytes, x86_imm32, x86_imm16, x86_imm8, x86_op_abs
extern x86_call_rel, x86_text_offset
extern elem_size
extern pe_layout, pe_finish
extern pe_R, pe_D, pe_I, pe_T, pe_entry, pe_text_file, g_image

%define IMAGE_BASE       0x400000
%define RT_FN_WRITE      0
%define RT_FN_WRITE_INT  4
%define RT_FN_WRITE_BOOL 8
%define RT_FN_WRITE_STR  12
%define RT_FN_FLUSH      16
%define RT_FN_DIV_ZERO   20
%define RT_FN_STR_EQ     24
%define RT_FN_INPUT_STR  28
%define RT_FN_INPUT_INT  32
%define RT_FN_INDEX      36
%define RT_FN_WRITE_INT_SFX 40

%define IAT_GETSTDHANDLE 60
%define IAT_WRITEFILE    64
%define IAT_EXITPROCESS  68
%define IAT_READFILE     72

%define R_EAX 0
%define R_ECX 1
%define R_EDX 2
%define R_ESI 6
%define R_EDI 7
%define NOREG 0xFF

%define B_END    0
%define B_KIND   4
%define B_TOP    8
%define B_REG    12
%define B_SLOT   16
%define B_DYN    20
%define B_LIMIT  24
%define B_INIT   28
%define B_ALIAS  32
%define B_IFIDX  36
%define B_LABEL  40
%define B_TAKE   44
%define B_GIDX   48
%define B_GLD    52
%define B_FINAL  56
%define B_SIZE   64

section .bss
alignb 4
cg_end    resd 1
cg_cur    resd 1
cg_vars   resd 1
cg_pool   resd 1
cg_dst    resd 1
cg_type   resd 1
cg_piece  resd 1
cg_plast  resd 1
cg_line   resd 1
cg_target resd 1
cg_depth  resd 1
cg_ldepth resd 1
cg_bdepth resd 1
cg_patch  resd 1
cg_npatch resd 1
cg_lp     resd 1
cg_lpl    resd 1
cg_nlp    resd 1
cg_label  resd 1
cg_vreg   resd 1
cg_blfirst resd 1
cg_blacc  resd 1
cg_blk    resd 1
cg_blvar  resd 1
cg_bldata resd 1
cg_bland  resd 1
cg_tmp    resd 4
mg_tmp    resd 4
mg_m      resd 1
mg_s      resd 1
cg_inuse  resd 1
cg_inoff  resd 1
ix_c      resd 1
ad_size   resd 1
ad_type   resd 1
cg_prom   resd 4
cg_nprom  resd 1
cg_vcount resd 1
cg_touched resd 1
cg_ntouch resd 1
cg_md     resd 1
cg_tsp    resd 1
cg_tcap   resd 1
cg_dreg   resd 1
cg_blreg  resd 1
ts_n      resd 1
ts_k      resd 1
ts_arr    resd 1
ts_alen   resd 1
ts_ix     resd 1
ts_line   resd 1
ts_p      resd 1
ts_qn     resd 1
ts_st     resd 1
ts_jle    resd 1
cg_kv     resd 1
cg_kvok   resd 1
cg_vhi    resd 1
rg_state  resd 1
rg_list   resd 1
rg_n      resd 1
rg_lo     resd 1
rg_chg    resd 1
cg_dleft  resd 1
cg_nonneg resd 1
af_x      resd 1
af_c      resd 1
af_lv     resd 1
af_a      resd 1
af_b      resd 1
af_k      resd 1
af_A      resd 1
af_B      resd 1
af_sign   resd 1
af_div    resd 1
af_inv    resd 1
af_c1     resd 1
af_t      resd 1
cg_tstack resd MAX_BLOCKS + 1
cg_bstack resb B_SIZE * (MAX_NEST + 1)

section .text

%macro OPA 3
    mov eax, %1
    mov ecx, %2
    mov edx, %3
    call x86_op_abs
%endmacro

%macro BYTES 2
    mov eax, %1
    mov ecx, %2
    call x86_bytes
%endmacro

%macro CALL_RT 1
    mov ecx, [rt_offsets + %1]
    call x86_call_rel
%endmacro

FUNC codegen
    mov dword [cg_inuse], 0
    mov eax, [g_stmts]
    mov ecx, [g_nstmt]
    shl ecx, 5
    add ecx, eax
.in_scan:
    cmp eax, ecx
    jae .in_done
    cmp word [eax + S_KIND], SK_INPUT
    je .in_found
    add eax, S_SIZE
    jmp .in_scan
.in_found:
    mov dword [cg_inuse], 1
    mov eax, [g_vars_size]
    add eax, 15
    and eax, -16
    mov [cg_inoff], eax
    add eax, IN_SIZE + 16 + RD_SIZE
    mov [g_vars_size], eax
.in_done:
    call pe_layout
    mov edi, [g_image]
    add edi, [pe_text_file]
    mov [x86_text_base], edi
    mov esi, rt_start
    mov ecx, [rt_size]
    rep movsb
    push edi
    mov ecx, [g_nparts]
    add ecx, 16
    shl ecx, 2
    call mem_alloc
    mov [cg_patch], eax
    mov ecx, [g_nparts]
    add ecx, [g_nstmt]
    add ecx, 16
    shl ecx, 3
    call mem_alloc
    mov [cg_lp], eax
    mov ecx, [g_nparts]
    add ecx, [g_nstmt]
    add ecx, 16
    lea eax, [eax + ecx * 4]
    mov [cg_lpl], eax
    mov ecx, [g_nvars]
    add ecx, 16
    call mem_alloc
    mov [cg_vreg], eax
    mov ecx, [g_nvars]
    add ecx, 16
    shl ecx, 2
    call mem_alloc
    mov [cg_vcount], eax
    mov ecx, [g_nvars]
    add ecx, 16
    shl ecx, 2
    call mem_alloc
    mov [cg_touched], eax
    mov ecx, [g_nvars]
    add ecx, 16
    shl ecx, 4
    call mem_alloc
    mov [cg_kv], eax
    mov ecx, [g_nvars]
    add ecx, 16
    lea edx, [eax + ecx * 4]
    mov [cg_vhi], edx
    lea edx, [edx + ecx * 4]
    mov [rg_state], edx
    lea edx, [edx + ecx * 4]
    mov [rg_list], edx
    push ecx
    call mem_alloc
    mov [cg_kvok], eax
    pop ecx
    mov edx, [cg_vhi]
.vhi_init:
    mov dword [edx + ecx * 4 - 4], -1
    dec ecx
    jnz .vhi_init
    mov dword [rg_n], 0
    mov dword [cg_dleft], -1
    pop edi
    mov dword [cg_nprom], 0
    mov dword [cg_tcap], 3
    mov dword [cg_npatch], 0
    mov dword [cg_nlp], 0
    mov dword [cg_label], 1
    mov dword [cg_bdepth], 0
    mov dword [cg_ldepth], 0
    mov dword [cg_depth], 0
.pad:
    call x86_text_offset
    test eax, 15
    jz .entry
    mov byte [edi], 0xCC
    inc edi
    jmp .pad
.entry:
    mov [pe_entry], eax

    mov eax, [pe_D]
    add eax, IMAGE_BASE + RT_VARS
    mov [cg_vars], eax
    mov eax, [pe_R]
    add eax, IMAGE_BASE + RC_SIZE
    mov [cg_pool], eax

    BYTES 0xF56A, 2
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_GETSTDHANDLE
    OPA 0x15FF, 2, edx
    OPA 0xA3, 1, RT_BASE + RT_STDOUT
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_WRITEFILE
    OPA 0xA1, 1, edx
    OPA 0xA3, 1, RT_BASE + RT_WRITEFILE
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_GETSTDHANDLE
    OPA 0xA1, 1, edx
    OPA 0xA3, 1, RT_BASE + RT_GETSTD
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_EXITPROCESS
    OPA 0xA1, 1, edx
    OPA 0xA3, 1, RT_BASE + RT_EXIT
    OPA 0x05C7, 2, RT_BASE + RT_CONST
    mov edx, [pe_R]
    add edx, IMAGE_BASE
    call x86_imm32
    cmp dword [cg_inuse], 0
    je .no_input
    BYTES 0xF66A, 2
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_GETSTDHANDLE
    OPA 0x15FF, 2, edx
    OPA 0xA3, 1, RT_BASE + RT_STDIN
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_READFILE
    OPA 0xA1, 1, edx
    OPA 0xA3, 1, RT_BASE + RT_READFILE
    OPA 0x05C7, 2, RT_BASE + RT_INPOS
    mov edx, [cg_vars]
    add edx, [cg_inoff]
    call x86_imm32
    OPA 0x05C7, 2, RT_BASE + RT_INLEFT
    mov edx, IN_SIZE
    call x86_imm32
.no_input:

    mov esi, [g_stmts]
    mov eax, [g_nstmt]
    shl eax, 5
    add eax, esi
    mov [cg_end], eax
.stmt:
    mov [cg_cur], esi
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    call close_blocks
    mov esi, [cg_cur]
    cmp esi, [cg_end]
    jae .epilogue
    mov eax, [esi + S_TOK]
    shl eax, 4
    add eax, [g_tokens]
    mov eax, [eax + T_LINE]
    mov [cg_line], eax
    movzx eax, word [esi + S_KIND]
    cmp eax, SK_OUT
    je .out
    cmp eax, SK_IF
    je .if
    cmp eax, SK_FOR
    je .loop
    cmp eax, SK_LOOPS
    je .loop
    cmp eax, SK_ELSE
    je .else
    cmp eax, SK_BREAK
    je .jump
    cmp eax, SK_CONTINUE
    je .jump
    cmp eax, SK_GROUP
    je .group
    cmp eax, SK_INPUT
    je .input
    cmp eax, SK_ADECL
    je .adecl
    cmp eax, SK_ASET
    je .aset
    call emit_store
    jmp .next
.adecl:
    call emit_adecl
    jmp .next
.aset:
    call emit_aset
    jmp .next
.input:
    call sync_out
    call emit_out_body
    call emit_input
    jmp .next
.jump:
    call emit_jump
    jmp .next
.group:
    call group_open
    jmp .next
.out:
    call sync_out
    call emit_out_body
    jmp .next
.else:
    call kv_invalidate
    jmp .next
.if:
    cmp dword [cg_bdepth], 0
    jne .if_kv
    call kv_invalidate
.if_kv:
    call try_branchless
    test eax, eax
    jz .if_branch
    add dword [cg_cur], S_SIZE
    jmp .next
.if_branch:
    mov eax, [cg_bdepth]
    imul eax, eax, B_SIZE
    lea ecx, [cg_bstack + eax]
    mov edx, [esi + S_PIECES]
    mov [ecx + B_END], edx
    mov dword [ecx + B_KIND], BK_IF
    mov edx, [cg_npatch]
    mov [ecx + B_TOP], edx
    mov edx, esi
    sub edx, [g_stmts]
    shr edx, 5
    mov [ecx + B_IFIDX], edx
    inc dword [cg_bdepth]
    mov eax, [esi + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    xor edx, edx
    xor eax, eax
    call emit_cond
    jmp .next
.loop:
    call try_fill
    test eax, eax
    jnz .next
    call try_mark
    test eax, eax
    jnz .next
    call try_count
    test eax, eax
    jnz .next
    call try_affine
    test eax, eax
    jnz .next
    cmp dword [cg_ldepth], 0
    jne .loop_head
    call range_setup
    call promote_region
.loop_head:
    cmp dword [cg_bdepth], 0
    jne .loop_kv
    call kv_invalidate
.loop_kv:
    call emit_loop_head
.next:
    mov esi, [cg_cur]
    add esi, S_SIZE
    jmp .stmt

.epilogue:
    CALL_RT RT_FN_FLUSH
    BYTES 0x006A, 2
    mov edx, [pe_I]
    add edx, IMAGE_BASE + IAT_EXITPROCESS
    OPA 0x15FF, 2, edx
    call x86_text_offset
    mov ecx, eax
    call pe_finish
    ENDF

node_addr:
    mov eax, ecx
    shl eax, 4
    add eax, [g_parts]
    ret

var_abs_idx:
    shl eax, 5
    add eax, [g_vars]
    mov eax, [eax + VR_OFF]
    add eax, [cg_vars]
    ret

var_abs:
    mov eax, [eax + V_DATA]
    jmp var_abs_idx

var_reg:
    mov eax, [cg_vreg]
    movzx eax, byte [eax + ecx]
    and eax, 0x1F
    dec eax
    ret

stmt_ptr:
    mov eax, ecx
    shl eax, 5
    add eax, [g_stmts]
    ret

stmt_root:
    mov eax, [eax + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    ret

e_rr:
    push edx
    push ecx
    call .op
    pop ecx
    pop edx
    shl ecx, 3
    or ecx, edx
    or ecx, 0xC0
    mov [edi], cl
    inc edi
    ret
.op:
    mov [edi], al
    inc edi
    ret

e_rr2:
    mov [edi], ax
    add edi, 2
    shl ecx, 3
    or ecx, edx
    or ecx, 0xC0
    mov [edi], cl
    inc edi
    ret

e_mr:
    mov [edi], al
    inc edi
    shl ecx, 3
    or ecx, 5
    mov [edi], cl
    mov [edi + 1], edx
    add edi, 5
    ret

temp_limit:
    mov eax, [cg_ldepth]
    cmp eax, 2
    jbe .ok
    mov eax, 2
.ok:
    neg eax
    add eax, 3
    cmp eax, [cg_tcap]
    jbe .r
    mov eax, [cg_tcap]
.r:
    ret

temp_reg:
    mov eax, [cg_depth]
    movzx eax, byte [temp_codes + eax]
    ret

emit_store:
    push esi
    push ebx
    mov esi, [cg_cur]
    call kv_record
    mov eax, [esi + S_VAR]
    call var_abs_idx
    mov [cg_dst], eax
    movzx eax, word [esi + S_MODE]
    mov [cg_type], eax
    mov dword [cg_dreg], -1
    cmp eax, TY_INT
    jne .dreg_set
    mov ecx, [esi + S_VAR]
    call prom_reg
    mov [cg_dreg], eax
.dreg_set:
    cmp dword [esi + S_NPARTS], 0
    je .store_default
    mov eax, [esi + S_PARTS]
    mov ebx, [g_roots]
    mov ebx, [ebx + eax * 4]
    mov [cg_target], ebx
    shl ebx, 4
    add ebx, [g_parts]
    movzx eax, byte [ebx + V_KIND]
    cmp eax, VK_EXPR
    je .store_expr
    cmp eax, VK_ELEM
    je .store_elem
    cmp eax, VK_VAR
    je .copy_var
    cmp eax, VK_NULL
    je .store_default
    cmp eax, VK_STR
    je .store_str
    cmp dword [cg_type], TY_BOOL
    je .store_bool
    mov edx, [ebx + V_DATA]
    call store_imm
    jmp .done
.store_expr:
    mov eax, [esi + S_VAR]
    call try_update_in_place
    test eax, eax
    jnz .done
    mov ecx, [cg_target]
    call emit_expr
    call store_eax
    jmp .done
.store_elem:
    mov ecx, [cg_target]
    mov edx, [cg_type]
    call load_value
    cmp dword [cg_type], TY_INT
    jne .se_not_int
    call store_eax
    jmp .done
.se_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .se_str
    OPA 0xA2, 1, [cg_dst]
    jmp .done
.se_str:
    push edx
    OPA 0xA3, 1, [cg_dst]
    pop edx
    push edx
    BYTES 0x158966, 3
    mov edx, [cg_dst]
    add edx, 8
    call x86_imm32
    pop edx
    jmp .done
.store_bool:
    OPA 0x05C6, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    call x86_imm8
    jmp .done
.store_str:
    OPA 0x05C7, 2, [cg_dst]
    mov edx, [ebx + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
    mov edx, [cg_dst]
    add edx, 8
    OPA 0x05C766, 3, edx
    mov edx, [ebx + V_DATA_HI]
    call x86_imm16
    jmp .done
.store_default:
    cmp dword [cg_type], TY_INT
    jne .def_not_int
    xor edx, edx
    call store_imm
    jmp .done
.def_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .def_str
    OPA 0x05C6, 2, [cg_dst]
    xor edx, edx
    call x86_imm8
    jmp .done
.def_str:
    OPA 0x05C7, 2, [cg_dst]
    xor edx, edx
    call x86_imm32
    mov edx, [cg_dst]
    add edx, 8
    OPA 0x05C766, 3, edx
    xor edx, edx
    call x86_imm16
    jmp .done
.copy_var:
    mov ecx, [ebx + V_DATA]
    mov eax, ecx
    call var_abs_idx
    mov ebx, eax
    cmp dword [cg_type], TY_INT
    jne .copy_not_int
    call var_reg
    test eax, eax
    js .copy_mem
    mov ecx, eax
    mov eax, 0x89
    xor edx, edx
    call e_rr
    jmp .copy_store
.copy_mem:
    OPA 0xA1, 1, ebx
.copy_store:
    call store_eax
    jmp .done
.copy_not_int:
    cmp dword [cg_type], TY_BOOL
    jne .copy_str
    OPA 0xA0, 1, ebx
    OPA 0xA2, 1, [cg_dst]
    jmp .done
.copy_str:
    OPA 0xA1, 1, ebx
    OPA 0xA3, 1, [cg_dst]
    lea edx, [ebx + 8]
    OPA 0xA166, 2, edx
    mov edx, [cg_dst]
    add edx, 8
    OPA 0xA366, 2, edx
.done:
    pop ebx
    pop esi
    ret

prom_reg:
    mov eax, [cg_vreg]
    movzx eax, byte [eax + ecx]
    test al, 0x80
    jz .none
    and eax, 0x1F
    dec eax
    ret
.none:
    mov eax, -1
    ret

store_eax:
    mov edx, [cg_dreg]
    test edx, edx
    js .mem
    mov ecx, R_EAX
    mov eax, 0x89
    jmp e_rr
.mem:
    OPA 0xA3, 1, [cg_dst]
    ret

store_imm:
    mov ecx, [cg_dreg]
    test ecx, ecx
    js .mem
    test edx, edx
    jz .zero
    push edx
    mov eax, 0xB8
    call emit_reg1
    pop edx
    jmp x86_imm32
.zero:
    mov edx, ecx
    mov eax, 0x31
    jmp e_rr
.mem:
    push edx
    OPA 0x05C7, 2, [cg_dst]
    pop edx
    jmp x86_imm32

sync_out:
    cmp dword [cg_nprom], 0
    je .r
    mov edx, [cg_cur]
    mov ecx, [edx + S_NPIECES]
    mov eax, [edx + S_PIECES]
    shl eax, 4
    add eax, [g_pieces]
.scan:
    test ecx, ecx
    jz .r
    cmp dword [eax + P_KIND], PK_INT
    je flush_prom
    add eax, 16
    dec ecx
    jmp .scan
.r:
    ret

flush_prom:
    push ebx
    xor ebx, ebx
.l:
    cmp ebx, [cg_nprom]
    jae .d
    mov ecx, [cg_prom + ebx * 4]
    call var_reg
    push eax
    mov eax, [cg_prom + ebx * 4]
    call var_abs_idx
    mov edx, eax
    pop ecx
    mov eax, 0x89
    call e_mr
    inc ebx
    jmp .l
.d:
    pop ebx
    ret

unpromote:
    call range_clear
    cmp dword [cg_nprom], 0
    je .r
    call flush_prom
.clr:
    mov eax, [cg_nprom]
    test eax, eax
    jz .r
    dec eax
    mov [cg_nprom], eax
    mov ecx, [cg_prom + eax * 4]
    mov edx, [cg_vreg]
    mov byte [edx + ecx], 0
    jmp .clr
.r:
    mov dword [cg_tcap], 3
    ret

touch:
    mov eax, [cg_vcount]
    lea eax, [eax + ecx * 4]
    test dword [eax], 0x40000000
    jnz .r
    or dword [eax], 0x40000000
    push edx
    push eax
    mov edx, [cg_ntouch]
    mov eax, [cg_touched]
    mov [eax + edx * 4], ecx
    inc dword [cg_ntouch]
    pop eax
    pop edx
.r:
    ret

pin_take:
    mov eax, [eax + S_MODETOK]
    test eax, eax
    jz pin_group.r
    dec eax
    shl eax, 5
    add eax, [g_stmts]
pin_group:
    test word [eax + S_MODE], 1
    jz .r
    mov ecx, [eax + S_VAR]
    call touch
    or dword [eax], 0x80000000
.r:
    ret

promote_region:
    push esi
    push ebx
    push ebp
    mov ebx, [cg_cur]
    mov eax, ebx
    sub eax, [g_stmts]
    shr eax, 5
    lea esi, [eax + 1]
    mov ebp, [ebx + S_PIECES]
    mov dword [cg_ntouch], 0
    mov dword [cg_md], 1
    mov dword [cg_tsp], 0
    mov eax, ebx
    call pin_take
    cmp word [ebx + S_KIND], SK_FOR
    jne .scan
    mov ecx, [ebx + S_VAR]
    call touch
    or dword [eax], 0x80000000
.scan:
    cmp esi, ebp
    jae .scanned
.pop:
    mov eax, [cg_tsp]
    test eax, eax
    jz .popped
    cmp [cg_tstack + eax * 4 - 4], esi
    ja .popped
    dec dword [cg_tsp]
    jmp .pop
.popped:
    mov ebx, esi
    shl ebx, 5
    add ebx, [g_stmts]
    movzx eax, word [ebx + S_KIND]
    cmp eax, SK_FOR
    je .loop_stmt
    cmp eax, SK_LOOPS
    je .loop_stmt
    cmp eax, SK_GROUP
    je .group_stmt
    cmp eax, SK_DECL
    je .assign
    cmp eax, SK_ASSIGN
    jne .next
.assign:
    cmp word [ebx + S_MODE], TY_INT
    jne .next
    mov ecx, [ebx + S_VAR]
    call touch
    mov ecx, [cg_tsp]
    imul ecx, ecx, 3
    cmp ecx, 24
    jbe .w
    mov ecx, 24
.w:
    mov edx, 1
    shl edx, cl
    mov ecx, [eax]
    and ecx, 0x3FFFFFFF
    add ecx, edx
    cmp ecx, 0x3FFFFFFF
    jbe .sat
    mov ecx, 0x3FFFFFFF
.sat:
    and dword [eax], 0xC0000000
    or [eax], ecx
    jmp .next
.group_stmt:
    mov eax, ebx
    call pin_group
    jmp .next
.loop_stmt:
    mov eax, ebx
    call pin_take
    cmp word [ebx + S_KIND], SK_FOR
    jne .push
    mov ecx, [ebx + S_VAR]
    call touch
    or dword [eax], 0x80000000
.push:
    mov eax, [cg_tsp]
    cmp eax, MAX_BLOCKS
    jae .next
    mov ecx, [ebx + S_PIECES]
    mov [cg_tstack + eax * 4], ecx
    inc eax
    mov [cg_tsp], eax
    inc eax
    cmp eax, [cg_md]
    jbe .next
    mov [cg_md], eax
.next:
    inc esi
    jmp .scan
.scanned:
    xor ebp, ebp
.pick:
    cmp ebp, 1
    jb .go
    ja .picked
    cmp dword [cg_md], 1
    jne .picked
.go:
    xor ecx, ecx
    mov edx, -1
    xor ebx, ebx
.find:
    cmp ecx, [cg_ntouch]
    jae .found
    mov eax, [cg_touched]
    mov eax, [eax + ecx * 4]
    mov esi, [cg_vcount]
    mov esi, [esi + eax * 4]
    test esi, 0x80000000
    jnz .fnext
    and esi, 0x3FFFFFFF
    cmp esi, ebx
    jbe .fnext
    mov ebx, esi
    mov edx, ecx
.fnext:
    inc ecx
    jmp .find
.found:
    cmp edx, -1
    je .picked
    mov eax, [cg_touched]
    mov ecx, [eax + edx * 4]
    mov eax, [cg_vcount]
    or dword [eax + ecx * 4], 0x80000000
    movzx eax, byte [prom_regs + ebp]
    mov edx, [cg_vreg]
    lea ebx, [eax + 0x81]
    mov [edx + ecx], bl
    mov edx, [cg_nprom]
    mov [cg_prom + edx * 4], ecx
    inc dword [cg_nprom]
    cmp eax, R_EDI
    jne .load
    mov dword [cg_tcap], 1
.load:
    push eax
    mov eax, ecx
    call var_abs_idx
    mov edx, eax
    pop ecx
    mov eax, 0x8B
    call e_mr
    inc ebp
    jmp .pick
.picked:
    xor ecx, ecx
.zero:
    cmp ecx, [cg_ntouch]
    jae .r
    mov eax, [cg_touched]
    mov eax, [eax + ecx * 4]
    mov edx, [cg_vcount]
    mov dword [edx + eax * 4], 0
    inc ecx
    jmp .zero
.r:
    pop ebp
    pop ebx
    pop esi
    ret

emit_out_body:
    push esi
    push ebx
    mov esi, [cg_cur]
    mov eax, [esi + S_PIECES]
    mov [cg_piece], eax
    add eax, [esi + S_NPIECES]
    mov [cg_plast], eax
.piece:
    mov eax, [cg_piece]
    cmp eax, [cg_plast]
    jae .done
    inc dword [cg_piece]
    shl eax, 4
    add eax, [g_pieces]
    mov ebx, eax
    mov eax, [ebx + P_KIND]
    cmp eax, PK_TEXT
    jne .piece_var
    cmp dword [ebx + P_B], 0
    je .piece
    BYTES 0xB9, 1
    mov edx, [ebx + P_A]
    add edx, [cg_pool]
    call x86_imm32
    BYTES 0xBA, 1
    mov edx, [ebx + P_B]
    call x86_imm32
    CALL_RT RT_FN_WRITE
    jmp .piece
.piece_var:
    cmp eax, PK_ELEM
    je .piece_elem
    cmp eax, PK_EXPR
    jne .piece_plain
    mov ecx, [ebx + P_A]
    call emit_expr
    BYTES 0xC189, 2
    call .wint
    jmp .piece
.wint:
    mov eax, [cg_piece]
    cmp eax, [cg_plast]
    jae .wint_plain
    shl eax, 4
    add eax, [g_pieces]
    cmp dword [eax + P_KIND], PK_TEXT
    jne .wint_plain
    mov edx, [eax + P_B]
    test edx, edx
    jz .wint_plain
    cmp edx, 16
    ja .wint_plain
    inc dword [cg_piece]
    push edx
    mov edx, [eax + P_A]
    add edx, [cg_pool]
    push edx
    BYTES 0xBA, 1
    pop edx
    call x86_imm32
    BYTES 0xB8, 1
    pop edx
    call x86_imm32
    CALL_RT RT_FN_WRITE_INT_SFX
    ret
.wint_plain:
    CALL_RT RT_FN_WRITE_INT
    ret
.piece_plain:
    mov edx, [ebx + P_A]
    add edx, [cg_vars]
    cmp eax, PK_INT
    jne .piece_not_int
    OPA 0x0D8B, 2, edx
    call .wint
    jmp .piece
.piece_not_int:
    cmp eax, PK_BOOL
    jne .piece_str
    OPA 0x0DB60F, 3, edx
    CALL_RT RT_FN_WRITE_BOOL
    jmp .piece
.piece_str:
    BYTES 0xB9, 1
    call x86_imm32
    CALL_RT RT_FN_WRITE_STR
    jmp .piece
.piece_elem:
    mov ecx, [ebx + P_A]
    call node_addr
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    mov eax, [ebx + P_B]
    cmp eax, TY_INT
    jne .pc_bool
    BYTES 0x098B, 2
    call .wint
    jmp .piece
.pc_bool:
    cmp eax, TY_BOOL
    jne .pc_str
    BYTES 0x09B60F, 3
    CALL_RT RT_FN_WRITE_BOOL
    jmp .piece
.pc_str:
    CALL_RT RT_FN_WRITE_STR
    jmp .piece
.done:
    pop ebx
    pop esi
    ret

try_update_in_place:
    push esi
    push ebx
    mov ebx, eax
    mov ecx, [cg_target]
    call node_addr
    mov esi, eax
    movzx eax, byte [esi + V_NEG]
    push eax
    mov ecx, [esi + V_DATA]
    mov edx, [esi + V_DATA + 4]
    cmp eax, OP_SUB
    je .check
    cmp eax, OP_ADD
    jne .no
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    je .swap
    cmp byte [eax + V_KIND], VK_ELEM
    jne .check
.swap:
    xchg ecx, edx
.check:
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    cmp [eax + V_DATA], ebx
    jne .no
    mov ecx, edx
    call node_addr
    cmp byte [eax + V_KIND], VK_ELEM
    je .elem
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov esi, [eax + V_DATA]
    pop eax
    push eax
    cmp eax, OP_SUB
    jne .add
    neg esi
.add:
    mov ecx, [cg_dreg]
    test ecx, ecx
    jns .add_reg
    cmp esi, 1
    je .inc
    cmp esi, -1
    je .dec
    OPA 0x0581, 2, [cg_dst]
    mov edx, esi
    call x86_imm32
    jmp .yes
.inc:
    OPA 0x05FF, 2, [cg_dst]
    jmp .yes
.dec:
    OPA 0x0DFF, 2, [cg_dst]
    jmp .yes
.elem:
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    mov eax, [cg_dreg]
    test eax, eax
    jns .elem_reg
    BYTES 0x018B, 2
    cmp dword [esp], OP_SUB
    je .elem_sub
    OPA 0x0501, 2, [cg_dst]
    jmp .yes
.elem_sub:
    OPA 0x0529, 2, [cg_dst]
    jmp .yes
.add_reg:
    cmp esi, 1
    je .inc_reg
    cmp esi, -1
    je .dec_reg
    lea eax, [ecx + 0xC0]
    shl eax, 8
    lea edx, [esi + 128]
    cmp edx, 255
    ja .add_reg32
    mov edx, esi
    and edx, 0xFF
    shl edx, 16
    or eax, edx
    or eax, 0x83
    mov ecx, 3
    call x86_bytes
    jmp .yes
.add_reg32:
    or eax, 0x81
    mov ecx, 2
    call x86_bytes
    mov edx, esi
    call x86_imm32
    jmp .yes
.inc_reg:
    mov eax, 0x40
    call emit_reg1
    jmp .yes
.dec_reg:
    mov eax, 0x48
    call emit_reg1
    jmp .yes
.elem_reg:
    shl eax, 3
    or eax, 1
    shl eax, 8
    or eax, 0x03
    cmp dword [esp], OP_SUB
    jne .elem_emit
    xor eax, 0x28
.elem_emit:
    mov ecx, 2
    call x86_bytes
.yes:
    pop eax
    mov eax, 1
    pop ebx
    pop esi
    ret
.no:
    pop eax
    xor eax, eax
    pop ebx
    pop esi
    ret

emit_expr:
    push esi
    push ebx
    call node_addr
    mov esi, eax
    movzx eax, byte [esi + V_KIND]
    cmp eax, VK_INT
    je .const
    cmp eax, VK_VAR
    je .var
    cmp eax, VK_ELEM
    je .elem
    movzx ebx, byte [esi + V_NEG]
    cmp ebx, OP_NEG
    je .neg
    mov ecx, [esi + V_DATA + 4]
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jbe .right_simple
    cmp ebx, OP_ADD
    je .try_left
    cmp ebx, OP_MUL
    jne .general
.try_left:
    mov ecx, [esi + V_DATA]
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jbe .left_simple
.general:
    mov ecx, [esi + V_DATA]
    call emit_expr
    call temp_limit
    cmp [cg_depth], eax
    jae .spill
    call temp_reg
    push eax
    inc dword [cg_depth]
    mov ecx, R_EAX
    mov edx, eax
    mov eax, 0x89
    call e_rr
    mov ecx, [esi + V_DATA + 4]
    call emit_expr
    dec dword [cg_depth]
    pop eax
    cmp ebx, OP_ADD
    je .reg_add
    cmp ebx, OP_MUL
    je .reg_mul
    cmp ebx, OP_SUB
    je .reg_sub
    push eax
    BYTES 0xC189, 2
    pop ecx
    mov edx, R_EAX
    mov eax, 0x89
    call e_rr
    call apply_reg
    jmp .done
.reg_add:
    mov ecx, eax
    mov edx, R_EAX
    mov eax, 0x01
    call e_rr
    jmp .done
.reg_mul:
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0xAF0F
    call e_rr2
    jmp .done
.reg_sub:
    push eax
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0x29
    call e_rr
    pop ecx
    mov edx, R_EAX
    mov eax, 0x89
    call e_rr
    jmp .done
.spill:
    BYTES 0x50, 1
    mov ecx, [esi + V_DATA + 4]
    call emit_expr
    BYTES 0xC189, 2
    BYTES 0x58, 1
    call apply_reg
    jmp .done
.right_simple:
    mov ecx, [esi + V_DATA]
    call emit_expr
    mov eax, [esi + V_DATA]
    mov [cg_dleft], eax
    mov ecx, [esi + V_DATA + 4]
    call apply_simple
    jmp .done
.left_simple:
    mov ecx, [esi + V_DATA + 4]
    call emit_expr
    mov dword [cg_dleft], -1
    mov ecx, [esi + V_DATA]
    call apply_simple
    jmp .done
.neg:
    mov ecx, [esi + V_DATA]
    call emit_expr
    BYTES 0xD8F7, 2
    jmp .done
.const:
    cmp dword [esi + V_DATA], 0
    jne .const_mov
    BYTES 0xC031, 2
    jmp .done
.const_mov:
    BYTES 0xB8, 1
    mov edx, [esi + V_DATA]
    call x86_imm32
    jmp .done
.var:
    mov ecx, [esi + V_DATA]
    call var_reg
    test eax, eax
    js .var_mem
    mov ecx, eax
    xor edx, edx
    mov eax, 0x89
    call e_rr
    jmp .done
.var_mem:
    mov eax, esi
    call var_abs
    mov edx, eax
    OPA 0xA1, 1, edx
    jmp .done
.elem:
    mov ecx, [esi + V_DATA]
    mov edx, [esi + V_DATA + 4]
    call elem_addr
    BYTES 0x018B, 2
.done:
    pop ebx
    pop esi
    ret

apply_simple:
    push esi
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    je .var
    mov esi, [eax + V_DATA]
    cmp ebx, OP_ADD
    je .add_imm
    cmp ebx, OP_SUB
    je .sub_imm
    cmp ebx, OP_MUL
    je .mul_imm
    cmp ebx, OP_DIV
    je .div_imm
    jmp .mod_imm
.add_imm:
    cmp esi, 1
    je .inc
    cmp esi, -1
    je .dec
    BYTES 0x05, 1
    mov edx, esi
    call x86_imm32
    jmp .ret
.sub_imm:
    cmp esi, 1
    je .dec
    cmp esi, -1
    je .inc
    BYTES 0x2D, 1
    mov edx, esi
    call x86_imm32
    jmp .ret
.inc:
    BYTES 0x40, 1
    jmp .ret
.dec:
    BYTES 0x48, 1
    jmp .ret
.mul_imm:
    call pow2_shift
    test eax, eax
    jz .mul_lea
    push eax
    BYTES 0xE0C1, 2
    pop edx
    call x86_imm8
    jmp .ret
.mul_lea:
    push esi
    inc esi
    call pow2_shift
    pop esi
    cmp eax, 3
    jb .mul_lea3
    push eax
    BYTES 0xC189, 2
    BYTES 0xE0C1, 2
    pop edx
    call x86_imm8
    BYTES 0xC829, 2
    jmp .ret
.mul_lea3:
    cmp esi, 3
    je .lea2
    cmp esi, 5
    je .lea4
    cmp esi, 9
    je .lea8
    BYTES 0xC069, 2
    mov edx, esi
    call x86_imm32
    jmp .ret
.lea2:
    BYTES 0x40048D, 3
    jmp .ret
.lea4:
    BYTES 0x80048D, 3
    jmp .ret
.lea8:
    BYTES 0xC0048D, 3
    jmp .ret
.div_imm:
    cmp esi, 1
    je .ret
    cmp esi, -1
    jne .div_any
    BYTES 0xD8F7, 2
    jmp .ret
.div_any:
    call left_nonneg
    cmp dword [cg_nonneg], 0
    je .div_signed
    cmp esi, 2
    jl .div_signed
    call pow2_shift
    test eax, eax
    jz .div_umag
    push eax
    BYTES 0xE8C1, 2
    pop edx
    call x86_imm8
    jmp .ret
.div_umag:
    cmp dword [cg_ldepth], 0
    je .div_signed
    call umagic
    BYTES 0xBA, 1
    mov edx, [mg_m]
    call x86_imm32
    BYTES 0xE2F7, 2
    BYTES 0xEAC1, 2
    mov edx, [mg_s]
    call x86_imm8
    BYTES 0xD089, 2
    jmp .ret
.div_signed:
    xor eax, eax
    test esi, esi
    jns .div_sign
    cmp esi, 0x80000000
    je .div_sign
    mov ecx, esi
    neg ecx
    lea edx, [ecx - 1]
    test edx, ecx
    jnz .div_sign
    neg esi
    mov eax, 1
.div_sign:
    push eax
    call pow2_shift
    test eax, eax
    jz .div_plain
    push eax
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [esi - 1]
    call x86_imm32
    BYTES 0xD001, 2
    BYTES 0xF8C1, 2
    pop edx
    call x86_imm8
    pop eax
    test eax, eax
    jz .ret
    BYTES 0xD8F7, 2
    jmp .ret
.div_plain:
    pop eax
    test eax, eax
    jz .div_magic
    neg esi
.div_magic:
    call magic_quot
    test eax, eax
    jz .div_idiv
    BYTES 0xD089, 2
    jmp .ret
.div_idiv:
    BYTES 0xB9, 1
    mov edx, esi
    call x86_imm32
    BYTES 0xF9F799, 3
    jmp .ret
.mod_imm:
    lea eax, [esi + 1]
    cmp eax, 2
    ja .mod_any
    BYTES 0xC031, 2
    jmp .ret
.mod_any:
    call left_nonneg
    cmp dword [cg_nonneg], 0
    je .mod_signed
    mov eax, esi
    cdq
    xor eax, edx
    sub eax, edx
    cmp eax, 2
    jl .mod_signed
    mov esi, eax
    call pow2_shift
    test eax, eax
    jz .mod_umag
    BYTES 0x25, 1
    lea edx, [esi - 1]
    call x86_imm32
    jmp .ret
.mod_umag:
    cmp dword [cg_ldepth], 0
    je .mod_signed
    call umagic
    BYTES 0xC189, 2
    BYTES 0xBA, 1
    mov edx, [mg_m]
    call x86_imm32
    BYTES 0xE2F7, 2
    BYTES 0xEAC1, 2
    mov edx, [mg_s]
    call x86_imm8
    BYTES 0xD269, 2
    mov edx, esi
    call x86_imm32
    BYTES 0xC889, 2
    BYTES 0xD029, 2
    jmp .ret
.mod_signed:
    test esi, esi
    jns .mod_pos
    cmp esi, 0x80000000
    je .mod_pos
    mov ecx, esi
    neg ecx
    lea edx, [ecx - 1]
    test edx, ecx
    jnz .mod_pos
    neg esi
.mod_pos:
    call pow2_shift
    test eax, eax
    jz .mod_plain
    BYTES 0xC289, 2
    BYTES 0x1FFAC1, 3
    BYTES 0xE281, 2
    lea edx, [esi - 1]
    call x86_imm32
    BYTES 0x100C8D, 3
    BYTES 0xE181, 2
    mov edx, esi
    neg edx
    call x86_imm32
    BYTES 0xC829, 2
    jmp .ret
.mod_plain:
    call magic_quot
    test eax, eax
    jz .mod_idiv
    BYTES 0xD269, 2
    mov edx, esi
    call x86_imm32
    BYTES 0xC889, 2
    BYTES 0xD029, 2
    jmp .ret
.mod_idiv:
    BYTES 0xB9, 1
    mov edx, esi
    call x86_imm32
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    jmp .ret
.var:
    mov ecx, [eax + V_DATA]
    push eax
    call var_reg
    mov ecx, eax
    pop eax
    test ecx, ecx
    js .var_mem
    mov edx, R_EAX
    mov eax, 0x01
    cmp ebx, OP_ADD
    je .var_rr
    mov eax, 0x29
    cmp ebx, OP_SUB
    je .var_rr
    cmp ebx, OP_MUL
    je .var_mul
    mov edx, R_ECX
    mov eax, 0x89
    call e_rr
    pop esi
    jmp checked_div
.var_rr:
    call e_rr
    jmp .ret
.var_mul:
    mov edx, ecx
    mov ecx, R_EAX
    mov eax, 0xAF0F
    call e_rr2
    jmp .ret
.var_mem:
    call var_abs
    mov esi, eax
    cmp ebx, OP_ADD
    je .add_mem
    cmp ebx, OP_SUB
    je .sub_mem
    cmp ebx, OP_MUL
    je .mul_mem
    OPA 0x0D8B, 2, esi
    pop esi
    jmp checked_div
.add_mem:
    OPA 0x0503, 2, esi
    jmp .ret
.sub_mem:
    OPA 0x052B, 2, esi
    jmp .ret
.mul_mem:
    OPA 0x05AF0F, 3, esi
.ret:
    pop esi
    ret

pow2_shift:
    xor eax, eax
    cmp esi, 2
    jl .r
    lea edx, [esi - 1]
    test edx, esi
    jnz .r
    bsf eax, esi
.r:
    ret

magic_of:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, esi
    cmp eax, 0x80000000
    je .fail
    mov ecx, eax
    neg ecx
    cmovs ecx, eax
    cmp ecx, 2
    jb .fail
    mov [mg_tmp], ecx
    mov [mg_tmp + 4], eax
    shr eax, 31
    add eax, 0x80000000
    xor edx, edx
    div ecx
    mov eax, [mg_tmp + 4]
    shr eax, 31
    add eax, 0x80000000
    sub eax, edx
    dec eax
    mov ebp, eax
    mov ebx, 31
    mov eax, 0x80000000
    xor edx, edx
    div ebp
    mov esi, eax
    imul eax, ebp
    mov edi, 0x80000000
    sub edi, eax
    mov eax, 0x80000000
    xor edx, edx
    div dword [mg_tmp]
    mov [mg_tmp + 8], eax
    imul eax, [mg_tmp]
    mov edx, 0x80000000
    sub edx, eax
    mov [mg_tmp + 12], edx
.loop:
    inc ebx
    add esi, esi
    add edi, edi
    cmp edi, ebp
    jb .r1
    inc esi
    sub edi, ebp
.r1:
    mov eax, [mg_tmp + 8]
    add eax, eax
    mov [mg_tmp + 8], eax
    mov edx, [mg_tmp + 12]
    add edx, edx
    cmp edx, [mg_tmp]
    jb .r2
    inc dword [mg_tmp + 8]
    sub edx, [mg_tmp]
.r2:
    mov [mg_tmp + 12], edx
    mov ecx, [mg_tmp]
    sub ecx, edx
    cmp esi, ecx
    jb .loop
    jne .done
    test edi, edi
    jz .loop
.done:
    mov eax, [mg_tmp + 8]
    inc eax
    cmp dword [mg_tmp + 4], 0
    jns .pos
    neg eax
.pos:
    mov [mg_m], eax
    lea eax, [ebx - 32]
    mov [mg_s], eax
    mov eax, 1
    jmp .out
.fail:
    xor eax, eax
.out:
    pop ebp
    pop edi
    pop esi
    pop ebx
    ret

magic_quot:
    xor eax, eax
    cmp dword [cg_ldepth], 0
    je .r
    call magic_of
    test eax, eax
    jz .r
    BYTES 0xC189, 2
    BYTES 0xB8, 1
    mov edx, [mg_m]
    call x86_imm32
    BYTES 0xE9F7, 2
    cmp esi, 0
    jle .neg_d
    cmp dword [mg_m], 0
    jge .shift
    BYTES 0xCA01, 2
    jmp .shift
.neg_d:
    cmp dword [mg_m], 0
    jle .shift
    BYTES 0xCA29, 2
.shift:
    cmp dword [mg_s], 0
    je .sign
    BYTES 0xFAC1, 2
    mov edx, [mg_s]
    call x86_imm8
.sign:
    BYTES 0xD089, 2
    BYTES 0x1FE8C1, 3
    BYTES 0xC201, 2
    mov eax, 1
.r:
    ret

apply_reg:
    cmp ebx, OP_ADD
    je .add
    cmp ebx, OP_SUB
    je .sub
    cmp ebx, OP_MUL
    je .mul
    jmp checked_div
.add:
    BYTES 0xC801, 2
    ret
.sub:
    BYTES 0xC829, 2
    ret
.mul:
    BYTES 0xC1AF0F, 3
    ret

checked_div:
    BYTES 0x0A75C985, 4
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x86_imm32
    mov ecx, [rt_offsets + RT_FN_DIV_ZERO]
    call x86_call_rel
    BYTES 0x75FFF983, 4
    BYTES 0x04, 1
    cmp ebx, OP_DIV
    jne .mod
    BYTES 0x03EBD8F7, 4
    BYTES 0xF9F799, 3
    ret
.mod:
    BYTES 0x05EBC031, 4
    BYTES 0xF9F799, 3
    BYTES 0xD089, 2
    ret

record_patch:
    push eax
    call x86_text_offset
    mov ecx, [cg_npatch]
    mov edx, [cg_patch]
    mov [edx + ecx * 4], eax
    inc dword [cg_npatch]
    mov dword [edi], 0
    add edi, 4
    pop eax
    ret

patch_range:
    push esi
    push ebx
    mov esi, ecx
    mov ebx, edx
    call x86_text_offset
.loop:
    cmp esi, ebx
    jae .done
    mov ecx, [cg_patch]
    mov ecx, [ecx + esi * 4]
    mov edx, eax
    sub edx, ecx
    sub edx, 4
    add ecx, [x86_text_base]
    mov [ecx], edx
    inc esi
    jmp .loop
.done:
    pop ebx
    pop esi
    ret

jump_to_label:
    test ecx, ecx
    jz record_patch
    push ecx
    call x86_text_offset
    pop ecx
    mov edx, [cg_nlp]
    push ebx
    mov ebx, [cg_lp]
    mov [ebx + edx * 4], eax
    mov ebx, [cg_lpl]
    mov [ebx + edx * 4], ecx
    pop ebx
    inc dword [cg_nlp]
    mov dword [edi], 0
    add edi, 4
    ret

place_label:
    push esi
    push ebx
    push ebp
    mov ebp, ecx
    call x86_text_offset
    mov [cg_tmp], eax
    xor esi, esi
    xor ebx, ebx
.l:
    cmp esi, [cg_nlp]
    jae .done
    mov eax, [cg_lpl]
    mov ecx, [eax + esi * 4]
    mov eax, [cg_lp]
    mov edx, [eax + esi * 4]
    cmp ecx, ebp
    jne .keep
    mov eax, [cg_tmp]
    sub eax, edx
    sub eax, 4
    add edx, [x86_text_base]
    mov [edx], eax
    jmp .n
.keep:
    mov eax, [cg_lp]
    mov [eax + ebx * 4], edx
    mov eax, [cg_lpl]
    mov [eax + ebx * 4], ecx
    inc ebx
.n:
    inc esi
    jmp .l
.done:
    mov [cg_nlp], ebx
    pop ebp
    pop ebx
    pop esi
    ret

emit_cond:
    push esi
    push ebx
    push ebp
    mov ebx, edx
    mov ebp, eax
    call node_addr
    mov esi, eax
    movzx eax, byte [esi + V_KIND]
    cmp eax, VK_BOOL
    je .const
    cmp eax, VK_OR
    je .or
    cmp eax, VK_AND
    je .and
    call emit_compare
    test ebx, ebx
    jnz .jcc
    xor eax, 1
.jcc:
    shl eax, 8
    or eax, 0x800F
    mov ecx, 2
    call x86_bytes
    jmp .record
.const:
    xor eax, eax
    cmp dword [esi + V_DATA], 0
    setne al
    cmp eax, ebx
    jne .done
    BYTES 0xE9, 1
.record:
    mov ecx, ebp
    call jump_to_label
    jmp .done
.or:
    mov eax, 1
    jmp .pair
.and:
    xor eax, eax
.pair:
    cmp eax, ebx
    jne .split
    mov ecx, [esi + V_DATA]
    mov edx, ebx
    mov eax, ebp
    call emit_cond
    mov ecx, [esi + V_DATA + 4]
    mov edx, ebx
    mov eax, ebp
    call emit_cond
    jmp .done
.split:
    mov edx, eax
    mov eax, [cg_label]
    inc dword [cg_label]
    push eax
    mov ecx, [esi + V_DATA]
    call emit_cond
    mov ecx, [esi + V_DATA + 4]
    mov edx, ebx
    mov eax, ebp
    call emit_cond
    pop ecx
    call place_label
.done:
    pop ebp
    pop ebx
    pop esi
    ret

cc_of_op:
    mov eax, 4
    cmp ecx, CMP_IS
    je .r
    mov eax, 5
    cmp ecx, CMP_ISNOT
    je .r
    mov eax, 0xC
    cmp ecx, CMP_LT
    je .r
    mov eax, 0xE
    cmp ecx, CMP_LE
    je .r
    mov eax, 0xD
    cmp ecx, CMP_GE
    je .r
    mov eax, 0xF
.r:
    ret

emit_compare:
    push ebx
    push ebp
    push dword [cg_tmp + 8]
    movzx eax, byte [esi + V_NEG]
    mov [cg_tmp + 8], eax
    mov ebx, [esi + V_DATA]
    mov ebp, [esi + V_DATA + 4]
    movzx eax, byte [esi + V_TYPE]
    cmp eax, TY_STR
    je .str
    cmp eax, TY_BOOL
    je .bool
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .order_ok
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    je .order_ok
    xchg ebx, ebp
    mov eax, [cg_tmp + 8]
    mov ecx, CMP_GT
    cmp eax, CMP_LT
    je .mirror
    mov ecx, CMP_LT
    cmp eax, CMP_GT
    je .mirror
    mov ecx, CMP_GE
    cmp eax, CMP_LE
    je .mirror
    mov ecx, CMP_LE
    cmp eax, CMP_GE
    jne .order_ok
.mirror:
    mov [cg_tmp + 8], ecx
.order_ok:
    call try_divisible
    test eax, eax
    jnz .ret
    mov ecx, ebx
    call emit_expr
    mov ecx, ebp
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_INT
    je .int_imm
    cmp edx, VK_VAR
    je .int_var
    call temp_limit
    cmp [cg_depth], eax
    jae .int_spill
    call temp_reg
    push eax
    inc dword [cg_depth]
    mov ecx, R_EAX
    mov edx, eax
    mov eax, 0x89
    call e_rr
    mov ecx, ebp
    call emit_expr
    dec dword [cg_depth]
    pop edx
    mov ecx, R_EAX
    mov eax, 0x39
    call e_rr
    jmp .int_cc
.int_spill:
    BYTES 0x50, 1
    mov ecx, ebp
    call emit_expr
    BYTES 0x58C189, 3
    BYTES 0xC839, 2
    jmp .int_cc
.int_imm:
    mov edx, [eax + V_DATA]
    test edx, edx
    jnz .imm_cmp
    BYTES 0xC085, 2
    jmp .int_cc
.imm_cmp:
    push edx
    BYTES 0x3D, 1
    pop edx
    call x86_imm32
    jmp .int_cc
.int_var:
    push eax
    mov ecx, [eax + V_DATA]
    call var_reg
    mov ecx, eax
    pop eax
    test ecx, ecx
    js .int_mem
    xor edx, edx
    mov eax, 0x39
    call e_rr
    jmp .int_cc
.int_mem:
    call var_abs
    mov edx, eax
    OPA 0x053B, 2, edx
.int_cc:
    mov ecx, [cg_tmp + 8]
    call cc_of_op
    jmp .ret
.bool:
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    je .bool_left_var
    cmp byte [eax + V_KIND], VK_ELEM
    je .bool_left_elem
    mov edx, [eax + V_DATA]
    push edx
    BYTES 0xB8, 1
    pop edx
    call x86_imm32
    jmp .bool_right
.bool_left_var:
    call var_abs
    mov edx, eax
    OPA 0x05B60F, 3, edx
    jmp .bool_right
.bool_left_elem:
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    BYTES 0x01B60F, 3
.bool_right:
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    je .bool_right_var
    cmp byte [eax + V_KIND], VK_ELEM
    je .bool_right_elem
    mov edx, [eax + V_DATA]
    push edx
    BYTES 0x3D, 1
    pop edx
    call x86_imm32
    jmp .bool_cc
.bool_right_var:
    call var_abs
    mov edx, eax
    OPA 0x0DB60F, 3, edx
    BYTES 0xC839, 2
    jmp .bool_cc
.bool_right_elem:
    push eax
    BYTES 0x50, 1
    pop eax
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    BYTES 0x09B60F, 3
    BYTES 0x58, 1
    BYTES 0xC839, 2
.bool_cc:
    mov ecx, [cg_tmp + 8]
    call cc_of_op
    jmp .ret
.str:
    mov ecx, ebp
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_VAR
    je .b_var
    cmp edx, VK_STR
    je .b_lit
    cmp edx, VK_ELEM
    je .b_elem
    BYTES 0xC031006A, 4
    jmp .a
.b_elem:
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    BYTES 0x0841B70F, 4
    BYTES 0x50, 1
    BYTES 0x018B, 2
    jmp .a
.b_var:
    call var_abs
    push eax
    lea edx, [eax + 8]
    OPA 0x05B70F, 3, edx
    BYTES 0x50, 1
    pop edx
    OPA 0xA1, 1, edx
    jmp .a
.b_lit:
    push eax
    BYTES 0x68, 1
    mov eax, [esp]
    mov edx, [eax + V_DATA_HI]
    call x86_imm32
    BYTES 0xB8, 1
    pop eax
    mov edx, [eax + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
.a:
    mov ecx, ebx
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_VAR
    je .a_var
    cmp edx, VK_STR
    je .a_lit
    cmp edx, VK_ELEM
    je .a_elem
    BYTES 0xD231C931, 4
    jmp .call
.a_elem:
    push eax
    BYTES 0x50, 1
    pop eax
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    BYTES 0x0851B70F, 4
    BYTES 0x098B, 2
    BYTES 0x58, 1
    jmp .call
.a_var:
    call var_abs
    push eax
    mov edx, eax
    OPA 0x0D8B, 2, edx
    pop edx
    add edx, 8
    OPA 0x15B70F, 3, edx
    jmp .call
.a_lit:
    push eax
    BYTES 0xB9, 1
    mov eax, [esp]
    mov edx, [eax + V_DATA]
    add edx, [cg_pool]
    call x86_imm32
    BYTES 0xBA, 1
    pop eax
    mov edx, [eax + V_DATA_HI]
    call x86_imm32
.call:
    CALL_RT RT_FN_STR_EQ
    BYTES 0xC085, 2
    mov eax, 5
    cmp dword [cg_tmp + 8], CMP_IS
    je .ret
    mov eax, 4
.ret:
    pop dword [cg_tmp + 8]
    pop ebp
    pop ebx
    ret

try_divisible:
    xor eax, eax
    cmp dword [cg_ldepth], 0
    je .r
    cmp dword [cg_tmp + 8], CMP_LT
    jae .no
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_MOD
    jne .no
    push eax
    mov ecx, [eax + V_DATA + 4]
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov edx, [eax + V_DATA]
    cmp edx, 0x80000000
    je .no
    mov eax, edx
    neg eax
    cmovs eax, edx
    cmp eax, 2
    jb .no
    push esi
    mov esi, eax
    push ecx
    mov ecx, [ecx + V_DATA]
    push ecx
    call node_addr
    pop ecx
    lea edx, [esi - 1]
    test edx, esi
    jz .gen
    cmp byte [eax + V_KIND], VK_VAR
    jne .gen
    push ecx
    mov ecx, [eax + V_DATA]
    mov eax, [cg_vreg]
    movzx eax, byte [eax + ecx]
    pop ecx
    test eax, 0x40
    jz .gen
    and eax, 0x1F
    dec eax
    mov ecx, eax
    mov edx, R_ECX
    mov eax, 0x89
    call e_rr
    pop ecx
    jmp .gm_mul
.gen:
    call emit_expr
    pop ecx
    lea edx, [esi - 1]
    test edx, esi
    jnz .gm_abs
    cmp edx, 0xFF
    ja .test32
    BYTES 0xA8, 1
    call x86_imm8
    jmp .zf
.test32:
    BYTES 0xA9, 1
    call x86_imm32
.zf:
    pop esi
    mov ecx, [cg_tmp + 8]
    call cc_of_op
    ret
.gm_abs:
    BYTES 0xD9F7C189, 4
    BYTES 0xC8480F, 3
.gm_mul:
    mov ecx, esi
    bsf ecx, esi
    mov edx, esi
    shr edx, cl
    mov [cg_tmp], ecx
    mov eax, edx
    mov ecx, 4
.newton:
    push ecx
    mov ecx, edx
    imul ecx, eax
    neg ecx
    add ecx, 2
    imul eax, ecx
    pop ecx
    dec ecx
    jnz .newton
    push eax
    BYTES 0xC969, 2
    pop edx
    call x86_imm32
    cmp dword [cg_tmp], 0
    je .no_ror
    BYTES 0xC9C1, 2
    mov edx, [cg_tmp]
    call x86_imm8
.no_ror:
    BYTES 0xF981, 2
    mov eax, 0xFFFFFFFF
    xor edx, edx
    div esi
    mov edx, eax
    call x86_imm32
    pop esi
    mov eax, 6
    cmp dword [cg_tmp + 8], CMP_IS
    je .r
    mov eax, 7
.r:
    ret
.no:
    xor eax, eax
    ret

close_blocks:
    push esi
    push ebx
    mov ebx, eax
.loop:
    mov eax, [cg_bdepth]
    test eax, eax
    jz .done
    dec eax
    imul eax, eax, B_SIZE
    lea esi, [cg_bstack + eax]
    cmp [esi + B_END], ebx
    jne .done
    cmp dword [esi + B_KIND], BK_GROUP
    je .close_group
    cmp dword [esi + B_KIND], BK_IF
    jne .close_loop
    call else_of
    test eax, eax
    jz .plain_if
    push eax
    BYTES 0xE9, 1
    call x86_text_offset
    push eax
    mov dword [edi], 0
    add edi, 4
    mov ecx, [esi + B_TOP]
    mov edx, [cg_npatch]
    call patch_range
    pop eax
    mov ecx, [esi + B_TOP]
    mov edx, [cg_patch]
    mov [edx + ecx * 4], eax
    inc ecx
    mov [cg_npatch], ecx
    pop eax
    mov edx, [eax + S_PIECES]
    mov [esi + B_END], edx
    mov dword [esi + B_IFIDX], -1
    jmp .loop
.plain_if:
    mov ecx, [esi + B_TOP]
    mov edx, [cg_npatch]
    call patch_range
    mov ecx, [esi + B_TOP]
    mov [cg_npatch], ecx
    dec dword [cg_bdepth]
    jmp .loop
.close_group:
    mov ecx, [esi + B_LABEL]
    call place_label
    call take_clear
    dec dword [cg_bdepth]
    jmp .loop
.close_loop:
    call emit_loop_tail
    mov ecx, [esi + B_LABEL]
    test ecx, ecx
    jz .no_exit
    call place_label
.no_exit:
    call take_clear
    dec dword [cg_bdepth]
    dec dword [cg_ldepth]
    jnz .loop
    call unpromote
    jmp .loop
.done:
    pop ebx
    pop esi
    ret

emit_jump:
    push esi
    push ebx
    mov ebx, [cg_cur]
    mov eax, [cg_bdepth]
    imul eax, eax, B_SIZE
    lea esi, [cg_bstack + eax]
.find:
    sub esi, B_SIZE
    cmp word [ebx + S_MODE], 0
    jne .group
    cmp dword [esi + B_KIND], BK_FOR
    je .found
    cmp dword [esi + B_KIND], BK_LOOPS
    je .found
    jmp .find
.group:
    cmp dword [esi + B_KIND], BK_GROUP
    jne .find
    mov eax, [ebx + S_VAR]
    cmp [esi + B_GIDX], eax
    jne .find
    cmp dword [esi + B_GLD], 0
    jne .found
    call flush_prom
.found:
    BYTES 0xE9, 1
    mov ecx, [esi + B_LABEL]
    cmp word [ebx + S_KIND], SK_CONTINUE
    jne .emit
    inc ecx
.emit:
    call jump_to_label
    pop ebx
    pop esi
    ret

emit_input:
    push esi
    push ebx
    mov esi, [cg_cur]
    mov ecx, [esi + S_VAR]
    mov edx, [cg_kvok]
    mov byte [edx + ecx], 0
    mov eax, [esi + S_VAR]
    mov ecx, eax
    shl ecx, 5
    add ecx, [g_vars]
    movzx ebx, word [ecx + VR_TYPE]
    cmp dword [esi + S_MODETOK], NO_TOKEN
    jne .elem
    call var_abs_idx
    push eax
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x86_imm32
    pop edx
    cmp ebx, TY_INT
    je .int
    BYTES 0xB9, 1
    call x86_imm32
    CALL_RT RT_FN_INPUT_STR
    jmp .r
.int:
    push edx
    CALL_RT RT_FN_INPUT_INT
    pop edx
    mov ecx, [esi + S_VAR]
    call prom_reg
    test eax, eax
    js .int_mem
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0x89
    call e_rr
    jmp .r
.int_mem:
    OPA 0xA3, 1, edx
    jmp .r
.elem:
    cmp ebx, TY_INT
    je .elem_int
    mov ecx, [esi + S_VAR]
    mov edx, [esi + S_MODETOK]
    call elem_addr
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x86_imm32
    CALL_RT RT_FN_INPUT_STR
    jmp .r
.elem_int:
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x86_imm32
    CALL_RT RT_FN_INPUT_INT
    BYTES 0x50, 1
    mov ecx, [esi + S_VAR]
    mov edx, [esi + S_MODETOK]
    call elem_addr
    BYTES 0x58, 1
    BYTES 0x0189, 2
.r:
    pop ebx
    pop esi
    ret

group_open:
    push ebx
    mov ebx, [cg_cur]
    cmp word [ebx + S_MODE], 0
    je .r
    cmp dword [cg_bdepth], 0
    jne .kv_done
    call kv_invalidate
.kv_done:
    mov eax, [cg_bdepth]
    imul eax, eax, B_SIZE
    lea ecx, [cg_bstack + eax]
    inc dword [cg_bdepth]
    mov edx, [ebx + S_PIECES]
    mov [ecx + B_END], edx
    mov dword [ecx + B_KIND], BK_GROUP
    mov edx, ebx
    sub edx, [g_stmts]
    shr edx, 5
    mov [ecx + B_GIDX], edx
    mov edx, [cg_ldepth]
    mov [ecx + B_GLD], edx
    mov edx, [cg_label]
    mov [ecx + B_LABEL], edx
    inc dword [cg_label]
    mov dword [ecx + B_TAKE], 0
    test word [ebx + S_MODE], 1
    jz .r
    push ecx
    mov eax, [ebx + S_VAR]
    call var_abs_idx
    pop ecx
    mov [ecx + B_TAKE], eax
.r:
    pop ebx
    ret

take_store:
    mov edx, [esi + B_TAKE]
    test edx, edx
    jz .r
    cmp dword [esi + B_DYN], 0
    jne .dyn
    OPA 0x05C7, 2, edx
    mov edx, [esi + B_LIMIT]
    jmp x86_imm32
.dyn:
    OPA 0xA3, 1, edx
.r:
    ret

take_clear:
    mov edx, [esi + B_TAKE]
    test edx, edx
    jz .r
    OPA 0x05C7, 2, edx
    xor edx, edx
    jmp x86_imm32
.r:
    ret

else_of:
    xor eax, eax
    mov ecx, ebx
    mov edx, [g_nstmt]
    cmp ecx, edx
    jae .r
    call stmt_ptr
    cmp word [eax + S_KIND], SK_ELSE
    jne .no
    mov ecx, [eax + S_VAR]
    cmp ecx, [esi + B_IFIDX]
    jne .no
    ret
.no:
    xor eax, eax
.r:
    ret

for_aliasable:
    push esi
    push ebx
    mov ebx, ecx
    mov esi, [cg_cur]
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    lea ecx, [eax + 1]
    mov edx, [esi + S_PIECES]
.l:
    cmp ecx, edx
    jae .yes
    push ecx
    call stmt_ptr
    pop ecx
    inc ecx
    movzx esi, word [eax + S_KIND]
    cmp esi, SK_DECL
    je .chk
    cmp esi, SK_ASSIGN
    je .chk
    cmp esi, SK_INPUT
    je .chk
    cmp esi, SK_FOR
    jne .l
.chk:
    cmp [eax + S_VAR], ebx
    jne .l
    xor eax, eax
    jmp .r
.yes:
    mov eax, 1
.r:
    pop ebx
    pop esi
    ret

emit_reg1:
    add eax, ecx
    mov [edi], al
    inc edi
    ret

emit_loop_head:
    push esi
    push ebx
    mov ebx, [cg_cur]
    mov eax, [cg_bdepth]
    imul eax, eax, B_SIZE
    lea esi, [cg_bstack + eax]
    inc dword [cg_bdepth]
    mov edx, [ebx + S_PIECES]
    mov [esi + B_END], edx
    mov dword [esi + B_INIT], -1
    mov dword [esi + B_ALIAS], -1
    mov dword [esi + B_LABEL], 0
    mov dword [esi + B_TAKE], 0
    mov dword [esi + B_FINAL], 0
    test word [ebx + S_MODE], 1
    jz .no_label
    mov eax, [cg_label]
    mov [esi + B_LABEL], eax
    add dword [cg_label], 2
.no_label:
    mov eax, [ebx + S_MODETOK]
    test eax, eax
    jz .no_take
    dec eax
    shl eax, 5
    add eax, [g_stmts]
    test word [eax + S_MODE], 1
    jz .no_take
    mov eax, [eax + S_VAR]
    call var_abs_idx
    mov [esi + B_TAKE], eax
.no_take:
    mov dword [esi + B_KIND], BK_LOOPS
    cmp word [ebx + S_KIND], SK_FOR
    jne .kind_set
    mov dword [esi + B_KIND], BK_FOR
.kind_set:
    mov eax, [cg_ldepth]
    inc dword [cg_ldepth]
    mov ecx, NOREG
    cmp eax, 2
    jae .reg_set
    movzx ecx, byte [loop_regs + eax]
.reg_set:
    mov [esi + B_REG], ecx
    mov eax, [ebx + S_NPIECES]
    add eax, [cg_vars]
    mov [esi + B_LIMIT], eax
    add eax, 4
    mov [esi + B_SLOT], eax
    mov eax, [ebx + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    push ecx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .dynamic
    mov dword [esi + B_DYN], 0
    mov edx, [eax + V_DATA]
    mov [esi + B_LIMIT], edx
    jmp .count_ready
.dynamic:
    mov dword [esi + B_DYN], 1
    call emit_expr
.count_ready:
    call take_store
    cmp dword [esi + B_KIND], BK_FOR
    je .for_head
    cmp dword [esi + B_DYN], 0
    jne .loops_dyn
    cmp dword [esi + B_REG], NOREG
    je .loops_const_mem
    mov eax, 0xB8
    mov ecx, [esi + B_REG]
    call emit_reg1
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .loops_test
.loops_const_mem:
    OPA 0x05C7, 2, [esi + B_SLOT]
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .loops_test
.loops_dyn:
    cmp dword [esi + B_REG], NOREG
    je .loops_dyn_mem
    mov ecx, R_EAX
    mov edx, [esi + B_REG]
    mov eax, 0x89
    call e_rr
    jmp .loops_test
.loops_dyn_mem:
    OPA 0xA3, 1, [esi + B_SLOT]
.loops_test:
    cmp dword [esi + B_DYN], 0
    jne .loops_need_test
    cmp dword [esi + B_LIMIT], 0
    jg .loops_top
.loops_need_test:
    cmp dword [esi + B_REG], NOREG
    je .loops_test_mem
    mov ecx, [esi + B_REG]
    mov edx, ecx
    mov eax, 0x85
    call e_rr
    jmp .loops_jle
.loops_test_mem:
    OPA 0x3D83, 2, [esi + B_SLOT]
    xor edx, edx
    call x86_imm8
.loops_jle:
    BYTES 0x8E0F, 2
    call x86_text_offset
    mov [esi + B_INIT], eax
    mov dword [edi], 0
    add edi, 4
.loops_top:
    call x86_text_offset
    mov [esi + B_TOP], eax
    jmp .done

.for_head:
    cmp dword [esi + B_DYN], 0
    je .for_init
    OPA 0xA3, 1, [esi + B_LIMIT]
.for_init:
    cmp dword [esi + B_REG], NOREG
    je .for_init_mem
    mov eax, 0xB8
    mov ecx, [esi + B_REG]
    call emit_reg1
    mov edx, 1
    call x86_imm32
    jmp .for_jump
.for_init_mem:
    OPA 0x05C7, 2, [esi + B_SLOT]
    mov edx, 1
    call x86_imm32
.for_jump:
    cmp dword [esi + B_DYN], 0
    jne .for_need_jump
    cmp dword [esi + B_LIMIT], 0
    jg .for_top
.for_need_jump:
    BYTES 0xE9, 1
    call x86_text_offset
    mov [esi + B_INIT], eax
    mov dword [edi], 0
    add edi, 4
.for_top:
    call x86_text_offset
    mov [esi + B_TOP], eax
    mov eax, [ebx + S_VAR]
    call var_abs_idx
    mov edx, eax
    cmp dword [esi + B_REG], NOREG
    je .for_store_mem
    push edx
    mov ecx, [ebx + S_VAR]
    call for_aliasable
    test eax, eax
    jz .for_store_reg
    mov ecx, [ebx + S_VAR]
    mov [esi + B_ALIAS], ecx
    mov eax, [cg_vreg]
    mov edx, [esi + B_REG]
    inc edx
    or edx, 0x40
    mov [eax + ecx], dl
    mov eax, 0x7FFFFFFE
    cmp dword [esi + B_DYN], 0
    jne .alias_hi
    mov eax, [esi + B_LIMIT]
.alias_hi:
    mov edx, [cg_vhi]
    mov [edx + ecx * 4], eax
    test word [ebx + S_MODE], 1
    jnz .for_store_reg
    cmp dword [esi + B_DYN], 0
    jne .for_store_reg
    cmp dword [esi + B_LIMIT], 0
    jle .for_store_reg
    call body_callfree
    cmp eax, 1
    jne .for_store_reg
    pop edx
    mov [esi + B_FINAL], edx
    jmp .done
.for_store_reg:
    pop edx
    mov ecx, [esi + B_REG]
    mov eax, 0x89
    call e_mr
    jmp .done
.for_store_mem:
    push edx
    OPA 0xA1, 1, [esi + B_SLOT]
    pop edx
    OPA 0xA3, 1, edx
.done:
    pop ebx
    pop esi
    ret

patch_initial:
    mov eax, [esi + B_INIT]
    cmp eax, -1
    je .none
    push eax
    call x86_text_offset
    mov edx, eax
    pop eax
    sub edx, eax
    sub edx, 4
    add eax, [x86_text_base]
    mov [eax], edx
.none:
    ret

emit_rel32_back:
    call x86_text_offset
    add eax, 4
    sub ecx, eax
    mov [edi], ecx
    add edi, 4
    ret

emit_loop_tail:
    mov ecx, [esi + B_ALIAS]
    cmp ecx, -1
    je .no_alias
    mov eax, [cg_vreg]
    mov byte [eax + ecx], 0
    mov eax, [cg_vhi]
    mov dword [eax + ecx * 4], -1
.no_alias:
    mov ecx, [esi + B_LABEL]
    test ecx, ecx
    jz .no_cont
    inc ecx
    call place_label
.no_cont:
    cmp dword [esi + B_KIND], BK_FOR
    jne .loops_tail
    cmp dword [esi + B_REG], NOREG
    je .for_inc_mem
    mov eax, 0x40
    mov ecx, [esi + B_REG]
    call emit_reg1
    jmp .for_check
.for_inc_mem:
    OPA 0x05FF, 2, [esi + B_SLOT]
.for_check:
    call patch_initial
    cmp dword [esi + B_REG], NOREG
    je .for_cmp_mem
    cmp dword [esi + B_DYN], 0
    jne .for_cmp_reg_slot
    mov ecx, 7
    mov edx, [esi + B_REG]
    mov eax, 0x81
    call e_rr
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .jl_back
.for_cmp_reg_slot:
    mov ecx, [esi + B_REG]
    mov edx, [esi + B_LIMIT]
    mov eax, 0x3B
    call e_mr
    jmp .jl_back
.for_cmp_mem:
    OPA 0xA1, 1, [esi + B_SLOT]
    cmp dword [esi + B_DYN], 0
    jne .for_cmp_mem_slot
    BYTES 0x3D, 1
    mov edx, [esi + B_LIMIT]
    call x86_imm32
    jmp .jl_back
.for_cmp_mem_slot:
    OPA 0x053B, 2, [esi + B_LIMIT]
.jl_back:
    BYTES 0x8E0F, 2
    mov ecx, [esi + B_TOP]
    call emit_rel32_back
    cmp dword [esi + B_FINAL], 0
    je .r
    OPA 0x05C7, 2, [esi + B_FINAL]
    mov edx, [esi + B_LIMIT]
    call x86_imm32
.r:
    ret
.loops_tail:
    cmp dword [esi + B_REG], NOREG
    je .loops_dec_mem
    mov eax, 0x48
    mov ecx, [esi + B_REG]
    call emit_reg1
    jmp .loops_jnz
.loops_dec_mem:
    OPA 0x0DFF, 2, [esi + B_SLOT]
.loops_jnz:
    BYTES 0x850F, 2
    mov ecx, [esi + B_TOP]
    call emit_rel32_back
    jmp patch_initial

umagic:
    lea ecx, [esi - 1]
    bsr ecx, ecx
    mov [mg_s], ecx
    mov edx, 1
    shl edx, cl
    dec edx
    mov eax, -1
    div esi
    inc eax
    mov [mg_m], eax
    ret

left_nonneg:
    mov dword [cg_nonneg], 0
    mov ecx, [cg_dleft]
    cmp ecx, -1
    je .r
    call node_range
    test eax, eax
    js .r
    mov dword [cg_nonneg], 1
.r:
    ret

node_range:
    push ebx
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_INT
    je .int
    cmp edx, VK_VAR
    je .var
    cmp edx, VK_EXPR
    jne .unknown
    mov ebx, eax
    movzx edx, byte [ebx + V_NEG]
    cmp edx, OP_ADD
    je .add
    cmp edx, OP_MUL
    je .mul
    cmp edx, OP_DIV
    je .div
    cmp edx, OP_MOD
    je .mod
    jmp .unknown
.int:
    mov eax, [eax + V_DATA]
    test eax, eax
    js .unknown
    pop ebx
    ret
.var:
    mov edx, [eax + V_DATA]
    mov eax, [cg_vhi]
    mov eax, [eax + edx * 4]
    pop ebx
    ret
.add:
    call .pair
    js .unknown
    add eax, edx
    jmp .fit
.mul:
    call .pair
    js .unknown
    mul edx
    test edx, edx
    jnz .unknown
.fit:
    cmp eax, 0x7FFFFFFF
    ja .unknown
    pop ebx
    ret
.div:
    call .const_right
    jz .unknown
    test eax, eax
    jle .unknown
    push eax
    mov ecx, [ebx + V_DATA]
    call node_range
    pop ecx
    test eax, eax
    js .unknown
    xor edx, edx
    div ecx
    pop ebx
    ret
.mod:
    call .const_right
    jz .unknown
    cmp eax, 0x80000000
    je .unknown
    mov ecx, eax
    neg ecx
    cmovs ecx, eax
    dec ecx
    push ecx
    mov ecx, [ebx + V_DATA]
    call node_range
    pop ecx
    test eax, eax
    js .unknown
    cmp eax, ecx
    cmova eax, ecx
    pop ebx
    ret
.unknown:
    mov eax, -1
    pop ebx
    ret
.pair:
    mov ecx, [ebx + V_DATA]
    call node_range
    test eax, eax
    js .pair_r
    push eax
    mov ecx, [ebx + V_DATA + 4]
    call node_range
    mov edx, eax
    pop eax
    test edx, edx
.pair_r:
    ret
.const_right:
    mov ecx, [ebx + V_DATA + 4]
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .not_const
    mov eax, [eax + V_DATA]
    or ecx, 1
    ret
.not_const:
    xor ecx, ecx
    ret

kv_record:
    cmp dword [cg_bdepth], 0
    jne .r
    cmp dword [cg_ldepth], 0
    jne .r
    cmp word [esi + S_MODE], TY_INT
    jne .r
    mov ecx, [esi + S_VAR]
    mov edx, [cg_kvok]
    mov byte [edx + ecx], 0
    xor eax, eax
    cmp dword [esi + S_NPARTS], 0
    je .known
    push ecx
    mov eax, esi
    call stmt_root
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .r
    mov eax, [eax + V_DATA]
.known:
    mov edx, [cg_kv]
    mov [edx + ecx * 4], eax
    mov edx, [cg_kvok]
    mov byte [edx + ecx], 1
.r:
    ret

kv_invalidate:
    push esi
    push ebx
    mov esi, [cg_cur]
    call ts_cur_idx
    lea ebx, [eax + 1]
    mov edx, [cg_kvok]
    cmp word [esi + S_KIND], SK_FOR
    jne .l
    mov ecx, [esi + S_VAR]
    mov byte [edx + ecx], 0
.l:
    cmp ebx, [esi + S_PIECES]
    jae .r
    mov ecx, ebx
    call stmt_ptr
    inc ebx
    movzx ecx, word [eax + S_KIND]
    cmp ecx, SK_DECL
    je .kill
    cmp ecx, SK_ASSIGN
    je .kill
    cmp ecx, SK_INPUT
    je .kill
    cmp ecx, SK_FOR
    jne .l
.kill:
    mov ecx, [eax + S_VAR]
    mov byte [edx + ecx], 0
    jmp .l
.r:
    pop ebx
    pop esi
    ret

rg_add:
    mov edx, [rg_state]
    cmp dword [edx + ecx * 4], 0
    jne .r
    mov dword [edx + ecx * 4], 1
    mov edx, [rg_list]
    mov eax, [rg_n]
    mov [edx + eax * 4], ecx
    inc dword [rg_n]
.r:
    ret

rg_mod_of:
    push ecx
    mov eax, ebp
    call stmt_root
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_EXPR
    jne .bad
    cmp byte [eax + V_NEG], OP_MOD
    jne .bad
    push ecx
    mov ecx, [eax + V_DATA + 4]
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .bad
    mov eax, [eax + V_DATA]
    test eax, eax
    jz .bad
    cmp eax, 0x80000000
    je .bad
    mov edx, eax
    neg edx
    cmovs edx, eax
    mov eax, edx
    ret
.bad:
    xor eax, eax
    ret

range_setup:
    push esi
    push ebx
    push ebp
    mov esi, [cg_cur]
    call ts_cur_idx
    lea ebx, [eax + 1]
    mov [rg_lo], ebx
.scan:
    cmp ebx, [esi + S_PIECES]
    jae .scanned
    mov ecx, ebx
    call stmt_ptr
    mov ebp, eax
    inc ebx
    movzx edx, word [ebp + S_KIND]
    cmp edx, SK_FOR
    je .bad_var
    cmp edx, SK_INPUT
    je .bad_var
    cmp edx, SK_DECL
    je .assign
    cmp edx, SK_ASSIGN
    jne .scan
.assign:
    cmp word [ebp + S_MODE], TY_INT
    jne .scan
    mov ecx, [ebp + S_VAR]
    call rg_add
    mov edx, [rg_state]
    cmp dword [edx + ecx * 4], -2
    je .scan
    cmp dword [ebp + S_NPARTS], 0
    je .bad_var
    call rg_mod_of
    test eax, eax
    jz .bad_var
    mov edx, [rg_state]
    cmp [edx + ecx * 4], eax
    jae .scan
    mov [edx + ecx * 4], eax
    jmp .scan
.bad_var:
    mov ecx, [ebp + S_VAR]
    call rg_add
    mov edx, [rg_state]
    mov dword [edx + ecx * 4], -2
    jmp .scan
.scanned:
    xor ebx, ebx
.entry:
    cmp ebx, [rg_n]
    jae .entry_done
    mov edx, [rg_list]
    mov ecx, [edx + ebx * 4]
    inc ebx
    mov edx, [rg_state]
    mov eax, [edx + ecx * 4]
    cmp eax, 2
    jl .entry
    dec eax
    mov edx, [cg_kvok]
    cmp byte [edx + ecx], 0
    je .entry
    mov edx, [cg_kv]
    mov edx, [edx + ecx * 4]
    test edx, edx
    js .entry
    cmp edx, eax
    cmova eax, edx
    mov edx, [cg_vhi]
    mov [edx + ecx * 4], eax
    jmp .entry
.entry_done:
    cmp word [esi + S_KIND], SK_FOR
    jne .verify
    mov ecx, [esi + S_VAR]
    call for_aliasable
    test eax, eax
    jz .verify
    mov ecx, [esi + S_VAR]
    call rg_add
    mov edx, [rg_state]
    mov dword [edx + ecx * 4], -2
    mov eax, esi
    call stmt_root
    call node_addr
    mov edx, 0x7FFFFFFE
    cmp byte [eax + V_KIND], VK_INT
    jne .top_hi
    mov edx, [eax + V_DATA]
    test edx, edx
    jle .verify
.top_hi:
    mov ecx, [esi + S_VAR]
    mov eax, [cg_vhi]
    mov [eax + ecx * 4], edx
.verify:
    mov dword [rg_chg], 0
    mov ebx, [rg_lo]
.v_scan:
    cmp ebx, [esi + S_PIECES]
    jae .v_done
    mov ecx, ebx
    call stmt_ptr
    mov ebp, eax
    inc ebx
    movzx edx, word [ebp + S_KIND]
    cmp edx, SK_DECL
    je .v_assign
    cmp edx, SK_ASSIGN
    jne .v_scan
.v_assign:
    cmp word [ebp + S_MODE], TY_INT
    jne .v_scan
    mov ecx, [ebp + S_VAR]
    mov edx, [cg_vhi]
    cmp dword [edx + ecx * 4], 0
    jl .v_scan
    mov eax, ebp
    call stmt_root
    call node_addr
    mov ecx, [eax + V_DATA]
    call node_range
    test eax, eax
    jns .v_scan
    mov ecx, [ebp + S_VAR]
    mov edx, [cg_vhi]
    mov dword [edx + ecx * 4], -1
    mov dword [rg_chg], 1
    jmp .v_scan
.v_done:
    cmp dword [rg_chg], 0
    jne .verify
    cmp word [esi + S_KIND], SK_FOR
    jne .r
    mov ecx, [esi + S_VAR]
    mov edx, [cg_vhi]
    mov dword [edx + ecx * 4], -1
.r:
    pop ebp
    pop ebx
    pop esi
    ret

range_clear:
    mov ecx, [rg_n]
.l:
    test ecx, ecx
    jz .done
    dec ecx
    mov edx, [rg_list]
    mov eax, [edx + ecx * 4]
    mov edx, [rg_state]
    mov dword [edx + eax * 4], 0
    mov edx, [cg_vhi]
    mov dword [edx + eax * 4], -1
    jmp .l
.done:
    mov dword [rg_n], 0
    ret

af_leaf:
    push ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_CMP
    jne .no
    cmp byte [eax + V_TYPE], TY_INT
    jne .no
    movzx edx, byte [eax + V_NEG]
    mov ecx, [eax + V_DATA]
    mov ebx, [eax + V_DATA + 4]
    cmp edx, CMP_GT
    jne .gt_done
    xchg ecx, ebx
    mov edx, CMP_LT
.gt_done:
    cmp edx, CMP_LT
    je .lt
    cmp edx, CMP_IS
    jne .no
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .is_ord
    xchg ecx, ebx
.is_ord:
    push ecx
    mov ecx, ebx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_MOD
    jne .no
    mov ebx, [eax + V_DATA + 4]
    mov ecx, [eax + V_DATA]
    mov edx, [af_x]
    call ts_isvar
    test eax, eax
    jz .no
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    cmp eax, 0x80000000
    je .no
    cdq
    xor eax, edx
    sub eax, edx
    cmp eax, 2
    jb .no
    test eax, 1
    jnz .div_ok
    lea edx, [eax - 1]
    test edx, eax
    jnz .no
.div_ok:
    cmp dword [af_div], 0
    jne .no
    mov [af_div], eax
    jmp .yes
.lt:
    mov edx, [af_x]
    call ts_isvar
    test eax, eax
    jz .no
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    cmp dword [af_sign], 0
    jne .no
    mov dword [af_sign], 1
.yes:
    mov eax, 1
    pop ebx
    ret
.no:
    xor eax, eax
    pop ebx
    ret

af_lane:
    push eax
    BYTES 0xC869, 2
    mov edx, [af_A]
    call x86_imm32
    cmp dword [af_B], 0
    je .no_b
    BYTES 0xC181, 2
    mov edx, [af_B]
    call x86_imm32
.no_b:
    pop eax
    test eax, eax
    jz .not_last
    BYTES 0xC889, 2
.not_last:
    mov eax, [af_div]
    test eax, eax
    jz .sign_only
    test eax, 1
    jz .pow2
    BYTES 0xD169, 2
    mov edx, [af_inv]
    call x86_imm32
    cmp dword [af_sign], 0
    jne .cmp_t
    BYTES 0xC281, 2
    mov edx, [af_c1]
    call x86_imm32
.cmp_t:
    BYTES 0xFA81, 2
    mov edx, [af_t]
    call x86_imm32
    jmp .sbb
.pow2:
    BYTES 0xE281CA89, 4
    mov edx, [af_div]
    dec edx
    call x86_imm32
    BYTES 0x01FA83, 3
.sbb:
    BYTES 0xD219, 2
    cmp dword [af_sign], 0
    je .div_only
    BYTES 0x091FF9C1, 4
    BYTES 0xCA, 1
.div_only:
    BYTES 0xD529, 2
    ret
.sign_only:
    BYTES 0x291FF9C1, 4
    BYTES 0xCD, 1
    ret

try_affine:
    push esi
    push ebx
    push ebp
    mov esi, [cg_cur]
    movzx eax, word [esi + S_KIND]
    cmp eax, SK_FOR
    je .kind_ok
    cmp eax, SK_LOOPS
    jne .no
.kind_ok:
    call ts_loop_ok
    test eax, eax
    jz .no
    call ts_const_n
    test eax, eax
    jz .no
    mov dword [af_lv], -1
    cmp word [esi + S_KIND], SK_FOR
    jne .lv_set
    mov eax, [esi + S_VAR]
    mov [af_lv], eax
.lv_set:
    call ts_cur_idx
    lea ecx, [eax + 4]
    cmp [esi + S_PIECES], ecx
    jne .no
    cmp ecx, [g_nstmt]
    jae .no_else
    call stmt_ptr
    cmp word [eax + S_KIND], SK_ELSE
    je .no
.no_else:
    lea ebx, [esi + S_SIZE]
    cmp word [ebx + S_KIND], SK_ASSIGN
    jne .no
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    cmp dword [ebx + S_NPARTS], 0
    je .no
    mov eax, [ebx + S_VAR]
    mov [af_x], eax
    cmp eax, [af_lv]
    je .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    mov dword [af_b], 0
    movzx edx, byte [eax + V_NEG]
    cmp edx, OP_MUL
    je .mul
    mov ecx, [eax + V_DATA + 4]
    mov ebp, [eax + V_DATA]
    cmp edx, OP_SUB
    je .sub
    cmp edx, OP_ADD
    jne .no
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    je .b_set
    xchg ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
.b_set:
    mov eax, [eax + V_DATA]
    mov [af_b], eax
    jmp .mul_node
.sub:
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    neg eax
    mov [af_b], eax
.mul_node:
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_MUL
    jne .no
.mul:
    mov ecx, [eax + V_DATA]
    mov ebp, [eax + V_DATA + 4]
    mov edx, [af_x]
    call ts_isvar
    test eax, eax
    jnz .a_node
    xchg ecx, ebp
    mov edx, [af_x]
    call ts_isvar
    test eax, eax
    jz .no
.a_node:
    mov ecx, ebp
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    mov [af_a], eax
    add ebx, S_SIZE
    cmp word [ebx + S_KIND], SK_IF
    jne .no
    mov eax, [esi + S_PIECES]
    cmp [ebx + S_PIECES], eax
    jne .no
    mov dword [af_sign], 0
    mov dword [af_div], 0
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_OR
    jne .one_leaf
    push dword [eax + V_DATA + 4]
    mov ecx, [eax + V_DATA]
    call af_leaf
    pop ecx
    test eax, eax
    jz .no
.one_leaf:
    call af_leaf
    test eax, eax
    jz .no
    add ebx, S_SIZE
    cmp word [ebx + S_KIND], SK_ASSIGN
    jne .no
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    cmp dword [ebx + S_NPARTS], 0
    je .no
    mov ebp, [ebx + S_VAR]
    cmp ebp, [af_x]
    je .no
    cmp ebp, [af_lv]
    je .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    movzx edx, byte [eax + V_NEG]
    mov ecx, [eax + V_DATA]
    mov ebx, [eax + V_DATA + 4]
    cmp edx, OP_SUB
    je .k_sub
    cmp edx, OP_ADD
    jne .no
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jnz .k_node
    xchg ecx, ebx
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jz .no
.k_node:
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    jmp .k_set
.k_sub:
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jz .no
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    neg eax
.k_set:
    mov [af_k], eax
    mov [af_c], ebp
    mov ecx, [af_div]
    test ecx, 1
    jz .consts_done
    mov edx, ecx
    mov ebx, 4
.newton:
    mov eax, ecx
    imul eax, edx
    neg eax
    add eax, 2
    imul edx, eax
    dec ebx
    jnz .newton
    mov [af_inv], edx
    cmp dword [af_sign], 0
    je .signed_t
    mov eax, -1
    xor edx, edx
    div ecx
    inc eax
    mov [af_t], eax
    jmp .consts_done
.signed_t:
    mov eax, 0x7FFFFFFF
    xor edx, edx
    div ecx
    mov [af_c1], eax
    lea eax, [eax * 2 + 1]
    mov [af_t], eax
.consts_done:
    mov ecx, [af_x]
    call var_reg
    test eax, eax
    js .x_mem
    mov ecx, eax
    mov edx, R_EAX
    mov eax, 0x89
    call e_rr
    jmp .x_loaded
.x_mem:
    mov eax, [af_x]
    call var_abs_idx
    mov edx, eax
    OPA 0xA1, 1, edx
.x_loaded:
    BYTES 0xED3156, 3
    mov ebx, [ts_n]
    shr ebx, 2
    jz .tail
    BYTES 0xBE, 1
    mov edx, ebx
    call x86_imm32
    call x86_text_offset
    mov ebp, eax
    mov eax, [af_a]
    mov [af_A], eax
    mov eax, [af_b]
    mov [af_B], eax
    mov ebx, 1
.lane:
    xor eax, eax
    cmp ebx, 4
    jne .lane_emit
    inc eax
.lane_emit:
    call af_lane
    mov eax, [af_A]
    imul eax, [af_a]
    mov [af_A], eax
    mov eax, [af_B]
    imul eax, [af_a]
    add eax, [af_b]
    mov [af_B], eax
    inc ebx
    cmp ebx, 4
    jbe .lane
    BYTES 0x850F4E, 3
    mov ecx, ebp
    call emit_rel32_back
.tail:
    mov ebx, [ts_n]
    and ebx, 3
    jz .fin
    BYTES 0xBE, 1
    mov edx, ebx
    call x86_imm32
    call x86_text_offset
    mov ebp, eax
    mov eax, [af_a]
    mov [af_A], eax
    mov eax, [af_b]
    mov [af_B], eax
    mov eax, 1
    call af_lane
    BYTES 0x850F4E, 3
    mov ecx, ebp
    call emit_rel32_back
.fin:
    BYTES 0x5E, 1
    mov ecx, [af_x]
    call var_reg
    test eax, eax
    js .xs_mem
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0x89
    call e_rr
    jmp .xs_done
.xs_mem:
    mov eax, [af_x]
    call var_abs_idx
    mov edx, eax
    OPA 0xA3, 1, edx
.xs_done:
    mov edx, [af_k]
    test edx, edx
    jz .c_done
    cmp edx, 1
    je .add_c
    cmp edx, -1
    jne .k_mul
    BYTES 0xDDF7, 2
    jmp .add_c
.k_mul:
    BYTES 0xED69, 2
    mov edx, [af_k]
    call x86_imm32
.add_c:
    mov ecx, [af_c]
    call var_reg
    test eax, eax
    js .c_mem
    mov edx, eax
    mov ecx, 5
    mov eax, 0x01
    call e_rr
    jmp .c_done
.c_mem:
    mov eax, [af_c]
    call var_abs_idx
    mov edx, eax
    mov ecx, 5
    mov eax, 0x01
    call e_mr
.c_done:
    cmp word [esi + S_KIND], SK_FOR
    jne .skip
    call ts_done
    jmp .r
.skip:
    call ts_skip
    jmp .r
.no:
    xor eax, eax
.r:
    pop ebp
    pop ebx
    pop esi
    ret

ts_cur_idx:
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    ret

ts_loop_ok:
    xor eax, eax
    test word [esi + S_MODE], 1
    jnz .r
    cmp dword [esi + S_MODETOK], 0
    jne .r
    inc eax
.r:
    ret

ts_const_n:
    mov eax, esi
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov edx, [eax + V_DATA]
    mov [ts_n], edx
    test edx, edx
    jle .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

ts_isvar:
    push edx
    call node_addr
    pop edx
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    cmp [eax + V_DATA], edx
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

ts_aset:
    cmp word [ebx + S_KIND], SK_ASET
    jne .no
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    mov eax, [ebx + S_VAR]
    shl eax, 5
    add eax, [g_vars]
    cmp word [eax + VR_TYPE], TY_INT
    jne .no
    mov edx, [eax + VR_ALEN]
    mov [ts_alen], edx
    mov eax, [ebx + S_VAR]
    call var_abs_idx
    mov [ts_arr], eax
    mov dword [ts_k], 0
    mov eax, [ebx + S_PARTS]
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    mov [ts_ix], ecx
    cmp dword [ebx + S_NPARTS], 2
    jb .yes
    mov ecx, [edx + eax * 4 + 4]
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    mov [ts_k], eax
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

ts_setvar:
    push edx
    push ecx
    call var_reg
    pop ecx
    test eax, eax
    js .mem
    mov ecx, eax
    mov eax, 0xB8
    call emit_reg1
    pop edx
    jmp x86_imm32
.mem:
    mov eax, ecx
    call var_abs_idx
    mov edx, eax
    OPA 0x05C7, 2, edx
    pop edx
    jmp x86_imm32

ts_done:
    mov ecx, [esi + S_VAR]
    mov edx, [ts_n]
    call ts_setvar
ts_skip:
    cmp dword [cg_bdepth], 0
    jne .kv
    call kv_invalidate
.kv:
    mov eax, [esi + S_PIECES]
    dec eax
    shl eax, 5
    add eax, [g_stmts]
    mov [cg_cur], eax
    mov eax, 1
    ret

try_fill:
    push esi
    push ebx
    mov esi, [cg_cur]
    cmp word [esi + S_KIND], SK_FOR
    jne .no
    call ts_loop_ok
    test eax, eax
    jz .no
    call ts_const_n
    test eax, eax
    jz .no
    call ts_cur_idx
    add eax, 2
    cmp [esi + S_PIECES], eax
    jne .no
    lea ebx, [esi + S_SIZE]
    call ts_aset
    test eax, eax
    jz .no
    mov edx, [ts_n]
    cmp [ts_alen], edx
    jb .no
    mov ecx, [ts_ix]
    mov edx, [esi + S_VAR]
    call ts_isvar
    test eax, eax
    jz .no
    BYTES 0xBF57, 2
    mov edx, [ts_arr]
    call x86_imm32
    BYTES 0xB9, 1
    mov edx, [ts_n]
    call x86_imm32
    mov edx, [ts_k]
    test edx, edx
    jz .k0
    BYTES 0xB8, 1
    mov edx, [ts_k]
    call x86_imm32
    jmp .k_set
.k0:
    BYTES 0xC031, 2
.k_set:
    BYTES 0x5FABF3, 3
    call ts_done
    jmp .r
.no:
    xor eax, eax
.r:
    pop ebx
    pop esi
    ret

try_mark:
    push esi
    push ebx
    push ebp
    mov esi, [cg_cur]
    cmp word [esi + S_KIND], SK_LOOPS
    jne .no
    call ts_loop_ok
    test eax, eax
    jz .no
    call ts_cur_idx
    add eax, 3
    cmp [esi + S_PIECES], eax
    jne .no
    lea ebx, [esi + S_SIZE]
    call ts_aset
    test eax, eax
    jz .no
    mov ecx, [ts_ix]
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    mov ebp, [eax + V_DATA]
    mov [ts_p], ebp
    mov eax, [ebx + S_TOK]
    shl eax, 4
    add eax, [g_tokens]
    mov eax, [eax + T_LINE]
    mov [ts_line], eax
    add ebx, S_SIZE
    cmp word [ebx + S_KIND], SK_ASSIGN
    jne .no
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    cmp dword [ebx + S_NPARTS], 0
    je .no
    cmp [ebx + S_VAR], ebp
    jne .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_ADD
    jne .no
    mov ebx, [eax + V_DATA]
    mov ecx, [eax + V_DATA + 4]
    mov [ts_qn], ecx
    mov ecx, ebx
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jnz .q_ok
    mov ecx, [ts_qn]
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jz .no
    mov [ts_qn], ebx
.q_ok:
    mov ecx, [ts_qn]
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    cmp [eax + V_DATA], ebp
    je .no
    mov eax, esi
    call stmt_root
    call emit_expr
    BYTES 0x50, 1
    mov ecx, [ts_qn]
    call emit_expr
    BYTES 0x50, 1
    mov ecx, [ts_ix]
    call emit_expr
    BYTES 0x585AC189, 4
    BYTES 0x8E0FC085, 4
    call x86_text_offset
    mov [ts_jle], eax
    mov dword [edi], 0
    add edi, 4
    BYTES 0x0FFF688D, 4
    BYTES 0x1670EAAF, 4
    BYTES 0x1270CD01, 4
    BYTES 0xF98149, 3
    mov edx, [ts_alen]
    call x86_imm32
    BYTES 0x814D0973, 4
    BYTES 0xFD, 1
    mov edx, [ts_alen]
    call x86_imm32
    BYTES 0xBA0A72, 3
    mov edx, [ts_line]
    call x86_imm32
    CALL_RT RT_FN_INDEX
    BYTES 0x8D0C8D, 3
    mov edx, [ts_arr]
    call x86_imm32
    BYTES 0x01156C8D, 4
    BYTES 0x8302E2C1, 4
    BYTES 0x2C7204F8, 4
    mov ebx, 2
.l4:
    BYTES 0x01C7, 2
    mov edx, [ts_k]
    call x86_imm32
    BYTES 0x1104C7, 3
    mov edx, [ts_k]
    call x86_imm32
    BYTES 0x510C8D, 3
    dec ebx
    jnz .l4
    BYTES 0x8304E883, 4
    BYTES 0xD87304F8, 4
    BYTES 0x0B74C085, 4
    BYTES 0x01C7, 2
    mov edx, [ts_k]
    call x86_imm32
    BYTES 0x7548D101, 4
    BYTES 0xF5, 1
    mov ebp, [ts_p]
    mov ecx, ebp
    call var_reg
    test eax, eax
    js .p_mem
    mov edx, eax
    mov ecx, 5
    mov eax, 0x89
    call e_rr
    jmp .p_done
.p_mem:
    mov eax, ebp
    call var_abs_idx
    mov edx, eax
    mov ecx, 5
    mov eax, 0x89
    call e_mr
.p_done:
    call x86_text_offset
    mov edx, eax
    mov eax, [ts_jle]
    sub edx, eax
    sub edx, 4
    add eax, [x86_text_base]
    mov [eax], edx
    call ts_skip
    jmp .r
.no:
    xor eax, eax
.r:
    pop ebp
    pop ebx
    pop esi
    ret

try_count:
    push esi
    push ebx
    push ebp
    mov esi, [cg_cur]
    cmp word [esi + S_KIND], SK_FOR
    jne .no
    call ts_loop_ok
    test eax, eax
    jz .no
    call ts_const_n
    test eax, eax
    jz .no
    mov dword [ts_st], 1
    lea ebx, [esi + S_SIZE]
    cmp word [ebx + S_KIND], SK_IF
    jne .no
    call ts_cur_idx
    lea ecx, [eax + 3]
    cmp [esi + S_PIECES], ecx
    je .zero_if
    inc ecx
    cmp [esi + S_PIECES], ecx
    jne .no
    cmp [ebx + S_PIECES], ecx
    jne .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_CMP
    jne .no
    movzx ebp, byte [eax + V_NEG]
    push dword [eax + V_DATA + 4]
    mov ecx, [eax + V_DATA]
    mov edx, [esi + S_VAR]
    call ts_isvar
    pop ecx
    test eax, eax
    jz .no
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    cmp ebp, CMP_GE
    je .ge
    cmp ebp, CMP_GT
    jne .no
    cmp eax, [ts_n]
    jge .no
    inc eax
.ge:
    cmp eax, [ts_n]
    jg .no
    cmp eax, 1
    jl .guard_done
    mov [ts_st], eax
.guard_done:
    add ebx, S_SIZE
    cmp word [ebx + S_KIND], SK_IF
    jne .no
.zero_if:
    mov eax, [esi + S_PIECES]
    cmp [ebx + S_PIECES], eax
    jne .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_CMP
    jne .no
    cmp byte [eax + V_NEG], CMP_IS
    jne .no
    push dword [eax + V_DATA]
    mov ecx, [eax + V_DATA + 4]
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    call node_addr
    cmp byte [eax + V_KIND], VK_ELEM
    jne .no
    mov ebp, [eax + V_DATA]
    mov ecx, [eax + V_DATA + 4]
    mov edx, [esi + S_VAR]
    call ts_isvar
    test eax, eax
    jz .no
    mov eax, ebp
    shl eax, 5
    add eax, [g_vars]
    cmp word [eax + VR_TYPE], TY_INT
    jne .no
    mov edx, [eax + VR_ALEN]
    cmp edx, [ts_n]
    jb .no
    mov eax, ebp
    call var_abs_idx
    mov [ts_arr], eax
    add ebx, S_SIZE
    cmp word [ebx + S_KIND], SK_ASSIGN
    jne .no
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    cmp dword [ebx + S_NPARTS], 0
    je .no
    mov ebp, [ebx + S_VAR]
    cmp ebp, [esi + S_VAR]
    je .no
    mov eax, ebx
    call stmt_root
    call node_addr
    mov ebx, [eax + V_DATA + 4]
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_ADD
    jne .no
    mov ecx, [eax + V_DATA]
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jnz .one
    xchg ebx, ecx
    mov edx, ebp
    call ts_isvar
    test eax, eax
    jz .no
.one:
    mov ecx, ebx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 1
    jne .no
    BYTES 0xB9, 1
    mov edx, [ts_st]
    dec edx
    shl edx, 2
    add edx, [ts_arr]
    call x86_imm32
    mov ebx, [ts_n]
    sub ebx, [ts_st]
    inc ebx
    mov edx, ebx
    shr edx, 2
    jz .no_vec
    push edx
    BYTES 0xC0EF0F66, 4
    BYTES 0xC9EF0F66, 4
    BYTES 0xBA, 1
    pop edx
    call x86_imm32
    BYTES 0x116F0FF3, 4
    BYTES 0xD1760F66, 4
    BYTES 0xC2FA0F66, 4
    BYTES 0x4A10C183, 4
    BYTES 0x0F66EE75, 4
    BYTES 0x664EC870, 4
    BYTES 0x66C1FE0F, 4
    BYTES 0xB1C8700F, 4
    BYTES 0xC1FE0F66, 4
    BYTES 0xC07E0F66, 4
    jmp .rem
.no_vec:
    BYTES 0xC031, 2
.rem:
    and ebx, 3
    jz .add_c
    BYTES 0xBA, 1
    mov edx, ebx
    call x86_imm32
    BYTES 0x83013983, 4
    BYTES 0xC18300D0, 4
    BYTES 0xF4754A04, 4
.add_c:
    mov ecx, ebp
    call var_reg
    test eax, eax
    js .c_mem
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0x01
    call e_rr
    jmp .c_done
.c_mem:
    mov eax, ebp
    call var_abs_idx
    mov edx, eax
    mov ecx, R_EAX
    mov eax, 0x01
    call e_mr
.c_done:
    call ts_done
    jmp .r
.no:
    xor eax, eax
.r:
    pop ebp
    pop ebx
    pop esi
    ret

body_callfree:
    push ebx
    push esi
    push ebp
    mov ebx, [cg_cur]
    mov eax, ebx
    sub eax, [g_stmts]
    shr eax, 5
    lea esi, [eax + 1]
    mov ebp, [ebx + S_PIECES]
.l:
    cmp esi, ebp
    jae .yes
    mov ebx, esi
    shl ebx, 5
    add ebx, [g_stmts]
    inc esi
    movzx eax, word [ebx + S_KIND]
    cmp eax, SK_OUT
    je .no
    cmp eax, SK_INPUT
    je .no
    cmp eax, SK_ADECL
    je .no
    cmp eax, SK_ASET
    je .no
    mov ecx, [ebx + S_PARTS]
    mov edx, [g_roots]
    cmp eax, SK_IF
    je .cond
    cmp eax, SK_FOR
    je .expr
    cmp eax, SK_LOOPS
    je .expr
    cmp dword [ebx + S_NPARTS], 0
    je .l
    cmp word [ebx + S_MODE], TY_INT
    je .expr
    mov ecx, [edx + ecx * 4]
    call node_addr
    cmp byte [eax + V_KIND], VK_ELEM
    je .no
    jmp .l
.expr:
    mov ecx, [edx + ecx * 4]
    call expr_safe
    test eax, eax
    jz .no
    jmp .l
.cond:
    mov ecx, [edx + ecx * 4]
    call cond_leaves
    test eax, eax
    js .no
    jmp .l
.yes:
    mov eax, 1
    jmp .r
.no:
    xor eax, eax
.r:
    pop ebp
    pop esi
    pop ebx
    ret

expr_safe:
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_INT
    je .yes
    cmp edx, VK_VAR
    je .var
    cmp edx, VK_ELEM
    je .elem
    cmp edx, VK_EXPR
    jne .no
    movzx edx, byte [eax + V_NEG]
    cmp edx, OP_NEG
    je .left
    cmp edx, OP_DIV
    je .div
    cmp edx, OP_MOD
    jne .both
.div:
    push eax
    mov ecx, [eax + V_DATA + 4]
    call node_addr
    mov ecx, eax
    pop eax
    cmp byte [ecx + V_KIND], VK_INT
    jne .no
    mov edx, [ecx + V_DATA]
    add edx, 1
    cmp edx, 2
    jbe .no
.both:
    push eax
    mov ecx, [eax + V_DATA + 4]
    call expr_safe
    pop ecx
    test eax, eax
    jz .no
    mov eax, ecx
.left:
    mov ecx, [eax + V_DATA]
    jmp expr_safe
.var:
    mov edx, [eax + V_DATA]
    mov eax, [cg_vreg]
    test byte [eax + edx], 0x40
    jnz .yes
    mov dword [cg_bldata], 1
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret
.elem:
    push eax
    mov edx, [eax + V_DATA]
    shl edx, 5
    add edx, [g_vars]
    cmp word [edx + VR_TYPE], TY_INT
    jne .elem_no
    mov edx, [edx + VR_ALEN]
    mov ecx, [eax + V_DATA + 4]
    call idx_proven
    test eax, eax
    js .elem_no
    pop eax
    mov dword [cg_bldata], 1
    mov ecx, [eax + V_DATA + 4]
    jmp expr_safe
.elem_no:
    pop eax
    xor eax, eax
    ret

cond_leaves:
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_OR
    je .or
    cmp edx, VK_AND
    je .and
    cmp edx, VK_CMP
    jne .bad
    movzx edx, byte [eax + V_TYPE]
    cmp edx, TY_INT
    je .typed
    cmp edx, TY_BOOL
    jne .bad
.typed:
    push eax
    mov ecx, [eax + V_DATA]
    call expr_safe
    pop ecx
    test eax, eax
    jz .bad
    mov ecx, [ecx + V_DATA + 4]
    call expr_safe
    test eax, eax
    jz .bad
    mov eax, 1
    ret
.and:
    mov dword [cg_bland], 1
.or:
    push eax
    mov ecx, [eax + V_DATA]
    call cond_leaves
    pop ecx
    test eax, eax
    js .r
    push eax
    mov ecx, [ecx + V_DATA + 4]
    call cond_leaves
    pop ecx
    test eax, eax
    js .r
    add eax, ecx
.r:
    ret
.bad:
    mov eax, -1
    ret

bl_emit:
    push esi
    call node_addr
    mov esi, eax
    cmp byte [esi + V_KIND], VK_OR
    jne .leaf
    mov ecx, [esi + V_DATA]
    call bl_emit
    mov ecx, [esi + V_DATA + 4]
    call bl_emit
    pop esi
    ret
.leaf:
    call emit_compare
    add eax, 0x90
    shl eax, 8
    or eax, 0xC1000F
    mov ecx, 3
    call x86_bytes
    BYTES 0xC9B60F, 3
    mov eax, 0x09
    mov ecx, R_ECX
    mov edx, [cg_blacc]
    call e_rr
    pop esi
    ret

bl_sign:
    call node_addr
    cmp byte [eax + V_KIND], VK_CMP
    jne .no
    movzx edx, byte [eax + V_NEG]
    mov ecx, [eax + V_DATA]
    push ecx
    mov ecx, [eax + V_DATA + 4]
    pop eax
    cmp edx, CMP_LT
    je .lt
    cmp edx, CMP_GT
    jne .no
    xchg eax, ecx
.lt:
    mov [cg_tmp], eax
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    cmp dword [eax + V_DATA], 0
    jne .no
    mov ecx, [cg_tmp]
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    je .no
    cmp byte [eax + V_KIND], VK_VAR
    jne .expr
    push eax
    mov ecx, [eax + V_DATA]
    call var_reg
    mov ecx, eax
    pop eax
    test ecx, ecx
    js .mem
    lea eax, [ecx + 0xE0]
    shl eax, 16
    or eax, 0x1F00BA0F
    mov ecx, 4
    call x86_bytes
    mov eax, 1
    ret
.mem:
    call var_abs
    mov edx, eax
    OPA 0x25BA0F, 3, edx
    BYTES 0x1F, 1
    mov eax, 1
    ret
.expr:
    mov ecx, [cg_tmp]
    call emit_expr
    BYTES 0x1FE0BA0F, 4
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

try_branchless:
    push esi
    push ebx
    mov esi, [cg_cur]
    call temp_limit
    cmp [cg_depth], eax
    jae .no
    mov eax, esi
    sub eax, [g_stmts]
    shr eax, 5
    add eax, 2
    cmp [esi + S_PIECES], eax
    jne .no
    cmp eax, [g_nstmt]
    jae .no_else
    mov ecx, eax
    call stmt_ptr
    cmp word [eax + S_KIND], SK_ELSE
    je .no
.no_else:
    lea ebx, [esi + S_SIZE]
    movzx eax, word [ebx + S_KIND]
    cmp eax, SK_DECL
    je .body_kind
    cmp eax, SK_ASSIGN
    jne .no
.body_kind:
    cmp word [ebx + S_MODE], TY_INT
    jne .no
    cmp dword [ebx + S_NPARTS], 0
    je .no
    mov eax, ebx
    call stmt_root
    call node_addr
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    movzx edx, byte [eax + V_NEG]
    mov [cg_tmp + 4], edx
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    cmp dword [cg_tmp + 4], OP_SUB
    je .order_ok
    cmp dword [cg_tmp + 4], OP_ADD
    jne .no
    push ecx
    mov ecx, edx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    je .order_ok
    xchg ecx, edx
.order_ok:
    push edx
    call node_addr
    pop edx
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    mov eax, [eax + V_DATA]
    cmp eax, [ebx + S_VAR]
    jne .no
    mov [cg_blvar], eax
    mov ecx, edx
    call node_addr
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov eax, [eax + V_DATA]
    cmp dword [cg_tmp + 4], OP_SUB
    jne .k_ok
    neg eax
.k_ok:
    mov [cg_blk], eax
    mov eax, esi
    call stmt_root
    mov dword [cg_bldata], 0
    mov dword [cg_bland], 0
    push ecx
    call cond_leaves
    pop ecx
    test eax, eax
    jle .no
    cmp eax, 4
    ja .no
    cmp dword [cg_bldata], 0
    je .no
    cmp dword [cg_bland], 0
    jne .no
    mov eax, [cg_blvar]
    call var_abs_idx
    mov ebx, eax
    push ecx
    mov ecx, [cg_blvar]
    call prom_reg
    pop ecx
    mov [cg_blreg], eax
    mov eax, [cg_blk]
    lea edx, [eax + 1]
    cmp edx, 2
    ja .generic
    test eax, eax
    jz .generic
    push ecx
    call bl_sign
    pop ecx
    test eax, eax
    jz .generic
    mov edx, [cg_blreg]
    test edx, edx
    jns .carry_reg
    mov eax, 0x1583
    cmp dword [cg_blk], 1
    je .carry
    mov eax, 0x1D83
.carry:
    mov ecx, 2
    mov edx, ebx
    call x86_op_abs
    xor edx, edx
    call x86_imm8
    jmp .yes
.carry_reg:
    lea eax, [edx + 0xD0]
    cmp dword [cg_blk], 1
    je .carry_emit
    add eax, 8
.carry_emit:
    shl eax, 8
    or eax, 0x83
    mov ecx, 3
    call x86_bytes
    jmp .yes
.generic:
    call temp_reg
    mov [cg_blacc], eax
    push ecx
    mov ecx, eax
    mov edx, eax
    mov eax, 0x31
    call e_rr
    pop ecx
    inc dword [cg_depth]
    call bl_emit
    dec dword [cg_depth]
    mov eax, [cg_blk]
    cmp eax, 1
    je .add_acc
    cmp eax, -1
    je .sub_acc
    mov ecx, [cg_blacc]
    mov edx, ecx
    mov eax, 0x69
    call e_rr
    mov edx, [cg_blk]
    call x86_imm32
.add_acc:
    mov eax, 0x01
    jmp .apply
.sub_acc:
    mov eax, 0x29
.apply:
    mov ecx, [cg_blacc]
    mov edx, [cg_blreg]
    test edx, edx
    jns .apply_reg
    mov edx, ebx
    call e_mr
    jmp .yes
.apply_reg:
    call e_rr
.yes:
    mov eax, 1
    pop ebx
    pop esi
    ret
.no:
    xor eax, eax
    pop ebx
    pop esi
    ret

elem_addr:
    push esi
    push ebx
    push ebp
    mov eax, ecx
    shl eax, 5
    add eax, [g_vars]
    mov ebx, eax
    push edx
    movzx ecx, word [ebx + VR_TYPE]
    call elem_size
    mov esi, eax
    mov eax, [ebx + VR_OFF]
    add eax, [cg_vars]
    mov ebp, eax
    pop ecx
    push ecx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .dyn
    mov edx, [eax + V_DATA]
    dec edx
    imul edx, esi
    add edx, ebp
    BYTES 0xB9, 1
    call x86_imm32
    jmp .r
.dyn:
    push ecx
    mov edx, [ebx + VR_ALEN]
    call idx_proven
    pop ecx
    test eax, eax
    jns .proven
    call emit_expr
    BYTES 0xFF488D, 3
    BYTES 0xF981, 2
    mov edx, [ebx + VR_ALEN]
    call x86_imm32
    BYTES 0x0A72, 2
    BYTES 0xBA, 1
    mov edx, [cg_line]
    call x86_imm32
    CALL_RT RT_FN_INDEX
    cmp esi, 4
    je .s4
    cmp esi, 1
    je .s1
    BYTES 0x04E1C1, 3
.s1:
    BYTES 0xC181, 2
    mov edx, ebp
    call x86_imm32
    jmp .r
.s4:
    BYTES 0x8D0C8D, 3
    mov edx, ebp
    call x86_imm32
    jmp .r
.proven:
    mov edx, [ix_c]
    dec edx
    imul edx, esi
    add ebp, edx
    cmp esi, 16
    je .pv16
    shl eax, 3
    or eax, 5
    cmp esi, 4
    jne .pv_sib
    or eax, 0x80
.pv_sib:
    shl eax, 16
    or eax, 0x0C8D
    mov ecx, 3
    call x86_bytes
    mov edx, ebp
    call x86_imm32
    jmp .r
.pv16:
    mov ecx, eax
    mov edx, R_ECX
    mov eax, 0x89
    call e_rr
    BYTES 0x04E1C1, 3
    jmp .s1
.r:
    pop ebp
    pop ebx
    pop esi
    ret

idx_proven:
    push esi
    push ebx
    mov esi, edx
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jne .not_var
    xor ebx, ebx
    jmp .check
.not_var:
    cmp byte [eax + V_KIND], VK_EXPR
    jne .no
    cmp byte [eax + V_NEG], OP_ADD
    jne .no
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    push edx
    push ecx
    call node_addr
    pop ecx
    pop edx
    cmp byte [eax + V_KIND], VK_INT
    jne .right
    mov ebx, [eax + V_DATA]
    mov ecx, edx
    jmp .check
.right:
    push ecx
    mov ecx, edx
    call node_addr
    pop ecx
    cmp byte [eax + V_KIND], VK_INT
    jne .no
    mov ebx, [eax + V_DATA]
.check:
    cmp ebx, 0
    jl .no
    call node_addr
    cmp byte [eax + V_KIND], VK_VAR
    jne .no
    mov ecx, [eax + V_DATA]
    mov eax, [cg_vreg]
    test byte [eax + ecx], 0x40
    jz .no
    mov edx, [cg_bdepth]
.find:
    test edx, edx
    jz .no
    dec edx
    imul eax, edx, B_SIZE
    lea eax, [cg_bstack + eax]
    cmp dword [eax + B_KIND], BK_FOR
    jne .find
    cmp [eax + B_ALIAS], ecx
    jne .find
    cmp dword [eax + B_DYN], 0
    jne .no
    mov eax, [eax + B_LIMIT]
    add eax, ebx
    cmp eax, esi
    jg .no
    mov [ix_c], ebx
    call var_reg
    jmp .r
.no:
    mov eax, -1
.r:
    pop ebx
    pop esi
    ret

load_value:
    push esi
    push ebx
    mov ebx, ecx
    mov esi, edx
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp esi, TY_INT
    jne .not_int
    mov ecx, ebx
    call emit_expr
    jmp .r
.not_int:
    cmp edx, VK_ELEM
    jne .not_elem
    mov ecx, [eax + V_DATA]
    mov edx, [eax + V_DATA + 4]
    call elem_addr
    cmp esi, TY_BOOL
    jne .elem_str
    BYTES 0x01B60F, 3
    jmp .r
.elem_str:
    BYTES 0x0851B70F, 4
    BYTES 0x018B, 2
    jmp .r
.not_elem:
    cmp edx, VK_VAR
    jne .not_var
    call var_abs
    mov ebx, eax
    cmp esi, TY_BOOL
    jne .var_str
    OPA 0x05B60F, 3, ebx
    jmp .r
.var_str:
    OPA 0xA1, 1, ebx
    lea edx, [ebx + 8]
    OPA 0x15B70F, 3, edx
    jmp .r
.not_var:
    cmp esi, TY_BOOL
    jne .str_const
    mov ebx, [eax + V_DATA]
    BYTES 0xB8, 1
    mov edx, ebx
    call x86_imm32
    jmp .r
.str_const:
    cmp edx, VK_STR
    jne .null
    mov esi, [eax + V_DATA_HI]
    mov ebx, [eax + V_DATA]
    add ebx, [cg_pool]
    BYTES 0xB8, 1
    mov edx, ebx
    call x86_imm32
    BYTES 0xBA, 1
    mov edx, esi
    call x86_imm32
    jmp .r
.null:
    BYTES 0xD231C031, 4
.r:
    pop ebx
    pop esi
    ret

store_at_ecx:
    cmp edx, TY_INT
    jne .not_int
    BYTES 0x0189, 2
    ret
.not_int:
    cmp edx, TY_BOOL
    jne .str
    BYTES 0x0188, 2
    ret
.str:
    BYTES 0x0189, 2
    BYTES 0x08518966, 4
    ret

is_default:
    call node_addr
    movzx edx, byte [eax + V_KIND]
    cmp edx, VK_NULL
    je .yes
    cmp edx, VK_INT
    je .num
    cmp edx, VK_BOOL
    jne .no
.num:
    cmp dword [eax + V_DATA], 0
    je .yes
.no:
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

emit_aset:
    push esi
    push ebx
    push ebp
    mov esi, [cg_cur]
    mov eax, [esi + S_PARTS]
    mov edx, [g_roots]
    mov ebx, [edx + eax * 4 + 4]
    mov edx, [edx + eax * 4]
    movzx ebp, word [esi + S_MODE]
    mov ecx, [esi + S_VAR]
    call elem_addr
    cmp dword [esi + S_NPARTS], 2
    jb .zero
    mov ecx, ebx
    call node_addr
    movzx eax, byte [eax + V_KIND]
    cmp eax, VK_EXPR
    je .saved
    cmp eax, VK_ELEM
    je .saved
    mov ecx, ebx
    mov edx, ebp
    call load_value
    jmp .store
.saved:
    BYTES 0x51, 1
    mov ecx, ebx
    mov edx, ebp
    call load_value
    BYTES 0x59, 1
.store:
    mov edx, ebp
    call store_at_ecx
    jmp .r
.zero:
    cmp ebp, TY_INT
    jne .zero_not_int
    BYTES 0x01C7, 2
    xor edx, edx
    call x86_imm32
    jmp .r
.zero_not_int:
    cmp ebp, TY_BOOL
    jne .zero_str
    BYTES 0x0001C6, 3
    jmp .r
.zero_str:
    BYTES 0x01C7, 2
    xor edx, edx
    call x86_imm32
    BYTES 0x0841C766, 4
    xor edx, edx
    call x86_imm16
.r:
    pop ebp
    pop ebx
    pop esi
    ret

emit_adecl:
    push esi
    push ebx
    push ebp
    mov esi, [cg_cur]
    mov eax, [esi + S_VAR]
    shl eax, 5
    add eax, [g_vars]
    movzx ecx, word [eax + VR_TYPE]
    mov [ad_type], ecx
    call elem_size
    mov [ad_size], eax
    mov eax, [esi + S_VAR]
    call var_abs_idx
    mov ebp, eax
    cmp dword [esi + S_PIECES], 0
    jne .fill_value
    cmp dword [esi + S_NPIECES], 0
    je .values
    BYTES 0xD231C031, 4
    call .fill_loop
    jmp .values
.fill_value:
    mov eax, [esi + S_PARTS]
    mov edx, [g_roots]
    mov ebx, [edx + eax * 4]
    cmp dword [esi + S_NPIECES], 0
    jne .fill_emit
    mov ecx, ebx
    call is_default
    test eax, eax
    jnz .done
.fill_emit:
    mov ecx, ebx
    mov edx, [ad_type]
    call load_value
    call .fill_loop
    jmp .done
.values:
    xor ebx, ebx
.v_loop:
    cmp ebx, [esi + S_NPARTS]
    jae .done
    mov eax, [esi + S_PARTS]
    add eax, ebx
    mov edx, [g_roots]
    mov ecx, [edx + eax * 4]
    push ecx
    cmp dword [esi + S_NPIECES], 0
    jne .v_emit
    call is_default
    test eax, eax
    jnz .v_next
.v_emit:
    mov ecx, [esp]
    call node_addr
    mov edx, ebx
    imul edx, [ad_size]
    add edx, ebp
    movzx ecx, byte [eax + V_KIND]
    cmp ecx, VK_INT
    je .v_int
    cmp ecx, VK_BOOL
    je .v_bool
    mov ecx, [esp]
    mov edx, [ad_type]
    call load_value
    push edx
    BYTES 0xB9, 1
    mov edx, ebx
    imul edx, [ad_size]
    add edx, ebp
    call x86_imm32
    pop edx
    mov edx, [ad_type]
    call store_at_ecx
    jmp .v_next
.v_int:
    push dword [eax + V_DATA]
    OPA 0x05C7, 2, edx
    pop edx
    call x86_imm32
    jmp .v_next
.v_bool:
    push dword [eax + V_DATA]
    OPA 0x05C6, 2, edx
    pop edx
    call x86_imm8
.v_next:
    pop ecx
    inc ebx
    jmp .v_loop
.done:
    pop ebp
    pop ebx
    pop esi
    ret
.fill_loop:
    BYTES 0xB9, 1
    mov edx, ebp
    call x86_imm32
    mov edx, [ad_type]
    call store_at_ecx
    BYTES 0xC183, 2
    mov edx, [ad_size]
    call x86_imm8
    BYTES 0xF981, 2
    mov eax, [esi + S_VAR]
    shl eax, 5
    add eax, [g_vars]
    mov edx, [eax + VR_ALEN]
    imul edx, [ad_size]
    add edx, ebp
    call x86_imm32
    BYTES 0x72, 1
    mov edx, -13
    cmp dword [ad_type], TY_STR
    jne .fl_rel
    mov edx, -17
.fl_rel:
    jmp x86_imm8

section .rdata
temp_codes db 5, 7, 6
loop_regs  db 6, 7
prom_regs  db 3, 7
section .text
