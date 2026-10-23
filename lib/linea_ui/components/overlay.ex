defmodule LineaUI.Components.Overlay do
  @moduledoc """
  What the overlays share: the `on_open` / `on_close` callbacks, which take an event name or a `%JS{}`,
  and LineOne's close glyph.
  """

  use LineaUI.Component

  @doc """
  The `%JS{}` an overlay runs when it opens or closes. An event name becomes `JS.push/2` with
  `%{"id" => id}` as its value, sent to `target` when one is given.
  """
  @spec callback(nil | String.t() | JS.t(), String.t(), term()) :: JS.t()
  def callback(nil, _id, _target), do: %JS{}
  def callback(%JS{} = js, _id, _target), do: js

  def callback(event, id, target) when is_binary(event),
    do: JS.push(event, [value: %{id: id}] ++ target_opt(target))

  defp target_opt(nil), do: []
  defp target_opt(target), do: [target: target]

  @doc "LineOne's close icon (an ×), sized by `class`."
  attr :class, :any, default: "size-4.5"

  def close_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
    </svg>
    """
  end

  @doc "The chevron LineOne's dropdown buttons draw, turning over while the menu is open."
  attr :class, :any, default: nil

  def chevron_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={
        merge([
          "size-4 transition-transform duration-200 [[aria-expanded=true]>&]:rotate-180",
          @class
        ])
      }
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
    </svg>
    """
  end
end
