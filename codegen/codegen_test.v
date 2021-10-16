module codegen

import v.ast
// import v.checker
import v.fmt
import v.pref
import v.token

fn test_gen_fn() {
  answer := "fn yey() string {
	a := r'example'
	bool_op := (1) && (1.1)
}
"

	scope := &ast.Scope{
		parent: 0
	}
	mut file := &ast.File{
		global_scope: scope
		scope: scope
		mod: ast.Module{
			name: 'main'
			short_name: 'main'
			is_skipped: false
		}
	}
	mut table := ast.new_table()

	mut gen := Codegen{
		table: table
		file: file
		no_main: true
	}

	file.stmts << gen.gen_fn_example('yey')
	// file.stmts << t.visit_ast(node)
	res := fmt.fmt(file, table, &pref.Preferences{}, false)

	assert res == answer
}