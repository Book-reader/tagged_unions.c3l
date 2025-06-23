/*
 MIT License

 Copyright (c) 2025 Book-reader

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/
module tagged_unions::tu;

attrdef @TaggedUnion = @tag("is_tagged_union", true);
attrdef @Tag = @tag("is_tag", true);
attrdef @Union = @tag("is_union", true);
// TODO: replace with String[] once bug is fixed
attrdef @TagIs(String[] name) = @tag("tag_name", name);
// TODO: check if this should be allowed
// attrdef @Priv = @const, @private;
macro bool String[].@contains($self, String $other) @const
{
	$foreach $s : $self:
		$if $s == $other:
			return true;
		$endif
	$endforeach
	return false;
}

macro bool String[].@contains_any($self, String[] $other) @const
{
	$foreach $s : $other:
		$if $self.@contains($s):
			return true;
		$endif
	$endforeach
	return false;
}

macro bool String[].@has_mismatch($self, String[] $other) @const
{
	$foreach $s : $other:
		$if !$self.@contains($s):
			return true;
		$endif
	$endforeach
	return false;
}


macro String String[].@first_match($self, String[] $other) @const
{
	bool $found;
	$foreach $s : $other:
		$if $self.@contains($s):
			$found = true;
			return $s;
		$endif
	$endforeach
	$assert($found);
}

macro String String[].@first_mismatch($self, String[] $other) @const
{
	bool $found;
	$foreach $s : $other:
		$if !$self.@contains($s):
			$found = true;
			return $s;
		$endif
	$endforeach
	$assert($found);
}

macro String[].@index_of($self, String $other) @const
{
	bool $found;
	$foreach $i, $s : $self:
		$if $s == $other:
			$found = true;
			return $i;
		$endif
	$endforeach
	$assert($found);
}

<*
 @require validate_tagged_union($Type)
 @require @validate_tagged_union_tag($Type, #tag)
*>
macro init($Type, #tag, #val = EMPTY_MACRO_SLOT) @safemacro
{
	$Type new;
	set(new, #tag, #val);
	return new;
}

<*
 @require validate_tagged_union($typeof(#var))
 @require @validate_tagged_union_tag($typeof(#var), #tag)
*>
macro set(#var, #tag, #new_val = EMPTY_MACRO_SLOT) @safemacro
{
	var $Type = $typeof(#var);
	*&get_tag($Type).get(#var) = @tag_id($Type, #tag);
	$if $stringify(#new_val) == "EMPTY_MACRO_SLOT":
		$if @has_union_member($Type, #tag):
			$error @sprintf(`Tried to set tag "%s" with value to an empty value`, $stringify(#tag));
		$endif
	$else
		$if !@has_union_member($Type, #tag):
			$error @sprintf(`Tried to set tag "%s" with no value to a value`, $stringify(#tag));
		$endif
		*&@union_member($Type, #tag).get(get_union($Type).get(#var)) = #new_val;
	$endif
}

<*
 @require validate_tagged_union($typeof(#var))
*>
macro tag(#var) @safemacro => get_tag($typeof(#var)).get(#var);

<*
 @require validate_tagged_union($Type)
 @require @validate_tagged_union_tag($Type, #tag)
*>
macro @id($Type, #tag) @const => @tag_id($Type, #tag);

<*
 @require validate_tagged_union($typeof(#var))
 @require @validate_tagged_union_tag($typeof(#var), #tag)
 @require @has_union_member($typeof(#var), #tag) : "tried to get the value of a tag without value"
 @require #var.$eval(get_tag($typeof(#var)).nameof) == @tag_id($typeof(#var), #tag) : "tried to get the value of the incorrect tag"
*>
macro get(#var, #tag) @safemacro => @union_member($typeof(#var), #tag).get(get_union($typeof(#var)).get(#var));

macro bool validate_tagged_union($Type) @private @const
{
	$if !is_struct_type($Type): $error @sprintf(`Type "%s" is not a struct type and so cannot be a tagged union`, $Type.nameof); $endif
	$if !$Type.has_tagof("is_tagged_union"): $error @sprintf(`Tagged union type "%s" must be annotated with @TaggedUnion`, $Type.nameof); $endif

	$if !has_tag_member($Type): $error @sprintf(`Tagged union "%s" doesn't have a tag marked with @Tag`, $Type.nameof); $endif
	$if !has_union_member($Type): $error @sprintf(`Tagged union "%s" doesn't have a union marked with @Union`, $Type.nameof); $endif

	var $TagType = get_tag($Type).typeid;
	String[] $names;
	$foreach $member : get_union($Type).membersof:
		String[] $member_names = member_names($member);
		$if has_enum_tag($Type):
			$if $TagType.names.@has_mismatch($member_names):
				$error @sprintf(`at "%s %s": Invalid tag name "%s" for enum-based tagged union. valid names are "%s".`"\n"`consider using "@TagIs({"NAME"})" to change it to a valid name`, $member.typeid.nameof, $member.nameof, $TagType.names.@first_mismatch($member_names), $TagType.names);
			$endif
		$endif
		$if !$names.@contains_any($member_names):
			$names = (String[])($names +++ $member_names);
		$else
			$error @sprintf(`Duplicate tag name "%s" at "%s %s"`, $names.@first_match($member_names), $member.typeid.nameof, $member.nameof);
		$endif
	$endforeach
	
	return true;
}

macro bool @validate_tagged_union_tag($Type, #tag) @private @const
{
	$if @has_tag_variant($Type, #tag):
		return true;
	$else
		$error @sprintf(`Invalid tag name "%s", options are "%s"`, $stringify(#tag), all_tag_names($Type));
	$endif
}

macro @union_member($Type, #tag) @private @const
{
	bool $found;
	$foreach $member : get_union($Type).membersof:
		$if member_names($member).@contains($stringify(#tag)):
			$found = true;
			return $member;
		$endif
	$endforeach
	$assert($found);
}

macro @tag_id($Type, #tag) @private @const
{
	var $TagType = get_tag($Type).typeid;
	$if has_enum_tag($Type):
		$TagType $enum = #tag;
		return $enum;
	$else
		var $names = all_tag_names($Type);
		return ($TagType)$names.@index_of($stringify(#tag));
	$endif
}

macro String[] all_tag_names($Type) @private @const
{
	String[] $names;
	$if has_enum_tag($Type):
		$names = $typefrom(get_tag($Type).typeid).names;
	$else
		$foreach $member : get_union($Type).membersof:
			$names = $names +++ member_names($member);
		$endforeach
	$endif
	return $names;
}

macro String[] member_names($member) @private @const
{
	$if $member.has_tagof("tag_name"):
		return $member.tagof("tag_name");
	$else
		return {@str_upper($member.nameof)};
	$endif
}

macro bool @has_union_member($Type, #tag) @private @const
{
	$foreach $member : get_union($Type).membersof:
		$if member_names($member).@contains($stringify(#tag)):
			return true;
		$endif
	$endforeach
	return false;
}

macro bool @has_tag_variant($Type, #tag) @private @const
{
	$if has_enum_tag($Type):
		var $TagType = get_tag($Type).typeid;
		// $echo $TagType.names;
		// $echo $stringify(#tag);
		return $TagType.names.@contains($stringify(#tag));
	$else
		$foreach $member : get_union($Type).membersof:
			$switch:
			$case $member.has_tagof("tag_name") &&& $member.tagof("tag_name").@contains($stringify(#tag)):
			$case !$member.has_tagof("tag_name") &&& $member.nameof == @str_lower($stringify(#tag)):
				return true;
			$endswitch
		$endforeach
	$endif

	return false;
}

macro bool has_enum_tag($Type) @private @const
{
	var $tag = get_tag($Type);

	$switch $tag.kindof:
	$case ENUM:
		return true;
	$case DISTINCT:
		return $typefrom($tag.typeid).inner.kindof == ENUM;
	$default:
		return false;
	$endswitch
}

macro get_tag($Type) @private @const
{
	bool $found;
	$foreach $member : $Type.membersof:
		$if $member.has_tagof("is_tag"):
			$found = true;
			return $member;
		$endif
	$endforeach
	$assert($found);
}

macro get_union($Type) @private @const
{
	bool $found;
	$foreach $member : $Type.membersof:
		$if $member.has_tagof("is_union"):
			$found = true;
			return $member;
		$endif
	$endforeach
	$assert($found);
}

macro bool has_tag_member($Type) @private @const
{
	bool $has_tag;
	$foreach $member : $Type.membersof:
		$if $member.has_tagof("is_tag"):
			$if $has_tag:
				$error @sprintf(`Tagged union type "%s" has multiple tags defined (second is "%s %s")`, $Type.nameof, $member.typeid.nameof, $member.nameof);
			$else
				$if is_int_type($member.typeid):
					$has_tag = true;
				$else
					$error @sprintf(`Tag "%s %s" must be either integer type or an enum`, $member.typeid.nameof, $member.nameof);
				$endif
			$endif
		$endif
	$endforeach
	return $has_tag;
}

macro bool has_union_member($Type) @private @const
{
	bool $has_union;
	$foreach $member : $Type.membersof:
		$if $member.has_tagof("is_union"):
			$if $has_union:
				$error @sprintf(`Tagged union type "%s" has multiple unions defined (second is "%s %s")`, $Type.nameof, $member.typeid.nameof, $member.nameof);
			$else
				$if is_union_type($member.typeid):
					$has_union = true;
				$else
					$error @sprintf(`Tag "%s %s" must be a union`, $member.typeid.nameof, $member.nameof);
				$endif
			$endif
		$endif
	$endforeach
	return $has_union;
}

macro bool is_struct_type($Type) @private @const
{
	$switch $Type.kindof:
		$case STRUCT:
			return true;
		$case POINTER:
		$case DISTINCT:
			return is_struct_type($Type.inner);
		$default:
			return false;
	$endswitch
}

macro bool is_int_type($Type) @private @const
{
	$switch $Type.kindof:
		$case SIGNED_INT:
		$case UNSIGNED_INT:
			return true;
		$case ENUM:
		$case DISTINCT:
			return is_int_type($Type.inner);
		$default:
			return false;
	$endswitch
}

macro bool is_union_type($Type) @private @const
{
	$switch $Type.kindof:
		$case UNION:
			return true;
		$case DISTINCT:
			return is_union_type($Type.inner);
		$default:
			return false;
	$endswitch

}
