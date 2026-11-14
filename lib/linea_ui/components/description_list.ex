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

  An item takes `id`, `class` and `style` for its `<dd>` (a test hook, a long e-mail that must
  wrap), and `wrapper_id` and `wrapper_class` for the `<div>` around the pair:

      <.description_list cols={1}>
        <:item label="E-mail" id="mail" style="overflow-wrap:anywhere">ana@example.com</:item>
      </.description_list>
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
    attr(:id, :string, doc: "The `id` of the `<dd>`.")
    attr(:class, :any, doc: "Classes of the `<dd>`, after `font-mono`.")
    attr(:style, :string, doc: "The `style` of the `<dd>`.")
    attr(:wrapper_id, :string, doc: "The `id` of the `<div>` around the label and the value.")
    attr(:wrapper_class, :any, doc: "Classes of the `<div>` around the label and the value.")
  end

  def description_list(assigns) do
    ~H"""
    <dl
      class={merge(["sg-dl linea-dl", @class])}
      data-layout={@layout}
      style={"grid-template-columns: repeat(#{@cols}, minmax(0, 1fr))"}
      {@rest}
    >
      <div :for={item <- @item} {wrapper_attrs(item)}>
        <dt>{item.label}</dt>
        <dd :if={item.inner_block} class={dd_class(item)} {dd_attrs(item)}>{render_slot(item)}</dd>
        <dd :if={!item.inner_block} class={item[:class]} {dd_attrs(item)}>{@empty}</dd>
      </div>
    </dl>
    """
  end

  defp wrapper_attrs(item), do: present(id: item[:wrapper_id], class: item[:wrapper_class])
  defp dd_attrs(item), do: present(id: item[:id], style: item[:style])
  defp present(attrs), do: Enum.reject(attrs, &is_nil(elem(&1, 1)))

  defp dd_class(%{mono: true, class: class}) when not is_nil(class),
    do: merge(["font-mono", class])

  defp dd_class(%{mono: true}), do: "font-mono"
  defp dd_class(item), do: item[:class]
end
