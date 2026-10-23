defmodule PreviewWeb.Pages.Skeleton do
  use PreviewWeb.Page, title: "Skeleton", category: :elements, lineone: "elements-skeleton"

  @text "Display a placeholder preview of your content before the data gets loaded to reduce load-time frustration. Check out code for detail of usage."

  def render(assigns) do
    assigns = assign(assigns, :text, @text)

    ~H"""
    <.example title="Basic Skeleton" text={@text} class="mt-5 max-w-md">
      <.profile animation="wave" />
    </.example>

    <.example title="Post Skeleton" text={@text} class="mt-5 max-w-md">
      <.post animation="wave" />
    </.example>

    <.example title="Post Skeleton" text={@text} class="mt-5 max-w-md">
      <.article animation="wave" />
    </.example>

    <.example title="Pulse Skeleton" class="">
      <.pulse_text />
      <div class="mt-5 max-w-md">
        <.profile animation="none" class="animate-pulse" />
      </div>
    </.example>

    <.example title="Pulse Skeleton" class="">
      <.pulse_text />
      <div class="mt-5 max-w-md">
        <.post animation="none" class="animate-pulse" />
      </div>
    </.example>

    <.example title="Pulse Skeleton" class="">
      <.pulse_text />
      <div class="mt-5 max-w-md">
        <.article animation="none" class="animate-pulse" />
      </div>
    </.example>
    """
  end

  defp pulse_text(assigns) do
    ~H"""
    <.text class="max-w-2xl">
      You can also use the
      <.inline_code>animate-pulse</.inline_code>
      to fade in and out skeleton. Check out code for detail of usage.
    </.text>
    """
  end

  attr :animation, :string, required: true
  attr :class, :string, default: nil

  defp profile(assigns) do
    ~H"""
    <div class={["flex flex-col border border-slate-150 dark:border-navy-500", @class]}>
      <div class="flex space-x-5 px-5 py-4">
        <.skeleton animation={@animation} shape="circle" class="size-16" />
        <div class="flex flex-1 flex-col justify-between py-2">
          <.skeleton animation={@animation} class="h-3 w-full" />
          <.skeleton animation={@animation} class="h-3 w-full" />
        </div>
      </div>
      <.skeleton animation={@animation} shape="square" class="h-48 w-full" />
      <div class="w-full px-6 py-4">
        <.skeleton animation={@animation} class="h-3 w-full" />
        <.skeleton animation={@animation} class="mt-4 h-3 w-8/12" />
      </div>
    </div>
    """
  end

  attr :animation, :string, required: true
  attr :class, :string, default: nil

  defp post(assigns) do
    ~H"""
    <div class={["flex flex-col", @class]}>
      <.skeleton animation={@animation} shape="lg" class="h-48 w-full" />
      <div class="flex space-x-5 py-4">
        <.skeleton animation={@animation} shape="circle" class="size-16" />
        <div class="flex flex-1 flex-col justify-between py-2">
          <.skeleton animation={@animation} class="h-3 w-10/12" />
          <.skeleton animation={@animation} class="h-6 w-full" />
        </div>
      </div>
    </div>
    """
  end

  attr :animation, :string, required: true
  attr :class, :string, default: nil

  defp article(assigns) do
    ~H"""
    <div class={["flex flex-col space-y-4 border border-slate-150 dark:border-navy-500", @class]}>
      <div class="px-4 pt-4">
        <.skeleton animation={@animation} shape="pill" class="h-8 w-10/12" />
      </div>
      <.skeleton animation={@animation} shape="square" class="h-48 w-full" />
      <div class="flex flex-1 flex-col justify-between space-y-4 p-4">
        <.skeleton animation={@animation} class="h-4 w-9/12" />
        <.skeleton animation={@animation} class="h-4 w-6/12" />
        <.skeleton animation={@animation} class="h-4 w-full" />
      </div>
    </div>
    """
  end
end
