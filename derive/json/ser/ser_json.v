module ser

import v.ast
import v.token
import term
import codegen { Codegen }

pub const (
	macro_name           = 'SerJson'
	attr_json2_as        = 'ser_json_as'
	attr_skip_if_default = 'ser_json_skip_if_default'
)

const (
	json2_map_name            = 'obj'
	json2_any_param_name      = 'j'
	encode_json_member_name   = 'to_json'
	encode_json_fn_name       = 'macro_ser_json'
	encode_json_fn_arg_name   = 'src'
	encode_json_map_fn_name   = 'macro_ser_json_map'
	encode_json_array_fn_name = 'macro_ser_json_array'
)

// generates
// ```vlang
// fn (self &Struct) to_json() json2.Any {
// 	mut obj := map[string]json2.Any{}
// 	obj['name'] = self.name
// 	obj['f64_val'] = f64(self.f64_val).str().trim_right('.') // as str
// 	return obj
// }
// ```
pub fn add_encode_json(mut self Codegen, stmt ast.StructDecl) {
	// mut body_stmts := []ast.Stmt{}
	mut body_stmts := get_encode_json_base_stmts(mut self)
	for field in stmt.fields {
		body_stmts << set_value_stmt_or_skip(mut self, field)
	}
	for embed in stmt.embeds {
		type_sym := self.table.final_sym(embed.typ)
		match type_sym.info {
			ast.Struct {
				struct_def := type_sym.info
				for field in struct_def.fields {
					body_stmts << set_value_stmt_or_skip(mut self, field)
				}
			}
			else {
				panic('${type_sym.info.type_name()} is not supported yet!')
			}
		}
	}
	body_stmts << ast.Stmt(ast.Return{
		exprs: [self.ident(json2_map_name)]
	})

	// t_j2map := self.find_type_or_add_placeholder('map[string]json2.Any', .v)
	t_j2any := self.find_type_or_add_placeholder('json2.Any', .v)

	self.add_struct_method(
		struct_name: stmt.name.split('.').last()
		is_mut: false
		name: ser.encode_json_member_name
		return_type: t_j2any
		body_stmts: body_stmts
		params: []
		comments: [
			self.gen_comment(text: 'generated by macro "$macro_name"'),
			self.gen_comment(
				text: 'Example: ${ser.encode_json_fn_name}()'
			),
		]
	)
}

// mut obj := map[string]json2.Any{}
fn get_encode_json_base_stmts(mut self Codegen) []ast.Stmt {
	return [
		ast.Stmt(ast.AssignStmt{
			left: [self.ident_opt(ser.json2_map_name, is_mut: true)]
			right: [
				ast.Expr(ast.MapInit{
				typ: self.find_type_or_add_placeholder('map[string]json2.Any', .v)
			})]
			op: token.Kind.decl_assign
		}),
	]
}

// ISSUE: https://github.com/vlang/v/issues/6717
// I should use optional field when it will be available
pub fn ser_json_should_skip(self Codegen, field ast.StructField) bool {
	if field.attrs.contains(attr_skip_if_default) {
		if field.default_expr is ast.EmptyExpr {
			// dump(field)
			if !self.table.sym(field.typ).is_builtin() {
				dump(field.name)
				$if print_issue ? {
					eprintln('ISSUE: optional field! $field.name')
				}
				// panic('$field.name has attr `$attr_skip_if_default` but has no default_expr!!')
				return false // FIXME: optional field is not implemented yet. Walkaround would be add skip_variant for Enum
			}
		}
		return true
	}
	return false
}

pub fn ser_json_get_default_expr(typ ast.Type) ast.Expr {
	// if self.table.sym(typ).is_builtin() {
	if int(typ) > ast.builtin_type_names.len - 1 {
		if typ != ast.usize_type {
			dump(typ)
			// ts := self.table.sym(typ)
			// dump(ts.name)
			// dump(ts.info)
			panic('typ should be builtin type')
		}
	}
	match typ {
		ast.i8_type {
			return codegen.integer_literal(i8(0))
		}
		ast.i16_type {
			return codegen.integer_literal(i16(0))
		}
		ast.int_type {
			return codegen.integer_literal(int(0))
		}
		ast.i64_type {
			return codegen.integer_literal(i64(0))
		}
		ast.isize_type {
			return codegen.integer_literal(isize(0))
		}
		ast.u8_type {
			return codegen.integer_literal(byte(0))
		}
		ast.u16_type {
			return codegen.integer_literal(u16(0))
		}
		ast.u32_type {
			return codegen.integer_literal(u32(0))
		}
		ast.u64_type {
			return codegen.integer_literal(u64(0))
		}
		ast.usize_type {
			return codegen.integer_literal(usize(0))
		}
		ast.f32_type {
			return codegen.float_literal(0.0)
		}
		ast.f64_type {
			return codegen.float_literal(0.0)
		}
		ast.bool_type {
			return codegen.bool_literal(false)
		}
		ast.string_type {
			return codegen.string_literal('')
		}
		else {
			panic('unsupported builtin type')
		}
	}
}

// ```v
// obj['js_field_name'] = self.field_name
// ```
fn set_value_stmt_or_skip(mut self Codegen, field ast.StructField) ast.Stmt {
	field_name := field.name
	js_field_name := get_js_field_name(field)
	typ := field.typ

	field_sel := ast.SelectorExpr{ // 'self.field'
		field_name: field_name
		expr: self.ident('self')
		scope: self.scope()
	}

	right := get_type_recursively(mut self, field, field_sel, typ)

	assign_stmt := ast.AssignStmt{
		left: [
			ast.Expr(ast.IndexExpr{
				index: self.string_literal(js_field_name)
				left: self.ident(ser.json2_map_name)
			}),
		]
		right: [right]
		op: token.Kind.assign
	}
	if !ser_json_should_skip(self, field) {
		return assign_stmt
	}

	default_expr := if field.default_expr is ast.EmptyExpr {
		ser_json_get_default_expr(field.typ)
	} else {
		field.default_expr
	}
	if_expr := ast.IfExpr{
		branches: [
			ast.IfBranch{
				scope: self.scope()
				// if status == 0 {
				cond: ast.Expr(ast.InfixExpr{
					op: token.Kind.ne
					left: field_sel
					right: default_expr
				})
				stmts: [ast.Stmt(assign_stmt)]
			},
		]
		is_expr: false
		has_else: false
	}
	return ast.ExprStmt{
		expr: if_expr
	}
}

fn get_type_recursively_builtin(mut self Codegen, field ast.StructField, field_sel ast.Expr, typ ast.Type, sym &ast.TypeSymbol) ast.Expr {
	ser_as := get_ser_as(field.attrs)

	return match typ {
		ast.f64_type, ast.f32_type {
			if ser_as == 'str' {
				ast.Expr(ast.CallExpr{
					scope: self.scope()
					is_method: true
					name: 'trim_right'
					args: [ast.CallArg{
						expr: codegen.string_literal('.')
					}]
					left: ast.CallExpr{
						scope: self.scope()
						is_method: true
						name: 'strlong'
						left: field_sel
					}
				})
			} else {
				field_sel
			}
		}
		ast.i8_type, ast.int_type, ast.i16_type, ast.i64_type, ast.isize_type, ast.u8_type,
		ast.u16_type, ast.u32_type, ast.u64_type, ast.usize_type {
			if ser_as == 'str' {
				ast.Expr(ast.CallExpr{
					scope: self.scope()
					is_method: true
					name: 'str'
					left: field_sel
				})
			} else {
				field_sel
			}
		}
		else {
			field_sel
		}
	}
}
fn get_type_recursively(mut self Codegen, field ast.StructField, field_sel ast.Expr, typ ast.Type) ast.Expr {
	// fallback to parent type, if type has no `str` method
	mut type_sym := self.table.sym(typ)
	$if debug_ser_json ? {
		if type_sym.name == 'Symbol' {
			dump('type_sym')
			println(type_sym)
			println(type_sym.name)
			println(type_sym.info)
			println(type_sym.has_method(encode_json_member_name))
			println(type_sym.has_method('str'))
		}
	}
	mut has_ser_json_method := false
	mut has_str_method := false
	mut is_alias := false
	for {
		if symbol__has_encode_method(mut self, type_sym) {
			has_ser_json_method = true
			break
		}
		if type_sym.has_method('str') {
			has_str_method = true
			break
		}
		info := type_sym.info
		if info is ast.Alias {
			is_alias = true
			type_sym = self.table.sym(info.parent_type)
			$if debug {
				println(term.red(type_sym.name))
				dump(type_sym.name)
			}
		} else {
			break
		}
	}
	if typ == ast.string_type {
		return field_sel
	} else if has_ser_json_method {
		return ast.Expr(ast.CallExpr{
			name: encode_json_member_name
			left: field_sel
			scope: self.scope()
			is_method: true
		})
	} else if has_str_method {
		// print(field_name)
		_ = $if debug {
			dump(type_sym.name)
			true
		} $else {
			true
		}

		return ast.Expr(ast.CallExpr{
			name: 'str'
			left: field_sel
			scope: self.scope()
			is_method: true
		})
	} else if type_sym.is_builtin() {
		return if is_alias {
			ast.CastExpr{
				typ: ast.Type(type_sym.idx)
				expr: get_type_recursively_builtin(mut self, field, field_sel, typ, type_sym)
			}
		} else {
			get_type_recursively_builtin(mut self, field, field_sel, typ, type_sym)
		}
	} else if self.table.final_sym(typ).is_builtin() {
		final_sym := self.table.final_sym(typ)
		return ast.CastExpr{
			typ: ast.Type(final_sym.idx)
			expr: get_type_recursively_builtin(mut self, field, field_sel, typ, final_sym)
		}
	} else {
		info := &type_sym.info

		match info {
			ast.Map {
				return field_sel
			}
			ast.Array {
				// $if debug {
				// 	dump(info)
				// }

				// elem_type_sym := self.table.sym(type_sym.info.elem_type)

				// match elem_type_sym.info {

				// }
				j2any := self.find_type_or_add_placeholder('json2.Any', .v)
				// print(type_sym.name)
				// dump(info.elem_type)
				// dump(j2any)
				map_arg_expr := get_type_recursively(mut self, field, self.ident('it'),
										info.elem_type)
				elem_type_sym := self.table.sym(info.elem_type)
				has_encode_method := symbol__has_encode_method(mut self, elem_type_sym)
				return ast.Expr(ast.CastExpr{
					typ: j2any
					expr: ast.CallExpr{
						name: 'map'
						args: [
							ast.CallArg{
								is_mut: false
								share: .mut_t
								// expr: if info.elem_type == j2any || elem_type_sym.has_method(encode_json_member_name) {
								expr: if info.elem_type == j2any || has_encode_method {
										map_arg_expr
									} else { ast.CastExpr{
										typ: j2any
										expr: map_arg_expr
									}
								}
							},
						]
						left: field_sel
						scope: self.scope()
						is_method: true
					}
				})
			}
			ast.Enum {
				return ast.Expr(ast.CallExpr{
					name: 'str'
					left: field_sel
					scope: self.scope()
					is_method: true
				})
			}
			ast.Struct {
				return ast.Expr(ast.CallExpr{
					name: encode_json_member_name
					left: field_sel
					scope: self.scope()
					is_method: true
				})
			}
			else {
				return field_sel
			}
		}
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

fn get_ser_as(attrs []ast.Attr) string {
	if attrs.contains(attr_json2_as) {
		for attr in attrs {
			if attr.name == attr_json2_as {
				return attr.arg
			}
		}
	}
	return ''
}

fn symbol__has_encode_method(mut self Codegen, type_sym &ast.TypeSymbol) bool {
	// type_sym.has_method(encode_json_member_name)
	if self.table.has_method(type_sym, encode_json_member_name) {
		return true
	}

	match type_sym.info {
		ast.Struct {
			if attr := type_sym.info.attrs.find_first('derive') {
				return attr.arg.contains(macro_name)
			}
		}
		ast.Enum {
			enum_decl := self.table.enum_decls[type_sym.name]
			if attr := enum_decl.attrs.find_first('derive') {
				return attr.arg.contains(macro_name)
			}
		}
		else {
			// 
		}
	}
	return false
}