defmodule LineaUI.Components.TimerTest do
  use LineaUI.ComponentCase, async: true

  alias Phoenix.LiveView.JS

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp text_of(html, selector),
    do: html |> find(selector) |> LazyHTML.text() |> String.split() |> Enum.join(" ")

  test "a timer with the hook, a name and the data the hook reads" do
    html = render(~H|<.timer id="shift" elapsed={11565} label="Register 01 · Ana Souza" />|)

    assert attr_of(html, "#shift", "role") == ["timer"]
    assert attr_of(html, "#shift", "aria-label") == ["Register 01 · Ana Souza"]
    assert attr_of(html, "#shift", "phx-hook") == ["LineaUI.Timer"]
    assert attr_of(html, "#shift", "data-elapsed") == ["11565"]
    assert attr_of(html, "#shift", "data-total") == ["28800"]
    assert attr_of(html, "#shift", "data-running") == ["true"]
    assert attr_of(html, "#shift", "data-direction") == ["up"]
    assert attr_of(html, "#shift", "data-format") == ["hms"]
    assert attr_of(html, "#shift", "data-state") == ["running"]
    assert attr_of(html, "#shift", "data-stop-at-total") == ["false"]
    assert "group" in classes(html, "#shift")
    assert "timer-checker" in classes(html, "#shift")
  end

  test "the accessible name falls back to Timer and aria-label from the caller wins" do
    assert render(~H|<.timer id="a" />|) |> attr_of("#a", "aria-label") == ["Timer"]

    html = render(~H|<.timer id="a" label="Shown" aria-label="Spoken" />|)
    assert attr_of(html, "#a", "aria-label") == ["Spoken"]
  end

  test "the ticking text is not a live region" do
    html = render(~H|<.timer id="a" kicker="Open" />|)

    assert find(html, "[aria-live]") |> Enum.to_list() == []
    assert attr_of(html, "svg", "aria-hidden") == ["true"]
  end

  test "the time is drawn hh:mm:ss, hm for the short form" do
    ring = render(~H|<.timer id="a" elapsed={11565} />|)
    assert text_of(ring, "[data-time]") == "03:12:45"

    short = render(~H|<.timer id="a" elapsed={11565} format="hm" />|)
    assert text_of(short, "[data-time]") == "3h12"
    assert attr_of(short, "#a", "data-format") == ["hm"]

    clock = render(~H|<.timer id="a" elapsed={11565} format="hh:mm" />|)
    assert text_of(clock, "[data-time]") == "03:12"
    assert attr_of(clock, "#a", "data-format") == ["hh:mm"]

    assert render(~H|<.timer id="a" elapsed={0} />|) |> text_of("[data-time]") == "00:00:00"
    assert render(~H|<.timer id="a" elapsed={-9} />|) |> text_of("[data-time]") == "00:00:00"
  end

  test "counting down shows what is left, never below zero" do
    left = render(~H|<.timer id="a" direction="down" total={900} elapsed={60} />|)
    assert text_of(left, "[data-time]") == "00:14:00"
    assert attr_of(left, "#a", "data-direction") == ["down"]

    over = render(~H|<.timer id="a" direction="down" total={900} elapsed={1000} />|)
    assert text_of(over, "[data-time]") == "00:00:00"
  end

  test "the ring is a circle of 326.7 and the arc is the elapsed fraction" do
    quarter = render(~H|<.timer id="a" elapsed={7200} />|)

    assert attr_of(quarter, "circle[data-ring]", "stroke-dasharray") == ["326.7"]
    assert attr_of(quarter, "circle[data-ring]", "stroke-dashoffset") == ["245.0"]
    assert attr_of(quarter, "circle[data-ring]", "stroke-linecap") == ["round"]
    assert attr_of(quarter, "circle[data-ring]", "r") == ["52"]
    assert attr_of(quarter, "svg", "viewBox") == ["0 0 120 120"]

    empty = render(~H|<.timer id="a" elapsed={0} />|)
    assert attr_of(empty, "circle[data-ring]", "stroke-dashoffset") == ["326.7"]

    full = render(~H|<.timer id="a" elapsed={99999} />|)
    assert attr_of(full, "circle[data-ring]", "stroke-dashoffset") == ["0.0"]
  end

  test "counting down the arc empties as time passes" do
    html = render(~H|<.timer id="a" direction="down" total={800} elapsed={200} />|)

    assert attr_of(html, "circle[data-ring]", "stroke-dashoffset") == ["81.7"]
  end

  test "a total of zero draws an empty ring" do
    html = render(~H|<.timer id="a" total={0} elapsed={5} />|)

    assert attr_of(html, "circle[data-ring]", "stroke-dashoffset") == ["326.7"]
  end

  test "the state decides the kicker and the data the hook starts from" do
    running = render(~H|<.timer id="a" kicker="Open" kicker_paused="Paused" />|)
    assert text_of(running, "[data-kicker-text]") == "Open"
    assert attr_of(running, "#a", "data-kicker") == ["Open"]
    assert attr_of(running, "#a", "data-kicker-paused") == ["Paused"]

    paused = render(~H|<.timer id="a" running={false} kicker="Open" kicker_paused="Paused" />|)
    assert text_of(paused, "[data-kicker-text]") == "Paused"
    assert attr_of(paused, "#a", "data-state") == ["paused"]
    assert attr_of(paused, "#a", "data-running") == ["false"]

    same = render(~H|<.timer id="a" running={false} kicker="Open" />|)
    assert text_of(same, "[data-kicker-text]") == "Open"

    none = render(~H|<.timer id="a" />|)
    assert find(none, "[data-kicker-text]") |> Enum.to_list() == []
  end

  test "the ring and the kicker take their colors from the state" do
    html = render(~H|<.timer id="a" kicker="Open" color="success" />|)

    ring = classes(html, "circle[data-ring]")
    assert "group-data-[state=running]:stroke-success" in ring
    assert "group-data-[state=paused]:stroke-warning-focus" in ring

    kicker = classes(html, "[data-kicker-text]")
    assert "group-data-[state=running]:text-success-focus" in kicker
    assert "group-data-[state=paused]:text-warning-focus" in kicker

    primary = render(~H|<.timer id="a" />|) |> classes("circle[data-ring]")
    assert "group-data-[state=running]:stroke-primary" in primary
    assert "dark:group-data-[state=running]:stroke-accent" in primary
  end

  test "sizes change the ring and the type" do
    sm = render(~H|<.timer id="a" size="sm" kicker="K" />|)
    assert "size-32" in classes(sm, "#a > div > div")
    assert "text-base" in classes(sm, "[data-time]")

    md = render(~H|<.timer id="a" kicker="K" />|)
    assert "size-42" in classes(md, "#a > div > div")
    assert "text-[22px]" in classes(md, "[data-time]")

    lg = render(~H|<.timer id="a" size="lg" kicker="K" />|)
    assert "size-52" in classes(lg, "#a > div > div")
    assert "text-[28px]" in classes(lg, "[data-time]")
  end

  test "label and caption lines" do
    assert render(~H|<.timer id="a" label="Register 01" />|) |> text_of("#a") =~ "Register 01"

    html =
      render(~H"""
      <.timer id="a" label="Register 01">
        <:caption><b>Custom</b></:caption>
      </.timer>
      """)

    assert text_of(html, "#a b") == "Custom"
    assert attr_of(html, "#a", "aria-label") == ["Register 01"]

    bare = render(~H|<.timer id="a" />|)
    assert find(bare, "span.font-inter") |> Enum.to_list() == []
  end

  test "the actions slot holds the caller's controls under the ring" do
    html =
      render(~H"""
      <.timer id="a">
        <:actions>
          <button id="pause">Pause</button>
          <button id="plus">+15 min</button>
        </:actions>
      </.timer>
      """)

    assert [_, _] = find(html, "#a button") |> Enum.to_list()
    assert attr_of(html, "#pause", "id") == ["pause"]

    bare = render(~H|<.timer id="a" />|)
    assert find(bare, "#a button") |> Enum.to_list() == []
  end

  test "the mini timer is a pill with a dot and the short time" do
    html = render(~H|<.timer id="m" variant="mini" elapsed={11565} />|)

    assert attr_of(html, "span#m", "role") == ["timer"]
    assert attr_of(html, "#m", "aria-label") == ["Timer"]
    assert attr_of(html, "#m", "phx-hook") == ["LineaUI.Timer"]
    assert attr_of(html, "#m", "data-format") == ["hm"]
    assert text_of(html, "#m [data-time]") == "3h12"
    assert attr_of(html, "#m i", "aria-hidden") == ["true"]
    assert "timer-dot" in classes(html, "#m i")
    assert "h-8" in classes(html, "#m")
    assert "font-mono" in classes(html, "#m")
    assert find(html, "#m svg") |> Enum.to_list() == []
  end

  test "the mini timer can show seconds, has sizes and a paused state" do
    html = render(~H|<.timer id="m" variant="mini" format="hms" size="sm" running={false} />|)

    assert text_of(html, "#m [data-time]") == "00:00:00"
    assert attr_of(html, "#m", "data-state") == ["paused"]
    assert "h-6.5" in classes(html, "#m")
    assert "h-10" in classes(render(~H|<.timer id="m" variant="mini" size="lg" />|), "#m")
  end

  test "events become %JS{} in data attributes, with the target" do
    html =
      render(~H"""
      <.timer
        id="a"
        on_toggle="toggled"
        on_tick="ticked"
        on_finish={JS.push("done")}
        target="#panel"
      />
      """)

    assert [toggle] = attr_of(html, "#a", "data-on-toggle")
    assert toggle =~ "toggled"
    assert toggle =~ "#panel"
    assert toggle =~ ~s("id":"a")
    assert attr_of(html, "#a", "data-on-tick") |> hd() =~ "ticked"
    assert attr_of(html, "#a", "data-on-finish") |> hd() =~ "done"

    bare = render(~H|<.timer id="a" />|)
    assert attr_of(bare, "#a", "data-on-toggle") == ["[]"]
  end

  test "stop_at_total, class and global attributes" do
    html = render(~H|<.timer id="a" stop_at_total class="w-80" data-test="x" />|)

    assert attr_of(html, "#a", "data-stop-at-total") == ["true"]
    assert "w-80" in classes(html, "#a")
    assert attr_of(html, "#a", "data-test") == ["x"]
  end

  describe "LineaUI.Timer commands" do
    test "return a %JS{} that dispatches linea:timer to the timer" do
      assert %JS{ops: [["dispatch", op]]} = LineaUI.Timer.pause("shift")
      assert op == %{event: "linea:timer", to: "#shift", detail: %{action: "pause"}}

      assert %JS{ops: [["dispatch", %{detail: %{action: "resume"}}]]} =
               LineaUI.Timer.resume("#shift")

      assert %JS{ops: [["dispatch", %{detail: %{action: "toggle"}}]]} =
               LineaUI.Timer.toggle("shift")

      assert %JS{ops: [["dispatch", %{to: "#shift", detail: %{action: "add", seconds: 900}}]]} =
               LineaUI.Timer.add("shift", 900)
    end

    test "chain onto a %JS{}" do
      js = JS.push("clicked") |> LineaUI.Timer.add("shift", -60)

      assert %JS{ops: [["push", _], ["dispatch", %{detail: %{seconds: -60}}]]} = js
    end

    test "work on a socket as a push event" do
      socket = %Phoenix.LiveView.Socket{}

      assert %Phoenix.LiveView.Socket{} = LineaUI.Timer.pause(socket, "shift")
      assert %Phoenix.LiveView.Socket{} = LineaUI.Timer.add(socket, "shift", 30)
    end
  end
end
