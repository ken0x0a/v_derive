module macro

pub struct Derive {
	names []string
}

pub struct Custom {
	name  string            [required]
	attrs map[string]string
}

pub type Macro = Custom | Derive

// pub struct Macro {
// 	typ   MacroType         [required]
// }

pub fn is_macro(text string) bool {
	return text.starts_with('#[') && text.ends_with(']')
}

// macro syntax is
// e.g.:
//   #[macro_name]
//   #[macro_name(attr = "value", attr_int = 22)]
//   #[macro_name(attr = "value", attr_ident = my_func_name)]
pub fn parse_from_text(text string) Macro {
	input := text[2..text.len - 1]
	// eprintln(input)

	mut name := ''
	mut attrs := map[string]string{}
	if input.contains('(') {
		assert input.ends_with(')') // 'Invalid macro syntax. missing `)`'
		parts := input[0..input.len -1].split('(')
		name = parts[0]

		match name {
			'derive' {
				return Derive{
					names: parts[1].split(',').map(it.trim_space())
				}
			}
			else {
				// parts[1]
				arr := parts[1].split(',').map(it.split('=').map(it.trim_space()))
				for val in arr {
					attrs[val[0]] = val[1]
				}
			}
		}
	} else {
		name = input
	}

	return Custom{
		name: name
		attrs: attrs
	}
	// return Macro{
	// 	typ: typ
	// 	name: name
	// 	attrs: attrs
	// }
	// mut name := []rune{}
	// mut is_name_finished := false
	// for t in input.runes() {

	// 	match t {
	// 		`(` {}
	// 		else {
	// 			if !is_name_finished {
	// 				name << t
	// 			} else {

	// 			}
	// 			// panic('unexpected input "$input"')
	// 		}
	// 	}
	// }
}
