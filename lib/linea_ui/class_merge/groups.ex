defmodule LineaUI.ClassMerge.Groups do
  @moduledoc false

  @text_sizes ~w(xs sm base lg xl 2xl 3xl 4xl 5xl 6xl 7xl 8xl 9xl tiny tiny-plus xs-plus sm-plus)
  @font_weights ~w(thin extralight light normal medium semibold bold extrabold black)
  @font_families ~w(sans serif mono inter)
  @align ~w(left center right justify start end)
  @line_styles ~w(solid dashed dotted double none hidden)
  @shadow_sizes ~w(2xs xs sm md lg xl 2xl none inner soft soft-dark)
  @radius_sides ~w(t r b l s e tl tr br bl ss se es ee)
  @bg_keywords ~r/^(fixed|local|scroll|clip-.+|origin-.+|repeat.*|no-repeat|auto|cover|contain|top|bottom|center|left|right|left-.+|right-.+|linear-.+|radial.*|conic.*|gradient-.+|none|blend-.+|size-.+|position-.+)$/

  @display ~w(block inline-block inline flex inline-flex grid inline-grid hidden contents table table-row table-cell flow-root list-item)
  @position ~w(static fixed absolute relative sticky)
  @visibility ~w(visible invisible collapse)

  @spacing_covers %{
    "p" => ~w(px py pt pr pb pl ps pe),
    "px" => ~w(pr pl ps pe),
    "py" => ~w(pt pb),
    "m" => ~w(mx my mt mr mb ml ms me),
    "mx" => ~w(mr ml ms me),
    "my" => ~w(mt mb),
    "inset" => ~w(inset-x inset-y top right bottom left start end),
    "inset-x" => ~w(right left start end),
    "inset-y" => ~w(top bottom),
    "size" => ~w(w h),
    "gap" => ~w(gap-x gap-y),
    "rounded" => Enum.map(@radius_sides, &"rounded-#{&1}"),
    "rounded-t" => ~w(rounded-tl rounded-tr),
    "rounded-r" => ~w(rounded-tr rounded-br),
    "rounded-b" => ~w(rounded-br rounded-bl),
    "rounded-l" => ~w(rounded-tl rounded-bl),
    "border-w" => ~w(border-w-x border-w-y border-w-t border-w-r border-w-b border-w-l),
    "border-w-x" => ~w(border-w-r border-w-l),
    "border-w-y" => ~w(border-w-t border-w-b),
    "overflow" => ~w(overflow-x overflow-y)
  }

  @doc false
  @spec covers(String.t()) :: [String.t()]
  def covers(group), do: Map.get(@spacing_covers, group, [])

  @doc false
  @spec key(String.t()) :: {String.t(), String.t()} | nil
  def key(class) do
    {variants, utility} = split_variants(class)
    {important, utility} = strip_important(utility)

    utility
    |> String.trim_leading("-")
    |> group()
    |> with_prefix(variants <> important)
  end

  defp with_prefix(nil, _prefix), do: nil
  defp with_prefix(group, prefix), do: {prefix, group}

  defp split_variants(class) do
    class
    |> String.graphemes()
    |> Enum.reduce({[], "", 0}, &split_char/2)
    |> then(fn {parts, current, _depth} -> {parts |> Enum.reverse() |> Enum.join(), current} end)
  end

  defp split_char(":", {parts, current, 0}), do: {[current <> ":" | parts], "", 0}
  defp split_char("[" = char, {parts, current, depth}), do: {parts, current <> char, depth + 1}
  defp split_char("]" = char, {parts, current, depth}), do: {parts, current <> char, depth - 1}
  defp split_char(char, {parts, current, depth}), do: {parts, current <> char, depth}

  defp strip_important("!" <> utility), do: {"!", utility}

  defp strip_important(utility) do
    case String.ends_with?(utility, "!") do
      true -> {"!", String.trim_trailing(utility, "!")}
      false -> {"", utility}
    end
  end

  defp group("[" <> rest), do: arbitrary_property(rest)
  defp group(utility) when utility in @display, do: "display"
  defp group(utility) when utility in @position, do: "position"
  defp group(utility) when utility in @visibility, do: "visibility"
  defp group(utility), do: utility |> String.split("-", parts: 2) |> by_root(utility)

  defp arbitrary_property(rest) do
    case String.split(rest, ":", parts: 2) do
      [property, _value] -> "[" <> property
      _ -> nil
    end
  end

  defp by_root([root, value], _utility)
       when root in ~w(p px py pt pr pb pl ps pe m mx my mt mr mb ml ms me),
       do: spacing(root, value)

  defp by_root([root, _value], _utility)
       when root in ~w(w h size z order basis grow shrink opacity leading tracking indent cursor
                       top right bottom left start end aspect columns duration delay ease
                       fill stroke caret accent rotate origin will content object mix select
                       resize scroll snap touch),
       do: root

  defp by_root([root, value], _utility) when root in ~w(translate scale skew),
    do: root <> sub_axis(value)

  defp by_root(["line", "clamp-" <> _], _utility), do: "line-clamp"
  defp by_root(["min", value], _utility), do: "min-" <> axis(value)
  defp by_root(["max", value], _utility), do: "max-" <> axis(value)
  defp by_root(["inset", value], _utility), do: inset(value)
  defp by_root(["gap", value], _utility), do: gap(value)
  defp by_root(["space", value], _utility), do: "space-" <> axis(value)
  defp by_root(["overflow", value], _utility), do: "overflow" <> sub_axis(value)
  defp by_root(["rounded"], _utility), do: "rounded"
  defp by_root(["rounded", value], _utility), do: rounded(value)
  defp by_root(["text", value], _utility), do: text(value)
  defp by_root(["font", value], _utility), do: font(value)
  defp by_root(["bg", value], _utility), do: background(value)
  defp by_root(["border"], _utility), do: "border-w"
  defp by_root(["border", value], _utility), do: border("border", value)
  defp by_root(["outline"], _utility), do: "outline-w"
  defp by_root(["outline", value], _utility), do: line("outline", value)
  defp by_root(["ring"], _utility), do: "ring-w"
  defp by_root(["ring", value], _utility), do: ring(value)
  defp by_root(["shadow"], _utility), do: "shadow"
  defp by_root(["shadow", value], _utility), do: shadow(value)
  defp by_root(["items", _value], _utility), do: "items"
  defp by_root(["justify", value], _utility), do: "justify" <> sub_kind(value)
  defp by_root(["self", _value], _utility), do: "self"
  defp by_root(["place", value], _utility), do: "place-" <> hd(String.split(value, "-"))
  defp by_root(["flex", value], _utility), do: flex(value)
  defp by_root(["grid", value], _utility), do: grid(value)
  defp by_root(["col", value], _utility), do: "col-" <> hd(String.split(value, "-"))
  defp by_root(["row", value], _utility), do: "row-" <> hd(String.split(value, "-"))
  defp by_root(["whitespace", _value], _utility), do: "whitespace"
  defp by_root(["break", _value], _utility), do: "break"
  defp by_root(["truncate"], _utility), do: "text-overflow"
  defp by_root(["transition"], _utility), do: "transition"
  defp by_root(["transition", _value], _utility), do: "transition"
  defp by_root(["animate", _value], _utility), do: "animate"
  defp by_root(["pointer", _value], _utility), do: "pointer-events"
  defp by_root(["blur"], _utility), do: "blur"
  defp by_root(["blur", _value], _utility), do: "blur"
  defp by_root(["backdrop", value], _utility), do: "backdrop-" <> hd(String.split(value, "-"))
  defp by_root(["divide", value], _utility), do: divide(value)
  defp by_root(["from", _value], _utility), do: "gradient-from"
  defp by_root(["via", _value], _utility), do: "gradient-via"
  defp by_root(["to", _value], _utility), do: "gradient-to"
  defp by_root(["uppercase"], _utility), do: "text-transform"
  defp by_root(["lowercase"], _utility), do: "text-transform"
  defp by_root(["capitalize"], _utility), do: "text-transform"
  defp by_root(["normal", "case"], _utility), do: "text-transform"
  defp by_root(["italic"], _utility), do: "font-style"
  defp by_root(["not", "italic"], _utility), do: "font-style"
  defp by_root(["underline"], _utility), do: "text-decoration"
  defp by_root(["no", "underline"], _utility), do: "text-decoration"
  defp by_root(["line", "through"], _utility), do: "text-decoration"
  defp by_root(_parts, _utility), do: nil

  defp spacing(root, _value), do: root

  defp axis("w-" <> _), do: "w"
  defp axis("h-" <> _), do: "h"
  defp axis("x-" <> _), do: "x"
  defp axis("y-" <> _), do: "y"
  defp axis("x"), do: "x"
  defp axis("y"), do: "y"
  defp axis(value), do: value

  defp sub_axis("x-" <> _), do: "-x"
  defp sub_axis("y-" <> _), do: "-y"
  defp sub_axis(_value), do: ""

  defp sub_kind("items-" <> _), do: "-items"
  defp sub_kind("self-" <> _), do: "-self"
  defp sub_kind(_value), do: ""

  defp inset("x-" <> _), do: "inset-x"
  defp inset("y-" <> _), do: "inset-y"
  defp inset(_value), do: "inset"

  defp gap("x-" <> _), do: "gap-x"
  defp gap("y-" <> _), do: "gap-y"
  defp gap(_value), do: "gap"

  defp rounded(value) do
    case String.split(value, "-", parts: 2) do
      [side | _] when side in @radius_sides -> "rounded-" <> side
      _ -> "rounded"
    end
  end

  defp text(value) when value in @text_sizes, do: "text-size"
  defp text(value) when value in @align, do: "text-align"
  defp text(value) when value in ~w(wrap nowrap balance pretty), do: "text-wrap"
  defp text(value) when value in ~w(ellipsis clip), do: "text-overflow"
  defp text("[length:" <> _), do: "text-size"
  defp text("[" <> rest), do: arbitrary_text(rest)
  defp text(_value), do: "text-color"

  defp arbitrary_text(rest) do
    case Regex.match?(~r/^[\d.]+(px|rem|em|%)\]/, rest) do
      true -> "text-size"
      false -> "text-color"
    end
  end

  defp font(value) when value in @font_weights, do: "font-weight"
  defp font(value) when value in @font_families, do: "font-family"
  defp font(_value), do: "font-family"

  defp background(value) do
    case Regex.match?(@bg_keywords, value) do
      true -> "bg-" <> hd(String.split(value, "-"))
      false -> "bg-color"
    end
  end

  defp border(root, value) do
    case String.split(value, "-", parts: 2) do
      [side] when side in ~w(x y t r b l s e) -> "#{root}-w-#{side}"
      [side, rest] when side in ~w(x y t r b l s e) -> border_side(root, side, rest)
      _ -> line(root, value)
    end
  end

  defp border_side(root, side, rest) do
    case width?(rest) do
      true -> "#{root}-w-#{side}"
      false -> "#{root}-color-#{side}"
    end
  end

  defp line(root, value) when value in @line_styles, do: root <> "-style"
  defp line(root, "offset-" <> _), do: root <> "-offset"

  defp line(root, value) do
    case width?(value) do
      true -> root <> "-w"
      false -> root <> "-color"
    end
  end

  defp ring("inset"), do: "ring-inset"
  defp ring("offset-" <> value), do: line("ring-offset", value)
  defp ring(value), do: line("ring", value)

  defp shadow(value) when value in @shadow_sizes, do: "shadow"
  defp shadow(_value), do: "shadow-color"

  defp divide("x"), do: "divide-x"
  defp divide("y"), do: "divide-y"
  defp divide(value), do: line("divide", value)

  defp flex(value) when value in ~w(row row-reverse col col-reverse), do: "flex-direction"
  defp flex(value) when value in ~w(wrap wrap-reverse nowrap), do: "flex-wrap"
  defp flex(_value), do: "flex"

  defp grid("cols-" <> _), do: "grid-cols"
  defp grid("rows-" <> _), do: "grid-rows"
  defp grid("flow-" <> _), do: "grid-flow"
  defp grid(_value), do: nil

  defp width?(value), do: Regex.match?(~r/^(\d+|\[\d.*(px|rem)\]|\(length:.*\))$/, value)
end
