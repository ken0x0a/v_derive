module codegen

import v.ast

pub fn integer_literal_stmt(val int) ast.Stmt {
	return ast.ExprStmt{expr: ast.IntegerLiteral{val: val.str()}}
}
pub fn integer_literal(val int) ast.Expr {
	return ast.IntegerLiteral{val: val.str()}
}
pub fn string_literal_stmt(str string) ast.Stmt {
	return ast.ExprStmt{expr: ast.StringLiteral{val: str}}
}
pub fn string_literal(str string) ast.Expr {
	return ast.StringLiteral{val: str}
}
pub fn bool_literal_stmt(val bool) ast.Stmt {
	return ast.ExprStmt{expr: ast.BoolLiteral{val: val}}
}
pub fn bool_literal(val bool) ast.Expr {
	return ast.BoolLiteral{val: val}
}
