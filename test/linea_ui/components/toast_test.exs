defmodule LineaUI.Components.ToastTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.Toast
  alias Phoenix.LiveView.JS

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the toaster carries the toasts of the flash and its defaults" do
    flash = %{"linea_toast" => [%{"id" => "t1", "message" => "Saved", "color" => "success"}]}
    assigns = %{flash: flash}

    html =
      Phoenix.LiveViewTest.rendered_to_string(~H"""
      <.toaster flash={@flash} position="center-top" duration={3000} />
      """)

    assert attr_of(html, "#linea-toaster", "phx-hook") == ["LineaUI.Toast"]
    assert attr_of(html, "#linea-toaster", "phx-update") == ["ignore"]
    assert attr_of(html, "#linea-toaster", "data-position") == ["center-top"]
    assert attr_of(html, "#linea-toaster", "data-duration") == ["3000"]
    assert [json] = attr_of(html, "#linea-toaster", "data-flash")
    assert [%{"message" => "Saved", "color" => "success"}] = Jason.decode!(json)
  end

  test "the toaster stacks its toasts unless told not to" do
    assigns = %{}
    stacked = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster />")
    open = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster stack={false} />")

    assert attr_of(stacked, "#linea-toaster", "data-stack") == ["true"]
    assert attr_of(open, "#linea-toaster", "data-stack") == ["false"]
  end

  test "put_toast piles toasts up in the flash of a conn" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Phoenix.Controller.fetch_flash()
      |> Toast.put_toast("One", color: "info", position: "left-top", duration: 3000)
      |> Toast.put_toast("Two", close: true)

    assert [one, two] = Phoenix.Flash.get(conn.assigns.flash, "linea_toast")

    assert %{"message" => "One", "color" => "info", "position" => "left-top", "duration" => 3000} =
             one

    assert %{"message" => "Two", "color" => "neutral", "close" => true} = two
  end

  test "show_toast dispatches to the toaster" do
    %JS{ops: [["dispatch", args]]} = Toast.show_toast("Hi", color: "primary")
    assert args.event == "linea:toast"
    assert args.to == "[data-linea-toaster]"
    assert %{"message" => "Hi", "color" => "primary"} = args.detail

    %JS{ops: [_, ["dispatch", _]]} = Toast.show_toast(JS.push("x"), "Hi")
  end

  test "an unknown color or position is refused" do
    assert_raise ArgumentError, ~r/color/, fn -> Toast.payload("x", color: "purple") end
    assert_raise ArgumentError, ~r/position/, fn -> Toast.payload("x", position: "middle") end
  end
end
