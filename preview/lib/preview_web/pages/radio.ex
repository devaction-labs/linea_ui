defmodule PreviewWeb.Pages.Radio do
  use PreviewWeb.Page, title: "Radio", category: :forms, lineone: "forms-radio"

  @colors ~w(neutral primary secondary info success warning error)
  @grid "grid grid-cols-2 place-items-start gap-6 sm:grid-cols-3"

  @sections [
    {"Basic Radio",
     "Radio are generally used in radio groups collections of radio buttons describing a set of related options. Check out code for detail of usage.",
     %{name: "basic", variant: "basic", filled: false, shape: "circle"}},
    {"Filled Radio", "The radio component can be filled. Check out code for detail of usage.",
     %{name: "basic_filled", variant: "basic", filled: true, shape: "circle"}},
    {"Outline Radio", "The radio component can be outtlined. Check out code for detail of usage.",
     %{name: "outline", variant: "outline", filled: false, shape: "circle"}},
    {"Outline Filled",
     "The radio component can be outlined and filled. Check out code for detail of usage.",
     %{name: "outline_filled", variant: "outline", filled: true, shape: "circle"}},
    {"Outline Squircle",
     "The radio component can have a squircle shape. Check out code for detail of usage",
     %{name: "outline_squircle", variant: "outline", filled: false, shape: "squircle"}}
  ]

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, grid: @grid, sections: @sections)

    ~H"""
    <.example
      :for={{title, text, style} <- @sections}
      title={title}
      text={text}
      class="mt-5 max-w-2xl"
    >
      <.radio_group
        id={style.name}
        name={style.name}
        value="neutral"
        variant={style.variant}
        filled={style.filled}
        shape={style.shape}
        class={@grid}
      >
        <:radio :for={color <- @colors} value={color} color={color}>{label_for(color)}</:radio>
      </.radio_group>
    </.example>
    <.example
      title="Disabled Radio"
      text="The radio have their own style when disabled. Check out code for detail of usage."
      class="mt-5 max-w-2xl"
    >
      <.radio_group id="disabled" name="disabled" value="on" color="primary" disabled class={@grid}>
        <:radio value="off">Primary</:radio>
        <:radio value="on">Primary</:radio>
      </.radio_group>
    </.example>
    <.example
      title="Radio Error"
      text="Errors paint the unchecked radios with the error border and show the message below."
      class="mt-5 max-w-2xl"
    >
      <.radio_group
        id="terms"
        name="terms"
        color="primary"
        errors={["Choose an option to continue."]}
        class={@grid}
      >
        <:radio value="yes">I agree</:radio>
        <:radio value="no">I do not agree</:radio>
      </.radio_group>
    </.example>
    <.example
      title="Radio Size"
      text="The radio component can have various sizes. Check out code for detail of usage."
      class="mt-5 max-w-2xl"
    >
      <.radio_group
        id="size"
        name="size"
        value="1"
        color="primary"
        class="inline-space flex flex-wrap items-center"
      >
        <:radio value="1" class="size-3">1</:radio>
        <:radio value="2" class="size-3.5">2</:radio>
        <:radio value="3" class="size-4">3</:radio>
        <:radio value="4" class="size-4.5">4</:radio>
        <:radio value="5">5</:radio>
        <:radio value="6" class="size-6">6</:radio>
      </.radio_group>
    </.example>
    """
  end

  defp label_for("neutral"), do: "Default"
  defp label_for(color), do: String.capitalize(color)
end
