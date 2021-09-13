module main

import v.ast
// import v.checker
import v.fmt
import v.pref
import v.token
import v.parser
import os
import json
import term
import tool.codegen.util {str_to_type}
import tool.codegen.codegen {Codegen}

const (
	json2_map_name = 'obj'
	decode_json_member_name = 'decode_json'
	decode_json_fn_name = 'macro_deser_json'
	decode_json_map_fn_name = 'macro_deser_json_map'
	decode_json_array_fn_name = 'macro_deser_json_array'
)

fn main() {
	// file_def := parse_code()
	// derived_code := derive()
	code := gencode()?
	println(code)
}

pub fn decode_json<T>(src string) ?T {
	res := raw_decode(src) ?
	mut typ := T{}
	typ.from_json(res) ?
	return typ
}

fn gencode() ?string {
mod_name := 'mylib'
	mut gen := codegen.new_plain(mod_name: mod_name)

	decode_json_fn_str := '[inline]
fn ${decode_json_fn_name}<T>(src string) ?T {
	res := raw_decode(src) ?
	mut typ := T{}
	typ.${decode_json_member_name}(res) ?
	return typ
}
[inline]
fn ${decode_json_map_fn_name}<T>(src map[string]json2.Any) map[string]T {
	mut res := map[string]T{}
	for key,val in src {
		res[key] = val
	}
	return res
}
[inline]
fn ${decode_json_array_fn_name}<T>(src []json2.Any) []T {
	return src.map($decode_json_fn_name<T>(it))
}
'


input := '
module $mod_name

import x.json2
[derive: "Deser_json,Ser_json"]
pub struct Inner {
	failed bool [required]
}
pub struct JsonResponse {
	amp string
	inner_field Inner [required; json: innerField]
	usize_field usize [required]
	map_field   map[string]Inner
	array_field   []Inner
mut:
	mutable_field byte
}

pub fn (mut self ClassName) from_json(j json2.Any) ? {
	obj := j.as_map()
	self.aaa = obj[js_field_name]
	self.aaa = obj[\'string_literal\']
	self.field_name = obj[js_field_name].str()
	self.field_name = byte(obj[js_field_name].str())
}
'
	parsed := parser.parse_text(input, 'a.v', gen.table, .parse_comments, &pref.Preferences{})
	$if debug_codegen ? {
		for stmt in parsed.stmts {
			// util.debug_stmt(stmt)
			if stmt is ast.FnDecl {
				println(term.green(stmt.name))
				for fn_stmt in stmt.stmts {
					util.debug_stmt(fn_stmt)
					if fn_stmt is ast.AssignStmt {
						for expr in fn_stmt.left {
							print(term.yellow('left'))
							util.debug_expr(expr)
						}
						for expr in fn_stmt.right {
							print(term.yellow('right'))
							util.debug_expr(expr)
						}
						
					}
				}
			}
		}
	}


	gen.add_import('x.json2')


	// gen.add_struct_method(struct_name: 'RegClient', is_mut: true, name: 'decode_json', return_type: my_new_type, body_stmts: [], params: [],comments: [])
	add_decode_json(mut gen, parsed.stmts[3] as ast.StructDecl)

	// file.stmts << t.visit_ast(node)
	return gen.to_code_string()
}

fn get_decode_json_base_stmts(mut self codegen.Codegen) []ast.Stmt {
	return [ast.Stmt(ast.AssignStmt{
		left: [self.ident(json2_map_name)]
		right: [
			ast.Expr(ast.CallExpr{
				name: 'as_map'
				left: self.ident('j')
				scope: self.scope()
				is_method: true
			})
		]
		// op: token.Kind.assign
		op: token.Kind.decl_assign
		// op: token.Kind.and
	})]
}
fn set_field_stmt(mut self codegen.Codegen, field_name string, js_field_name string, typ ast.Type) ast.Stmt {
	return ast.AssignStmt{
		left: [ast.Expr(ast.SelectorExpr{ // 'self.field'
			field_name: field_name
			expr: self.ident('self')
			scope: self.scope()
		})]
		right: [get_assign_right_expr(mut self, field_name, js_field_name, typ)]
		// op: token.Kind.assign
		op: token.Kind.assign
		// op: token.Kind.and
	}
}
fn get_assign_right_expr(mut self codegen.Codegen, field_name string, js_field_name string, typ ast.Type) ast.Expr {
	if typ > ast.builtin_type_names.len {
		type_sym := self.table.get_type_symbol(typ)
		arg := ast.CallArg {
						expr: ast.IndexExpr{
							index: self.string_literal(js_field_name)
							left: self.ident(json2_map_name)
						}
					}
		if type_sym.name.starts_with('map[') {
			// map
			type_arg := type_sym.name.split_nth(']', 2)[1]
			type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			return ast.Expr(ast.CallExpr{
					name: decode_json_map_fn_name
					args: [arg]
					concrete_types: [type_arg_idx]
					scope: self.scope(), is_method: false // left: self.ident('j')
			})
		} else if type_sym.name.starts_with('[') {
			// array
			type_arg := type_sym.name.split_nth(']', 2)[1]
			type_arg_idx := ast.Type(self.table.type_idxs[type_arg])
			return ast.Expr(ast.CallExpr{
					name: decode_json_array_fn_name
					args: [arg]
					concrete_types: [type_arg_idx]
					scope: self.scope(), is_method: false // left: self.ident('j')
			})
		}
		// else {
			// 'json'
			return ast.Expr(ast.CallExpr{
					name: decode_json_fn_name
					args: [arg]
					concrete_types: [typ]
					scope: self.scope(), is_method: false // left: self.ident('j')
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
					left: self.ident(json2_map_name)
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
fn get_json2_method_name(typ ast.Type) (string, ast.Type) {
	mut cast_type := ast.Type(0)
	// if typ > ast.builtin_type_names.len {
	// 	return
	// } else {
		method_name := match typ {
			// ast.void_type_idx          { }
			// ast.voidptr_type_idx       { }
			// ast.byteptr_type_idx       { }
			// ast.charptr_type_idx       { }
			ast.i8_type_idx            {
				cast_type = ast.i8_type
				'int'
			}
			ast.i16_type_idx           {
				cast_type = ast.i16_type
				'int' }
			ast.int_type_idx           { 'int' }
			ast.i64_type_idx           { 'i64' }
			ast.isize_type_idx         {
				cast_type = ast.isize_type
				 'i64' }
			ast.byte_type_idx          {
				cast_type = ast.byte_type
				 'u64' }
			ast.u16_type_idx           {
				cast_type = ast.u16_type
				 'u64' }
			ast.u32_type_idx           {
				cast_type = ast.u32_type
				 'u64' }
			ast.u64_type_idx           { 'u64' }
			ast.usize_type_idx         {
				cast_type = ast.usize_type
				'u64' }
			ast.f32_type_idx           { 'f32' }
			ast.f64_type_idx           { 'f64' }
			// ast.char_type_idx          {  }
			ast.bool_type_idx          { 'bool' }
			// ast.none_type_idx          {  }
			ast.string_type_idx        { 'str' }
			// ast.rune_type_idx          {  }
			// 🚨 ast.array_type_idx         {  }
			// 🚨 ast.map_type_idx           {  }
			// ast.chan_type_idx          {  }
			ast.size_t_type_idx        {
				cast_type = ast.usize_type
				'u64' }
			// ast.any_type_idx           {  }
			// ast.float_literal_type_idx { 'f64' }
			// ast.int_literal_type_idx   { 'int' }
			// ast.thread_type_idx        {  }
			// ast.error_type_idx         {  }
			ast.u8_type_idx            {
				cast_type = ast.byte_type
				'u64' }
			else {
				panic('unexpected!! typ $typ')
			}
		}
	// }
	return method_name, cast_type
}
fn get_js_field_name(field ast.StructField) string {
	mut name := field.name
	for attr in field.attrs {
		if attr.name == 'json' {
			name = attr.arg
		}
		println(attr)
	}
	return name
}
fn add_decode_json(mut self codegen.Codegen, stmt ast.StructDecl) {
	// mut body_stmts := []ast.Stmt{}
	mut body_stmts := get_decode_json_base_stmts(mut self)
	for field in stmt.fields {
		js_field_name := get_js_field_name(field)
		body_stmts << set_field_stmt(mut self, field.name, js_field_name, field.typ)
	}
	mut params := [ast.Param{ name: 'j', typ: self.find_type_or_add_placeholder('json2.Any', .v) }]
	self.add_struct_method(struct_name: stmt.name, is_mut: true, name: decode_json_member_name, return_type: ast.ovoid_type, body_stmts: body_stmts, params: params, comments: [
		self.gen_comment(text: 'generated by macro "derive_Deser')
		self.gen_comment(text: 'Example: ${decode_json_fn_name}<${stmt.name.split('.').last()}>(text)')
	])
}

// Generate something like following
// ```v
// pub fn (mut self ClassName) from_json(j json2.Any) ? {
// 	obj := j.as_map()
// 	self.field_name = obj[js_field_name].type()
// }
// ```
fn add_decode_json_exp(mut self codegen.Codegen) {
	mut body_stmts := []ast.Stmt{}
	body_stmts << ast.AssignStmt{
		left: [self.ident('obj')]
		right: [
			ast.Expr(ast.CallExpr{
				name: 'as_map'
				left: self.ident('j')
				scope: self.scope()
				is_method: true
			})
		]
		// op: token.Kind.assign
		op: token.Kind.decl_assign
		// op: token.Kind.and
	}
	body_stmts << ast.AssignStmt{
		left: [ast.Expr(ast.SelectorExpr{ // 'self.field'
			field_name: 'field_name'
			expr: self.ident('self')
			scope: self.scope()
		})]
		right: [
			ast.Expr(ast.CallExpr{
				name: 'str'
				left: ast.IndexExpr{
					index: self.ident('js_field_name')
					left: self.ident('obj')
				}
				scope: self.scope()
				is_method: true
			}),
		]
		// op: token.Kind.assign
		op: token.Kind.assign
		// op: token.Kind.and
	}
	body_stmts << ast.AssignStmt{
		left: [ast.Expr(ast.SelectorExpr{ // 'self.field'
			field_name: 'field_name'
			expr: self.ident('self')
			scope: self.scope()
		})]
		right: [
			ast.Expr(ast.CallExpr{
				name: 'str'
				left: ast.IndexExpr{
					index: ast.StringLiteral{val: 'js_field_name'}
					left: self.ident('obj')
				}
				scope: self.scope()
				is_method: true
			}),
		]
		// op: token.Kind.assign
		op: token.Kind.assign
		// op: token.Kind.and
	}
	// if !self.has_import('x.json2') {
	// 	self.add_import('x.json2')
	// }
	mut params := [ast.Param{
		name: 'j'
		typ: self.find_type_or_add_placeholder('json2.Any', .v)
	}]

	self.add_struct_method(struct_name: 'JsonResponse', is_mut: true, name: 'decode_json', return_type: ast.ovoid_type, body_stmts: body_stmts, params: params ,comments: [])
}