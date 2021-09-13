module codegen

import v.ast
// import v.checker
import v.fmt
import v.pref
import v.token
import util {str_to_type}

pub struct Codegen {
	mod string
mut:
	const_decl &ast.ConstDecl = voidptr(0)
	no_main bool
	scope      &ast.Scope     = &ast.Scope{
		parent: 0
	}
pub mut:
	file       &ast.File
	table        &ast.Table
}

pub fn (self Codegen) scope() &ast.Scope {
	return self.scope
}
pub fn (self Codegen) to_code_string() string {
	return fmt.fmt(self.file, self.table, &pref.Preferences{}, false)
}
pub struct NewPlainArg {
	mod_name string = 'main'
}
pub fn new_plain(arg NewPlainArg) Codegen {
	scope := &ast.Scope{
		parent: 0
	}
	mut file := &ast.File{
		global_scope: scope
		scope: scope
		mod: ast.Module{
			name: arg.mod_name
			short_name: arg.mod_name
			is_skipped: false
		}
	}
	mut table := ast.new_table()

	mut gen := Codegen{
		table: table
		file: file
		no_main: true
		mod: arg.mod_name
	}
	gen.file.stmts << ast.Module{
		name: arg.mod_name
		short_name: arg.mod_name
		is_skipped: false
	}
	return gen
}

pub fn (mut self Codegen) add_import(name string) {
	self.file.imports << self.gen_import(name)
}
pub fn (mut self Codegen) gen_import(name string) ast.Import {
	return ast.Import{
		mod: name
		alias: name.split('.').last()
	}
}

pub fn (mut self Codegen) ident(name string) ast.Expr {
	return ast.Ident{
		name: name
		scope: self.scope
		info: ast.IdentVar{}
	}
}



pub fn (mut self Codegen) add_struct_decl(opt ast.StructDecl) {
		self.file.stmts << self.gen_struct_decl(opt)
}
[inline]
pub fn (mut self Codegen) gen_struct_decl(opt ast.StructDecl) ast.StructDecl {
	return opt
}
[inline]
pub fn (mut self Codegen) gen_struct(opt ast.Struct) ast.Struct {
	return opt
}

// pub struct GentructOpt {
// 	name string
// 	fields []ast.StructField
// }
// util.str_to_type('string')
pub struct GenStructFieldOpt {
	name    string [required]
	typ     ast.Type [required]
	comment string
	// default_value
	def_val string
	is_mut  bool
	attrs []ast.Attr
}


pub fn (mut self Codegen) add_stmt(stmt ast.Stmt)  {
	self.file.stmts << stmt
}
pub fn (mut self Codegen) gen_struct_field(opt GenStructFieldOpt) ast.StructField {
	return ast.StructField{
		name: opt.name
		typ: opt.typ
		default_val: opt.def_val
		comments: [self.gen_comment(text: opt.comment)]
		is_mut: opt.is_mut
		// comments: opt.comment.split('\n').map(
		// 	self.gen_comment(it, false, false)
		// )
	}
}

pub struct GenCommentOpt {
	text string
	is_multi bool
	is_inline bool
}

pub fn (mut self Codegen) gen_comment(opt GenCommentOpt) ast.Comment {
	return ast.Comment{
		text: opt.text
		is_multi: opt.is_multi
		is_inline: opt.is_inline
	}
}


pub fn (mut self Codegen) add_comment_stmt(opt GenCommentOpt) {
		self.file.stmts << self.gen_comment_stmt(opt)
}
pub fn (mut self Codegen) gen_comment_stmt(opt GenCommentOpt) ast.Stmt {
	return ast.ExprStmt{
		is_expr: false
		expr: ast.Comment{
			text: opt.text
			is_multi: opt.is_multi
			is_inline: opt.is_inline
		}
	}
}

pub struct GenFnDeclOpt {
	name string [required]
	return_type ast.Type = ast.void_type
	body_stmts []ast.Stmt [required]
	comments []ast.Comment [required]
	params []ast.Param [required]
}

pub fn (mut self Codegen) add_fn(opt GenFnDeclOpt) {
		self.file.stmts << self.gen_fn(opt)
}
pub fn (mut self Codegen) gen_fn(opt GenFnDeclOpt) ast.Stmt {
	return ast.FnDecl{
		return_type: opt.return_type
		params: opt.params
		stmts: opt.body_stmts
		name: opt.name
		scope: self.scope
		comments: opt.comments
	}
}

pub struct GenStructMethodOpt {
	name string [required]
	return_type ast.Type = ast.void_type
	body_stmts []ast.Stmt [required]
	comments []ast.Comment [required]
	params []ast.Param [required]
	struct_name string [required]
	receiver_name string = 'self'
	receiver_type ast.Type
	is_pub bool = true
	is_mut bool // => rec_mut is_self_mut
}

pub fn (mut self Codegen) add_struct_method(opt GenStructMethodOpt) {
	mut typ_idx := self.table.type_idxs[opt.struct_name]
	if typ_idx == 0 {
		typ_idx = self.table.type_idxs['${self.mod}.$opt.struct_name']
	}
	$if debug_codegen ? {
		println('self.table.type_idxs $self.table.type_idxs')
		println('opt.struct_name in self.table.type_idxs ${opt.struct_name in self.table.type_idxs}')
		println('opt: $opt')
		println('typ_idx: $typ_idx ${@FILE}:${@LINE}:${@COLUMN}')
		println(self.table.type_idxs[opt.struct_name])
	}
	mut type_sym := self.table.get_type_symbol(typ_idx)

	mut typ := ast.new_type(typ_idx)
	if opt.is_mut {
		typ = typ.to_ptr()
	}

	mut params := opt.params[..]
	params << ast.Param {
		name: opt.receiver_name
		typ: typ
		is_mut: opt.is_mut
	}

	method_idx := type_sym.register_method(ast.Fn{
		name: opt.name
		file_mode: .v
		params: params
		return_type: opt.return_type
		// is_variadic: is_variadic
		// generic_names: generic_names
		is_pub: opt.is_pub
		// is_deprecated: is_deprecated
		// is_unsafe: is_unsafe
		is_main: false
		// is_test: is_test
		// is_keep_alive: is_keep_alive
		//
		// attrs: p.attrs
		is_conditional: false
		ctdefine_idx: -1
		//
		// no_body: no_body
		mod: self.mod
		language: .v
	})
	self.file.stmts << self.gen_struct_method(GenStructMethodOpt{...opt, params: params, receiver_type: typ})
}
fn (mut self Codegen) gen_struct_method(opt GenStructMethodOpt) ast.Stmt {
	return ast.FnDecl{
		return_type: opt.return_type
		params: opt.params
		stmts: opt.body_stmts
		name: opt.name
		scope: self.scope
		comments: opt.comments
		is_method: true
		is_pub: opt.is_pub
		rec_mut: opt.is_mut
		rec_share: .mut_t
		// receiver: self.gen_struct_field(name: opt.receiver_name, typ: u16(-1) + self.table.type_idxs[opt.struct_name])
		receiver: self.gen_struct_field(name: opt.receiver_name, typ: opt.receiver_type)
		mod: self.mod
	}
}
