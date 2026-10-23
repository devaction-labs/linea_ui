defmodule PreviewWeb.Pages.Alert do
  use PreviewWeb.Page, title: "Alert", category: :elements, lineone: "elements-alert"

  @colors ~w(neutral primary secondary info success warning error)

  def render(assigns) do
    assigns = assign(assigns, :colors, @colors)

    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:gap-5 lg:grid-cols-2 lg:gap-6">
      <.example
        title="Basic Alert"
        text="The alert component is used to convey important information to the user through the use of contextual types, icons, and colors"
        class="mt-5 max-w-2xl space-y-4"
      >
        <.alert :for={color <- @colors} color={color}>This is simple alert</.alert>
      </.example>

      <.example
        title="Outlined Alert"
        text="Alerts can be outlied. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.alert :for={color <- @colors} color={color} variant="outline">
          This is simple alert
        </.alert>
      </.example>

      <.example
        title="Outlined Alert"
        text="Alerts can have a soft colors. To do this, you should use some opacity. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.alert :for={color <- tl(@colors)} color={color} variant="soft" shape="pill">
          This is simple alert
        </.alert>
      </.example>

      <.example
        title="Bordered Alert"
        text="Alerts can have a border. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.alert
          color="primary"
          variant="soft"
          shape="pill"
          class="border border-primary dark:border-accent"
        >
          This is simple alert
        </.alert>
        <.alert color="secondary" variant="soft" accent="left">This is simple alert</.alert>
        <.alert color="info" variant="outline">
          <:icon boxed><.info_icon /></:icon>
          This is simple alert
        </.alert>
        <.alert color="success" variant="bordered">This is simple alert</.alert>
        <.alert color="warning" variant="soft" accent="right">
          <:icon>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </:icon>
          This is simple alert
        </.alert>
        <.alert color="error" variant="outline" class="sm:px-4">
          <:icon>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
          </:icon>
          This is simple alert
        </.alert>
      </.example>

      <div class="lg:col-span-2">
        <.example
          title="Dismissable Alert"
          text="Alerts can be dismissable. Check out code for detail of usage."
          class="mt-5 max-w-2xl space-y-4"
          id="dismissable-alert"
        >
          <.alert id="alert-dismissable-1" color="info" variant="outline" dismissible>
            <:icon boxed><.info_icon /></:icon>
            This is simple alert
          </.alert>
          <.alert id="alert-dismissable-2" color="dark">
            <p>Lorem ipsum dolor sit amet consectetur.</p>
            <:action>
              <button
                type="button"
                aria-label="Remove"
                phx-click={dismiss_alert()}
                class="btn -mr-1.5 size-7 shrink-0 rounded-full p-0 text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25"
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
                    d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
                  />
                </svg>
              </button>
            </:action>
          </.alert>
          <.alert
            id="alert-dismissable-3"
            variant="outline"
            class="flex-col space-y-4 py-3 text-center sm:flex-row sm:space-y-0"
          >
            <p>Lorem ipsum dolor sit amet consectetur.</p>
            <:action>
              <.button shape="pill" class="space-x-2" phx-click={dismiss_alert()}>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="size-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
                  />
                </svg>
                <span>REMIND ME LATER</span>
              </.button>
            </:action>
          </.alert>
        </.example>
      </div>
    </div>
    """
  end

  defp info_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
    """
  end
end
