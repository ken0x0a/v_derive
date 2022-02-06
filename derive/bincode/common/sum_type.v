module common

import v.ast
import v.token
import codegen { Codegen }
import util

// ```v
// len += bincode.len_for<byte>()
// ```
fn plus_assign_sumtype_type(mut cg Codegen) ast.Stmt {
	right := ast.Expr(ast.CallExpr{
		name: 'len_for'
		concrete_types: [ast.byte_type]
		left: cg.ident(mod_name)
		scope: cg.scope()
		is_method: true
	})
	return ast.AssignStmt{
		left: [cg.ident(ident_name_len)]
		right: [right]
		op: token.Kind.plus_assign
	}
}

// ```v
// len += match self {
// 	ItemA { self.bin_len() }
// 	ItemB { self.bin_len() }
// }
// ```
fn plus_assign_sumtype_match(mut cg Codegen, decl ast.SumTypeDecl) ast.Stmt {
	mut branches := []ast.MatchBranch{cap: decl.variants.len}
	for var in decl.variants {
		sym := cg.table.sym(var.typ)
		dump(sym.info)
		branches << ast.MatchBranch{
			scope: cg.scope()
			exprs: [cg.ident(util.get_type_name_without_module(sym.name))]
			stmts: [
				ast.Stmt(ast.ExprStmt{
					expr: ast.CallExpr{
						name: fn_method_name_len
						left: cg.ident(ident_name_self)
						scope: cg.scope()
						is_method: true
					}
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
		left: [cg.ident(ident_name_len)]
		right: [right]
		op: token.Kind.plus_assign
	}
}
