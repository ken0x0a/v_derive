module codegen

import v.ast

pub fn integer_literal_stmt<T>(val T) ast.Stmt {
	return ast.ExprStmt{
		expr: integer_literal<T>(val)
	}
}

pub fn integer_literal<T>(val T) ast.Expr {
	return ast.IntegerLiteral{
		val: val.str()
	}
}

pub fn float_literal_stmt(val f64) ast.Stmt {
	return ast.ExprStmt{
		expr: float_literal(val)
	}
}

pub fn float_literal(val f64) ast.Expr {
	return ast.FloatLiteral{
		val: val.strlong()
	}
}

pub fn string_literal_stmt(str string) ast.Stmt {
	return ast.ExprStmt{
		expr: string_literal(str)
	}
}

pub fn string_literal(str string) ast.Expr {
	return ast.StringLiteral{
		val: str
	}
}

pub fn bool_literal_stmt(val bool) ast.Stmt {
	return ast.ExprStmt{
		expr: bool_literal(val)
	}
}

pub fn bool_literal(val bool) ast.Expr {
	return ast.BoolLiteral{
		val: val
	}
}

// ```vlang
// self.scope_into_child()
// self.parse_stmt('v := 1')
// self.parse_stmt('res := call(v)')
// self.scope_into_parent()
// ```
pub fn (mut self Codegen) parse_stmt(code string) ast.Stmt {
	return parse_stmt(code, self.table, self.scope)
}

pub fn (mut self Codegen) parse_stmts(code string) []ast.Stmt {
	stmt := parse_stmt('{\n$code\n}', self.table, self.scope)
	if stmt is ast.Block {
		return stmt.stmts
	} else {
		return []
	}
}

// get `[]` as Expr
pub fn array_init_void() ast.Expr {
	return ast.ArrayInit{
		typ: ast.void_type
		elem_type: ast.void_type
	}
}

// get `[]` as Stmt
pub fn array_init_void_stmt() ast.Stmt {
	return ast.Stmt(ast.ExprStmt{
		expr: array_init_void()
	})
}
