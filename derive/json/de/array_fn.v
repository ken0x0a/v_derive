module de

import v.ast
import v.token
import codegen { Codegen }

fn get_array_depth_and_type_arg(type_name string) (int, string) {
	mut temp := type_name
	mut depth := 0
	for {
		if temp.starts_with('[') {
			depth += 1
			temp = temp.split_nth(']', 2)[1]
		} else {
			break
		}
	}
	return depth, temp
}
fn get_deser_array_expr_recursively(mut self Codegen, field ast.Expr, typ ast.Type) ast.Expr {
	dump('')
	panic('')
	return ast.empty_expr()
}

fn get_deser_array_expr(mut self Codegen, typ ast.Type, js_field_name string) ast.Expr {
	type_sym := self.table.sym(typ)
	depth, type_arg := get_array_depth_and_type_arg(type_sym.name)
	if depth != 1 {
		dump(type_arg)
		panic('depth: $depth')
	}
	// fn_name := get_decode_array_fn_name(type_arg, depth)
	fn_name := get_decode_fn_name(type_arg)
	elem_typ_sym := self.table.find_type(type_arg) or { panic(err) }
	// dump(elem_typ_sym.idx)
	// dump(ast.builtin_type_names.len)
	// map_fn_arg_expr := if elem_typ_sym.idx < ast.builtin_type_names.len {
	map_fn_arg_expr := if elem_typ_sym.is_builtin() {
		// self.table.type_idxs[type_arg]
		elem_typ := self.find_type_or_add_placeholder(type_arg, .v)
		method_name, cast_type := get_json2_method_name(elem_typ)
		expr := ast.Expr(ast.CallExpr{
			name: method_name
			left: self.ident('it')
			scope: self.scope()
			is_method: true
		})
		if cast_type > 0 {
			ast.Expr(ast.CastExpr{
				typ: cast_type
				expr: expr
			})
		} else {
			expr
		}
	} else {
		ast.Expr(ast.CallExpr{
			name: fn_name
			args: [
				// get_deser_array_expr_recursively(mut self, self.ident('it'), depth - 1)
				ast.CallArg{
					expr: self.ident('it')
				}
			]
			or_block: ast.OrExpr{ kind: .propagate }
			scope: self.scope()
		})
	}
	// expr := get_deser_array_expr_recursively(mut self, self.ident('it'), depth)
	return ast.Expr(
		// ast.CallExpr{
		// name: decode_json_array_fn_name
		// args: [ast.CallArg{
			ast.CallExpr{
				name: 'map'
				args: [ast.CallArg {
					is_mut: false
					share: .mut_t
					expr: map_fn_arg_expr
				}]
				// left: field
				scope: self.scope()
				is_method: true

				left: ast.CallExpr{
					name: 'arr'
					left: ast.IndexExpr{
						index: self.string_literal(js_field_name)
						left: self.ident(json2_map_name)
						or_expr: ast.OrExpr{
							kind: .block
							// stmts: []
							stmts: [ast.Stmt(ast.ExprStmt{expr:ast.ArrayInit{typ: self.find_type_or_add_placeholder('[]json2.Any', .v), elem_type: self.find_type_or_add_placeholder('json2.Any', .v)}})]
						}
					}
					scope: self.scope()
					is_method: true
				}
			}
		// 	}]
		// 	concrete_types: [type_arg_idx]
		// 	scope: self.scope()
		// 	is_method: false // left: self.ident('j')
		// 	or_block: ast.OrExpr{
		// 		kind: .propagate
		// 	}
		// }
	)
}
fn register_array_fn_if_not_exist(mut self Codegen, typ ast.Type, typ_arg string, fn_name string, depth int) {
	if fn_name in self.table.fns {
		eprintln('"$fn_name" is already registered')
	} else {
		typ_sym := self.table.sym(typ)
		body_stmts := [
			// obj := j.as_map()
			ast.Stmt(ast.AssignStmt{
				left: [self.ident(json2_map_name)]
				right: [ast.Expr(ast.CallExpr{
					name: 'as_map'
					left: self.ident(json2_any_param_name)
					scope: self.scope()
					is_method: true
				})]
				op: token.Kind.decl_assign // op: token.Kind.and // op: token.Kind.assign
			}),
			// 
			ast.Stmt(ast.AssignStmt{
				left: [self.ident_opt('res', is_mut: true)]
				right: [ast.Expr(ast.MapInit{
					typ: typ
				})]
				op: token.Kind.decl_assign // op: token.Kind.and // op: token.Kind.assign
			}),
			// ast.Stmt(ast.AssignStmt{
			// 	left: [self.ident(json2_map_name)]
			// 	right: [
			// 		ast.Expr(ast.CallExpr{
			// 			name: 'as_map'
			// 			left: self.ident('j')
			// 			scope: self.scope()
			// 			is_method: true
			// 		})
			// 	]
			// 	// op: token.Kind.assign
			// 	op: token.Kind.decl_assign
			// 	// op: token.Kind.and
			// })
			ast.ForInStmt{
				key_var: 'key'
				val_var: 'val'
				cond: self.ident(json2_map_name)
				scope: self.scope()
				stmts: [
					ast.Stmt(ast.AssignStmt{
					left: [
						ast.Expr(ast.IndexExpr{
							index: self.ident('key')
							left: self.ident('res')
						}),
					]
					right: [
						ast.Expr(ast.CallExpr{
							name: if depth == 1 {
								get_decode_fn_name(typ_arg)
							} else {
								get_decode_map_fn_name(typ_arg, depth - 1)
							}
							args: [ast.CallArg{
								expr: self.ident('val')
							}]
							scope: self.scope()
							is_method: false
							or_block: ast.OrExpr{
								kind: .propagate
							}
						}),
					]
					// op: token.Kind.assign
					op: token.Kind.assign
					// op: token.Kind.and
				}),
				]
			},
			ast.Return{
				exprs: [self.ident('res')]
			},
		]

		// return_type := self.find_type_or_add_placeholder(typ_sym.name, .v)
		return_type := typ.set_flag(.optional)
		$if debug_ast ? {
			dump(self.find_type_or_add_placeholder('map[string]json2.Any', .v))
			dump(typ)
		}
		params := [ast.Param{
			name: json2_any_param_name
			typ: self.find_type_or_add_placeholder('json2.Any', .v)
		}]

		// ## Register to table
		fn_def := ast.Fn{
			name: fn_name
			params: params
			return_type: return_type
		}
		// self.table.fns[fn_name] = fn_def

		self.add_fn(
			name: fn_name
			return_type: return_type
			body_stmts: body_stmts
			params: params
			comments: [self.gen_comment(text: 'generated by macro "derive_Deser')]
		)
		self.table.find_or_register_fn_type(typ_sym.mod, fn_def, false, true)
	}
}
