module deser_json

import v.ast
import v.token
import codegen { Codegen }

const issue_11563_if_guard_var_name = 'k'
// https://github.com/vlang/v/issues/11563

// params := if p := obj['params'] {
// 	a := macro_deser_json__map__param_spec(p) ?
// 	a
// } else {
// 	map[string]ParamSpec{}
// }
fn issue_11563__get_declaration_stmt_temp_var_for_map(mut self Codegen, decode_fn_name string, field_name string, js_field_name string, typ ast.Type, depth int) ast.Stmt {
	temp_ident := self.ident('a')
	return ast.AssignStmt {
		op: token.Kind.decl_assign
		left: [self.ident(field_name)]
		right: [ast.Expr(ast.IfExpr {
			branches: [
				ast.IfBranch {
					scope: self.scope()
					cond: ast.Expr(ast.IfGuardExpr{
						var_name: issue_11563_if_guard_var_name
						expr: ast.IndexExpr{
							index: self.string_literal(js_field_name)
							// left: self.ident(decode_json_fn_arg_name)
							left: self.ident(json2_map_name)
						}
					})
					stmts: [
						ast.Stmt(
							ast.AssignStmt{
								op: token.Kind.decl_assign
								left: [temp_ident]
								right: [ast.Expr(
									ast.CallExpr {
										name: decode_fn_name
										args: [ast.CallArg{
											expr: self.ident(issue_11563_if_guard_var_name)
										}]
										scope: self.scope()
										is_method: false // left: self.ident('j')
										or_block: ast.OrExpr{
											kind: .propagate
										}
									}
								)]
							}
						)
						ast.Stmt(
							ast.ExprStmt{
								expr: temp_ident
							}
						)
					]
				},
				ast.IfBranch{
					scope: self.scope()
					stmts: [ast.Stmt(ast.ExprStmt{
						expr: ast.MapInit{
							typ: typ
						}
					})]
				}
			]
			is_expr: false
			has_else: true
		})]
	}
}