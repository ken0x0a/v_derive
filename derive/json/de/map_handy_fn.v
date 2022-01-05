module de

// import v.ast
// import v.token
// import codegen {Codegen}

// // [inline]
// // fn ${decode_json_pub_fn_prefix}__map__cb<T>(src string, cb fn(json2.Any) T) ?map[string]T {
// // 	decoded := json2.raw_decode(src) ?
// // 	return ${decode_json_fn_name}__map__cb<T>(decoded.as_map(), cb)
// // }
// fn impl_code_for_map_decode_path(mut self Codegen, depth int, typ ast.Type) {
// 	mut type_name := ''
// 	for _ in 1..depth {
// 		type_name += 'map[string]'
// 	}
// 	type_name += 'T'
// 	res_type := self.find_type_or_add_placeholder(type_name, .v)
// 	body_stmts := [
// 		ast.Stmt(ast.AssignStmt{
// 			left: [self.ident_opt('res', is_mut: true)]
// 			right: [
// 				ast.Expr(ast.MapInit{
// 					typ: res_type
// 				})
// 			]
// 			// op: token.Kind.assign
// 			op: token.Kind.decl_assign
// 			// op: token.Kind.and
// 		})
// 	]
// 	params := [
// 		ast.Param{ name: 'src', typ: ast.string_type }
// 		ast.Param{ name: 'cb', typ: self.find_type_or_add_placeholder('json2.Any', .v) }
// 	]
// 	fn_name := 'placeholder'
// 	self.add_fn(name: fn_name, return_type: res_type, body_stmts: body_stmts,
// 		params: params, comments: [self.gen_comment(text: 'generated by macro "$macro_name"')],
// 		attrs: [ast.Attr{name: 'inline'}]
// 	)
// }
// fn impl_code_for_map_depth_if_required(mut self Codegen, depth int, typ ast.Type) {
// 	for num in 1..depth {
// 		println('impl for depth $num')
// 		impl_code_for_map_decode_path(mut self, num, typ)
// 		if num == 1 {
// 			// [inline]
// 			// fn ${decode_json_fn_name}__map__cb<T>(src map[string]json2.Any, cb fn(json2.Any) ?T) ?map[string]T {
// 			// 	mut res := map[string]T{}
// 			// 	for key, val in src {
// 			// 		res[key] = cb(val) ?
// 			// 	}
// 			// 	return res
// 			// }
// 			fn_name := '${decode_json_fn_name}__map__cb'
// 			if fn_name !in self.table.fns {
// 				// self.table.fns[fn_name] = ...
// 				// self.table.find_or_register_fn_type()

// 				body_stmts := [
// 					ast.Stmt(ast.AssignStmt{
// 						left: [self.ident_opt('res', is_mut: true)]
// 						right: [
// 							ast.Expr(ast.MapInit{
// 								typ: typ // res_type
// 							})
// 						]
// 						// op: token.Kind.assign
// 						op: token.Kind.decl_assign
// 						// op: token.Kind.and
// 					})
// 					// ast.Stmt(ast.AssignStmt{
// 					// 	left: [self.ident(json2_map_name)]
// 					// 	right: [
// 					// 		ast.Expr(ast.CallExpr{
// 					// 			name: 'as_map'
// 					// 			left: self.ident('j')
// 					// 			scope: self.scope()
// 					// 			is_method: true
// 					// 		})
// 					// 	]
// 					// 	// op: token.Kind.assign
// 					// 	op: token.Kind.decl_assign
// 					// 	// op: token.Kind.and
// 					// })
// 					ast.ForInStmt{
// 						key_var: 'key'
// 						val_var: 'val'
// 						scope: self.scope()
// 						cond: self.ident('src')
// 						stmts: [
// 							ast.Stmt(ast.AssignStmt{
// 								left: [ast.Expr(ast.IndexExpr{
// 									index: self.ident('key')
// 									left: self.ident('res')
// 									or_expr: ast.OrExpr{ kind: .propagate } // ast.CastExpr('json2.Any')
// 								})]
// 								right: [
// 									ast.Expr(ast.CallExpr{
// 										name: 'cb'
// 										args: [ast.CallArg { expr: self.ident('val') }]
// 										scope: self.scope(), is_method: false
// 										or_block: ast.OrExpr{ kind: .propagate }
// 									})
// 								]
// 								// op: token.Kind.assign
// 								op: token.Kind.decl_assign
// 								// op: token.Kind.and
// 							})
// 						]
// 					}
// 				]

// 				// self.add_fn(name: fn_name, return_type: ast.ovoid_type, body_stmts: body_stmts,
// 				// 	params: params, comments: [self.gen_comment(text: 'generated by macro "$macro_name"')])
// 			}
// 		}
// 	}

// }