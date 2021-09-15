module derive

import v.ast { FnDecl, StructDecl }
import tool.codegen.macro { Macro, Derive, Custom }
import tool.codegen.derive.deser_json
import tool.codegen.codegen {Codegen}

pub type GenCodeDecl = FnDecl | StructDecl

pub fn gen_code(mut gen Codegen, macro Macro, decl GenCodeDecl) string {
	match decl {
		ast.StructDecl {
			match macro {
				Custom {}
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
	}
	return ''
}

pub fn gen_derive_for_struct(mut gen Codegen, macro_name string, decl StructDecl) {
	match macro_name {
		'Deser_json' {

			gen.add_import('x.json2')

			// mut result := ''
			// if is_sum_type {
			// 	'json2.raw()'
			// } else {
				// pub fn (mut self ClassName) from_json(j json2.Any) {
				// 	obj := j.as_map()
				// 	self.field_name = obj[js_field_name].type()
				// }
				deser_json.add_decode_json(mut gen, decl)
				
// 				mut table := ast.new_table()
// 				mut fn_template := parser.parse_text('
// module $mod_name
// pub fn (mut self ClassName) from_json(j json2.Any) ? {
// 	obj := j.as_map()
// 	self.field_name = obj[js_field_name].type()
// }
// ', 'dummy.v', table, .parse_comments, &pref.Preferences{}).stmts[1]
// 				for f in decl.fields {
					
// 				}
			// }


		}
		else {}
	}
}
