module tagged_unions;

attrdef @TaggedUnion = @tag("is_tagged_union", true);
attrdef @Tag = @tag("is_tag", true);
attrdef @Union = @tag("is_union", true);

<*
 @require @is_tagged_union($typeof(#var)) : "@tagset must be used on a tagged union"
 @require @has_tagged_union_member(#var, #tag) : "#tag must be a valid tagged union member"
*>
macro @taginit(#var, #tag, #val) @builtin
{
	$typeof(#var) new;
	@tagset(new, #tag, #val);
	return new;
}

<*
 @require @is_tagged_union($typeof(#var)) : "@tagset must be used on a tagged union"
 @require @has_tagged_union_member(#var, #tag) : "#tag must be a valid tagged union member"
*>
macro @tagset(#var, #tag, #new_val) @builtin
{
	// TODO: use this once it's fixed
	// @get_tag_member(#var).get(#var) = @get_tagged_union_idx(#var, #tag);
	#var.$eval(@get_tag_member(#var).nameof) = @get_tagged_union_member_id(#var, #tag);
	@get_union_member(#var).get(#var).$eval(@str_lower($stringify(#tag))) = #new_val;
}

<*
 @require @is_tagged_union($typeof(#var)) : "@tagof must be used on a tagged union"
*>
macro @tagof(#var) @builtin => @get_tag_member(#var).get(#var);

<*
 @require @is_tagged_union($typeof(#var)) : "@tagid must be used on a tagged union"
 @require @has_tagged_union_member(#var, #tag) : "#tag must be a valid tagged union member"
*>
macro @tagid(#var, #tag) @builtin @const => @get_tagged_union_member_id(#var, #tag);

<*
 @require @is_tagged_union($typeof(#var)) : "@tagget must be used on a tagged union"
 @require @has_tagged_union_member(#var, #tag) : "#tag must be a valid tagged union member"
 @require #var.$eval(@get_tag_member(#var).nameof) == @get_tagged_union_member_id(#var, #tag) : "tried to get the value of the incorrect tag"
*>
macro @tagget(#var, #tag) @builtin => @get_union_member(#var).get(#var).$eval(@str_lower($stringify(#tag)));

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

macro @get_tag_member(#val) @const @private
{
	$foreach $member : $typeof(#val).membersof:
		$if $member.has_tagof("is_tag"): return $member; $endif
	$endforeach
}


macro @get_union_member(#val) @const @private
{
	$foreach $member : $typeof(#val).membersof:
		$if $member.has_tagof("is_union"): return $member; $endif
	$endforeach
}

macro @get_tagged_union_member_id(#val, #tag_name) @const @private
{
	$foreach $i, $member : @get_union_member(#val).membersof:
		$if $member.nameof == @str_lower($stringify(#tag_name)):
			$if @get_tag_member(#val).kindof == ENUM:
				return $typefrom(@get_tag_member(#val).typeid).from_ordinal($i);
			$else
				return ($typefrom(@get_tag_member(#val).typeid))$i;
			$endif
		$endif
	$endforeach
	unreachable("this cannot happen");
}

macro bool @has_tagged_union_member(#val, #tag_name) @const @private
{
	$foreach $i, $member : @get_union_member(#val).membersof:
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

