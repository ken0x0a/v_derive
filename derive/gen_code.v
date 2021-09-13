module derive

import v.ast { FnDecl, StructDecl }
import v.pref
import v.parser
import tool.codegen.derive.macro { Macro, Derive, Custom }

type GenCodeDecl = FnDecl | StructDecl

pub fn gen_code(macro Macro, decl GenCodeDecl) string {
	match decl {
		ast.StructDecl {
			match macro {
				Custom {}
				Derive {
					for macro_name in macro.names {
						gen_derive_for_struct(macro_name, decl)
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

pub fn gen_derive_for_struct(macro_name string, decl StructDecl) FnDecl {
	match macro_name {
		'Deser_json' {
			add_import('x.json2')

			mut result := ''
			if is_sum_type {
				'json2.raw()'
			} else {
				// pub fn (mut self ClassName) from_json(j json2.Any) {
				// 	obj := j.as_map()
				// 	self.field_name = obj[js_field_name].type()
				// }
				mod_name := ''
				
				mut table := ast.new_table()
				mut fn_template := parser.parse_text('
module $mod_name
pub fn (mut self ClassName) from_json(j json2.Any) {
	obj := j.as_map()
	self.field_name = obj[js_field_name].type()
}
', 'dummy.v', table, .parse_comments, &pref.Preferences{}).stmts[1]
				for f in decl.fields {
					
				}
			}


		}
		else {}
	}
	return ''
}
