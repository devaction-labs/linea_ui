defmodule LineaUI.Components.Modal do
  @moduledoc """
  LineOne's modal: a centered card over a dark backdrop, with LineOne's enter and leave animations.

      <.button phx-click={LineaUI.open("edit-pin")}>Edit</.button>

      <.modal id="edit-pin" animation="scale" origin="top">
        <:header>Edit Pin</:header>
        <p>Lorem ipsum dolor sit amet.</p>
        <:footer>
          <.button phx-click={LineaUI.close("edit-pin")}>Cancel</.button>
        </:footer>
      </.modal>

  It opens and closes in the browser (`LineaUI.open/close/toggle("id")`), from the server
  (`LineaUI.open(socket, "id")`) or from an assign:

      <.modal id="confirm" open={@confirming} on_close="cancel-confirm">…</.modal>

  `on_close` runs however the modal closed (Esc, the backdrop, the close button, a command), so
  the server can keep `@confirming` in sync. With an event name the LiveView (or `target`) gets
  `handle_event("cancel-confirm", %{"id" => "confirm"}, socket)`; a `%JS{}` is run as is.
  Without a `:header` the close × sits in the card's corner above the content; give wide content
  (an image) a `close_variant="chip"` so the button keeps a backdrop.

  `title` (with `description`) gives it the header of a sheet instead (the design canvas modal): the
  19px title over a muted line with the round × at the end, the body under it, and the `:footer`
  buttons aligned to the end over a line, like a `LineaUI.Components.Drawer` sheet:

      <.modal id="delete-customer" title="Delete customer?" description="Casa das Tintas" class="max-w-[440px]">
        <p>The orders stay in the history.</p>
        <:footer>
          <.button variant="ghost" phx-click={LineaUI.close("delete-customer")}>Cancel</.button>
          <.button color="error">Delete customer</.button>
        </:footer>
      </.modal>

  `prevent_close` keeps Esc and the backdrop from closing it.

  A modal opened from a drawer (or from another modal) is drawn above it, and Esc closes only
  the one on top; render it next to the drawer, not inside its markup. Its layer is the CSS
  custom property `--linea-z-modal` (see the README).
  """

  use LineaUI.Component

  alias LineaUI.Components.Drawer
  alias LineaUI.Components.Overlay

  @animations %{
    "fade" => "",
    "shift-up" => "shift-up",
    "shift-down" => "shift-down",
    "scale" => "modal-scale",
    "sheet" => "modal-sheet"
  }

  @placements %{
    "center" => "justify-center",
    "top" => "justify-start",
    "bottom" => "justify-end"
  }

  @sizes %{
    "xs" => "max-w-xs",
    "sm" => "max-w-sm",
    "md" => "max-w-md",
    "lg" => "max-w-lg",
    "xl" => "max-w-2xl",
    "full" => "max-w-full"
  }

  @close_variants %{
    "plain" =>
      "hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25",
    "chip" =>
      "bg-white/80 text-slate-700 shadow-sm backdrop-blur-sm hover:bg-white focus:bg-white dark:bg-navy-700/80 dark:text-navy-100 dark:hover:bg-navy-700 dark:focus:bg-navy-700"
  }

  @origins %{"center" => "", "top" => "origin-top", "bottom" => "origin-bottom"}

  @doc """
  Renders a modal, closed unless `open`.

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true

  attr :open, :boolean,
    default: false,
    doc: "The server's state; the browser can still open and close it."

  attr :animation, :string,
    default: "fade",
    values: Map.keys(@animations),
    doc: "LineOne's transitions: the backdrop always fades, the card shifts, scales or slides up."

  attr :size, :string, default: "lg", values: Map.keys(@sizes), doc: "The card's maximum width."
  attr :placement, :string, default: "center", values: Map.keys(@placements)

  attr :origin, :string,
    default: "center",
    values: Map.keys(@origins),
    doc: "Where the `scale` animation grows from."

  attr :blur, :boolean, default: false, doc: "Blurs the page behind the backdrop."

  attr :backdrop_class, :any,
    default: nil,
    doc:
      "Merged into the backdrop (`bg-black/30` for a lighter one than the default `bg-slate-900/60`)."

  attr :prevent_close, :boolean, default: false, doc: "Esc and the backdrop do not close it."

  attr :close_button, :boolean,
    default: true,
    doc: "The × in the header; without a header it sits in the card's corner."

  attr :close_variant, :string,
    default: "plain",
    values: ~w(plain chip),
    doc:
      "The corner × of a modal without a header: `plain` is a bare icon button, `chip` gives it a translucent backdrop so it stays legible over wide content such as an image."

  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_open` / `on_close` events."
  attr :close_label, :string, default: "Close"

  attr :role, :string,
    default: "dialog",
    values: ~w(dialog alertdialog),
    doc:
      "`alertdialog` for confirmations that interrupt the user (a destructive action); point `aria-describedby` at the message."

  attr :title, :string,
    default: nil,
    doc:
      "A sheet's header (the canvas modal): the title, `description` under it and the × (unless `close_button` is false); the `:footer` becomes the sheet's footer."

  attr :description, :string, default: nil, doc: "The line under `title`."

  attr :body_class, :any,
    default: nil,
    doc:
      "Merged into the body under a `:header` (`px-4 py-4 sm:px-5` by default) or a `title` (the sheet body)."

  attr :class, :any, default: nil, doc: "Merged into the card."
  attr :rest, :global

  slot :header do
    attr :variant, :string,
      values: ~w(bar plain),
      doc: "`bar` is LineOne's tinted title bar, `plain` the card title of the page."

    attr :class, :any
  end

  slot :inner_block, required: true

  slot :footer do
    attr :class, :any
  end

  def modal(assigns) do
    assigns =
      assigns
      |> assign(:layout, layout(assigns.title, assigns.header))
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <div
      id={@id}
      class={[
        "modal fixed inset-0 flex flex-col items-center overflow-hidden px-4 py-6 sm:px-5",
        animation_class(@animation),
        placement_class(@placement)
      ]}
      role={@role}
      aria-modal="true"
      aria-hidden="true"
      aria-labelledby={(@header != [] or @title != nil) && "#{@id}-title"}
      phx-hook="LineaUI.Dialog"
      phx-mounted='[["ignore_attrs",{"attrs":["class","data-state","aria-hidden","style"]}]]'
      data-state="closed"
      data-open={bool(@open)}
      data-kind="modal"
      data-layout={@layout == :sheet && "sheet"}
      data-lock="true"
      data-leave-ms="300"
      data-prevent-close={bool(@prevent_close)}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <div
        class={
          merge([
            "modal-overlay absolute inset-0 bg-slate-900/60",
            @blur && "backdrop-blur-sm",
            @backdrop_class
          ])
        }
        data-backdrop
      >
      </div>
      <div
        id={"#{@id}-panel"}
        class={
          merge([
            "modal-content relative flex w-full flex-col rounded-[22px] bg-white shadow-[0_0_0_1px_var(--color-slate-150),0_40px_90px_-30px_rgb(23_23_26/.4)] outline-hidden dark:bg-navy-700 dark:shadow-[0_0_0_1px_var(--color-navy-600)]",
            panel_class(@layout),
            size_class(@size),
            origin_class(@origin),
            @class
          ])
        }
        tabindex="-1"
        data-panel
      >
        <Drawer.sheet_header
          :if={@layout == :sheet}
          id={"#{@id}-title"}
          drawer={@id}
          title={@title}
          description={@description}
          close_button={@close_button}
          close_label={@close_label}
        />
        <.modal_header
          :for={header <- @header}
          :if={@layout != :sheet}
          header={header}
          variant={Map.get(header, :variant, "bar")}
          id={@id}
          close_button={@close_button}
          close_label={@close_label}
        />
        <button
          :if={@layout == :none and @close_button}
          type="button"
          class={
            merge([
              "btn absolute right-3 top-3 z-10 size-7 rounded-full p-0",
              close_variant_class(@close_variant)
            ])
          }
          aria-label={@close_label}
          phx-click={LineaUI.close(@id)}
        >
          <Overlay.close_icon />
        </button>
        <.modal_body layout={@layout} class={@body_class}>{render_slot(@inner_block)}</.modal_body>
        <Drawer.sheet_footer
          :for={footer <- @footer}
          :if={@layout == :sheet}
          class={Map.get(footer, :class)}
        >
          {render_slot(footer)}
        </Drawer.sheet_footer>
        <div
          :for={footer <- @footer}
          :if={@layout != :sheet}
          class={merge(["space-x-2 px-4 pb-4 text-right sm:px-5", Map.get(footer, :class)])}
        >
          {render_slot(footer)}
        </div>
      </div>
    </div>
    """
  end

  attr :header, :map, required: true
  attr :variant, :string, required: true
  attr :id, :string, required: true
  attr :close_button, :boolean, required: true
  attr :close_label, :string, required: true

  defp modal_header(%{variant: "plain"} = assigns) do
    ~H"""
    <div class={
      merge(["my-3 flex h-8 items-center justify-between px-4 sm:px-5", Map.get(@header, :class)])
    }>
      <h2
        id={"#{@id}-title"}
        class="font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100 lg:text-base"
      >
        {render_slot(@header)}
      </h2>
      <.close_button :if={@close_button} id={@id} label={@close_label} />
    </div>
    """
  end

  defp modal_header(assigns) do
    ~H"""
    <div class={
      merge([
        "flex justify-between rounded-t-lg bg-slate-200 px-4 py-3 dark:bg-navy-800 sm:px-5",
        Map.get(@header, :class)
      ])
    }>
      <h3 id={"#{@id}-title"} class="text-base font-medium text-slate-700 dark:text-navy-100">
        {render_slot(@header)}
      </h3>
      <.close_button :if={@close_button} id={@id} label={@close_label} />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true

  defp close_button(assigns) do
    ~H"""
    <button
      type="button"
      class="btn -mr-1.5 size-7 rounded-full p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"
      aria-label={@label}
      phx-click={LineaUI.close(@id)}
    >
      <Overlay.close_icon />
    </button>
    """
  end

  attr :layout, :atom, required: true
  attr :class, :any, required: true
  slot :inner_block, required: true

  defp modal_body(%{layout: :none} = assigns), do: ~H"{render_slot(@inner_block)}"

  defp modal_body(%{layout: :sheet} = assigns) do
    ~H"""
    <Drawer.sheet_body class={@class}>{render_slot(@inner_block)}</Drawer.sheet_body>
    """
  end

  defp modal_body(%{layout: :plain} = assigns) do
    ~H"""
    <div class={merge(["px-4 pb-4 sm:px-5", @class])}>{render_slot(@inner_block)}</div>
    """
  end

  defp modal_body(assigns) do
    ~H"""
    <div class={merge(["scrollbar-sm overflow-y-auto px-4 py-4 sm:px-5", @class])}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp layout(title, _header) when is_binary(title), do: :sheet
  defp layout(_title, []), do: :none
  defp layout(_title, [%{variant: "plain"} | _]), do: :plain
  defp layout(_title, [_ | _]), do: :bar

  defp panel_class(:bar), do: "overflow-hidden"
  defp panel_class(:sheet), do: "max-h-full overflow-hidden"
  defp panel_class(_layout), do: "scrollbar-sm overflow-y-auto"

  defp close_variant_class(variant), do: Map.fetch!(@close_variants, variant)
  defp animation_class(animation), do: Map.fetch!(@animations, animation)
  defp placement_class(placement), do: Map.fetch!(@placements, placement)
  defp size_class(size), do: Map.fetch!(@sizes, size)
  defp origin_class(origin), do: Map.fetch!(@origins, origin)
end
