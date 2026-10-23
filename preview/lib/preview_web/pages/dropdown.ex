defmodule PreviewWeb.Pages.Dropdown do
  use PreviewWeb.Page, title: "Dropdown", category: :components, lineone: "components-dropdown"

  import PreviewWeb.Pages.NarrowExample

  @text "Dropdowns are lightweight context menus for housing navigation and actions. Check out code for detail of usage."

  @people [
    {"Simon Tods", "Web Developer", {:img, "avatar-10"}},
    {"John Doe", "Web Developer",
     {:initial, "jd", "border border-success/30 bg-success/10 text-success"}},
    {"Konnor Guzman", "Frontend Developer", {:initial, "KG", "bg-warning text-white"}},
    {"Samantha Shelton", "Web Developer", {:img, "avatar-12"}},
    {"Derrick Simmons", "UI/UX Designer", {:img, "avatar-19"}}
  ]

  def render(assigns) do
    assigns = assign(assigns, text: @text, people: @people)

    ~H"""
    <.narrow title="Basic Dropdown" text={@text} class="inline-space mt-5 flex flex-wrap items-end">
      <.dropdown id="dropdown1" label="Dropdown">
        <.basic_items />
      </.dropdown>
      <.dropdown id="dropdown2" label="Dropdown" shape="pill">
        <.basic_items />
      </.dropdown>
      <.dropdown id="dropdown3">
        <:toggle>
          <.icon_toggle path="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
        </:toggle>
        <.basic_items />
      </.dropdown>
      <.dropdown id="dropdown4">
        <:toggle>
          <.icon_toggle path="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z" />
        </:toggle>
        <.basic_items />
      </.dropdown>
    </.narrow>

    <.narrow title="Primary Actions" text={@text} class="mt-5">
      <.dropdown id="dropdown5" label="Dropdown" color="primary">
        <.dropdown_item href="#" color="primary">Action</.dropdown_item>
        <.dropdown_item href="#" color="primary">Another Action</.dropdown_item>
        <.dropdown_item href="#" color="primary">Something Else</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item href="#" color="primary">Separated Link</.dropdown_item>
      </.dropdown>
    </.narrow>

    <.narrow title="Dropdown Icons" text={@text} class="mt-5">
      <.dropdown id="dropdown6" label="Dropdown">
        <.dropdown_item href="#">
          <:icon>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mt-px size-4.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1.5"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
              />
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
              />
            </svg>
          </:icon>
          <span> View</span>
        </.dropdown_item>
        <.dropdown_item href="#">
          <:icon>
            <.item_icon path="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
          </:icon>
          <span> Edit</span>
        </.dropdown_item>
        <.dropdown_item href="#">
          <:icon>
            <.item_icon path="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </:icon>
          <span> Update</span>
        </.dropdown_item>
        <.dropdown_item href="#" color="error">
          <:icon>
            <.item_icon path="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </:icon>
          <span> Delete item</span>
        </.dropdown_item>
      </.dropdown>
    </.narrow>

    <.narrow title="Scrolled Dropdown" text={@text} class="mt-5">
      <.dropdown id="dropdown7" label="Dropdown" class="h-36 overflow-y-auto dark:border-navy-600">
        <.dropdown_item href="#">Action</.dropdown_item>
        <.dropdown_item href="#">Another Action</.dropdown_item>
        <.dropdown_item :for={_ <- 1..12} href="#">Something else</.dropdown_item>
      </.dropdown>
    </.narrow>

    <.narrow title="HTML Content" text={@text} class="mt-5">
      <.dropdown id="dropdown8" label="Dropdown" class="w-72 py-0 dark:border-navy-600">
        <.dropdown_header>Only Selected People</.dropdown_header>
        <.dropdown_search placeholder="Type username..." />
        <div class="my-2">
          <.dropdown_item :for={{name, job, face} <- @people} href="#" variant="media">
            <.face face={face} />
            <div>
              <p class="text-slate-700 line-clamp-1 dark:text-navy-100">{name}</p>
              <p class="text-xs text-slate-500 dark:text-navy-300">{job}</p>
            </div>
          </.dropdown_item>
        </div>
      </.dropdown>
    </.narrow>
    """
  end

  defp basic_items(assigns) do
    ~H"""
    <.dropdown_item href="#">Action</.dropdown_item>
    <.dropdown_item href="#">Another Action</.dropdown_item>
    <.dropdown_item href="#">Something else</.dropdown_item>
    <.dropdown_separator />
    <.dropdown_item href="#">Separated Link</.dropdown_item>
    """
  end

  attr :path, :string, required: true

  defp icon_toggle(assigns) do
    ~H"""
    <.button
      variant="flat"
      icon
      shape="pill"
      size="sm"
      class="size-8 text-inherit dark:text-inherit"
      aria-label="Menu"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="size-5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="2"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d={@path} />
      </svg>
    </.button>
    """
  end

  attr :path, :string, required: true

  defp item_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-4.5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d={@path} />
    </svg>
    """
  end

  attr :face, :any, required: true

  defp face(%{face: {:img, name}} = assigns) do
    assigns = assign(assigns, :name, name)

    ~H"""
    <div class="avatar size-10">
      <img class="rounded-full" src={"/lineone/images/avatar/#{@name}.jpg"} alt="avatar" />
    </div>
    """
  end

  defp face(%{face: {:initial, text, class}} = assigns) do
    assigns = assign(assigns, text: text, class: class)

    ~H"""
    <div class="avatar size-10">
      <div class={["is-initial rounded-full uppercase", @class]}>{@text}</div>
    </div>
    """
  end
end
