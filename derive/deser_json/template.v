module deser_json

import v.pref
import v.parser
import tool.codegen.codegen {Codegen}

pub fn add_template_stmts(mut gen Codegen, mod_name string) {
	decode_json_fn_str := 'module $mod_name
import x.json2

[inline]
fn ${decode_json_fn_name}<T>(src json2.Any) ?T {
	mut typ := T{}
	typ.${decode_json_member_name}(src) ?
	return typ
}
[inline]
fn ${decode_json_map_fn_name}<T>(src map[string]json2.Any) ?map[string]T {
	mut res := map[string]T{}
	for key,val in src {
		res[key] = $decode_json_fn_name<T>(val) ?
	}
	return res
}
[inline]
fn ${decode_json_array_fn_name}<T>(src []json2.Any) ?[]T {
	return src.map($decode_json_fn_name<T>(it) ?)
}
'
	parsed := parser.parse_text(decode_json_fn_str, 'a.v', gen.table, .parse_comments, &pref.Preferences{})
	for stmt in parsed.stmts[2..] {
		gen.add_stmt(stmt)
	}
}
