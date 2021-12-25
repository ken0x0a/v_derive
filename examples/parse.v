module main

import v.ast
// import v.checker
import v.fmt
import v.pref
import v.token
import v.parser
import v.scanner
import term
import os
import json
import macro
import util {debug_stmt, str_from_type}

[inline]
pub fn is_comment(stmt ast.Stmt) bool {
	if stmt is ast.ExprStmt {
		return stmt.expr is ast.Comment
	} else {
		return false
	}
}

fn main() {
	mod_name := 'my_mod'
	path := 'main.v'
	text := '
module $mod_name

// #[invalid
// #[derive(Deser_json)]
[derive: Deser]
[custom: \'{something: b}\']
pub struct MyStruct {
	priv_field string
}
'
	table := ast.new_table()
	file := parser.parse_text(text, path, table, .parse_comments, &pref.Preferences{})
	println(file)
	debug_stmt(file.stmts[0])
	debug_stmt(file.stmts[1])
	debug_stmt(file.stmts[2])
	debug_stmt(file.stmts[3])
	for idx, stmt in file.stmts {
		match stmt {
			ast.StructDecl, ast.FnDecl {
				println(idx)
				if idx == 0 {
					continue
				}
				mut i := 1
				for {
					maybe_comment_stmt := file.stmts[idx - i]
					// if is_comment(maybe_comment_stmt) {
					if maybe_comment_stmt is ast.ExprStmt {
						if maybe_comment_stmt.expr is ast.Comment {
							comment_text := maybe_comment_stmt.expr.text.trim('\u0001 ')
							if macro.is_macro(comment_text) {
								mcr := macro.parse_from_text(comment_text)
								println(mcr)
							} else {
								print(term.red(comment_text))
								println(' is not a macro')
								break
							}
						} else {
							println('is not a Comment')
							break
						}
					}
					i++
				}
			}
			else {}
		}
	}
}

