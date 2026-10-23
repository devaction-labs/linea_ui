defmodule LineaUI.Components.Breadcrumb do
  @moduledoc """
  LineOne's breadcrumb: the links to the pages above the current one, then the current page.

      <.breadcrumb>
        <:item navigate={~p"/"}>Home</:item>
        <:item navigate={~p"/elements"}>Elements</:item>
        <:item>Breadcrumb</:item>
      </.breadcrumb>

  An item with `href`, `navigate` or `patch` is a link; the others are plain text (the current
  page is the last one). The separator is LineOne's chevron unless a `:separator` is given:

      <.breadcrumb variant="bordered">
        <:separator><span class="text-xs font-light">/</span></:separator>
        <:item href="/"><svg>…</svg></:item>
        <:item>Calendar</:item>
      </.breadcrumb>
  """

  use LineaUI.Component

  @links %{
    "plain" =>
      "flex items-center space-x-1.5 text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent",
    "bordered" =>
      "flex items-center space-x-1.5 rounded-lg border border-slate-200 px-1.5 py-1 leading-none text-primary transition-colors hover:text-primary-focus dark:border-navy-500 dark:text-accent-light dark:hover:text-accent"
  }

  @doc "Renders a breadcrumb trail."
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
  end

  slot(:separator, doc: "What goes between two steps, LineOne's chevron by default.")

  def breadcrumb(assigns) do
    assigns = assign(assigns, :last, length(assigns.item) - 1)

    ~H"""
    <nav aria-label={@label} {@rest}>
      <ul class={merge(["flex flex-wrap items-center space-x-2", @class])}>
        <li
          :for={{item, index} <- Enum.with_index(@item)}
          class={index < @last && "flex items-center space-x-2"}
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

  defp crumb(%{item: item} = assigns)
       when is_map_key(item, :href) or is_map_key(item, :navigate) or is_map_key(item, :patch) do
    ~H"""
    <.link
      href={@item[:href]}
      navigate={@item[:navigate]}
      patch={@item[:patch]}
      class={merge([@link_class, @item[:class]])}
      aria-current={@current && "page"}
    >
      {render_slot(@item)}
    </.link>
    """
  end

  defp crumb(assigns) do
    ~H"""
    <div
      class={merge(["flex items-center space-x-1.5", @item[:class]])}
      aria-current={@current && "page"}
    >
      {render_slot(@item)}
    </div>
    """
  end

  attr(:separator, :list, required: true)

  defp separator(%{separator: []} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-3.5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
    </svg>
    """
  end

  defp separator(assigns) do
    ~H"""
    <span aria-hidden="true" class="contents">{render_slot(@separator)}</span>
    """
  end
end
