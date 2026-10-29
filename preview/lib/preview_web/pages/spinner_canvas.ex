defmodule PreviewWeb.Pages.SpinnerCanvas do
  use PreviewWeb.Page, title: "Spinner (canvas)", category: :components

  @colors ~w(neutral primary secondary info success warning error)
  @orders [
    {"Ana Souza", "Projeto Aurora", "R$ 1.240"},
    {"Carlos Lima", "Loja online", "R$ 860"},
    {"Marina Rocha", "Painel interno", "R$ 2.100"},
    {"Pedro Alves", "Aplicativo", "R$ 3.480"}
  ]

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, orders: @orders)

    ~H"""
    <div class="grid gap-5 lg:grid-cols-3">
      <.example title="Variant: primary, md" class="mt-2 block">
        <div class="flex flex-wrap items-end gap-x-5 gap-y-5">
          <.item label="border"><.spinner color="primary" size="md" /></.item>
          <.item label="soft"><.spinner color="primary" size="md" variant="soft" /></.item>
          <.item label="grow"><.spinner color="primary" size="md" variant="grow" /></.item>
          <.item label="svg"><.spinner color="primary" size="md" variant="svg" /></.item>
        </div>
        <p class="mt-3 text-xs">
          border: ring with a gap; soft: tinted ring; grow: a dot that grows and fades; svg: vector ring. All have role status and a label.
        </p>
      </.example>

      <.example title="Elastic: LineOne timing" class="mt-2 block">
        <div class="flex flex-wrap items-end gap-x-5 gap-y-5">
          <.item label="border elastic"><.spinner color="primary" size="md" elastic /></.item>
          <.item label="soft elastic">
            <.spinner color="primary" size="md" variant="soft" elastic />
          </.item>
          <.item label="svg elastic">
            <.spinner color="primary" size="md" variant="svg" elastic />
          </.item>
        </div>
        <p class="mt-3 text-xs">
          A light jolt on every turn. Use at most one per screen. With reduced motion the turn slows down instead of stopping, so it still says working.
        </p>
      </.example>

      <.example title="Size" class="mt-2 block">
        <div class="flex flex-wrap items-end gap-x-5 gap-y-5">
          <.item :for={size <- ~w(xs sm md lg xl)} label={size}>
            <.spinner color="primary" size={size} />
          </.item>
        </div>
        <p class="mt-3 text-xs">
          xs 20, sm 28, md 40, lg 48, xl 64. The ring thickness follows: 2, 3 and 4px.
        </p>
      </.example>
    </div>

    <div class="mt-5 grid gap-5 lg:grid-cols-3">
      <.example title="Color: soft" class="mt-2 block">
        <div class="flex flex-wrap items-end gap-x-5 gap-y-5">
          <.item :for={color <- @colors} label={color}>
            <.spinner color={color} size="md" variant="soft" />
          </.item>
        </div>
        <div class="mt-5 flex flex-wrap items-center gap-5">
          <div class="inline-flex items-center gap-7 rounded-lg bg-primary px-5 py-4 dark:bg-accent">
            <.spinner color="white" size="md" />
            <.spinner color="white" size="md" variant="soft" />
            <.spinner color="white" size="md" variant="svg" />
            <code class="font-mono text-xs text-white">white</code>
          </div>
          <div class="flex items-center gap-2.5 text-error">
            <.spinner color="current" size="sm" />
            <code class="font-mono text-xs">current</code>
          </div>
        </div>
        <p class="mt-3 text-xs">
          white is for filled backgrounds; current takes the surrounding text color.
        </p>
      </.example>
    </div>

    <.example title="Inside a button: xs with white or current" class="mt-5 block" id="canvas-buttons">
      <div class="flex flex-wrap items-center gap-3">
        <.button color="primary" loading>Salvando…</.button>
        <.button color="primary" variant="outline" loading>Enviando</.button>
        <.button shape="pill" loading>Carregando</.button>
        <.button color="error" loading>Excluindo</.button>
        <.button color="primary">Salvar</.button>
      </div>
      <p class="mt-3 text-xs">
        loading keeps the button where it is and disables it while it works, to avoid a double submit; the text turns into the gerund.
      </p>
    </.example>

    <.example title="Over an area: veil with spinner and label" class="mt-5 block" id="canvas-area">
      <div
        class="relative overflow-hidden rounded-lg border border-slate-150 dark:border-navy-500"
        aria-busy="true"
      >
        <div
          :for={{name, project, value} <- @orders}
          class="grid grid-cols-[minmax(0,2fr)_minmax(0,1fr)_72px] gap-4 border-t border-slate-150 px-4 py-3 text-sm first:border-t-0 dark:border-navy-500"
        >
          <span class="text-slate-700 dark:text-navy-100">{name}</span>
          <span>{project}</span>
          <span class="text-right">{value}</span>
        </div>
        <div class="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-white/70 dark:bg-navy-700/70">
          <.spinner color="primary" size="md" />
          <p class="text-[13px] font-medium text-slate-700 dark:text-navy-100">Carregando pedidos…</p>
        </div>
      </div>
      <p class="mt-3 text-xs">
        The veil covers only the area that updates, at 70% of the surface, and the old content stays readable under it.
      </p>
    </.example>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp item(assigns) do
    ~H"""
    <div class="flex min-w-10 flex-col items-center gap-2.5">
      {render_slot(@inner_block)}
      <code class="font-mono text-xs">{@label}</code>
    </div>
    """
  end
end
