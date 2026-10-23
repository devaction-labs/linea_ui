defmodule LineaUI.Components.TextEditor do
  @moduledoc """
  LineOne's rich text editor (Quill's snow toolbar in LineOne's skin) on a plain
  `contenteditable`: bold, italic, underline, strike, quote, code, headings, lists,
  sub/superscript, indent, text direction, size, font, colors, alignment, links and clean.

      <.text_editor field={@form[:body]} placeholder="Enter your content..." />
      <.text_editor name="note" toolbar={[~w(bold italic underline), ~w(list-ordered list-bullet header-1 background)]} />
      <.text_editor name="post" filled content_class="h-72" />

  The HTML of the text is submitted through a hidden input named like the field, and each edit
  fires a bubbling `input` event, so `phx-change` runs. The editor cleans the HTML it is given
  and the HTML it pastes (only formatting tags and safe links stay), but the server should still
  sanitize what it stores. A value sent by the server replaces the text; the same value echoed
  back does not touch it.
  """

  use LineaUI.Component

  alias LineaUI.Components.Pickers
  alias LineaUI.Components.TextEditor.Icons

  @full [
    ~w(bold italic underline strike),
    ~w(blockquote code-block),
    ~w(header-1 header-2),
    ~w(list-ordered list-bullet),
    ~w(script-sub script-super),
    ~w(indent-minus1 indent-plus1),
    ~w(direction-rtl),
    ~w(size),
    ~w(header),
    ~w(color background),
    ~w(font),
    ~w(align),
    ~w(clean)
  ]

  @buttons ~w(bold italic underline strike blockquote code-block code header-1 header-2 list-ordered list-bullet script-sub script-super indent-minus1 indent-plus1 direction-rtl link clean)

  @doc """
  Renders a rich text editor.

      <.text_editor id="post" name="post[body]" placeholder="Enter your content..." filled />

  `toolbar` is a list of groups, each a list of tools: `bold italic underline strike blockquote
  code-block code header-1 header-2 list-ordered list-bullet script-sub script-super
  indent-minus1 indent-plus1 direction-rtl link clean` (buttons) and `size header color
  background font align` (pickers). The default is LineOne's full toolbar.

  Events: `on_change` is pushed with `%{"id" => id, "value" => html}` after edits (debounced by
  `debounce` ms), to `target` or to the LiveView/LiveComponent the editor is in.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :string, doc: "The HTML of the text; defaults to the field value."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :toolbar, :list, default: @full, doc: "Groups of tool names, see above."

  attr :filled, :boolean,
    default: false,
    doc: "The toolbar on a filled background (LineOne's Filled Header)."

  attr :content_class, :any,
    default: "h-48",
    doc: "Classes of the text area, its height above all."

  attr :link_label, :string, default: "Enter link:"
  attr :save_label, :string, default: "Save"
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def text_editor(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:id, fn -> gen_id("editor") end)
    |> then(&assign_new(&1, :name, fn -> &1.id end))
    |> assign_new(:value, fn -> nil end)
    |> then(&assign(&1, :value, &1.value || ""))
    |> render_editor()
  end

  defp render_editor(assigns) do
    ~H"""
    <Pickers.field label={@label} help={@help} errors={@errors}>
      <div
        id={@id}
        phx-hook="LineaUI.TextEditor"
        phx-target={@target}
        class={merge(["w-full", @label && "mt-1.5", @filled && "ql-header-filled", @class])}
        data-value={@value}
        data-on-change={@on_change}
        data-debounce={@debounce}
        {@rest}
      >
        <div
          class={[
            "ql-toolbar ql-snow",
            @errors != [] && "border-error",
            @disabled && "pointer-events-none opacity-60"
          ]}
          role="toolbar"
          aria-disabled={@disabled && "true"}
          data-toolbar
        >
          <span :for={group <- @toolbar} class="ql-formats">
            <.tool :for={tool <- group} tool={tool} id={@id} disabled={@disabled} />
          </span>
        </div>
        <div
          id={@id <> "-container"}
          class={
            merge([
              "ql-container ql-snow",
              @errors != [] && "border-error",
              @disabled && "cursor-not-allowed bg-slate-50 opacity-60 dark:bg-navy-800",
              @content_class
            ])
          }
          phx-update="ignore"
        >
          <div
            class="ql-editor ql-blank"
            contenteditable={to_string(not @disabled)}
            role="textbox"
            aria-multiline="true"
            aria-label={@label || @placeholder}
            data-placeholder={@placeholder}
            data-editor
          >
          </div>
          <div class="ql-tooltip ql-snow" hidden data-link-box style="left: 15px; top: 10px;">
            <span>{@link_label}</span>
            <input type="text" placeholder="https://" data-link-input />
            <button type="button" data-link-save>{@save_label}</button>
          </div>
          <input type="hidden" id={@id <> "-input"} name={@name} value={@value} data-input />
        </div>
      </div>
    </Pickers.field>
    """
  end

  attr :tool, :string, required: true
  attr :id, :string, required: true
  attr :disabled, :boolean, required: true

  defp tool(%{tool: tool} = assigns) when tool in @buttons do
    ~H"""
    <button
      type="button"
      class={button_class(@tool)}
      aria-label={label(@tool)}
      aria-pressed="false"
      disabled={@disabled}
      data-tool={@tool}
    >
      {Icons.svg(icon(@tool))}
    </button>
    """
  end

  defp tool(%{tool: tool} = assigns) when tool in ~w(color background) do
    assigns = assign(assigns, :colors, palette(tool))

    ~H"""
    <span class={"ql-#{@tool} ql-picker ql-color-picker"} data-picker={@tool}>
      <span
        class="ql-picker-label"
        tabindex="0"
        role="button"
        aria-expanded="false"
        aria-label={@tool}
        data-picker-label
      >
        {Icons.svg("picker-" <> @tool)}
      </span>
      <span class="ql-picker-options" aria-hidden="true" tabindex="-1">
        <span
          :for={{color, index} <- Enum.with_index(@colors)}
          tabindex="0"
          role="button"
          class={[
            "ql-picker-item",
            index < 7 && "ql-primary",
            default_color?(@tool, color) && "ql-selected"
          ]}
          data-value={not default_color?(@tool, color) && color}
          data-item
          style={not default_color?(@tool, color) && "background-color: #{color};"}
          aria-label={color}
        ></span>
      </span>
    </span>
    """
  end

  defp tool(%{tool: "align"} = assigns) do
    ~H"""
    <span class="ql-align ql-picker ql-icon-picker" data-picker="align">
      <span
        class="ql-picker-label"
        tabindex="0"
        role="button"
        aria-expanded="false"
        aria-label="align"
        data-picker-label
      >
        {Icons.svg("picker-align")}
      </span>
      <span class="ql-picker-options" aria-hidden="true" tabindex="-1">
        <span
          :for={value <- ["", "center", "right", "justify"]}
          tabindex="0"
          role="button"
          class={["ql-picker-item", value == "" && "ql-selected"]}
          data-value={value != "" && value}
          data-item
          aria-label={"align " <> (value_or_left(value))}
        >
          {Icons.svg("align-" <> value_or_left(value))}
        </span>
      </span>
    </span>
    """
  end

  defp tool(%{tool: tool} = assigns) when tool in ~w(size header font) do
    assigns = assign(assigns, :values, picker_values(tool))

    ~H"""
    <span class={"ql-#{@tool} ql-picker"} data-picker={@tool}>
      <span
        class="ql-picker-label"
        tabindex="0"
        role="button"
        aria-expanded="false"
        aria-label={@tool}
        data-picker-label
      >
        {Icons.svg("dropdown")}
      </span>
      <span class="ql-picker-options" aria-hidden="true" tabindex="-1">
        <span
          :for={value <- @values}
          tabindex="0"
          role="button"
          class={["ql-picker-item", value == "" && "ql-selected"]}
          data-value={value != "" && value}
          data-item
        ></span>
      </span>
    </span>
    """
  end

  defp button_class(tool) do
    [name | _value] = String.split(tool, "-", parts: 2)
    "ql-" <> base_name(name, tool)
  end

  defp base_name(_name, "code-block"), do: "code-block"
  defp base_name(name, _tool), do: name

  defp label(tool), do: String.replace(tool, "-", " ")

  defp icon("code"), do: "code"
  defp icon(tool), do: tool

  defp value_or_left(""), do: "left"
  defp value_or_left(value), do: value

  defp picker_values("size"), do: ["small", "", "large", "huge"]
  defp picker_values("header"), do: ["1", "2", "3", "4", "5", "6", ""]
  defp picker_values("font"), do: ["", "serif", "monospace"]

  defp palette(_tool), do: ["#000000" | Icons.colors()]

  defp default_color?("color", "#000000"), do: true
  defp default_color?("background", "#ffffff"), do: true
  defp default_color?(_tool, _color), do: false
end
