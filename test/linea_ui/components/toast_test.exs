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

  test "the toaster and a toast can invert the colors" do
    assigns = %{}
    on = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster invert />")
    off = Phoenix.LiveViewTest.rendered_to_string(~H"<.toaster />")

    assert attr_of(on, "#linea-toaster", "data-invert") == ["true"]
    assert attr_of(off, "#linea-toaster", "data-invert") == ["false"]
    assert %{"invert" => true} = LineaUI.Components.Toast.payload("x", invert: true)
    assert %{"invert" => nil} = LineaUI.Components.Toast.payload("x", [])
    assert %{"invert" => false} = LineaUI.Components.Toast.changes("x", invert: false)
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

    assert %{"aura_size" => "default"} = Toast.payload("x", aura: true, aura_size: :default)

    for size <- ~w(xs sm default lg)a,
        do: assert(%{"aura_size" => _} = Toast.payload("x", aura: true, aura_size: size))

    assert %{"aura" => nil} = Toast.payload("x", aura: false)
    assert_raise ArgumentError, ~r/aura/, fn -> Toast.payload("x", aura: :rainbow) end
    assert_raise ArgumentError, ~r/aura_size/, fn -> Toast.payload("x", aura_size: :xl) end
    assert_raise ArgumentError, ~r/aura_color/, fn -> Toast.payload("x", aura_color: :pink) end
    assert_raise ArgumentError, ~r/value/, fn -> Toast.payload("x", value: "half") end

    assert %{"id" => "t", "value" => 64, "aura" => "dual"} =
             Toast.changes("t", value: 64, aura: :dual)
  end

  test "a toast in steps carries steps and step, checked" do
    assert %{"steps" => 5, "step" => 2} = Toast.payload("Batch", id: "b", steps: 5, step: 2)
    assert %{"steps" => nil, "step" => nil} = Toast.payload("x", [])
    assert %{"id" => "b", "step" => 3} = Toast.changes("b", step: 3)
    assert %{"steps" => 4} = Toast.changes("b", steps: 4)
    assert_raise ArgumentError, ~r/steps/, fn -> Toast.payload("x", steps: 0) end
    assert_raise ArgumentError, ~r/steps/, fn -> Toast.payload("x", steps: "5") end
    assert_raise ArgumentError, ~r/step/, fn -> Toast.payload("x", steps: 5, step: -1) end
    assert_raise ArgumentError, ~r/step/, fn -> Toast.changes("b", step: 1.5) end
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

  describe "toast_card/1" do
    test "the canvas toast card with its tile, texts, actions and close button" do
      html =
        render(~H"""
        <.toast_card
          id="t"
          kind="error"
          icon="huge-cancel-circle"
          title="Não foi possível emitir"
          description="SEFAZ fora do ar."
          close_label="Fechar"
        >
          <:action><button id="undo">Desfazer</button></:action>
        </.toast_card>
        """)

      assert "sg-toast" in classes(html, "#t")
      refute "dark" in classes(html, "#t")
      assert "neg" in classes(html, "#t .sg-ic")
      assert [_] = find(html, "#t .sg-ic span.huge-cancel-circle") |> Enum.to_list()
      assert find(html, "#t .t") |> LazyHTML.text() == "Não foi possível emitir"
      assert find(html, "#t .sg-toast-desc") |> LazyHTML.text() == "SEFAZ fora do ar."
      assert [_] = find(html, "#t > #undo") |> Enum.to_list()
      assert find(html, "#t > button.sg-ib") |> LazyHTML.attribute("aria-label") == ["Fechar"]
    end

    test "the dark tone, no description and no close button" do
      html = render(~H|<.toast_card id="t" tone="dark" title="Excluído" dismissible={false} />|)
      assert "dark" in classes(html, "#t")
      assert find(html, "#t .sg-toast-desc") |> Enum.empty?()
      assert find(html, "#t button") |> Enum.empty?()
    end

    test "an aura wraps the card in the canvas ring" do
      html =
        render(~H"""
        <.toast_card id="t" aura="dual" aura_tone="ai" aura_width="lg" title="Pronto" dismissible={false} />
        """)

      aura = classes(html, "div.sg-aura")
      for c <- ~w(sg-aura sg-aura-shadow ai dual lg), do: assert(c in aura)
      assert [_] = find(html, ".sg-aura > #t.sg-toast") |> Enum.to_list()
    end

    test "no aura leaves the card alone, and busy puts a spinner" do
      html = render(~H|<.toast_card id="t" busy title="Lendo" dismissible={false} />|)
      assert find(html, ".sg-aura") |> Enum.empty?()
      assert [_] = find(html, "#t > .sg-spin") |> Enum.to_list()
    end

    test "a progress toast fills up to the percentage, with spinner and label" do
      html = render(~H|<.toast_card id="t" progress={42} title="Emitindo" dismissible={false} />|)
      assert "prog" in classes(html, "#t")
      assert find(html, "#t") |> LazyHTML.attribute("style") == ["--p:42%"]
      assert find(html, "#t .pct") |> LazyHTML.text() == "42%"
      assert [_] = find(html, "#t > .sg-spin") |> Enum.to_list()
    end

    test "a done progress toast is complete without spinner; a failed one shows neither percentage nor spinner" do
      done =
        render(
          ~H|<.toast_card id="t" progress={100} progress_state="done" title="Ok" dismissible={false} />|
        )

      assert "done" in classes(done, "#t")
      assert find(done, "#t .pct") |> LazyHTML.text() == "100%"
      assert find(done, "#t > .sg-spin") |> Enum.empty?()

      fail =
        render(
          ~H|<.toast_card id="t" progress={64} progress_state="fail" title="Falhou" dismissible={false} />|
        )

      assert "fail" in classes(fail, "#t")
      assert find(fail, "#t .pct") |> Enum.empty?()
      assert find(fail, "#t > .sg-spin") |> Enum.empty?()
    end
  end

  describe "status_toast/1" do
    test "the compact inverse card with its circle, message and buttons" do
      html =
        render(~H"""
        <.status_toast id="s" state="ok">
          Deploy <b>f798c00</b>
          published
          <:action ghost>Logs</:action>
          <:action>Open</:action>
        </.status_toast>
        """)

      assert "sg-toast" in classes(html, "#s")
      assert "st" in classes(html, "#s")
      assert "ok" in classes(html, "#s > .sg-st")
      assert find(html, "#s .msg b") |> LazyHTML.text() == "f798c00"
      assert [_, _] = find(html, "#s > button.act") |> Enum.to_list()
      assert [_] = find(html, "#s > button.act.ghost") |> Enum.to_list()
    end

    test "a running circle takes the percentage; the default state has no extra class" do
      html = render(~H|<.status_toast id="s" percent={42}>Importando</.status_toast>|)
      assert classes(html, "#s > .sg-st") == ["sg-st"]
      assert find(html, "#s > .sg-st") |> LazyHTML.attribute("style") == ["--stp:42%"]
    end
  end

  test "payload and update carry the status and reject an unknown one" do
    assert Toast.payload("x", status: :run, value: 42)["status"] == "run"
    assert Toast.payload("x", [])["status"] == "ok"
    assert Toast.changes("a", status: :ok)["status"] == "ok"

    assert Toast.payload("x", actions: [[label: "Logs", variant: :ghost]])["actions"]
           |> hd()
           |> Map.get("variant") == "ghost"

    assert_raise ArgumentError, fn -> Toast.payload("x", status: :weird) end
  end

  describe "default look" do
    test "a plain toast is a status card, by kind" do
      assert Toast.payload("Saved.", kind: :success)["status"] == "ok"
      assert Toast.payload("Saved.", kind: :info)["status"] == "ok"
      assert Toast.payload("Failed.", kind: :error)["status"] == "err"
      assert Toast.payload("Careful.", kind: :warning)["status"] == "err"
      assert Toast.payload("Working.", kind: :loading)["status"] == "run"
    end

    test "rich toasts keep their card" do
      assert Toast.payload("x", description: "more")["status"] == nil
      assert Toast.payload("x", aura: true)["status"] == nil
      assert Toast.payload("x", value: 10)["status"] == nil
    end
  end

  describe "status_toast/1 actions as links" do
    test "href, navigate and patch render links; id goes on both" do
      html =
        render(~H"""
        <.status_toast id="s">
          Building
          <:action id="toast-logs" patch="/logs" ghost>Logs</:action>
          <:action id="toast-open" href="/app">Open</:action>
          <:action id="toast-hide" on_click="hide">Hide</:action>
        </.status_toast>
        """)

      assert ["/logs"] == html |> find("a#toast-logs.act.ghost") |> LazyHTML.attribute("href")
      assert ["/app"] == html |> find("a#toast-open") |> LazyHTML.attribute("href")
      assert [_] = find(html, "button#toast-hide.act") |> Enum.to_list()
    end
  end
end
