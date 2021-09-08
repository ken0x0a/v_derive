module derive

import v.ast { FnDecl, StructDecl }
import tool.codegen.derive.macro { Macro, Derive, Custom }

type GenCodeDecl = FnDecl | StructDecl

pub fn gen_code(macro Macro, decl GenCodeDecl) string {
	match decl {
		ast.StructDecl {
			match macro {
				Custom {}
				Derive {
					gen_derive_for_struct(macro.name, decl)
				}
			}
		}
		ast.FnDecl {
			if macro !is Custom
		}
	}
	return ''
}

pub fn gen_derive_for_struct(macro_name string, decl StructDecl) string {
	match macro_name {
		'Deser_json' {
			'json2.raw'
		}
		else {}
	}
	return ''
}
