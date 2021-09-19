module deser_json

import v.ast

fn get_json2_method_name(typ ast.Type) (string, ast.Type) {
	mut cast_type := ast.Type(0)
	method_name := match typ {
		// ast.void_type_idx          { }
		// ast.voidptr_type_idx       { }
		// ast.byteptr_type_idx       { }
		// ast.charptr_type_idx       { }
		ast.i8_type_idx            {
			cast_type = ast.i8_type
			'int'
		}
		ast.i16_type_idx           {
			cast_type = ast.i16_type
			'int' }
		ast.int_type_idx           { 'int' }
		ast.i64_type_idx           { 'i64' }
		ast.isize_type_idx         {
			cast_type = ast.isize_type
				'i64' }
		ast.byte_type_idx          {
			cast_type = ast.byte_type
				'u64' }
		ast.u16_type_idx           {
			cast_type = ast.u16_type
				'u64' }
		ast.u32_type_idx           {
			cast_type = ast.u32_type
				'u64' }
		ast.u64_type_idx           { 'u64' }
		ast.usize_type_idx         {
			cast_type = ast.usize_type
			'u64' }
		ast.f32_type_idx           { 'f32' }
		ast.f64_type_idx           { 'f64' }
		// ast.char_type_idx          {  }
		ast.bool_type_idx          { 'bool' }
		// ast.none_type_idx          {  }
		ast.string_type_idx        { 'str' }
		// ast.rune_type_idx          {  }
		// 🚨 ast.array_type_idx         {  }
		// 🚨 ast.map_type_idx           {  }
		// ast.chan_type_idx          {  }
		ast.size_t_type_idx        {
			cast_type = ast.usize_type
			'u64' }
		// ast.any_type_idx           {  }
		// ast.float_literal_type_idx { 'f64' }
		// ast.int_literal_type_idx   { 'int' }
		// ast.thread_type_idx        {  }
		// ast.error_type_idx         {  }
		ast.u8_type_idx            {
			cast_type = ast.byte_type
			'u64' }
		else {
			panic('unexpected!! typ $typ')
		}
	}

	return method_name, cast_type
}
