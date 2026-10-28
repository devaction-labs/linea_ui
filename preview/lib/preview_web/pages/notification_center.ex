defmodule PreviewWeb.Pages.NotificationCenter do
  use PreviewWeb.Page, title: "Notification center", category: :components

  @tabs [
    %{id: "all", label: "Todas"},
    %{id: "unread", label: "Não lidas"},
    %{id: "orders", label: "Pedidos", empty: "Nenhum pedido novo"},
    %{id: "system", label: "Sistema"},
    %{id: "notices", label: "Avisos", empty: "Nenhum aviso"}
  ]

  @items [
    %{id: 1, title: "Pedido aguardando aprovação", body: "Pedido 2483, Clínica Vida Plena", at: "há 4 min", group: "Hoje", type: "warning", category: "orders", read: false, href: "#"},
    %{id: 2, title: "Falha na integração", body: "Sincronização com o ERP: tempo esgotado", at: "há 22 min", group: "Hoje", type: "error", category: "system", read: false, href: "#"},
    %{id: 3, title: "Pedido faturado", body: "Pedido 2481, R$ 4.280,00", at: "07:41", group: "Hoje", type: "success", category: "orders", read: false, href: "#"},
    %{id: 4, title: "Novo documento recebido", body: "Distribuidora Nordeste, R$ 12.480,00", at: "06:58", group: "Hoje", type: "info", category: "system", read: true, href: "#"},
    %{id: 5, title: "Comunicado", body: "Janela de manutenção no sábado, 22h", at: "17:20", group: "Ontem", type: "primary", category: "notices", read: true, href: "#"},
    %{id: 6, title: "Pedido aguardando aprovação", body: "Pedido 2482, Pet Shop Amigo Fiel", at: "11:52", group: "Ontem", type: "warning", category: "orders", read: true, href: "#"}
  ]

  def mount(socket), do: assign(socket, items: @items, tabs: @tabs)

  def handle_event("read_all", _params, socket),
    do: {:noreply, assign(socket, items: Enum.map(socket.assigns.items, &Map.put(&1, :read, true)))}

  def handle_event("read", %{"item" => id}, socket),
    do: {:noreply, assign(socket, items: Enum.map(socket.assigns.items, &if(&1.id == id, do: Map.put(&1, :read, true), else: &1)))}

  def handle_event("reset", _params, socket), do: {:noreply, assign(socket, items: @items)}
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.example title="Bell and panel" text="The dot says something is unread. Tabs filter in the browser; mark all as read and click an item to read it." class="mt-5">
      <div class="flex min-h-[40rem] items-start justify-end gap-3">
        <.button variant="flat" size="sm" phx-click="reset">Reset</.button>
        <.notification_center id="nc-demo" items={@items} tabs={@tabs} on_read_all="read_all" on_read="read" all_href="#" preferences_href="#" open />
      </div>
    </.example>

    <.example title="Bell states" text="Up to date, pending." class="mt-5">
      <div class="flex gap-6">
        <.notification_center id="nc-clear" items={[]} tabs={[]} />
        <.notification_center id="nc-pending" items={@items} />
      </div>
    </.example>

    <.example title="Empty tab" text="Each tab has its own empty message." class="mt-5">
      <div class="flex min-h-[28rem] items-start justify-end">
        <.notification_center id="nc-empty" items={[]} tabs={@tabs} on_read_all="read_all" open />
      </div>
    </.example>
    """
  end
end
