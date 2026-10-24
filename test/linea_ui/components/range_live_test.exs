defmodule LineaUI.Components.RangeLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule PriceLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket) do
      {:ok,
       assign(socket,
         form: to_form(%{"markup" => "60", "from" => "40", "to" => "280"}, as: :price),
         test: session["test"]
       )}
    end

    def handle_event("validate", %{"price" => params}, socket) do
      send(socket.assigns.test, {:changed, params})
      {:noreply, assign(socket, form: to_form(params, as: :price))}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="price" phx-change="validate">
        <.range
          field={@form[:markup]}
          min={0}
          max={200}
          show_value
          value_format="%{value}%"
          filled
          marks={[0, 100, 200]}
        />
        <.range
          start_field={@form[:from]}
          end_field={@form[:to]}
          min={0}
          max={500}
          show_value
        />
      </.form>
      """
    end
  end

  test "phx-change hears the slider and both thumbs of the pair", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, PriceLive, session: %{"test" => self()})

    assert find(html, "input[name='price[markup]']") |> LazyHTML.attribute("value") == ["60"]
    assert find(html, "input[name='price[from]']") |> LazyHTML.attribute("value") == ["40"]
    assert find(html, "input[name='price[to]']") |> LazyHTML.attribute("value") == ["280"]

    view
    |> form("#price", %{"price" => %{"markup" => "150", "from" => "100", "to" => "300"}})
    |> render_change()

    assert_received {:changed, %{"markup" => "150", "from" => "100", "to" => "300"}}

    html = render(view)
    assert find(html, "input[name='price[markup]']") |> LazyHTML.attribute("value") == ["150"]

    assert find(html, "input[name='price[markup]']") |> LazyHTML.attribute("style") == [
             "--p: 75.0%"
           ]

    assert find(html, "[data-slider] output") |> LazyHTML.text() |> String.trim() == "150%"

    assert find(html, "[data-fill]") |> LazyHTML.attribute("style") == [
             "left: 20.0%; width: 40.0%"
           ]

    assert find(html, "[data-pair] output") |> LazyHTML.text() |> String.trim() == "100 – 300"
  end
end
