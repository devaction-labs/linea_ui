defmodule LineaUI.Components.ColorPickerLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule StageLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket) do
      {:ok,
       assign(socket,
         form: to_form(%{"color" => "#4C3FE0"}, as: :stage),
         test: session["test"]
       )}
    end

    def handle_event("validate", %{"stage" => params}, socket) do
      send(socket.assigns.test, {:changed, params})
      {:noreply, assign(socket, form: to_form(params, as: :stage))}
    end

    def handle_event("picked", params, socket) do
      send(socket.assigns.test, {:picked, params})
      {:noreply, socket}
    end

    def handle_event("recolor", _params, socket),
      do: {:noreply, assign(socket, form: to_form(%{"color" => "#18996E"}, as: :stage))}

    def render(assigns) do
      ~H"""
      <.form for={@form} id="stage" phx-change="validate">
        <.color_picker field={@form[:color]} on_change="picked" />
      </.form>
      <button id="recolor" phx-click="recolor">Recolor</button>
      """
    end
  end

  test "the hidden input is part of the form and phx-change hears its value", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, StageLive, session: %{"test" => self()})

    assert find(html, "input[name='stage[color]']") |> LazyHTML.attribute("value") == ["#4C3FE0"]

    view |> form("#stage") |> render_change(%{"stage" => %{"color" => "#EB3B2F"}})

    assert_received {:changed, %{"color" => "#EB3B2F"}}

    assert find(render(view), "#stage_color-picker")
           |> LazyHTML.attribute("data-value") == ["#EB3B2F"]
  end

  test "a color the server sets replaces the one in the picker", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, StageLive, session: %{"test" => self()})

    view |> element("#recolor") |> render_click()
    html = render(view)

    assert find(html, "#stage_color-picker") |> LazyHTML.attribute("data-value") == ["#18996E"]

    assert find(html, "[data-preset][aria-pressed=true]") |> LazyHTML.attribute("data-preset") ==
             ["#18996E"]
  end

  test "on_change is wired for the hook to push", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, StageLive, session: %{"test" => self()})

    assert find(html, "#stage_color-picker") |> LazyHTML.attribute("data-on-change") == ["picked"]
  end
end
