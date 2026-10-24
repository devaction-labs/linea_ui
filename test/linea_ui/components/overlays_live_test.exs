defmodule LineaUI.Components.OverlaysLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule OverlaysLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket),
      do: {:ok, assign(socket, confirming: false, closed: [], section: false)}

    def handle_event("confirm", _params, socket), do: {:noreply, assign(socket, confirming: true)}

    def handle_event("closed", %{"id" => id}, socket),
      do: {:noreply, assign(socket, confirming: false, closed: [id | socket.assigns.closed])}

    def handle_event("open", %{"id" => id}, socket), do: {:noreply, LineaUI.open(socket, id)}
    def handle_event("close", %{"id" => id}, socket), do: {:noreply, LineaUI.close(socket, id)}
    def handle_event("toggle", %{"id" => id}, socket), do: {:noreply, LineaUI.toggle(socket, id)}
    def handle_event("expand", _params, socket), do: {:noreply, assign(socket, section: true)}

    def handle_event("toast", _params, socket),
      do: {:noreply, send_toast(socket, "Saved", color: "success", position: "right-top")}

    def handle_event("loading", _params, socket),
      do: {:noreply, send_toast(socket, id: "nfe", kind: :loading, title: "Sending")}

    def handle_event("resolve", _params, socket),
      do: {:noreply, send_toast(socket, "Authorized", id: "nfe", kind: :success)}

    def handle_event("describe", _params, socket),
      do: {:noreply, update_toast(socket, "nfe", description: "SEFAZ")}

    def handle_event("dismiss", _params, socket), do: {:noreply, dismiss_toast(socket, "nfe")}
    def handle_event("clear", _params, socket), do: {:noreply, clear_toasts(socket)}

    def handle_event("flash-toast", _params, socket),
      do: {:noreply, put_toast(socket, "Kept", color: "info")}

    def render(assigns) do
      ~H"""
      <.toaster flash={@flash} />
      <p id="closed">{Enum.join(@closed, ",")}</p>
      <button id="confirm" phx-click="confirm">Confirm</button>
      <button id="toast" phx-click="toast">Toast</button>
      <button id="flash-toast" phx-click="flash-toast">Flash</button>
      <button id="expand" phx-click="expand">Expand</button>
      <.modal id="m" open={@confirming} on_close="closed">
        <:header>Sure?</:header>
        <button id="done" phx-click="closed" phx-value-id="m">Done</button>
      </.modal>
      <.drawer id="d" on_close="closed">Menu</.drawer>
      <.dropdown id="dd" label="Menu" on_close="closed">
        <.dropdown_item phx-click="closed" phx-value-id="item">Pick</.dropdown_item>
      </.dropdown>
      <.popover id="p" on_open="closed">
        <:trigger><button>Info</button></:trigger>
        Text
      </.popover>
      <.accordion id="a">
        <.accordion_item id="a1" title="One" open={@section}>One</.accordion_item>
      </.accordion>
      """
    end
  end

  test "the server's open assign reaches the modal and an event syncs it back", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, OverlaysLive)
    assert find(html, "#m") |> LazyHTML.attribute("data-open") == ["false"]

    html = view |> element("#confirm") |> render_click()
    assert find(html, "#m") |> LazyHTML.attribute("data-open") == ["true"]

    html = view |> element("#done") |> render_click()
    assert find(html, "#m") |> LazyHTML.attribute("data-open") == ["false"]
    assert find(html, "#closed") |> LazyHTML.text() == "m"
  end

  test "on_close carries the event the hook pushes when the browser closes it", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, OverlaysLive)

    for id <- ~w(m d dd) do
      [encoded] = find(html, "##{id}") |> LazyHTML.attribute("data-on-close")

      assert [["push", %{"event" => "closed", "value" => %{"id" => ^id}}]] =
               Jason.decode!(encoded)
    end
  end

  test "LineaUI.open/close/toggle(socket, id) push the command the hooks handle", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OverlaysLive)

    render_click(view, "open", %{"id" => "m"})
    assert_push_event(view, "linea:open", %{id: "#m"})

    render_click(view, "close", %{"id" => "dd"})
    assert_push_event(view, "linea:close", %{id: "#dd"})

    render_click(view, "toggle", %{"id" => "#d"})
    assert_push_event(view, "linea:toggle", %{id: "#d"})
  end

  test "a dropdown item's own event reaches the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OverlaysLive)
    assert view |> element("#dd-menu [role=menuitem]") |> render_click() =~ "item"
  end

  test "send_toast pushes the toast to the toaster's hook", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OverlaysLive)
    view |> element("#toast") |> render_click()

    assert_push_event(view, "linea:toast", %{
      "message" => "Saved",
      "color" => "success",
      "position" => "right-top"
    })
  end

  test "put_toast leaves the toast in the flash the toaster reads", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OverlaysLive)
    html = view |> element("#flash-toast") |> render_click()

    [json] = find(html, "#linea-toaster") |> LazyHTML.attribute("data-flash")
    assert [%{"message" => "Kept", "color" => "info"}] = Jason.decode!(json)

    html = render_hook(view, "lv:clear-flash", %{"key" => "linea_toast"})
    assert find(html, "#linea-toaster") |> LazyHTML.attribute("data-flash") == ["[]"]
  end

  test "the server opens an accordion section through its open attr", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, OverlaysLive)
    assert find(html, "#a1") |> LazyHTML.attribute("data-open") == ["false"]

    html = view |> element("#expand") |> render_click()
    assert find(html, "#a1") |> LazyHTML.attribute("data-open") == ["true"]
  end

  test "a loading toast is resolved, updated and dismissed by its id", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OverlaysLive)

    render_click(view, "loading", %{})

    assert_push_event(view, "linea:toast", %{
      "id" => "nfe",
      "kind" => "loading",
      "message" => "Sending"
    })

    render_click(view, "resolve", %{})

    assert_push_event(view, "linea:toast", %{
      "id" => "nfe",
      "kind" => "success",
      "color" => "success",
      "message" => "Authorized"
    })

    render_click(view, "describe", %{})
    assert_push_event(view, "linea:toast-update", %{"id" => "nfe", "description" => "SEFAZ"})

    render_click(view, "dismiss", %{})
    assert_push_event(view, "linea:toast-dismiss", %{"id" => "nfe"})

    render_click(view, "clear", %{})
    assert_push_event(view, "linea:toast-dismiss", %{"all" => true})
  end
end
