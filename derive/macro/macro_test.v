module macro

fn test_parse_macro_text() {
	{
		macro_text := '#[derive(Deser_json)]'
		assert is_macro(macro_text)
		mcr := parse_from_text(macro_text)
		if mcr is Derive {
			assert mcr.names.len == 1
			assert mcr.names[0] == 'Deser_json'
		} else {
			panic('must be derive macro!!')
		}
	}
	{
		macro_text := '#[serde(deserialize_with = my_func)]'
		assert is_macro(macro_text)
		mcr := parse_from_text(macro_text)
		if mcr is Custom {
			assert mcr.name == 'serde'
			assert 'deserialize_with' in mcr.attrs
			println('mcr.attrs[\'deserialize_with\']: ${mcr.attrs['deserialize_with']}')
			assert mcr.attrs['deserialize_with'] == 'my_func'
		} else {
			panic('must be custom macro!!')
		}
	}
	{
		macro_text := '#[macro_name(attr = "value", attr_int = 22)]'
		assert is_macro(macro_text)
		mcr := parse_from_text(macro_text)
		if mcr is Custom {
			assert mcr.name == 'macro_name'
			assert 'attr' in mcr.attrs
			println('mcr.attrs[\'attr\']: ${mcr.attrs['attr']}')
			assert mcr.attrs['attr'] == '"value"'
			assert mcr.attrs['attr_int'] == '22'
		} else {
			panic('must be custom macro!!')
		}
	}
	{
		macro_text := '#[macro_name(attr = "value", attr_ident = my_func_name)]'
		assert is_macro(macro_text)
		mcr := parse_from_text(macro_text)
		if mcr is Custom {
			assert mcr.name == 'macro_name'
			assert 'attr_ident' in mcr.attrs
			println('mcr.attrs[\'attr_ident\']: ${mcr.attrs['attr_ident']}')
			assert mcr.attrs['attr_ident'] == 'my_func_name'
		} else {
			panic('must be custom macro!!')
		}
	}
	{
		macro_text := '#[macro_name]'
		assert is_macro(macro_text)
		mcr := parse_from_text(macro_text)
		if mcr is Custom {
			assert mcr.name == 'macro_name'
			assert mcr.attrs.len == 0
		} else {
			panic('must be custom macro!!')
		}
	}
}
