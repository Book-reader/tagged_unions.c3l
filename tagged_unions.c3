module tagged_unions::tu;

attrdef @TaggedUnion = @tag("is_tagged_union", true);
attrdef @Tag = @tag("is_tag", true);
attrdef @Union = @tag("is_union", true);

<*
 @require @is_tagged_union($Type) : "init must be used on a tagged union type"
 @require @has_tagged_union_member($Type, #tag) : "#tag must be a valid tagged union member"
*>
macro init($Type, #tag, #val) @safemacro
{
	$Type new;
	set(new, #tag, #val);
	return new;
}

<*
 @require @is_tagged_union($typeof(#var)) : "set must be used on a tagged union"
 @require @has_tagged_union_member($typeof(#var), #tag) : "#tag must be a valid tagged union member"
*>
macro set(#var, #tag, #new_val) @safemacro
{
	*&@get_tag_member($typeof(#var)).get(#var) = @get_tagged_union_member_id($typeof(#var), #tag);
	@get_union_member($typeof(#var)).get(#var).$eval(@str_lower($stringify(#tag))) = #new_val;
}

<*
 @require @is_tagged_union($typeof(#var)) : "tag must be used on a tagged union"
*>
macro tag(#var) @safemacro => @get_tag_member($typeof(#var)).get(#var);

<*
 @require @is_tagged_union($Type) : "@id must be used on a tagged union"
 @require @has_tagged_union_member($Type, #tag) : "#tag must be a valid tagged union member"
*>
macro @id($Type, #tag) @const => @get_tagged_union_member_id($Type, #tag);

<*
 @require @is_tagged_union($typeof(#var)) : "get must be used on a tagged union"
 @require @has_tagged_union_member($typeof(#var), #tag) : "#tag must be a valid tagged union member"
 @require #var.$eval(@get_tag_member($typeof(#var)).nameof) == @get_tagged_union_member_id($typeof(#var), #tag) : "tried to get the value of the incorrect tag"
*>
macro get(#var, #tag) @safemacro => @get_union_member($typeof(#var)).get(#var).$eval(@str_lower($stringify(#tag)));

macro bool @is_tagged_union($Type) @private
{
	$if !$Type.has_tagof("is_tagged_union"): return false; $endif
	bool $has_tag = false;
	bool $has_union = false;
	$foreach $member : $Type.membersof:
		// $echo @sprintf("%s: %s %s, t:%s u:%s", $member.nameof, $member.typeid.nameof, $member.kindof, $member.has_tagof("is_tag"), $member.has_tagof("is_union"));
		$if $member.has_tagof("is_tag"):
			// $echo "found tag";
			$if $has_tag: $error @sprintf(`Tagged union "%s" cannot have multiple tags`, $Type.nameof); $endif
			$if !is_tag_type($member.typeid): $error @sprintf(`Invalid type for tag "%s %s", must be integer based`, $member.typeid.nameof, $member.nameof); $endif
			$has_tag = true;
		$endif
		$if $member.has_tagof("is_union"):
			// $echo "found union";
			$if $has_union: $error @sprintf(`Tagged union "%s" cannot have multiple unions`, $Type.nameof); $endif
			$if !is_union_type($member.typeid): $error @sprintf(`Invalid type for union "%s %s", must be a union`, $member.typeid.nameof, $member.nameof); $endif
			$has_union = true;
		$endif
	$endforeach
	return $has_tag &&& $has_union;
}

macro @get_tag_member($Type) @const @private
{
	$foreach $member : $Type.membersof:
		$if $member.has_tagof("is_tag"): return $member; $endif
	$endforeach
}


macro @get_union_member($Type) @const @private
{
	$foreach $member : $Type.membersof:
		$if $member.has_tagof("is_union"): return $member; $endif
	$endforeach
}

macro @get_tagged_union_member_id($Type, #tag_name) @const @private
{
	$foreach $i, $member : @get_union_member($Type).membersof:
		$if $member.nameof == @str_lower($stringify(#tag_name)):
			$if @get_tag_member($Type).kindof == ENUM:
				return $typefrom(@get_tag_member($Type).typeid).from_ordinal($i);
			$else
				return ($typefrom(@get_tag_member($Type).typeid))$i;
			$endif
		$endif
	$endforeach
	unreachable("this cannot happen");
}

macro bool @has_tagged_union_member($Type, #tag_name) @const @private
{
	$foreach $i, $member : @get_union_member($Type).membersof:
		$if $member.nameof == @str_lower($stringify(#tag_name)):
			return true;
		$endif
	$endforeach
	return false;
}

macro bool is_tag_type($Type) @private
{
	$switch $Type.kindof:
	$case SIGNED_INT:
	$case UNSIGNED_INT:
		return true;
	$case ENUM:
	$case DISTINCT:
		return is_tag_type($Type.inner);
	$default:
		return false;
	$endswitch
}

macro bool is_union_type($Type) @private
{
	$switch $Type.kindof:
	$case UNION:
		return true;
	$case DISTINCT:
		return is_tag_type($Type.inner);
	$default:
		return false;
	$endswitch

}

