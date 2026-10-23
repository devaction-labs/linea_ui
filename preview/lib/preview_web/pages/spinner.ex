defmodule PreviewWeb.Pages.Spinner do
  use PreviewWeb.Page, title: "Spinner", category: :elements, lineone: "elements-spinner"

  @colors ~w(neutral primary secondary info success warning error)
  @timing "A Timing function describes how an animation will progress, allowing it to change speed during its course. Check out code for detail of usage."

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, timing: @timing)

    ~H"""
    <.example
      title="Basic Spinner"
      text="A Spinner component is used to show the user a timely process is currently taking place. Check out code for detail of usage."
    >
      <.spinner :for={color <- @colors} color={color} />
    </.example>

    <.example title="Elastic Timing Function" text={@timing}>
      <.spinner :for={color <- @colors} color={color} elastic />
    </.example>

    <.example
      title="Soft Color Spinner"
      text="Spinner can have a soft colors. To do this, you should use some opacity. Check out code for detail of usage."
    >
      <.spinner :for={color <- @colors} color={color} variant="soft" />
    </.example>

    <.example title="Soft Elsatic Spinner" text={@timing}>
      <.spinner :for={color <- @colors} color={color} variant="soft" elastic />
    </.example>

    <.example
      title="Grow Spinner"
      text="If you don’t fancy a border spinner, switch to the grow spinner. Check out code for detail of usage."
    >
      <.spinner :for={color <- @colors} color={color} variant="grow" />
    </.example>

    <.example
      title="SVG Spinner"
      text="You can also use SVG shapes for spinners. Check out code for detail of usage."
    >
      <.spinner :for={color <- @colors} color={color} variant="svg" />
    </.example>

    <.example title="SVG Spinner Elastic" text={@timing}>
      <.spinner :for={color <- @colors} color={color} variant="svg" elastic />
    </.example>

    <.example
      title="Spinner Size"
      text="A Spinner component is used to show the user a timely process is currently taking place. Check out code for detail of usage."
      class="inline-space flex flex-wrap"
    >
      <div :for={variant <- ~w(border soft grow)} class="inline-space mt-5 flex flex-wrap">
        <.spinner :for={size <- ~w(xs sm md lg xl)} color="primary" variant={variant} size={size} />
      </div>
    </.example>
    """
  end
end
