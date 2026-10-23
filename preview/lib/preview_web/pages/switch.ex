defmodule PreviewWeb.Pages.Switch do
  use PreviewWeb.Page, title: "Switch", category: :forms, lineone: "forms-switch"

  @colors ~w(neutral primary secondary info success warning error)
  @grid "mt-5 grid max-w-2xl grid-cols-2 place-items-start gap-6 sm:grid-cols-3"

  @sections [
    {"Basic Switch",
     "The Switch component is used as an alternative for the checkbox. The option that the switch controls, as well as the state it's in, should be made clear from the corresponding inline label. Check out code for detail of usage.",
     %{variant: "basic", filled: false, shape: "pill"}},
    {"Squircle Switch",
     "The Switch component can have a squircle shape. Check out code for detail of usage.55",
     %{variant: "basic", filled: false, shape: "squircle"}},
    {"Outline Switch",
     "The Switch can be outlied. Check out code for detail of usage. Check out code for detail of usage.",
     %{variant: "outline", filled: false, shape: "pill"}},
    {"Outline Filled", "The Switch component can be filled. Check out code for detail of usage.",
     %{variant: "outline", filled: true, shape: "pill"}},
    {"Outline Squircle",
     "The outline Switch component can have a squircle shape. Check out code for detail of usage.",
     %{variant: "outline", filled: false, shape: "squircle"}}
  ]

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, grid: @grid, sections: @sections)

    ~H"""
    <.example
      :for={{{title, text, style}, index} <- Enum.with_index(@sections)}
      title={title}
      text={text}
      class={@grid}
    >
      <.switch
        :for={color <- @colors}
        id={"sw-#{index}-#{color}"}
        name={"sw-#{index}-#{color}"}
        label={label_for(color)}
        color={color}
        variant={style.variant}
        filled={style.filled}
        shape={style.shape}
      />
    </.example>
    <.example
      title="Disabled Switch"
      text="The Switch have their own style when disabled. Check out code for detail of usage."
      class={@grid}
    >
      <.switch name="disabled-off" label="Default" disabled />
      <.switch name="disabled-on" label="Primary" color="primary" disabled checked />
    </.example>
    <.example
      title="Switch Size"
      text="The Switch component can have various sizes. Check out code for detail of usage."
      class={@grid}
    >
      <.switch name="small" label="Small" color="primary" size="sm" />
      <.switch name="normal" label="Normal" color="primary" />
      <.switch name="large" label="Large" color="primary" size="lg" />
    </.example>
    <.example
      title="Thumb Size"
      text="The Switch component can have various thumb sizes. Check out code for detail of usage."
      class={@grid}
    >
      <.switch
        :for={inset <- [6, 5, 4, 3, 2]}
        name={"thumb-#{inset}"}
        label="label"
        color="primary"
        thumb_inset={inset}
        checked
      />
    </.example>
    """
  end

  defp label_for("neutral"), do: "Default"
  defp label_for(color), do: String.capitalize(color)
end
