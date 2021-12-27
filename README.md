# V Derive

Pre-compile code generation for Vlang

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

MPL-2.0 (is not viral)
https://www.mozilla.org/en-US/MPL/2.0/

I might change the license to MIT and/or Apache-2.0 in future.
So, please give me the right to change license in the future for your contribution,
in case you'll contribute.

## Contributing

More than welcome.
Please read about [the license](#License).
