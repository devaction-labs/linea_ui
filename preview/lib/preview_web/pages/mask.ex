defmodule PreviewWeb.Pages.Mask do
  use PreviewWeb.Page, title: "Mask", category: :elements, lineone: "elements-mask"

  @sections [
    {"Squircle Mask", "squircle", ~w(squircle)},
    {"Reuleaux Triangle Mask", "reuleaux triangle", ~w(reuleaux-triangle)},
    {"Diamond Mask", "diamond", ~w(diamond)},
    {"Hexagon Mask", "hexagon", ~w(hexagon hexagon-2)},
    {"Octagon Mask", "octagon", ~w(octagon)},
    {"Star Mask", "star", ~w(star star-2)},
    {"Heart Mask", "heart", ~w(heart)}
  ]

  def render(assigns) do
    assigns = assign(assigns, :sections, @sections)

    ~H"""
    <.example
      :for={{title, name, shapes} <- @sections}
      title={title}
      text={"Mask crops the content of the element to common shapes. The mask can crop the shape of #{name}. Check out code for detail of usage."}
      class={(length(shapes) > 1 && "inline-space mt-4") || "mt-4"}
    >
      <.mask
        :for={shape <- shapes}
        shape={shape}
        src="/lineone/images/avatar/avatar-12.jpg"
        alt="avatar"
        class="size-36"
      />
    </.example>
    """
  end
end
