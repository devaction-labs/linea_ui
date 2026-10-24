defmodule LineaUI.Components.Overlay do
  @moduledoc """
  What the overlays share: the `on_open` / `on_close` callbacks, which take an event name or a `%JS{}`,
  and the close glyph.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

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
    <.glyph name={:close} class={@class} />
    """
  end

  @doc "The chevron LineOne's dropdown buttons draw, turning over while the menu is open."
  attr :class, :any, default: nil

  def chevron_icon(assigns) do
    ~H"""
    <.glyph
      name={:chevron_down}
      class={
        merge([
          "size-4 transition-transform duration-200 [[aria-expanded=true]>&]:rotate-180",
          @class
        ])
      }
    />
    """
  end
end
