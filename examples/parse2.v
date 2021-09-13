module main

import v.ast
// import v.checker
import v.fmt
import v.pref
import v.token
import v.parser
import term
import tool.codegen.util {debug_stmt, str_from_type}

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
	path := 'generated.v'
	text := "
module $mod_name

import net.http
import json

pub struct AuthConfig {
pub:
	api_key    string [required]
	secret_key string [required]
}

pub struct Client {
pub:
	config AuthConfig [required]
}

// 資産残高を取得
// GET /private/v1/account/assets
pub fn (mut c Client) account_assets() ?AccountAssetResponse {
	resp := request_private_api(
		secret_key: c.config.secret_key
		api_key: c.config.api_key
		method: .get
		path: '/v1/account/assets'
	) ?
	// println(resp)
	return handle_response<AccountAssetResponse>(resp)
}

fn handle_response<T>(resp http.Response) ?T {
	return json.decode(T, resp.text) ?
}
"
	mut table := ast.new_table()
	file := parser.parse_text(text, path, table, .parse_comments, &pref.Preferences{})
	// println(file)
	for stmt in file.stmts {
		if stmt is ast.FnDecl {
			// println(stmt.stmts)
			// for stmt2 in stmt.stmts {
			// 	debug_stmt(stmt2)
			// }
			print('FnDecl ')
			println(term.green(stmt.name))
			println(stmt)
			println(stmt.receiver)
			println(str_from_type(stmt.receiver.typ))
			println(int(stmt.receiver.typ))
			println(stmt.receiver.typ.idx())
			println(table.type_symbols[stmt.receiver.typ.idx()])
			println(table.type_symbols[stmt.receiver.typ.idx()].info)
			if table.type_symbols[stmt.receiver.typ.idx()].kind == .struct_ {
				println(table.type_symbols[stmt.receiver.typ.idx()].struct_info())
			}
			println(table.type_symbols[stmt.receiver.typ.idx()].kind)
			println(table.type_symbols[stmt.receiver.typ.idx()].cname)
			// println(table.bitsize_to_type(stmt.receiver.typ))
			// println(stmt.receiver.default_expr)
		}
		if stmt is ast.StructDecl {
			print('StructDecl ')
			println(term.green(stmt.name))
			println(stmt)

			for field in stmt.fields {
				for attr in field.attrs {
					println('attr: $attr.debug()')
				}
			}
		}
		// debug_stmt(stmt)
	}
	// println(table.type_symbols)
	for sym in table.type_symbols {
		// print('$sym ')
		print('${sym.name:-20}')
		print('${sym.idx:-10}')
		print('${sym.kind:-10}')
		print('${sym.info:-10}')
		println('${sym.cname:-20}')
	}
	println(table.type_idxs)
	// for idx, stmt in file.stmts {
	// 	match stmt {
	// 		ast.StructDecl, ast.FnDecl {
	// 			println(idx)
	// 			if idx == 0 {
	// 				continue
	// 			}
	// 			mut i := 1
	// 			for {
	// 				maybe_comment_stmt := file.stmts[idx - i]
	// 				// if is_comment(maybe_comment_stmt) {
	// 				if maybe_comment_stmt is ast.ExprStmt {
	// 					if maybe_comment_stmt.expr is ast.Comment {
	// 						comment_text := maybe_comment_stmt.expr.text.trim('\u0001 ')
	// 						if macro.is_macro(comment_text) {
	// 							mcr := macro.parse_from_text(comment_text)
	// 							println(mcr)
	// 						} else {
	// 							print(term.red(comment_text))
	// 							println(' is not macro')
	// 							break
	// 						}
	// 					} else {
	// 						println('is not a Comment')
	// 						break
	// 					}
	// 				}
	// 				i++
	// 			}
	// 		}
	// 		else {}
	// 	}
	// }
}

