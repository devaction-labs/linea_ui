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
  `suggestions` are offered in the list while typing.
  """

  use LineaUI.Component

  @doc "Renders a tag input."
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil

  attr :suggestions, :list,
    default: [],
    doc: "Options offered while typing, in any select option shape."

  attr :removable, :boolean, default: false, doc: "A remove button on each tag."
  attr :clearable, :boolean, default: false, doc: "A button that removes every tag."
  attr :clear_label, :string, default: "Clear"
  attr :remove_label, :string, default: "Remove"
  attr :create_label, :string, default: "Add"
  attr :persist, :boolean, default: true, doc: "A removed tag stays in the list of suggestions."
  attr :restore_on_backspace, :boolean, default: false
  attr :max, :integer, default: nil, doc: "How many tags can be added."
  attr :no_results, :string, default: "No results found"
  attr :disabled, :boolean, default: false
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  def tags_input(assigns) do
    assigns
    |> assign(:multiple, true)
    |> assign_field()
    |> assign_new(:id, fn -> gen_id("tags") end)
    |> then(&assign(&1, :name, &1.name || &1.id))
    |> assign(options: assigns.suggestions, create: true, on_search: nil, debounce: 0)
    |> assign(option: [], item: [])
    |> LineaUI.Components.Select.Listbox.prepare(:tags)
    |> LineaUI.Components.Select.Listbox.listbox()
  end
end
