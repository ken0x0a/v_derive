module de

import v.ast
import v.pref
import v.parser
import codegen

fn test_enum_bin_decode_fn() ? {
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
	// dump((parsed.stmts[1] as ast.FnDecl).stmts)
	assert parsed.stmts.len == 2
	assert parsed.stmts[1] is ast.EnumDecl
	add_decode_fn_for_enum(mut gen, parsed.stmts[1] as ast.EnumDecl)
	// dump(gen)
	assert gen.to_code_string() == 'module main

// generated by macro "DeserBin"
pub fn bin_decode__test_enum(b []u8, mut d_len &int) TestEnum {
	return TestEnum(bincode.decode<int>(b, mut d_len))
}
'
	// pub fn (self TestEnum) bin_decode(b []u8) TestEnum {
	// }
}

fn test_struct_bin_decode_fn() ? {
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
	add_decode_fn_for_struct(mut gen, parsed.stmts[1] as ast.StructDecl)
	// dump(gen)
	assert gen.to_code_string() == 'module main

// generated by macro "DeserBin"
pub fn bin_decode__test(b []u8, mut d_len &int) Test {
	mut pos := 0
	defer {
		d_len += pos
	}
	return Test{
		a: bincode.decode<int>(b, mut pos)
		b: bincode.decode<string>(b[pos..], mut pos)
		c: bincode.decode<u64>(b[pos..], mut pos)
	}
}
'
	// pub fn (self Test) bin_decode(b []u8, mut d_len &int) Test {
	// }
}

fn test_sumtype_bin_decode() ? {
	test_text := '
type OneOf = ItemA | ItemB
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
	add_decode_fn_for_sumtype_fn(mut gen, parsed.stmts[1] as ast.TypeDecl as ast.SumTypeDecl)
	dump(gen.file.stmts)
	assert gen.to_code_string() == 'module main

// generated by macro "DeserBin"
pub fn bin_decode__one_of(b []u8, mut d_len &int) OneOf {
	mut pos := 0
	defer {
		d_len += pos
	}
	typ := bincode.decode<u8>(b, mut pos)
	match typ {
		1 { return OneOf(bin_decode__item_a(b[pos..], mut pos)) }
		2 { return OneOf(bin_decode__item_b(b[pos..], mut pos)) }
		else { panic(\'Unsupported type `\$typ` < 2\') }
	}
}
'
	// pub fn (self Test) bin_decode(b []u8, mut d_len &int) Test {
	// }
}
