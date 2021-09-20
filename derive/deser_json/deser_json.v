module deser_json

import v.ast
import v.token
import tool.codegen.util
import tool.codegen.codegen { Codegen }

const (
	json2_map_name            = 'obj'
	decode_json_pub_fn_prefix = 'deser_json'
	decode_json_member_name   = 'decode_json'
	decode_json_fn_name       = 'macro_deser_json'
	decode_json_map_fn_name   = 'macro_deser_json_map'
	decode_json_array_fn_name = 'macro_deser_json_array'
)

// generates
// ```vlang
// fn (mut self Struct) decode_json(j json2.Any) ? { ... }
// ```
pub fn add_decode_json(mut self Codegen, stmt ast.StructDecl) {
	// mut body_stmts := []ast.Stmt{}
	mut body_stmts := get_decode_json_base_stmts(mut self)
	for field in stmt.fields {
		js_field_name := get_js_field_name(field)
		body_stmts << set_field_stmt(mut self, field.name, js_field_name, field.typ)
	}
	mut params := [ast.Param{
		name: 'j'
		typ: self.find_type_or_add_placeholder('json2.Any', .v)
	}]
	self.add_struct_method(
		struct_name: stmt.name
		is_mut: true
		name: deser_json.decode_json_member_name
		return_type: ast.ovoid_type
		body_stmts: body_stmts
		params: params
		comments: [
			self.gen_comment(text: 'generated by macro "derive_Deser'),
			self.gen_comment(
				text: 'Example: $deser_json.decode_json_fn_name<${stmt.name.split('.').last()}>(text)'
			),
		]
	)
}

fn get_decode_json_base_stmts(mut self Codegen) []ast.Stmt {
	return [
		ast.Stmt(ast.AssignStmt{
		left: [self.ident(deser_json.json2_map_name)]
		right: [
			ast.Expr(ast.CallExpr{
			name: 'as_map'
			left: self.ident('j')
			scope: self.scope()
			is_method: true
		}),
		]
		// op: token.Kind.assign
		op: token.Kind.decl_assign
		// op: token.Kind.and
	}),
	]
}

fn set_field_stmt(mut self Codegen, field_name string, js_field_name string, typ ast.Type) ast.Stmt {
	return ast.AssignStmt{
		left: [
			ast.Expr(ast.SelectorExpr{ // 'self.field'
			field_name: field_name
			expr: self.ident('self')
			scope: self.scope()
		}),
		]
		right: [get_assign_right_expr(mut self, field_name, js_field_name, typ)]
		// op: token.Kind.assign
		op: token.Kind.assign
		// op: token.Kind.and
	}
}

fn get_assign_right_expr(mut self Codegen, field_name string, js_field_name string, typ ast.Type) ast.Expr {
	if typ > ast.builtin_type_names.len {
		type_sym := self.table.get_type_symbol(typ)
		if type_sym.name.starts_with('map[string]') {
			// map
			// type_arg := type_sym.name.split_nth(']', 2)[1]
			type_arg := type_sym.name[10..]
			type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			return ast.Expr(ast.CallExpr{
				name: deser_json.decode_json_map_fn_name
				args: [ast.CallArg{
					expr: ast.CallExpr{
						name: 'as_map'
						left: ast.IndexExpr{
							index: self.string_literal(js_field_name)
							left: self.ident(deser_json.json2_map_name)
							or_expr: ast.OrExpr{
								kind: .block
								stmts: [self.integer_literal_stmt(0)]
							} // ast.CastExpr('json2.Any')
						}
						scope: self.scope()
						is_method: true
					}
				}]
				concrete_types: [type_arg_idx]
				scope: self.scope()
				is_method: false // left: self.ident('j')
				or_block: ast.OrExpr{
					kind: .propagate
				}
			})
		} else if type_sym.name.starts_with('[') {
			// array
			type_arg := type_sym.name.split_nth(']', 2)[1]
			type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			return ast.Expr(ast.CallExpr{
				name: deser_json.decode_json_array_fn_name
				args: [ast.CallArg{
					expr: ast.CallExpr{
						name: 'arr'
						left: ast.IndexExpr{
							index: self.string_literal(js_field_name)
							left: self.ident(deser_json.json2_map_name)
							or_expr: ast.OrExpr{
								kind: .block
								stmts: [self.integer_literal_stmt(0)]
							}
						}
						scope: self.scope()
						is_method: true
					}
				}]
				concrete_types: [type_arg_idx]
				scope: self.scope()
				is_method: false // left: self.ident('j')
				or_block: ast.OrExpr{
					kind: .propagate
				}
			})
		}
		// else {
		// 'json'
		mut decode_fn_name := deser_json.decode_json_fn_name
		mut concrete_types := [typ]
		type_info := type_sym.info
		if type_info is ast.Enum {
			for attr in self.table.enum_decls[type_sym.name].attrs {
				if attr.name == 'deser_json_with' {
					decode_fn_name = attr.arg
					concrete_types.pop()
				}
			}
		}
		if type_info is ast.Struct {
			for attr in type_info.attrs {
				if attr.name == 'deser_json_with' {
					decode_fn_name = attr.arg
					concrete_types.pop()
				}
			}
		}
		return ast.Expr(ast.CallExpr{
			name: decode_fn_name
			args: [ast.CallArg{
				expr: ast.IndexExpr{
					index: self.string_literal(js_field_name)
					left: self.ident(deser_json.json2_map_name)
					or_expr: ast.OrExpr{
						kind: .block
						stmts: [self.integer_literal_stmt(0)]
					}
				}
			}]
			concrete_types: concrete_types
			scope: self.scope()
			is_method: false // left: self.ident('j')
			or_block: ast.OrExpr{
				kind: .propagate
			}
		})
		// }
	} else if typ == ast.array_type_idx {
		return ast.Expr(ast.EmptyExpr{}) // TODO:
	} else if typ == ast.map_type_idx {
		return ast.Expr(ast.EmptyExpr{}) // TODO:
	} else {
		method_name, cast_type := get_json2_method_name(typ)
		mut expr := ast.Expr(ast.CallExpr{
			name: method_name
			left: ast.IndexExpr{
				index: self.string_literal(js_field_name)
				left: self.ident(deser_json.json2_map_name)
				or_expr: ast.OrExpr{
					kind: .block
					stmts: [self.integer_literal_stmt(0)]
				}
			}
			scope: self.scope()
			is_method: true
		})
		if cast_type > 0 {
			return ast.CastExpr{
				typ: cast_type
				expr: expr
			}
		}
		return expr
	}
}

fn get_js_field_name(field ast.StructField) string {
	mut name := field.name
	for attr in field.attrs {
		if attr.name == 'json' {
			name = attr.arg
		}
		$if debug_attr ? {
			println(attr)
		}
	}
	return name
}
