defmodule PreviewWeb.Pages.Shell do
  use PreviewWeb.Page, title: "Shell", category: :layout, lineone: "pages-starter-1"

  @nav [
    %{label: "Home", icon: "home", navigate: "/shell"},
    %{label: "Orders", icon: "cart", navigate: "/shell?page=orders"},
    %{label: "Customers", icon: "users", navigate: "/shell?page=customers"}
  ]

  def render(assigns) do
    assigns = assign(assigns, :nav, @nav)

    ~H"""
    <.example
      title="Mobile"
      text="The bottom bar of tabs: the :tab_bar slot shows below 768px, fixed at the foot with the safe area, and the page keeps room under it."
      class="mt-5"
    >
      <div class="relative h-[640px] w-full overflow-hidden rounded-xl [transform:translateZ(0)]">
        <.shell
          id="shell-demo"
          nav={@nav}
          current="/shell"
          brand={%{name: "Signetum", logo: "S"}}
          user={%{name: "Ana Souza"}}
          class="h-[640px]!"
        >
          <div class="space-y-2">
            <.skeleton class="h-4 w-3/5" />
            <.skeleton class="h-2.5 w-11/12" />
            <.skeleton class="h-2.5 w-4/5" />
          </div>
          <.skeleton :for={_ <- 1..8} class="h-16 w-full shrink-0" />
          <:tab_bar>
            <.tab_bar label="Sections">
              <:tab navigate="/shell" label="Home" active><.glyph name={:apps} /></:tab>
              <:tab navigate="/shell?page=orders" label="Orders"><.glyph name={:calendar} /></:tab>
              <:tab navigate="/shell?page=customers" label="Customers">
                <.glyph name={:search} />
              </:tab>
              <:tab navigate="/shell?page=settings" label="Settings"><.glyph name={:filter} /></:tab>
            </.tab_bar>
          </:tab_bar>
        </.shell>
      </div>
    </.example>
    """
  end
end
