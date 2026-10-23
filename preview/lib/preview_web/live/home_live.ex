defmodule PreviewWeb.HomeLive do
  use PreviewWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, page_title: "Components")}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.preview flash={@flash}>
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div :for={{label, pages} <- PreviewWeb.Registry.by_category()} class="card p-4">
          <h3 class="text-base font-medium text-slate-700 dark:text-navy-100">{label}</h3>
          <p class="text-xs text-slate-400 dark:text-navy-300">{length(pages)} pages</p>
          <ul class="mt-3 space-y-1">
            <li :for={page <- pages}>
              <.link
                navigate={"/" <> page.slug}
                class="hover:text-primary dark:hover:text-accent-light"
              >
                {page.title}
              </.link>
            </li>
          </ul>
        </div>
      </div>
    </Layouts.preview>
    """
  end
end
