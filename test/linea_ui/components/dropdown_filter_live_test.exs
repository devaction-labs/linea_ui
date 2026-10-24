defmodule LineaUI.Components.DropdownFilterLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule OrdersLive do
    use Phoenix.LiveView
    use LineaUI

    @statuses ~w(Aprovado Faturado Cancelado)

    def mount(_params, session, socket) do
      {:ok,
       assign(socket,
         statuses: @statuses,
         filter: %{"status" => ["Aprovado"], "sort" => "recent"},
         test: session["test"]
       )}
    end

    def handle_event("draft", %{"filter" => params}, socket) do
      send(socket.assigns.test, {:draft, params})
      {:noreply, assign(socket, filter: Map.merge(%{"status" => []}, params))}
    end

    def handle_event("apply", %{"filter" => params}, socket) do
      send(socket.assigns.test, {:apply, params})
      {:noreply, socket}
    end

    def handle_event("reset", _params, socket),
      do: {:noreply, assign(socket, filter: %{"status" => ["Faturado"], "sort" => "value"})}

    def render(assigns) do
      ~H"""
      <form id="filters" phx-change="draft" phx-submit="apply">
        <.dropdown id="menu" label="Filter" keep_submenus close_on_select={false}>
          <.dropdown_submenu id="status" label="Status" count={length(@filter["status"])}>
            <.dropdown_checkbox
              :for={status <- @statuses}
              name="filter[status][]"
              value={status}
              checked={status in @filter["status"]}
            >
              {status}
            </.dropdown_checkbox>
          </.dropdown_submenu>
          <.dropdown_label>Sort by</.dropdown_label>
          <.dropdown_radio name="filter[sort]" value="recent" checked={@filter["sort"] == "recent"}>
            Recent
          </.dropdown_radio>
          <.dropdown_radio name="filter[sort]" value="value" checked={@filter["sort"] == "value"}>
            Value
          </.dropdown_radio>
          <.dropdown_footer locale="pt_BR" />
        </.dropdown>
      </form>
      <button id="reset" phx-click="reset">Reset</button>
      """
    end
  end

  defp checked(html, role),
    do:
      html
      |> find("[role=#{role}][aria-checked=true]")
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  test "the first paint carries what the server says is checked", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, OrdersLive, session: %{"test" => self()})

    assert checked(html, "menuitemcheckbox") == ["Aprovado"]
    assert checked(html, "menuitemradio") == ["Recent"]

    assert find(html, "input[name='filter[status][]'][checked]") |> LazyHTML.attribute("value") ==
             ["Aprovado"]

    assert find(html, "#status [data-submenu-count]") |> LazyHTML.text() |> String.trim() == "1"
  end

  test "phx-change hears the form the inputs make", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OrdersLive, session: %{"test" => self()})

    view
    |> form("#filters", %{"filter" => %{"status" => ["Aprovado", "Faturado"], "sort" => "value"}})
    |> render_change()

    assert_received {:draft, %{"status" => ["Aprovado", "Faturado"], "sort" => "value"}}

    html = render(view)
    assert checked(html, "menuitemcheckbox") == ["Aprovado", "Faturado"]
    assert checked(html, "menuitemradio") == ["Value"]
    assert find(html, "#status [data-submenu-count]") |> LazyHTML.text() |> String.trim() == "2"
  end

  test "the form submits only the checked ones when Apply is pressed", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OrdersLive, session: %{"test" => self()})

    view |> form("#filters", %{"filter" => %{"status" => ["Cancelado"]}}) |> render_submit()

    assert_received {:apply, %{"status" => ["Cancelado"], "sort" => "recent"}}
  end

  test "a state the server sets reaches the items through data-server-checked", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OrdersLive, session: %{"test" => self()})

    view |> element("#reset") |> render_click()
    html = render(view)

    assert find(html, "[role=menuitemcheckbox][data-server-checked=true]")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == ["Faturado"]

    assert find(html, "[role=menuitemradio][data-server-checked=true]")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == ["Value"]
  end
end
