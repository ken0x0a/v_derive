module common

import v.ast
import v.pref
import v.parser
import codegen

fn test_enum_bin_len() ? {
	test_text := '
enum TestEnum {
	a
	b
	c
}
'
	mut table := ast.new_table()
	// parsed := parser.parse_file(filename, table, .parse_comments, &pref.Preferences{})
	// mut gen := codegen.new_with_table(mod_name: module_name, table: table)
	mut gen := codegen.new_with_table(table: table)
	parsed := parser.parse_text(test_text, 'dummy.v', gen.table, .parse_comments, &pref.Preferences{})
	module_name := parsed.mod.name.split('.').last()
	println('module_name: $module_name ($parsed.mod.name)')
	dump(parsed.stmts)
	assert parsed.stmts.len == 2
	assert parsed.stmts[1] is ast.EnumDecl
	add_len_fn_for_enum(mut gen, parsed.stmts[1] as ast.EnumDecl)
	dump(gen)
	assert gen.to_code_string() == 'module main

// generated by macro "BinEncode"
pub fn (self TestEnum) bin_len() int {
	return 4
}
'
}

fn test_struct_bin_len() ? {
	test_text := '
struct Test {
	a int
	b string
	c u64
}
'
	mut table := ast.new_table()
	// parsed := parser.parse_file(filename, table, .parse_comments, &pref.Preferences{})
	// mut gen := codegen.new_with_table(mod_name: module_name, table: table)
	mut gen := codegen.new_with_table(table: table)
	parsed := parser.parse_text(test_text, 'dummy.v', gen.table, .parse_comments, &pref.Preferences{})
	module_name := parsed.mod.name.split('.').last()
	println('module_name: $module_name ($parsed.mod.name)')
	dump(parsed.stmts)
	assert parsed.stmts.len == 2
	assert parsed.stmts[1] is ast.StructDecl
	add_len_fn_for_struct(mut gen, parsed.stmts[1] as ast.StructDecl)
	dump(gen)
	assert gen.to_code_string() == 'module main

// generated by macro "BinEncode"
pub fn (self Test) bin_len() int {
	mut len := 0
	len += bincode.len(self.a)
	len += bincode.len(self.b)
	len += bincode.len(self.c)
	return len
}
'
}

fn test_sumtype_bin_len() ? {
	test_text := '
type Test = ItemA | ItemB
struct ItemA {
	a int
}
struct ItemB {
	b string
}
'
	mut table := ast.new_table()
	// parsed := parser.parse_file(filename, table, .parse_comments, &pref.Preferences{})
	// mut gen := codegen.new_with_table(mod_name: module_name, table: table)
	mut gen := codegen.new_with_table(table: table)
	parsed := parser.parse_text(test_text, 'dummy.v', gen.table, .parse_comments, &pref.Preferences{})
	module_name := parsed.mod.name.split('.').last()
	println('module_name: $module_name ($parsed.mod.name)')
	assert parsed.stmts.len == 4
	assert parsed.stmts[1] is ast.TypeDecl
	dump(parsed.stmts[1] as ast.TypeDecl as ast.SumTypeDecl)
	add_len_fn_for_sumtype(mut gen, parsed.stmts[1] as ast.TypeDecl as ast.SumTypeDecl)
	dump(gen.file.stmts)
	assert gen.to_code_string() == 'module main

// generated by macro "BinEncode"
pub fn (self Test) bin_len() int {
	mut len := 0
	len += bincode.len_for<byte>()
	len += match self {
		ItemA { self.bin_len() }
		ItemB { self.bin_len() }
	}
	return len
}
'
}