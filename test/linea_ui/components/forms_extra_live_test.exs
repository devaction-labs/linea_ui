defmodule LineaUI.Components.FormsExtraLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule OrderLive do
    use Phoenix.LiveView
    use LineaUI

    @customers [{"Ana", "1"}, {"Bruno", "2"}, {"Carla", "3"}]

    def mount(_params, session, socket) do
      {:ok,
       assign(socket,
         form: to_form(%{"price" => "10.5", "customer_id" => "2"}, as: :order),
         customers: @customers,
         test: session["test"]
       )}
    end

    def handle_event("validate", %{"order" => params}, socket) do
      send(socket.assigns.test, {:changed, params})
      {:noreply, assign(socket, form: to_form(params, as: :order))}
    end

    def handle_event("search", %{"id" => "order_customer_id", "query" => query}, socket) do
      found = Enum.filter(@customers, fn {label, _value} -> String.contains?(label, query) end)
      {:reply, %{count: length(found)}, assign(socket, customers: found)}
    end

    def handle_event("reset", _params, socket) do
      {:noreply,
       assign(socket, form: to_form(%{"price" => "1", "customer_id" => "3"}, as: :order))}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="order" phx-change="validate">
        <.number_input field={@form[:price]} label="Price" decimals={2} prefix="R$" steppers />
        <.autocomplete
          field={@form[:customer_id]}
          options={@customers}
          on_search="search"
          no_results="Nobody called %{query}"
        />
      </.form>
      <button id="reset" phx-click="reset">Reset</button>
      """
    end
  end

  test "both fields submit machine values through their hidden inputs", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, OrderLive, session: %{"test" => self()})

    assert find(html, "#order_price") |> LazyHTML.attribute("value") == ["10,50"]
    assert find(html, "input[name='order[price]']") |> LazyHTML.attribute("value") == ["10.50"]
    assert find(html, "#order_customer_id-input") |> LazyHTML.attribute("value") == ["Bruno"]

    view
    |> form("#order")
    |> render_change(%{"order" => %{"price" => "1234.56", "customer_id" => "1"}})

    assert_receive {:changed, %{"price" => "1234.56", "customer_id" => "1"}}

    html = render(view)
    assert find(html, "#order_price-number") |> LazyHTML.attribute("data-value") == ["1234.56"]
    assert find(html, "#order_price") |> LazyHTML.attribute("value") == ["1.234,56"]
    assert find(html, "#order_customer_id") |> LazyHTML.attribute("data-label") == ["Ana"]
  end

  test "on_search narrows the options from the server", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OrderLive, session: %{"test" => self()})

    html =
      view
      |> element("#order_customer_id")
      |> render_hook("search", %{"id" => "order_customer_id", "query" => "Car"})

    assert find(html, "#order_customer_id .option") |> LazyHTML.attribute("data-value") == ["3"]
  end

  test "a value the server sets reaches both fields", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, OrderLive, session: %{"test" => self()})

    html = view |> element("#reset") |> render_click()
    assert find(html, "#order_price-number") |> LazyHTML.attribute("data-value") == ["1.00"]
    assert find(html, "#order_customer_id") |> LazyHTML.attribute("data-value") == ["3"]
    assert find(html, "#order_customer_id") |> LazyHTML.attribute("data-label") == ["Carla"]
  end
end
