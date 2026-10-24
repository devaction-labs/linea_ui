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

  A sheet is `variant="float"` by default: 12px from the screen's edges, 16px corners, always the
  whole height, the footer fixed under the body. `variant="flush"` is the panel glued to the edge,
  as LineOne draws it. `placement` is `left`, `right` or `bottom`; the bottom one is the phone's
  sheet, a rounded panel with a grab handle, 78% of the screen's height and the full width.

  The header, the body and the footer are also components of their own, for a sheet laid out by
  hand (`variant` makes a bare drawer a sheet):

      <.drawer id="edit-customer" variant="float" size="lg" on_close={JS.patch(~p"/customers")}>
        <.sheet_header title="Edit customer" description="Since March 2025" />
        <.sheet_body>
          <.input field={@form[:legal_name]} label="Legal name" />
        </.sheet_body>
        <.sheet_footer>
          <.button variant="outline" phx-click={LineaUI.close("edit-customer")}>Cancel</.button>
          <.button color="primary">Save</.button>
        </.sheet_footer>
      </.drawer>

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

  @float_sizes %{
    nil => "w-72 max-w-[calc(100%-1.5rem)]",
    "sm" => "w-full max-w-[min(400px,calc(100%-1.5rem))]",
    "md" => "w-full max-w-[min(560px,calc(100%-1.5rem))]",
    "lg" => "w-full max-w-[min(760px,calc(100%-1.5rem))]",
    "xl" => "w-full max-w-[min(1080px,calc(100%-1.5rem))]"
  }

  @frames %{
    {nil, "left"} => "top-0 left-0 h-full",
    {nil, "right"} => "top-0 right-0 h-full",
    {"float", "left"} => "top-3 left-3 h-[calc(100%-1.5rem)]",
    {"float", "right"} => "top-3 right-3 h-[calc(100%-1.5rem)]",
    {"float", "bottom"} => "inset-x-3 bottom-3 h-[78dvh]",
    {"flush", "left"} => "top-0 left-0 h-full",
    {"flush", "right"} => "top-0 right-0 h-full",
    {"flush", "bottom"} => "inset-x-0 bottom-0 h-[78dvh]"
  }

  @floating "overflow-hidden rounded-2xl shadow-[0_24px_48px_-12px_rgb(15_23_42/.35)] ring-1 ring-slate-150 dark:shadow-[0_24px_48px_-12px_rgb(0_0_0/.5)] dark:ring-navy-500"

  @flush "shadow-[0_0_40px_rgb(15_23_42/.2)] dark:shadow-[0_24px_48px_-12px_rgb(0_0_0/.5)] dark:ring-1 dark:ring-navy-500"

  @panels %{
    {"float", "left"} => @floating,
    {"float", "right"} => @floating,
    {"float", "bottom"} => @floating,
    {"flush", "left"} => @flush,
    {"flush", "right"} => @flush,
    {"flush", "bottom"} => "overflow-hidden rounded-t-2xl #{@flush}"
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
    values: [nil, "left", "right", "bottom"],
    doc:
      "The same as `side`, which it overrides when given. `bottom` is the phone's sheet: full width, 78% of the height, with a grab handle."

  attr :size, :string,
    default: nil,
    values: [nil, "sm", "md", "lg", "xl"],
    doc:
      "The sheet's width: `sm` 400px, `md` 560px, `lg` 760px, `xl` 1080px, full width on a phone. `nil` is LineOne's `w-72` frame."

  attr :variant, :string,
    default: nil,
    values: [nil, "float", "flush"],
    doc:
      "A sheet is `float` unless told otherwise: 12px from the edges, 16px corners, the whole height, a fixed footer. `flush` is glued to the edge. Giving it makes a drawer without title or footer a sheet, for `sheet_header`, `sheet_body` and `sheet_footer` laid out by hand."

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
    layout = layout?(assigns)
    variant = variant(assigns, layout)

    assigns =
      assigns
      |> assign(:side, side)
      |> assign(:layout, layout)
      |> assign(:variant, variant)
      |> assign(:headed, assigns.title != nil or assigns.header != [])
      |> assign(:frame, frame_class(variant, side, assigns.size))
      |> assign(:panel, panel_class(variant, side))
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <div
      id={@id}
      class={[
        "drawer",
        @side == "right" && "drawer-right",
        @side == "bottom" && "drawer-bottom",
        @variant == "float" && "drawer-float"
      ]}
      role="dialog"
      aria-modal={bool(@overlay)}
      aria-hidden="true"
      aria-labelledby={@headed && "#{@id}-title"}
      phx-hook="LineaUI.Dialog"
      phx-mounted={JS.ignore_attributes(["data-state", "aria-hidden", "style"])}
      data-state="closed"
      data-open={bool(@open)}
      data-kind="drawer"
      data-variant={@variant}
      data-placement={@side}
      data-lock={bool(@lock_scroll)}
      data-leave-ms="200"
      data-prevent-close={bool(@prevent_close)}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <div
        :if={@overlay}
        class="drawer-overlay fixed inset-0 hidden bg-slate-900/45"
        phx-mounted={JS.ignore_attributes(["class"])}
        data-backdrop
      >
      </div>
      <div
        class={merge(["drawer-content fixed hidden", @frame, @class])}
        phx-mounted={JS.ignore_attributes(["class"])}
      >
        <div
          id={"#{@id}-panel"}
          class={
            merge([
              "flex h-full w-full flex-col bg-white outline-hidden transition-transform duration-200 dark:bg-navy-700",
              @panel,
              @panel_class
            ])
          }
          tabindex="-1"
          data-panel
        >
          <span
            :if={@variant && @side == "bottom"}
            class="mx-auto mt-2.5 h-1 w-10 shrink-0 rounded-full bg-slate-300 dark:bg-navy-450"
            aria-hidden="true"
            data-drawer-grab
          ></span>
          <.drawer_layout
            sheet={@layout}
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
    <.sheet_header
      :if={@header == [] and (@headed or @back != [] or @actions != [])}
      id={"#{@id}-title"}
      drawer={@id}
      title={@title}
      description={@description}
      close_button={@close_button}
      close_label={@close_label}
    >
      <:back :if={@back != []}>{render_slot(@back)}</:back>
      <:actions :if={@actions != []}>{render_slot(@actions)}</:actions>
    </.sheet_header>
    <.sheet_header
      :if={@header != []}
      id={"#{@id}-title"}
      drawer={@id}
      class={Enum.find_value(@header, &Map.get(&1, :class))}
      close_button={@close_button}
      close_label={@close_label}
    >
      <:back :if={@back != []}>{render_slot(@back)}</:back>
      <:actions :if={@actions != []}>{render_slot(@actions)}</:actions>
      <:content>{render_slot(@header)}</:content>
    </.sheet_header>
    <.sheet_body class={@body_class}>{render_slot(@inner_block)}</.sheet_body>
    <.sheet_footer :for={footer <- @footer} class={Map.get(footer, :class)}>
      {render_slot(footer)}
    </.sheet_footer>
    """
  end

  @doc """
  The header of a sheet: the title with its description, a back arrow, buttons and the close ×.
  A `drawer` with `title`, `:header`, `:back` or `:actions` draws it by itself; use this one to lay
  a sheet out by hand.

      <.sheet_header title="Edit customer" description="Since March 2025">
        <:actions><.button size="sm">Archive</.button></:actions>
      </.sheet_header>

  The × closes the drawer it is in (the closest one), or the `drawer` with that id.
  """
  attr :id, :string, default: nil, doc: "The id of the title, for the drawer's `aria-labelledby`."

  attr :drawer, :string,
    default: nil,
    doc: "The id of the drawer the × closes; the closest drawer when not given."

  attr :title, :string, default: nil
  attr :description, :string, default: nil, doc: "A line under the title."
  attr :close_button, :boolean, default: true
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :content, doc: "The header's content instead of `title` and `description`."
  slot :back, doc: "Before the title: the button back to the sheet this one was opened from."
  slot :actions, doc: "Buttons at the end of the header, before the ×."

  def sheet_header(assigns) do
    assigns = assign(assigns, :close_js, close_js(assigns.drawer))

    ~H"""
    <header
      class={
        merge([
          "flex shrink-0 items-start gap-3 border-b border-slate-150 px-4 pt-5 pb-4 dark:border-navy-700 sm:px-5.5",
          @class
        ])
      }
      data-drawer-header
      {@rest}
    >
      <div :if={@back != []} class="-ml-1.5 flex shrink-0 items-center">{render_slot(@back)}</div>
      <div class="min-w-0 flex-1">
        <div :if={@content != []} id={@id}>{render_slot(@content)}</div>
        <h2
          :if={@content == [] and @title}
          id={@id}
          class="text-lg/[26px] font-medium text-slate-800 dark:text-navy-50"
        >
          {@title}
        </h2>
        <p
          :if={@content == [] and @description}
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
        phx-click={@close_js}
        data-drawer-close
      >
        <Overlay.close_icon />
      </button>
    </header>
    """
  end

  @doc """
  The scrolling body of a sheet: it takes the height the header and the footer leave and scrolls by
  itself, so the footer stays in place.

      <.sheet_body>…the form…</.sheet_body>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_body(assigns) do
    ~H"""
    <div
      class={
        merge([
          "scrollbar-sm flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto px-4 py-5 sm:px-5.5",
          @class
        ])
      }
      data-drawer-body
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The footer of a sheet: the buttons, aligned to the end on a tinted bar that never scrolls with the
  body.

      <.sheet_footer>
        <.button variant="outline" phx-click={LineaUI.close("customer")}>Cancel</.button>
        <.button color="primary">Save</.button>
      </.sheet_footer>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_footer(assigns) do
    ~H"""
    <footer
      class={
        merge([
          "flex shrink-0 items-center justify-end gap-2 border-t border-slate-150 bg-slate-50 px-4 py-3.5 dark:border-navy-700 dark:bg-navy-750 sm:px-5.5",
          @class
        ])
      }
      data-drawer-footer
      {@rest}
    >
      {render_slot(@inner_block)}
    </footer>
    """
  end

  defp close_js(nil), do: JS.dispatch(%JS{}, "linea:close", to: {:closest, "[data-kind=drawer]"})
  defp close_js(id), do: LineaUI.close(id)

  defp layout?(%{title: nil, header: [], back: [], actions: [], footer: []}), do: false
  defp layout?(_assigns), do: true

  defp variant(%{variant: nil}, true), do: "float"
  defp variant(%{variant: nil, placement: "bottom"}, false), do: "flush"
  defp variant(%{variant: variant}, _layout), do: variant

  defp frame_class(nil, side, size), do: "#{Map.fetch!(@frames, {nil, side})} #{size_class(size)}"
  defp frame_class(variant, "bottom", _size), do: Map.fetch!(@frames, {variant, "bottom"})

  defp frame_class("float", side, size),
    do: "#{Map.fetch!(@frames, {"float", side})} #{Map.fetch!(@float_sizes, size)}"

  defp frame_class("flush", side, size),
    do: "#{Map.fetch!(@frames, {"flush", side})} #{size_class(size)}"

  defp panel_class(nil, _side), do: nil
  defp panel_class(variant, side), do: Map.fetch!(@panels, {variant, side})

  defp size_class(size), do: Map.fetch!(@sizes, size)
end
