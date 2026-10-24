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

  test "the toaster draws the countdown line by default and can turn it off" do
    assigns = %{}
    on = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster />")
    off = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster timer={false} />")

    assert attr_of(on, "#linea-toaster", "data-timer") == ["true"]
    assert attr_of(off, "#linea-toaster", "data-timer") == ["false"]
  end

  test "a toast carries its own timer choice" do
    assert %{"timer" => false} = LineaUI.Components.Toast.payload("x", timer: false)
    assert %{"timer" => nil} = LineaUI.Components.Toast.payload("x", [])
    assert %{"timer" => false} = LineaUI.Components.Toast.changes("x", timer: false)
  end

  test "the toaster carries an icon template per kind and the persist_errors flag" do
    assigns = %{}
    html = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster persist_errors />")

    kinds =
      html
      |> find("template[data-toast-icon]")
      |> LazyHTML.attribute("data-toast-icon")
      |> Enum.sort()

    assert kinds == ~w(error info loading success warning)
    assert attr_of(html, "#linea-toaster", "data-persist-errors") == ["true"]
  end

  test "a kind gives its color, a description and actions ride along" do
    payload =
      Toast.payload("Sent",
        kind: :success,
        description: "NF-e 1",
        actions: [
          [label: "Open", event: "open", value: %{id: 1}, target: "#c"],
          %{label: "Undo", js: JS.push("undo"), dismiss: false},
          [label: "All", href: "/all"]
        ]
      )

    assert %{"kind" => "success", "color" => "success", "description" => "NF-e 1"} = payload

    assert [
             %{"label" => "Open", "event" => "open", "value" => %{id: 1}, "target" => "#c"},
             %{"label" => "Undo", "js" => %JS{}, "dismiss" => false},
             %{"label" => "All", "href" => "/all", "dismiss" => true}
           ] = payload["actions"]

    assert %{"kind" => "loading", "color" => "neutral"} = Toast.payload("x", kind: "loading")

    assert %{"kind" => "error", "color" => "dark"} =
             Toast.payload("x", kind: :error, color: :dark)

    assert %{"kind" => nil, "actions" => []} = Toast.payload("x", [])
    assert %{"duration" => 0} = Toast.payload("x", duration: :infinity)
  end

  test "an unknown kind or an action without a label is refused" do
    assert_raise ArgumentError, ~r/kind/, fn -> Toast.payload("x", kind: :fancy) end
    assert_raise ArgumentError, ~r/label/, fn -> Toast.payload("x", actions: [[event: "x"]]) end
  end

  test "an update carries only what it changes" do
    assert Toast.changes("t", kind: :success, title: "Done", duration: :infinity) ==
             %{"id" => "t", "kind" => "success", "message" => "Done", "duration" => 0}

    assert %{"actions" => [%{"label" => "Go"}], "close" => true, "color" => "info"} =
             Toast.changes("t", actions: [[label: "Go"]], close: true, color: "info")

    assert %{"message" => "m", "description" => "d"} =
             Toast.changes("t", message: "m", description: "d")

    assert_raise ArgumentError, ~r/position/, fn -> Toast.changes("t", position: "left-top") end
  end

  test "an action takes a variant and a color, and a toast a progress bar" do
    assert [
             %{"variant" => "solid", "color" => nil},
             %{"variant" => "soft", "color" => "error"},
             %{"variant" => nil, "color" => nil}
           ] =
             Toast.payload("x",
               actions: [
                 [label: "A", variant: :solid],
                 [label: "B", variant: "soft", color: :error],
                 [label: "C"]
               ]
             )["actions"]

    assert_raise ArgumentError, ~r/action variant/, fn ->
      Toast.payload("x", actions: [[label: "A", variant: :loud]])
    end

    assert_raise ArgumentError, ~r/action color/, fn ->
      Toast.payload("x", actions: [[label: "A", color: :pink]])
    end

    assert %{"bar" => true} = Toast.payload("x", value: 10, bar: true)
    assert %{"bar" => false} = Toast.payload("x", value: 10)
    assert %{"bar" => true} = Toast.changes("t", bar: true)
  end

  test "an aura and a progress value ride along and are checked" do
    assert %{"aura" => "default", "aura_size" => nil, "aura_color" => nil, "value" => nil} =
             Toast.payload("x", aura: true)

    assert %{"aura" => "glow", "aura_size" => "lg", "aura_color" => "error", "value" => 40} =
             Toast.payload("x", aura: :glow, aura_size: :lg, aura_color: :error, value: 40)

    assert %{"aura" => nil} = Toast.payload("x", aura: false)
    assert_raise ArgumentError, ~r/aura/, fn -> Toast.payload("x", aura: :rainbow) end
    assert_raise ArgumentError, ~r/aura_size/, fn -> Toast.payload("x", aura_size: :xl) end
    assert_raise ArgumentError, ~r/aura_color/, fn -> Toast.payload("x", aura_color: :pink) end
    assert_raise ArgumentError, ~r/value/, fn -> Toast.payload("x", value: "half") end

    assert %{"id" => "t", "value" => 64, "aura" => "dual"} =
             Toast.changes("t", value: 64, aura: :dual)
  end

  test "aura wraps any content in the ring of light" do
    html =
      render(~H"""
      <.aura variant="dual" size="lg" color="success" class="rounded-xl">
        <p>Inside</p>
      </.aura>
      """)

    assert "linea-aura" in classes(html, "div")
    assert "rounded-xl" in classes(html, "div")
    assert attr_of(html, "div", "data-aura") == ["dual"]
    assert attr_of(html, "div", "data-aura-size") == ["lg"]
    assert attr_of(html, "div", "data-aura-color") == ["success"]
    assert [_] = find(html, "p") |> Enum.to_list()
  end

  test "dismiss_toast and clear_toasts dispatch to the toaster in the browser" do
    %JS{ops: [["dispatch", one]]} = Toast.dismiss_toast("t")
    assert one.event == "linea:toast-dismiss"
    assert one.to == "[data-linea-toaster]"
    assert one.detail == %{"id" => "t"}

    %JS{ops: [["dispatch", all]]} = Toast.clear_toasts()
    assert all.detail == %{"all" => true}

    %JS{ops: [_, ["dispatch", _]]} = Toast.dismiss_toast(JS.push("x"), "t")
    %JS{ops: [_, ["dispatch", _]]} = Toast.clear_toasts(JS.push("x"))
  end
end
