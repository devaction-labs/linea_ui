defmodule LineaUI.Components.Stat do
  @moduledoc """
  daisyUI's stats (`stats`, `stat`, `stat-title`, `stat-value`): short figures side by side, each with a faint
  label over it and a divider between them, in one card.

      <.stat_group>
        <.stat_item label="Subtotal" value="R$ 3.240" />
        <.stat_item label="Desconto" value="− R$ 120" />
        <.stat_item label="Total" value="R$ 3.120" tone="accent" />
      </.stat_group>

  `unit` is a smaller suffix beside the figure (`un`, `dias`, `%`). A `stat_item/1` also works on its own, inside any
  flex row; `stat_group card={false}` drops the card frame.
  """

  use LineaUI.Component

  @doc """
  One figure with its label.

      <.stat_item label="Estoque" value="1.284" unit="un" />
  """
  attr(:label, :string, required: true)
  attr(:value, :string, required: true, doc: "The figure, already formatted.")
  attr(:unit, :string, default: nil, doc: "A smaller faint suffix beside the figure.")

  attr(:tone, :string,
    default: "default",
    values: ~w(default accent),
    doc: "`accent` paints the figure in the accent (the total of a strip)."
  )

  attr(:size, :string,
    default: "default",
    values: ~w(default sm),
    doc: "`sm` sets the figure at 18px (a word such as `Boleto`)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def stat_item(assigns) do
    ~H"""
    <div class={merge(["stat px-5 py-3", @class])} {@rest}>
      <span class="stat-title">{@label}</span>
      <span class={[
        "stat-value font-semibold",
        (@size == "sm" && "text-lg") || "text-2xl",
        @tone == "accent" && "text-primary"
      ]}>
        {@value}<small :if={@unit} class="ml-1 text-sm font-normal text-base-content/60">{@unit}</small>
      </span>
    </div>
    """
  end

  @doc """
  A row of `stat_item/1`: daisyUI's `stats` in a card, the figures side by side.
  """
  attr(:card, :boolean, default: true, doc: "Draws the card around the row.")

  attr(:variant, :string,
    default: "default",
    values: ~w(default sunken),
    doc: "`sunken` fills the row with the grey sunken background."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def stat_group(assigns) do
    ~H"""
    <div
      class={
        merge([
          "stats",
          @card && "border border-base-300 bg-base-100",
          @variant == "sunken" && "border-transparent bg-base-200",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
