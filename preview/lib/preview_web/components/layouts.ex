defmodule PreviewWeb.Layouts do
  @moduledoc "The preview's shell: the list of pages on the left and the page on the right."

  use PreviewWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :page, :map, default: nil
  slot :inner_block, required: true

  def preview(assigns) do
    ~H"""
    <aside class="fixed inset-y-0 left-0 z-30 hidden w-60 flex-col border-r border-slate-150 bg-white dark:border-navy-700 dark:bg-navy-750 md:flex">
      <.link
        navigate="/"
        class="flex h-[61px] items-center px-5 text-lg font-semibold text-slate-700 dark:text-navy-100"
      >
        LineaUI
      </.link>
      <nav class="is-scrollbar-hidden flex-1 overflow-y-auto px-3 pb-6">
        <div :for={{label, pages} <- PreviewWeb.Registry.by_category()} :if={pages != []} class="mt-3">
          <p class="px-2 text-tiny-plus font-semibold uppercase tracking-wide text-slate-400 dark:text-navy-300">
            {label}
          </p>
          <.link
            :for={item <- pages}
            navigate={"/" <> item.slug}
            class={[
              "mt-1 block rounded-lg px-2 py-1.5 text-xs-plus tracking-wide transition-colors",
              active_class(@page, item)
            ]}
          >
            {item.title}
          </.link>
        </div>
      </nav>
    </aside>
    <div class="md:ml-60">
      <header class="sticky top-0 z-20 flex h-[61px] items-center justify-between border-b border-slate-150 bg-white/80 px-[var(--margin-x)] backdrop-blur-sm dark:border-navy-700 dark:bg-navy-750/80">
        <div class="flex items-center space-x-4">
          <h2 class="text-xl font-medium text-slate-800 dark:text-navy-50 lg:text-2xl">
            {(@page && @page.title) || "LineaUI"}
          </h2>
          <a
            :if={@page && @page.lineone}
            href={"/lineone/#{@page.lineone}.html"}
            target="_blank"
            class="text-xs text-primary hover:text-primary-focus dark:text-accent-light"
          >
            LineOne original ↗
          </a>
        </div>
        <button
          type="button"
          id="preview-theme"
          phx-click={JS.toggle_class("dark", to: "html") |> JS.dispatch("preview:theme")}
          class="btn size-8 rounded-full p-0 hover:bg-slate-300/20 dark:hover:bg-navy-300/20"
          aria-label="Toggle dark mode"
        >
          <span class="dark:hidden">☾</span>
          <span class="hidden dark:inline">☀</span>
        </button>
      </header>
      <main class="w-full px-[var(--margin-x)] pt-5 pb-8 lg:pt-6">
        <div class="grid grid-cols-1 gap-4 sm:gap-5 lg:gap-6">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    <.toaster id="preview-toaster" flash={@flash} />
    """
  end

  defp active_class(%{slug: slug}, %{slug: slug}),
    do: "bg-primary/10 font-medium text-primary dark:bg-accent-light/10 dark:text-accent-light"

  defp active_class(_page, _item),
    do: "text-slate-600 hover:bg-slate-100 dark:text-navy-200 dark:hover:bg-navy-600"
end
