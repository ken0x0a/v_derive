module main

import v.ast
import v.pref
import v.parser
import os
import tool.codegen.codegen {Codegen}
import tool.codegen.macro {Macro, Derive}
import tool.codegen.derive
import tool.codegen.derive.deser_json

fn main() {
	if os.args.len == 1 {
		eprintln('Usage:
	${os.args[0]} filename.v
')
		exit(1)
	}
	filename := os.args[1]
	// println(filename)
	mut table := ast.new_table()
	parsed := parser.parse_file(filename, table, .parse_comments, &pref.Preferences{})
	mut gen := codegen.new_with_table(mod_name: parsed.mod.name, table: table)
	deser_json.add_template_stmts(mut gen, parsed.mod.name)

	for stmt in parsed.stmts {
		if stmt is ast.StructDecl {
			mut macros := []Macro{}
			for attr in stmt.attrs {
				if attr.name == 'derive' {
					macros << Macro(Derive{names: attr.arg.split(',')})
				}
			}
			for macro in macros {
				derive.gen_code(mut gen, macro, derive.GenCodeDecl(stmt as ast.StructDecl))
			}
		}
	}

	if os.args.len > 2 {
		os.write_file(os.args[2], gen.to_code_string()) ?
	} else {
		println(gen.to_code_string())
	}
}
