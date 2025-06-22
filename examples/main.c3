module main;
import tagged_unions;

import std::io;
enum Test
{
	VAL_A,
	VAL_B,
	VAL_C,
}

union __Temp
{
	int foo;
	String bar;
	Test enum_test;

}
struct TaggedUnion @TaggedUnion
{
	Test tag @Tag;
	__Temp a @Union;
	// Doesn't work yet because of a bug
	/*union a @Union
	{
		int foo;
		int bar;
		int baz;
	}*/
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
