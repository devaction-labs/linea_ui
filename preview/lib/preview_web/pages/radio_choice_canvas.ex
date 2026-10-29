defmodule PreviewWeb.Pages.RadioChoiceCanvas do
  use PreviewWeb.Page, title: "Radio e escolha (canvas)", category: :components

  @focus "outline-2 outline-offset-2 outline-primary"

  def render(assigns) do
    assigns = assign(assigns, focus: @focus)

    ~H"""
    <.example title="Radios" class="mt-5 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
      <.radio_group
        id="rc-a"
        name="rc-a"
        label="Prioridade · basic"
        value="normal"
        color="primary"
        class="flex-col gap-2.5 [&>*]:!m-0"
      >
        <:radio value="normal">Normal</:radio>
        <:radio value="alta">Alta</:radio>
        <:radio value="urgente" class={@focus}>
          Urgente <span class="text-xs text-slate-400">(foco)</span>
        </:radio>
        <:radio value="critica" disabled>Crítica</:radio>
      </.radio_group>

      <.radio_group
        id="rc-b"
        name="rc-b"
        label="Entrega · outline, com descrição"
        variant="outline"
        color="primary"
        value="loja"
        class="flex-col gap-2.5 [&>*]:!m-0"
      >
        <:radio value="loja" description="Disponível em 2 horas">Retirada na loja</:radio>
        <:radio value="expressa" description="Chega hoje, taxa de R$ 12">Entrega expressa</:radio>
      </.radio_group>

      <div>
        <span class="block">Cores e formato</span>
        <div class="mt-1.5 flex flex-wrap gap-x-5 gap-y-2.5">
          <.radio_group id="rc-c" name="rc-c" value="1" color="success">
            <:radio value="1">Sucesso</:radio>
          </.radio_group>
          <.radio_group id="rc-d" name="rc-d" value="1" color="warning">
            <:radio value="1">Aviso</:radio>
          </.radio_group>
          <.radio_group id="rc-e" name="rc-e" value="1" color="error">
            <:radio value="1">Erro</:radio>
          </.radio_group>
          <.radio_group id="rc-f" name="rc-f" value="1" color="primary" shape="squircle">
            <:radio value="1">Squircle</:radio>
          </.radio_group>
          <.radio_group
            id="rc-g"
            name="rc-g"
            value="1"
            color="info"
            variant="outline"
            shape="squircle"
          >
            <:radio value="1">Outline</:radio>
          </.radio_group>
        </div>
      </div>

      <.radio_group
        id="rc-h"
        name="rc-h"
        label="Termos · erro"
        errors={["Escolha uma opção para continuar."]}
        class="flex-col gap-2.5 [&>*]:!m-0"
        options={[{"Li e aceito", "sim"}, {"Não aceito", "nao"}]}
      />
    </.example>

    <.example title="Cartões" class="mt-5 grid grid-cols-1 gap-6 lg:grid-cols-2">
      <.radio_group
        id="rc-p"
        name="rc-p"
        label="Plano · cartão com descrição"
        variant="card"
        color="primary"
        value="essencial"
      >
        <:radio value="essencial" description="Até 3 usuários e 10 projetos ativos." count="R$ 49">
          Essencial
        </:radio>
        <:radio value="pro" description="Usuários ilimitados e relatórios." count="R$ 129">
          Profissional
        </:radio>
        <:radio value="enterprise" description="Sob consulta." disabled>Enterprise</:radio>
      </.radio_group>

      <.radio_group
        id="rc-s"
        name="rc-s"
        label="Sessão · cartão com ícone"
        variant="card"
        color="primary"
        value="once"
      >
        <:radio value="device" description="Manter conectado por 30 dias." icon="huge-laptop">
          Este dispositivo
        </:radio>
        <:radio value="once" description="Sair ao fechar o navegador." icon="huge-clock-01">
          Só desta vez
        </:radio>
        <:radio value="corp" description="Pede confirmação a cada acesso." icon="huge-truck">
          Rede da empresa
        </:radio>
      </.radio_group>
    </.example>

    <.example title="Escolha em pílulas" class="mt-5 grid grid-cols-1 gap-6 lg:grid-cols-2">
      <.radio_group
        id="rc-t"
        name="rc-t"
        label="Status · pílulas com contagem"
        variant="chip"
        color="primary"
        value="all"
        options={[
          %{label: "Todos", value: "all", count: 128},
          %{label: "Rascunho", value: "draft", count: 4},
          %{label: "Confirmado", value: "ok", count: 12},
          %{label: "Cancelado", value: "x", disabled: true}
        ]}
      />
      <.radio_group
        id="rc-u"
        name="rc-u"
        label="Período · estilo segmentado"
        variant="segmented"
        value="mes"
        options={[{"Semana", "semana"}, {"Mês", "mes"}, {"Trimestre", "tri"}]}
      />
    </.example>
    """
  end
end
