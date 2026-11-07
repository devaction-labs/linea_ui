defmodule LineaUI.Components.ContextMenu do
  @moduledoc """
  A menu that opens under the pointer on a right click.

      <.context_menu id="file-menu">
        <div class="rounded-lg border p-6">Right click here</div>
        <:item phx-click="rename">Rename</:item>
        <:item phx-click="copy">Copy</:item>
        <:item phx-click="delete" tone="danger" divider>Delete</:item>
      </.context_menu>

  The hook `LineaUI.ContextMenu` opens it at the pointer (kept inside the window), moves the focus to the first item and
  closes it on a click outside, on `Escape`, on a scroll and when an item is chosen. The arrows and `Home` and `End` move
  between the items.
  """

  use LineaUI.Component

  @doc """
  Renders the area and its menu.

      <.context_menu id="menu"><p>Area</p><:item>Open</:item></.context_menu>
  """
  attr :id, :string, required: true
  attr :label, :string, default: "Actions", doc: "The accessible name of the menu."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "The area that answers to the right click."

  slot :item do
    attr :tone, :string, values: ~w(default danger)
    attr :divider, :boolean, doc: "A line above the item."
    attr :disabled, :boolean
    attr :"phx-click", :any
    attr :"phx-value-id", :string
    attr :"phx-target", :any
  end

  def context_menu(assigns) do
    ~H"""
    <div id={@id} phx-hook="LineaUI.ContextMenu" class={merge(["contents", @class])} {@rest}>
      <div data-area class="contents">{render_slot(@inner_block)}</div>
      <div
        id={@id <> "-menu"}
        role="menu"
        aria-label={@label}
        data-menu
        hidden
        phx-update="ignore"
        class="fixed z-[9500] min-w-44 rounded-md border border-slate-200 bg-white p-1 shadow-md dark:border-navy-450 dark:bg-navy-900"
      >
        <%= for item <- @item do %>
          <div
            :if={item[:divider]}
            role="separator"
            class="-mx-1 my-1 h-px bg-slate-200 dark:bg-navy-450"
          >
          </div>
          <button
            type="button"
            role="menuitem"
            tabindex="-1"
            disabled={item[:disabled]}
            phx-click={item[:"phx-click"]}
            phx-value-id={item[:"phx-value-id"]}
            phx-target={item[:"phx-target"]}
            class={[
              "flex w-full items-center gap-2 rounded-md px-2.5 py-1.75 text-start text-sm outline-none focus-visible:bg-slate-100 hover:bg-slate-100 disabled:pointer-events-none disabled:opacity-50 dark:focus-visible:bg-navy-600 dark:hover:bg-navy-600",
              (item[:tone] == "danger" && "text-error") || "text-slate-950 dark:text-navy-50"
            ]}
          >
            {render_slot(item)}
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end
