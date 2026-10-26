defmodule PreviewWeb.Pages.ConnectionBanner do
  use PreviewWeb.Page, title: "Connection banner", category: :components

  def render(assigns) do
    ~H"""
    <.example title="A toast while the socket is down" text="Shown by phx-disconnected, dismissed by phx-connected. The buttons run the same two calls." class="mt-5">
      <.connection_banner id="cb-demo" title="Sem conexão" description="Tentando reconectar..." />
      <div class="flex gap-3">
        <.button
          phx-click={show_toast("Sem conexão", id: "cb-demo-toast", kind: :loading, description: "Tentando reconectar...", aura: true, aura_color: "warning", duration: :infinity)}
        >
          Disconnect
        </.button>
        <.button variant="outline" phx-click={dismiss_toast("cb-demo-toast")}>Reconnect</.button>
      </div>
    </.example>
    """
  end
end
