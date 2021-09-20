module codegen

import v.ast
import term

// copied from https://github.com/vlang/v/blob/5162c257a22f9005c0ec055727cedd10e85705ea/vlib/v/parser/parse_type.v#L497
pub fn (mut p Codegen) find_type_or_add_placeholder(name string, language ast.Language) ast.Type {
	// struct / enum / placeholder
	mut idx := p.table.find_type_idx(name)
	if idx > 0 {
		if idx == ast.size_t_type_idx {
			return ast.new_type(ast.usize_type_idx)
		}
		return ast.new_type(idx)
	} else {
		$if debug_codegen ? {
			eprintln(term.red('not found type "$name"'))
			dump(name)
		}
		if name.starts_with('map[') {
			parts := name[4..].split_nth(']', 2)
			map_type_idx := p.table.find_or_register_map(p.find_type_or_add_placeholder(parts[0], .v), p.find_type_or_add_placeholder(parts[1], .v))
			$if debug_codegen ? {
				dump(map_type_idx)
			}
			if map_type_idx > 0 {
				return ast.new_type(map_type_idx)
			}
		}
	}
	// not found - add placeholder
	idx = p.table.add_placeholder_type(name, language)
	// println('NOT FOUND: $name - adding placeholder - $idx')
	return ast.new_type(idx)
}
