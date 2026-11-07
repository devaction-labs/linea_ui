defmodule LineaUI.Components.DescriptionList do
  @moduledoc """
  Label and value pairs in a grid, as the canvas `sg-dl`: the label small and faint, the value in
  the ink color. For the short data of a detail (an order, a client).

      <.description_list cols={2}>
        <:item label="Razão social">Mercadinho Bom Preço Ltda</:item>
        <:item label="CNPJ" mono>12.345.678/0001-90</:item>
      </.description_list>

  `cols` is 1 to 4. `layout="inline"` puts the label at the left and the value at the right, one
  pair per line, for a narrow drawer. An item with no content shows "—" (`empty`).
  """

  use LineaUI.Component

  attr(:cols, :integer, default: 2, values: [1, 2, 3, 4])

  attr(:layout, :string,
    default: "stacked",
    values: ~w(stacked inline),
    doc: "`stacked` puts the value under the label; `inline` the label left and the value right."
  )

  attr(:empty, :string, default: "—", doc: "Shown for an item with no content.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :item, required: true, doc: "A pair: `label`, and the value as content." do
    attr(:label, :string, required: true)
    attr(:mono, :boolean, doc: "The value in the mono font (keys, documents).")
  end

  def description_list(assigns) do
    ~H"""
    <dl
      class={merge(["sg-dl linea-dl", @class])}
      data-layout={@layout}
      style={"grid-template-columns: repeat(#{@cols}, minmax(0, 1fr))"}
      {@rest}
    >
      <div :for={item <- @item}>
        <dt>{item.label}</dt>
        <dd :if={item.inner_block} class={item[:mono] && "font-mono"}>{render_slot(item)}</dd>
        <dd :if={!item.inner_block}>{@empty}</dd>
      </div>
    </dl>
    """
  end
end
