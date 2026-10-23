defmodule PreviewWeb.Pages.Card do
  use PreviewWeb.Page, title: "Card", category: :elements, lineone: "elements-card"

  @lorem "Lorem ipsum dolor sit, amet consectetur adipisicing elit. Aut laboriosam praesentium adipisci iure doloribus accusamus animi quos."

  def render(assigns) do
    assigns = assign(assigns, :lorem, @lorem)

    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:gap-5 lg:grid-cols-3 lg:gap-6">
      <.card>
        <:title>Simple Card</:title>
        <p>{@lorem}</p>
      </.card>
      <.card shape="xl">
        <:title>Rounded Card</:title>
        <p>{@lorem}</p>
      </.card>
      <.card variant="bordered">
        <:title>Bordered Card</:title>
        <p>{@lorem}</p>
      </.card>
      <.card
        :for={color <- ~w(primary secondary info success warning error)}
        variant="solid"
        color={color}
      >
        <:title>{String.capitalize(color)} Card</:title>
        <p>{@lorem}</p>
      </.card>
      <.card :for={color <- ~w(primary warning info)} variant="glow" color={color}>
        <:title>Glow Card</:title>
        <p>{@lorem}</p>
      </.card>
      <.card
        :for={gradient <- ~w(purple-indigo fuchsia-pink amber-orange)}
        variant="gradient"
        gradient={gradient}
      >
        <:title>Gradient Card</:title>
        <p>{@lorem}</p>
      </.card>
      <.card variant="gradient_outline" gradient="sky-blue">
        <:title class="text-slate-600">Outlined Gradient</:title>
        <p>{@lorem}</p>
      </.card>
      <.card
        :for={gradient <- ~w(green-fuchsia amber-orange)}
        variant="gradient_outline"
        gradient={gradient}
      >
        <:title>Outlined Gradient</:title>
        <p>{@lorem}</p>
      </.card>
    </div>
    """
  end
end
