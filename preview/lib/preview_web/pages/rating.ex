defmodule PreviewWeb.Pages.Rating do
  use PreviewWeb.Page, title: "Rating", category: :elements

  def mount(socket), do: assign(socket, form: to_form(%{"score" => "3"}, as: :review), saved: nil)

  def handle_event("validate", %{"review" => %{"score" => score}}, socket),
    do: {:noreply, assign(socket, form: to_form(%{"score" => score}, as: :review), saved: score)}

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.example
      title="Read-only"
      text="The score as stars, with the number of ratings. The last star is filled by the fraction."
      class="mt-5 space-y-3"
    >
      <div><.rating value={4.5} count={1284} /></div>
      <div><.rating value={3.25} /></div>
      <div><.rating value={5} count={12} /></div>
      <div><.rating value={0} /></div>
    </.example>

    <.example title="Sizes" class="mt-5 space-y-3">
      <div :for={size <- ~w(sm md lg)}><.rating value={4} size={size} count={87} /></div>
    </.example>

    <.example
      title="Interactive"
      text="A group of native radios: the arrow keys move between stars, hovering previews a score and the chosen star stays filled. The form's phx-change receives the score."
      class="mt-5"
    >
      <.form for={@form} phx-change="validate" class="space-y-2">
        <.rating field={@form[:score]} readonly={false} label="How was the service?" size="lg" />
        <p class="text-sm text-slate-500 dark:text-navy-300">Chosen: {@saved || "3 (initial)"}</p>
      </.form>
    </.example>

    <.example title="Disabled" class="mt-5">
      <.rating name="locked" value={2} readonly={false} disabled label="Closed for ratings" />
    </.example>
    """
  end
end
