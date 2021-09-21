module deser_json

import v.pref
import v.parser
import tool.codegen.codegen { Codegen }

pub fn add_template_stmts(mut gen Codegen, mod_name string) {
	decode_json_fn_str := 'module $mod_name
import x.json2

[inline]
fn $decode_json_fn_name<T>(src json2.Any) ?T {
	mut typ := T{}
	typ.${decode_json_member_name}(src) ?
	return typ
}
[inline]
fn $decode_json_map_fn_name<T>(src map[string]json2.Any) ?map[string]T {
	mut res := map[string]T{}
	for key,val in src {
		res[key] = $decode_json_fn_name<T>(val) ?
	}
	return res
}
[inline]
fn $decode_json_array_fn_name<T>(src []json2.Any) ?[]T {
	return src.map($decode_json_fn_name<T>(it) ?)
}
[inline]
fn decode_json<T>(src string) ?T {
	res := json2.raw_decode(src) ?
	return macro_deser_json<T>(res)
}
[inline]
fn deser_json_map<T>(src string) ?map[string]T {
	decoded := json2.raw_decode(src) ?

	mut res := map[string]T{}
	for key, val in decoded.as_map() {
		res[key] = macro_deser_json<T>(val) ?
	}
	return res
}
[inline]
fn deser_json_map_map<T>(src string) ?map[string]map[string]T {
	decoded := json2.raw_decode(src) ?

	mut res := map[string]map[string]T{}
	for key, val in decoded.as_map() {
		res[key] = macro_deser_json_map<T>(val.as_map()) ?
	}
	return res
}
'

	parsed := parser.parse_text(decode_json_fn_str, 'a.v', gen.table, .parse_comments,
		&pref.Preferences{})
	for stmt in parsed.stmts[2..] {
		gen.add_stmt(stmt)
	}
}

pub fn add_template_stmts__fn(mut gen Codegen, mod_name string) {
	decode_json_fn_str := 'module $mod_name
import x.json2

[inline]
fn ${decode_json_fn_name}__map__cb<T>(src map[string]json2.Any, cb fn(json2.Any) ?T) ?map[string]T {
	mut res := map[string]T{}
	for key, val in src {
		res[key] = cb(val) ?
	}
	return res
}
[inline]
fn ${decode_json_fn_name}__map_map__cb<T>(src map[string]json2.Any, cb fn(json2.Any) ?T) ?map[string]map[string]T {
	mut res := map[string]map[string]T{}
	for key, val in src {
		res[key] = ${decode_json_fn_name}__map__cb<T>(val.as_map(), cb) ?
	}
	return res
}

[inline]
fn ${decode_json_pub_fn_prefix}__map__cb<T>(src string, cb fn(json2.Any) ?T) ?map[string]T {
	decoded := json2.raw_decode(src) ?
	return ${decode_json_fn_name}__map__cb<T>(decoded.as_map(), cb)
}

[inline]
fn ${decode_json_pub_fn_prefix}__map_map__cb<T>(src string, cb fn(json2.Any) ?T) ?map[string]map[string]T {
	decoded := json2.raw_decode(src) ?
	return ${decode_json_fn_name}__map_map__cb<T>(decoded.as_map(), cb)
}
'
	parsed := parser.parse_text(decode_json_fn_str, 'a.v', gen.table, .parse_comments,
		&pref.Preferences{})
	for stmt in parsed.stmts[2..] {
		gen.add_stmt(stmt)
	}
}
