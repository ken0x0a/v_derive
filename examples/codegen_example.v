module main

import v.ast
// import v.checker
import v.fmt
import v.pref
import v.parser
import util {str_to_type}
import codegen {Codegen}
import term

fn main() {
	code := codegen() ?
	println('')
	println(code)
	println('a')
}

fn codegen() ?string {
	mod_name := 'someother'
	scope := &ast.Scope{
		parent: 0
	}
	mut file := &ast.File{
		global_scope: scope
		scope: scope
		mod: ast.Module{
			name: mod_name
			short_name: mod_name
			is_skipped: false
		}
	}
	mut table := ast.new_table()

	mut gen := Codegen{
		table: table
		file: file
		no_main: true
		mod: mod_name
	}

	file.imports << gen.gen_import('x.json2')
	file.stmts << ast.Module{
		name: mod_name
		short_name: mod_name
		is_skipped: false
	}
	my_new_type := table.register_type_symbol(ast.TypeSymbol {
		name: "RegClient"
		kind: .struct_
		info: gen.gen_struct(fields: [])
		mod: mod_name
		is_public: true
		language: .v
	})
	println('my_new_type $my_new_type')
	eprint(term.red('type'))
	eprintln(table.type_symbols[my_new_type].debug())

	// file.imports << gen.gen_import('yey')
	parsed := parser.parse_text('module $mod_name
import net.http

// Handle http responses
fn handle_response<T>(resp http.Response) ?T {
	return json2.decode<T>(resp.text) ?
}

fn (self Client) assets() {}
', 'a.v', table, .parse_comments, &pref.Preferences{})
	gen.add_stmt(parsed.stmts[3])
	util.debug_stmt(parsed.stmts[4])
	eprint(term.red('type'))
	eprintln(table.type_symbols[34].debug())
	gen.add_stmt(parsed.stmts[4])
	file.stmts << gen.gen_struct_decl(
		name: 'camelCaseStruct'
		fields: [
			gen.gen_struct_field(
				name: 'name'
				typ: str_to_type('string')
				// comment: 'comment'
				comment: 'multiline\ncomment'
				def_val: 'def_val'
			),
		]
	)
	file.stmts << gen.gen_comment_stmt(text: 'yey')
	file.stmts << gen.gen_comment_stmt(text: '\u0001 this is doc for \nast2codeComment', is_inline: true)
	file.stmts << gen.gen_comment_stmt(text: 'aaa this is doc for \nast2codeComment', is_multi: true)
	file.stmts << gen.gen_fn_example('yey')
	file.stmts << gen.gen_fn(name: 'myfn', return_type: my_new_type, body_stmts: [], params: [],comments: [])
	println(term.green('adding struct method'))
	gen.add_struct_method(struct_name: 'RegClient', is_mut: true, name: 'myfn_mut', return_type: my_new_type, body_stmts: [], params: [],comments: [])
	gen.add_struct_method(struct_name: 'RegClient', is_mut: false, name: 'myfn', return_type: my_new_type, body_stmts: [], params: [],comments: [])
	util.debug_stmt(file.stmts[file.stmts.len -1])
	// file.stmts << t.visit_ast(node)
	// assert fmt.fmt(file, table, &pref.Preferences{}, false) == gen.to_code_string()
	// return fmt.fmt(file, table, &pref.Preferences{}, false)
	return gen.to_code_string()
}

