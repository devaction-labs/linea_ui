defmodule LineaUI.Components.DatePickerTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.DatePicker.Shell

  test "a single date: the input, the icon, the hidden input and the calendar" do
    html =
      render(
        ~H|<.date_picker id="d" name="due" value={~D[2026-10-03]} placeholder="Choose date..." />|
      )

    assert find(html, "#d[phx-hook='LineaUI.DatePicker'][data-kind=date][data-mode=single]")
           |> Enum.count() == 1

    assert html |> find("#d") |> LazyHTML.attribute("data-value") == [~s(["2026-10-03"])]
    display = find(html, "#d-display")
    assert LazyHTML.attribute(display, "value") == ["2026-10-03"]
    assert LazyHTML.attribute(display, "placeholder") == ["Choose date..."]
    assert "pl-9" in classes(html, "#d-display")
    assert find(html, "input[type=hidden][name=due][value='2026-10-03']") |> Enum.count() == 1

    assert find(html, "#d-calendar.flatpickr-calendar.arrowTop[phx-update=ignore]")
           |> Enum.count() == 1

    assert find(html, "#d-field span svg") |> Enum.count() == 1
  end

  test "display_format and names" do
    html = render(~H|<.date_picker id="d" name="d" value="2026-10-03" display_format="F j, Y" />|)
    assert html |> find("#d-display") |> LazyHTML.attribute("value") == ["October 3, 2026"]

    assert html |> find("input[type=hidden][name=d]") |> LazyHTML.attribute("value") == [
             "2026-10-03"
           ]
  end

  test "multiple and range submit name[]" do
    html =
      render(
        ~H|<.date_picker id="m" name="m" mode="multiple" value={["2022-10-10", "2022-10-12"]} />|
      )

    assert html |> find("#m-display") |> LazyHTML.attribute("value") == ["2022-10-10, 2022-10-12"]

    assert html |> find("input[type=hidden][name='m[]']") |> LazyHTML.attribute("value") == [
             "",
             "2022-10-10",
             "2022-10-12"
           ]

    html =
      render(
        ~H|<.date_picker id="r" name="r" mode="range" value={{~D[2016-10-10], ~D[2016-10-20]}} />|
      )

    assert html |> find("#r-display") |> LazyHTML.attribute("value") == [
             "2016-10-10 to 2016-10-20"
           ]

    assert find(html, "#r-calendar.rangeMode") |> Enum.count() == 1
  end

  test "limits and disabled days reach the hook" do
    html =
      render(~H"""
      <.date_picker
        id="d"
        name="d"
        min={~D[2026-01-01]}
        max="2026-12-31"
        disabled_dates={[~D[2026-05-01]]}
        disabled_weekdays={[0, 6]}
        week_start={1}
        today={~D[2026-10-23]}
        on_change="picked"
      />
      """)

    wrapper = find(html, "#d")
    assert LazyHTML.attribute(wrapper, "data-min") == ["2026-01-01"]
    assert LazyHTML.attribute(wrapper, "data-max") == ["2026-12-31"]
    assert LazyHTML.attribute(wrapper, "data-disabled-dates") == [~s(["2026-05-01"])]
    assert LazyHTML.attribute(wrapper, "data-disabled-weekdays") == ["[0,6]"]
    assert LazyHTML.attribute(wrapper, "data-week-start") == ["1"]
    assert LazyHTML.attribute(wrapper, "data-today") == ["2026-10-23"]
    assert LazyHTML.attribute(wrapper, "data-on-change") == ["picked"]
  end

  test "trailing buttons join the input and drop the icon; inline shows the calendar" do
    html =
      render(~H"""
      <.date_picker id="x" name="x" inline>
        <:trailing><button id="tg" phx-click={LineaUI.toggle("x")}>t</button></:trailing>
      </.date_picker>
      """)

    assert find(html, "#x-field.flex.-space-x-px #tg") |> Enum.count() == 1
    assert "rounded-l-lg" in classes(html, "#x-display")
    refute "pl-9" in classes(html, "#x-display")
    assert find(html, "#x-calendar.open") |> Enum.count() == 1
  end

  test "datetime_picker carries the time rules" do
    html = render(~H|<.datetime_picker
  id="t"
  name="t"
  value={~N[2026-10-03 16:30:00]}
  min_time="16:00"
  max_time="22:00"
/>|)
    assert html |> find("#t-display") |> LazyHTML.attribute("value") == ["2026-10-03 16:30"]

    assert find(html, "#t[data-kind=datetime][data-min-time='16:00'][data-max-time='22:00']")
           |> Enum.count() == 1

    assert find(html, "#t-calendar.hasTime") |> Enum.count() == 1
  end

  test "field wiring, label and errors" do
    assigns = %{
      __changed__: nil,
      form: Phoenix.Component.to_form(%{"due" => "2026-10-03"}, as: :task)
    }

    html =
      rendered_to_string(
        ~H|<.date_picker field={@form[:due]} label="Due" errors={["is late"]} />|
      )

    assert find(html, "#task_due input[type=hidden][name='task[due]'][value='2026-10-03']")
           |> Enum.count() == 1

    assert "border-error" in classes(html, "#task_due-display")
    assert html |> find(".text-error") |> LazyHTML.text() =~ "is late"
  end

  test "date_picker_clear dispatches linea:clear" do
    assert %Phoenix.LiveView.JS{ops: [["dispatch", %{event: "linea:clear", to: "#x"}]]} =
             LineaUI.Components.DatePicker.date_picker_clear("x")
  end

  test "format writes flatpickr tokens" do
    names = %{months: Shell.months(), weekdays: Shell.weekdays()}
    assert Shell.format("2026-10-03", nil, "D, M j y", names) == "Sat, Oct 3 26"
    assert Shell.format(nil, "00:05", "h:i K", names) == "12:05 AM"
    assert Shell.format(nil, "13:05", "H:i G", names) == "13:05 13"
  end

  test "show_icon={false} leaves a bare input and display_format shapes the text" do
    html =
      render(
        ~H|<.date_picker id="d" name="due" value={~D[2026-10-03]} show_icon={false} display_format="M j, Y" />|
      )

    assert [] = find(html, "#d-field span svg") |> Enum.to_list()
    refute "pl-9" in classes(html, "#d-display")
    assert LazyHTML.attribute(find(html, "#d-display"), "value") == ["Oct 3, 2026"]
    assert find(html, "input[type=hidden][name=due][value='2026-10-03']") |> Enum.count() == 1
  end
end
