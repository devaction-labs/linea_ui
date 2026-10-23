defmodule LineaUI.Components.Pickers do
  @moduledoc false

  use LineaUI.Component

  alias LineaUI.Components.Form

  @doc false
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :for, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def field(%{label: nil, help: nil, errors: []} = assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def field(assigns) do
    ~H"""
    <label class={merge(["block", @class])} for={@for}>
      <span :if={@label}>{@label}</span>
      {render_slot(@inner_block)}
      <Form.help_text :if={@help} class="mt-1 block">{@help}</Form.help_text>
      <Form.error :for={message <- @errors} class="mt-1">{message}</Form.error>
    </label>
    """
  end

  @doc false
  @spec json(term()) :: String.t()
  def json(value), do: Phoenix.json_library().encode!(value)

  @doc false
  @spec forwarded(map()) :: map()
  def forwarded(rest), do: Map.take(rest, [:"phx-debounce", :"phx-throttle"])
end
