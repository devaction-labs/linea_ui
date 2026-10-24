defmodule LineaUI.Components.Calendar do
  @moduledoc """
  A calendar for dates that matter (due dates, appointments, deadlines): a month grid or a week grid
  of hours, with colored event chips, month and week switching and keyboard navigation.

      <.calendar
        id="due"
        view={@view}
        date={@date}
        events={@events}
        locale="pt_BR"
        on_navigate="calendar_navigate"
        on_view="calendar_view"
        on_select="calendar_select"
        on_event="calendar_event"
      />

  The server owns what the calendar shows, because the events of another period have to be loaded:
  `view` and `date` come from your assigns, and the toolbar (previous, next, today, month and week)
  and the keyboard push the events below with the date and view to show next. Update the assigns and
  load that period's events with `calendar_range/3`:

      def handle_event("calendar_navigate", %{"date" => date, "view" => view}, socket) do
        {:noreply, assign(socket, date: Date.from_iso8601!(date), view: view)}
      end

  An event is a map with `:date` (a `Date` or ISO text) and `:title`, and optionally `:id`, `:subtitle`,
  `:color` (`neutral primary secondary info success warning error`), and `:start` and `:end` (`"09:00"`
  or a `Time`). In the week view an event with a `:start` is a block in its hour; the others sit in an
  all-day row.

      %{id: 1, title: "Coelba", date: ~D[2026-10-15], color: "error"}
      %{id: 2, title: "Visit", subtitle: "Santa Mônica", date: ~D[2026-10-19], start: "10:00", end: "11:00"}

  The grid is `role="grid"`: Tab lands on one day, the arrows move between days (past the first or the
  last day they go to the previous or the next period), Home and End go to the ends of the week, Page Up
  and Page Down change period, and Enter or Space selects the day. `locale="pt_BR"` names months and
  weekdays in Portuguese, like `date_picker`, and writes the labels of the toolbar in Portuguese.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Button
  alias LineaUI.Components.Calendar.Grid
  alias LineaUI.Components.DatePicker.Shell
  alias LineaUI.Components.Strings

  @colors %{
    "neutral" => "bg-slate-150/60 text-slate-700 dark:bg-navy-500/40 dark:text-navy-100",
    "primary" => "bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light",
    "secondary" =>
      "bg-secondary/10 text-secondary dark:bg-secondary-light/15 dark:text-secondary-light",
    "info" => "bg-info/10 text-info dark:bg-info/15",
    "success" => "bg-success/10 text-success dark:bg-success/15",
    "warning" => "bg-warning/10 text-warning dark:bg-warning/15",
    "error" => "bg-error/10 text-error dark:bg-error/15"
  }

  @cell "relative border-t border-l border-slate-150 bg-white outline-hidden first:border-l-0 focus-visible:z-10 focus-visible:ring-2 focus-visible:ring-primary/60 focus-visible:ring-inset dark:border-navy-600 dark:bg-navy-700 dark:focus-visible:ring-accent/60"
  @head "bg-slate-200 px-2.5 py-2 font-inter text-tiny-plus font-semibold tracking-wider text-slate-500 uppercase dark:bg-navy-800 dark:text-navy-200"
  @switch "inline-flex gap-0.5 rounded-lg bg-slate-150 p-0.5 dark:bg-navy-800"
  @switch_item "inline-flex h-7.5 items-center justify-center rounded-md px-3 text-xs-plus font-medium whitespace-nowrap text-slate-500 outline-hidden transition-colors duration-200 hover:text-slate-700 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary/50 disabled:pointer-events-none disabled:opacity-60 aria-pressed:bg-white aria-pressed:text-slate-800 aria-pressed:shadow-soft dark:text-navy-200 dark:hover:text-navy-50 dark:focus-visible:outline-accent/50 dark:aria-pressed:bg-navy-500 dark:aria-pressed:text-navy-50 dark:aria-pressed:shadow-none"
  @chip "block w-full truncate rounded px-1.5 py-0.5 text-left font-inter text-tiny-plus font-medium"
  @chip_button "outline-hidden transition-opacity hover:opacity-80 focus-visible:ring-2 focus-visible:ring-primary/60 dark:focus-visible:ring-accent/60"

  @doc """
  Renders the calendar.

  Events pushed to the LiveView, or to the LiveComponent in `target`:

    * `on_navigate`: `%{"id" => id, "date" => "2026-11-01", "view" => "month"}`, the period to show next
      (the toolbar's arrows and Today, Page Up and Page Down, and the arrows at the edge of the grid).
    * `on_view`: `%{"id" => id, "date" => "2026-10-24", "view" => "week"}`, from the month and week buttons.
    * `on_select`: `%{"id" => id, "date" => "2026-10-24"}`, when a day is clicked or chosen with Enter,
      and from the "more" chip of a crowded day.
    * `on_event`: `%{"id" => id, "event" => event_id, "date" => "2026-10-24"}`, when an event is clicked.

  A button whose event is not set does not render as a button (the chips) or is disabled (the toolbar).
  """
  attr :id, :string, required: true
  attr :view, :string, default: "month", values: ~w(month week)

  attr :date, :any,
    default: nil,
    doc:
      "A day of the period to show (a `Date` or ISO text); today by default. It is also where the keyboard lands."

  attr :today, :any,
    default: nil,
    doc: "The day marked as today; the server's UTC day by default."

  attr :selected, :any, default: nil, doc: "A day drawn as selected (`aria-selected`)."

  attr :events, :list,
    default: [],
    doc: "Maps with `:date`, `:title` and the optional keys above."

  attr :legend, :list,
    default: [],
    doc: "Pairs `{label, color}` drawn under the grid, with the colors of the events."

  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :months, :list, default: nil, doc: "The twelve month names, for another language."

  attr :weekdays, :list,
    default: nil,
    doc: "The seven weekday names from Sunday; the grid shows their first three letters."

  attr :labels, :map,
    default: %{},
    doc:
      "Single texts: `:calendar_today`, `:calendar_previous`, `:calendar_next`, `:calendar_view`, `:calendar_month`, `:calendar_week`, `:calendar_all_day`, `:calendar_more` (with `%{count}`)."

  attr :week_start, :integer, default: 0, doc: "The first column of the grid, 0 = Sunday."

  attr :show_weekends, :boolean,
    default: true,
    doc: "Saturday and Sunday columns in the week view."

  attr :day_start, :integer, default: 8, doc: "The first hour row of the week view."
  attr :day_end, :integer, default: 18, doc: "The end of the last hour row of the week view."
  attr :max_events, :integer, default: 3, doc: "Chips per day in the month view before \"more\"."

  attr :header, :boolean,
    default: true,
    doc: "The toolbar with the title, arrows and view switch."

  attr :on_navigate, :string, default: nil
  attr :on_view, :string, default: nil
  attr :on_select, :string, default: nil
  attr :on_event, :string, default: nil
  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :event,
    doc:
      "Replaces the content of an event chip or block; receives the event map (`:let={event}`)."

  def calendar(assigns) do
    assigns
    |> prepare()
    |> render_calendar()
  end

  @doc """
  The first and last day the calendar draws for `date` in `view` (`"month"` or `"week"`), the range
  to load the events for. A month includes the days of the neighbor months in its first and last
  row. `week_start` is the first day of a week, 0 = Sunday.

      iex> LineaUI.Components.Calendar.calendar_range(~D[2026-10-24], "month")
      {~D[2026-09-27], ~D[2026-10-31]}

      iex> LineaUI.Components.Calendar.calendar_range(~D[2026-10-24], "week", 1)
      {~D[2026-10-19], ~D[2026-10-25]}
  """
  @spec calendar_range(Date.t(), String.t(), 0..6) :: {Date.t(), Date.t()}
  def calendar_range(date, view, week_start \\ 0), do: Grid.range(date, view, week_start)

  @doc """
  The day a month or week away from `date`, in `direction` `:prev` or `:next`, for a handler that
  moves the calendar yourself.

      iex> LineaUI.Components.Calendar.calendar_shift(~D[2026-01-31], "month", :next)
      ~D[2026-02-28]
  """
  @spec calendar_shift(Date.t(), String.t(), :prev | :next) :: Date.t()
  def calendar_shift(date, view, direction), do: Grid.shift(date, view, direction)

  defp prepare(assigns) do
    today = Grid.to_date(assigns.today) || Date.utc_today()
    date = Grid.to_date(assigns.date) || today
    names = Shell.names(assigns.locale)

    assigns =
      assign(assigns,
        today: today,
        date: date,
        selected: Grid.to_date(assigns.selected),
        text: Strings.table(assigns.locale, assigns.labels),
        months: assigns.months || names.months,
        weekdays: assigns.weekdays || names.weekdays,
        by_date: Grid.events(assigns.events),
        colors: @colors
      )

    assigns
    |> assign(:short_weekdays, short_weekdays(assigns))
    |> layout()
  end

  defp short_weekdays(assigns) do
    assigns.weekdays
    |> Enum.map(&String.slice(&1, 0, 3))
    |> rotate(assigns.week_start)
  end

  defp rotate(list, by), do: Enum.drop(list, by) ++ Enum.take(list, by)

  defp layout(%{view: "month"} = assigns) do
    weeks = Grid.month_weeks(assigns.date, assigns.week_start)
    days = List.flatten(weeks)
    active = active_day(days, assigns.date, assigns.date)

    assign(assigns,
      title: month_title(assigns, assigns.date),
      weeks: Enum.map(weeks, fn week -> Enum.map(week, &month_cell(&1, assigns, active)) end),
      columns: 7,
      label_id: assigns.id <> "-title"
    )
  end

  defp layout(%{view: "week"} = assigns) do
    days = Grid.week_days(assigns.date, assigns.week_start, assigns.show_weekends)
    active = active_day(days, assigns.date, hd(days))
    hours = assigns.day_start..(assigns.day_end - 1)//1
    events = Map.new(days, &{&1, Map.get(assigns.by_date, &1, [])})
    all_day? = Enum.any?(events, fn {_day, list} -> Enum.any?(list, &is_nil(&1.from)) end)

    assign(assigns,
      title: week_title(assigns, List.first(days), List.last(days)),
      days: Enum.map(days, &week_head(&1, assigns)),
      all_day: all_day? && Enum.map(days, &week_all_day(&1, events, assigns)),
      rows: Enum.map(hours, &week_row(&1, days, events, assigns, active)),
      columns: length(days),
      grid_style: "grid-template-columns: 56px repeat(#{length(days)}, minmax(0, 1fr))",
      label_id: assigns.id <> "-title"
    )
  end

  defp active_day(days, date, fallback), do: (date in days && date) || fallback

  defp month_cell(day, assigns, active) do
    {chips, rest} = assigns.by_date |> Map.get(day, []) |> Enum.split(assigns.max_events)

    %{
      date: day,
      iso: Date.to_iso8601(day),
      day: day.day,
      out?: day.month != assigns.date.month,
      today?: day == assigns.today,
      selected?: day == assigns.selected,
      active?: day == active,
      label: day_label(assigns, day),
      events: chips,
      more: length(rest)
    }
  end

  defp week_head(day, assigns) do
    weekday = Enum.at(assigns.weekdays, rem(Date.day_of_week(day), 7))

    %{
      iso: Date.to_iso8601(day),
      label: "#{String.slice(weekday, 0, 3)} #{day.day}",
      today?: day == assigns.today
    }
  end

  defp week_all_day(day, events, assigns) do
    %{
      date: day,
      iso: Date.to_iso8601(day),
      today?: day == assigns.today,
      label: day_label(assigns, day),
      events: events |> Map.fetch!(day) |> Enum.filter(&is_nil(&1.from))
    }
  end

  defp week_row(hour, days, events, assigns, active) do
    %{
      hour: hour,
      label: Grid.clock(hour * 60),
      cells:
        Enum.map(days, fn day ->
          %{
            date: day,
            iso: Date.to_iso8601(day),
            active?: day == active and hour == assigns.day_start,
            today?: day == assigns.today,
            label: day_label(assigns, day) <> ", " <> Grid.clock(hour * 60),
            blocks:
              events
              |> Map.fetch!(day)
              |> Grid.blocks(assigns.day_start, assigns.day_end)
              |> Enum.filter(&(&1.hour == hour))
          }
        end)
    }
  end

  defp day_label(assigns, day) do
    Strings.fill(assigns.text.calendar_day, %{
      weekday: Enum.at(assigns.weekdays, rem(Date.day_of_week(day), 7)),
      month: Enum.at(assigns.months, day.month - 1),
      day: day.day,
      year: day.year
    })
  end

  defp month_title(assigns, date) do
    Strings.fill(assigns.text.calendar_title_month, %{
      month: Enum.at(assigns.months, date.month - 1),
      year: date.year
    })
  end

  defp week_title(assigns, first, last) do
    cond do
      {first.year, first.month} == {last.year, last.month} ->
        "#{first.day} – #{last.day} #{month_abbr(assigns, last)} #{last.year}"

      first.year == last.year ->
        "#{first.day} #{month_abbr(assigns, first)} – #{last.day} #{month_abbr(assigns, last)} #{last.year}"

      true ->
        "#{first.day} #{month_abbr(assigns, first)} #{first.year} – #{last.day} #{month_abbr(assigns, last)} #{last.year}"
    end
  end

  defp month_abbr(assigns, date),
    do: assigns.months |> Enum.at(date.month - 1) |> String.slice(0, 3)

  defp push_js(nil, _id, _target, _values), do: nil

  defp push_js(event, id, nil, values), do: JS.push(event, value: Map.put(values, :id, id))

  defp push_js(event, id, target, values),
    do: JS.push(event, value: Map.put(values, :id, id), target: target)

  defp iso(date), do: Date.to_iso8601(date)

  defp render_calendar(assigns) do
    assigns =
      assign(assigns,
        cell: @cell,
        head: @head,
        switch: @switch,
        switch_item: @switch_item,
        row_px: Grid.row_px()
      )

    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.Calendar"
      phx-target={@target}
      data-view={@view}
      data-columns={@columns}
      class={merge(["w-full", @class])}
      {@rest}
    >
      <div :if={@header} class="mb-4 flex flex-wrap items-center justify-end gap-3">
        <Button.button
          size="sm"
          variant="flat"
          data-nav="today"
          disabled={@on_navigate == nil}
          phx-click={push_js(@on_navigate, @id, @target, %{date: iso(@today), view: @view})}
        >
          {@text.calendar_today}
        </Button.button>
        <div class="flex items-center gap-1">
          <Button.button
            icon
            size="sm"
            variant="flat"
            shape="pill"
            class="size-8"
            aria-label={@text.calendar_previous}
            data-nav="prev"
            disabled={@on_navigate == nil}
            phx-click={
              push_js(@on_navigate, @id, @target, %{
                date: iso(Grid.shift(@date, @view, :prev)),
                view: @view
              })
            }
          >
            <.glyph name={:chevron_left} class="size-4" />
          </Button.button>
          <h2
            id={@label_id}
            aria-live="polite"
            class="min-w-32 text-center font-medium text-slate-700 dark:text-navy-100"
          >
            {@title}
          </h2>
          <Button.button
            icon
            size="sm"
            variant="flat"
            shape="pill"
            class="size-8"
            aria-label={@text.calendar_next}
            data-nav="next"
            disabled={@on_navigate == nil}
            phx-click={
              push_js(@on_navigate, @id, @target, %{
                date: iso(Grid.shift(@date, @view, :next)),
                view: @view
              })
            }
          >
            <.glyph name={:chevron_right} class="size-4" />
          </Button.button>
        </div>
        <div role="group" aria-label={@text.calendar_view} class={@switch}>
          <button
            :for={{view, label} <- [{"month", @text.calendar_month}, {"week", @text.calendar_week}]}
            type="button"
            aria-pressed={bool(@view == view)}
            data-view-button={view}
            disabled={@on_view == nil}
            phx-click={push_js(@on_view, @id, @target, %{date: iso(@date), view: view})}
            class={@switch_item}
          >
            {label}
          </button>
        </div>
      </div>

      <div
        :if={@view == "month"}
        role="grid"
        aria-labelledby={@header && @label_id}
        aria-label={!@header && @title}
        class="overflow-hidden rounded-lg border border-slate-150 dark:border-navy-600"
      >
        <div role="row" class="grid grid-cols-7">
          <div :for={name <- @short_weekdays} role="columnheader" class={@head}>{name}</div>
        </div>
        <div :for={week <- @weeks} role="row" class="grid grid-cols-7">
          <div
            :for={cell <- week}
            role="gridcell"
            data-cell
            data-date={cell.iso}
            tabindex={(cell.active? && "0") || "-1"}
            aria-label={cell.label}
            aria-selected={cell.selected? && "true"}
            aria-current={cell.today? && "date"}
            phx-click={push_js(@on_select, @id, @target, %{date: cell.iso})}
            class={
              merge([
                @cell,
                "flex min-h-24 min-w-0 flex-col gap-1 px-2 py-1.5",
                cell.out? && "bg-slate-50 dark:bg-navy-750",
                cell.selected? && "bg-primary/5 dark:bg-accent/10",
                @on_select && "cursor-pointer"
              ])
            }
          >
            <span class={[
              "inline-flex h-5.5 items-center font-inter text-xs font-medium",
              (cell.today? &&
                 "size-5.5 justify-center rounded-full bg-primary text-white dark:bg-accent") ||
                (cell.out? && "text-slate-400 dark:text-navy-300") ||
                "text-slate-600 dark:text-navy-100"
            ]}>
              {cell.day}
            </span>
            <.chip
              :for={event <- cell.events}
              event={event}
              js={push_js(@on_event, @id, @target, %{event: event.id, date: cell.iso})}
              slot={@event}
            />
            <button
              :if={cell.more > 0}
              type="button"
              tabindex="-1"
              phx-click={push_js(@on_select, @id, @target, %{date: cell.iso})}
              class="w-full truncate rounded px-1.5 py-0.5 text-left font-inter text-tiny-plus font-medium text-slate-500 outline-hidden hover:bg-slate-150/60 dark:text-navy-200 dark:hover:bg-navy-500/40"
            >
              {Strings.fill(@text.calendar_more, %{count: cell.more})}
            </button>
          </div>
        </div>
      </div>

      <div
        :if={@view == "week"}
        role="grid"
        aria-labelledby={@header && @label_id}
        aria-label={!@header && @title}
        class="overflow-x-auto rounded-lg border border-slate-150 dark:border-navy-600"
      >
        <div role="row" class="grid" style={@grid_style}>
          <div role="columnheader" class={@head}></div>
          <div
            :for={day <- @days}
            role="columnheader"
            aria-current={day.today? && "date"}
            class={merge([@head, day.today? && "text-primary dark:text-accent-light"])}
          >
            {day.label}
          </div>
        </div>
        <div :if={@all_day} role="row" class="grid" style={@grid_style}>
          <div
            role="rowheader"
            class="border-t border-slate-150 px-2 py-1.5 text-right font-inter text-tiny-plus text-slate-400 dark:border-navy-600 dark:text-navy-300"
          >
            {@text.calendar_all_day}
          </div>
          <div
            :for={cell <- @all_day}
            role="gridcell"
            data-cell
            data-date={cell.iso}
            tabindex="-1"
            aria-label={cell.label <> ", " <> @text.calendar_all_day}
            class={merge([@cell, "flex min-h-10 min-w-0 flex-col gap-1 p-1"])}
          >
            <.chip
              :for={event <- cell.events}
              event={event}
              js={push_js(@on_event, @id, @target, %{event: event.id, date: cell.iso})}
              slot={@event}
            />
          </div>
        </div>
        <div :for={row <- @rows} role="row" class="grid" style={@grid_style}>
          <div
            role="rowheader"
            class="h-13 border-t border-slate-150 px-2 py-1 text-right font-inter text-tiny-plus text-slate-400 dark:border-navy-600 dark:text-navy-300"
          >
            {row.label}
          </div>
          <div
            :for={cell <- row.cells}
            role="gridcell"
            data-cell
            data-date={cell.iso}
            tabindex={(cell.active? && "0") || "-1"}
            aria-label={cell.label}
            aria-current={cell.today? && "date"}
            phx-click={push_js(@on_select, @id, @target, %{date: cell.iso})}
            class={merge([@cell, "h-13 min-w-0", @on_select && "cursor-pointer"])}
          >
            <div
              :for={block <- cell.blocks}
              class="absolute z-10 min-w-0"
              style={block.style}
            >
              <.chip
                event={block.event}
                js={push_js(@on_event, @id, @target, %{event: block.event.id, date: cell.iso})}
                slot={@event}
                block
                class="h-full"
              />
            </div>
          </div>
        </div>
      </div>

      <ul
        :if={@legend != []}
        class="mt-4 flex flex-wrap gap-4 font-inter text-xs font-medium text-slate-500 dark:text-navy-200"
      >
        <li :for={{label, color} <- @legend} class="inline-flex items-center gap-1.5">
          <span class={
            merge([
              "size-2.5 rounded-[3px]",
              Map.get(@colors, color, @colors["primary"])
            ])
          }></span>
          {label}
        </li>
      </ul>
    </div>
    """
  end

  attr :event, :map, required: true
  attr :js, :any, default: nil
  attr :slot, :list, default: []
  attr :block, :boolean, default: false
  attr :class, :any, default: nil

  defp chip(%{js: nil} = assigns) do
    ~H"""
    <span title={@event.title} class={chip_class(@event, @block, @class, false)}>
      <.chip_text event={@event} slot={@slot} block={@block} />
    </span>
    """
  end

  defp chip(assigns) do
    ~H"""
    <button
      type="button"
      title={@event.title}
      phx-click={@js}
      class={chip_class(@event, @block, @class, true)}
    >
      <.chip_text event={@event} slot={@slot} block={@block} />
    </button>
    """
  end

  defp chip_class(event, block, extra, button?) do
    merge([
      @chip,
      Map.get(@colors, event.color, @colors["primary"]),
      button? && @chip_button,
      block && "py-1 leading-[15px] whitespace-normal",
      extra
    ])
  end

  attr :event, :map, required: true
  attr :slot, :list, required: true
  attr :block, :boolean, required: true

  defp chip_text(%{slot: [_ | _]} = assigns) do
    ~H"""
    {render_slot(@slot, @event)}
    """
  end

  defp chip_text(assigns) do
    ~H"""
    {@event.title}<span :if={@block and @event.subtitle} class="block truncate font-normal opacity-75">{@event.subtitle}</span>
    """
  end
end
