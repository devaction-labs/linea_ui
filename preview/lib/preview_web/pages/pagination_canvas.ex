defmodule PreviewWeb.Pages.PaginationCanvas do
  use PreviewWeb.Page, title: "Pagination (canvas)", category: :components

  @sum "Mostrando %{first}–%{last} de %{total}"
  # the same classes, written out so Tailwind finds them
  @hv3 "[&_li:nth-child(4)_button]:!bg-slate-300 dark:[&_li:nth-child(4)_button]:!bg-navy-450"
  @fc3 "[&_li:nth-child(4)_button]:relative [&_li:nth-child(4)_button]:outline-2 [&_li:nth-child(4)_button]:outline-offset-1 [&_li:nth-child(4)_button]:outline-primary/55 dark:[&_li:nth-child(4)_button]:outline-accent/55"
  @fc4 "[&_li:nth-child(5)_button]:relative [&_li:nth-child(5)_button]:outline-2 [&_li:nth-child(5)_button]:outline-offset-1 [&_li:nth-child(5)_button]:outline-primary/55 dark:[&_li:nth-child(5)_button]:outline-accent/55"

  def render(assigns) do
    assigns =
      assign(assigns, sum: @sum, hv3: @hv3, fc3: @fc3, fc4: @fc4)

    ~H"""
    <.example
      title="Formas e variantes"
      text="Barra unida ou separada, rounded ou pill, três tamanhos"
    >
      <div class="grid w-full gap-x-7 gap-y-5 lg:grid-cols-2">
        <.panel>
          <.line label="rounded · barra unida (padrão)">
            <.pagination page={1} total_pages={5} on_change="noop" class={@fc3} />
          </.line>
          <.line label="pill · barra unida">
            <.pagination page={2} total_pages={5} on_change="noop" shape="pill" />
          </.line>
          <.line label="rounded · divided">
            <.pagination page={3} total_pages={5} on_change="noop" divided />
          </.line>
          <.line label="pill · divided">
            <.pagination page={3} total_pages={5} on_change="noop" divided shape="pill" />
          </.line>
        </.panel>
        <.panel>
          <.line label={~s(size="sm")}>
            <.pagination page={2} total_pages={5} on_change="noop" size="sm" />
          </.line>
          <.line label={"size=\"md\" (padrão)"}>
            <.pagination page={2} total_pages={5} on_change="noop" />
          </.line>
          <.line label={~s(size="lg")}>
            <.pagination page={2} total_pages={5} on_change="noop" size="lg" />
          </.line>
        </.panel>
      </div>
    </.example>

    <.example
      title="Janela de páginas e estados"
      text="reticências, extremos, hover, foco"
      class="mt-5"
    >
      <div class="grid w-full gap-x-7 gap-y-5 lg:grid-cols-2">
        <.panel>
          <.line label="Início: anterior inerte (aria-disabled)">
            <.pagination page={1} total_pages={10} on_change="noop" />
          </.line>
          <.line label="Meio: siblings=1, boundaries=1 · 5 de 10">
            <.pagination page={5} total_pages={10} on_change="noop" class={@hv3} />
          </.line>
          <.line label="Fim: próxima inerte">
            <.pagination page={10} total_pages={10} on_change="noop" />
          </.line>
          <.line label="Hover em uma página e foco do teclado">
            <.pagination page={2} total_pages={5} on_change="noop" class={[@hv3, @fc4]} />
          </.line>
        </.panel>
        <div class="flex flex-col gap-5">
          <.panel>
            <p class="m-0 text-[11px] font-semibold tracking-widest text-slate-400 uppercase">
              Rodapé de lista · total_entries, page_size e page_sizes
            </p>
            <.pagination
              page={1}
              page_size={15}
              total_entries={128}
              page_sizes={[15, 30, 50]}
              on_change="noop"
              summary={@sum}
              page_size_label="%{size} / página"
            />
          </.panel>
          <.panel>
            <p class="m-0 text-[11px] font-semibold tracking-widest text-slate-400 uppercase">
              Página intermediária
            </p>
            <.pagination
              page={4}
              page_size={15}
              total_entries={128}
              page_sizes={[15, 30, 50]}
              on_change="noop"
              summary={@sum}
              page_size_label="%{size} / página"
            />
          </.panel>
        </div>
      </div>
    </.example>
    """
  end

  slot :inner_block, required: true

  defp panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 rounded-xl p-[18px] ring-1 ring-slate-150 dark:ring-navy-500">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp line(assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5">
      <small class="text-[11.5px] font-medium text-slate-400 dark:text-navy-300">{@label}</small>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
