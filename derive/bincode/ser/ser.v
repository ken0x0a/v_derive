module ser

import v.ast { Stmt }
import v.token
import codegen { Codegen }
import util { get_type_name_without_module }

pub const (
	macro_name           = 'SerBin'
	attr_bincode2_as     = 'ser_bincode_as'
	attr_skip_if_default = 'ser_bincode_skip_if_default'
)

const (
	ident_name_bytes = 'b'
	ident_name_encode_pos = 'pos'
)

const (
	bincode2_map_name            = 'obj'
	bincode2_any_param_name      = 'j'
	encode_bincode_member_name   = 'to_bincode'
	encode_bincode_fn_name       = 'macro_ser_bincode'
	encode_bincode_fn_arg_name   = 'src'
	encode_bincode_map_fn_name   = 'macro_ser_bincode_map'
	encode_bincode_array_fn_name = 'macro_ser_bincode_array'
)

// ```v
// mut len := 0
// ```
fn base_assign_stmt(mut cg Codegen) Stmt {
	return Stmt(ast.AssignStmt{
		left: [cg.ident_opt(ident_name_encode_pos, is_mut: true)]
		right: [cg.integer_literal(0)]
		op: token.Kind.decl_assign
	})
}

fn get_params(mut cg Codegen) []ast.Param {
	return [ast.Param{
		name: ident_name_bytes
		typ: cg.find_type_or_add_placeholder(get_type_name_without_module('[]byte'),.v)
		is_mut: true
	}]
}

// Generates
// ```vlang
// [derive: 'DeserBincode,SerBincode']
// type OneOf = ItemA | ItemB
//
// fn bin_decode__one_of(buf []byte) OneOf {
// 	mut pos := 0
// 	typ := decode<byte>(buf)
// 	pos += encode_len(typ)
// 	match typ {
// 		1 { return OneOf(bin_decode__item_a(buf[pos..])) }
// 		2 { return OneOf(bin_decode__item_b(buf[pos..])) }
// 		else { panic('Unsupported type `$typ`') }
// 	}
// }
// pub fn (self OneOf) bin_decode(buf []byte) OneOf {
// 	return bin_decode__one_of(buf)
// }
// pub fn (self OneOf) bin_encode_len() int {
// 	mut len := 0
// 	len += encode_len_for<byte>()
// 	len += match self {
// 		ItemA { self.bin_encode_len() }
// 		ItemB { self.bin_encode_len() }
// 	}
// 	return len
// }
//
// pub fn (self OneOf) bin_encode(mut buf []byte) {
// 	mut pos := 0
// 	typ := match self {
// 		ItemA { byte(1) }
// 		ItemB { byte(2) }
// 	}
// 	encode(mut buf, typ)
// 	pos += encode_len_for<byte>()
// 	match self {
// 		ItemA {
// 			dump(self)
// 			encode(mut buf[pos..], self)
// 		}
// 		ItemB {
// 			dump(self)
// 			encode(mut buf[pos..], self)
// 		}
// 	}
// }
