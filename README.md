
# V Derive

Pre-compile code generation for Vlang

![Test](https://github.com/ken0x0a/v_derive/actions/workflows/v-compatibility-check.yml/badge.svg)

## Usage

There is some options for customization, but not yet documented.
See [examples](#Examples) for the basic usage.

### Build
```sh
git clone https://github.com/ken0x0a/v_derive derive
cd derive 
v -o derive bin/derive
```

### Generate code
```sh
./derive <file_or_directory_name> [output_filename]
```

## Examples

See https://github.com/ken0x0a/v_derive_example

```v ignore
[derive: 'DeserJson, SerJson']
struct Item {
	name  string [required]
	price f64    [required]
}

// in other file
import x.json2

input := '{"name":"Cool Stuff","price":999.9}'
j := json2.raw_decode(input) ?
item := macro_deser_json__item(j) ?

assert item.name == 'Cool Stuff'
assert item.price == 999.9

output := item.to_json()

assert input == output
```

## License

Most code is under **MPL-2.0** (is not viral)
https://www.mozilla.org/en-US/MPL/2.0/

I might change the license to MIT and/or Apache-2.0 in future.
So, please give me the right to change license in the future for your contribution,
in case you'll contribute.

### Other licenses
/codegen/type.v is [MIT License](https://github.com/vlang/v/blob/5162c257a22f9005c0ec055727cedd10e85705ea/LICENSE)
/codegen/parse_stmt.v is [MIT License](https://github.com/vlang/v/blob/ac2c3847afc0f7a9a0d3b99064188124df6a6fb5/LICENSE)

## Contributing

More than welcome.
Please read about [the license](#License).
