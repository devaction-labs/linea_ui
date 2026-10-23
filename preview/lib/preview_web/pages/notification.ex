defmodule PreviewWeb.Pages.Notification do
  use PreviewWeb.Page,
    title: "Notification",
    category: :components,
    lineone: "components-notification"

  import PreviewWeb.Pages.NarrowExample

  @text "The toast is used to show alerts on top of an overlay. The toast will close itself when the close button is clicked, or after a timeout — the default is 5 seconds. Check out code for detail of usage."

  @positions [
    {"left-top", "Left Top"},
    {"left-bottom", "Left Bottom"},
    {"center-top", "Center Top"},
    {"center-bottom", "Center Bottom"},
    {"right-top", "Right Top"},
    {"right-bottom", "Right Bottom"}
  ]

  def handle_event("default-toast", _params, socket),
    do: {:noreply, send_toast(socket, "This is a simple notification")}

  def render(assigns) do
    assigns = assign(assigns, text: @text, positions: @positions)

    ~H"""
    <.toaster flash={@flash} />
    <.narrow title="Basic Notification" text={@text} class="mt-5">
      <.button phx-click="default-toast">Default</.button>
    </.narrow>

    <.narrow title="Notification Variants" text={@text} class="inline-space mt-5">
      <.button
        :for={color <- ~w(primary secondary info success warning error)}
        color={color}
        phx-click={show_toast("This is a simple notification", color: color)}
      >
        {String.capitalize(color)}
      </.button>
      <.button
        class="dark:bg-slate-150 dark:text-slate-800 dark:hover:bg-slate-200 dark:focus:bg-slate-200 dark:active:bg-slate-200/80"
        phx-click={show_toast("This is a simple notification", color: "light")}
      >
        Light
      </.button>
      <.button
        class="bg-navy-500 text-slate-200 hover:bg-navy-450 focus:bg-navy-450 active:bg-navy-450/90"
        phx-click={show_toast("This is a simple notification", color: "dark")}
      >
        Dark
      </.button>
    </.narrow>

    <.narrow title="Notification Position" text={@text} class="inline-space mt-5">
      <.button
        :for={{position, label} <- @positions}
        phx-click={
          show_toast("This is a #{String.downcase(label)} notification",
            color: "info",
            position: position
          )
        }
      >
        {label}
      </.button>
    </.narrow>

    <.narrow title="Notification Duration" text={@text} class="mt-5">
      <.button phx-click={show_toast("This is a simple notification", color: "info", duration: 3000)}>
        3 Seconds
      </.button>
    </.narrow>

    <.narrow title="Custom HTML Content" text={@text} class="mt-5">
      <.button phx-click={show_toast(nil, template: "custom-html-notif", duration: 3000)}>
        HTML content
      </.button>
      <template id="custom-html-notif">
        <div class="flex max-w-xs overflow-hidden rounded-lg bg-navy-600 font-normal">
          <div class="flex items-start p-4">
            <div class="avatar size-10">
              <img class="rounded-full" src="/lineone/images/avatar/avatar-10.jpg" alt="avatar" />
              <div class="absolute right-0 size-3 rounded-full border-2 border-navy-600 bg-primary dark:bg-accent">
              </div>
            </div>
          </div>
          <div class="p-2">
            <div class="flex items-center justify-between space-x-2">
              <h5 class="font-medium tracking-wide text-navy-100 line-clamp-1 lg:text-base">
                Message Header
              </h5>
              <button
                data-toast-dismiss
                class="btn size-7 rounded-full p-0 text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="size-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            <p class="text-navy-100">Lorem ipsum dolor sit amet, consectetur</p>
            <div class="flex justify-end px-3 py-1">
              <a href="#" class="uppercase text-accent-light hover:underline">show</a>
            </div>
          </div>
        </div>
      </template>
    </.narrow>
    """
  end
end
