defmodule LineaUI.Components.SelectInput do
  @moduledoc """
  A bare select: a native `<select>` that keeps the `data-kt-select` attribute its script looks for, with the
  options as the content.

      <.select_input name="period" class="w-36" data-kt-select-placeholder="Select period">
        <option value="1">1 month</option>
        <option value="3">3 months</option>
      </.select_input>

  Without the script it is a plain select with the look of the other controls. Use `select/1` for a select that takes
  its options as data and draws its own list.
  """

  use LineaUI.Component

  @doc "The select; `class` sets its width and the like, the options go in the content."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(name id form disabled required multiple size autofocus)
  slot :inner_block, required: true

  def select_input(assigns) do
    ~H"""
    <select class={merge(["kt-select", @class])} data-kt-select="true" {@rest}>{render_slot(
      @inner_block
    )}</select>
    """
  end
end
