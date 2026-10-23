defmodule PreviewWeb.Pages.Checkbox do
  use PreviewWeb.Page, title: "Checkbox", category: :forms, lineone: "forms-checkbox"

  @colors ~w(neutral primary secondary info success warning error)
  @grid "mt-5 grid max-w-2xl grid-cols-2 place-items-start gap-6 sm:grid-cols-3"

  @sections [
    {"Basic Checkbox",
     "Checkboxes are for selecting one or several options in a list, while radios are for selecting one option from many Check out code for detail of usage.",
     %{variant: "basic", filled: false, shape: "square"}},
    {"Filled Checkbox",
     "The checkbox component can be filled. Check out code for detail of usage.",
     %{variant: "basic", filled: true, shape: "square"}},
    {"Circle Checkbox",
     "The checkbox component can have a circle shape. Check out code for detail of usage",
     %{variant: "basic", filled: false, shape: "circle"}},
    {"Outline Checkbox",
     "The checkbox component can be outtlined. Check out code for detail of usage.",
     %{variant: "outline", filled: false, shape: "square"}},
    {"Outline Filled",
     "The checkbox component can be outlined and filled. Check out code for detail of usage.",
     %{variant: "outline", filled: true, shape: "square"}},
    {"Outline Circle",
     "The checkbox component can have a circle shape. Check out code for detail of usage.",
     %{variant: "outline", filled: false, shape: "circle"}}
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
      <.checkbox
        :for={color <- @colors}
        id={"cb-#{index}-#{color}"}
        name={"cb-#{index}-#{color}"}
        label={label_for(color)}
        color={color}
        variant={style.variant}
        filled={style.filled}
        shape={style.shape}
        checked={color == "neutral"}
        class={index == 0 and color == "secondary" and "size-4.5"}
      />
    </.example>
    <.example
      title="Disabled Checkbox"
      text="The checkbox have their own style when disabled. Check out code for detail of usage."
      class={@grid}
    >
      <.checkbox name="disabled-off" label="Unchecked" color="primary" disabled />
      <.checkbox name="disabled-on" label="Checked" color="primary" disabled checked />
    </.example>
    <.example
      title="Checkbox Size"
      text="The checkbox component can have various sizes. Check out code for detail of usage."
      class="inline-space mt-5 flex max-w-2xl flex-wrap items-center"
    >
      <.checkbox name="size-1" label="1" color="primary" size="xs" checked />
      <.checkbox name="size-2" label="2" color="primary" class="size-3.5" />
      <.checkbox name="size-3" label="3" color="primary" size="sm" />
      <.checkbox name="size-4" label="4" color="primary" />
      <.checkbox name="size-5" label="5" color="primary" />
      <.checkbox name="size-6" label="6" color="primary" size="lg" />
    </.example>
    """
  end

  defp label_for("neutral"), do: "Default"
  defp label_for(color), do: String.capitalize(color)
end
