# a simple and mostly safe tagged unions library for C3

## api:
```c3
// returns a new tagged union the same type as #var with a tag of #tag and a value of #val.
@taginit(#var, #tag, #val)
// sets the tagged union #var to tag #tag and value #new_val.
@tagset(#var, #tag, #new_val)
// returns the currently used tag by tagged union #var.
@tagof(#var)
// returns the compile-time constant index of #tag from tagged union #var. this is meant to be compared to @tagof(#var) in a switch or if statement
@tagid(#var, #tag)
// returns the value of #var assumming that it has the tag #tag, will panic in safe mode if this is not true
@tagget(#var, #tag)
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
	TaggedUnion x = @taginit(x, FOO, 123);
	switch (@tagof(x))
	{
		case @tagid(x, FOO):
			io::printfn("was foo: %s", @tagget(x, FOO));
		default:
			io::printn("wasn't foo");
	}

	@tagset(x, BAR, "hello");
	if (@tagof(x) == @tagid(x, FOO))
	{
		io::printfn("was foo with val '%s'", @tagget(x, FOO));
	}
	else if (@tagof(x) == @tagid(x, BAR))
	{
		io::printfn("was bar with val '%s'", @tagget(x, BAR));
	}

	@tagset(x, ENUM_TEST, VAL_A);
	assert(@tagget(x, ENUM_TEST) == Test.VAL_A);
	return 0;
}
```
