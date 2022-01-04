module de

import v.ast
import codegen { Codegen }

struct DeserJsonFn {
mut:
	gen Codegen [required]
	prepend_stmts []ast.Stmt // ISSUE: 11563
	// ↓↓↓ for debug ↓↓↓
	stmt ast.StructDecl
}
fn (mut self DeserJsonFn) gen() {
	stmt := self.stmt
	mut body_stmts := get_decode_json_base_stmts(mut self.gen)
	

	// ISSUE: 11563
	return_stmt := ast.Return{
		exprs: [
			ast.Expr(ast.StructInit{
				// typ: self.table.sym(self.table.type_idxs[stmt.name])
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
	type_self := self.gen.find_type_or_add_placeholder(get_struct_name_without_module(stmt.name), .v)
	mut params := [ast.Param{
		name: 'j'
		typ: self.gen.find_type_or_add_placeholder('json2.Any', .v)
	}]
	self.gen.add_fn(
		is_pub: true
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
	mut inst := DeserJsonFn{gen: self, stmt: stmt}
	inst.gen()
}

// ISSUE: 11563
fn (mut inst DeserJsonFn) gen_struct_init_field(field ast.StructField) ast.StructInitField {
	return ast.StructInitField{
		name: field.name
		expr: inst.get_assign_right_expr__fn(field)
	}
}

fn is_field_required(field &ast.StructField) bool {
	mut is_required := false
	for attr in field.attrs {
		if attr.name == 'required' {
			is_required = true
			break
		}
	}
	return is_required
}
fn (mut inst DeserJsonFn) get_assign_right_expr__fn(field ast.StructField) ast.Expr {
	field_name := field.name
	js_field_name := get_js_field_name(field)
	typ := field.typ // BUG? `u8` is not parsed properly => `def.u8`
	// if self.table.sym(typ).name.split('.').last() == 'u8' { panic("Don't use `u8` as it doesn't parsed properly") }
	is_required := is_field_required(&field)

	mut self := inst.gen
	// dump(ast.builtin_type_names.len)
	if !self.table.sym(typ).is_builtin() {
		type_sym := self.table.sym(typ)
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
			// type_arg := type_sym.name.split_nth(']', 2)[1]
			// type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			return get_deser_array_expr(mut self, typ, js_field_name)
			// ISSUE: currently, static method for struct is not allowed
			// return ast.Expr(ast.CallExpr{
			// 	name: decode_json_array_fn_name
			// 	args: [ast.CallArg{
			// 		expr: ast.CallExpr{
			// 			name: 'arr'
			// 			left: ast.IndexExpr{
			// 				index: self.string_literal(js_field_name)
			// 				left: self.ident(json2_map_name)
			// 				or_expr: ast.OrExpr{
			// 					kind: .block
			// 					stmts: [codegen.string_literal_stmt('')]
			// 				}
			// 			}
			// 			scope: self.scope()
			// 			is_method: true
			// 		}
			// 	}]
			// 	concrete_types: [type_arg_idx]
			// 	scope: self.scope()
			// 	is_method: false // left: self.ident('j')
			// 	or_block: ast.OrExpr{
			// 		kind: .propagate
			// 	}
			// })
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
	} else if field.attrs.contains(attr_json2_as) {
		// .${method_name_josn2}().${method_name_chain}()
		method_name_josn2 := field.attrs.filter(it.name == attr_json2_as)[0].arg
		method_name_chain := self.table.sym(typ).name
		return ast.Expr(ast.CallExpr{
			scope: self.scope()
			is_method: true
			name: method_name_chain
			left: ast.CallExpr{
				scope: self.scope()
				is_method: true
				name: method_name_josn2
				left: ast.IndexExpr{
					index: self.string_literal(js_field_name)
					left: self.ident(json2_map_name)
					or_expr: get_json2_map_index_or_expr(is_required, typ)
				}
			}
		})
	} else {
		method_name, cast_type := get_json2_method_name(typ)
		or_expr := get_json2_map_index_or_expr(is_required, typ)
		expr := ast.Expr(ast.CallExpr{
			name: method_name
			left: ast.IndexExpr{
				index: self.string_literal(js_field_name)
				left: self.ident(json2_map_name)
				or_expr: or_expr
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

fn get_json2_map_index_or_expr(is_required bool, typ ast.Type) ast.OrExpr {
	return if is_required {
		ast.OrExpr{
			kind: .propagate
		}
	} else {
		default_value := get_json2_default_value(typ)
		ast.OrExpr{
			kind: .block
			stmts: [default_value]
		}
	}
} 