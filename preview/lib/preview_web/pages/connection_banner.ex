defmodule PreviewWeb.Pages.ConnectionBanner do
  use PreviewWeb.Page, title: "Connection banner", category: :components

  def render(assigns) do
    ~H"""
    <.example title="Shown while the socket is down" text="Hidden at rest; it is forced open here (class=block) to be seen. Stop the server to watch the real one." class="mt-5">
      <div class="relative h-28 overflow-hidden rounded-lg bg-slate-100 [transform:translateZ(0)] dark:bg-navy-900">
        <.connection_banner id="cb-demo" class="!absolute !block" title="Sem conexão" description="Tentando reconectar..." />
      </div>
    </.example>
    <.example title="At the bottom, in another color" class="mt-5">
      <div class="relative h-28 overflow-hidden rounded-lg bg-slate-100 [transform:translateZ(0)] dark:bg-navy-900">
        <.connection_banner id="cb-demo-2" class="!absolute !block" position="bottom" color="error" />
      </div>
    </.example>
    """
  end
end
