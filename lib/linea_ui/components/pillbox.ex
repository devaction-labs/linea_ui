defmodule LineaUI.Components.Pillbox do
  @moduledoc """
  A multiple choice from a list, drawn as the design canvas's Pillbox: the chosen options become pills inside
  the field, and the list opens under it with a search on top and a check box on every option.

      <.pillbox field={@form[:categories]} label="Categories" options={@categories} />

      <.pillbox
        name="categories"
        value={["tintas", "acessorios"]}
        options={[
          %{label: "Tintas", value: "tintas", count: 128},
          %{label: "Ferramentas", value: "ferramentas", count: 86},
          %{label: "Acessórios", value: "acessorios", count: 54}
        ]}
        clear
      />

      <.pillbox name="tags" options={@tags} value={@chosen} create create_label="Create" />
      <.pillbox name="branches" options={@branches} value={@chosen} overflow="wrap" />
      <.pillbox name="people" options={@people} value={@chosen} />
      <.pillbox name="branches" options={@branches} value={@chosen} readonly label="Branches (read only)" />

  Options are strings, `{label, value}` tuples or maps with `:label` and `:value`, as in
  `LineaUI.Components.Select.Options`. A map can also carry

    * `:count`: a faint mono number on the right of its row;
    * `:color` and `:initials`: a person. Its pill gets a 22px avatar with that background; the initials
      default to the first letters of the first and last word of the label.

  ## Overflow

  By default the field keeps to the width the layout gave it and stays on one line (`overflow="one"`): the pills
  that do not fit are hidden and a `+N` pill takes their place. Its `title` lists the hidden names and its
  `aria-label` is `hidden_label` (`"3 hidden"`; `%{count}` is the number). The hook measures on mount, on every
  change and when the field is resized. `overflow="wrap"` lets the pills break into more lines and the field
  grow; use it only where the height can vary.

  ## The list

  It opens on click, Enter or the arrow keys. The search field on top (`search_placeholder`) filters the options
  ignoring case and accents and shows what matched in bold. Arrow keys move, Enter or a click toggles the option
  (the list stays open), Backspace on an empty search takes the last pill back and Esc closes. With `create` a
  typed term that is not an option is offered as a last row (`create_label` before the term in curly quotes, and
  `create_hint`, the key, on the right); choosing it adds a pill and an option. When nothing matches,
  `empty_label` (`%{query}` is the term) is said above that row.

  ## Form

  The pills are submitted as `name[]`, with an empty `name[]` first so that an emptied field still reaches the
  server, and each change fires a bubbling `input` event for `phx-change`. `readonly` keeps the values in the form
  but takes the x, the chevron and the list away; `disabled` does that and leaves them out of the form.

  It is the `LineaUI.Components.Select` listbox (`multiple`, `search="panel"`), so it shares its hook
  (`LineaUI.Select`), the options and the server-side search (`on_search`, `target`, `debounce`).
  """

  use LineaUI.Component

  alias LineaUI.Components.Select.Listbox

  @doc """
  Renders a pillbox.

  Events: with `on_search`, `%{"id" => id, "query" => text}` is pushed to `target` (or the LiveView) as the person
  searches, `debounce` ms after the last key; the server answers by re-rendering `options`.
  """
  attr :id, :string, doc: "Defaults to the field id, then `name`, then a generated one."
  attr :name, :string, doc: "Defaults to the field name; `[]` is appended."
  attr :value, :any, doc: "The chosen values (a list). Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :options, :list, default: [], doc: "Options and groups, see the module doc."

  attr :selected_options, :list,
    default: [],
    doc:
      "Options for chosen values that are not in `options` (after a server search narrowed it)."

  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil, doc: "Shown in the empty field."
  attr :search_placeholder, :string, default: "Search…"

  attr :overflow, :string,
    default: "one",
    values: ~w(one wrap),
    doc:
      "`one` keeps one line and sums the pills that do not fit in a `+N` pill; `wrap` breaks lines."

  attr :create, :boolean, default: false, doc: "A typed term that is not an option can be added."
  attr :create_label, :string, default: "Create", doc: "The text before the typed term."
  attr :create_hint, :string, default: "↵", doc: "The key shown on the right of the create row."

  attr :empty_label, :string,
    default: "No results found",
    doc: "Said when the search matches nothing; `%{query}` is replaced by the term."

  attr :clear, :boolean, default: false, doc: "A button that takes every pill back."
  attr :clear_label, :string, default: "Clear"
  attr :remove_label, :string, default: "Remove"

  attr :hidden_label, :string,
    default: "%{count} hidden",
    doc: "The `aria-label` of the `+N` pill; `%{count}` is how many are hidden."

  attr :readonly, :boolean,
    default: false,
    doc: "Values are shown and submitted but cannot change."

  attr :disabled, :boolean, default: false
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form required)

  def pillbox(assigns) do
    assigns
    |> assign_field()
    |> put_default(:name, nil)
    |> put_default(:value, nil)
    |> then(&assign_new(&1, :id, fn -> &1.name || stable_id("pillbox", &1) end))
    |> then(&assign(&1, :name, &1.name || &1.id))
    |> assign(:options, with_hints(assigns.options))
    |> assign(
      multiple: true,
      look: "pillbox",
      search: "panel",
      create_position: "bottom",
      removable: not (assigns.readonly or assigns.disabled),
      clearable: assigns.clear and not assigns.readonly,
      no_results: assigns.empty_label,
      overflow: if(assigns.overflow == "wrap", do: "wrap", else: "count"),
      persist: true,
      restore_on_backspace: false,
      max: nil,
      prompt: nil,
      size: "md",
      footer: false,
      compact: false,
      option: [],
      item: []
    )
    |> Listbox.prepare(:select)
    |> Listbox.listbox()
  end

  # A `count:` is drawn as the row's hint (a faint mono number on the right).
  defp with_hints(options), do: Enum.map(options, &hint/1)

  defp hint({label, options}) when is_list(options), do: {label, with_hints(options)}

  defp hint(%{count: count} = option) when count not in [nil, ""],
    do: Map.put_new(option, :hint, to_string(count))

  defp hint(option), do: option
end
