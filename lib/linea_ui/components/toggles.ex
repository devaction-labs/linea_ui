defmodule LineaUI.Components.Toggles do
  @moduledoc """
  The bare inputs of a form: a checkbox, a radio and a switch that are one `<input>` each, with no label or
  wrapper, for a form that lays the caption out itself.

      <label class="flex items-center gap-2">
        <.checkbox_input name="terms" checked />
        <span>I accept the terms</span>
      </label>
      <.radio_input name="plan" value="pro" />
      <.switch_input name="notify" size="sm" checked />

  They are drawn with the state of the browser (`:checked`, `:indeterminate`, `:disabled`), so they need no hook. For a
  checkbox, radio or switch with its caption, its color and its error message use `checkbox/1`, `radio/1` and
  `switch/1`.
  """

  use LineaUI.Component

  @fields ~w(name value checked disabled form required id autofocus tabindex)

  @doc """
  A checkbox, 18px.

      <.checkbox_input name="remember" checked />
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: @fields

  def checkbox_input(assigns) do
    ~H"""
    <input type="checkbox" class={merge(["check-input", @class])} {@rest} />
    """
  end

  @doc """
  A radio, 20px (`size="sm"` 18px).

      <.radio_input name="plan" value="starter" />
  """
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :class, :any, default: nil
  attr :rest, :global, include: @fields

  def radio_input(assigns) do
    ~H"""
    <input
      type="radio"
      class={merge(["radio-input", @size == "sm" && "radio-input-sm", @class])}
      {@rest}
    />
    """
  end

  @doc """
  A switch, 26x18, 30x20 or 34x22 by `size`.

      <.switch_input name="alerts" size="lg" />
  """
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :class, :any, default: nil
  attr :rest, :global, include: @fields

  def switch_input(assigns) do
    ~H"""
    <input
      type="checkbox"
      role="switch"
      class={merge(["switch-input", size_class(@size), @class])}
      {@rest}
    />
    """
  end

  defp size_class("sm"), do: "switch-input-sm"
  defp size_class("lg"), do: "switch-input-lg"
  defp size_class(_size), do: nil
end
