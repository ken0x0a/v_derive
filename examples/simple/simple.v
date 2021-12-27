module simple

[derive: 'DeserJson, SerJson']
struct Item {
	name  string [required]
	price f64    [required]
}
