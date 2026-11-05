defmodule LineaUI.Components.Box do
  @moduledoc """
  A card: a bordered white panel with a header, a body, a footer and a table that fills it. It is plainer than
  `card/1`, the LineOne card.

      <.box>
        <.box_header>
          <.box_title>Teams</.box_title>
          <.box_toolbar><.button size="sm" variant="outline">Add</.button></.box_toolbar>
        </.box_header>
        <.box_body>…</.box_body>
        <.box_footer class="justify-center">All teams</.box_footer>
      </.box>

  Every part takes `class` and any global attribute, and is a `div` (the title an `h3`) unless it says otherwise.
  `accent` makes the muted tray of `kt-card-accent`: the header loses its line and the table sits on a white inset.
  """

  use LineaUI.Component

  @box "flex flex-col items-stretch rounded-xl border border-slate-200 bg-white text-slate-950 shadow-xs dark:border-navy-450 dark:bg-navy-900 dark:text-navy-50"
  @accent "bg-slate-100 p-1 dark:bg-navy-800 [&_.box-header]:border-b-0 [&_.box-table]:rounded-xl [&_.box-table]:bg-white dark:[&_.box-table]:bg-navy-900 [&_.box-footer]:mt-0.5 [&_.box-footer]:rounded-b-xl [&_.box-footer]:border-t-0 [&_.box-footer]:bg-white dark:[&_.box-footer]:bg-navy-900"

  @doc """
  Renders the panel.

      <.box accent>…</.box>
  """
  attr :accent, :boolean, default: false

  attr :grid, :boolean,
    default: false,
    doc:
      "The body gives up its padding and its table loses its border, for a table that touches the edges (`kt-card-grid`)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box(assigns) do
    ~H"""
    <div class={merge([box_class(), @accent && accent(), @grid && grid_class(), @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The header of a panel: the title on the left and the toolbar on the right, 56px high at least."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box_header(assigns) do
    ~H"""
    <div
      class={
        merge([
          "box-header flex min-h-14 flex-wrap items-center justify-between gap-2.5 border-b border-slate-200 px-5 dark:border-navy-450",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The title of a panel header."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box_title(assigns) do
    ~H"""
    <h3 class={merge(["text-base leading-none font-semibold tracking-tight", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc "The buttons and fields at the end of a panel header."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box_toolbar(assigns) do
    ~H"""
    <div class={merge(["flex items-center gap-2.5", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The body of a panel: it grows and keeps 20px of padding."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box_body(assigns) do
    ~H"""
    <div class={merge(["box-body grow p-5", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "The footer of a panel, under a line."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box_footer(assigns) do
    ~H"""
    <div
      class={
        merge([
          "box-footer flex items-center border-t border-slate-200 px-5 py-4 dark:border-navy-450",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A grid that fills the panel, for a table that touches its edges."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def box_table(assigns) do
    ~H"""
    <div class={merge(["box-table grid grow", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @grid "[&_.box-body]:p-0 [&_.box-body_table]:border-0 [&_.box-body_.table-plain_:is(th,td):first-child]:ps-5 [&_.box-body_.table-plain_:is(th,td):last-child]:pe-5"

  defp grid_class, do: @grid
  defp accent, do: @accent
  defp box_class, do: @box
end
