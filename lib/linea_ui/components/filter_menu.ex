defmodule LineaUI.Components.FilterMenu do
  @moduledoc """
  A filter button that opens a menu of filters: one row per group (Status, Sales channel, Seller) that opens a second
  panel to its side with the group's options as checkboxes, and flat sections (Sort by) in the same menu. It is
  the Signetum canvas's "Menu de filtros com submenus", and the replacement for a row of status chips that eats a
  toolbar. It is built on `dropdown/1` and its filter items, so the keyboard and ARIA are the dropdown's.

  Nothing is applied until Apply (`mode="apply"`, the default): ticks only stage, a group's row shows how many
  values are staged, Apply shows how many records they leave (from the options' `count`), Clear unticks the filter
  groups, and closing the menu any other way takes the staged values back. The trigger shows how many values are
  applied, from the `value` of the groups. This is an orders list inside a form; Apply submits it:

      <.form for={@form} phx-submit="apply_filters">
        <.filter_menu
          id="orders-filter"
          label="Filtrar"
          locale="pt_BR"
          variant="outline"
          dashed
          size="sm"
          groups={[
            %{
              name: "filter[status]",
              label: "Status",
              icon: "huge-checkmark-circle-02",
              value: @filter["status"],
              options: [{"Faturado", "invoiced", 3}, {"Aprovado", "approved", 2}, {"Rascunho", "draft", 2}, {"Cancelado", "canceled", 1}]
            },
            %{
              name: "filter[channel]",
              label: "Canal de venda",
              icon: "huge-store-01",
              value: @filter["channel"],
              options: [{"Balcão", "counter", 3}, {"Representante", "rep", 3}, {"Loja online", "online", 2}]
            },
            %{
              name: "filter[seller]",
              label: "Vendedor",
              icon: "huge-user",
              value: @filter["seller"],
              options: [{"Ana Souza", "ana", 3}, {"Carlos Lima", "carlos", 3}, {"Juliana Moraes", "juliana", 2}]
            },
            %{
              name: "filter[sort]",
              label: "Ordenar por",
              caption: "Ordenar por",
              display: :section,
              type: :single,
              value: @filter["sort"],
              options: [{"Mais recentes", "recent"}, {"Maior valor", "value"}, {"Cliente A-Z", "client"}]
            }
          ]}
        />
      </.form>

  Every option is a real input named `filter[status][]` (a multiple group) or `filter[sort]` (a single one), so a
  plain form posts them too, and the LiveView gets them on Apply. A group with nothing ticked posts no key, so merge
  the defaults, and assign the result back: the `value`s are what the menu then shows as applied.

      def handle_event("apply_filters", %{"filter" => params}, socket) do
        defaults = %{"status" => [], "channel" => [], "seller" => []}
        {:noreply, assign(socket, filter: Map.merge(defaults, params))}
      end

  In `apply` mode the ticks do not reach the form's `phx-change`; the staged state is the browser's until Apply.
  `icon` takes a Hugeicons name; the default is the `:filter` glyph (`icon="huge-filter"` is the funnel).

  `display: :submenu` (the default) is a row that opens a panel; `display: :section` is the options laid flat in the
  menu under a `caption`, for settings such as a sort order. Only submenu groups are filters: sections do not count in
  the trigger, in a group's pill or in Apply. `type: :multiple` (the default) is checkboxes, `type: :single` radios.

  One group, with the trigger of a toolbar:

      <.filter_menu
        id="status-filter"
        label="Status"
        groups={[%{name: "status", label: "Status", value: @status, options: ~w(Paid Open Late) |> Enum.map(&{&1, &1})}]}
        on_apply="set_status"
      />

  With `on_apply` (and `on_change`, `on_clear`) the events carry `%{"id" => id, "values" => %{"status" => ["Paid"]}}`, to
  `target`, so the form is optional. `mode="live"` has no Apply: every tick reaches the form's `phx-change` and
  `on_change` at once, and the footer is only Clear.

      <.form for={@form} phx-change="filter">
        <.filter_menu id="live-filter" mode="live" groups={@groups} />
      </.form>

  A `:group` slot takes the same attributes as a group and your own content, any `dropdown_checkbox` or
  `dropdown_radio` (give each a `name`, and `data-count` for what Apply counts):

      <.filter_menu id="custom">
        <:group name="tags[]" label="Tags" value={@tags}>
          <.dropdown_checkbox :for={tag <- @all_tags} name="tags[]" value={tag.id} checked={tag.id in @tags}>
            {tag.name}
          </.dropdown_checkbox>
        </:group>
      </.filter_menu>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1, icon: 1]

  alias LineaUI.Components.Button
  alias LineaUI.Components.Dropdown
  alias LineaUI.Components.Strings

  @group_defaults %{
    icon: nil,
    display: :submenu,
    type: :multiple,
    caption: nil,
    options: [],
    value: nil,
    entry: nil
  }
  @group_keys [:name, :label | Map.keys(@group_defaults)]

  @menu_class "min-w-57.5 shadow-[0_10px_30px_-8px_rgb(48_46_56/0.18)] dark:border-navy-700 dark:shadow-soft-dark"

  @doc """
  Renders the filter menu.

  Events: `on_change` (every tick, staged ones too), `on_apply` (Apply) and `on_clear` (Clear) push
  `%{"id" => id, "values" => %{group_name => ["a", "b"] | "x"}}` to `target`: a list for a multiple group and the chosen
  value (or `""`) for a single one. `LineaUI.open/close/toggle` work on the `id`.
  """
  attr :id, :string, required: true

  attr :label, :string,
    default: nil,
    doc: "The trigger's text; \"Filters\" (\"Filtros\" in pt_BR) when not given."

  attr :icon, :string,
    default: nil,
    doc:
      "A Hugeicons name (`huge-filter`) or icon classes before the label; the `:filter` glyph by default."

  attr :groups, :list,
    default: [],
    doc:
      "A list of maps: `name` (the input name, required), `label` (required), `icon` (`huge-...`), `display` (`:submenu` or `:section`), `type` (`:multiple` or `:single`), `caption` (over a section), `options` (`{label, value}` or `{label, value, count}`) and `value` (a list for a multiple group, the value for a single one)."

  attr :mode, :string,
    default: "apply",
    values: ~w(apply live),
    doc: "`apply` stages the ticks until Apply; `live` pushes each one at once and has no Apply."

  attr :locale, :string, default: "en", values: ~w(en pt_BR)

  attr :results, :integer,
    default: nil,
    doc:
      "The number after Apply, when the server knows the exact records the staged filters leave. Without it the menu adds up the options' `count`s (the smallest staged group when several are staged)."

  attr :variant, :string,
    default: "outline",
    values: ~w(solid glow outline soft bordered flat),
    doc: "The trigger button's variant."

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error),
    doc: "The trigger button's color."

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "The trigger button's size."

  attr :dashed, :boolean, default: false, doc: "A dashed border on the trigger button."
  attr :placement, :string, default: "bottom-start"
  attr :open, :boolean, default: false

  attr :on_change, :string, default: nil, doc: "An event name pushed on every tick."

  attr :on_apply, :string,
    default: nil,
    doc: "An event name pushed by Apply instead of submitting the form."

  attr :on_clear, :string, default: nil, doc: "An event name pushed by Clear."
  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :class, :any, default: nil, doc: "Merged into the menu box (`w-72`...)."
  attr :rest, :global

  slot :group,
    doc:
      "A group with your own options: the attributes of a `groups` entry (except `options`), and `dropdown_checkbox` / `dropdown_radio` items inside." do
    attr :name, :string, required: true
    attr :label, :string, required: true
    attr :icon, :string
    attr :display, :atom, values: [:submenu, :section]
    attr :type, :atom, values: [:multiple, :single]
    attr :caption, :string
    attr :value, :any
  end

  def filter_menu(assigns) do
    groups = Enum.map(assigns.groups, &group(&1, nil)) ++ Enum.map(assigns.group, &group(&1, &1))
    text = Strings.table(assigns.locale)

    assigns =
      assign(assigns,
        groups: groups,
        text: text,
        menu_class: @menu_class,
        applied: applied(groups),
        apply_count: assigns.results || pending_results(groups)
      )

    ~H"""
    <div
      id={"#{@id}-filter"}
      class="inline-flex"
      phx-hook="LineaUI.FilterMenu"
      phx-target={@target}
      data-filter-id={@id}
      data-mode={@mode}
      data-results={@results}
      data-on-change={@on_change}
      data-on-apply={@on_apply}
      data-on-clear={@on_clear}
      {@rest}
    >
      <Dropdown.dropdown
        id={@id}
        keep_submenus
        close_on_select={false}
        open={@open}
        placement={@placement}
        on_close={JS.dispatch("linea:filter-close")}
        class={merge([@menu_class, @class])}
      >
        <:toggle>
          <Button.button
            variant={@variant}
            color={@color}
            size={@size}
            class={merge(["gap-2", @dashed && "border-dashed"])}
            aria-haspopup="menu"
          >
            <.icon :if={@icon} name={@icon} class="size-4 shrink-0" />
            <.glyph :if={@icon == nil} name={:filter} class="size-4 shrink-0" />
            <span>{@label || @text.filter_label}</span>
            <span
              data-filter-applied
              hidden={@applied == 0}
              class="inline-flex h-5 min-w-5 items-center justify-center rounded bg-primary/10 px-1.5 font-inter text-tiny-plus font-medium text-primary dark:bg-accent-light/15 dark:text-accent-light"
            >
              {@applied}
            </span>
          </Button.button>
        </:toggle>
        <.group_block
          :for={{group, index} <- Enum.with_index(@groups)}
          id={@id}
          group={group}
          first={index == 0}
        />
        <Dropdown.dropdown_footer
          locale={@locale}
          show_apply={@mode == "apply"}
          apply_count={@apply_count}
          on_apply={%JS{}}
          class="dark:border-navy-700"
        />
      </Dropdown.dropdown>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :group, :map, required: true
  attr :first, :boolean, required: true

  defp group_block(%{group: %{display: :submenu}} = assigns) do
    ~H"""
    <Dropdown.dropdown_submenu
      id={"#{@id}-#{slug(@group.name)}"}
      label={@group.label}
      count={length(@group.selected)}
      class="min-w-57.5 dark:border-navy-700"
      data-filter-group={@group.name}
      data-filter-type={@group.type}
      data-count-radios="true"
    >
      <:icon :if={@group.icon}><.icon name={@group.icon} class="size-4 shrink-0" /></:icon>
      <.group_items group={@group} />
    </Dropdown.dropdown_submenu>
    """
  end

  defp group_block(%{group: %{display: :section}} = assigns) do
    ~H"""
    <Dropdown.dropdown_separator :if={not @first} class="dark:bg-navy-700" />
    <div
      role="group"
      aria-label={@group.caption || @group.label}
      data-filter-group={@group.name}
      data-filter-type={@group.type}
    >
      <Dropdown.dropdown_label :if={@group.caption}>{@group.caption}</Dropdown.dropdown_label>
      <.group_items group={@group} />
    </div>
    """
  end

  attr :group, :map, required: true

  defp group_items(%{group: %{entry: nil, type: :multiple}} = assigns) do
    ~H"""
    <Dropdown.dropdown_checkbox
      :for={option <- @group.options}
      name={"#{@group.name}[]"}
      value={option.value}
      checked={option.value in @group.selected}
      count={option.count}
      data-count={option.count}
    >
      {option.label}
    </Dropdown.dropdown_checkbox>
    """
  end

  defp group_items(%{group: %{entry: nil, type: :single}} = assigns) do
    ~H"""
    <Dropdown.dropdown_radio
      :for={option <- @group.options}
      name={@group.name}
      value={option.value}
      checked={option.value in @group.selected}
      count={option.count}
      data-count={option.count}
    >
      {option.label}
    </Dropdown.dropdown_radio>
    """
  end

  defp group_items(assigns) do
    ~H"""
    {render_slot(@group.entry)}
    """
  end

  defp group(%{name: _, label: _} = source, entry) do
    base = Map.merge(@group_defaults, Map.take(source, @group_keys))

    Map.merge(base, %{
      entry: entry,
      options: Enum.map(base.options, &option/1),
      selected: selected(base.value)
    })
  end

  defp option({label, value}), do: %{label: label, value: to_string(value), count: nil}
  defp option({label, value, count}), do: %{label: label, value: to_string(value), count: count}

  defp selected(nil), do: []
  defp selected(""), do: []
  defp selected(values) when is_list(values), do: Enum.map(values, &to_string/1)
  defp selected(value), do: [to_string(value)]

  defp applied(groups) do
    groups
    |> Enum.filter(&(&1.display == :submenu))
    |> Enum.map(&length(&1.selected))
    |> Enum.sum()
  end

  defp pending_results(groups) do
    states = for %{display: :submenu} = group <- groups, do: states(group)

    countable =
      states != [] and Enum.all?(states, &Enum.all?(&1, fn state -> is_integer(state.count) end))

    staged =
      states |> Enum.map(&Enum.filter(&1, fn state -> state.on end)) |> Enum.reject(&(&1 == []))

    results(countable, staged, states)
  end

  defp states(%{entry: nil} = group),
    do: Enum.map(group.options, &%{on: &1.value in group.selected, count: &1.count})

  defp states(group), do: Enum.map(group.selected, fn _value -> %{on: true, count: nil} end)

  defp results(false, staged, _states), do: staged |> Enum.concat() |> length() |> nonzero()
  defp results(true, [], states), do: states |> Enum.map(&sum/1) |> Enum.max()
  defp results(true, staged, _states), do: staged |> Enum.map(&sum/1) |> Enum.min()

  defp sum(states), do: states |> Enum.map(& &1.count) |> Enum.sum()

  defp nonzero(0), do: nil
  defp nonzero(count), do: count

  defp slug(name), do: Regex.replace(~r/[^a-zA-Z0-9_-]+/, name, "-")
end
