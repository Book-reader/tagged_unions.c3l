module main;
import tagged_unions;

import std::io;

enum TokenType : char
{
	INVALID,
	LPAREN,
	RPAREN,
	PLUS,
	MINUS,
	NUMBER,
	IDENT,
	STRING,
}

struct Token @TaggedUnion
{
	union val @Union
	{
		double number;
		String id @TagIs({"IDENT", "STRING"});
	}
	TokenType type @Tag;
	usz tok_id; // other values are allowed
}

// You can define convenience methods if needed
// macro Token.get(#self, #tag) @safemacro => tu::get(#self, #tag);
// macro Token.set(#self, #tag, #val = EMPTY_MACRO_SLOT) @safemacro => tu::set(#self, #tag, #val);

fn int main(String[] args)
{
	Token tok = tu::init(Token, INVALID);
	tok.tok_id = 1;

	if (args.len > 1) switch (args[1])
	{
		case "(": tu::set(tok, LPAREN);
		case ")": tu::set(tok, RPAREN);
		case "+": tu::set(tok, PLUS);
		case "-": tu::set(tok, MINUS);
		default:
			if (try num = args[1].to_double())
			{
				tu::set(tok, NUMBER, num);
			}
			else
			{
				if (args[1][0] == '"' && args[1][^1] == '"')
				{
					tu::set(tok, STRING, args[1][1..^2]);
				}
				else
				{
					tu::set(tok, IDENT, args[1]);
				}
			}
	}

	switch (tu::tag(tok))
	{
		case tu::@id(Token, INVALID): // for enum tags the enum or @id can be used, for integer tags @id *must* be used
		case LPAREN:
		case RPAREN:
		case PLUS:
		case MINUS:
			io::printfn("token was %s", tu::tag(tok));
		case NUMBER:
			io::printfn("got number '%s'", tu::get(tok, NUMBER));
		case IDENT:
			io::printfn("got ident '%s'", tu::get(tok, IDENT));
		case STRING:
			io::printfn("got string '%s'", tu::get(tok, STRING));
	}
	return 0;
}

/*
import std::io;
enum Test
{
	FOO,
	VAL_A,
	VAL_B,
	VAL_C,
}
typedef Aa = Test;
union __Temp
{
	int foo @TagIs({"FOO", "BAR"}); // @id(FOO) != @id(BAR)
	String bar @TagIs({"FOO1"});
	Test enum_test;

}
struct TaggedUnion @TaggedUnion
{
	// Test tag @Tag;
	char tag @Tag;
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
	TaggedUnion x = tu::init(TaggedUnion, FOO1, "hello");
//	tu::set(x, FOO1, "hello");
	io::printfn("%s %s", x.tag, x.a.bar);
	switch (tu::tag(x))
	{
		case tu::@id(TaggedUnion, FOO1):
			io::printfn("was foo: %s", tu::get(x, FOO1));
		default:
			io::printn("wasn't foo");
	}

	tu::set(x, BAR, 123);
	if (tu::tag(x) == tu::@id(TaggedUnion, FOO1))
	{
		io::printfn("was foo with val '%s'", tu::get(x, FOO1));
	}
	else if (tu::tag(x) == tu::@id(TaggedUnion, BAR))
	{
		io::printfn("was bar with val '%s'", tu::get(x, BAR));
	}

	tu::set(x, ENUM_TEST, VAL_A);
	assert(tu::get(x, ENUM_TEST) == Test.VAL_A);
	return 0;
}
