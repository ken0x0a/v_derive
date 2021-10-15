module clone

import v.ast
import tool.codegen.codegen {Codegen}

pub const (
	macro_name = 'Clone'
)

pub fn add_derive(mut self Codegen, stmt ast.StructDecl) {
	// TODO implement
	panic('NotImpelemented')
}
