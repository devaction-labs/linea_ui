defmodule LineaUI.Components.Control do
  @moduledoc false

  import LineaUI.Component.Helpers, only: [assign_field: 1, put_default: 3]

  @spec state(String.t() | nil, list()) :: String.t() | nil
  def state(_state, [_ | _]), do: "error"
  def state(state, []), do: state

  @spec assign_control(map()) :: map()
  def assign_control(assigns) do
    assigns
    |> assign_field()
    |> put_default(:id, nil)
    |> put_default(:name, nil)
    |> put_default(:value, nil)
  end
end
