defmodule LineaUI.Installer.Css do
  @moduledoc """
  The edits `mix linea_ui.install` makes to the app's `assets/css/app.css`, as pure functions
  from the file's contents to its new contents.

  Every edit is idempotent: it finds what it would add and leaves the file alone when it is there.
  """

  @fonts ~s|@import "../../deps/linea_ui/assets/css/fonts.css";|
  @styles ~s|@import "../../deps/linea_ui/assets/css/linea_ui.css";|
  @source ~s|@source "../../deps/linea_ui/lib";|
  @hugeicons ~s|@plugin "../../deps/linea_ui/assets/css/hugeicons.cjs" {\n  dir: "deps/hugeicons/icons";\n}|

  @tailwind_import ~r/^@import\s+["']tailwindcss["'][^;\n]*;/m
  @styles_import ~r/^@import\s+["'][^"']*linea_ui\/assets\/css\/linea_ui\.css["'];/m
  @sources ~r/^@source\s[^\n]*$/m

  @comment "(?:^/\\*(?:(?!\\*/).)*\\*/[ \\t]*\\n)?"
  @daisy_plugins Regex.compile!(
                   @comment <>
                     "^@plugin\\s+[\"'][^\"']*(?:daisyui|heroicons)[^\"']*[\"']\\s*(?:\\{[^}]*\\}|;)[ \\t]*\\n?(?:[ \\t]*\\n)?",
                   "ms"
                 )
  @dark_variant Regex.compile!(
                  @comment <>
                    "^@custom-variant\\s+dark\\s+\\(&:where\\(\\[data-theme=dark\\][^\\n]*\\n?(?:[ \\t]*\\n)?",
                  "ms"
                )

  @doc "Whether the stylesheet still loads daisyUI."
  @spec daisyui?(String.t()) :: boolean()
  def daisyui?(css), do: css =~ ~r/^@plugin\s+["'][^"']*daisyui/m

  @doc "Whether the stylesheet turns Tailwind's automatic source detection off with `source(none)`."
  @spec source_none?(String.t()) :: boolean()
  def source_none?(css), do: css =~ ~r/^@import\s+["']tailwindcss["'][^;\n]*source\(none\)/m

  @doc "Whether the stylesheet imports Tailwind, the anchor the other edits are placed after."
  @spec tailwind?(String.t()) :: boolean()
  def tailwind?(css), do: Regex.match?(@tailwind_import, css)

  @doc """
  Imports LineaUI's fonts and styles after Tailwind's import.

  Returns the stylesheet unchanged when it has no Tailwind import or already imports both.
  """
  @spec import_styles(String.t()) :: String.t()
  def import_styles(css) do
    [@fonts, @styles]
    |> Enum.reject(&String.contains?(css, &1))
    |> import_lines(css)
  end

  defp import_lines([], css), do: css

  defp import_lines(lines, css) do
    insert_after(css, @tailwind_import, Enum.join(lines, "\n"))
  end

  @doc """
  Adds `@source` for LineaUI's templates, which Tailwind needs when `source(none)` turned its
  automatic detection off. Unchanged when the stylesheet already has it.
  """
  @spec add_source(String.t()) :: String.t()
  def add_source(css) do
    css
    |> String.contains?("deps/linea_ui/lib")
    |> source_after(css)
  end

  defp source_after(true, css), do: css

  defp source_after(false, css) do
    case Regex.scan(@sources, css, return: :index) do
      [] -> insert_after(css, @styles_import, @source)
      matches -> matches |> List.last() |> place(css, @source)
    end
  end

  @doc """
  Adds the Hugeicons Tailwind plugin after the LineaUI styles import. Unchanged when present.
  """
  @spec add_hugeicons(String.t()) :: String.t()
  def add_hugeicons(css) do
    css
    |> String.contains?("hugeicons.cjs")
    |> hugeicons_after(css)
  end

  defp hugeicons_after(true, css), do: css
  defp hugeicons_after(false, css), do: insert_after(css, @styles_import, @hugeicons)

  @doc """
  Removes the daisyUI and heroicons `@plugin` blocks (with the comment above each) and the
  `data-theme` dark variant Phoenix generates next to them, which LineaUI's `.dark` class replaces.
  """
  @spec replace_daisyui(String.t()) :: String.t()
  def replace_daisyui(css) do
    css
    |> remove(@daisy_plugins)
    |> remove(@dark_variant)
  end

  defp remove(css, regex), do: Regex.replace(regex, css, "")

  defp insert_after(css, anchor, text) do
    anchor
    |> Regex.run(css, return: :index)
    |> place(css, text)
  end

  defp place(nil, css, _text), do: css

  defp place([{start, length} | _], css, text) do
    {head, tail} = split_at_byte(css, start + length)
    head <> "\n" <> text <> tail
  end

  defp split_at_byte(css, bytes) do
    {binary_part(css, 0, bytes), binary_part(css, bytes, byte_size(css) - bytes)}
  end
end
