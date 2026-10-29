defmodule PreviewWeb.Pages.AutocompleteCanvas do
  use PreviewWeb.Page, title: "Autocomplete (artboard)", category: :forms

  @customers [
    %{label: "Ana Souza", value: "ana", hint: "ana@exemplo.com"},
    %{label: "Robando Alves", value: "robando", hint: "12 pedidos"},
    %{label: "Mariana Costa", value: "mariana", hint: "3 pedidos"},
    %{label: "Antônio Reis", value: "antonio", hint: "inativo", disabled: true},
    %{label: "Carlos Lima", value: "carlos", hint: "8 pedidos"}
  ]

  @projects [
    {"Ativos",
     [
       %{label: "Portal do cliente", value: "p104", hint: "PRJ-104"},
       %{label: "App de pedidos", value: "p098", hint: "PRJ-098"}
     ]},
    {"Concluídos", [%{label: "Site institucional", value: "p061", hint: "PRJ-061"}]}
  ]

  def mount(socket), do: assign(socket, customers: @customers, projects: @projects)

  # A slow server search, so the loading row stays visible long enough to see.
  def handle_event("search", %{"query" => query}, socket) do
    Process.sleep(4000)
    term = String.downcase(query)
    found = Enum.filter(@customers, &String.contains?(String.downcase(&1.label), term))
    {:noreply, assign(socket, customers: found)}
  end

  def render(assigns) do
    ~H"""
    <.example
      title="Autocomplete"
      text="Campo com lista de sugestões: destaque do trecho, carregando e vazio"
      class="mt-5 space-y-6"
    >
      <div class="grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-4">
        <.autocomplete
          id="ac-a"
          name="a"
          label="Cliente · vazio"
          help="Digite para filtrar a lista."
          options={@customers}
          placeholder="Escolha um cliente"
        >
          <:prefix><.icon name="huge-search-01" class="size-4" /></:prefix>
        </.autocomplete>
        <.autocomplete
          id="ac-b"
          name="b"
          value="ana"
          label="Cliente · escolhido, com limpar"
          help="Sair do campo com texto inválido restaura o rótulo."
          options={@customers}
          clearable
          clear_label="Limpar"
        >
          <:prefix><.icon name="huge-search-01" class="size-4" /></:prefix>
        </.autocomplete>
        <.autocomplete
          id="ac-c"
          name="c"
          label="Cliente · erro"
          errors={["Selecione um cliente da lista."]}
          options={@customers}
          placeholder="Escolha um cliente"
        />
        <.autocomplete
          id="ac-d"
          name="d"
          value="carlos"
          label="Cliente · desabilitado"
          help="Bloqueado após o faturamento."
          options={@customers}
          disabled
        />
      </div>

      <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-navy-300">
        Tamanhos
      </h3>
      <div class="grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-3">
        <div>
          <span class="text-sm text-slate-600 dark:text-navy-200">sm</span>
          <.autocomplete
            id="ac-sm"
            name="sm"
            size="sm"
            options={@customers}
            placeholder="Cliente"
            aria-label="Cliente sm"
          />
        </div>
        <div>
          <span class="text-sm text-slate-600 dark:text-navy-200">md</span>
          <.autocomplete
            id="ac-md"
            name="md"
            options={@customers}
            placeholder="Cliente"
            aria-label="Cliente md"
          />
        </div>
        <div>
          <span class="text-sm text-slate-600 dark:text-navy-200">lg</span>
          <.autocomplete
            id="ac-lg"
            name="lg"
            size="lg"
            options={@customers}
            placeholder="Cliente"
            aria-label="Cliente lg"
          />
        </div>
      </div>

      <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-navy-300">
        Lista aberta
      </h3>
      <div
        class="grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-4"
        style="min-height: 15rem"
      >
        <div>
          <.autocomplete
            id="ac-open"
            name="open"
            label="Digitando “an” · linha ativa pelo teclado"
            options={@customers}
          >
            <:prefix><.icon name="huge-search-01" class="size-4" /></:prefix>
          </.autocomplete>
        </div>
        <div>
          <.autocomplete
            id="ac-load"
            name="load"
            label="Busca no servidor · carregando"
            options={@customers}
            on_search="search"
            debounce={0}
            loading_text="Buscando…"
          >
            <:prefix><.icon name="huge-search-01" class="size-4" /></:prefix>
          </.autocomplete>
        </div>
        <div>
          <.autocomplete
            id="ac-none"
            name="none"
            label="Sem resultado"
            options={@customers}
            no_results="Nada para “%{query}”"
          >
            <:prefix><.icon name="huge-search-01" class="size-4" /></:prefix>
          </.autocomplete>
        </div>
        <div>
          <.autocomplete
            id="ac-groups"
            name="groups"
            label="Com grupos e slot de opção"
            options={@projects}
            placeholder="Escolha um projeto"
            open_on_focus
          />
        </div>
      </div>
    </.example>
    """
  end
end
