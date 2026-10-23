defmodule PreviewWeb.Pages.Tab do
  use PreviewWeb.Page, title: "Tab", category: :components, lineone: "components-tab"

  @text "Tabs make it easy to explore and switch between different views. Check out code for detail of usage."

  @panels [
    {"home", "Home",
     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent elementum finibus arcu vitae scelerisque. Etiam rutrum blandit condimentum. Maecenas condimentum massa vitae quam interdum, et lacinia urna tempor"},
    {"profile", "Profile",
     "Pellentesque pulvinar, sapien eget fermentum sodales, felis lacus viverra magna, id pulvinar odio metus non enim. Ut id augue interdum, ultrices felis eu, tincidunt libero."},
    {"messages", "Messages",
     "Cras iaculis ipsum quis lectus faucibus, in mattis nulla molestie. Vestibulum vel tristique libero. Morbi vulputate odio at viverra sodales. Curabitur accumsan justo eu libero porta ultrices vitae eu leo."},
    {"settings", "Settings",
     "Etiam nec ante eget lacus vulputate egestas non iaculis tellus. Suspendisse tempus ex in tortor venenatis malesuada. Aenean consequat dui vitae nibh lobortis condimentum. Duis vel risus est."}
  ]

  @icons %{
    "home" =>
      "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6",
    "profile" => "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z",
    "messages" =>
      "M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
  }

  def mount(socket), do: assign(socket, server_tab: "profile")

  def handle_event("select_tab", %{"value" => tab}, socket),
    do: {:noreply, assign(socket, server_tab: tab)}

  def handle_event("server_select", _params, socket),
    do: {:noreply, assign(socket, server_tab: "settings")}

  def render(assigns) do
    assigns =
      assigns
      |> assign(:text, @text)
      |> assign(:panels, @panels)
      |> assign(:three, Enum.take(@panels, 3))
      |> assign(:icons, @icons)

    ~H"""
    <.example title="Basic Tabs" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.tabs id="tab-wrapper-1">
            <:tab :for={{name, label, _} <- @panels} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @panels} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example title="Border Bottom" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.tabs id="tab-wrapper-2" bordered transition="up">
            <:tab :for={{name, label, _} <- @panels} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @panels} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example title="Tab With Icon" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.tabs id="tab-wrapper-3" selected="profile" bordered overlap>
            <:tab :for={{name, label, _} <- @three} name={name}>
              {icon(%{d: @icons[name]})}<span>{label}</span>
            </:tab>
            <:panel :for={{name, _, body} <- @three} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example title="Boxed Tabs" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.tabs id="tab-wrapper-4" variant="boxed">
            <:tab :for={{name, label, _} <- @panels} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @panels} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example title="Boxed Tabs With Icon" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.tabs id="tab-wrapper-5" variant="boxed">
            <:tab :for={{name, label, _} <- @three} name={name}>
              {icon(%{d: @icons[name]})}<span>{label}</span>
            </:tab>
            <:panel :for={{name, _, body} <- @three} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example title="Pill Tabs" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5 space-y-6">
          <.tabs id="tab-wrapper-6" variant="pill">
            <:tab :for={{name, label, _} <- @three} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @three} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
          <.tabs id="tab-wrapper-7" variant="pill" color="neutral">
            <:tab :for={{name, label, _} <- @three} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @three} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example title="Vertical Tabs" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5 space-y-6">
          <.tabs id="tab-wrapper-8" orientation="vertical" bordered overlap>
            <:tab :for={{name, label, _} <- @panels} name={name}>
              {icon(%{d: @icons[name] || @icons["home"]})}<span>{label}</span>
            </:tab>
            <:panel :for={{name, _, body} <- @panels} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
          <.tabs id="tab-wrapper-9" orientation="vertical" variant="boxed" transition="up">
            <:tab :for={{name, label, _} <- @panels} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @panels} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
        </div>
      </div>
    </.example>
    <.example
      title="Server Driven Tabs"
      class=""
    >
      <div class="max-w-xl">
        <p>
          With on_change the LiveView owns the selection: each click or arrow key pushes an event.
        </p>
        <div class="mt-5">
          <.tabs id="tab-wrapper-10" selected={@server_tab} on_change="select_tab" bordered>
            <:tab :for={{name, label, _} <- @panels} name={name}>{label}</:tab>
            <:panel :for={{name, _, body} <- @panels} name={name}>{panel(%{body: body})}</:panel>
          </.tabs>
          <p id="server-tab-value" class="pt-3 text-xs text-slate-400 dark:text-navy-300">
            Selected on the server: {@server_tab}
          </p>
          <.button id="server-select" size="sm" class="mt-3" phx-click="server_select">
            Select Settings from the server
          </.button>
        </div>
      </div>
    </.example>
    """
  end

  defp icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-4.5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d={@d} />
    </svg>
    """
  end

  defp panel(assigns) do
    ~H"""
    <div>
      <p>{@body}</p>
      <div class="flex space-x-2 pt-3">
        <a
          :for={tag <- ["Tag 1", "Tag 2"]}
          href="#"
          class="tag rounded-full border border-primary text-primary dark:border-accent-light dark:text-accent-light"
        >
          {tag}
        </a>
      </div>
      <p class="pt-3 text-xs text-slate-400 dark:text-navy-300">
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Tempore dolore non atque?
      </p>
    </div>
    """
  end
end
