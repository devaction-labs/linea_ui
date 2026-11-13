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
      <.button :for={color <- @colors} color={color}>{color_label(color)}</.button>
    </.example>
    <.example title="Rounded Button">
      <.button :for={color <- @colors} color={color} shape="pill">{color_label(color)}</.button>
    </.example>
    <.example title="Outlined Button">
      <.button :for={color <- @colors} color={color} variant="outline">{color_label(color)}</.button>
    </.example>
    <.example title="Soft Color Button">
      <.button :for={color <- tl(@colors)} color={color} variant="soft">{color_label(color)}</.button>
    </.example>
    <.example title="Bordered Button">
      <.button :for={color <- tl(@colors)} color={color} variant="bordered">{color_label(color)}</.button>
    </.example>
    <.example title="Flat Button">
      <.button :for={color <- List.delete(@colors, "success")} color={color} variant="flat">
        {color_label(color)}
      </.button>
    </.example>
    <.example title="Glow buttons">
      <.button :for={color <- @colors} color={color} variant="glow">{color_label(color)}</.button>
    </.example>
    <.example title="Button Size">
      <.button :for={size <- ~w(xs sm md lg xl)} color="primary" size={size}>{size}</.button>
    </.example>
    <.example title="Only Icons">
      <.button :for={color <- @colors} color={color} icon shape="pill" aria-label={color}>★</.button>
    </.example>
    <.example
      title="Icon Button"
      text="Square, icon only, always with aria-label. The canvas defines the bordered control, plain (flat, ghost, dim), sizes md 36, sm 32 and xs 24, the pill shape and the pip."
    >
      <.button icon aria-label="New"><.ib_icon /></.button>
      <.button icon pip aria-label="Notices"><.ib_icon /></.button>
      <.button icon variant="flat" aria-label="More"><.ib_icon /></.button>
      <.button icon size="sm" aria-label="Edit"><.ib_icon /></.button>
      <.button icon size="sm" variant="ghost" aria-label="Close"><.ib_icon /></.button>
      <.button icon size="xs" aria-label="Edit"><.ib_icon /></.button>
      <.button icon size="xs" variant="dim" aria-label="Close"><.ib_icon /></.button>
      <.button icon shape="pill" aria-label="Pill"><.ib_icon /></.button>
      <.button icon disabled aria-label="Disabled"><.ib_icon /></.button>
    </.example>
    <.example title="Disabled Button">
      <.button :for={color <- @colors} color={color} disabled>{color_label(color)}</.button>
    </.example>
    """
  end

  defp ib_icon(assigns) do
    ~H"""
    <svg
      class="i"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      aria-hidden="true"
    >
      <path d="M12 4v16M20 12H4" />
    </svg>
    """
  end

  defp color_label("neutral"), do: "Default"
  defp color_label(color), do: String.capitalize(color)
end
