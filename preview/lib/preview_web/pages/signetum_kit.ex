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

  def mount(socket),
    do:
      assign(socket,
        items: @items,
        picked: nil,
        form: to_form(%{"regime" => "simples"}, as: :company),
        status: "all",
        step: 1,
        failed: false
      )

  def handle_event("palette-select", %{"value" => value, "new_tab" => new_tab}, socket),
    do: {:noreply, assign(socket, picked: "#{value} (new tab: #{new_tab})")}

  def handle_event("palette-assistant", %{"query" => query}, socket),
    do: {:noreply, assign(socket, picked: "assistant: #{query}")}

  def handle_event("validate", %{"company" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :company))}

  def handle_event("set-status", %{"value" => value}, socket),
    do: {:noreply, assign(socket, status: value)}

  def handle_event("step", %{"to" => to}, socket),
    do: {:noreply, assign(socket, step: String.to_integer(to) |> max(0) |> min(3), failed: false)}

  def handle_event("fail", _params, socket), do: {:noreply, assign(socket, step: 1, failed: true)}

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

    <.example
      title="Segmented"
      text="Toggle buttons with aria-pressed; counts, form field and server value."
      class="mt-5 flex flex-col gap-5"
    >
      <.segmented
        id="seg-status"
        label="Status do pedido"
        value={@status}
        on_change="set-status"
        options={[
          %{label: "Todos", value: "all", count: 128},
          %{label: "Rascunho", value: "draft", count: 9},
          %{label: "Aprovado", value: "approved", count: 31},
          %{label: "Faturado", value: "billed", count: 88}
        ]}
      />
      <p class="text-sm">status: {@status}</p>
      <.segmented
        id="seg-period"
        label="Período"
        value="month"
        options={["Semana", "Mês", "Trimestre"]}
      />
      <.form for={@form} phx-change="validate">
        <.segmented
          field={@form[:regime]}
          label="Regime tributário"
          options={[{"Simples Nacional", "simples"}, {"Regime normal", "normal"}]}
        />
      </.form>
      <p class="text-sm">regime: {@form[:regime].value}</p>
      <.segmented id="seg-lg" size="lg" full value="a" options={["Lista", "Kanban"]} />
    </.example>

    <.example
      title="Empty state"
      text="The card for a whole area and the inline notice for tables, lists and search."
      class="mt-5 grid gap-5 md:grid-cols-2"
    >
      <.empty_state icon="huge-package" kicker="Contas a receber" title="Nenhum título ainda">
        Um título nasce quando uma nota com pagamento a prazo é autorizada.
        <:action>
          <.button color="primary">Novo pedido</.button>
          <.button variant="flat">Ver notas emitidas</.button>
        </:action>
      </.empty_state>
      <.empty_state
        icon="huge-ai-magic"
        tone="gradient"
        kicker="Assistente"
        title="Pergunte sobre a sua empresa"
      >
        Vendas da semana, notas para manifestar, clientes em atraso.
        <:action><.button color="primary">Fazer uma pergunta</.button></:action>
      </.empty_state>
      <div class="flex flex-col gap-3 md:col-span-2">
        <.empty_state variant="inline" icon="huge-search-01" title="Nada para “dipirona 1 g”">
          Tente outro termo ou limpe os filtros.
        </.empty_state>
        <.empty_state
          variant="inline"
          color="success"
          icon="huge-checkmark-circle-02"
          title="Nenhuma nota para manifestar"
        >
          Todas as notas recebidas já têm manifestação.
        </.empty_state>
        <.empty_state
          variant="inline"
          color="error"
          icon="huge-alert-02"
          title="Não deu para falar com a SEFAZ"
        >
          A consulta de notas recebidas não respondeu.
          <:action>
            <.button size="sm" variant="outline" color="error">Tentar de novo</.button>
          </:action>
        </.empty_state>
      </div>
    </.example>

    <.example
      title="Stepper"
      text="Horizontal and vertical, with done, current, error and to do states."
      class="mt-5 flex flex-col gap-6"
    >
      <.stepper current={@step} error={@failed}>
        <:step label="Empresa" sub="CNPJ e endereço fiscal" />
        <:step label="Certificado A1" sub="Arquivo .pfx e senha" />
        <:step label="Perfil fiscal" sub="Regime e operações" />
        <:step label="Nota de teste" sub="Emissão em homologação" />
      </.stepper>
      <div class="flex justify-between gap-2.5">
        <.button variant="outline" phx-click="step" phx-value-to={@step - 1}>Voltar</.button>
        <div class="flex gap-2">
          <.button variant="flat" phx-click="fail">Simular erro</.button>
          <.button color="primary" phx-click="step" phx-value-to={@step + 1}>Continuar</.button>
        </div>
      </div>
      <.stepper orientation="vertical" current={3}>
        <:step label="Dados da empresa" sub="Farmácia Signetum Ltda · 12.345.678/0001-90" />
        <:step label="Certificado digital" sub="A1 válido até 14/08/2027" />
        <:step label="Conta bancária" sub="Banco do Brasil · CC 48210-7" />
        <:step
          label="Cadastrar produtos"
          sub="12 cadastrados · importe a planilha para ir mais rápido"
        >
          <.button size="sm" color="primary">Importar planilha</.button>
        </:step>
        <:step label="Convidar a equipe" sub="Vendas, financeiro e estoque" />
        <:step label="Emitir a primeira NF-e" sub="Depois dos produtos, a partir de um pedido" />
      </.stepper>
    </.example>
    <.example
      title="Progress"
      text="Determinate bars and the indeterminate ones, sliding or with the running shine."
      class="mt-5 flex flex-col gap-5"
    >
      <.progress value={64} color="primary" label="Importando planilha" />
      <.progress indeterminate shine color="primary" label="Compactando o pacote de XMLs" />
      <.progress indeterminate color="primary" label="Sliding" />
      <.progress value={82} color="warning" label="Notas emitidas" />
      <.progress value={24} color="success" label="Armazenamento" />
    </.example>
    """
  end
end
