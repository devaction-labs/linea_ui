defmodule LineaUI.Components.TimerLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule TimerLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket),
      do: {:ok, assign(socket, running: true, elapsed: 120, events: [])}

    def render(assigns) do
      ~H"""
      <.timer
        id="shift"
        elapsed={@elapsed}
        running={@running}
        on_toggle="toggled"
        on_finish="finished"
      >
        <:actions>
          <button id="local" phx-click={LineaUI.Timer.toggle("shift")}>Pause</button>
          <button id="server-add" phx-click="server-add">Add</button>
          <button id="server-pause" phx-click="server-pause">Pause</button>
        </:actions>
      </.timer>
      <p id="events">{inspect(@events)}</p>
      """
    end

    def handle_event(
          "toggled",
          %{"id" => "shift", "running" => running, "elapsed" => elapsed},
          socket
        ),
        do:
          {:noreply,
           assign(socket,
             running: running,
             elapsed: elapsed,
             events: [:toggled | socket.assigns.events]
           )}

    def handle_event("finished", %{"id" => "shift"}, socket),
      do: {:noreply, assign(socket, events: [:finished | socket.assigns.events])}

    def handle_event("server-add", _params, socket),
      do: {:noreply, LineaUI.Timer.add(socket, "shift", 900)}

    def handle_event("server-pause", _params, socket),
      do: {:noreply, LineaUI.Timer.pause(socket, "#shift")}
  end

  test "the server pushes commands the hook listens for" do
    {:ok, view, _html} = live_isolated(build_conn(), TimerLive)

    view |> element("#server-add") |> render_click()
    assert_push_event(view, "linea:timer", %{id: "#shift", action: "add", seconds: 900})

    view |> element("#server-pause") |> render_click()
    assert_push_event(view, "linea:timer", %{id: "#shift", action: "pause"})
  end

  test "the toggle the hook pushes reaches the server and the new assigns reach the data" do
    {:ok, view, _html} = live_isolated(build_conn(), TimerLive)

    render_hook(view, "toggled", %{"id" => "shift", "running" => false, "elapsed" => 305})

    html = render(view)
    assert html =~ ~s(data-running="false")
    assert html =~ ~s(data-elapsed="305")
    assert html =~ ~s(data-state="paused")
    assert html =~ "[:toggled]"
  end

  test "the finish the hook pushes reaches the server" do
    {:ok, view, _html} = live_isolated(build_conn(), TimerLive)

    render_hook(view, "finished", %{"id" => "shift", "elapsed" => 28_800})

    assert render(view) =~ "[:finished]"
  end

  test "the caller's button runs the command in the browser, with no server event" do
    {:ok, _view, html} = live_isolated(build_conn(), TimerLive)

    [button] = html |> find("#local") |> LazyHTML.attribute("phx-click")
    assert button =~ "linea:timer"
    assert button =~ "toggle"
    assert button =~ "#shift"
  end
end
