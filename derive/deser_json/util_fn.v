module deser_json

fn get_struct_name_without_module(struct_name string) string {
	mut name := struct_name
	parts := name.split('.')

	if parts.len > 1 {
		name = parts.last()
	}
	return name
}

pub fn get_decode_fn_name(struct_name string) string {
	return '${decode_json_fn_name}__${to_snake_case(get_struct_name_without_module(struct_name))}'
}

// Generates something like:
//	 macro_deser_json__map__my_struct_type()
//	 macro_deser_json__map_map__my_struct_type()
//	 macro_deser_json__map_map_map__my_struct_type()
fn get_decode_map_fn_name(struct_name string, depth int) string {
	mut res := '${decode_json_fn_name}__'
	for _ in 0 .. depth {
		res += 'map_'
	}
	name := get_struct_name_without_module(struct_name)
	res += '_${to_snake_case(name)}'
	return res
}
// Generates something like:
//	 macro_deser_json__arr__my_struct_type()
//	 macro_deser_json__arr_arr__my_struct_type()
//	 macro_deser_json__arr_arr_arr__my_struct_type()
fn get_decode_array_fn_name(struct_name string, depth int) string {
	mut res := '${decode_json_fn_name}__'
	for _ in 0 .. depth {
		res += 'arr_'
	}
	name := get_struct_name_without_module(struct_name)
	res += '_${to_snake_case(name)}'
	return res
}
