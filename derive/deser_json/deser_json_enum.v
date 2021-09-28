module deser_json

import v.ast
import v.token
import term
import tool.codegen.codegen { Codegen }

const enum_rename_set = ['snake_case', 'UPPER_CASE', 'PascalCase', 'camelCase', 'kebab-case', 'SCREAMING-KEBAB-CASE', 'repr']

enum EnumRename {
	snake_case
	upper_case // UPPER_CASE
	pascal_case // PascalCase
	camel_case // camelCase
	kebab_case // kebab-case
	screaming_kebab_case // SCREAMING-KEBAB-CASE
	repr // * use repr
}
fn (self EnumRename) json2_conversion_fn_name() string {
	return match self {
		.repr { 'int' }
		else { 'str' }
	}
}

struct DeserJsonEnum {
	stmt ast.EnumDecl [required]
mut:
	gen Codegen [required]
}

// generates
// ```vlang
// fn (self Enum) to_json() string {
// 	return match self {
// 		.one { 'ONE' }
// 		else { error('Unexpected value $self') }
// 	}
// }
// ```
pub fn add_decode_json_enum(mut self Codegen, stmt ast.EnumDecl) {
	mut gen := DeserJsonEnum{gen: self, stmt: stmt}
	gen.add_impl()
}

fn (mut self DeserJsonEnum) get_enum_value_expr(field ast.EnumField, rename_to EnumRename) ast.Expr {
	return match rename_to {
		.snake_case { self.gen.string_literal(field.name) }
		.upper_case { self.gen.string_literal(field.name.to_upper()) }
		.pascal_case { self.gen.string_literal(field.name.split('_').map('${it[0..1].to_upper()}${it[1..]}').join('')) }
		.camel_case {
			parts := field.name.split('_')
			p2 := parts[1..].map('${it[0..1].to_upper()}${it[1..]}')
			self.gen.string_literal('${parts[0]}${p2}')
		}
		.kebab_case { self.gen.string_literal(field.name.replace('_', '-')) }
		.screaming_kebab_case { 
			// dump(field.name.replace('_', '-').to_upper())
			self.gen.string_literal(field.name.replace('_', '-').to_upper()) }
		.repr {
			if field.has_expr {
				field.expr
			} else {
				dump(field)
				panic('Not Implemented yet for $rename_to without expr')
			}
		}
	}
}

fn (mut self DeserJsonEnum) add_impl() {
	rename_to := self.get_rename_method()

	mut body_stmts := []ast.Stmt{}
	mut branches := []ast.MatchBranch{}
	ident_str := self.gen.ident('str')
	body_stmts << ast.Stmt(ast.AssignStmt{
		left: [ident_str]
		right: [
			ast.Expr(ast.CallExpr{
				name: rename_to.json2_conversion_fn_name()
				left: self.gen.ident('j')
				scope: self.gen.scope()
				is_method: true
			})
		]
		op: token.Kind.decl_assign
	})
	for field in self.stmt.fields {
		branches << ast.MatchBranch{
			scope: self.gen.scope()
			stmts: [ast.Stmt(ast.Return{exprs: [ast.Expr(ast.EnumVal{val: field.name})]})]
			exprs: [self.get_enum_value_expr(field, rename_to)]
		}
	}
	branches << ast.MatchBranch{
		scope: self.gen.scope()
		stmts: [ast.Stmt(ast.Return{exprs: [ast.Expr(ast.CallExpr{
				name: 'error'
				args: [ast.CallArg{expr: ast.StringInterLiteral{vals: ['Unexpected value "', '"'], exprs: [ident_str], fwidths: [0], pluss: [false], fills: [false], fmts: ['_'.bytes()[0]], need_fmts: [false], precisions: [987698]}}]
				scope: self.gen.scope()
		})]})]
		is_else: true
	}
	body_stmts << ast.Stmt(
		ast.ExprStmt{
			expr: ast.Expr(
				ast.MatchExpr{
					is_expr: true
					return_type: ast.string_type
					cond: ident_str
					branches: branches
				}
			)
		}
	)
	type_self := self.gen.find_type_or_add_placeholder(get_struct_name_without_module(self.stmt.name), .v)
	mut params := [ast.Param{
		name: 'j'
		typ: self.gen.find_type_or_add_placeholder('json2.Any', .v)
	}]
	self.gen.add_fn(
		is_pub: true
		name: get_decode_fn_name(self.stmt.name)
		return_type: type_self.set_flag(.optional)
		body_stmts: body_stmts
		params: params
		comments: [
			self.gen.gen_comment(text: 'generated by macro "derive_Deser')
			// self.gen.gen_comment(text: 'Example: $decode_json_fn_name<${stmt.name.split('.').last()}>(text)')
		]
	)
}

fn (self DeserJsonEnum) get_rename_method() EnumRename {
	for attr in self.stmt.attrs {
		if attr.name == 'serde_rename' {
			return match attr.arg {
				'snake_case', 'snake' { EnumRename.snake_case }
				'UPPER_CASE', 'UPPER' { EnumRename.upper_case }
				'PascalCase' { EnumRename.pascal_case }
				'camelCase' { EnumRename.camel_case }
				'kebab-case' { EnumRename.kebab_case }
				'SCREAMING-KEBAB-CASE' { EnumRename.screaming_kebab_case }
				'repr' { EnumRename.repr }
				else {
					eprintln(term.red('Unexpected serde_rename attr: $attr.arg'))
					eprintln('must be one of "$enum_rename_set"')
					dump(attr.name)
					exit(1)
				}
			}
		}
	}
	return EnumRename.snake_case
}