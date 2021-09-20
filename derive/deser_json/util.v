module deser_json

fn to_snake_case(input string) string {
	res := input.replace_each(['A', '_a', 'B', '_b', 'C', '_c', 'D', '_d', 'E', '_e', 'F', '_f',
		'G', '_g', 'H', '_h', 'J', '_j', 'I', '_i', 'K', '_k', 'L', '_l', 'M', '_m', 'N', '_n',
		'O', '_o', 'Q', '_q', 'P', '_p', 'R', '_r', 'S', '_s', 'T', '_t', 'U', '_u', 'V', '_v',
		'X', '_x', 'W', '_w', 'Y', '_y', 'Z', '_z'])

	if res.starts_with('_') {
		return res[1..]
	} else {
		return res
	}
}
