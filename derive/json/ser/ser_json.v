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
// fn (self Struct) to_json() string {
// 	mut obj := map[string]json2.Any{}
// 	obj['name'] = self.name
// 	obj['f64_val'] = f64(self.f64_val).str().trim_right('.') // as str
// 	return obj.str()
// }
// ```
pub fn add_encode_json(mut self Codegen, stmt ast.StructDecl) {
	// mut body_stmts := []ast.Stmt{}
	mut body_stmts := get_encode_json_base_stmts(mut self)
	for field in stmt.fields {
		body_stmts << set_value_stmt_or_skip(mut self, field)
	}
	body_stmts << ast.Stmt(ast.Return{
		exprs: [
			ast.Expr(ast.CallExpr{
				name: 'str'
				left: self.ident(json2_map_name)
				scope: self.scope()
				is_method: true
			}),
		]
	})
	self.add_struct_method(
		struct_name: stmt.name.split('.').last()
		is_mut: false
		name: ser.encode_json_member_name
		return_type: ast.string_type
		body_stmts: body_stmts
		params: []
		comments: [
			self.gen_comment(text: 'generated by macro "$macro_name"'),
			self.gen_comment(
				text: 'Example: $ser.encode_json_fn_name<${stmt.name.split('.').last()}>(text)'
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
			return codegen.integer_literal(-i8(u8(-1) / 2))
		}
		ast.i16_type {
			return codegen.integer_literal(-i16(u16(-1) / 2))
		}
		ast.int_type {
			return codegen.integer_literal(-int(int(-1) / 2))
		}
		ast.i64_type {
			return codegen.integer_literal(-i64(u64(-1) / 2))
		}
		ast.isize_type {
			return codegen.integer_literal(-isize(usize(-1) / 2))
		}
		ast.u8_type {
			return codegen.integer_literal(byte(-1))
		}
		ast.u16_type {
			return codegen.integer_literal(u16(-1))
		}
		ast.u32_type {
			return codegen.integer_literal(u32(-1))
		}
		ast.u64_type {
			return codegen.integer_literal(u64(-1))
		}
		ast.usize_type {
			return codegen.integer_literal(usize(-1))
		}
		ast.f32_type {
			return codegen.float_literal(-1.0)
		}
		ast.f64_type {
			return codegen.float_literal(-1.0)
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
	for {
		if type_sym.has_method(encode_json_member_name) {
			has_ser_json_method = true
			break
		}
		if type_sym.has_method('str') {
			has_str_method = true
			break
		}
		info := type_sym.info
		if info is ast.Alias {
			type_sym = self.table.sym(info.parent_type)
			$if debug {
				println(term.red(type_sym.name))
				dump(type_sym.name)
			}
		} else {
			break
		}
	}
	right := if typ == ast.string_type {
		field_sel
	} else if has_ser_json_method {
		ast.Expr(ast.CallExpr{
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

		ast.Expr(ast.CallExpr{
			name: 'str'
			left: field_sel
			scope: self.scope()
			is_method: true
		})
	} else if type_sym.is_builtin() {
		ser_as := get_ser_as(field.attrs)

		match typ {
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
	} else {
		info := &type_sym.info

		match info {
			ast.Map {
				field_sel
			}
			ast.Array {
				// $if debug {
				// 	dump(info)
				// }

				// elem_type_sym := self.table.sym(type_sym.info.elem_type)

				// match elem_type_sym.info {

				// }
				j2any := self.find_type_or_add_placeholder('json2.Any', .v)
				ast.Expr(ast.CastExpr{
					typ: j2any
					expr: ast.CallExpr{
						name: 'map'
						args: [
							ast.CallArg{
								is_mut: false
								share: .mut_t
								expr: ast.CastExpr{
									typ: j2any
									expr: get_type_recursively(mut self, field, self.ident('it'),
										info.elem_type)
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
				ast.Expr(ast.CallExpr{
					name: 'str'
					left: field_sel
					scope: self.scope()
					is_method: true
				})
			}
			ast.Struct {
				ast.Expr(ast.CallExpr{
					name: encode_json_member_name
					left: field_sel
					scope: self.scope()
					is_method: true
				})
			}
			else {
				field_sel
			}
		}
	}
	return right
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
