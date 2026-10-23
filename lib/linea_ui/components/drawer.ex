defmodule LineaUI.Components.Drawer do
  @moduledoc """
  LineOne's drawer: a full-height panel that slides in from the left or the right over a dark
  backdrop.

      <.button phx-click={LineaUI.toggle("menu")}>Menu</.button>

      <.drawer id="menu" side="right">
        <nav class="p-5">…</nav>
      </.drawer>

  Like the modal it opens from the browser (`LineaUI.open/close/toggle("id")`), from the server
  (`LineaUI.open(socket, "id")`) or from `open`; `on_close` runs however it closed (Esc, the
  backdrop, a command), so the server can follow. A drawer does not lock the page's scroll,
  as in LineOne.
  """

  use LineaUI.Component

  alias LineaUI.Components.Overlay

  @doc """
  Renders a drawer, closed unless `open`.

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :side, :string, default: "left", values: ~w(left right)

  attr :overlay, :boolean,
    default: true,
    doc: "The dark backdrop, which closes the drawer when clicked."

  attr :prevent_close, :boolean, default: false, doc: "Esc and the backdrop do not close it."
  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_open` / `on_close` events."

  attr :class, :any,
    default: nil,
    doc:
      "Merged into the sliding frame: its width (`w-72` by default, e.g. `class=\"w-96\"`) and shadow."

  attr :panel_class, :any, default: nil, doc: "Merged into the white panel inside the frame."
  attr :rest, :global
  slot :inner_block, required: true

  def drawer(assigns) do
    assigns =
      assigns
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <div
      id={@id}
      class={["drawer", @side == "right" && "drawer-right"]}
      role="dialog"
      aria-modal={bool(@overlay)}
      aria-hidden="true"
      phx-hook="LineaUI.Dialog"
      phx-mounted={JS.ignore_attributes(["data-state", "aria-hidden"])}
      data-state="closed"
      data-open={bool(@open)}
      data-kind="drawer"
      data-lock="false"
      data-leave-ms="200"
      data-prevent-close={bool(@prevent_close)}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <div
        :if={@overlay}
        class="drawer-overlay fixed inset-0 z-[100] hidden bg-slate-900/60"
        phx-mounted={JS.ignore_attributes(["class"])}
        data-backdrop
      >
      </div>
      <div
        class={
          merge(["drawer-content fixed top-0 z-[101] hidden h-full w-72", side_class(@side), @class])
        }
        phx-mounted={JS.ignore_attributes(["class"])}
      >
        <div
          id={"#{@id}-panel"}
          class={
            merge([
              "flex h-full w-full transform-gpu flex-col bg-white outline-hidden transition-transform duration-200 dark:bg-navy-700",
              @panel_class
            ])
          }
          tabindex="-1"
          data-panel
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp side_class("left"), do: "left-0"
  defp side_class("right"), do: "right-0"
end
