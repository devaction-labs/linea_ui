defmodule LineaUI.Components.ChartTest do
  use LineaUI.ComponentCase, async: true

  test "encodes map options into data-options and wires the hook" do
    html =
      render(~H"""
      <.chart id="sales" options={%{chart: %{type: "bar"}, series: [%{data: [1, 2]}]}} />
      """)

    [root] = find(html, "#sales") |> Enum.to_list()
    assert LazyHTML.attribute(root, "phx-hook") == ["LineaUI.Chart"]

    assert root |> LazyHTML.attribute("data-options") |> hd() |> Jason.decode!() == %{
             "chart" => %{"type" => "bar"},
             "series" => [%{"data" => [1, 2]}]
           }

    assert [_] =
             find(html, "#sales-canvas[phx-update=ignore][data-chart-canvas]") |> Enum.to_list()
  end

  test "passes a JSON string through untouched and merges class" do
    html =
      render(~H"""
      <.chart id="c" options={~s({"chart":{"type":"line"}})} class="h-80" data-test="x" />
      """)

    assert find(html, "#c") |> LazyHTML.attribute("data-options") == [
             ~s({"chart":{"type":"line"}})
           ]

    assert "h-80" in classes(html, "#c")
    assert find(html, "#c") |> LazyHTML.attribute("data-test") == ["x"]
  end

  test "formatters become data-formatters and are omitted when empty" do
    html =
      render(~H"""
      <.chart id="a" options={%{}} formatters={%{"yaxis.labels.formatter" => "thousands"}} />
      <.chart id="b" options={%{}} />
      """)

    assert [json] = find(html, "#a") |> LazyHTML.attribute("data-formatters")
    assert Jason.decode!(json) == %{"yaxis.labels.formatter" => "thousands"}
    assert [] = find(html, "#b[data-formatters]") |> Enum.to_list()
  end

  defp labels(buttons),
    do: buttons |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  test "table_toggle adds a pressed-state Chart / Table switch, and is absent by default" do
    html =
      render(~H"""
      <.chart id="a" options={%{}} />
      <.chart id="b" options={%{}} table_toggle />
      <.chart
        id="c"
        options={%{}}
        table_toggle={%{chart: "Gráfico", table: "Tabela", label: "Visualização"}}
      />
      """)

    assert find(html, "#a [data-chart-view]") |> Enum.to_list() == []

    assert find(html, "#b [data-chart-view] button") |> labels() == ["Chart", "Table"]

    assert find(html, "#b-view") |> LazyHTML.attribute("aria-label") == ["View"]

    assert find(html, "#b-view button") |> LazyHTML.attribute("aria-pressed") == ["true", "false"]
    assert find(html, "#b-view button") |> LazyHTML.attribute("data-value") == ["chart", "table"]

    assert find(html, "#c-view") |> LazyHTML.attribute("aria-label") == ["Visualização"]
    assert find(html, "#c-view button") |> labels() == ["Gráfico", "Tabela"]

    assert find(html, "#c-canvas[phx-update=ignore]") |> Enum.to_list() |> length() == 1
  end

  test "table_toggle takes a class for the row of the switch, replacing the default margin" do
    html =
      render(~H"""
      <.chart id="a" options={%{}} table_toggle />
      <.chart id="b" options={%{}} table_toggle={%{class: "absolute top-4 right-5 mb-0"}} />
      """)

    [default] = find(html, "#a [data-chart-view]") |> LazyHTML.attribute("class")
    [placed] = find(html, "#b [data-chart-view]") |> LazyHTML.attribute("class")
    assert default =~ "mb-2"
    assert placed =~ "absolute top-4 right-5"
    refute placed =~ "mb-2"
  end

  test "summary adds a quiet header line, on_cursor names the pushed event, both off by default" do
    html =
      render(~H"""
      <.chart id="a" options={%{}} />
      <.chart id="b" options={%{}} summary on_cursor="cursor" />
      """)

    assert find(html, "#a-summary") |> Enum.to_list() == []
    assert find(html, "#a[data-on-cursor]") |> Enum.to_list() == []

    assert find(html, "#b-summary[data-chart-summary][aria-live=off][phx-update=ignore]")
           |> Enum.to_list()
           |> length() == 1

    assert find(html, "#b") |> LazyHTML.attribute("data-on-cursor") == ["cursor"]
  end
end

defmodule LineaUI.Components.ChartLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule ChartLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket), do: {:ok, assign(socket, data: [1, 2, 3])}

    def handle_event("grow", _params, socket),
      do: {:noreply, update(socket, :data, &(&1 ++ [length(&1) + 1]))}

    def handle_event("stream", _params, socket),
      do: {:noreply, push_event(socket, "linea:chart", %{id: "live", series: [%{data: [9]}]})}

    def render(assigns) do
      ~H"""
      <.chart id="live" options={%{chart: %{type: "line"}, series: [%{data: @data}]}} />
      <button id="grow" phx-click="grow">grow</button>
      <button id="stream" phx-click="stream">stream</button>
      """
    end
  end

  defp series(html) do
    html
    |> find("#live")
    |> LazyHTML.attribute("data-options")
    |> hd()
    |> Jason.decode!()
    |> get_in(["series", Access.at(0), "data"])
  end

  test "options follow the assign so the hook's updated/0 redraws", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, ChartLive)
    assert series(html) == [1, 2, 3]
    assert view |> element("#grow") |> render_click() |> series() == [1, 2, 3, 4]
  end

  test "series can be pushed to the hook without re-rendering", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ChartLive)
    view |> element("#stream") |> render_click()
    assert_push_event(view, "linea:chart", %{id: "live", series: [%{data: [9]}]})
  end
end
