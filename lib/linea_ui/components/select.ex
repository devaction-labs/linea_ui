defmodule LineaUI.Components.Select do
  @moduledoc """
  LineOne's selects: the styled native `<select>` of the Select page and the searchable
  listbox of the Tom Select page, with chips, groups, a clear button and created options.

      <.select native label="What type of event is it?" options={~w(Wedding Birthday Other)} />
      <.select native variant="filled" shape="pill" size="sm" field={@form[:kind]} options={@kinds} />

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

  Events: with `on_search` the listbox stops filtering on its own and pushes
  `on_search` with `%{"id" => id, "query" => text}` as the person types (after `debounce`
  ms), to `target` or to the LiveView/LiveComponent the select is in; the server answers by
  re-rendering `options`.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
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

  attr :size, :string, default: "md", values: ~w(sm md lg), doc: "Native only."
  attr :shape, :string, default: "rounded", values: ~w(rounded pill), doc: "Native only."
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
  attr :no_results, :string, default: "No results found"
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
    |> assign_new(:id, fn -> gen_id("select") end)
    |> then(&assign_new(&1, :name, fn -> &1.id end))
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
