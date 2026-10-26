defmodule LineaUI.Components.ConnectionBanner do
  @moduledoc """
  A notice that shows while the LiveView socket is down and goes away when it is back: a pill with
  a spinner and a ring of light (`aura/1`), at the top or the bottom of the screen.

      <.connection_banner />
      <.connection_banner title="Sem conexão" description="Tentando reconectar..." position="bottom" />

  Put it once in the root layout, inside the `<body>`. It needs no hook and no JavaScript of its own: it
  is hidden at rest, `phx-disconnected` shows it and `phx-connected` hides it again. It is a
  `role="status"` live region, so a screen reader announces it.
  """

  use LineaUI.Component

  import LineaUI.Components.Spinner, only: [spinner: 1]
  import LineaUI.Components.Toast, only: [aura: 1]

  @positions ~w(top bottom)
  @colors ~w(assistant primary secondary info success warning error)

  attr :id, :string, default: "linea-connection-banner"
  attr :title, :string, default: "Connection lost"
  attr :description, :string, default: "Trying to reconnect..."
  attr :position, :string, default: "top", values: @positions, doc: "The edge of the screen."
  attr :color, :string, default: "warning", values: @colors, doc: "The light around the pill."
  attr :class, :any, default: nil
  attr :rest, :global

  def connection_banner(assigns) do
    ~H"""
    <div
      id={@id}
      role="status"
      aria-live="polite"
      data-position={@position}
      phx-disconnected={JS.remove_class("hidden", to: "##{@id}")}
      phx-connected={JS.add_class("hidden", to: "##{@id}")}
      class={
        merge([
          "linea-connection hidden pointer-events-none fixed inset-x-0 z-(--linea-z-toast) px-3",
          @position == "top" && "top-4",
          @position == "bottom" && "bottom-4",
          @class
        ])
      }
      {@rest}
    >
      <div class="flex justify-center">
        <.aura variant="glow" color={@color} class="pointer-events-auto rounded-full shadow-lg">
          <div class="flex items-center gap-3 rounded-full bg-white py-2 pr-5 pl-3 text-sm dark:bg-navy-700">
            <.spinner size="sm" label={@title} />
            <div class="leading-tight">
              <p class="font-medium text-slate-800 dark:text-navy-50">{@title}</p>
              <p class="text-xs text-slate-500 dark:text-navy-200">{@description}</p>
            </div>
          </div>
        </.aura>
      </div>
    </div>
    """
  end
end
