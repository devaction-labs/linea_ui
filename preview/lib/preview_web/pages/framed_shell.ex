defmodule PreviewWeb.Pages.FramedShell do
  use PreviewWeb.Page, title: "Framed Shell", category: :layout, lineone: "pages-starter-1"

  def mount(socket), do: assign(socket, collapsed: false, tab: "items")

  def handle_event("collapse", %{"collapsed" => collapsed}, socket),
    do: {:noreply, assign(socket, :collapsed, collapsed)}

  def handle_event("tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, :tab, tab)}

  def render(assigns) do
    ~H"""
    <.example
      title="Framed shell"
      text="The grey frame, the menu that collapses to a rail and the page header with crumbs, clock, bell, badge, context line, actions and tabs."
      class="mt-5"
    >
      <div class="relative h-[640px] w-full overflow-hidden rounded-xl">
        <.app_shell id="framed-demo" layout="framed" class="h-[640px]!">
          <:sidebar>
            <.framed_sidebar
              id="framed-menu"
              collapsed={@collapsed}
              on_collapse="collapse"
              class="max-md:absolute!"
            >
              <:brand><.glyph name={:apps} class="size-5 text-primary" /></:brand>
              <:wordmark>Signetum</:wordmark>
              <:search aria-label="Search" phx-click="noop">
                <.glyph name={:search} class="size-4.5 shrink-0" />
                <span class="flex-1">Search</span>
                <.kbd>Ctrl K</.kbd>
              </:search>
              <.rail_link navigate="/framed-shell?page=today" label="Today">
                <.glyph name={:apps} />
              </.rail_link>
              <.rail_module id="framed-sales" label="Sales" badge="3">
                <:icon><.glyph name={:calendar} /></:icon>
                <:item navigate="/framed-shell" active>Orders</:item>
                <:item navigate="/framed-shell?page=products">Products</:item>
              </.rail_module>
              <.rail_module id="framed-fiscal" label="Fiscal" badge="2">
                <:icon><.glyph name={:filter} /></:icon>
                <:item navigate="/framed-shell?page=docs">Received documents</:item>
                <:item navigate="/framed-shell?page=markups">Markup</:item>
              </.rail_module>
              <:bottom>
                <.rail_toggle for="framed-menu" class="self-start" />
                <.dropdown id="framed-user" placement="top-start">
                  <:toggle>
                    <.button type="button" variant="flat" color="current" class="h-auto w-full justify-start p-0 text-left font-normal" aria-label="Account">
                      <.rail_user name="Ana Souza de Albuquerque Montenegro" subtitle="Platform administrator">
                        <.avatar name="Ana Souza" color="auto" size="32" />
                      </.rail_user>
                    </.button>
                  </:toggle>
                  <.dropdown_item>My account</.dropdown_item>
                </.dropdown>
              </:bottom>
            </.framed_sidebar>
          </:sidebar>
          <.page_header
            variant="page"
            title="Order PV-1283"
            description="Clinica Santa Monica · Carlos Lima · delivery on Monday"
            clock
            bell
          >
            <:crumb navigate="/framed-shell">Sales</:crumb>
            <:crumb navigate="/framed-shell">Orders</:crumb>
            <:crumb>PV-1283</:crumb>
            <:badge>
              <.badge color="info">Approved</.badge>
            </:badge>
            <:actions>
              <.button variant="outline">Duplicate</.button>
              <.button color="primary">Issue NF-e</.button>
            </:actions>
            <:tabs>
              <button
                :for={
                  {key, label} <- [{"items", "Items"}, {"payment", "Payment"}, {"history", "History"}]
                }
                type="button"
                role="tab"
                aria-selected={to_string(@tab == key)}
                phx-click="tab"
                phx-value-tab={key}
                class={[
                  "h-[42px] border-b-2 px-3 text-sm",
                  @tab == key && "border-primary text-slate-800 dark:text-navy-50",
                  @tab != key && "border-transparent text-slate-500 dark:text-navy-200"
                ]}
              >
                {label}
              </button>
            </:tabs>
          </.page_header>
          <div class="grid flex-1 grid-cols-3 gap-4">
            <div :for={n <- 1..3} class="rounded-lg bg-slate-100 p-4 dark:bg-navy-600">Card {n}</div>
          </div>
        </.app_shell>
      </div>
    </.example>
    """
  end
end
