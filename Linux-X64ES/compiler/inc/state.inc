%macro IMPORT 1
%ifndef OWN_%1
extern %1
%endif
%endmacro

IMPORT g_src
IMPORT g_src_len
IMPORT g_file
IMPORT g_hout
IMPORT g_herr
IMPORT g_tokens
IMPORT g_ntok
IMPORT g_stmts
IMPORT g_nstmt
IMPORT g_parts
IMPORT g_nparts
IMPORT g_roots
IMPORT g_nroots
IMPORT g_pieces
IMPORT g_npieces
IMPORT g_vars
IMPORT g_nvars
IMPORT g_htab
IMPORT g_hmask
IMPORT g_pool
IMPORT g_pool_len
IMPORT g_vars_size
IMPORT mem_alloc
IMPORT write_out
IMPORT write_err
IMPORT write_outz
IMPORT write_errz
IMPORT zlen
IMPORT sys_exit
IMPORT msg_reset
IMPORT msg_add
IMPORT msg_addz
IMPORT msg_addu
IMPORT msg_addc
IMPORT msg_tok
IMPORT diag_error_tok
IMPORT diag_error_at
IMPORT diag_warn_tok
IMPORT fatal
IMPORT fatal_path
