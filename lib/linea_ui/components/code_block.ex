defmodule LineaUI.Components.CodeBlock do
  @moduledoc """
  Code, terminal output, logs and diffs in a quiet card: an optional header with a title and a copy button,
  line numbers, wrapping, added, removed and highlighted lines, and a small size for tool output inside a
  `trace/1`. It is the canvas's `CodeBlock`, in the spirit of the shadcn/ui Code Block.

      <.code_block id="install" title="Terminal" icon="huge-command-line" code={@output} line_numbers wrap />

  ## The code

  `code` is a string, split into lines. `lines` is a list instead, each a string or a map with `:text` and
  `:variant` (`"added"`, `"removed"` or `"highlighted"`), for a diff:

      <.code_block id="diff" title="mix.exs" lines={[
        "defp deps do",
        %{text: ~s(  {:phoenix, "~> 1.7"},), variant: "removed"},
        %{text: ~s(  {:phoenix, "~> 1.8"},), variant: "added"},
        "end"
      ]} />

  `highlight` marks lines by number (`highlight={[2, 3]}`). A line's text is escaped; to show syntax colors pass
  safe HTML, such as `Phoenix.HTML.raw(Makeup.highlight_inner_html(source))`, as the block: the block is drawn
  as is, without line numbers.

  Added and removed lines carry a `+` or `−` before the text, and line numbers sit in a gutter that grows
  with the largest number (`start_line` is the first one). Both are drawn by CSS, so a selection copies the
  code alone. The code itself always runs left to right.

  ## Header and actions

  `title` (with an optional `icon`) puts a header above the code; it truncates. `copy` adds a copy button
  (to the header, or floating at the top end on hover when there is no header) that copies the code without
  the markers. The `:actions` slot adds buttons next to it and the `:footer` slot a row under the code (a
  "Show more", say).

  `size="sm"` is tighter and 12px, for tool output; `variant="destructive"` tints the card for errors and
  failed output. A long block caps its height with `class="[&_pre]:max-h-64"` or `max_height`.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [icon: 1]

  alias LineaUI.Components.Clipboard

  @variants ~w(added removed highlighted)

  @doc """
  Renders the code block.
  """
  attr :id, :string, required: true, doc: "Needed by the copy button and to point at the code."
  attr :code, :string, default: nil, doc: "The code, split into lines."

  attr :lines, :list,
    default: nil,
    doc: "The lines: strings or maps with `:text` and `:variant` (added, removed, highlighted)."

  attr :highlight, :list, default: [], doc: "Line numbers drawn highlighted."
  attr :title, :string, default: nil, doc: "A filename or a label in the header."
  attr :icon, :string, default: nil, doc: "A `huge-*` icon before the title."
  attr :copy, :boolean, default: false, doc: "Adds a copy button."
  attr :copy_label, :string, default: "Copy", doc: "The accessible name of the copy button."
  attr :line_numbers, :boolean, default: false
  attr :start_line, :integer, default: 1, doc: "The number of the first line."
  attr :wrap, :boolean, default: false, doc: "Wraps long lines instead of scrolling."
  attr :max_height, :integer, default: nil, doc: "Caps the height of the code, in px; it scrolls past it."
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "Buttons next to the copy button."
  slot :footer, doc: "A row under the code."
  slot :inner_block, doc: "Code as safe HTML (highlighted), drawn as is."

  def code_block(assigns) do
    assigns =
      assign_derived(assigns, :rows, [:code, :lines, :highlight], fn ->
        rows(assigns.code, assigns.lines, assigns.highlight)
      end)

    assigns = assign(assigns, :text, assigns.rows && Enum.map_join(assigns.rows, "\n", &plain(&1.text)))

    ~H"""
    <div
      id={@id}
      class={merge(["linea-code", @class])}
      data-size={@size != "default" && @size}
      data-variant={@variant != "default" && @variant}
      {@rest}
    >
      <div :if={@title || @actions != []} class="linea-code-h">
        <span :if={@title} class="linea-code-title">
          <.icon :if={@icon} name={@icon} class="size-4" />
          <span class="linea-code-name">{@title}</span>
        </span>
        <span class="linea-code-actions">
          {render_slot(@actions)}
          <.copy_button :if={@copy} id={@id} text={@text} label={@copy_label} />
        </span>
      </div>
      <span :if={@copy && !@title && @actions == []} class="linea-code-actions linea-code-float">
        <.copy_button id={@id} text={@text} label={@copy_label} />
      </span>
      <pre
        id={"#{@id}-code"}
        class="linea-code-pre"
        data-wrap={@wrap}
        data-numbers={@line_numbers && @rows != nil}
        style={code_style(@start_line, @max_height, @rows)}
        tabindex="0"
      ><code :if={@rows}><span
        :for={row <- @rows}
        class="linea-code-line"
        data-variant={row.variant}
      >{row.text}</span></code><code :if={!@rows}>{render_slot(@inner_block)}</code></pre>
      <div :if={@footer != []} class="linea-code-f">{render_slot(@footer)}</div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :text, :string, default: nil
  attr :label, :string, required: true

  defp copy_button(assigns) do
    ~H"""
    <Clipboard.clipboard
      id={"#{@id}-copy"}
      value={@text}
      from={!@text && "##{@id}-code"}
      toast={nil}
      icon_only
      variant="flat"
      size="sm"
      class="linea-code-copy"
      aria-label={@label}
    />
    """
  end

  defp rows(nil, nil, _highlight), do: nil
  defp rows(code, nil, highlight) when is_binary(code), do: rows(nil, String.split(code, ~r/\r?\n/), highlight)

  defp rows(_code, lines, highlight) when is_list(lines) do
    lines
    |> Enum.with_index(1)
    |> Enum.map(fn {line, n} -> row(line, n in highlight) end)
  end

  defp row(%{text: text} = line, highlighted?),
    do: %{text: text, variant: variant(line[:variant], highlighted?)}

  defp row(text, highlighted?), do: %{text: text, variant: variant(nil, highlighted?)}

  defp variant(v, _) when v in @variants, do: v
  defp variant(_, true), do: "highlighted"
  defp variant(_, _), do: nil

  defp plain({:safe, iodata}), do: iodata |> IO.iodata_to_binary() |> strip_tags()
  defp plain(text), do: to_string(text)

  defp strip_tags(html),
    do: html |> String.replace(~r/<[^>]*>/, "") |> String.replace(~w(&lt; &gt; &quot; &#39; &amp;), &unescape/1)

  defp unescape("&lt;"), do: "<"
  defp unescape("&gt;"), do: ">"
  defp unescape("&quot;"), do: "\""
  defp unescape("&#39;"), do: "'"
  defp unescape("&amp;"), do: "&"

  defp code_style(start, max_height, rows) do
    digits = if rows, do: (start + length(rows) - 1) |> Integer.to_string() |> String.length(), else: 1

    [
      start != 1 && "counter-reset:linea-line #{start - 1}",
      "--linea-code-gutter:#{digits}ch",
      max_height && "max-height:#{max_height}px"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
  end
end
