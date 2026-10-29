defmodule PreviewWeb.Pages.PhoneInputCanvas do
  use PreviewWeb.Page, title: "Telefone (canvas)", category: :components

  def render(assigns) do
    ~H"""
    <.example
      title="Telefone"
      class="mt-5 grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-4"
    >
      <.phone_input
        id="ph-1"
        name="ph1"
        label="Telefone · vazio"
        help="O formulário envia +5511912345678."
        placeholder="(11) 91234-5678"
      />
      <.phone_input
        id="ph-2"
        name="ph2"
        label="Telefone · preenchido, com limpar"
        value="+5571987654321"
        clearable
        clear_label="Limpar"
      />
      <.phone_input
        id="ph-3"
        name="ph3"
        label="Telefone · digitando"
        help="Separadores surgem quando um dígito os segue."
        value="119"
      />
      <.phone_input
        id="ph-4"
        name="ph4"
        label="Telefone · erro"
        value="119123"
        errors={["Número incompleto."]}
      />
      <.phone_input
        id="ph-5"
        name="ph5"
        label="Telefone · desabilitado"
        country="PT"
        value="912345678"
        disabled
      />
      <div>
        <span class="block">Tamanhos sm e lg</span>
        <div class="mt-1.5 space-y-2">
          <.phone_input id="ph-sm" name="phsm" size="sm" placeholder="(11) 91234-5678" />
          <.phone_input id="ph-lg" name="phlg" size="lg" placeholder="(11) 91234-5678" />
        </div>
      </div>
    </.example>

    <.example title="Seletor aberto" class="mt-5 h-96 max-w-sm">
      <.phone_input
        id="ph-open"
        name="phopen"
        placeholder="(11) 91234-5678"
        search_placeholder="Buscar…"
      />
    </.example>
    """
  end
end
