module ser

import v.ast { Stmt, SumTypeDecl}
import v.token
import codegen { Codegen }
import common
import util

// ```v
// pub fn (self OneOf) bin_len() int {
// 	mut len := 0
// 	len += bincode.len_for<u8>()
// 	len += match self {
// 		ItemA { self.bin_len() }
// 		ItemB { self.bin_len() }
// 	}
// 	return len
// }
// ```
pub fn add_encode_fn_for_sumtype(mut cg Codegen, decl SumTypeDecl) {
	fn_name := common.fn_method_name_encode
	mut params := get_params(mut cg)

	mut body_stmts := []Stmt{cap: decl.variants.len + 5}
	body_stmts << base_assign_stmt(mut cg)
	body_stmts << plus_assign_sumtype_match(mut cg, decl)
	body_stmts << Stmt(ast.Return{
		exprs: [cg.ident(ident_name_encode_pos)]
	})

	cg.add_struct_method(
		struct_name: decl.name.split('.').last()
		is_mut: false
		name: fn_name
		return_type: ast.int_type
		body_stmts: body_stmts
		params: params
		comments: [
			cg.gen_comment(text: 'generated by macro "$macro_name"'),
		]
	)
}

// ```v
// len += match self {
// 	ItemA { self.bin_len() }
// 	ItemB { self.bin_len() }
// }
// ```
fn plus_assign_sumtype_match(mut cg Codegen, decl ast.SumTypeDecl) ast.Stmt {
	mut branches := []ast.MatchBranch{cap: decl.variants.len}
	for idx, var in decl.variants {
		sym := cg.table.sym(var.typ)
		dump(sym.info)
		branches << ast.MatchBranch{
			scope: cg.scope()
			exprs: [cg.ident(util.get_type_name_without_module(sym.name))]
			stmts: [
				ast.Stmt(ast.AssignStmt{
					left: [cg.ident(ident_name_encode_pos)]
					right: [ast.Expr(ast.UnsafeExpr{expr:ast.CallExpr{
						name: 'encode'
						left: cg.ident(common.mod_name)
						scope: cg.scope()
						is_method: true
						concrete_types: [ast.u8_type]
						args: [
							ast.CallArg {expr: cg.ident(ident_name_bytes), is_mut: true},
							ast.CallArg {expr: cg.integer_literal(idx + 1)}
						]
					}})]
					op: token.Kind.plus_assign
				}),
				ast.Stmt(ast.ExprStmt{
					expr: ast.UnsafeExpr{expr:ast.CallExpr{
						name: 'encode'
						left: cg.ident(common.mod_name)
						scope: cg.scope()
						is_method: true
						args: [
							ast.CallArg {expr: ast.IndexExpr{
									left: cg.ident(ident_name_bytes)
									index: ast.RangeExpr{has_low: true, low: cg.ident(ident_name_encode_pos)}
								}, is_mut: true},
							ast.CallArg {expr: cg.ident(common.ident_name_self)}
						]
					}}
				}),
			]
		}
	}
	right := ast.Expr(ast.MatchExpr{
		is_expr: true
		return_type: ast.string_type
		cond: cg.ident('self')
		branches: branches
	})
	return ast.AssignStmt{
		left: [cg.ident(ident_name_encode_pos)]
		right: [right]
		op: token.Kind.plus_assign
	}
}
