defmodule PreviewWeb.Pages.Monochrome do
  use PreviewWeb.Page,
    title: "Monochrome Mode",
    category: :components,
    lineone: "components-extension-monochrome"

  def mount(socket), do: assign(socket, :monochrome, nil)

  def handle_event("monochrome", %{"monochrome" => on}, socket),
    do: {:noreply, assign(socket, :monochrome, on)}

  def render(assigns) do
    ~H"""
    <.example title="Monochrome Mode" class="max-w-xl">
      <p>
        Monochromatic UI/UX design may look simpler. Monochrome mode can be used if the network is offline.
      </p>
      <div class="inline-space mt-5 flex flex-wrap">
        <div class="size-16 rounded-lg bg-primary dark:bg-accent"></div>
        <div class="size-16 rounded-lg bg-secondary"></div>
        <div class="size-16 rounded-lg bg-info"></div>
        <div class="size-16 rounded-lg bg-success"></div>
        <div class="size-16 rounded-lg bg-warning"></div>
        <div class="size-16 rounded-lg bg-error"></div>
      </div>
      <.monochrome_toggle id="monochromeToggle" variant="switch" on_change="monochrome" class="mt-4">
        Toggle Monochrome Mode
      </.monochrome_toggle>
    </.example>
    """
  end
end
