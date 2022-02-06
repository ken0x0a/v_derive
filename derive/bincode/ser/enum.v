module ser

import v.ast { EnumDecl, Stmt }
import v.token
import codegen { Codegen }
import common
import util {get_type_name_without_module}

// Enum value is always `int` => 4 bytes in Vlang
// Generates:
//
// ```v
// [inline]
// fn (self EnumName) bin_len() int {
// 	return 4
// }
// ```
pub fn add_encode_fn_for_enum(mut cg Codegen, decl EnumDecl) {
	fn_name := common.fn_method_name_encode
	params := get_params(mut cg)
	return_type := ast.int_type
	mut body_stmts := []Stmt{}

	body_stmts << Stmt(ast.Return{
		exprs: [
			ast.Expr(ast.UnsafeExpr {
				expr: ast.CallExpr{
					name: 'encode'
					left: cg.ident(common.mod_name)
					scope: cg.scope()
					is_method: true
					args: [
						ast.CallArg {
							expr: ast.CastExpr {
								typ: ast.int_type
								expr: cg.ident(common.ident_name_self)
							}
						}
					]
				}
			})
		]
	})
	cg.add_struct_method(
		struct_name: decl.name.split('.').last()
		is_mut: false
		name: fn_name
		return_type: return_type
		body_stmts: body_stmts
		params: params
		comments: [
			cg.gen_comment(text: 'generated by macro "$common.macro_name"'),
		]
	)
}
