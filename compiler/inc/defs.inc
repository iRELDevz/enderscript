bits 32

%define TK_EOF      0
%define TK_NL       1
%define TK_IDENT    2
%define TK_INT      3
%define TK_STR      4
%define TK_DOT      5
%define TK_EQ       6
%define TK_MINUS    7
%define TK_SHR      8
%define TK_LBRACE   9
%define TK_RBRACE   10
%define TK_PRINT    11
%define TK_SHOW     12
%define TK_KINT     13
%define TK_KSTR     14
%define TK_KBOOL    15
%define TK_TRUE     16
%define TK_FALSE    17
%define TK_NULL     18
%define TK_PLUS     19
%define TK_STAR     20
%define TK_SLASH    21
%define TK_PERCENT  22
%define TK_LPAREN   23
%define TK_RPAREN   24
%define TK_FNUM     25

%define T_KIND      0
%define T_COL       2
%define T_LINE      4
%define T_OFF       8
%define T_LEN       12
%define T_SIZE      16

%define TY_INT      1
%define TY_STR      2
%define TY_BOOL     3
%define TY_NULL     4

%define VK_INT      1
%define VK_STR      2
%define VK_BOOL     3
%define VK_NULL     4
%define VK_VAR      5
%define VK_EXPR     6

%define V_KIND      0
%define V_NEG       1
%define V_TYPE      2
%define V_BAD       3
%define V_TOK       4
%define V_DATA      8
%define V_DATA_HI   12
%define V_SIZE      16

%define SK_DECL     1
%define SK_ASSIGN   2
%define SK_OUT      3

%define S_KIND      0
%define S_MODE      2
%define S_TOK       4
%define S_VAR       8
%define S_NPARTS    12
%define S_PARTS     16
%define S_MODETOK   20
%define S_NPIECES   24
%define S_PIECES    28
%define S_SIZE      32

%define VR_HASH     0
%define VR_TOK      8
%define VR_TYPE     12
%define VR_OFF      16
%define VR_LINE     20
%define VR_SIZE     32

%define PK_TEXT     1
%define PK_INT      2
%define PK_BOOL     3
%define PK_STR      4
%define PK_EXPR     5

%define OP_ADD      1
%define OP_SUB      2
%define OP_MUL      3
%define OP_DIV      4
%define OP_MOD      5
%define OP_NEG      6

%define P_KIND      0
%define P_A         4
%define P_B         8
%define P_SIZE      16

%define NO_TOKEN    0xFFFFFFFF
%define NO_EXPR     0xFFFFFFFF
%define MAX_DEPTH   1000
%define MAX_NODES   2000

%define RT_OUT_LEN    0
%define RT_STDOUT     4
%define RT_WRITEFILE  8
%define RT_CONST      16
%define RT_WRITTEN    20
%define RT_GETSTD     24
%define RT_EXIT       28
%define RT_BUF        64
%define RT_BUF_SIZE   65536
%define RT_VARS       (RT_BUF + RT_BUF_SIZE)

%define RC_TRUE     0
%define RC_FALSE    4
%define RC_NULL     9
%define RC_SIZE     16

%define MAX_SOURCE  (16 * 1024 * 1024)

%define L(x) ebp - 12 - FRAME + x

%macro FUNC 1-2 0
global %1
%xdefine FRAME %2
%1:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
%if %2 > 0
    sub esp, %2
%endif
%endmacro

%macro ENDF 0
    lea esp, [ebp - 12]
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
%endmacro

%macro WINAPI 2
    extern __imp__%1@%2
    %define API_%1 __imp__%1@%2
%endmacro

%macro CALLAPI 1
    call [API_%1]
%endmacro
