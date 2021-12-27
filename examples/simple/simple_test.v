module simple

import x.json2

fn test_struct_item() ? {
	input := '{"name":"Cool Stuff","price":999.9}'
	j := json2.raw_decode(input) ?
	item := macro_deser_json__item(j) ?

	assert item.name == 'Cool Stuff'
	assert item.price == 999.9

	output := item.to_json()

	assert input == output
}
