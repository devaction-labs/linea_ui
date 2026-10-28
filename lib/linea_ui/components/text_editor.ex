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

  ## Commands, variables, the assistant and a footer

  `slash` opens a menu of blocks when "/" is typed at the start of a word (text, headings, lists,
  quote, code, divider) and `variables` adds the placeholders of a template to it: `{cliente}` is
  drawn as a chip in the editor and goes to the server as the plain text `{cliente}`. The `:ai` slot
  is a button at the end of the toolbar (`on_ai` is pushed with the HTML and the selected text; answer
  with `insert_html/3`), and `footer` draws a bar with a hint and the word count:

      <.text_editor field={@form[:description]} slash variables={~w(cliente preço)} footer
        hint="Markdown shortcuts work. / opens the commands" on_ai="write">
        <:ai>Write with the assistant</:ai>
      </.text_editor>

  The menu takes commands of your own: an entry of `slash_items` whose `key` is not one of the blocks
  is pushed to `on_slash` with that key (the "/" text is removed first), and `hint` is the line after its label:

      <.text_editor name="post" slash on_slash="slash"
        slash_items={[%{key: "paragraph", label: "Text"}, %{key: "image", label: "Image", hint: "Upload a picture", icon: "▣"}]} />

      def handle_event("slash", %{"id" => id, "key" => "image"}, socket), do: ...

  ## Image, variable and highlight buttons

  Three toolbar buttons are opt-in (the default toolbar does not have them), added to a group of `toolbar`:

      <.text_editor name="post" variables={~w(cliente preço)}
        toolbar={[~w(bold italic mark), ~w(link image variable)]} />

    * `mark` toggles a `<mark>` around the selection (the highlight; pressed while the caret is in one).
      It is styled by `.ql-editor mark`, so rendering the saved HTML inside a `ql-editor` element draws it too,
      in dark mode as well.
    * `variable` opens a menu of `variables` at the caret and inserts the chosen `{name}` as a chip, like the
      "/" menu does; it is disabled while `variables` is empty.
    * `image` opens a small field for the address and the description of a picture and inserts an `<img src alt>`.
      With `on_image` set no field opens: the event is pushed with `%{"id" => id}` so the app can upload the file,
      and answers with `insert_image/4`:

          <.text_editor id="post" name="post" on_image="image" toolbar={[~w(bold image)]} />

          def handle_event("image", %{"id" => id}, socket),
            do: {:noreply, TextEditor.insert_image(socket, id, ~p"/uploads/photo.png", "A photo")}

  An `<img>` is kept by the HTML cleaning only in an editor with the image button, `on_image` or `images`, and
  only with an `http(s)` or relative `src` (never `data:`, `javascript:` or `//host`), a `width` and `height` of
  1 to 4000 pixels and an `alt` of up to 300 characters. `<mark>` is kept everywhere. The names of the buttons
  come from `tool_labels` (`%{"image" => "Imagem", "variable" => "Variável", "mark" => "Destacar"}`).

  ## Comments

  `variant="comment"` is the compact editor of a thread: no toolbar, a bar with a "mention" button,
  the `:actions` slot (an attach button) and the submit button; Ctrl+Enter (or Cmd+Enter) submits,
  and "@" opens the list of `mentions`, each drawn as a chip and sent as `@handle`:

      <.text_editor name="comment" variant="comment" on_submit="comment"
        mentions={[%{handle: "juliana-moraes", label: "Juliana Moraes"}]}
        placeholder="Write a comment" />

      def handle_event("comment", %{"value" => html, "mentions" => handles}, socket), do: ...
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

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

  @slash_items [
    %{key: "paragraph", label: "Text", hint: "Plain paragraph", icon: "¶"},
    %{key: "h1", label: "Heading 1", hint: "Big section title", icon: "H1"},
    %{key: "h2", label: "Heading 2", hint: "Medium section title", icon: "H2"},
    %{key: "bullet", label: "Bulleted list", hint: "A simple list", icon: "•"},
    %{key: "ordered", label: "Numbered list", hint: "A list with order", icon: "1."},
    %{key: "quote", label: "Quote", hint: "Highlight a passage", icon: "❝"},
    %{key: "code", label: "Code block", hint: "Monospaced text", icon: "</>"},
    %{key: "divider", label: "Divider", hint: "A horizontal rule", icon: "—"}
  ]

  @doc """
  Pushes `html` to the editor `id`, inserted at the caret (replacing the selection): the answer to
  `on_ai`, from `handle_event/3` or `handle_info/2`. The editor cleans it like pasted text.
  """
  @spec insert_html(Phoenix.LiveView.Socket.t(), String.t(), String.t()) ::
          Phoenix.LiveView.Socket.t()
  def insert_html(%Phoenix.LiveView.Socket{} = socket, id, html),
    do: Phoenix.LiveView.push_event(socket, "linea:editor-insert", %{id: id, html: html})

  @doc """
  Pushes an image to the editor `id`, inserted at the caret: the answer to `on_image`, once the app
  has the address of the uploaded file. The editor drops it unless the `src` is `http(s)` or relative.
  """
  @spec insert_image(Phoenix.LiveView.Socket.t(), String.t(), String.t(), String.t()) ::
          Phoenix.LiveView.Socket.t()
  def insert_image(%Phoenix.LiveView.Socket{} = socket, id, src, alt \\ "") do
    insert_html(socket, id, ~s(<img src="#{escape(src)}" alt="#{escape(alt)}">))
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  @buttons ~w(bold italic underline strike blockquote code-block code header-1 header-2 list-ordered list-bullet script-sub script-super indent-minus1 indent-plus1 direction-rtl link image variable mark clean)

  @tool_labels %{"image" => "Image", "variable" => "Variable", "mark" => "Highlight"}

  @doc """
  Renders a rich text editor.

      <.text_editor id="post" name="post[body]" placeholder="Enter your content..." filled />

  `toolbar` is a list of groups, each a list of tools: `bold italic underline strike blockquote
  code-block code header-1 header-2 list-ordered list-bullet script-sub script-super
  indent-minus1 indent-plus1 direction-rtl link image variable mark clean` (buttons) and `size
  header color background font align` (pickers). The default is LineOne's full toolbar, without
  `image`, `variable` and `mark`: those are buttons you add yourself.

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

  attr :tool_labels, :map,
    default: %{},
    doc:
      "The accessible names of the buttons by tool, e.g. `%{\"mark\" => \"Destacar\"}`; the others keep their English name."

  attr :on_image, :string,
    default: nil,
    doc:
      "The event the `image` button pushes, with `%{\"id\" => id}`, instead of opening the address field; answer with `insert_image/4`."

  attr :images, :boolean,
    default: false,
    doc:
      "Keeps `<img>` in the HTML the editor loads and pastes. On by itself with the `image` button or `on_image`."

  attr :image_label, :string, default: "Image URL:"
  attr :image_alt_label, :string, default: "Description"
  attr :image_save_label, :string, default: "Insert"
  attr :save_label, :string, default: "Save"
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil

  attr :variant, :string,
    default: "default",
    values: ~w(default comment),
    doc:
      "`comment` is the compact editor of a thread: no toolbar, a bar under the text with the mention button, the `:actions` and the submit button."

  attr :slash, :boolean,
    default: false,
    doc: "Typing \"/\" at the start of a word opens the menu of blocks (and the `variables`)."

  attr :slash_items, :list,
    default: @slash_items,
    doc:
      "The entries of the menu: maps with `key` (`paragraph h1 h2 bullet ordered quote code divider`), `label`, and optionally `hint` (a line after the label) and `icon` (a short text). Any other `key` is a custom command: choosing it removes the typed \"/…\" and pushes `on_slash` with that key."

  attr :on_slash, :string,
    default: nil,
    doc:
      "The event a custom entry of the \"/\" menu pushes, with `%{\"id\" => id, \"key\" => key}`; answer with `insert_html/3` if the command inserts something."

  attr :slash_title, :string, default: "Insert", doc: "The caption of the \"/\" menu."

  attr :variables, :list,
    default: [],
    doc:
      "Names of the placeholders of a template (`[\"cliente\"]`): `{cliente}` is shown as a chip, sent as plain text, and offered in the \"/\" menu."

  attr :variable_label, :string, default: "Variable", doc: "The hint of a variable in the menu."

  attr :variable_title, :string,
    default: "Insert variable",
    doc: "The caption of the menu the `variable` button opens."

  attr :mentions, :list,
    default: [],
    doc:
      "People that \"@\" can mention: maps with `handle` and `label`. A mention is a chip, sent as `@handle`."

  attr :mention_title, :string, default: "Mention someone", doc: "The caption of the \"@\" menu."

  attr :mention_label, :string,
    default: "Mention",
    doc: "The label of the mention button of a comment."

  attr :on_ai, :string,
    default: nil,
    doc:
      "The event the `:ai` button pushes, with `%{\"id\" => id, \"value\" => html, \"selection\" => text}`; answer with `insert_html/3`."

  attr :on_submit, :string,
    default: nil,
    doc:
      "The event Ctrl+Enter (and a comment's button) pushes, with `%{\"id\" => id, \"value\" => html, \"mentions\" => handles}`."

  attr :submit_label, :string, default: "Comment"

  attr :submit_key, :string,
    default: "Ctrl ↵",
    doc: "The shortcut shown next to a comment's button."

  attr :clear_on_submit, :boolean, default: true, doc: "Empties the editor after it submits."

  attr :footer, :boolean,
    default: false,
    doc: "A bar under the text with the `hint` and the word count."

  attr :hint, :string, default: nil, doc: "The text at the start of the footer."
  attr :words_label, :string, default: "words", doc: "The word after the count in the footer."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :ai,
    doc: "The content of a button at the end of the toolbar that asks the assistant (`on_ai`)."

  slot :actions, doc: "The buttons at the start of a comment's bar (attach...)."

  def text_editor(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:id, fn -> gen_id("editor") end)
    |> then(&assign_new(&1, :name, fn -> &1.id end))
    |> assign_new(:value, fn -> nil end)
    |> then(&assign(&1, :value, &1.value || ""))
    |> then(&assign(&1, :content_class, content_class(&1.variant, &1.content_class)))
    |> then(&assign(&1, :images, &1.images || &1.on_image != nil || image_tool?(&1.toolbar)))
    |> render_editor()
  end

  defp image_tool?(toolbar), do: Enum.any?(toolbar, &("image" in &1))

  defp content_class("comment", "h-48"), do: "min-h-16"
  defp content_class(_variant, content_class), do: content_class

  defp render_editor(assigns) do
    ~H"""
    <Pickers.field label={@label} help={@help} errors={@errors}>
      <div
        id={@id}
        phx-hook="LineaUI.TextEditor"
        phx-target={@target}
        class={
          merge([
            "relative w-full",
            @label && "mt-1.5",
            @filled && "ql-header-filled",
            @variant == "default" && "ql-box",
            @variant == "default" && @errors != [] && "border-error",
            @variant == "comment" && "ql-comment",
            @class
          ])
        }
        data-value={@value}
        data-on-change={@on_change}
        data-debounce={@debounce}
        data-slash={@slash && Jason.encode!(@slash_items)}
        data-on-slash={@on_slash}
        data-slash-title={@slash_title}
        data-variables={Jason.encode!(@variables)}
        data-variable-label={@variable_label}
        data-variable-title={@variable_title}
        data-images={to_string(@images)}
        data-on-image={@on_image}
        data-mentions={Jason.encode!(@mentions)}
        data-mention-title={@mention_title}
        data-on-ai={@on_ai}
        data-on-submit={@on_submit}
        data-clear-on-submit={to_string(@clear_on_submit)}
        data-words-label={@words_label}
        {@rest}
      >
        <div
          :if={@variant == "default"}
          class={[
            "ql-toolbar ql-snow",
            @disabled && "pointer-events-none opacity-60"
          ]}
          role="toolbar"
          aria-disabled={@disabled && "true"}
          data-toolbar
        >
          <span :for={group <- @toolbar} class="ql-formats">
            <.tool
              :for={tool <- group}
              tool={tool}
              id={@id}
              disabled={@disabled}
              labels={@tool_labels}
              no_variables={@variables == []}
            />
          </span>
          <button :if={@ai != []} type="button" class="ql-ai" disabled={@disabled} data-ai>
            <svg
              class="size-3.5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M12 3l1.8 4.2L18 9l-4.2 1.8L12 15l-1.8-4.2L6 9l4.2-1.8z" />
            </svg>
            {render_slot(@ai)}
          </button>
        </div>
        <div
          id={@id <> "-container"}
          class={
            merge([
              "ql-container ql-snow",
              @disabled && "cursor-not-allowed bg-slate-50 opacity-60 dark:bg-navy-800",
              @footer && "ql-has-footer",
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
          <div
            :if={@images and @on_image == nil and not @disabled}
            class="ql-tooltip ql-snow ql-image-box"
            hidden
            data-image-box
            style="left: 15px; top: 10px;"
          >
            <span>{@image_label}</span>
            <input type="text" placeholder="https://" aria-label={@image_label} data-image-input />
            <input
              type="text"
              placeholder={@image_alt_label}
              aria-label={@image_alt_label}
              data-image-alt
            />
            <button type="button" data-image-save>{@image_save_label}</button>
          </div>
          <input type="hidden" id={@id <> "-input"} name={@name} value={@value} data-input />
        </div>
        <div :if={@footer} class="ql-footer" data-footer>
          <span>{@hint}</span>
          <span data-count></span>
        </div>
        <div :if={@variant == "comment"} class="ql-comment-bar" data-comment-bar>
          {render_slot(@actions)}
          <button
            :if={@mentions != []}
            type="button"
            class="ql-comment-tool"
            aria-label={@mention_label}
            title={@mention_label}
            disabled={@disabled}
            data-mention-button
          >
            @
          </button>
          <kbd :if={@on_submit} class="ql-kbd">{@submit_key}</kbd>
          <button type="button" class="ql-submit" disabled={@disabled} data-submit>
            {@submit_label}
          </button>
        </div>
        <div
          id={@id <> "-menu"}
          class="ql-menu"
          role="listbox"
          phx-update="ignore"
          hidden
          data-menu
          aria-label={@slash_title}
        >
        </div>
      </div>
    </Pickers.field>
    """
  end

  attr :tool, :string, required: true
  attr :id, :string, required: true
  attr :disabled, :boolean, required: true
  attr :labels, :map, default: %{}
  attr :no_variables, :boolean, default: false

  defp tool(%{tool: tool} = assigns) when tool in @buttons do
    ~H"""
    <button
      type="button"
      class={button_class(@tool)}
      aria-label={Map.get(@labels, @tool, label(@tool))}
      aria-pressed={pressable?(@tool) && "false"}
      aria-haspopup={@tool in ~w(variable image) && "true"}
      disabled={@disabled or (@tool == "variable" and @no_variables)}
      data-tool={@tool}
    >
      <.glyph name={Icons.glyph(icon(@tool))} class={nil} />
      <.glyph :if={@tool == "direction-rtl"} name={:editor_direction_active} class={nil} />
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
        <.glyph name={Icons.glyph("picker-" <> @tool)} class={nil} />
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
        <.glyph name={Icons.glyph("picker-align")} class={nil} />
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
          <.glyph name={Icons.glyph("align-" <> value_or_left(value))} class={nil} />
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
        <.glyph name={Icons.glyph("dropdown")} class={nil} />
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

  defp label(tool), do: Map.get(@tool_labels, tool, String.replace(tool, "-", " "))

  defp pressable?(tool), do: tool not in ~w(variable image)

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
