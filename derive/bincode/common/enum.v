module common

import v.ast
import v.token
import codegen { Codegen }

// ```v
// len += bincode.len(self.b)
// ```
fn set_value_stmt_or_skip(mut cg Codegen, field ast.StructField) ast.Stmt {
	field_name := field.name
	typ := field.typ

	field_sel := ast.SelectorExpr{ // 'self.$field'
		field_name: field_name
		expr: cg.ident(ident_name_self)
		scope: cg.scope()
	}

// TODO: handle type here `array` `map` & ...
	right := get_type_recursively(mut cg, field, field_sel)

	return ast.AssignStmt{
		left: [cg.ident(ident_name_len)]
		right: [right]
		op: token.Kind.plus_assign
	}
}

// ```v
// bincode.len(self.b)
// ```
fn get_type_recursively(mut cg Codegen, field ast.StructField, sel ast.Expr) ast.Expr {
	return ast.CallExpr{
		name: 'len'
		left: cg.ident(mod_name)
		args: [
			ast.CallArg{
					expr: sel
				}
		]
		scope: cg.scope()
		is_method: true
	}
}