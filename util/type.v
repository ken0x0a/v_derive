module util

import v.ast

pub fn str_from_type(typ ast.Type) string {
	return match typ {
		ast.void_type          { 'ast.void_type' }
		ast.ovoid_type         { 'ast.ovoid_type' }
		ast.voidptr_type       { 'ast.voidptr_type' }
		ast.byteptr_type       { 'ast.byteptr_type' }
		ast.charptr_type       { 'ast.charptr_type' }
		ast.i8_type            { 'ast.i8_type' }
		ast.int_type           { 'ast.int_type' }
		ast.i16_type           { 'ast.i16_type' }
		ast.i64_type           { 'ast.i64_type' }
		ast.isize_type         { 'ast.isize_type' }
		ast.byte_type          { 'ast.byte_type' }
		ast.u16_type           { 'ast.u16_type' }
		ast.u32_type           { 'ast.u32_type' }
		ast.u64_type           { 'ast.u64_type' }
		ast.usize_type         { 'ast.usize_type' }
		ast.f32_type           { 'ast.f32_type' }
		ast.f64_type           { 'ast.f64_type' }
		ast.char_type          { 'ast.char_type' }
		ast.bool_type          { 'ast.bool_type' }
		ast.none_type          { 'ast.none_type' }
		ast.string_type        { 'ast.string_type' }
		ast.rune_type          { 'ast.rune_type' }
		ast.array_type         { 'ast.array_type' }
		ast.map_type           { 'ast.map_type' }
		ast.chan_type          { 'ast.chan_type' }
		ast.any_type           { 'ast.any_type' }
		ast.float_literal_type { 'ast.float_literal_type' }
		ast.int_literal_type   { 'ast.int_literal_type' }
		ast.thread_type        { 'ast.thread_type' }
		else {
			eprintln("unsupported type $typ")
			// panic("oops!!")
			"unsupported type"
		}
	}
}