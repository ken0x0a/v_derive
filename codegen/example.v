module codegen

import v.ast
import v.token

pub fn (mut self Codegen) gen_fn_example(name string) ast.Stmt {
	mut body_stmts := []ast.Stmt{}
	mut right := []ast.Expr{}
	right << ast.StringLiteral{
		val: 'example'
		is_raw: true
		language: .v
		// pos      token.Position
	}
	body_stmts << ast.AssignStmt{
		left: [self.ident('a')]
		right: right
		// op: token.Kind.assign
		op: token.Kind.decl_assign
		// op: token.Kind.and
	}
	body_stmts << ast.AssignStmt{
		left: [self.ident('bool_op')]
		right: [
			ast.Expr(ast.InfixExpr{
				op: token.Kind.and
				left: ast.ParExpr{
					expr: ast.IntegerLiteral{
						val: '1'
					}
				}
				right: ast.ParExpr{
					// expr: ast.FloatLiteral {
					expr: ast.IntegerLiteral{
						val: '1.1'
					}
				}
			}),
		]
		// op: token.Kind.assign
		op: token.Kind.decl_assign
		// op: token.Kind.and
	}
	return self.gen_fn(
		name: name
		return_type: ast.string_type
		body_stmts: body_stmts
		comments: [
			ast.Comment{
				text: '\u0001 this is my comment\n'
				is_multi: true
				is_inline: true
			},
		]
		params: []
	)
}
