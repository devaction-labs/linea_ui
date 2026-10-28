defmodule LineaUI.Components.TagsInput do
  @moduledoc """
  LineOne's tag input (the Tom Select page's Input Tags demos): what is typed becomes a chip
  on Enter, Tab or the delimiter, chips are removed with Backspace or their remove button.

      <.tags_input label="Enter Tags:" placeholder="Enter tags" field={@form[:tags]} />
      <.tags_input name="tags" value={["awesome", "neat"]} removable restore_on_backspace />
      <.tags_input name="tags" value="clear,items" clearable persist={false} max={5} />

  `value` is a list of strings or a comma separated string. The tags are submitted as
  `name[]` (plus an empty `name[]` so an empty list still reaches the server) through a
  hidden `<select multiple>`, and each change fires a bubbling `input` event for `phx-change`.
  `suggestions` are offered in the list while typing. The `:option` and `:item` slots draw an
  option in the list and a tag in the field, as in `LineaUI.Components.Select`.

  With `max`, the input is disabled at the limit, its placeholder becomes `limit_placeholder`
  and a `3 / 3` counter appears under the field. The row that creates a tag reads
  `Enter Add “pri”`: `create_label` and `create_hint` are its words.

  ## Picking from a server-searched list

  With `create={false}` only listed options can be chosen, and with `on_search` the server
  does the search: the typed text is pushed (debounced) and the LiveView answers by
  re-rendering `options`. Chips show the labels; the form gets the values as `name[]`.
  `selected_options` gives the labels of the chosen values that are not in the current
  `options` (after a search narrowed them).

      <.tags_input
        field={@form[:tag_ids]}
        options={@tag_results}
        selected_options={@chosen_tags}
        create={false}
        on_search="search_tags"
        target={@myself}
        removable
        placeholder="Search tags"
      />

      def handle_event("search_tags", %{"query" => query}, socket),
        do: {:noreply, assign(socket, :tag_results, Tags.search(query))}
  """

  use LineaUI.Component

  @doc """
  Renders a tag input.

  Events: with `on_search`, `%{"id" => id, "query" => text}` is pushed to `target` (or the
  LiveView) as the person types, `debounce` ms after the last key; the list then shows the
  `options` the server renders, unfiltered.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name (with `[]` when several values)."
  attr :value, :any, doc: "Defaults to the field value."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil

  attr :suggestions, :list,
    default: [],
    doc: "Options offered while typing, in any select option shape."

  attr :options, :list,
    default: nil,
    doc: "The options to pick from (any select option shape); `suggestions` by another name."

  attr :selected_options, :list,
    default: [],
    doc: "Options whose labels the chips of chosen values use when they are not in `options`."

  attr :create, :boolean,
    default: true,
    doc: "Typed text becomes a tag; `false` allows only listed options (option-picking mode)."

  attr :on_search, :string,
    default: nil,
    doc: "Event pushed with the typed text; the server then renders `options`."

  attr :debounce, :integer,
    default: 300,
    doc: "Milliseconds between the last key and `on_search`."

  attr :removable, :boolean, default: false, doc: "A remove button on each tag."
  attr :clearable, :boolean, default: false, doc: "A button that removes every tag."
  attr :clear_label, :string, default: "Clear"
  attr :remove_label, :string, default: "Remove"
  attr :create_label, :string, default: "Add"
  attr :persist, :boolean, default: true, doc: "A removed tag stays in the list of suggestions."
  attr :restore_on_backspace, :boolean, default: false

  attr :create_hint, :string,
    default: "Enter",
    doc: "The key shown in the create row (`Enter Add “pri”`); `nil` hides it."

  attr :max, :integer,
    default: nil,
    doc:
      "How many tags can be added. At the limit the input is disabled, shows `limit_placeholder` and a `3 / 3` counter appears under the field."

  attr :limit_placeholder, :string,
    default: "Limit reached",
    doc: "The placeholder of the disabled input at `max`."

  attr :no_results, :string, default: "No results found"
  attr :disabled, :boolean, default: false
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  slot :option,
    doc: "How an option shows in the list; gets the option map (`label`, `value`, `data`)."

  slot :item, doc: "How a chosen tag shows in the control; gets the option map."

  def tags_input(assigns) do
    assigns
    |> assign(:multiple, true)
    |> assign_field()
    |> assign_new(:id, fn -> gen_id("tags") end)
    |> then(&assign_new(&1, :name, fn -> &1.id end))
    |> assign_new(:value, fn -> nil end)
    |> assign(:options, assigns.options || assigns.suggestions)
    |> then(&assign(&1, :debounce, debounce(&1.on_search, &1.debounce)))
    |> LineaUI.Components.Select.Listbox.prepare(:tags)
    |> LineaUI.Components.Select.Listbox.listbox()
  end

  defp debounce(nil, _debounce), do: 0
  defp debounce(_event, debounce), do: debounce
end
