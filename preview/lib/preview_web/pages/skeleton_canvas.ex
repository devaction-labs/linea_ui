defmodule PreviewWeb.Pages.SkeletonCanvas do
  use PreviewWeb.Page, title: "Skeleton (canvas)", category: :components

  @rows [
    {"62%", "38%"},
    {"48%", "30%"},
    {"70%", "42%"},
    {"55%", "34%"},
    {"40%", "26%"}
  ]

  @people [{12, "48%", "30%"}, {10, "56%", "36%"}, {8, "40%", nil}]

  def render(assigns) do
    assigns = assign(assigns, rows: @rows, people: @people)

    ~H"""
    <div class="grid gap-5 md:grid-cols-3">
      <.example title="Text" class="mt-2 block">
        <.skeleton_group label="Loading content" class="flex flex-col gap-2.5">
          <.skeleton class="h-4 w-[42%]" />
          <.skeleton class="h-3 w-full" />
          <.skeleton class="h-3 w-[92%]" />
          <.skeleton class="h-3 w-[96%]" />
          <.skeleton class="h-3 w-[58%]" />
        </.skeleton_group>
        <p class="mt-3 text-xs">Lines of 12px, the last one shorter. The title is 16px.</p>
      </.example>

      <.example title="Avatar and text" class="mt-2 block">
        <.skeleton_group label="Loading people" class="flex flex-col gap-5">
          <div :for={{size, w1, w2} <- @people} class="flex items-center gap-3.5">
            <.skeleton
              shape="circle"
              class="shrink-0"
              style={"width: #{size * 4}px; height: #{size * 4}px"}
            />
            <div class="flex min-w-0 flex-1 flex-col gap-2.5">
              <.skeleton class="h-3" style={"width: #{w1}"} />
              <.skeleton :if={w2} class="h-2.5" style={"width: #{w2}"} />
            </div>
          </div>
        </.skeleton_group>
        <p class="mt-3 text-xs">shape circle for the avatar, the same size as the real one.</p>
      </.example>

      <.example title="Card" class="mt-2 block">
        <.skeleton_group label="Loading card" class="flex flex-col gap-3.5">
          <.skeleton shape="lg" class="h-[132px] w-full" />
          <div class="flex flex-col gap-2.5">
            <.skeleton class="h-4 w-[64%]" />
            <.skeleton class="h-3 w-full" />
            <.skeleton class="h-3 w-[80%]" />
          </div>
          <div class="flex items-center gap-2.5">
            <.skeleton shape="pill" class="h-[30px] w-[84px]" />
            <.skeleton shape="pill" class="h-[30px] w-16" />
          </div>
        </.skeleton_group>
      </.example>
    </div>

    <.example title="Table rows" class="mt-2 block" id="canvas-table">
      <.skeleton_group label="Loading orders">
        <.table id="skeleton-table" rows={@rows} variant="hoverable" rounded="row">
          <:col :let={_row} label="" class="w-6"><.skeleton class="size-[18px]" /></:col>
          <:col :let={{a, b}} label="Customer" class="w-[40%]">
            <div class="flex flex-col gap-1.5">
              <.skeleton class="h-[11px]" style={"width: #{a}"} />
              <.skeleton class="h-[9px] opacity-70" style={"width: #{b}"} />
            </div>
          </:col>
          <:col :let={_row} label="Project" class="w-[25%]"><.skeleton class="h-[11px] w-[72%]" /></:col>
          <:col :let={_row} label="Status" class="w-28"><.skeleton shape="pill" class="h-5 w-[54px]" /></:col>
          <:col :let={_row} label="Value" align="right" class="w-28">
            <.skeleton class="ml-auto h-[11px] w-[72px]" />
          </:col>
        </.table>
      </.skeleton_group>
      <p class="mt-3 text-xs">Same columns as the real table: nothing jumps when the data arrives.</p>
    </.example>

    <.example title="Animation and shape" class="mt-2 block" id="canvas-shapes">
      <div class="grid grid-cols-2 items-end gap-x-4 gap-y-4 sm:grid-cols-4 lg:grid-cols-6">
        <.shape_cell label="wave (default)"><.skeleton class="h-9 w-full" /></.shape_cell>
        <.shape_cell label="pulse"><.skeleton animation="pulse" class="h-9 w-full" /></.shape_cell>
        <.shape_cell label="none"><.skeleton animation="none" class="h-9 w-full" /></.shape_cell>
        <.shape_cell label="rounded"><.skeleton class="h-9 w-full" /></.shape_cell>
        <.shape_cell label="pill"><.skeleton shape="pill" class="h-9 w-full" /></.shape_cell>
        <.shape_cell label="circle"><.skeleton shape="circle" class="size-9" /></.shape_cell>
        <.shape_cell label="square"><.skeleton shape="square" class="h-9 w-full" /></.shape_cell>
        <.shape_cell label="lg"><.skeleton shape="lg" class="h-9 w-full" /></.shape_cell>
      </div>
      <.skeleton_group label="Loading" class="mt-5 flex max-w-sm animate-pulse items-center gap-3">
        <.skeleton animation="none" shape="circle" class="size-9 shrink-0" />
        <div class="flex flex-1 flex-col gap-2.5">
          <.skeleton animation="none" class="h-3 w-[60%]" />
          <.skeleton animation="none" class="h-3 w-[90%]" />
        </div>
      </.skeleton_group>
      <p class="mt-3 text-xs">
        Group pulse: blocks with animation none inside an element with animate-pulse, as in LineOne.
      </p>
    </.example>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp shape_cell(assigns) do
    ~H"""
    <div class="flex flex-col items-start gap-2">
      {render_slot(@inner_block)}
      <code class="font-mono text-xs">{@label}</code>
    </div>
    """
  end
end
