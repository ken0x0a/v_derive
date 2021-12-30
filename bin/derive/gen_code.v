module main

import v.ast { FnDecl, StructDecl, EnumDecl }
import term
import macro { Macro, Derive, Custom }
import derive.json.de as deser_json
import derive.as_map
import derive.json.ser as ser_json
import derive.clone as derive_clone
import codegen {Codegen}

pub type GenCodeDecl = FnDecl | StructDecl | EnumDecl

pub fn gen_code(mut gen Codegen, macro Macro, decl GenCodeDecl) {
	match decl {
		ast.StructDecl {
			match macro {
				Custom {
					eprintln(term.red('Custom macro $macro is not supported for Struct'))
				}
				Derive {
					for macro_name in macro.names {
						gen_derive_for_struct(mut gen, macro_name, decl)
					}
				}
			}
		}
		ast.FnDecl {
			if macro !is Custom {
				panic('Only Custom macro is supported for FnDecl')
			}
		}
		ast.EnumDecl {
			match macro {
				Custom {
					eprintln(term.red('Custom macro $macro is not supported for Enum'))
				}
				Derive {
					for macro_name in macro.names {
						gen_derive_for_enum(mut gen, macro_name, decl)
					}
				}
			}
		}
	}
}

pub fn gen_derive_for_enum(mut gen Codegen, macro_name string, decl EnumDecl) {
	match macro_name {
		ser_json.macro_name {
			gen.add_import_if_not_exist('x.json2')
			ser_json.add_encode_json_enum(mut gen, decl)
		}
		deser_json.macro_name {
			gen.add_import_if_not_exist('x.json2')
			deser_json.add_decode_json_enum(mut gen, decl)
		}
		else {
			eprintln(term.red('Derive macro $macro_name is not supported for Enum'))
		}
	}
}
pub fn gen_derive_for_struct(mut gen Codegen, macro_name string, decl StructDecl) {
	match macro_name {
		derive_clone.macro_name {
			derive_clone.add_derive(mut gen, decl)
		}
		as_map.name_as_http_params {
			as_map.add_as_http_params_fn_for_struct(mut gen, decl)
		}
		ser_json.macro_name {
			gen.add_import_if_not_exist('x.json2')
			ser_json.add_encode_json(mut gen, decl)
		}
		deser_json.macro_name {
			gen.add_import_if_not_exist('x.json2')
			// deser_json.add_decode_json(mut gen, decl)
			deser_json.add_decode_json_fn(mut gen, decl)
		}
		else {
			eprintln(term.red('Derive macro $macro_name is not supported for Struct'))
		}
	}
}
