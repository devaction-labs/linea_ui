defmodule LineaUI.Components.Scrollspy do
  @moduledoc """
  A list of links to the sections of the page that marks the section in view: the
  settings pages with their menu of anchors.

      <.scrollspy id="settings-nav">
        <:item href="#profile">Profile</:item>
        <:item href="#security">Security</:item>
      </.scrollspy>

  The hook `LineaUI.Scrollspy` watches the elements the links point at and sets `aria-current` on the link of the one
  that is at the top of the view (`offset` pixels from the top, 120 by default). A click scrolls to the section.
  """

  use LineaUI.Component

  @doc """
  Renders the list of anchors.

      <.scrollspy id="nav" offset={96}>
        <:item href="#a">A</:item>
      </.scrollspy>
  """
  attr :id, :string, required: true
  attr :label, :string, default: "On this page", doc: "The accessible name of the navigation."
  attr :offset, :integer, default: 120
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :href, :string, required: true, doc: "The `#id` of the section."
  end

  def scrollspy(assigns) do
    ~H"""
    <nav
      id={@id}
      aria-label={@label}
      phx-hook="LineaUI.Scrollspy"
      phx-mounted={JS.ignore_attributes(["data-active"])}
      data-offset={@offset}
      class={merge(["flex flex-col gap-1", @class])}
      {@rest}
    >
      <a
        :for={item <- @item}
        href={item.href}
        data-spy-link
        class="rounded-md px-2.5 py-2 text-sm font-medium text-slate-700 outline-none hover:bg-slate-100 hover:text-slate-950 focus-visible:ring-2 focus-visible:ring-primary/50 aria-[current=true]:bg-slate-100 aria-[current=true]:text-primary dark:text-navy-200 dark:hover:bg-navy-600 dark:hover:text-navy-50 dark:aria-[current=true]:bg-navy-600 dark:aria-[current=true]:text-accent-light"
      >
        {render_slot(item)}
      </a>
    </nav>
    """
  end
end
