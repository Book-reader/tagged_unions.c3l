# a simple and mostly safe tagged unions library for C3

## api:
```c3
// returns a new tagged union of type $Type with a tag of #tag and a value of #val.
tu::init($Type, #tag, #val)
// sets the tagged union #var to tag #tag and value #new_val.
tu::set(#var, #tag, #new_val)
// returns the currently used tag by tagged union #var.
tu::tag(#var)
// returns the compile-time constant index of #tag from tagged union type $Type. this is meant to be compared to tu::tag(#var) in a switch or if statement
tu::@id($Type, #tag)
// returns the value of #var assumming that it has the tag #tag, will panic in safe mode if this is not true
tu::get(#var, #tag)
```

## example usage:
```c3
import tagged_unions;
import std::io;

enum Test
{
	VAL_A,
	VAL_B,
}

struct TaggedUnion @TaggedUnion
{
	char tag @Tag;
	union vals @Union
	{
		int foo;
		String bar;
		Test enum_test;
	}
	// this is allowed
	int always_existing_val;
}

fn int main(String[] args)
{
	TaggedUnion x = tu::init(TaggedUnion, FOO, 123);
	switch (tu::tag(x))
	{
		case tu::@id(TaggedUnion, FOO):
			io::printfn("was foo: %s", tu::get(x, FOO));
		default:
			io::printn("wasn't foo");
	}

	tu::set(x, BAR, "hello");
	if (tu::tag(x) == tu::@id(TaggedUnion, FOO))
	{
		io::printfn("was foo with val '%s'", tu::get(x, FOO));
	}
	else if (tu::tag(x) == tu::@id(TaggedUnion, BAR))
	{
		io::printfn("was bar with val '%s'", tu::get(x, BAR));
	}

	tu::set(x, ENUM_TEST, VAL_A);
	assert(tu::get(x, ENUM_TEST) == Test.VAL_A);
	return 0;
}
```
