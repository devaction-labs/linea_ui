defmodule PreviewWeb.Pages.SignetumKit do
  use PreviewWeb.Page, title: "Signetum kit", category: :components

  @items [
    %{
      group: "Ir para",
      scope: "go",
      label: "Pedidos",
      sub: "Vendas",
      icon: "huge-shopping-cart-01",
      value: "orders",
      keys: ["G", "P"]
    },
    %{
      group: "Ir para",
      scope: "go",
      label: "Clientes",
      sub: "Relacionamento",
      icon: "huge-user-group",
      value: "customers",
      keys: ["G", "C"]
    },
    %{
      group: "Ir para",
      scope: "go",
      label: "Produtos",
      sub: "Catálogo",
      icon: "huge-package",
      value: "products",
      keys: ["G", "R"]
    },
    %{
      group: "Ações",
      scope: "act",
      label: "Novo pedido",
      sub: "Abre o formulário de pedido",
      icon: "huge-add-01",
      value: "new-order",
      keys: ["N"]
    },
    %{
      group: "Ações",
      scope: "act",
      label: "Novo cliente",
      sub: "Com consulta de CNPJ",
      icon: "huge-add-01",
      value: "new-customer"
    },
    %{
      group: "Recentes",
      scope: "rec",
      label: "PV-1283 · Clínica Santa Mônica",
      sub: "Pedido · R$ 12.850,40",
      icon: "huge-shopping-cart-01",
      value: "pv-1283"
    }
  ]

  def mount(socket), do: assign(socket, items: @items, picked: nil)

  def handle_event("palette-select", %{"value" => value, "new_tab" => new_tab}, socket),
    do: {:noreply, assign(socket, picked: "#{value} (new tab: #{new_tab})")}

  def handle_event("palette-assistant", %{"query" => query}, socket),
    do: {:noreply, assign(socket, picked: "assistant: #{query}")}

  def render(assigns) do
    ~H"""
    <.example
      title="Command palette"
      text="Ctrl K or the button; type, pick a scope, arrows and Enter."
    >
      <.button id="open-palette" phx-click={LineaUI.open("palette")}>Open palette</.button>
      <span id="picked" class="text-sm">{@picked}</span>
      <.command_palette
        id="palette"
        items={@items}
        scopes={[{"Tudo", "all"}, {"Páginas", "go"}, {"Ações", "act"}, {"Recentes", "rec"}]}
        assistant={
          %{label: "Perguntar ao assistente: “%{query}”", sub: "Responde com os dados da sua empresa"}
        }
        label="Paleta de comandos"
        placeholder="Buscar ou digitar um comando"
        empty="Nada encontrado"
        hint_navigate="navegar"
        hint_open="abrir"
        hint_new_tab="abrir em nova aba"
        scopes_label="Onde buscar"
        on_select="palette-select"
        on_assistant="palette-assistant"
      />
    </.example>
    """
  end
end
