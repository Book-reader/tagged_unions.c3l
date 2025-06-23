# a simple and mostly safe tagged unions library for C3

> [!WARNING]
> This *requires* a C3 version after [aff3a3f](https://github.com/c3lang/c3c/commit/aff3a3f7464b3297930e6e61ce9ff40fe91751c3)
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

// Should be possible to inline in the struct soon once the compiler bug is fixed
union __Token
{
	double number;
	String id @TagIs({"IDENT", "STRING"});
}

struct Token @TaggedUnion
{
	__Token val @Union;
	TokenType type @Tag;
}

fn int main(String[] args)
{
	Token tok = tu::init(Token, INVALID);

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
		case tu::@id(Token, INVALID): // for enum tags the enum or @id can be used, for integer types @id *must* be used
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
