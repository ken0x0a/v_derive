module util

import v.ast

// https://github.com/vlang/v/blob/master/vlib/v/ast/types.v#L419
pub fn str_to_type(typ string) ast.Type {
	return match typ {
		'void' {
			ast.void_type
		}
		'ovoid' {
			ast.ovoid_type
		}
		'voidptr' {
			ast.voidptr_type
		}
		'byteptr' {
			ast.byteptr_type
		}
		'charptr' {
			ast.charptr_type
		}
		'i8' {
			ast.i8_type
		}
		'int' {
			ast.int_type
		}
		'i16' {
			ast.i16_type
		}
		'i64' {
			ast.i64_type
		}
		'byte' {
			ast.byte_type
		}
		'u8' {
			ast.u8_type
		}
		'u16' {
			ast.u16_type
		}
		'u32' {
			ast.u32_type
		}
		'u64' {
			ast.u64_type
		}
		'f32' {
			ast.f32_type
		}
		'f64' {
			ast.f64_type
		}
		'char' {
			ast.char_type
		}
		'bool' {
			ast.bool_type
		}
		'none' {
			ast.none_type
		}
		'string' {
			ast.string_type
		}
		'rune' {
			ast.rune_type
		}
		'array' {
			ast.array_type
		}
		'map' {
			ast.map_type
		}
		'chan' {
			ast.chan_type
		}
		'any' {
			ast.any_type
		}
		'float_literal' {
			ast.float_literal_type
		}
		'int_literal' {
			ast.int_literal_type
		}
		'thread' {
			ast.thread_type
		}
		'error' {
			ast.error_type
		}
		// charptr_types
		// byteptr_types
		// voidptr_types
		// cptr_types
		else {
			panic('unsupported type $typ')
			ast.error_type
		}
	}
}

pub fn debug_stmt(stmt ast.Stmt) {
	// println(stmt.type_name())
	println(stmt)
	// match stmt {
	// 	ast.AsmStmt { println(stmt) }
	// 	ast.AssertStmt { println(stmt) }
	// 	ast.AssignStmt { println(stmt) }
	// 	ast.Block { println(stmt) }
	// 	ast.BranchStmt { println(stmt) }
	// 	ast.CompFor { println(stmt) }
	// 	ast.ConstDecl { println(stmt) }
	// 	ast.DeferStmt { println(stmt) }
	// 	ast.EmptyStmt { println(stmt) }
	// 	ast.EnumDecl { println(stmt) }
	// 	ast.ExprStmt { println(stmt) }
	// 	ast.FnDecl { println(stmt) }
	// 	ast.ForCStmt { println(stmt) }
	// 	ast.ForInStmt { println(stmt) }
	// 	ast.ForStmt { println(stmt) }
	// 	ast.GlobalDecl { println(stmt) }
	// 	ast.GotoLabel { println(stmt) }
	// 	ast.GotoStmt { println(stmt) }
	// 	ast.HashStmt { println(stmt) }
	// 	ast.Import { println(stmt) }
	// 	ast.InterfaceDecl { println(stmt) }
	// 	ast.Module { println(stmt) }
	// 	ast.NodeError { println(stmt) }
	// 	ast.Return { println(stmt) }
	// 	ast.SqlStmt { println(stmt) }
	// 	ast.StructDecl { println(stmt) }
	// 	ast.TypeDecl { println(stmt) }
	// }
}

pub fn debug_expr(expr ast.Expr) {
	println(expr)
	// match expr {
	// 	ast.AnonFn { println(expr) }
	// 	ast.ArrayDecompose { println(expr) }
	// 	ast.ArrayInit { println(expr) }
	// 	ast.AsCast { println(expr) }
	// 	ast.Assoc { println(expr) }
	// 	ast.AtExpr { println(expr) }
	// 	ast.BoolLiteral { println(expr) }
	// 	ast.CTempVar { println(expr) }
	// 	ast.CallExpr { println(expr) }
	// 	ast.CastExpr { println(expr) }
	// 	ast.ChanInit { println(expr) }
	// 	ast.CharLiteral { println(expr) }
	// 	ast.Comment { println(expr) }
	// 	// ast.ComptimeCall { println(expr) }
	// 	ast.ComptimeSelector { println(expr) }
	// 	ast.ConcatExpr { println(expr) }
	// 	ast.DumpExpr { println(expr) }
	// 	ast.EmptyExpr { println(expr) }
	// 	ast.EnumVal { println(expr) }
	// 	ast.FloatLiteral { println(expr) }
	// 	ast.GoExpr { println(expr) }
	// 	ast.Ident { println(expr) }
	// 	ast.IfExpr { println(expr) }
	// 	ast.IfGuardExpr { println(expr) }
	// 	ast.IndexExpr { println(expr) }
	// 	ast.InfixExpr { println(expr) }
	// 	ast.IntegerLiteral { println(expr) }
	// 	ast.IsRefType { println(expr) }
	// 	ast.Likely { println(expr) }
	// 	ast.LockExpr { println(expr) }
	// 	ast.MapInit { println(expr) }
	// 	ast.MatchExpr { println(expr) }
	// 	ast.NodeError { println(expr) }
	// 	ast.None { println(expr) }
	// 	ast.OffsetOf { println(expr) }
	// 	ast.OrExpr { println(expr) }
	// 	ast.ParExpr { println(expr) }
	// 	ast.PostfixExpr { println(expr) }
	// 	ast.PrefixExpr { println(expr) }
	// 	ast.RangeExpr { println(expr) }
	// 	ast.SelectExpr { println(expr) }
	// 	ast.SelectorExpr { println(expr) }
	// 	ast.SizeOf { println(expr) }
	// 	ast.SqlExpr { println(expr) }
	// 	ast.StringInterLiteral { println(expr) }
	// 	ast.StringLiteral { println(expr) }
	// 	ast.StructInit { println(expr) }
	// 	ast.TypeNode { println(expr) }
	// 	ast.TypeOf { println(expr) }
	// 	ast.UnsafeExpr { println(expr) }
	// 	else {
	// 		eprint(term.red('unsupported type'))
	// 		eprintln(expr.type_name())
	// 		println(expr)
	// 	}
	// }
}
