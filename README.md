# a simple and mostly safe tagged unions library for C3

## api:
```cpp
// returns a new tagged union of type $Type with a tag of #tag and a value of #val. #tag must be the name of the union member converted to uppercase.
tu::init($Type, #tag, #val)
// sets the tagged union #var to tag #tag and value #new_val.
tu::set(#var, #tag, #new_val)
// returns the currently used tag by tagged union #var.
tu::tag(#var)
// returns the compile-time constant index of #tag from tagged union type $Type. this is meant to be compared to tu::tag(#var) in a switch or if statement
tu::@id($Type, #tag)
// returns the value of #var assumming that its current value is of tag #tag, will panic in safe mode if this is not true
tu::get(#var, #tag)
```

to create a tagged union, create a struct annotated with `@TaggedUnion`, then place in it an integer or enum annotated with `@Tag` and a union annotated with `@Union`

## example usage:
```cpp
import tagged_unions;
import std::io;

struct TaggedUnion @TaggedUnion
{
	char tag @Tag;
	// NOTE: currently this doesn't work due to a bug, it will need to be a separate union type eg: 'MyUnion vals @Union'
	union vals @Union
	{
		int foo;
		String bar;
	}
	// extra values are allowed
	int always_existing_val;
}

fn int main(String[] args)
{
	// tu::init is optional
	TaggedUnion x = tu::init(TaggedUnion, FOO, 123);
	switch (tu::tag(x))
	{
		case tu::@id(TaggedUnion, FOO):
			io::printfn("was foo with value '%s'", tu::get(x, FOO));
		default:
			io::printn("wasn't foo");
	}

	tu::set(x, BAR, "hello");
	if (tu::tag(x) == tu::@id(TaggedUnion, BAR))
	{
		io::printfn("was bar with val '%s'", tu::get(x, BAR));
	}

	// this will cause a panic at runtime in safe mode (opt level -O1 and below, or with --safe=yes)
	tu::get(x, FOO);
	return 0;
}
```
