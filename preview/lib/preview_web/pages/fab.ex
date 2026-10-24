defmodule PreviewWeb.Pages.Fab do
  use PreviewWeb.Page, title: "Floating action button", category: :components

  @stage "relative overflow-hidden rounded-lg bg-slate-100 [transform:translateZ(0)] dark:bg-navy-900"
  @offset "!bottom-4 !right-4"

  def render(assigns) do
    assigns = assign(assigns, stage: @stage, offset: @offset)

    ~H"""
    <.example
      title="Retract: hover"
      text="The bubble at rest; hover it, or focus it with the keyboard, to see the label."
      class="mt-5"
    >
      <div id="stage-hover" class={[@stage, "h-44"]}>
        <.fab id="fab-hover" label="Ask the assistant" class={@offset} phx-click="noop" />
      </div>
    </.example>

    <.example
      title="Retract: auto"
      text="Expanded at first, retracts after retract_after ms or when the page scrolls, expands again on hover."
      class="mt-5"
    >
      <div id="stage-auto" class={[@stage, "h-44"]}>
        <.fab id="fab-auto" label="Need a hand?" retract="auto" retract_after={3000} class={@offset} />
      </div>
    </.example>

    <.example title="Retract: never" text="Always expanded." class="mt-5">
      <div id="stage-never" class={[@stage, "h-44"]}>
        <.fab id="fab-never" label="Ask the assistant" retract="never" class={@offset} />
      </div>
    </.example>

    <.example
      title="Retract: always"
      text="Always the bubble; the label is the aria-label and tooltip."
      class="mt-5"
    >
      <div id="stage-always" class={[@stage, "h-44"]}>
        <.fab id="fab-always" label="Ask the assistant" retract="always" badge={3} class={@offset} />
      </div>
    </.example>

    <.example title="Colors and sizes" class="mt-5">
      <div id="stage-colors" class={[@stage, "h-96"]}>
        <.fab id="fab-c1" label="Assistant" retract="never" class="!bottom-4 !right-4" />
        <.fab id="fab-c2" label="Primary" retract="never" color="primary" class="!bottom-24 !right-4" />
        <.fab id="fab-c3" label="Dark" retract="never" color="dark" class="!bottom-44 !right-4" />
        <.fab
          id="fab-c4"
          label="Light"
          retract="never"
          color="light"
          position="bottom-left"
          class="!bottom-4 !left-4"
        />
        <.fab
          id="fab-c5"
          label="Large"
          retract="never"
          size="lg"
          position="top-left"
          class="!top-4 !left-4"
        />
        <.fab
          id="fab-c6"
          label="Forced open"
          expanded
          color="primary"
          position="top-right"
          class="!top-4 !right-4"
        />
      </div>
    </.example>
    """
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}
end
