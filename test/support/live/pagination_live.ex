defmodule LineaUI.Test.PaginationLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, page: 1)}

  def render(assigns) do
    ~H"""
    <.pagination id="pages" page={@page} total_pages={10} on_change="paginate" />
    <.live_component module={LineaUI.Test.PaginationComponent} id="inner" />
    """
  end

  def handle_event("paginate", %{"page" => page}, socket),
    do: {:noreply, assign(socket, page: String.to_integer(page))}
end

defmodule LineaUI.Test.PaginationComponent do
  @moduledoc false
  use Phoenix.LiveComponent
  use LineaUI

  def mount(socket), do: {:ok, assign(socket, page: 1)}

  def render(assigns) do
    ~H"""
    <div id="inner-wrap">
      <.pagination
        id="inner-pages"
        page={@page}
        total_pages={3}
        on_change="paginate"
        target={@myself}
      />
    </div>
    """
  end

  def handle_event("paginate", %{"page" => page}, socket),
    do: {:noreply, assign(socket, page: String.to_integer(page))}
end
