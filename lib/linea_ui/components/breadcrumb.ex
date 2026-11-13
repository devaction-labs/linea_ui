defmodule LineaUI.Components.Breadcrumb do
  @moduledoc """
  LineOne's breadcrumb: the links to the pages above the current one, then the current page.

      <.breadcrumb>
        <:item navigate={~p"/"}>Home</:item>
        <:item navigate={~p"/elements"}>Elements</:item>
        <:item>Breadcrumb</:item>
      </.breadcrumb>

  An item with `href`, `navigate` or `patch` is a link; one with `phx-click` is a button that
  looks like a link, so a crumb can navigate through a server event; the others are plain text
  (the current page is the last one). Any other attribute of the item (`phx-target`,
  `phx-value-*`, `id`, `data-*`, `aria-*`) is passed on to the link or button.

      <.breadcrumb>
        <:item :for={folder <- @path} phx-click="open_folder" phx-value-id={folder.id}>
          {folder.name}
        </:item>
      </.breadcrumb>

  The current page is in the soft text color and a long label is cut with an ellipsis; give the
  item a `title` for the full label.

  A long trail collapses with `max_items`: it keeps the first step and the last ones, and the steps
  in between become a single "…" button that opens them in a dropdown (links and `phx-click`
  steps keep working there). `max_items` counts the "…" as a step, so `max_items={4}` shows the
  first step, "…" and the last two. Give the breadcrumb an `id`: the dropdown's is `"<id>-more"`.

      <.breadcrumb id="path" max_items={4}>
        <:item navigate={~p"/finance"}>Finance</:item>
        <:item navigate={~p"/finance/reconciliation"}>Reconciliation</:item>
        <:item navigate={~p"/finance/reconciliation/statements"}>Statements</:item>
        <:item>October</:item>
      </.breadcrumb>

  The separator is LineOne's chevron unless a `:separator` is given:

      <.breadcrumb variant="bordered">
        <:separator><span class="text-xs font-light">/</span></:separator>
        <:item href="/"><svg>…</svg></:item>
        <:item>Calendar</:item>
      </.breadcrumb>

  `variant="canvas"` (the default; `variant="plain"` is the old LineOne trail) is the design canvas trail (`sg-crumb`): a 32px pill with an inset line, muted
  13px links, faint `/` separators and the current page in the ink.

      <.breadcrumb>
        <:item navigate={~p"/customers"}>Customers</:item>
        <:item>Casa das Tintas</:item>
      </.breadcrumb>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Button
  alias LineaUI.Components.Dropdown

  @focus "outline-hidden focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary/55 dark:focus-visible:outline-accent/55"

  @links %{
    "plain" =>
      "flex items-center gap-1.5 rounded-md text-primary transition-colors hover:text-primary-focus hover:underline hover:underline-offset-3 dark:text-accent-light dark:hover:text-blue-300",
    "bordered" =>
      "flex items-center gap-1.5 rounded-lg px-2 py-[5px] leading-none text-primary shadow-[inset_0_0_0_1px_var(--color-slate-200)] transition-colors hover:text-primary-focus hover:shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--color-primary)_40%,transparent)] dark:text-accent-light dark:shadow-[inset_0_0_0_1px_var(--color-navy-500)] dark:hover:text-blue-300 dark:hover:shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--color-accent)_40%,transparent)]",
    "canvas" =>
      "flex items-center gap-1.5 rounded-md text-[var(--muted)] transition-colors hover:text-[var(--ink)]"
  }

  @lists %{
    "plain" => "flex flex-wrap items-center gap-2",
    "bordered" => "flex flex-wrap items-center gap-2",
    "canvas" => "sg-crumb"
  }

  @currents %{
    "plain" => "text-slate-600 dark:text-navy-200",
    "bordered" => "text-slate-600 dark:text-navy-200",
    "canvas" => "font-medium text-[var(--ink)]"
  }

  @doc """
  Renders a breadcrumb trail; the last `:item` is the current page.

      <.breadcrumb>
        <:item navigate={~p"/"}>Home</:item>
        <:item>Settings</:item>
      </.breadcrumb>
  """
  attr(:variant, :string,
    default: "canvas",
    values: ~w(canvas plain bordered),
    doc:
      "`canvas` (the default) is the design canvas pill trail with `/` separators; `plain` is the old LineOne trail. `bordered` draws a rounded border around each link; `canvas` is the design canvas pill trail with `/` separators."
  )

  attr(:label, :string, default: "Breadcrumb", doc: "The `aria-label` of the navigation.")

  attr(:max_items, :integer,
    default: nil,
    doc:
      "With more steps than this, the middle ones collapse into a \"…\" dropdown, keeping the first step and the last `max_items - 2` (the \"…\" counts as a step; below 3 it is 3)."
  )

  attr(:more_label, :string,
    default: "Show hidden steps",
    doc: "The accessible name of the \"…\" button."
  )

  attr(:id, :string,
    default: nil,
    doc:
      "The id of the `<nav>`; it prefixes the id of the \"…\" dropdown (`breadcrumb-more` without one), so set it when a page has several."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:item, required: true, doc: "A step of the trail.") do
    attr(:href, :string)
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:class, :any)

    attr(:"phx-click", :any,
      doc: "Makes the item a button that sends this event or runs this `JS`."
    )

    attr(:"phx-target", :any)
    attr(:"phx-value-id", :any)
    attr(:id, :string)
    attr(:title, :string, doc: "The full label, shown on hover when the current page is cut.")
  end

  slot(:separator, doc: "What goes between two steps, LineOne's chevron by default.")

  def breadcrumb(assigns) do
    assigns =
      assigns
      |> assign(:crumbs, crumbs(assigns.item, assigns.max_items))
      |> then(&assign(&1, :last, length(&1.crumbs) - 1))
      |> assign(:lists, @lists)
      |> assign(:current_class, @currents[assigns.variant])

    ~H"""
    <nav id={@id} aria-label={@label} {@rest}>
      <ul class={merge([@lists[@variant], @class])}>
        <li
          :for={{crumb, index} <- Enum.with_index(@crumbs)}
          class={if index < @last, do: "flex items-center gap-2", else: "min-w-0 max-w-full"}
        >
          <.more
            :if={match?({:more, _}, crumb)}
            id={"#{@id || "breadcrumb"}-more"}
            label={@more_label}
            hidden={elem(crumb, 1)}
          />
          <.crumb
            :if={match?({:item, _}, crumb)}
            item={elem(crumb, 1)}
            link_class={link_class(@variant)}
            current_class={@current_class}
            current={index == @last}
          />
          <.separator :if={index < @last} separator={@separator} variant={@variant} />
        </li>
      </ul>
    </nav>
    """
  end

  defp crumbs(items, max) when is_integer(max) and length(items) > max do
    keep = max(max, 3) - 2
    [first | rest] = items
    {hidden, tail} = Enum.split(rest, length(rest) - keep)
    [{:item, first}, {:more, hidden} | Enum.map(tail, &{:item, &1})]
  end

  defp crumbs(items, _max), do: Enum.map(items, &{:item, &1})

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:hidden, :list, required: true)

  defp more(assigns) do
    ~H"""
    <Dropdown.dropdown id={@id}>
      <:toggle>
        <Button.button icon size="sm" variant="flat" aria-label={@label}>
          <.glyph name={:dots_horizontal} class="size-4" />
        </Button.button>
      </:toggle>
      <Dropdown.dropdown_item
        :for={item <- @hidden}
        {Map.drop(item, [:inner_block, :__slot__, :class])}
      >
        {render_slot(item)}
      </Dropdown.dropdown_item>
    </Dropdown.dropdown>
    """
  end

  defp link_class(variant), do: [@links[variant], @focus]

  attr(:item, :map, required: true)
  attr(:link_class, :any, required: true)
  attr(:current_class, :any, default: nil)
  attr(:current, :boolean, required: true)

  defp crumb(%{item: item} = assigns) when is_map_key(item, :"phx-click") do
    assigns = assign(assigns, :extra, extra(item))

    ~H"""
    <button
      type="button"
      class={merge([@link_class, "cursor-pointer", @item[:class]])}
      aria-current={@current && "page"}
      {@extra}
    >
      {render_slot(@item)}
    </button>
    """
  end

  defp crumb(%{item: item} = assigns)
       when is_map_key(item, :href) or is_map_key(item, :navigate) or is_map_key(item, :patch) do
    assigns = assign(assigns, :extra, extra(item))

    ~H"""
    <.link
      href={@item[:href]}
      navigate={@item[:navigate]}
      patch={@item[:patch]}
      class={merge([@link_class, @item[:class]])}
      aria-current={@current && "page"}
      {@extra}
    >
      {render_slot(@item)}
    </.link>
    """
  end

  defp crumb(assigns) do
    assigns = assign(assigns, :extra, extra(assigns.item))

    ~H"""
    <div
      class={
        merge([
          "flex min-w-0 items-center gap-1.5",
          @current_class,
          @item[:class]
        ])
      }
      aria-current={@current && "page"}
      {@extra}
    >
      <span class="min-w-0 truncate">{render_slot(@item)}</span>
    </div>
    """
  end

  defp extra(item),
    do: Map.drop(item, [:inner_block, :__slot__, :href, :navigate, :patch, :class])

  attr(:separator, :list, required: true)
  attr(:variant, :string, default: "plain")

  defp separator(%{separator: [], variant: "canvas"} = assigns) do
    ~H"""
    <span aria-hidden="true" class="sep">/</span>
    """
  end

  defp separator(%{separator: []} = assigns) do
    ~H"""
    <.glyph name={:chevron_right} class="size-3.5 shrink-0 text-slate-400 dark:text-navy-300" />
    """
  end

  defp separator(assigns) do
    ~H"""
    <span aria-hidden="true" class="contents">{render_slot(@separator)}</span>
    """
  end
end
