module deser_json

fn get_struct_name_without_module(struct_name string) string {
	mut name := struct_name
	parts := name.split('.')

	if parts.len > 1 {
		name = parts.last()
	}
	return name
}

fn get_decode_fn_name(struct_name string) string {
	return '${decode_json_fn_name}__${to_snake_case(get_struct_name_without_module(struct_name))}'
}

fn get_decode_map_fn_name(struct_name string, depth int) string {
	mut res := '${decode_json_fn_name}__'
	for _ in 0 .. depth {
		res += 'map_'
	}
	name := get_struct_name_without_module(struct_name)
	res += '_${to_snake_case(name)}'
	return res
}
