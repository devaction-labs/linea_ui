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

  The separator is LineOne's chevron unless a `:separator` is given:

      <.breadcrumb variant="bordered">
        <:separator><span class="text-xs font-light">/</span></:separator>
        <:item href="/"><svg>…</svg></:item>
        <:item>Calendar</:item>
      </.breadcrumb>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @links %{
    "plain" =>
      "flex items-center gap-1.5 text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent",
    "bordered" =>
      "flex items-center gap-1.5 rounded-lg border border-slate-200 px-1.5 py-1 leading-none text-primary transition-colors hover:text-primary-focus dark:border-navy-500 dark:text-accent-light dark:hover:text-accent"
  }

  @doc """
  Renders a breadcrumb trail; the last `:item` is the current page.

      <.breadcrumb>
        <:item navigate={~p"/"}>Home</:item>
        <:item>Settings</:item>
      </.breadcrumb>
  """
  attr(:variant, :string,
    default: "plain",
    values: ~w(plain bordered),
    doc: "`bordered` draws a rounded border around each link."
  )

  attr(:label, :string, default: "Breadcrumb", doc: "The `aria-label` of the navigation.")
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
  end

  slot(:separator, doc: "What goes between two steps, LineOne's chevron by default.")

  def breadcrumb(assigns) do
    assigns = assign(assigns, :last, length(assigns.item) - 1)

    ~H"""
    <nav aria-label={@label} {@rest}>
      <ul class={merge(["flex flex-wrap items-center gap-2", @class])}>
        <li
          :for={{item, index} <- Enum.with_index(@item)}
          class={index < @last && "flex items-center gap-2"}
        >
          <.crumb item={item} link_class={link_class(@variant)} current={index == @last} />
          <.separator :if={index < @last} separator={@separator} />
        </li>
      </ul>
    </nav>
    """
  end

  defp link_class(variant), do: @links[variant]

  attr(:item, :map, required: true)
  attr(:link_class, :string, required: true)
  attr(:current, :boolean, required: true)

  defp crumb(%{item: item} = assigns) when is_map_key(item, :"phx-click") do
    assigns = assign(assigns, :extra, extra(item))

    ~H"""
    <button
      type="button"
      class={merge([@link_class, "cursor-pointer outline-hidden", @item[:class]])}
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
      class={merge(["flex items-center gap-1.5", @item[:class]])}
      aria-current={@current && "page"}
      {@extra}
    >
      {render_slot(@item)}
    </div>
    """
  end

  defp extra(item),
    do: Map.drop(item, [:inner_block, :__slot__, :href, :navigate, :patch, :class])

  attr(:separator, :list, required: true)

  defp separator(%{separator: []} = assigns) do
    ~H"""
    <.glyph name={:chevron_right} class="size-3.5" />
    """
  end

  defp separator(assigns) do
    ~H"""
    <span aria-hidden="true" class="contents">{render_slot(@separator)}</span>
    """
  end
end
