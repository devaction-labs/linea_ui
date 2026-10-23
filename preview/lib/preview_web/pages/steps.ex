defmodule PreviewWeb.Pages.Steps do
  use PreviewWeb.Page, title: "Steps", category: :components, lineone: "components-steps"

  @text "Steps can be used to show a list of steps in a process. Check out code for detail of usage."

  def render(assigns) do
    assigns = assign(assigns, text: @text, four: 1..4)

    ~H"""
    <.example title="Basic Steps" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.steps>
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
        </div>
      </div>
    </.example>
    <.example title="Primary Steps" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.steps color="primary">
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
        </div>
      </div>
    </.example>
    <.example title="With Line Space" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.steps line_space>
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
        </div>
      </div>
    </.example>
    <.example title="Steps Size" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5 space-y-4">
          <.steps size="sm">
            <:step :for={n <- @four} label={"Step #{n}"} />
          </.steps>
          <.steps>
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
          <.steps size="lg">
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
        </div>
      </div>
    </.example>
    <.example title="Vertical Steps" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.steps orientation="vertical">
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
        </div>
      </div>
    </.example>
    <.example title="Vertical With Line Space" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.steps orientation="vertical" line_space>
            <:step :for={n <- @four} label={"Step #{n}"}>{n}</:step>
          </.steps>
        </div>
      </div>
    </.example>
    <.example title="Colored Steps" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.steps size="xs" line_space>
            <:step label="Step 1" color="primary" />
            <:step label="Step 2" color="secondary" ping />
            <:step label="Step 2" color="info" />
            <:step label="Step 2" color="error" />
            <:step label="Step 2" color="warning" />
          </.steps>
        </div>
      </div>
    </.example>
    """
  end
end
