// Copyright (c) 2019-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
// https://github.com/vlang/v/blob/ac2c3847afc0f7a9a0d3b99064188124df6a6fb5/LICENSE

module codegen

import v.scanner
import v.ast
import v.pref
import v.util
import v.parser

fn parse_stmt(text string, table &ast.Table, scope &ast.Scope) ast.Stmt {
	mut p := parser.Parser{
		scanner: scanner.new_scanner(text, .skip_comments, &pref.Preferences{})
		inside_test_file: true
		table: table
		pref: &pref.Preferences{
			is_fmt: true
		}
		scope: scope
	}
	p.init_parse_fns()
	// for imp in table.imports {
	// 	p.imports << imp.name
	// }
	p.read_first_token()
	return p.stmt(false)
}