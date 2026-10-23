defmodule PreviewWeb.Pages.Button do
  use PreviewWeb.Page, title: "Button", category: :elements, lineone: "elements-button"

  @colors ~w(neutral primary secondary info success warning error)

  def render(assigns) do
    assigns = assign(assigns, :colors, @colors)

    ~H"""
    <.example
      title="Button"
      text="Use Button component for actions in forms, dialogs, and more with support for multiple sizes, states, and more. Check out code for detail of usage."
    >
      <.button :for={color <- @colors} color={color}>{label(color)}</.button>
    </.example>
    <.example title="Rounded Button">
      <.button :for={color <- @colors} color={color} shape="pill">{label(color)}</.button>
    </.example>
    <.example title="Outlined Button">
      <.button :for={color <- @colors} color={color} variant="outline">{label(color)}</.button>
    </.example>
    <.example title="Soft Color Button">
      <.button :for={color <- tl(@colors)} color={color} variant="soft">{label(color)}</.button>
    </.example>
    <.example title="Bordered Button">
      <.button :for={color <- tl(@colors)} color={color} variant="bordered">{label(color)}</.button>
    </.example>
    <.example title="Flat Button">
      <.button :for={color <- List.delete(@colors, "success")} color={color} variant="flat">
        {label(color)}
      </.button>
    </.example>
    <.example title="Glow buttons">
      <.button :for={color <- @colors} color={color} variant="glow">{label(color)}</.button>
    </.example>
    <.example title="Button Size">
      <.button :for={size <- ~w(xs sm md lg xl)} color="primary" size={size}>{size}</.button>
    </.example>
    <.example title="Only Icons">
      <.button :for={color <- @colors} color={color} icon shape="pill" aria-label={color}>★</.button>
    </.example>
    <.example title="Disabled Button">
      <.button :for={color <- @colors} color={color} disabled>{label(color)}</.button>
    </.example>
    """
  end

  defp label("neutral"), do: "Default"
  defp label(color), do: String.capitalize(color)
end
