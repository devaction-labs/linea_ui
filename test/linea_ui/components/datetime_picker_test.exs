defmodule LineaUI.Components.DatetimePickerTest do
  use LineaUI.ComponentCase, async: true

  defp data(html, selector, key), do: html |> find(selector) |> LazyHTML.attribute(key)

  test "a single picker: hook, data, display input and the hidden wall-clock value" do
    html =
      render(
        ~H|<.datetime_picker id="d" name="at" value={~N[2026-10-14 10:30:00]} placeholder="Pick one" />|
      )

    assert find(
             html,
             "#d[phx-hook='LineaUI.DatetimePicker'][data-mode=single][data-time-mode=list]"
           )
           |> Enum.count() == 1

    assert data(html, "#d", "data-value") == [~s(["2026-10-14T10:30"])]
    assert data(html, "#d", "data-interval") == ["30"]
    assert data(html, "#d", "data-hour12") == ["true"]
    assert data(html, "#d", "data-name") == ["at"]

    display = find(html, "#d-display[readonly][data-display]")
    assert LazyHTML.attribute(display, "value") == ["Oct 14, 2026, 10:30 AM"]
    assert LazyHTML.attribute(display, "placeholder") == ["Pick one"]
    assert LazyHTML.attribute(display, "aria-haspopup") == ["dialog"]
    assert LazyHTML.attribute(display, "aria-controls") == ["d-panel"]
    assert "pl-9" in classes(html, "#d-display")

    assert html |> find("input[type=hidden][name=at]") |> LazyHTML.attribute("value") == [
             "2026-10-14T10:30"
           ]

    assert find(html, "#d-panel[popover=manual][role=dialog][data-panel][phx-update=ignore]")
           |> Enum.count() == 1

    assert find(html, "#d-panel [data-surface]") |> Enum.count() == 1
    assert find(html, "#d-field span svg") |> Enum.count() == 1
  end

  test "values: strings, structs and bad text, the clock is never converted" do
    for {value, expected} <- [
          {"2026-10-14T10:30", ~s(["2026-10-14T10:30"])},
          {"2026-10-14 10:30", ~s(["2026-10-14T10:30"])},
          {"2026-10-24T09:30:00Z", ~s(["2026-10-24T09:30"])},
          {~U[2026-10-14 23:45:10Z], ~s(["2026-10-14T23:45"])},
          {"2026-10-24 25:99", "[]"},
          {"not a date", "[]"},
          {"2026-02-30T10:00", "[]"},
          {"", "[]"},
          {nil, "[]"},
          {42, "[]"}
        ] do
      assigns = %{value: value, __changed__: nil}
      html = rendered_to_string(~H|<.datetime_picker id="d" name="at" value={@value} />|)
      assert data(html, "#d", "data-value") == [expected], inspect(value)
    end
  end

  test "a day without a time takes the default time, else min_time, else midnight" do
    html =
      render(~H|<.datetime_picker id="d" name="at" value="2026-10-14" default_time="09:30" />|)

    assert data(html, "#d", "data-value") == [~s(["2026-10-14T09:30"])]

    html = render(~H|<.datetime_picker id="d" name="at" value="2026-10-14" min_time="8:00" />|)
    assert data(html, "#d", "data-value") == [~s(["2026-10-14T08:00"])]

    html = render(~H|<.datetime_picker id="d" name="at" value={~D[2026-10-14]} />|)
    assert data(html, "#d", "data-value") == [~s(["2026-10-14T00:00"])]
  end

  test "the clock follows the locale and time_format" do
    html =
      render(~H|<.datetime_picker id="d" name="at" value="2026-10-14T15:05" locale="pt_BR" />|)

    assert data(html, "#d", "data-hour12") == ["false"]
    assert data(html, "#d-display", "value") == ["14/10/2026 15:05"]
    assert data(html, "#d", "data-labels") |> hd() =~ "Selecionar"
    assert data(html, "#d-display", "placeholder") == ["Selecionar data e hora"]

    html =
      render(~H|<.datetime_picker id="d" name="at" value="2026-10-14T15:05" time_format="24" />|)

    assert data(html, "#d-display", "value") == ["Oct 14, 2026, 15:05"]

    html =
      render(
        ~H|<.datetime_picker id="d" name="at" value="2026-10-14T15:05" locale="pt_BR" time_format="12" />|
      )

    assert data(html, "#d-display", "value") == ["14/10/2026 3:05 PM"]
  end

  test "display_format changes only the shown text" do
    html =
      render(
        ~H|<.datetime_picker id="d" name="at" value="2026-10-14T09:05" display_format="l, F j, G:i" />|
      )

    assert data(html, "#d-display", "value") == ["Wednesday, October 14, 9:05"]
    assert data(html, "input[type=hidden][name=at]", "value") == ["2026-10-14T09:05"]
  end

  test "a range submits name[] twice behind an empty one and shows both ends" do
    html =
      render(~H|<.datetime_picker
  id="r"
  name="shift"
  mode="range"
  value={{~N[2026-10-14 09:00:00], ~N[2026-10-20 17:30:00]}}
  default_time="09:00/17:00"
/>|)

    assert data(html, "#r", "data-mode") == ["range"]
    assert data(html, "#r", "data-name") == ["shift[]"]
    assert data(html, "#r", "data-value") == [~s(["2026-10-14T09:00","2026-10-20T17:30"])]
    assert data(html, "#r", "data-default-time") == ["09:00/17:00"]
    assert data(html, "#r-display", "value") == ["Oct 14, 2026, 9:00 AM – Oct 20, 2026, 5:30 PM"]
    assert data(html, "#r-display", "placeholder") == ["Select date range"]

    assert html |> find("input[type=hidden][name='shift[]']") |> LazyHTML.attribute("value") ==
             ["", "2026-10-14T09:00", "2026-10-20T17:30"]
  end

  test "a range with only one end shows nothing and a range takes a list or a Date.Range of days" do
    html =
      render(~H|<.datetime_picker id="r" name="s" mode="range" value={["2026-10-14T09:00"]} />|)

    assert data(html, "#r-display", "value") == [""]

    html =
      render(~H|<.datetime_picker
  id="r"
  name="s"
  mode="range"
  value={Date.range(~D[2026-11-02], ~D[2026-11-06])}
  default_time="08:00/18:00"
/>|)

    assert data(html, "#r", "data-value") == [~s(["2026-11-02T08:00","2026-11-06T18:00"])]
  end

  test "start_name and end_name submit the ends as two fields" do
    html =
      render(~H|<.datetime_picker
  id="r"
  start_name="from"
  end_name="to"
  value={["2026-10-14T09:00", "2026-10-20T17:00"]}
/>|)

    assert data(html, "#r", "data-mode") == ["range"]
    assert data(html, "#r", "data-start-name") == ["from"]
    assert data(html, "#r", "data-end-name") == ["to"]
    assert data(html, "input[type=hidden][name=from]", "value") == ["2026-10-14T09:00"]
    assert data(html, "input[type=hidden][name=to]", "value") == ["2026-10-20T17:00"]
    assert find(html, "input[type=hidden][name='from[]']") |> Enum.count() == 0
  end

  test "start_field and end_field wire two form fields" do
    assigns = %{
      __changed__: nil,
      form:
        Phoenix.Component.to_form(%{"from" => "2026-10-14T09:00", "to" => "2026-10-20T17:00"},
          as: :trip
        )
    }

    html =
      rendered_to_string(
        ~H|<.datetime_picker start_field={@form[:from]} end_field={@form[:to]} label="Window" />|
      )

    assert data(html, "#trip_from_range", "data-mode") == ["range"]
    assert data(html, "input[type=hidden][name='trip[from]']", "value") == ["2026-10-14T09:00"]
    assert data(html, "input[type=hidden][name='trip[to]']", "value") == ["2026-10-20T17:00"]
  end

  test "field wiring, label, help and errors" do
    assigns = %{
      __changed__: nil,
      form: Phoenix.Component.to_form(%{"at" => "2026-10-14T10:30"}, as: :event)
    }

    html =
      rendered_to_string(
        ~H|<.datetime_picker field={@form[:at]} label="Starts at" help="Local time" errors={["is late"]} />|
      )

    assert data(html, "#event_at", "data-name") == ["event[at]"]
    assert data(html, "input[type=hidden][name='event[at]']", "value") == ["2026-10-14T10:30"]
    assert html |> find("#event_at-label") |> LazyHTML.text() =~ "Starts at"
    assert data(html, "#event_at-display", "aria-labelledby") == ["event_at-label"]
    assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "Local time"
    assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "is late"
    assert data(html, "#event_at-display", "aria-invalid") == ["true"]
    assert "border-error" in classes(html, "#event_at-display")
  end

  test "the panel and the status region are not inside a label" do
    html = render(~H|<.datetime_picker id="d" name="at" label="At" />|)
    assert find(html, "label #d-panel") |> Enum.count() == 0
    assert find(html, "label") |> Enum.count() == 0
    assert find(html, "#d [role=status][aria-live=polite][data-status]") |> Enum.count() == 1
  end

  test "interval, time, restrictions and the week are handed to the hook" do
    html =
      render(~H|<.datetime_picker
  id="d"
  name="at"
  interval={15}
  time="input"
  min="now"
  max={~D[2026-12-31]}
  min_time="08:00"
  max_time="18:30"
  week_start={1}
  today={~D[2026-10-14]}
  unavailable="2026-10-20, 12:00-13:00 , 2026-10-21T10:00"
/>|)

    assert data(html, "#d", "data-interval") == ["15"]
    assert data(html, "#d", "data-time-mode") == ["input"]
    assert data(html, "#d", "data-min") == ["now"]
    assert data(html, "#d", "data-max") == ["2026-12-31"]
    assert data(html, "#d", "data-min-time") == ["08:00"]
    assert data(html, "#d", "data-max-time") == ["18:30"]
    assert data(html, "#d", "data-week-start") == ["1"]
    assert data(html, "#d", "data-today") == ["2026-10-14"]

    assert data(html, "#d", "data-unavailable") == [
             ~s(["2026-10-20","12:00-13:00","2026-10-21T10:00"])
           ]
  end

  test "unavailable takes a list of dates, date-times and time ranges" do
    html =
      render(~H|<.datetime_picker
  id="d"
  name="at"
  unavailable={[
    ~D[2026-10-20],
    ~N[2026-10-21 10:00:00],
    {~T[12:00:00], ~T[13:00:00]},
    "2026-10-22, 22:00-02:00",
    :junk
  ]}
  max={~N[2026-12-31 18:00:00]}
/>|)

    assert data(html, "#d", "data-unavailable") == [
             ~s(["2026-10-20","2026-10-21T10:00","12:00-13:00","2026-10-22","22:00-02:00"])
           ]

    assert data(html, "#d", "data-max") == ["2026-12-31T18:00"]
  end

  test "no today means the browser's day" do
    html = render(~H|<.datetime_picker id="d" name="at" />|)
    assert data(html, "#d", "data-today") == []
  end

  test "variant, size, icon and class on the input" do
    html =
      render(~H|<.datetime_picker id="d" name="at" variant="filled" size="lg" class="w-64" />|)

    assert "bg-slate-150" in classes(html, "#d-display")
    assert "h-12" in classes(html, "#d-display")
    assert "w-64" in classes(html, "#d-display")

    html = render(~H|<.datetime_picker id="d" name="at" show_icon={false} />|)
    refute "pl-9" in classes(html, "#d-display")
    assert find(html, "#d-field span") |> Enum.count() == 0

    html =
      render(~H"""
      <.datetime_picker id="d" name="at">
        <:icon><i id="mine"></i></:icon>
      </.datetime_picker>
      """)

    assert find(html, "#d-field span #mine") |> Enum.count() == 1
  end

  test "disabled disables the input and the hidden fields" do
    html = render(~H|<.datetime_picker id="d" name="at" value="2026-10-14T10:30" disabled />|)
    assert data(html, "#d", "data-disabled") == ["true"]
    assert data(html, "#d-display", "disabled") == [""]
    assert html |> find("input[type=hidden]") |> LazyHTML.attribute("disabled") == [""]
  end

  test "the trigger slot replaces the input and keeps the hidden value" do
    html =
      render(~H"""
      <.datetime_picker id="d" name="at" value="2026-10-14T10:30">
        <:trigger><button type="button" id="mine">Pick</button></:trigger>
      </.datetime_picker>
      """)

    assert find(html, "#d [data-trigger] #mine") |> Enum.count() == 1
    assert find(html, "#d-display") |> Enum.count() == 0
    assert data(html, "input[type=hidden][name=at]", "value") == ["2026-10-14T10:30"]
    assert find(html, "#d-panel") |> Enum.count() == 1
  end

  test "the panel opens on the chosen side and flips to the other" do
    html =
      render(~H|<.datetime_picker id="d" name="at" placement="top-end" on_change="changed" />|)

    assert data(html, "#d", "data-placement") == ["top-end"]
    assert data(html, "#d", "data-fallbacks") == ["bottom-end"]
    assert data(html, "#d", "data-on-change") == ["changed"]
    assert data(html, "#d", "data-offset") == ["6"]
  end

  test "labels override the words of the panel" do
    html =
      render(
        ~H|<.datetime_picker id="d" name="at" mode="range" labels={%{datetime_select_range: "Apply"}} />|
      )

    labels = html |> data("#d", "data-labels") |> hd() |> Jason.decode!()
    assert labels["datetime_select_range"] == "Apply"
    assert labels["datetime_start"] == "Start"
    assert Map.keys(labels) |> Enum.all?(&String.starts_with?(&1, "datetime_"))
  end

  test "the panel is announced as a dialog with a name, per mode and locale" do
    html = render(~H|<.datetime_picker id="d" name="at" />|)
    assert data(html, "#d-panel", "aria-label") == ["Choose date and time"]

    html = render(~H|<.datetime_picker id="d" name="at" mode="range" locale="pt_BR" />|)
    assert data(html, "#d-panel", "aria-label") == ["Escolher período com data e hora"]
  end

  test "the old date_picker no longer defines datetime_picker" do
    refute function_exported?(LineaUI.Components.DatePicker, :datetime_picker, 1)
    assert function_exported?(LineaUI.Components.DatetimePicker, :datetime_picker, 1)
  end

  test "the attributes of the former picker still work" do
    html =
      render(~H"""
      <.datetime_picker id="old" name="old" time_24hr minute_step={5} default_hour={9} />
      """)

    assert data(html, "#old", "data-interval") == ["5"]
    assert data(html, "#old", "data-default-time") == ["09:00"]
    assert data(html, "#old", "data-hour12") == ["false"]
  end
end
