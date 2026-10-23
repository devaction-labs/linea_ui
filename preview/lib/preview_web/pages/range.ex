defmodule PreviewWeb.Pages.Range do
  use PreviewWeb.Page, title: "Range", category: :forms, lineone: "forms-range"

  def mount(socket), do: assign(socket, volume: 50)

  def handle_event("volume", %{"volume" => volume}, socket) do
    {:noreply, assign(socket, volume: volume)}
  end

  def render(assigns) do
    ~H"""
    <.example
      title="Basic Input Range"
      text="Use our custom range inputs for consistent cross-browser styling and built-in customization. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.range name="basic" />
    </.example>
    <.example
      title="Colored Input Range"
      text="Input Range Thumb can have different colors. Check out code for detail of usage."
      class="mt-5 max-w-xl space-y-6"
    >
      <.range
        :for={color <- ~w(primary secondary info success warning error)}
        name={"color-#{color}"}
        value={50}
        color={color}
      />
    </.example>
    <.example
      title="Input Range Size"
      text="Input Ranges can have various sizes. Check out code for detail of usage."
      class="mt-5 max-w-xl space-y-6"
    >
      <.range :for={size <- ~w(sm md lg)} name={"size-#{size}"} size={size} />
    </.example>
    <.example
      id="live-range"
      title="Live Range"
      text="A range inside a form sends its value on every change."
      class="mt-5 max-w-xl"
    >
      <form id="volume-form" phx-change="volume">
        <.range id="volume" name="volume" value={@volume} color="primary" label="Volume" />
      </form>
      <p class="mt-2 text-xs-plus">Volume: <span id="volume-value">{@volume}</span></p>
    </.example>
    """
  end
end
