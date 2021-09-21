module deser_json

import v.ast
import tool.codegen.codegen { Codegen }

struct DeserJsonFn {
mut:
	gen Codegen [required]
	prepend_stmts []ast.Stmt // ISSUE: 11563
}
fn (mut self DeserJsonFn) gen(stmt ast.StructDecl) {
	mut body_stmts := get_decode_json_base_stmts(mut self.gen)

	// ISSUE: 11563
	return_stmt := ast.Return{
		exprs: [
			ast.Expr(ast.StructInit{
				// typ: self.table.get_type_symbol(self.table.type_idxs[stmt.name])
				typ: self.gen.find_type_or_add_placeholder(stmt.name, .v)
				fields: stmt.fields.map(self.gen_struct_init_field(it))
				// fields: [
				// 	ast.StructInitField{
				// 		name: 'field_name'
				// 		expr: self.string_literal('a')
				// 	}
				// ]
			}),
		]
	}
	for pre_stmt in self.prepend_stmts {
		body_stmts << pre_stmt
	}
	body_stmts << return_stmt
	type_self := self.gen.find_type_or_add_placeholder(stmt.name, .v)
	mut params := [ast.Param{
		name: 'j'
		typ: self.gen.find_type_or_add_placeholder('json2.Any', .v)
	}]
	self.gen.add_fn(
		name: get_decode_fn_name(stmt.name)
		return_type: type_self.set_flag(.optional)
		body_stmts: body_stmts
		params: params
		comments: [
			self.gen.gen_comment(text: 'generated by macro "derive_Deser'),
			self.gen.gen_comment(
				text: 'Example: $decode_json_fn_name<${stmt.name.split('.').last()}>(text)'
			),
		]
	)
}

// generates
// ```vlang
// fn macro_decode_json__my_struct_name(j json2.Any) ?MyStructName { ... }
// ```
pub fn add_decode_json_fn(mut self Codegen, stmt ast.StructDecl) {
	mut inst := DeserJsonFn{gen: self}
	inst.gen(stmt)
}

// ISSUE: 11563
fn (mut inst DeserJsonFn) gen_struct_init_field(field ast.StructField) ast.StructInitField {
	return ast.StructInitField{
		name: field.name
		expr: inst.get_assign_right_expr__fn(field.name, get_js_field_name(field),
			field.typ)
	}
}

fn (mut inst DeserJsonFn) get_assign_right_expr__fn(field_name string, js_field_name string, typ ast.Type) ast.Expr {
	mut self := inst.gen
	if typ > ast.builtin_type_names.len {
		type_sym := self.table.get_type_symbol(typ)
		map_depth := get_map_depth(type_sym.name)
		if map_depth > 0 {
			// impl_code_for_map_depth_if_required(depth, typ)
			// map
			// type_arg := type_sym.name.split_nth(']', 2)[1]
			type_arg := type_sym.name[10 * map_depth..]
			// type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			// fn_name := '${get_decode_fn_name(stmt.name)}'
			fn_name := get_decode_map_fn_name(type_arg, map_depth)
			register_map_fn_if_not_exist(mut self, typ, type_arg, fn_name, map_depth)
			inst.prepend_stmts << issue_11563__get_declaration_stmt_temp_var_for_map(mut self, fn_name, field_name, js_field_name, typ, map_depth)// ISSUE: 11563
			return self.ident(field_name) // ISSUE: 11563
			// ISSUE: 11563
			/*
			return ast.Expr(ast.CallExpr{
				name: fn_name
				args: [ast.CallArg{
					expr: ast.CallExpr{
						name: 'as_map'
						left: ast.IndexExpr{
							index: self.string_literal(js_field_name)
							left: self.ident(json2_map_name)
							or_expr: ast.OrExpr{
								kind: .block
								stmts: [codegen.string_literal_stmt('')]
							} // ast.CastExpr('json2.Any')
						}
						scope: self.scope()
						is_method: true
					}
				}]
				// concrete_types: [type_arg_idx]
				scope: self.scope()
				is_method: false // left: self.ident('j')
				or_block: ast.OrExpr{
					kind: .propagate
				}
			})
			*/
		} else if type_sym.name.starts_with('[') {
			// array
			type_arg := type_sym.name.split_nth(']', 2)[1]
			type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			dump(type_arg_idx)
			return ast.Expr(ast.CallExpr{
				name: decode_json_array_fn_name
				args: [ast.CallArg{
					expr: ast.CallExpr{
						name: 'arr'
						left: ast.IndexExpr{
							index: self.string_literal(js_field_name)
							left: self.ident(json2_map_name)
							or_expr: ast.OrExpr{
								kind: .block
								stmts: [codegen.string_literal_stmt('')]
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
		mut decode_fn_name := get_decode_fn_name(type_sym.name)
		// mut concrete_types := [typ]
		type_info := type_sym.info
		if type_info is ast.Enum {
			for attr in self.table.enum_decls[type_sym.name].attrs {
				if attr.name == 'deser_json_with' {
					decode_fn_name = attr.arg
					// concrete_types.pop()
				}
			}
		}
		if type_info is ast.Struct {
			for attr in type_info.attrs {
				if attr.name == 'deser_json_with' {
					decode_fn_name = attr.arg
					// concrete_types.pop()
				}
			}
		}
		// if type_info is ast.SumType {
		// 	for attr in type_info.attrs {
		// 		if attr.name == 'deser_json_with' {
		// 			decode_fn_name = attr.arg
		// 			// concrete_types.pop()
		// 		}
		// 	}
		// }
		return ast.Expr(ast.CallExpr{
			name: decode_fn_name
			args: [ast.CallArg{
				expr: ast.IndexExpr{
					index: self.string_literal(js_field_name)
					left: self.ident(json2_map_name)
					or_expr: ast.OrExpr{
						kind: .block
						stmts: [codegen.string_literal_stmt('')]
					}
				}
			}]
			// concrete_types: concrete_types
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
		default_value := get_json2_default_value(typ)
		expr := ast.Expr(ast.CallExpr{
			name: method_name
			left: ast.IndexExpr{
				index: self.string_literal(js_field_name)
				left: self.ident(json2_map_name)
				or_expr: ast.OrExpr{
					kind: .block
					stmts: [default_value]
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
