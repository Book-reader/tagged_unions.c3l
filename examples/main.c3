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
