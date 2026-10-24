defmodule LineaUI.Components.Drawer do
  @moduledoc """
  LineOne's drawer: a full-height panel that slides in from the left or the right over a dark
  backdrop. Bare, it is a sliding frame for a menu; with a `title` (or a `:header`) and a `:footer`
  it is a sheet, the panel a form or a detail opens in: a header with the title, its description
  and the close ×, a body that scrolls, and a footer with the buttons.

      <.button phx-click={LineaUI.toggle("menu")}>Menu</.button>

      <.drawer id="menu" side="right">
        <nav class="p-5">…</nav>
      </.drawer>

      <.drawer id="customer" placement="right" size="md" title="New customer"
        description="Who buys from you." on_close="cancel">
        <.form for={@form} id="customer-form" phx-submit="save">…</.form>
        <:footer>
          <.button variant="outline" phx-click={LineaUI.close("customer")}>Cancel</.button>
          <.button type="submit" form="customer-form" color="primary">Save</.button>
        </:footer>
      </.drawer>

  `size` sets the sheet's width (`sm` 400px, `md` 560px, `lg` 760px, `xl` 1080px), never wider
  than the screen, so it is full width on a phone. Buttons in the header go in `:actions`, a back
  arrow (a sheet opened from another) in `:back`.

  Like the modal it opens from the browser (`LineaUI.open/close/toggle("id")`), from the server
  (`LineaUI.open(socket, "id")`) or from `open`; `on_close` runs however it closed (Esc, the
  backdrop, the ×, a command), so the server can follow. By default a drawer does not lock the
  page's scroll, as in LineOne (`lock_scroll` locks it).

  Drawers and modals stack in the order they open: a drawer opened from another (a detail, then
  its edit form), or a modal opened from a drawer, is drawn above it; Esc and the backdrop close
  only the one on top. The second overlay may sit next to the first or inside its markup (a
  confirm rendered in the sheet's body or footer): the open drawer carries no CSS `transform`
  (the slide is an animation that only runs while it enters and leaves, with no fill), so it
  is not a containing block for `position: fixed` and a modal inside it still covers the whole
  viewport, above the drawer. Keep `panel_class` and `class` free of `transform`, `filter`,
  `backdrop-filter`, `perspective` and `contain` for the same reason. Nothing is moved out of
  the LiveView's DOM, so patches reach the nested modal as usual.
  The layers come from the CSS custom properties `--linea-z-overlay` (drawers) and
  `--linea-z-modal` (modals), see the README.
  """

  use LineaUI.Component

  alias LineaUI.Components.Overlay

  @sizes %{
    nil => "w-72",
    "sm" => "w-full max-w-[400px]",
    "md" => "w-full max-w-[560px]",
    "lg" => "w-full max-w-[760px]",
    "xl" => "w-full max-w-[1080px]"
  }

  @doc """
  Renders a drawer, closed unless `open`.

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :side, :string, default: "left", values: ~w(left right)

  attr :placement, :string,
    default: nil,
    values: [nil, "left", "right"],
    doc: "The same as `side`, which it overrides when given."

  attr :size, :string,
    default: nil,
    values: [nil, "sm", "md", "lg", "xl"],
    doc:
      "The sheet's width: `sm` 400px, `md` 560px, `lg` 760px, `xl` 1080px, full width on a phone. `nil` is LineOne's `w-72` frame."

  attr :title, :string, default: nil, doc: "The sheet's title; draws the header."
  attr :description, :string, default: nil, doc: "A line under the title."

  attr :close_button, :boolean,
    default: true,
    doc: "The × at the end of the header (only drawn when there is a header)."

  attr :close_label, :string, default: "Close"

  attr :overlay, :boolean,
    default: true,
    doc: "The dark backdrop, which closes the drawer when clicked."

  attr :lock_scroll, :boolean,
    default: false,
    doc: "Locks the page's scroll while it is open, as a modal does."

  attr :prevent_close, :boolean, default: false, doc: "Esc and the backdrop do not close it."
  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_open` / `on_close` events."

  attr :class, :any,
    default: nil,
    doc:
      "Merged into the sliding frame: its width (`size`, or `w-72`; e.g. `class=\"w-96\"`) and shadow."

  attr :panel_class, :any, default: nil, doc: "Merged into the white panel inside the frame."

  attr :body_class, :any,
    default: nil,
    doc: "Merged into the scrolling body of a sheet (`px-6 py-5`, a column with `gap-4`)."

  attr :rest, :global

  slot :header,
    doc:
      "The header's content instead of `title` and `description`; the back arrow, the actions and the × still frame it." do
    attr :class, :any
  end

  slot :back,
    doc:
      "Before the title: the button back to the sheet this one was opened from (`phx-click={LineaUI.close(\"this\")}`)."

  slot :actions, doc: "Buttons at the end of the header, before the ×."

  slot :footer, doc: "The buttons under the body, aligned to the end, on a tinted bar." do
    attr :class, :any
  end

  slot :inner_block, required: true

  def drawer(assigns) do
    side = assigns.placement || assigns.side

    assigns =
      assigns
      |> assign(:side, side)
      |> assign(:sheet, sheet?(assigns))
      |> assign(:headed, assigns.title != nil or assigns.header != [])
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <div
      id={@id}
      class={["drawer", @side == "right" && "drawer-right"]}
      role="dialog"
      aria-modal={bool(@overlay)}
      aria-hidden="true"
      aria-labelledby={@headed && "#{@id}-title"}
      phx-hook="LineaUI.Dialog"
      phx-mounted={JS.ignore_attributes(["data-state", "aria-hidden", "style"])}
      data-state="closed"
      data-open={bool(@open)}
      data-kind="drawer"
      data-lock={bool(@lock_scroll)}
      data-leave-ms="200"
      data-prevent-close={bool(@prevent_close)}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <div
        :if={@overlay}
        class="drawer-overlay fixed inset-0 hidden bg-slate-900/60"
        phx-mounted={JS.ignore_attributes(["class"])}
        data-backdrop
      >
      </div>
      <div
        class={
          merge([
            "drawer-content fixed top-0 hidden h-full",
            size_class(@size),
            side_class(@side),
            @class
          ])
        }
        phx-mounted={JS.ignore_attributes(["class"])}
      >
        <div
          id={"#{@id}-panel"}
          class={
            merge([
              "flex h-full w-full flex-col bg-white outline-hidden transition-transform duration-200 dark:bg-navy-700",
              @sheet && "shadow-[-12px_0_40px_-12px_rgb(15_23_42/.35)]",
              @panel_class
            ])
          }
          tabindex="-1"
          data-panel
        >
          <.drawer_layout
            sheet={@sheet}
            headed={@headed}
            id={@id}
            title={@title}
            description={@description}
            header={@header}
            back={@back}
            actions={@actions}
            footer={@footer}
            close_button={@close_button}
            close_label={@close_label}
            body_class={@body_class}
          >
            {render_slot(@inner_block)}
          </.drawer_layout>
        </div>
      </div>
    </div>
    """
  end

  attr :sheet, :boolean, required: true
  attr :headed, :boolean, required: true
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :header, :list, required: true
  attr :back, :list, required: true
  attr :actions, :list, required: true
  attr :footer, :list, required: true
  attr :close_button, :boolean, required: true
  attr :close_label, :string, required: true
  attr :body_class, :any, required: true
  slot :inner_block, required: true

  defp drawer_layout(%{sheet: false} = assigns), do: ~H"{render_slot(@inner_block)}"

  defp drawer_layout(assigns) do
    ~H"""
    <header
      :if={@headed or @back != [] or @actions != []}
      class={
        merge([
          "flex shrink-0 items-start gap-3 border-b border-slate-150 px-4 pt-5 pb-4 dark:border-navy-600 sm:px-6",
          Enum.find_value(@header, &Map.get(&1, :class))
        ])
      }
      data-drawer-header
    >
      <div :if={@back != []} class="-ml-1.5 flex shrink-0 items-center">{render_slot(@back)}</div>
      <div class="min-w-0 flex-1">
        <div :if={@header != []} id={"#{@id}-title"}>{render_slot(@header)}</div>
        <h2
          :if={@header == [] and @title}
          id={"#{@id}-title"}
          class="text-lg/[26px] font-medium text-slate-800 dark:text-navy-50"
        >
          {@title}
        </h2>
        <p
          :if={@header == [] and @description}
          class="mt-0.5 text-[13px]/[18px] text-slate-400 dark:text-navy-300"
        >
          {@description}
        </p>
      </div>
      <div :if={@actions != []} class="flex shrink-0 flex-wrap items-center gap-2">
        {render_slot(@actions)}
      </div>
      <button
        :if={@close_button}
        type="button"
        class="btn -mr-1.5 size-8 shrink-0 rounded-full p-0 text-slate-500 hover:bg-slate-300/20 hover:text-slate-800 focus:bg-slate-300/20 active:bg-slate-300/25 dark:text-navy-200 dark:hover:bg-navy-300/20 dark:hover:text-navy-50 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"
        aria-label={@close_label}
        phx-click={LineaUI.close(@id)}
        data-drawer-close
      >
        <Overlay.close_icon />
      </button>
    </header>
    <div
      class={
        merge([
          "scrollbar-sm flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto px-4 py-5 sm:px-6",
          @body_class
        ])
      }
      data-drawer-body
    >
      {render_slot(@inner_block)}
    </div>
    <footer
      :for={footer <- @footer}
      class={
        merge([
          "flex shrink-0 items-center justify-end gap-2 border-t border-slate-150 bg-slate-50 px-4 py-3.5 dark:border-navy-600 dark:bg-navy-750 sm:px-6",
          Map.get(footer, :class)
        ])
      }
      data-drawer-footer
    >
      {render_slot(footer)}
    </footer>
    """
  end

  defp sheet?(%{title: nil, header: [], back: [], actions: [], footer: []}), do: false
  defp sheet?(_assigns), do: true

  defp size_class(size), do: Map.fetch!(@sizes, size)
  defp side_class("left"), do: "left-0"
  defp side_class("right"), do: "right-0"
end
