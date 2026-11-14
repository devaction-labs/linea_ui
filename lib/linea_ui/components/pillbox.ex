defmodule LineaUI.Components.Pillbox do
  @moduledoc """
  A multiple (or, with `multiple={false}`, single) choice from a list, drawn as the design canvas's Pillbox: the chosen options become pills inside
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

  ## Single choice

  `multiple={false}` is a searchable single choice with the same look: the chosen option is one pill in the field,
  the list opens with the search on top, choosing a row replaces the pill and closes the list (no check boxes),
  and the value is submitted as `name` (not `name[]`). `clear` and `readonly` work as in the multiple one.

      <.pillbox name="product_id" value={@product_id} options={@products} multiple={false} label="Product" />

  ## Size

  `size` (`sm` 32px, `md` 40px, `lg` 48px) is the height of an input of that size, so a row of fields lines up.

  ## Panel width

  The list is as wide as the field. In a narrow field, `panel_min_width` (a CSS length: `"22rem"`, `"360px"`)
  gives it a minimum width of its own, still aligned to the field's left edge, and `panel_class` merges classes into
  the list.

      <.pillbox name="customer" options={@customers} multiple={false} class="w-56" panel_min_width="26rem" />

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

  Load more: with `on_load_more` and `has_more`, scrolling the list to within 48px of its end (or opening a
  list too short to scroll) pushes `on_load_more` once, with `%{"id" => id, "query" => text, "offset" => n}`
  (`n` is how many options are in the list), to `target` or the LiveView. The server appends the next page to
  `options` and sets `has_more`; the list keeps its scroll position. While `has_more` is true a last
  "Loading…" row (`loading_label`) shows; it is not an option. Nothing is pushed while `has_more` is false or
  a request is waiting for its answer (it ends when the list is rendered again).

      def handle_event("load_more", %{"offset" => offset, "query" => query}, socket) do
        limit = 30
        page = Customers.search(query, limit: limit, offset: offset)
        {:noreply, assign(socket, options: socket.assigns.options ++ page, has_more: length(page) == limit)}
      end

  A new search makes the server answer with page 1 (and `has_more`) again. A `load_more` answer that arrives
  after the term changed is not dropped by the client: compare the `"query"` of the event with your current
  term on the server and ignore it if they differ.
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

  attr :multiple, :boolean,
    default: true,
    doc:
      "`false` is a single choice (see the module doc): one pill, the list closes on choosing and `value` is one value."

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "The height of the field: `sm` 32px, `md` 40px, `lg` 48px, as an input of that size."

  attr :panel_min_width, :string,
    default: nil,
    doc:
      "A CSS length, the minimum width of the open list (`\"24rem\"`), for a narrow field; it stays aligned to the field's left edge."

  attr :panel_class, :any, default: nil, doc: "Classes merged into the open list."
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

  attr :on_load_more, :string,
    default: nil,
    doc: "the event pushed when the list is scrolled near its end (see the Events)."

  attr :has_more, :boolean,
    default: false,
    doc: "the server has more options after the ones in `options`."

  attr :loading_label, :string,
    default: "Loading…",
    doc: "the last row of the list while `has_more` and `on_load_more` are set."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form required)

  def pillbox(assigns) do
    assigns
    |> assign_field()
    |> put_default(:name, nil)
    |> put_default(:value, nil)
    |> then(&assign_new(&1, :id, fn -> &1.name || stable_id("pillbox", &1) end))
    |> then(&assign(&1, :name, &1.name || &1.id))
    |> assign_derived(:options, [:options], fn -> with_hints(assigns.options) end)
    |> assign_derived(:look, [], fn -> "pillbox" end)
    |> assign_derived(:search, [], fn -> "panel" end)
    |> assign_derived(:create_position, [], fn -> "bottom" end)
    |> assign_derived(:removable, [:readonly, :disabled], fn ->
      not (assigns.readonly or assigns.disabled)
    end)
    |> assign_derived(:clearable, [:clear, :readonly], fn ->
      assigns.clear and not assigns.readonly
    end)
    |> assign_derived(:no_results, [:empty_label], fn -> assigns.empty_label end)
    |> assign_derived(:overflow, [:overflow], fn ->
      if(assigns.overflow == "wrap", do: "wrap", else: "count")
    end)
    |> assign_derived(:persist, [], fn -> true end)
    |> assign_derived(:restore_on_backspace, [], fn -> false end)
    |> assign_derived(:max, [], fn -> nil end)
    |> assign_derived(:prompt, [], fn -> nil end)
    |> assign_derived(:footer, [], fn -> false end)
    |> assign_derived(:compact, [], fn -> false end)
    |> assign_derived(:option, [], fn -> [] end)
    |> assign_derived(:item, [], fn -> [] end)
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
