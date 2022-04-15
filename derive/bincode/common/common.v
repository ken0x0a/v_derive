module common

import v.ast { EnumDecl, Stmt, StructDecl, SumTypeDecl }
import v.token
import codegen { Codegen }
import util { get_type_name_without_module }

pub const (
	macro_name                 = 'BinEncode'
	mod_name                   = 'bincode'
	const_str_0_bytes_for_len  = 'num_bytes_for_len'
	bytes_len_int              = 4
	fn_method_name_len         = 'bin_len'
	fn_method_name_encode      = 'bin_encode'
	fn_method_name_encode_self = 'bin_encode_self'
	fn_method_name_decode      = 'bin_decode'
	ident_name_len             = 'len'
	ident_name_self            = 'self'
)

pub fn get_fn_name_decode(name string) string {
	base := util.to_snake_case(get_type_name_without_module(name))
	return 'bin_decode__$base'
}

// ```v
// mut len := 0
// ```
fn base_assign_stmt(mut cg Codegen) Stmt {
	return Stmt(ast.AssignStmt{
		left: [cg.ident_opt(common.ident_name_len, is_mut: true)]
		right: [cg.integer_literal(0)]
		op: token.Kind.decl_assign
	})
}
