defmodule LineaUI.Components.TimePickerTest do
  use LineaUI.ComponentCase, async: true

  test "a time with the clock icon and flatpickr's time-only popup" do
    html = render(~H|<.time_picker id="t" name="at" value="13:13" time_24hr minute_step={10} />|)

    assert find(html, "#t[phx-hook='LineaUI.TimePicker'][data-kind=time][data-time24=true]")
           |> Enum.count() == 1

    assert html |> find("#t") |> LazyHTML.attribute("data-minute-step") == ["10"]
    assert html |> find("#t-display") |> LazyHTML.attribute("value") == ["13:13"]
    assert find(html, "input[type=hidden][name=at][value='13:13']") |> Enum.count() == 1
    assert find(html, "#t-calendar.hasTime.noCalendar") |> Enum.count() == 1

    assert html |> find("#t-field svg path") |> LazyHTML.attribute("d") == [
             "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
           ]
  end

  test "a Time value and a 12-hour display format" do
    html =
      render(~H|<.time_picker id="t" name="at" value={~T[15:05:00]} display_format="h:i K" />|)

    assert html |> find("#t-display") |> LazyHTML.attribute("value") == ["3:05 PM"]
    assert find(html, "input[type=hidden][name=at][value='15:05']") |> Enum.count() == 1
  end

  test "limits and an empty value" do
    html =
      render(
        ~H|<.time_picker id="t" name="at" min_time="15:00" max_time="22:30" default_hour={16} />|
      )

    assert find(html, "#t[data-min-time='15:00'][data-max-time='22:30'][data-default-hour='16']")
           |> Enum.count() == 1

    assert find(html, "input[type=hidden][name=at][value='']") |> Enum.count() == 1
  end

  test "the popup is a named dialog and its texts can be set" do
    html = render(~H|<.time_picker id="t" name="t" />|)
    assert html |> find("#t-calendar") |> LazyHTML.attribute("aria-label") == ["Choose time"]
    labels = html |> find("#t") |> LazyHTML.attribute("data-labels") |> hd() |> Jason.decode!()
    assert labels["picker_hour_up"] == "Increase hour"
    assert labels["picker_toggle_period"] == "Toggle AM/PM"

    html =
      render(
        ~H|<.time_picker id="t" name="t" locale="pt_BR" labels={%{picker_minute_up: "Mais minutos"}} />|
      )

    assert html |> find("#t-calendar") |> LazyHTML.attribute("aria-label") == ["Escolher hora"]
    labels = html |> find("#t") |> LazyHTML.attribute("data-labels") |> hd() |> Jason.decode!()
    assert labels["picker_minute_up"] == "Mais minutos"
    assert labels["picker_hour_down"] == "Diminuir hora"
  end
end
