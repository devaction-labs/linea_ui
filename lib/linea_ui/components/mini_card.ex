defmodule LineaUI.Components.MiniCard do
  @moduledoc """
  The canvas's mini card: a small card (14px padding) for a shortcut, an icon box over a bold label, or for a
  short figure, a faint label over a mono value.

      <div class="grid grid-cols-3 gap-2.5">
        <.mini_card icon="huge-invoice-01" tone="accent" label="Novo pedido" navigate={~p"/pedidos/novo"} />
        <.mini_card icon="huge-file-01" label="Emitir NF-e" />
      </div>

      <.mini_card label="A receber" value="R$ 41,2 mil" />

  With `href`, `navigate` or `patch` the card is a link.
  """

  use LineaUI.Component

  attr(:label, :string, required: true)

  attr(:value, :string,
    default: nil,
    doc: "A short figure: the label turns into a faint caption over it."
  )

  attr(:icon, :string, default: nil, doc: "A Hugeicons name, drawn in the canvas icon box.")

  attr(:tone, :string,
    default: "neutral",
    values: ~w(neutral accent success warning error info),
    doc: "The colour of the icon box."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(href navigate patch method))
  slot(:inner_block, doc: "Extra content under the label.")

  def mini_card(%{rest: rest} = assigns)
      when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link class={classes(@value, @class)} {@rest}>
      <.icon_box :if={@icon && !@value} icon={@icon} tone={@tone} />
      <span :if={@value} class="sg-mini-l">{@label}</span>
      <b class={if @value, do: "sg-mini-n", else: "sg-mini-t"}>{@value || @label}</b>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def mini_card(assigns) do
    ~H"""
    <div class={classes(@value, @class)} {@rest}>
      <.icon_box :if={@icon && !@value} icon={@icon} tone={@tone} />
      <span :if={@value} class="sg-mini-l">{@label}</span>
      <b class={if @value, do: "sg-mini-n", else: "sg-mini-t"}>{@value || @label}</b>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp classes(value, class), do: merge(["sg-card sg-mini", value && "sg-mini-v", class])

  defp icon_box(assigns) do
    ~H"""
    <LineaUI.Components.Icon.icon name={@icon} tone={@tone} boxed />
    """
  end
end
