defmodule LineaUI.Components.TextEditor.Icons do
  @moduledoc false

  @glyphs %{
    "align-center" => :editor_align_center,
    "align-justify" => :editor_align_justify,
    "align-left" => :editor_align_left,
    "align-right" => :editor_align_right,
    "blockquote" => :editor_blockquote,
    "bold" => :editor_bold,
    "clean" => :editor_clean,
    "code" => :editor_code,
    "code-block" => :editor_code_block,
    "dropdown" => :editor_dropdown,
    "header-1" => :editor_header_1,
    "header-2" => :editor_header_2,
    "image" => :editor_image,
    "indent-minus1" => :editor_indent_minus1,
    "indent-plus1" => :editor_indent_plus1,
    "italic" => :editor_italic,
    "link" => :editor_link,
    "list-bullet" => :editor_list_bullet,
    "list-ordered" => :editor_list_ordered,
    "mark" => :editor_mark,
    "picker-align" => :editor_picker_align,
    "picker-background" => :editor_picker_background,
    "picker-color" => :editor_picker_color,
    "script-sub" => :editor_script_sub,
    "script-super" => :editor_script_super,
    "strike" => :editor_strike,
    "underline" => :editor_underline,
    "variable" => :editor_variable,
    "direction-rtl" => :editor_direction
  }

  @colors ~w(#e60000 #ff9900 #ffff00 #008a00 #0066cc #9933ff #ffffff #facccc #ffebcc #ffffcc #cce8cc #cce0f5 #ebd6ff #bbbbbb #f06666 #ffc266 #ffff66 #66b966 #66a3e0 #c285ff #888888 #a10000 #b26b00 #b2b200 #006100 #0047b2 #6b24b2 #444444 #5c0000 #663d00 #666600 #003700 #002966 #3d1466)

  @doc false
  def glyph(name), do: Map.fetch!(@glyphs, name)

  @doc false
  def colors, do: @colors
end
