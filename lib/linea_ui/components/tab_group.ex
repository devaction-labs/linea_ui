defmodule LineaUI.Components.TabGroup do
  @moduledoc """
  The container of Metronic's tabs: it carries `data-kt-tabs`, which the script of Metronic looks for, and holds the
  buttons that have `data-kt-tab-toggle="#panel"` (use `button/1` with those attributes).

      <.tab_group class="flex gap-2">
        <.button size="sm" variant="ghost" data-kt-tab-toggle="#year_2024" class="active">2024</.button>
        <.button size="sm" variant="ghost" data-kt-tab-toggle="#year_2023">2023</.button>
      </.tab_group>

  Use `tabs/1` for tabs that switch their own panels.
  """

  use LineaUI.Component

  @doc "The wrapper of the toggles; `class` lays them out."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tab_group(assigns) do
    ~H"""
    <div class={merge([@class])} data-kt-tabs="true" {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
