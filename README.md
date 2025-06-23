# a simple and mostly safe tagged unions library for C3

> [!WARNING]
> This *requires* a C3 version after [aff3a3f](https://github.com/c3lang/c3c/commit/aff3a3f7464b3297930e6e61ce9ff40fe91751c3), and versions after [affb722](https://github.com/c3lang/c3c/commit/affb722b23deb1401ffd5153368ebaad791e8533) to inline the definition of the union
>
> Older versions may work but will be unable to use the `@TagIs` feature

## api:
```cpp
// returns a new tagged union of type $Type with a tag of #tag and a value of #val. #tag must be the name of the union member converted to uppercase or a name specified by `@TagIs`.
tu::init($Type, #tag, #val);
// sets the tagged union #var to tag #tag and value #new_val.
tu::set(#var, #tag, #new_val);
// returns the currently used tag by tagged union #var.
tu::tag(#var);
// returns the compile-time constant index of #tag from tagged union type $Type. this is meant to be compared to tu::tag(#var) in a switch or if statement. not needed for tagged unions with enum tags
tu::@id($Type, #tag);
// returns the value of #var assumming that its current value is of tag #tag, will panic in safe mode if this is not true
tu::get(#var, #tag);
```

to create a tagged union, create a struct annotated with `@TaggedUnion`, then place in it an integer or enum annotated with `@Tag` and a union annotated with `@Union`

getting and setting the the tagged union use `tu::get(union, TAG)` and `tu::set(union, TAG, val)`, where the second parameter is the name of the union value in uppercase

`@TagIs({"NAME1", "NAME2", ...})` can be added to any union member to change tag used to refer to it or allow multiple tags to refer to it

## example usage:
```cpp
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

// You can define convenience methods if needed:
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
```
