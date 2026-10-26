defmodule LineaUI.Components.ConnectionBanner do
  @moduledoc """
  The notice of a lost connection, as a toast: while the LiveView socket is down the toaster shows a
  `loading` toast with the ring of light (`aura`), and it removes it when the socket is back.

      <.connection_banner />
      <.connection_banner title="Sem conexão" description="Tentando reconectar..." />

  Put it once in the root layout, next to the `<.toaster>` (it needs one on the page). It draws nothing
  by itself and has no JavaScript: `phx-disconnected` runs `show_toast/2` and `phx-connected` runs
  `dismiss_toast/2`.
  """

  use LineaUI.Component

  import LineaUI.Components.Toast, only: [show_toast: 2, dismiss_toast: 1]

  attr :id, :string, default: "linea-connection-banner"
  attr :title, :string, default: "Connection lost"
  attr :description, :string, default: "Trying to reconnect..."

  attr :color, :string,
    default: "warning",
    doc: "The light of the ring: `assistant primary secondary info success warning error`."

  attr :rest, :global

  def connection_banner(assigns) do
    assigns = assign(assigns, :toast_id, assigns.id <> "-toast")

    ~H"""
    <div
      id={@id}
      hidden
      phx-disconnected={
        show_toast(@title,
          id: @toast_id,
          kind: :loading,
          description: @description,
          aura: true,
          aura_color: @color,
          duration: :infinity
        )
      }
      phx-connected={dismiss_toast(@toast_id)}
      {@rest}
    >
    </div>
    """
  end
end
