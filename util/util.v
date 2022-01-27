module util

import v.ast
import term

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
	// println(stmt)
	match stmt {
		ast.AsmStmt { dump(stmt) }
		ast.AssertStmt { dump(stmt) }
		ast.AssignStmt { dump(stmt) }
		ast.Block { dump(stmt) }
		ast.BranchStmt { dump(stmt) }
		ast.ComptimeFor { dump(stmt) }
		ast.ConstDecl { dump(stmt) }
		ast.DeferStmt { dump(stmt) }
		ast.EmptyStmt { dump(stmt) }
		ast.EnumDecl { dump(stmt) }
		ast.ExprStmt { dump(stmt) }
		ast.FnDecl { dump(stmt) }
		ast.ForCStmt { dump(stmt) }
		ast.ForInStmt { dump(stmt) }
		ast.ForStmt { dump(stmt) }
		ast.GlobalDecl { dump(stmt) }
		ast.GotoLabel { dump(stmt) }
		ast.GotoStmt { dump(stmt) }
		ast.HashStmt { dump(stmt) }
		ast.Import { dump(stmt) }
		ast.InterfaceDecl { dump(stmt) }
		ast.Module { dump(stmt) }
		ast.NodeError { dump(stmt) }
		ast.Return { dump(stmt) }
		ast.SqlStmt { dump(stmt) }
		ast.StructDecl { dump(stmt) }
		ast.TypeDecl { dump(stmt) }
	}
}

pub fn debug_expr(expr ast.Expr) {
	// println(expr)
	match expr {
		ast.AnonFn { dump(expr) }
		ast.ArrayDecompose { dump(expr) }
		ast.ArrayInit { dump(expr) }
		ast.AsCast { dump(expr) }
		ast.Assoc { dump(expr) }
		ast.AtExpr { dump(expr) }
		ast.BoolLiteral { dump(expr) }
		ast.CTempVar { dump(expr) }
		ast.CallExpr { dump(expr) }
		ast.CastExpr { dump(expr) }
		ast.ChanInit { dump(expr) }
		ast.CharLiteral { dump(expr) }
		ast.Comment { dump(expr) }
		// ast.ComptimeCall { dump(expr) }
		ast.ComptimeSelector { dump(expr) }
		ast.ConcatExpr { dump(expr) }
		ast.DumpExpr { dump(expr) }
		ast.EmptyExpr { dump(expr) }
		ast.EnumVal { dump(expr) }
		ast.FloatLiteral { dump(expr) }
		ast.GoExpr { dump(expr) }
		ast.Ident { dump(expr) }
		ast.IfExpr { dump(expr) }
		ast.IfGuardExpr { dump(expr) }
		ast.IndexExpr { dump(expr) }
		ast.InfixExpr { dump(expr) }
		ast.IntegerLiteral { dump(expr) }
		ast.IsRefType { dump(expr) }
		ast.Likely { dump(expr) }
		ast.LockExpr { dump(expr) }
		ast.MapInit { dump(expr) }
		ast.MatchExpr { dump(expr) }
		ast.NodeError { dump(expr) }
		ast.None { dump(expr) }
		ast.OffsetOf { dump(expr) }
		ast.OrExpr { dump(expr) }
		ast.ParExpr { dump(expr) }
		ast.PostfixExpr { dump(expr) }
		ast.PrefixExpr { dump(expr) }
		ast.RangeExpr { dump(expr) }
		ast.SelectExpr { dump(expr) }
		ast.SelectorExpr { dump(expr) }
		ast.SizeOf { dump(expr) }
		ast.SqlExpr { dump(expr) }
		ast.StringInterLiteral { dump(expr) }
		ast.StringLiteral { dump(expr) }
		ast.StructInit { dump(expr) }
		ast.TypeNode { dump(expr) }
		ast.TypeOf { dump(expr) }
		ast.UnsafeExpr { dump(expr) }
		else {
			eprint(term.red('unsupported type'))
			eprintln(expr.type_name())
			println(expr)
		}
	}
}
