defmodule LineaUI.Components.ViewSwitcher do
  @moduledoc """
  The views of a collection (List, Board, Table…) as a row of tabs, with a "+ View" button whose menu offers
  the views that can still be added: an icon tile, a name and a line of description each, in two columns. It
  is the canvas's `ViewSwitcher`.

      <.view_switcher
        id="invoice-views"
        aria-label="Invoice views"
        value={@view}
        on_change="set_view"
        on_add="add_view"
        views={[
          %{label: "List", value: "list", icon: "huge-left-to-right-list-bullet"},
          %{label: "Board", value: "board", icon: "huge-kanban"}
        ]}
        options={[
          %{label: "Simple", value: "gallery", icon: "huge-grid-view", description: "Gallery view of invoices"},
          %{label: "Timeline", value: "timeline", icon: "huge-time-quarter-pass", description: "Timeline of invoices"},
          %{label: "Table", value: "table", icon: "huge-table-01", description: "Table view of invoices"}
        ]}
      />

  ## Views

  `views` are the tabs: maps with `:label` and `:value`, and optionally `:icon` (a `huge-*` name), `:count`
  and `:disabled`. The tab whose value is `value` is the chosen one. A tab is a button that sends `on_change`
  with `%{"view" => value}`; a view with `:patch`, `:navigate` or `:href` is a link instead, and the chosen one
  carries `aria-current="page"`:

      views={[
        %{label: "List", value: "list", patch: ~p"/invoices?view=list"},
        %{label: "Board", value: "board", patch: ~p"/invoices?view=board"}
      ]}

  ## The menu

  `options` are the views on offer: maps with `:label` and `:value`, and optionally `:icon`, `:description`,
  `:added` (a check at the end, for a view that is already a tab) and `:disabled`. Choosing one sends `on_add`
  with `%{"view" => value}` and closes the menu. Without `options` there is no button. `add_label` and
  `menu_title` are its texts and `columns` is `2` or `1`.

  The menu is a `dropdown/1` (`id` is `"\#{id}-add"`): it floats in the top layer, flips when there is no room,
  works with ↑ ↓ Home End, letters and Esc, and closes with `LineaUI.close(socket, "invoice-views-add")`.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [icon: 1]

  alias LineaUI.Components.Dropdown

  @doc """
  Renders the tabs of the views and the menu that adds one.

  Events: `on_change` and `on_add` receive `%{"view" => value}`.
  """
  attr :id, :string, required: true
  attr :value, :any, default: nil, doc: "The value of the chosen view."

  attr :views, :list,
    default: [],
    doc: "The tabs: maps with `:label` and `:value` (see the module doc)."

  attr :options, :list, default: [], doc: "The views the menu offers (see the module doc)."
  attr :on_change, :any, default: nil, doc: "An event name or a `%JS{}`, run by a tab."

  attr :on_add, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run by an option of the menu."

  attr :target, :any, default: nil, doc: "The `phx-target` of both events."
  attr :add_label, :string, default: "View"
  attr :menu_title, :string, default: "Add a new view"
  attr :columns, :integer, default: 2, values: [1, 2]

  attr :placement, :string,
    default: "bottom-start",
    doc: "Where the menu opens (as in `dropdown/1`)."

  attr :class, :any, default: nil
  attr :rest, :global

  def view_switcher(assigns) do
    assigns =
      assign_derived(assigns, :chosen, [:value], fn ->
        assigns.value && to_string(assigns.value)
      end)

    ~H"""
    <div id={@id} class={merge(["linea-views", @class])} role="group" {@rest}>
      <div class="linea-views-tabs">
        <.tab
          :for={view <- @views}
          view={view}
          active={to_string(view.value) == @chosen}
          on_change={@on_change}
          target={@target}
        />
      </div>
      <span :if={@views != [] and @options != []} class="linea-views-sep" aria-hidden="true"></span>
      <Dropdown.dropdown
        :if={@options != []}
        id={"#{@id}-add"}
        class={["linea-views-menu", @columns == 1 && "is-single"]}
        placement={@placement}
        offset={8}
      >
        <:toggle>
          <button type="button" class="linea-views-add" aria-haspopup="menu">
            <.icon name="huge-add-01" class="size-4" />{@add_label}
          </button>
        </:toggle>
        <p id={"#{@id}-add-title"} class="linea-views-title">{@menu_title}</p>
        <div class="linea-views-grid" role="group" aria-labelledby={"#{@id}-add-title"}>
          <button
            :for={option <- @options}
            type="button"
            class="linea-views-option"
            role="menuitem"
            tabindex="-1"
            aria-disabled={option[:disabled] && "true"}
            disabled={option[:disabled]}
            phx-click={@on_add}
            phx-value-view={option.value}
            phx-target={@target}
          >
            <span class="linea-views-tile" aria-hidden="true">
              <.icon :if={option[:icon]} name={option.icon} class="size-[18px]" />
            </span>
            <span class="linea-views-text">
              <b>{option.label}</b>
              <span :if={option[:description]}>{option.description}</span>
            </span>
            <.icon :if={option[:added]} name="huge-tick-02" class="linea-views-check" />
          </button>
        </div>
      </Dropdown.dropdown>
    </div>
    """
  end

  attr :view, :map, required: true
  attr :active, :boolean, required: true
  attr :on_change, :any, required: true
  attr :target, :any, required: true

  # a disabled view is never a link: it is the disabled button, which cannot navigate
  defp tab(%{view: view} = assigns) do
    link = Map.take(view, [:patch, :navigate, :href])

    if link != %{} and view[:disabled] != true,
      do: assigns |> assign(:link, link) |> link_tab(),
      else: button_tab(assigns)
  end

  defp link_tab(assigns) do
    ~H"""
    <.link class="linea-views-tab" aria-current={@active && "page"} {@link}>
      <.tab_body view={@view} />
    </.link>
    """
  end

  defp button_tab(assigns) do
    ~H"""
    <button
      type="button"
      class="linea-views-tab"
      aria-pressed={to_string(@active)}
      aria-disabled={@view[:disabled] && "true"}
      disabled={@view[:disabled]}
      phx-click={@on_change}
      phx-value-view={@view.value}
      phx-target={@target}
    >
      <.tab_body view={@view} />
    </button>
    """
  end

  attr :view, :map, required: true

  defp tab_body(assigns) do
    ~H"""
    <.icon :if={@view[:icon]} name={@view.icon} class="size-4" />{@view.label}<span
      :if={@view[:count]}
      class="linea-views-count"
    >{@view.count}</span>
    """
  end
end
