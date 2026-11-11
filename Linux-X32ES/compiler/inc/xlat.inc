extern vr8, vr9, vr10, vr11, vr12, vr13, vr14, vr15

%define LX(x) ebp - 28 - FRAME + x

%macro XFUNC 1-2 0
global %1
%xdefine FRAME %2
%1:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    push dword [vr12]
    push dword [vr13]
    push dword [vr14]
    push dword [vr15]
%if %2 > 0
    sub esp, %2
%endif
%endmacro

%macro XENDF 0
    lea esp, [ebp - 28]
    pop dword [vr15]
    pop dword [vr14]
    pop dword [vr13]
    pop dword [vr12]
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
%endmacro
