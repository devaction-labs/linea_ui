defmodule LineaUI.Components.CalendarTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.Calendar

  doctest Calendar

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp count(html, selector), do: html |> find(selector) |> Enum.count()

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&String.trim(LazyHTML.text(&1)))

  @events [
    %{id: 1, title: "Coelba", date: ~D[2026-10-15], color: "error"},
    %{
      id: 2,
      title: "Visit",
      subtitle: "Santa Mônica",
      date: "2026-10-19",
      start: "10:00",
      end: "11:30"
    },
    %{id: 3, title: "Report", date: ~D[2026-10-19]},
    %{id: 4, title: "Lost", date: "not a date"}
  ]

  describe "month" do
    test "is a grid of rows with column headers and one cell per visible day" do
      html = render(~H|<.calendar id="cal" date={~D[2026-10-24]} today={~D[2026-10-24]} />|)

      assert attr_of(html, "#cal [role=grid]", "aria-labelledby") == ["cal-title"]
      assert count(html, "[role=columnheader]") == 7
      assert count(html, "[role=row]") == 6
      assert count(html, "[role=gridcell]") == 35
      assert attr_of(html, "#cal", "phx-hook") == ["LineaUI.Calendar"]
      assert attr_of(html, "#cal", "data-columns") == ["7"]
    end

    test "starts on the week_start day and names weekdays by their first three letters" do
      sunday = render(~H|<.calendar id="cal" date={~D[2026-10-24]} />|)
      monday = render(~H|<.calendar id="cal" date={~D[2026-10-24]} week_start={1} />|)

      assert texts(sunday, "[role=columnheader]") ==
               ~w(Sun Mon Tue Wed Thu Fri Sat)

      assert texts(monday, "[role=columnheader]") == ~w(Mon Tue Wed Thu Fri Sat Sun)
      assert attr_of(sunday, "[role=gridcell]", "data-date") |> hd() == "2026-09-27"
      assert attr_of(monday, "[role=gridcell]", "data-date") |> hd() == "2026-09-28"
    end

    test "marks today, one cell in the tab order and the selected day" do
      html =
        render(
          ~H|<.calendar id="cal" date={~D[2026-10-24]} today={~D[2026-10-20]} selected={~D[2026-10-12]} />|
        )

      assert attr_of(html, "[aria-current=date]", "data-date") == ["2026-10-20"]
      assert attr_of(html, "[role=gridcell][tabindex='0']", "data-date") == ["2026-10-24"]
      assert count(html, "[role=gridcell][tabindex='0']") == 1
      assert attr_of(html, "[aria-selected=true]", "data-date") == ["2026-10-12"]
    end

    test "draws the title in the locale" do
      en = render(~H|<.calendar id="cal" date={~D[2026-10-24]} />|)
      pt = render(~H|<.calendar id="cal" date={~D[2026-10-24]} locale="pt_BR" />|)

      assert texts(en, "#cal-title") == ["October 2026"]
      assert texts(pt, "#cal-title") == ["Outubro de 2026"]
      assert texts(pt, "[role=columnheader]") == ~w(Dom Seg Ter Qua Qui Sex Sáb)

      assert attr_of(pt, "[data-date='2026-10-24']", "aria-label") == [
               "Sábado, 24 de Outubro de 2026"
             ]
    end

    test "months and weekdays can be given" do
      html =
        render(~H|<.calendar
  id="cal"
  date={~D[2026-10-24]}
  months={~w(J F M A M J J A S Oct N D)}
  weekdays={~w(A B C D E F G)}
/>|)

      assert texts(html, "#cal-title") == ["Oct 2026"]
      assert texts(html, "[role=columnheader]") == ~w(A B C D E F G)
    end

    test "puts the events in their day as chips and drops the ones without a date" do
      assigns = %{events: @events}

      html =
        rendered_to_string(
          ~H|<.calendar id="cal" date={~D[2026-10-24]} events={@events} on_event="pick" />|
        )

      assert texts(html, "[data-date='2026-10-15'] button") == ["Coelba"]
      assert texts(html, "[data-date='2026-10-19'] button") == ["Report", "Visit"]
      refute html =~ "Lost"
      assert "bg-error/10" in classes(html, "[data-date='2026-10-15'] button")
    end

    test "chips are plain text without on_event" do
      assigns = %{events: @events}
      html = rendered_to_string(~H|<.calendar id="cal" date={~D[2026-10-24]} events={@events} />|)

      assert count(html, "[role=gridcell] button") == 0
      assert texts(html, "[data-date='2026-10-15'] span:last-child") == ["Coelba"]
    end

    test "a crowded day shows max_events chips and a more button" do
      events = for n <- 1..5, do: %{id: n, title: "E#{n}", date: ~D[2026-10-15]}
      assigns = %{events: events}

      html =
        rendered_to_string(~H|<.calendar
  id="cal"
  date={~D[2026-10-24]}
  events={@events}
  max_events={2}
  locale="pt_BR"
  on_select="day"
  on_event="pick"
/>|)

      assert texts(html, "[data-date='2026-10-15'] button") == ["E1", "E2", "+3 mais"]

      assert attr_of(html, "[data-date='2026-10-15'] button[tabindex='-1']", "aria-label") == [
               "Ver mais 3 eventos"
             ]
    end

    test "the slot replaces the content of a chip" do
      assigns = %{events: @events}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" date={~D[2026-10-24]} events={@events}>
          <:event :let={event}>[{event.title}]</:event>
        </.calendar>
        """)

      assert texts(html, "[data-date='2026-10-15'] span:last-child") == ["[Coelba]"]
    end
  end

  describe "week" do
    test "is a grid of hour rows by day columns with the events as blocks" do
      assigns = %{events: @events}

      html =
        rendered_to_string(~H|<.calendar
  id="cal"
  view="week"
  date={~D[2026-10-21]}
  week_start={1}
  events={@events}
  day_start={8}
  day_end={12}
  locale="pt_BR"
/>|)

      assert attr_of(html, "#cal", "data-columns") == ["7"]
      assert texts(html, "#cal-title") == ["19 – 25 Out 2026"]
      assert texts(html, "[role=columnheader]") |> Enum.take(3) == ["", "Seg 19", "Ter 20"]

      assert texts(html, "[role=rowheader]") |> Enum.take(5) == [
               "Dia todo",
               "08:00",
               "09:00",
               "10:00",
               "11:00"
             ]

      assert texts(html, "[data-date='2026-10-19'] .absolute") == ["VisitSanta Mônica"]

      assert attr_of(html, "[data-date='2026-10-19'] .absolute", "style") == [
               "top: 2px; height: 74px; left: 0%; width: 100%"
             ]

      assert texts(html, "[data-date='2026-10-19'] button, [data-date='2026-10-19'] span")
             |> Enum.member?("Report")
    end

    test "hides the weekend columns on request and keeps one cell in the tab order" do
      html =
        render(
          ~H|<.calendar id="cal" view="week" date={~D[2026-10-21]} week_start={1} show_weekends={false} />|
        )

      assert attr_of(html, "#cal", "data-columns") == ["5"]
      assert count(html, "[role=columnheader]") == 6
      assert count(html, "[role=gridcell][tabindex='0']") == 1
      assert attr_of(html, "[role=gridcell][tabindex='0']", "data-date") == ["2026-10-21"]
    end

    test "a week across two months and two years has both in the title" do
      across_months = render(~H|<.calendar id="cal" view="week" date={~D[2026-09-30]} />|)
      across_years = render(~H|<.calendar id="cal" view="week" date={~D[2026-12-31]} />|)

      assert texts(across_months, "#cal-title") == ["27 Sep – 3 Oct 2026"]
      assert texts(across_years, "#cal-title") == ["27 Dec 2026 – 2 Jan 2027"]
    end
  end

  describe "toolbar" do
    test "has previous, today and next buttons and the view switch" do
      html =
        render(
          ~H|<.calendar id="cal" date={~D[2026-10-24]} locale="pt_BR" on_navigate="nav" on_view="view" />|
        )

      assert attr_of(html, "[data-nav=prev]", "aria-label") == ["Anterior"]
      assert attr_of(html, "[data-nav=next]", "aria-label") == ["Próximo"]
      assert texts(html, "[data-nav=today]") == ["Hoje"]
      assert texts(html, "[data-view-button]") == ["Mês", "Semana"]
      assert attr_of(html, "[data-view-button=month]", "aria-pressed") == ["true"]
      assert attr_of(html, "[data-view-button=week]", "aria-pressed") == ["false"]
    end

    test "buttons are disabled without their events" do
      html = render(~H|<.calendar id="cal" date={~D[2026-10-24]} />|)

      assert attr_of(html, "[data-nav=prev]", "disabled") == [""]
      assert attr_of(html, "[data-view-button=week]", "disabled") == [""]
    end

    test "the clicks push the next period, the view and the day" do
      html =
        render(~H|<.calendar
  id="cal"
  date={~D[2026-01-31]}
  today={~D[2026-10-24]}
  on_navigate="nav"
  on_view="view"
  on_select="day"
  target="#owner"
/>|)

      assert attr_of(html, "[data-nav=next]", "phx-click") |> hd() =~ ~s("date":"2026-02-28")
      assert attr_of(html, "[data-nav=next]", "phx-click") |> hd() =~ ~s("view":"month")
      assert attr_of(html, "[data-nav=next]", "phx-click") |> hd() =~ ~s("target":"#owner")
      assert attr_of(html, "[data-nav=today]", "phx-click") |> hd() =~ ~s("date":"2026-10-24")
      assert attr_of(html, "[data-view-button=week]", "phx-click") |> hd() =~ ~s("view":"week")

      assert attr_of(html, "[data-date='2026-01-15']", "phx-click") |> hd() =~
               ~s("date":"2026-01-15")
    end

    test "header false leaves only the grid, named by its title" do
      html = render(~H|<.calendar id="cal" date={~D[2026-10-24]} header={false} />|)

      assert count(html, "[data-nav]") == 0
      assert attr_of(html, "[role=grid]", "aria-label") == ["October 2026"]
    end
  end

  test "the toolbar has the title and the arrows at the left, Today and the switch at the right" do
    html =
      render(~H|<.calendar id="cal" date={~D[2026-10-24]} on_navigate="nav" on_view="view" />|)

    assert "justify-between" in classes(html, "#cal > div:first-child")
    left = "#cal > div:first-child > div:first-child"
    right = "#cal > div:first-child > div:last-child"
    assert count(html, "#{left} #cal-title") == 1
    assert count(html, "#{left} [data-nav=prev]") == 1
    assert count(html, "#{left} [data-nav=next]") == 1
    assert count(html, "#{right} [data-nav=today]") == 1
    assert count(html, "#{right} [data-view-button]") == 2
  end

  test "the month cell is 112px tall, hovers when it can be selected and rings the selected number" do
    html =
      render(
        ~H|<.calendar id="cal" date={~D[2026-10-24]} selected={~D[2026-10-12]} on_select="day" />|
      )

    cell = classes(html, "[data-date='2026-10-12']")
    assert "min-h-28" in cell
    assert "hover:bg-slate-100" in cell
    assert "ring-[1.5px]" in classes(html, "[data-date='2026-10-12'] > span")
    refute "ring-[1.5px]" in classes(html, "[data-date='2026-10-13'] > span")
    refute "bg-primary/5" in cell

    quiet = render(~H|<.calendar id="cal" date={~D[2026-10-24]} />|)
    refute "hover:bg-slate-100" in classes(quiet, "[data-date='2026-10-12']")
  end

  test "the week view tints the column of today and marks timed blocks with a coloured edge" do
    assigns = %{events: @events}

    html =
      rendered_to_string(~H|<.calendar
  id="cal"
  view="week"
  date={~D[2026-10-21]}
  today={~D[2026-10-19]}
  week_start={1}
  events={@events}
  day_start={8}
  day_end={12}
/>|)

    today = classes(html, "[role=gridcell][data-date='2026-10-19']")

    assert Enum.any?(
             today,
             &String.starts_with?(&1, "bg-[color-mix(in_oklab,var(--color-primary)_5%")
           )

    other = classes(html, "[role=gridcell][data-date='2026-10-20']")
    refute Enum.any?(other, &String.starts_with?(&1, "bg-[color-mix"))
    assert "border-l-[3px]" in classes(html, "[data-date='2026-10-19'] .absolute > *")
  end

  test "the legend swatches are solid colours" do
    html =
      render(
        ~H|<.calendar id="cal" date={~D[2026-10-24]} legend={[{"Pay", "error"}, {"Receive", "success"}]} />|
      )

    assert "bg-error" in classes(html, "ul li:first-child span")
    refute "bg-error/10" in classes(html, "ul li:first-child span")
    assert "bg-success" in classes(html, "ul li:last-child span")
  end

  test "the legend lists the colors" do
    html =
      render(
        ~H|<.calendar id="cal" date={~D[2026-10-24]} legend={[{"Pay", "error"}, {"Receive", "success"}]} />|
      )

    assert texts(html, "ul li") == ["Pay", "Receive"]
  end

  test "calendar_range and calendar_shift" do
    assert Calendar.calendar_range(~D[2026-10-24], "month") == {~D[2026-09-27], ~D[2026-10-31]}
    assert Calendar.calendar_range(~D[2026-10-24], "month", 1) == {~D[2026-09-28], ~D[2026-11-01]}
    assert Calendar.calendar_range(~D[2026-10-24], "week") == {~D[2026-10-18], ~D[2026-10-24]}
    assert Calendar.calendar_shift(~D[2026-10-24], "week", :next) == ~D[2026-10-31]
    assert Calendar.calendar_shift(~D[2026-03-31], "month", :prev) == ~D[2026-02-28]
  end
end
