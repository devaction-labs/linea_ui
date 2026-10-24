defmodule LineaUI.Components.FloatingLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule FloatingLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(picked: nil)
       |> stream(:rows, [%{id: 1, name: "Order 1"}, %{id: 2, name: "Order 2"}])}
    end

    def handle_event("pick", %{"id" => id}, socket), do: {:noreply, assign(socket, picked: id)}

    def handle_event("add", _params, socket),
      do: {:noreply, stream_insert(socket, :rows, %{id: 3, name: "Order 3"})}

    def render(assigns) do
      ~H"""
      <p id="picked">{@picked}</p>
      <button id="add" phx-click="add">Add</button>
      <.drawer id="sheet" title="Orders" open>
        <.table id="orders" rows={@streams.rows}>
          <:col :let={{_id, row}} label="Name">{row.name}</:col>
          <:col :let={{_id, row}} label="">
            <.dropdown id={"row-#{row.id}"} toggle_icon="dots" placement="bottom-end">
              <.dropdown_item phx-click="pick" phx-value-id={row.id}>Pick</.dropdown_item>
              <.dropdown_submenu id={"row-#{row.id}-more"} label="More">
                <.dropdown_item phx-click="pick" phx-value-id={"#{row.id}-more"}>Deeper</.dropdown_item>
              </.dropdown_submenu>
            </.dropdown>
          </:col>
        </.table>
        <.popover id="hint">
          <:trigger><button>Hint</button></:trigger>
          Text
        </.popover>
        <.tooltip id="tip" text="Tip"><button>Tip</button></.tooltip>
      </.drawer>
      """
    end
  end

  defp panel_attr(html, selector, name), do: find(html, selector) |> LazyHTML.attribute(name)

  test "the floating panels of a table inside a drawer render for the top layer", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, FloatingLive)

    for selector <- ~w(#row-1-menu #row-2-menu #hint-panel #tip-tip) do
      assert panel_attr(html, selector, "popover") == ["manual"]
    end

    assert "fixed" in classes(html, "#row-1-menu")
    assert "fixed" in classes(html, "#hint-panel")
    refute "absolute" in classes(html, "#row-1-menu")
  end

  test "an item in a row's menu and in its submenu reaches the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FloatingLive)

    view |> element("#row-2-menu button[phx-value-id='2']") |> render_click()
    assert view |> element("#picked") |> render() =~ ">2<"

    view |> element("#row-1-more-menu [role=menuitem]") |> render_click()
    assert view |> element("#picked") |> render() =~ "1-more"
  end

  test "a patch keeps the panel's client state and renders new rows the same way", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FloatingLive)
    html = view |> element("#add") |> render_click()

    assert panel_attr(html, "#row-3-menu", "popover") == ["manual"]
    [mounted] = panel_attr(html, "#row-1-menu", "phx-mounted")
    assert [["ignore_attrs", %{"attrs" => attrs}]] = Jason.decode!(mounted)
    assert ["class", "style", "data-popper-placement", "aria-hidden"] -- attrs == []
  end
end
