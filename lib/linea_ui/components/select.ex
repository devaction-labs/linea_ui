defmodule LineaUI.Components.Select do
  @moduledoc """
  LineOne's selects: the styled native `<select>` of the Select page and the searchable
  listbox of the Tom Select page, with chips, groups, a clear button and created options.

      <.select native label="What type of event is it?" options={~w(Wedding Birthday Other)} />
      <.select native variant="filled" shape="pill" size="sm" field={@form[:kind]} options={@kinds} />
      <.select native inline shape="pill" size="sm" name="period" options={~w(Week Month Year)} />

      <.select field={@form[:state]} options={[{"Alabama", "AL"}, {"Alaska", "AK"}]} multiple removable
               placeholder="Select a state..." />
      <.select field={@form[:author]} options={@authors} on_search="search_authors" target={@myself}>
        <:option :let={author}>{author.label} · {author.job}</:option>
      </.select>

  Options are strings, `{label, value}` tuples, keyword entries, or maps with `:label` and
  `:value` (other keys reach the `:option` and `:item` slots); `{group_label, [options]}` is a
  group. See `LineaUI.Components.Select.Options`.

  The listbox submits through a hidden `<select>` named like the field (`name[]` when
  `multiple`), and fires a bubbling `input` event when the person changes the choice, so a
  surrounding `phx-change` runs. A value the server sends wins over the one in the browser;
  re-rendering the same value does nothing.
  """

  use LineaUI.Component

  alias LineaUI.Components.Pickers
  alias LineaUI.Components.Select.Options

  @native %{
    "outline" =>
      "border border-slate-300 bg-white hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent",
    "filled" =>
      "bg-slate-150 ring-primary/50 hover:bg-slate-200 focus:ring-3 dark:bg-navy-900/90 dark:ring-accent/50 dark:hover:bg-navy-900 dark:focus:bg-navy-900"
  }

  @native_sizes %{
    {"sm", true} => "mt-1 h-8 px-2.5 text-xs-plus",
    {"md", true} => "mt-1.5 px-3 py-2",
    {"lg", true} => "mt-1 h-12 px-2.5 text-base",
    {"sm", false} => "h-8 px-2.5 text-xs-plus",
    {"md", false} => "px-3 py-2",
    {"lg", false} => "h-12 px-2.5 text-base"
  }

  @native_shapes %{"rounded" => "rounded-lg", "pill" => "rounded-full px-4"}

  @native_disabled "disabled:pointer-events-none disabled:select-none disabled:border-none disabled:bg-zinc-100 dark:disabled:bg-navy-600"

  @doc """
  Renders a select.

  With `native` it is the browser's `<select>` in LineOne's look; otherwise the listbox.

  ## Fixed choices, no search

  The listbox searches by default (see `search`). For a short, fixed list (a status, a period, a unit,
  yes/no) use `native`: the browser's own `<select>`, with no hook and no search, that submits
  like any input, opens the system picker on a phone and works with the keyboard as a plain
  select does. `prompt` adds a first, empty option; `{group, options}` entries become
  `<optgroup>`s; `inline` shrinks it to its content for a card header.

      <.select native field={@form[:status]} label="Status" prompt="Any status"
               options={[{"Open", "open"}, {"Paid", "paid"}, {"Canceled", "canceled"}]} />
      <form phx-change="period">
        <.select native inline shape="pill" size="sm" name="period" value={@period}
                 options={[{"This week", "week"}, {"This month", "month"}]} />
      </form>

  Only `variant`, `size`, `shape`, `inline` and `prompt` apply to it; `multiple` renders a
  `form-multiselect` box. The listbox-only attrs (`removable`, `clearable`, `create`,
  `on_search`, the slots...) are ignored.

  ## Search

  `search` sets where the person searches the options of the listbox, always in the tonality of
  the component:

    * `"control"` (default): types in the control itself, as in LineOne's Tom Select.
    * `"panel"`: the control is a plain trigger and the list opens with a search field on top
      (`search_placeholder` is its text). Arrow keys, Enter and Esc work from that field.
    * `"none"`: no search, the control is a plain trigger (a short list that fits the screen).

      <.select field={@form[:state]} options={@states} search="panel" search_placeholder="Find a state" />
      <.select field={@form[:status]} options={@statuses} search="none" placeholder="Any status" />

  Events: with `on_search` the listbox stops filtering on its own and pushes
  `on_search` with `%{"id" => id, "query" => text}` as the person types (after `debounce`
  ms), to `target` or to the LiveView/LiveComponent the select is in; the server answers by
  re-rendering `options`.
  """
  attr :id, :string, doc: "Defaults to the field id, then `name`, then a generated one."
  attr :name, :string, doc: "Defaults to the field name (with `[]` when several values)."
  attr :value, :any, doc: "Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: [], doc: "Options and groups, see the module doc."
  attr :prompt, :string, default: nil, doc: "Native only: a first option with an empty value."
  attr :placeholder, :string, default: nil
  attr :multiple, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :native, :boolean, default: false, doc: "The browser's own `<select>`."

  attr :variant, :string,
    default: "outline",
    values: ~w(outline filled),
    doc: "Native only: bordered or filled."

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Native: the height. Listbox: `sm` is the compact 32px control for filter bars."
  attr :shape, :string, default: "rounded", values: ~w(rounded pill), doc: "Native only."

  attr :inline, :boolean,
    default: false,
    doc:
      "Native only: the select is as wide as its content (`w-auto pr-9`) instead of filling its parent, for period pills in a card header."

  attr :removable, :boolean, default: false, doc: "A remove button on each chip."
  attr :clearable, :boolean, default: false, doc: "A button that removes every choice."
  attr :clear_label, :string, default: "Clear"
  attr :remove_label, :string, default: "Remove"
  attr :create, :boolean, default: false, doc: "What is typed can be added as a new option."

  attr :create_label, :string,
    default: "Add",
    doc: "The text before the typed term in the create row."

  attr :persist, :boolean,
    default: true,
    doc: "A created option stays in the list after it is removed."

  attr :restore_on_backspace, :boolean,
    default: false,
    doc: "Backspace puts the last chip back into the input as text."

  attr :max, :integer, default: nil, doc: "How many options can be chosen."

  attr :overflow, :string,
    default: "count",
    values: ~w(count wrap),
    doc:
      "Listbox with `multiple` only: `count` (the default) keeps one line, a pillbox: the chips that do not fit are hidden and a `+N` chip tells how many; `wrap` lets the chips break into more lines and the control grow."

  attr :footer, :boolean,
    default: false,
    doc: "Listbox with `multiple` only: a line under the list with how many are chosen and a hint."

  attr :footer_count, :string,
    default: "%{count} of %{total}",
    doc: "The footer's count; `%{count}` is what is chosen and `%{total}` the options."

  attr :footer_hint, :string, default: "Esc to close", doc: "The footer's hint."

  attr :more_label, :string,
    default: "more",
    doc: "Names the `+N` chip for screen readers (`3 more: Pix, Boleto…`)."

  attr :no_results, :string,
    default: "No results found",
    doc: "Shown when the search matches nothing; `%{query}` is replaced by what was typed."

  attr :search, :string,
    default: "control",
    values: ~w(control panel none),
    doc:
      "Listbox only: `control` types in the control, `panel` opens the list with a search field on top, `none` has no search."

  attr :search_placeholder, :string,
    default: "Search…",
    doc: "Listbox only: the placeholder of the `panel` search field."

  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form autocomplete required)

  slot :option,
    doc: "How an option shows in the list; gets the option map (`label`, `value`, `data`)."

  slot :item, doc: "How a chosen option shows in the control; gets the option map."

  def select(%{native: true} = assigns) do
    assigns
    |> assign_field()
    |> assign_new(:id, fn -> nil end)
    |> assign_new(:name, fn -> nil end)
    |> assign_new(:value, fn -> nil end)
    |> assign(:entries, Options.normalize(assigns.options))
    |> then(&assign(&1, :selected, Options.values(&1.value)))
    |> render_native()
  end

  def select(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("select") end))
    |> then(&assign(&1, :name, &1.name || &1.id))
    |> assign_new(:value, fn -> nil end)
    |> LineaUI.Components.Select.Listbox.prepare(:select)
    |> LineaUI.Components.Select.Listbox.listbox()
  end

  defp render_native(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        merge([
          native_base(assigns.multiple),
          "w-full",
          @native[assigns.variant],
          @native_sizes[{assigns.size, assigns.label != nil}],
          @native_shapes[assigns.shape],
          inline_class(assigns.inline),
          @native_disabled,
          error_class(assigns.errors),
          assigns.class
        ])
      )

    ~H"""
    <Pickers.field label={@label} help={@help} errors={@errors}>
      <select
        id={@id}
        name={@name}
        multiple={@multiple}
        disabled={@disabled}
        class={@classes}
        aria-invalid={@errors != [] && "true"}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        <.native_entry :for={entry <- @entries} entry={entry} selected={@selected} />
      </select>
    </Pickers.field>
    """
  end

  defp inline_class(true), do: "w-auto pr-9"
  defp inline_class(false), do: nil

  defp native_base(true), do: "form-multiselect"
  defp native_base(false), do: "form-select"

  defp error_class([]), do: nil
  defp error_class(_errors), do: "border-error"

  attr :entry, :map, required: true
  attr :selected, :list, required: true

  defp native_entry(%{entry: %{type: :group}} = assigns) do
    ~H"""
    <optgroup label={@entry.label}>
      <.native_entry :for={option <- @entry.options} entry={option} selected={@selected} />
    </optgroup>
    """
  end

  defp native_entry(assigns) do
    ~H"""
    <option value={@entry.value} selected={@entry.value in @selected} disabled={@entry.disabled}>
      {@entry.label}
    </option>
    """
  end
end
