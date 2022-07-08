module de

import v.ast
import codegen as cg

fn get_json2_method_name(typ ast.Type) (string, ast.Type) {
	mut cast_type := ast.Type(0)
	method_name := match typ {
		// ast.void_type_idx          { }
		// ast.voidptr_type_idx       { }
		// ast.byteptr_type_idx       { }
		// ast.charptr_type_idx       { }
		ast.i8_type_idx {
			cast_type = ast.i8_type
			'int'
		}
		ast.i16_type_idx {
			cast_type = ast.i16_type
			'int'
		}
		ast.int_type_idx {
			'int'
		}
		ast.i64_type_idx {
			'i64'
		}
		ast.isize_type_idx {
			cast_type = ast.isize_type
			'i64'
		}
		ast.u8_type_idx {
			cast_type = ast.u8_type
			'u64'
		}
		ast.u16_type_idx {
			cast_type = ast.u16_type
			'u64'
		}
		ast.u32_type_idx {
			cast_type = ast.u32_type
			'u64'
		}
		ast.u64_type_idx {
			'u64'
		}
		ast.usize_type_idx {
			cast_type = ast.usize_type
			'u64'
		}
		ast.f32_type_idx {
			'f32'
		}
		ast.f64_type_idx {
			'f64'
		}
		// ast.char_type_idx          {  }
		ast.bool_type_idx {
			'bool'
		}
		// ast.none_type_idx          {  }
		ast.string_type_idx {
			'str'
		}
		// ast.rune_type_idx          {  }
		// 🚨 ast.array_type_idx         {  }
		// 🚨 ast.map_type_idx           {  }
		// ast.chan_type_idx          {  }
		// ast.any_type_idx           {  }
		// ast.float_literal_type_idx { 'f64' }
		// ast.int_literal_type_idx   { 'int' }
		// ast.thread_type_idx        {  }
		// ast.error_type_idx         {  }
		else {
			dump(typ)
			panic('unexpected!! typ $typ')
		}
	}

	return method_name, cast_type
}

fn get_json2_default_value(typ ast.Type) ast.Stmt {
	return match typ {
		ast.i8_type_idx, ast.i16_type_idx, ast.int_type_idx, ast.i64_type_idx, ast.isize_type_idx,
		ast.u8_type_idx, ast.u16_type_idx, ast.u32_type_idx, ast.u64_type_idx,
		ast.usize_type_idx, ast.f32_type_idx, ast.f64_type_idx {
			cg.integer_literal_stmt(0)
		}
		ast.bool_type_idx {
			cg.bool_literal_stmt(false)
		}
		ast.string_type_idx {
			cg.string_literal_stmt('')
		}
		else {
			panic('unexpected!! typ $typ')
		}
	}
}
