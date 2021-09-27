module codegen

import v.ast
import term

// copied from https://github.com/vlang/v/blob/5162c257a22f9005c0ec055727cedd10e85705ea/vlib/v/parser/parse_type.v#L497
pub fn (mut p Codegen) find_type_or_add_placeholder(name string, language ast.Language) ast.Type {
	// struct / enum / placeholder
	mut idx := p.table.find_type_idx(name)
	if idx > 0 {
		return ast.new_type(idx)
	} else {
		$if debug_codegen ? {
			eprintln(term.red('not found type "$name"'))
			dump(name)
		}
		if name.starts_with('[]') {
			elem := name[2..]
			arr_type_idx := p.table.find_or_register_array(p.find_type_or_add_placeholder(elem, .v))
			$if debug_codegen ? {
				dump(arr_type_idx)
			}
			if arr_type_idx > 0 {
				return ast.new_type(arr_type_idx)
			}
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
		// https://github.com/vlang/v/issues/11989
		if name.starts_with('fn (') {
			dump(name)
			func := ast.Fn {
				params: [ast.Param {typ: p.find_type_or_add_placeholder('json2.Any', .v)}]
				return_type: p.find_type_or_add_placeholder(name.split(' ').last().trim_left('?'), .v).set_flag(.optional)
			}
			dump(p.table.type_symbols)
			dump(p.table.type_symbols.len)
			// fn_type_idx := p.table.register_type_symbol(name: name, info: ast.FnType{is_anon: true, has_decl: false, func: func}, kind: .function, idx: p.table.type_symbols.len)
			fn_type_idx := p.table.find_or_register_fn_type('def', func, true, false)
			dump(fn_type_idx)
			ts := p.table.type_symbols[fn_type_idx]
			dump(ts.name)
			dump(ts.idx)
			dump(ts.kind)
			dump(ts.info)
			return ast.new_type(fn_type_idx)
		}
	}
	// not found - add placeholder
	idx = p.table.add_placeholder_type(name, language)
	// println('NOT FOUND: $name - adding placeholder - $idx')
	return ast.new_type(idx)
}
