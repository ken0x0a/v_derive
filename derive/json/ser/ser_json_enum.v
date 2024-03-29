module ser

import v.ast
import term
import codegen { Codegen }

enum EnumRename {
	snake_case
	upper_case // UPPER_CASE
	pascal_case // PascalCase
	camel_case // camelCase
	kebab_case // kebab-case
	screaming_kebab_case // SCREAMING-KEBAB-CASE
	repr // * use repr
}

struct SerJsonEnum {
	stmt ast.EnumDecl [required]
mut:
	gen Codegen [required]
}

// generates
// ```vlang
// fn (self Enum) to_json() json2.Any {
// 	return match self {
// 		.one { 'ONE' }
// 		else { error('Unexpected value $self') }
// 	}
// }
// ```
pub fn add_encode_json_enum(mut self Codegen, stmt ast.EnumDecl) {
	mut gen := SerJsonEnum{
		gen: self
		stmt: stmt
	}
	gen.add_impl()
}

fn (mut self SerJsonEnum) get_enum_value_expr(field ast.EnumField, rename_to EnumRename) ast.Expr {
	return match rename_to {
		.snake_case {
			self.gen.string_literal(field.name)
		}
		.upper_case {
			self.gen.string_literal(field.name.to_upper())
		}
		.pascal_case {
			self.gen.string_literal(field.name.split('_').map('${it[0..1].to_upper()}${it[1..]}').join(''))
		}
		.camel_case {
			parts := field.name.split('_')
			p2 := parts[1..].map('${it[0..1].to_upper()}${it[1..]}')
			self.gen.string_literal('${parts[0]}${p2.join('')}')
		}
		.kebab_case {
			self.gen.string_literal(field.name.replace('_', '-'))
		}
		.screaming_kebab_case {
			self.gen.string_literal(field.name.replace('_', '-').to_upper())
		}
		.repr {
			dump(field)
			panic('Not Implemented yet for $rename_to')
		}
	}
}

fn (mut self SerJsonEnum) add_impl() {
	t_j2any := self.gen.find_type_or_add_placeholder('json2.Any', .v)
	rename_to := self.get_rename_method()

	mut body_stmts := []ast.Stmt{}
	mut branches := []ast.MatchBranch{}
	for field in self.stmt.fields {
		branches << ast.MatchBranch{
			scope: self.gen.scope()
			exprs: [ast.Expr(ast.EnumVal{
				val: field.name
			})]
			stmts: [
				ast.Stmt(ast.ExprStmt{
					expr: self.get_enum_value_expr(field, rename_to)
				}),
			]
		}
	}
	// branches << ast.MatchBranch{
	// 	scope: self.gen.scope()
	// 	exprs: []
	// 	is_else: true
	// }
	body_stmts << ast.Stmt(ast.Return{
		exprs: [
			ast.Expr(ast.MatchExpr{
				is_expr: true
				return_type: ast.string_type
				cond: self.gen.ident('self')
				branches: branches
			}),
		]
	})
	self.gen.add_struct_method(
		struct_name: self.stmt.name.split('.').last()
		is_mut: false
		is_ref: false
		name: encode_json_member_name
		return_type: t_j2any
		body_stmts: body_stmts
		params: []
		comments: [
			self.gen.gen_comment(text: 'generated by macro "$macro_name"'),
			// self.gen.gen_comment(
			// 	text: 'Example: $ser_json.encode_json_fn_name<${self.stmt.name.split('.').last()}>(text)'
			// ),
		]
	)
}

fn (self SerJsonEnum) get_rename_method() EnumRename {
	for attr in self.stmt.attrs {
		if attr.name == 'serde_rename' {
			return match attr.arg {
				'snake_case', 'snake' {
					EnumRename.snake_case
				}
				'UPPER_CASE', 'UPPER' {
					EnumRename.upper_case
				}
				'PascalCase' {
					EnumRename.pascal_case
				}
				'camelCase' {
					EnumRename.camel_case
				}
				'kebab-case' {
					EnumRename.kebab_case
				}
				'SCREAMING-KEBAB-CASE' {
					EnumRename.screaming_kebab_case
				}
				'repr' {
					EnumRename.repr
				}
				else {
					eprintln(term.red('Unexpected serde_rename attr: $attr.arg'))
					eprint('Must be one of: ')
					eprintln("'snake_case', 'snake', 'UPPER_CASE', 'UPPER', 'PascalCase', 'camelCase', 'kebab-case', 'SCREAMING-KEBAB-CASE', 'repr'")
					dump(attr.name)
					exit(1)
				}
			}
		}
	}
	return EnumRename.snake_case
}
