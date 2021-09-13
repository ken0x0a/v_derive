module codegen

import v.ast

// copied from https://github.com/vlang/v/blob/5162c257a22f9005c0ec055727cedd10e85705ea/vlib/v/parser/parse_type.v#L497
pub fn (mut p Codegen) find_type_or_add_placeholder(name string, language ast.Language) ast.Type {
	// struct / enum / placeholder
	mut idx := p.table.find_type_idx(name)
	if idx > 0 {
		if idx == ast.size_t_type_idx {
			return ast.new_type(ast.usize_type_idx)
		}
		return ast.new_type(idx)
	}
	// not found - add placeholder
	idx = p.table.add_placeholder_type(name, language)
	// println('NOT FOUND: $name - adding placeholder - $idx')
	return ast.new_type(idx)
}
