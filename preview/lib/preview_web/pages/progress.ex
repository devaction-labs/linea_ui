defmodule PreviewWeb.Pages.Progress do
  use PreviewWeb.Page, title: "Progress", category: :elements, lineone: "elements-progress"

  @colors ~w(neutral primary secondary info success warning error)

  def render(assigns) do
    assigns = assign(assigns, colors: Enum.with_index(@colors, 4))

    ~H"""
    <.example
      title="Basic Progress"
      text="The Progress component displays a colored loading bar. Check out code for detail of usage."
      class="mt-5 max-w-2xl space-y-4"
    >
      <.progress :for={{color, twelfths} <- @colors} color={color} value={twelfths} max={12} />
    </.example>

    <.example
      title="Soft Color Progress"
      text="Progress can have a soft colors. To do this, you should use some opacity. Check out code for detail of usage."
      class="mt-5 max-w-2xl space-y-4"
    >
      <.progress
        :for={{color, twelfths} <- tl(@colors)}
        color={color}
        variant="soft"
        value={twelfths}
        max={12}
      />
    </.example>

    <.example
      title="Progress Size"
      text="The Progress components can have various sizes. Check out code for detail of usage."
      class="mt-5 max-w-2xl space-y-4"
    >
      <.progress :for={size <- ~w(sm md lg xl)} color="primary" size={size} value={5} max={12} />
    </.example>

    <.example
      title="Active Progress"
      text="An indicating progress bar visually indicates the current level of progress of a task. Check out code for detail of usage."
      class="mt-5 max-w-2xl space-y-4"
    >
      <.progress :for={{color, twelfths} <- @colors} color={color} value={twelfths} max={12} active />
    </.example>

    <.example
      title="Progress Indeterminate"
      text="You can use indeterminate mode for the progress bar when you do not know how long an operation will take. Check out code for detail of usage."
      class="mt-5 max-w-2xl space-y-4"
    >
      <.progress :for={{color, _} <- @colors} color={color} size="sm" indeterminate />
    </.example>
    """
  end
end
