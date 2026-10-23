defmodule PreviewWeb.Pages.Breadcrumb do
  use PreviewWeb.Page, title: "Breadcrumb", category: :elements, lineone: "elements-breadcrumb"

  def render(assigns) do
    ~H"""
    <.example
      title="Breadcrumb"
      text="Breadcrumbs consist of a list of links that help a user visualize a page's location within the hierarchical structure of a website. Check out code for detail of usage."
      class="mt-4"
    >
      <.breadcrumb>
        <:item href="#">Home</:item>
        <:item href="#">Elements</:item>
        <:item>Breadcrumb</:item>
      </.breadcrumb>
    </.example>

    <.example
      title="Separators"
      text="Separators can be svg or any HTML chars. Check out code for detail of usage."
      class="mt-4 space-y-4"
    >
      <.trail>
        <:separator><span>&DoubleRightArrow;</span></:separator>
      </.trail>
      <.trail>
        <:separator><span>&centerdot;</span></:separator>
      </.trail>
      <.trail>
        <:separator><span class="text-xs font-light">|</span></:separator>
      </.trail>
      <.trail>
        <:separator><span class="text-xs font-light">/</span></:separator>
      </.trail>
      <.trail>
        <:separator>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-3.5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 7l5 5m0 0l-5 5m5-5H6"
            />
          </svg>
        </:separator>
      </.trail>
    </.example>

    <.example
      title="With Icon"
      text="Breadcrumb can have an icon. Check out code for detail of usage."
      class="mt-4 space-y-4"
    >
      <.icon_trail variant="plain" />
    </.example>

    <.example
      title="Bordered Breadcrumb"
      text="Breadcrumb can be bordered. Check out code for detail of usage."
      class="mt-4 space-y-4"
    >
      <.icon_trail variant="bordered" />
    </.example>
    """
  end

  slot :separator, required: true

  defp trail(assigns) do
    ~H"""
    <.breadcrumb>
      <:separator>{render_slot(@separator)}</:separator>
      <:item href="#">Home</:item>
      <:item href="#">Elements</:item>
      <:item>Breadcrumb</:item>
    </.breadcrumb>
    """
  end

  attr :variant, :string, required: true

  defp icon_trail(assigns) do
    ~H"""
    <.breadcrumb variant={@variant}>
      <:item href="#">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-4.5"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
          />
        </svg>
      </:item>
      <:item href="#">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-4.5"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
          />
        </svg>
        <span>Elements</span>
      </:item>
      <:item>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-4.5 text-slate-400 dark:text-navy-300"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
        <span>Calendar</span>
      </:item>
    </.breadcrumb>
    """
  end
end
