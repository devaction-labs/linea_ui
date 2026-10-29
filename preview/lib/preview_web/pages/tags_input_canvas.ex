defmodule PreviewWeb.Pages.TagsInputCanvas do
  use PreviewWeb.Page, title: "Campo de tags (artboard)", category: :forms

  @suggestions [
    %{label: "Prioridade", value: "Prioridade", hint: "12 usos"},
    %{label: "Privado", value: "Privado", hint: "4 usos"},
    %{label: "Retorno", value: "Retorno", hint: "7 usos"}
  ]

  def mount(socket), do: assign(socket, suggestions: @suggestions)

  def render(assigns) do
    ~H"""
    <.example
      title="Campo de tags"
      text="Chips dentro do campo: Enter ou vírgula adiciona, x remove"
      class="mt-5"
    >
      <div class="grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-4">
        <.tags_input
          id="ti-1"
          name="t1"
          label="Etiquetas · padrão"
          help="Enter, Tab ou vírgula adicionam."
          value={["Prioridade", "Cliente VIP"]}
          placeholder="Adicionar…"
          removable
          compact
          create_position="bottom"
          create_label="Adicionar"
        />
        <.tags_input
          id="ti-2"
          name="t2"
          label="Etiquetas · foco"
          help="Backspace com o campo vazio remove a última."
          value={["Prioridade", "Retorno"]}
          removable
          compact
          create_position="bottom"
          create_label="Adicionar"
        />
        <.tags_input
          id="ti-3"
          name="t3"
          label="Responsáveis · máximo de 3"
          help="Remova um para adicionar outro."
          value={["Ana Souza", "Carlos Lima", "Marina Alves"]}
          max={3}
          limit_placeholder="Limite atingido"
          removable
          compact
          create_position="bottom"
          create_label="Adicionar"
        />
        <.tags_input
          id="ti-4"
          name="t4"
          label="Destinatários · erro"
          errors={["Informe ao menos uma etiqueta."]}
          placeholder="nome@empresa.com"
          compact
        />
        <.tags_input
          id="ti-5"
          name="t5"
          label="Etiquetas · com limpar"
          help="Limpar remove todas de uma vez."
          value={["Em revisão", "Backlog"]}
          removable
          compact
          create_position="bottom"
          create_label="Adicionar"
          clearable
          clear_label="Limpar tudo"
          remove_label="Remover"
        />
        <.tags_input
          id="ti-6"
          name="t6"
          label="Etiquetas · desabilitado"
          help="Somente leitura."
          value={["Arquivado", "2024"]}
          removable
          compact
          create_position="bottom"
          create_label="Adicionar"
          disabled
        />
      </div>
      <div class="mt-5 max-w-md" style="min-height: 15rem">
        <.tags_input
          id="ti-open"
          name="t7"
          label="Sugestões aberta · digitando “pri”"
          value={["Cliente VIP"]}
          suggestions={@suggestions}
          removable
          compact
          create_position="bottom"
          create_label="Adicionar"
        />
      </div>
    </.example>
    """
  end
end
