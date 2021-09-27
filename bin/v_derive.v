module main

import v.ast
import v.pref
import v.parser
import os
import term
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
	mut filename := os.args[1]
	mut files := []string{}
	outdir := if os.is_dir(filename) {
		dirname := filename
		files = os.walk_ext(filename, '.v').filter(!it.ends_with(os.args[2]))

		filename = files.pop()
		dirname
	} else {
		os.dir(filename)
	}
	// println(filename)
	mut table := ast.new_table()
	print('Parsing ')
	print(term.green(filename))
	println(' ...')
	parsed := parser.parse_file(filename, table, .parse_comments, &pref.Preferences{})
	module_name := parsed.mod.name.split('.').last()
	println('module_name: $module_name ($parsed.mod.name)')
	mut gen := codegen.new_with_table(mod_name: module_name, table: table)
	// deser_json.add_template_stmts(mut gen, module_name)
	deser_json.add_template_stmts__fn(mut gen, module_name)

	derive_code_for_stmts(mut gen, parsed)
	for file in files {
		print('Parsing ')
		print(term.green(file))
		println(' ...')

		parsed_file := parser.parse_file(file, table, .parse_comments, &pref.Preferences{})
		derive_code_for_stmts(mut gen, parsed_file)
	}

	if os.args.len > 2 {
		out_path := os.join_path(outdir, os.args[2])
		print('Generating ')
		print(term.green(out_path))
		print(' ...')
		os.write_file(out_path, gen.to_code_string()) ?
		println(' DONE!!')
	} else {
		println(gen.to_code_string())
	}
}

fn derive_code_for_stmts(mut gen Codegen, parsed ast.File) {
	for stmt in parsed.stmts {
		if stmt is ast.StructDecl {
			macros := get_macros(&stmt)
			for macro in macros {
				derive.gen_code(mut gen, macro, derive.GenCodeDecl(stmt as ast.StructDecl))
			}
		}
		if stmt is ast.EnumDecl {
			macros := get_macros(&stmt)
			for macro in macros {
				derive.gen_code(mut gen, macro, derive.GenCodeDecl(stmt as ast.EnumDecl))
			}
		}

	}
}

interface HasAttrs {
	attrs []ast.Attr
}
fn get_macros(stmt HasAttrs) []Macro {
	mut macros := []Macro{}
	for attr in stmt.attrs {
		if attr.name == 'derive' {
			macros << Macro(Derive{names: attr.arg.split(',').map(it.trim_space())})
		}
	}
	return macros
}