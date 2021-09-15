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
import tool.codegen.derive.deser_json {add_decode_json}

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
			if stmt is ast.StructDecl {
				println(stmt.attrs)
			}
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