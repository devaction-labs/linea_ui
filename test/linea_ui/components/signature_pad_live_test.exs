defmodule LineaUI.Components.SignaturePadLiveTest do
  use LineaUI.LiveCase, async: true

  @svg ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 170"><path d="M1 2L3 4"/></svg>)

  defmodule ReceiptLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket) do
      {:ok,
       assign(socket,
         form: to_form(%{"signature" => ""}, as: :receipt),
         test: session["test"],
         svg: session["svg"]
       )}
    end

    def handle_event("validate", %{"receipt" => params}, socket) do
      send(socket.assigns.test, {:changed, params})
      {:noreply, assign(socket, form: to_form(params, as: :receipt))}
    end

    def handle_event("saved", params, socket) do
      send(socket.assigns.test, {:saved, params})
      {:noreply, socket}
    end

    def handle_event("load", %{"svg" => svg}, socket),
      do: {:noreply, assign(socket, form: to_form(%{"signature" => svg}, as: :receipt))}

    def render(assigns) do
      ~H"""
      <.form for={@form} id="receipt" phx-change="validate">
        <.signature_pad field={@form[:signature]} on_change="saved" />
      </.form>
      <button id="load" phx-click="load" phx-value-svg={@svg}>Load</button>
      """
    end
  end

  test "phx-change hears the SVG the pad writes into its hidden input", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, ReceiptLive, session: %{"test" => self(), "svg" => @svg})

    assert find(html, "input[name='receipt[signature]']") |> LazyHTML.attribute("value") == [""]

    view |> form("#receipt") |> render_change(%{"receipt" => %{"signature" => @svg}})

    assert_received {:changed, %{"signature" => @svg}}

    assert find(render(view), "#receipt_signature-signature")
           |> LazyHTML.attribute("data-value") == [@svg]
  end

  test "a signature the server sets reaches the pad", %{conn: conn} do
    {:ok, view, _html} =
      live_isolated(conn, ReceiptLive, session: %{"test" => self(), "svg" => @svg})

    view |> element("#load") |> render_click()

    assert find(render(view), "#receipt_signature-signature")
           |> LazyHTML.attribute("data-value") == [@svg]
  end

  test "on_change is wired for the hook to push", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, ReceiptLive, session: %{"test" => self(), "svg" => @svg})

    assert find(html, "#receipt_signature-signature") |> LazyHTML.attribute("data-on-change") == [
             "saved"
           ]
  end
end
