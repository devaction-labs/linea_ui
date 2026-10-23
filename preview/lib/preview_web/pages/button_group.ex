defmodule PreviewWeb.Pages.ButtonGroup do
  use PreviewWeb.Page,
    title: "Button Group",
    category: :elements,
    lineone: "elements-button-group"

  def render(assigns) do
    ~H"""
    <.example
      title="Button Group"
      text="Button groups are an easy way to group a series of buttons together. Check out code for detail of usage."
      class="mt-5 space-y-4"
    >
      <.button_group>
        <.button :for={n <- 1..5} color="primary" class={n == 3 && active("primary")}>{n}</.button>
      </.button_group>
      <.button_group shape="pill">
        <.button
          :for={label <- ~w(First Second Third)}
          color="secondary"
          class={label == "Second" && active("secondary")}
        >
          {label}
        </.button>
      </.button_group>
    </.example>

    <.example
      title="Outlined"
      text="Buttons groups can be outlied. Check out code for detail of usage."
      class="mt-5 space-y-4"
    >
      <.button_group>
        <.button :for={n <- 1..5} color="info" variant={(n == 3 && "solid") || "outline"}>
          {n}
        </.button>
      </.button_group>
      <.button_group shape="pill">
        <.button
          :for={label <- ~w(First Second Third)}
          color="warning"
          variant={(label == "Second" && "solid") || "outline"}
        >
          {label}
        </.button>
      </.button_group>
    </.example>

    <.example
      title="Soft Button Group"
      text="Buttons groups can have a soft colors. To do this, you should use some opacity. Check out code for detail of usage."
      class="mt-5 space-y-4"
    >
      <.button_group>
        <.button :for={n <- 1..5} color="success" variant={(n == 3 && "solid") || "soft"}>
          {n}
        </.button>
      </.button_group>
      <.button_group shape="pill">
        <.button
          :for={label <- ~w(First Second Third)}
          color="error"
          variant={(label == "Second" && "solid") || "soft"}
        >
          {label}
        </.button>
      </.button_group>
    </.example>
    """
  end

  defp active("primary"), do: "bg-primary-focus dark:bg-accent-focus"
  defp active("secondary"), do: "bg-secondary-focus"
end
