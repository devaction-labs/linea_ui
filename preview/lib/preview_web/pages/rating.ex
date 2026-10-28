defmodule PreviewWeb.Pages.Rating do
  use PreviewWeb.Page, title: "Rating", category: :components

  def mount(socket), do: assign(socket, grade: 4, form: to_form(%{"grade" => "3"}, as: :review))

  def handle_event("rate", %{"value" => value}, socket),
    do: {:noreply, assign(socket, grade: String.to_integer(value))}

  def handle_event("validate", %{"review" => review}, socket),
    do: {:noreply, assign(socket, form: to_form(review, as: :review))}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.example title="Read only" text="A fractional value fills the last star by proportion; show_value and count add the figures." class="mt-5">
      <div class="flex flex-col gap-4">
        <.rating value={4.5} />
        <.rating value={4.2} show_value count={38} />
        <.rating value={0} count={0} />
      </div>
    </.example>

    <.example title="Sizes" text="sm, md (default) and lg." class="mt-5">
      <div class="flex flex-col gap-4">
        <.rating value={4} size="sm" show_value />
        <.rating value={4} show_value />
        <.rating value={4} size="lg" show_value />
      </div>
    </.example>

    <.example title="Interactive" text="Native radios: Tab enters the group, the arrow keys choose, hover previews." class="mt-5">
      <.rating id="service" name="service" label="Como foi o atendimento?" size="lg" value={@grade} on_change="rate" />
      <p class="mt-3 text-xs-plus text-slate-500 dark:text-navy-200">Nota atual: {@grade} de 5</p>
    </.example>

    <.example title="Inside a form" text="field={@form[:grade]} submits through the radios and phx-change runs." class="mt-5">
      <.form for={@form} phx-change="validate">
        <.rating field={@form[:grade]} label="Nota" />
      </.form>
    </.example>

    <.example title="Disabled" class="mt-5">
      <.rating value={3} disabled show_value />
      <.rating id="off" name="off" value={2} disabled class="mt-3" />
    </.example>

    <.example title="Distribution" text="The average, the stars, the total and a bar per grade." class="mt-5">
      <.rating_distribution counts={[796, 308, 116, 38, 26]} class="max-w-xl" />
    </.example>
    """
  end
end
