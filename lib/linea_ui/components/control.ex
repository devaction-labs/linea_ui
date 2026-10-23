defmodule LineaUI.Components.Control do
  @moduledoc false

  import Phoenix.Component, only: [assign_new: 3]
  import LineaUI.Component.Helpers, only: [assign_field: 1]

  @spec state(String.t() | nil, list()) :: String.t() | nil
  def state(_state, [_ | _]), do: "error"
  def state(state, []), do: state

  @spec assign_control(map()) :: map()
  def assign_control(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:id, fn -> nil end)
    |> assign_new(:name, fn -> nil end)
    |> assign_new(:value, fn -> nil end)
  end
end
