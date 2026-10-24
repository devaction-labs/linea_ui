defmodule LineaUI.Components.DatetimePicker do
  @moduledoc """
  A date and a time chosen in one panel: a calendar with a list of times beside it, or, for a
  range, two months side by side with a start and an end time.

      <.datetime_picker field={@form[:starts_at]} label="Starts at" />
      <.datetime_picker name="meeting" interval={15} min="now" min_time="08:00" max_time="18:00" />
      <.datetime_picker name="slot" time="input" unavailable="12:00-13:00, 2026-10-14, 2026-10-15T10:00" />
      <.datetime_picker name="shift" mode="range" default_time="09:00/17:00" locale="pt_BR" />

  The value is wall-clock text, like a native `datetime-local` input: `2026-10-14T10:30`, with no
  time zone and no conversion. The form gets it through a hidden input named like the field (a
  range gets `name[]` twice, start then end, with an empty `name[]` first so an empty choice
  still reaches the server; `start_field`/`end_field` or `start_name`/`end_name` submit the two
  ends as two fields instead). `value` takes a `NaiveDateTime`, a `DateTime` (its clock, not
  converted), `"2026-10-14T10:30"` or `"2026-10-14 10:30"`; a range takes `{from, to}` or a list
  of two. A bubbling `input` event fires on every change, so `phx-change` runs; the server
  re-rendering the same value changes nothing, a different value replaces the one in the browser.

  ## One date and time

  The default `mode="single"` opens a calendar with the times of the day beside it, the chosen
  time highlighted. Changing only the day updates the value at once, keeping the time (or taking
  the default one when that time is closed on the new day); choosing a time updates it and closes
  the panel. On a narrow screen the time list becomes a dropdown under the calendar and a
  "Select" button confirms: a tap alone does not change the value.

  ## A range

  `mode="range"` shows two months and, under them, the day and a time control for the start and
  for the end. The first click on a day starts the range, the next one closes it (a click before
  the start restarts it); nothing is applied until "Select range" is pressed. `default_time`
  takes `"start/end"` (`"09:00/17:00"`); the end of a range cannot be before its start.

  ## Times

  `interval` is the step of the suggested times in minutes. With `time="input"` the person types an
  exact time (`9:30`, `930`, `9:30 pm`, `21:15`) and the suggested times drop down as they type.
  `time_format` is the 12 or 24-hour clock, by default the one of the `locale`.

  ## Restrictions

  `min` and `max` bound the days (`"now"`, `"today"`, a `Date`, a `NaiveDateTime` or ISO text;
  `"now"` also closes the earlier times of today). `min_time` and `max_time` bound the times of
  every day. `unavailable` closes whole days (`"2026-10-14"`), a time range every day
  (`"12:00-13:00"`, from the first time up to but not including the second; `"22:00-02:00"`
  crosses midnight) or one date-time (`"2026-10-14T10:00"`), as a comma separated text or a list.
  A day with no time left cannot be picked.

  ## Your own trigger

  The `trigger` slot replaces the input: any button opens the panel, and the picker shows no text
  of its own. The panel is an overlay, so `LineaUI.open/close/toggle("id")` work on it.

      <.datetime_picker id="when" name="when">
        <:trigger>
          <.button variant="outline">Pick a date and time</.button>
        </:trigger>
      </.datetime_picker>

  ## Keyboard

  `↓` or `Enter` on the input opens the panel with the focus on the chosen day. In the calendar the
  arrows move a day or a week, `Home`/`End` the start and end of the week, `Page Up`/`Page Down` a
  month (with `Shift` a year) and `Enter` or `Space` picks. In the time list `↑`/`↓`/`Home`/`End`
  move and `Enter` picks; in the time field `↓`/`↑` walk the suggestions. `Esc` closes the panel and
  gives the focus back; leaving the panel with `Tab` closes it.
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1, icon_set: 0]

  alias LineaUI.Components.DatePicker
  alias LineaUI.Components.DatePicker.Shell
  alias LineaUI.Components.Form
  alias LineaUI.Components.Strings

  @variants %{
    "outlined" =>
      "form-input peer w-full cursor-pointer rounded-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary disabled:pointer-events-none disabled:select-none disabled:border-none disabled:bg-zinc-100 dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent dark:disabled:bg-navy-600",
    "filled" =>
      "form-input peer w-full cursor-pointer rounded-lg bg-slate-150 px-3 py-2 ring-primary/50 placeholder:text-slate-400 hover:bg-slate-200 focus:ring-3 disabled:pointer-events-none disabled:select-none disabled:opacity-60 dark:bg-navy-900/90 dark:ring-accent/50 dark:placeholder:text-navy-300 dark:hover:bg-navy-900 dark:focus:bg-navy-900"
  }

  @errors %{
    "outlined" =>
      "border-error hover:border-error focus:border-error dark:border-error dark:hover:border-error dark:focus:border-error",
    "filled" => "ring-1 ring-error focus:ring-error/50 dark:ring-error"
  }

  @sizes %{"sm" => "h-8 text-xs-plus", "md" => "", "lg" => "h-12 text-base"}

  @icon "pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent"

  @date_formats %{"en" => {"M j, Y", ", "}, "pt_BR" => {"d/m/Y", " "}}
  @hour12 %{"en" => true, "pt_BR" => false}

  @moment ~r/\A(\d{4}-\d{2}-\d{2})(?:[T ](\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?)?\z/
  @clock ~r/\A(\d{1,2}):(\d{2})\z/

  @doc """
  Renders the date and time input with its panel.

      <.datetime_picker id="due" name="due" label="Due" help="Local time" />
      <.datetime_picker field={@form[:window]} mode="range" label="Window" min="today" />

  Events: `on_change` is pushed with `%{"id" => id, "value" => value}` after each change, where
  `value` is the wall-clock text (`"2026-10-14T10:30"`, `""` for no choice) or, for a range, the
  list of the two ends (`[]` for no choice), to `target` or to the LiveView/LiveComponent the
  picker is in.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."

  attr :value, :any,
    doc:
      "A `NaiveDateTime`, a `DateTime` (its clock, not converted) or `\"2026-10-14T10:30\"`; a range takes `{from, to}` or a list of two. A day without a time takes `default_time`."

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []

  attr :placeholder, :string,
    default: nil,
    doc:
      "Defaults to \"Select date and time\" (\"Select date range\" for a range) in the `locale`."

  attr :mode, :string,
    default: "single",
    values: ~w(single range),
    doc:
      "`range` picks a start and an end, each with its own time; set by `start_field`/`end_field` and `start_name`/`end_name`."

  attr :start_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "The field the start of a range goes to; with `end_field`."

  attr :end_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "The field the end of a range goes to; with `start_field`."

  attr :start_name, :string,
    default: nil,
    doc: "The input name of the start of a range (without fields); with `end_name`."

  attr :end_name, :string, default: nil, doc: "The input name of the end of a range."

  attr :interval, :integer,
    default: 30,
    doc: "Minutes between the suggested times, from midnight: `15` gives 9:00, 9:15, 9:30..."

  attr :time, :string,
    default: "list",
    values: ~w(list input),
    doc:
      "`list` chooses the time from the list beside the calendar (a dropdown on a narrow screen); `input` types an exact time, with the suggested times in a dropdown."

  attr :default_time, :string,
    default: nil,
    doc:
      "The time a picked day starts with, `\"09:00\"`; for a range `\"start/end\"`, `\"09:00/17:00\"`. The first open time when not given or closed."

  attr :time_format, :string,
    default: "auto",
    values: ~w(auto 12 24),
    doc:
      "`12` is 9:30 AM, `24` is 09:30; `auto` follows the `locale` (12 for `en`, 24 for `pt_BR`)."

  attr :time_24hr, :boolean,
    default: nil,
    doc: "The attribute of the former flatpickr picker, kept as `time_format=\"24\"`; use `time_format`."

  attr :minute_step, :integer,
    default: nil,
    doc: "The attribute of the former flatpickr picker, kept as `interval`; use `interval`."

  attr :default_hour, :integer,
    default: nil,
    doc: "The attribute of the former flatpickr picker, kept as `default_time=\"HH:00\"`; use `default_time`."

  attr :locale, :string,
    default: "en",
    values: ~w(en pt_BR),
    doc:
      "Month and weekday names, the words of the panel, the default text format and `time_format`."

  attr :display_format, :string,
    default: nil,
    doc:
      "The text of the input in flatpickr tokens (`Y y m n d j F M l D H G h i K`); `M j, Y, h:i K` (`d/m/Y H:i` in `pt_BR`) by default. Only the shown text changes: the form still gets the wall-clock text."

  attr :range_separator, :string,
    default: " – ",
    doc: "The text between the two ends of a range in the input."

  attr :min, :any,
    default: nil,
    doc:
      "The first day or moment that can be picked: `\"now\"` (closes the earlier times of today too), `\"today\"`, a `Date`, a `NaiveDateTime` or ISO text."

  attr :max, :any,
    default: nil,
    doc: "The last day or moment that can be picked; same values as `min`."

  attr :min_time, :string, default: nil, doc: "The earliest time of every day, `\"HH:MM\"`."
  attr :max_time, :string, default: nil, doc: "The latest time of every day, `\"HH:MM\"`."

  attr :unavailable, :any,
    default: [],
    doc:
      "What cannot be picked, a comma separated text or a list of: a day (`\"2026-10-14\"` or a `Date`), a daily time range (`\"12:00-13:00\"`, up to but not including the end; `\"22:00-02:00\"` crosses midnight) or a date-time (`\"2026-10-14T10:00\"` or a `NaiveDateTime`)."

  attr :week_start, :integer, default: 0, doc: "The first column of the calendar, 0 = Sunday."
  attr :months, :list, default: nil, doc: "The twelve month names, for another language."

  attr :weekdays, :list,
    default: nil,
    doc: "The seven weekday names from Sunday; the calendar shows their first three letters."

  attr :today, :any,
    default: nil,
    doc:
      "The day marked as today and meant by `\"now\"` and `\"today\"` (a `Date` or ISO text); the browser's day by default."

  attr :labels, :map,
    default: %{},
    doc:
      "Single texts of the panel: `:datetime_select`, `:datetime_select_range`, `:datetime_start`, `:datetime_end`, `:datetime_time`, `:datetime_times`, `:datetime_no_times`, `:datetime_time_placeholder`, `:datetime_previous`, `:datetime_next`, `:datetime_day` (with `%{weekday}`, `%{month}`, `%{day}`, `%{year}`), `:datetime_title` (with `%{month}`, `%{year}`), `:datetime_dialog`, `:datetime_dialog_range`, `:datetime_placeholder`, `:datetime_placeholder_range`."

  attr :variant, :string, default: "outlined", values: ~w(outlined filled)
  attr :size, :string, default: "md", values: ~w(sm md lg)

  attr :placement, :string,
    default: "bottom-start",
    doc:
      "Where the panel opens, `top`, `bottom`, `left` or `right` with `-start` or `-end`; it flips when there is no room."

  attr :show_icon, :boolean,
    default: true,
    doc: "The calendar icon inside the input; `false` leaves a bare input."

  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Classes of the input."
  attr :rest, :global

  slot :icon, doc: "Replaces the calendar icon."

  slot :trigger,
    doc:
      "Replaces the input: any button inside opens the panel. The picker then shows no text of its own."

  def datetime_picker(assigns) do
    assigns
    |> DatePicker.range_fields()
    |> assign_field()
    |> assign_new(:id, fn -> gen_id("datetime") end)
    |> then(&assign_new(&1, :name, fn -> &1.id end))
    |> assign_new(:value, fn -> nil end)
    |> legacy()
    |> prepare()
    |> render_picker()
  end

  defp legacy(assigns) do
    assign(assigns,
      time_format: legacy_format(assigns),
      interval: assigns.minute_step || assigns.interval,
      default_time: legacy_default(assigns)
    )
  end

  defp legacy_format(%{time_24hr: true}), do: "24"
  defp legacy_format(%{time_format: format}), do: format

  defp legacy_default(%{default_time: nil, default_hour: hour}) when is_integer(hour),
    do: hour |> Integer.to_string() |> String.pad_leading(2, "0") |> Kernel.<>(":00")

  defp legacy_default(%{default_time: time}), do: time

  defp prepare(assigns) do
    locale = assigns.locale
    hour12 = hour12?(assigns.time_format, locale)
    {date_format, joiner} = Map.fetch!(@date_formats, locale)
    time_format = time_format(hour12)
    format = assigns.display_format || date_format <> joiner <> time_format
    names = Shell.names(locale)

    names = %{
      months: assigns.months || names.months,
      weekdays: assigns.weekdays || names.weekdays
    }

    values = moments(assigns)

    assigns
    |> assign(
      hour12: hour12,
      format: format,
      date_format: date_format,
      names: names,
      values: values,
      display: display(values, assigns.mode, format, names, assigns.range_separator),
      text: texts(locale, assigns.labels),
      input_name: input_name(assigns.name, assigns.mode),
      split: split(assigns.start_name, assigns.end_name, values),
      hidden: hidden(assigns, values),
      unavailable: unavailable(assigns.unavailable),
      min: limit(assigns.min),
      max: limit(assigns.max),
      today: Shell.iso(assigns.today),
      input_class: input_class(assigns)
    )
  end

  defp hour12?("12", _locale), do: true
  defp hour12?("24", _locale), do: false
  defp hour12?("auto", locale), do: Map.fetch!(@hour12, locale)

  defp time_format(true), do: "h:i K"
  defp time_format(false), do: "H:i"

  defp texts(locale, labels) do
    locale
    |> Strings.table(labels)
    |> Enum.filter(fn {key, _text} ->
      key |> Atom.to_string() |> String.starts_with?("datetime_")
    end)
    |> Map.new()
  end

  defp input_name(name, "range"), do: name <> "[]"
  defp input_name(name, "single"), do: name

  defp split(start, finish, values) when is_binary(start) and is_binary(finish),
    do: [{start, Enum.at(values, 0, "")}, {finish, Enum.at(values, 1, "")}]

  defp split(_start, _finish, _values), do: nil

  defp hidden(%{start_name: start, end_name: finish}, values)
       when is_binary(start) and is_binary(finish),
       do: split(start, finish, values)

  defp hidden(%{name: name, mode: mode}, values) do
    input = input_name(name, mode)
    empty_field(input, name, values) ++ Enum.map(values, &{input, &1})
  end

  defp empty_field(input, name, values) when values == [] or input != name, do: [{input, ""}]
  defp empty_field(_input, _name, _values), do: []

  defp input_class(assigns) do
    merge([
      @variants[assigns.variant],
      @sizes[assigns.size],
      (assigns.show_icon or assigns.icon != []) && "pl-9",
      assigns.errors != [] && @errors[assigns.variant],
      assigns.class
    ])
  end

  defp moments(%{value: value, mode: mode} = assigns) do
    {start, finish} = default_times(assigns.default_time)
    fallback = assigns.min_time |> clock() |> Kernel.||("00:00")

    value
    |> flatten()
    |> Enum.map(&moment/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(count(mode))
    |> Enum.with_index()
    |> Enum.map(fn {moment, index} ->
      complete(moment, [start, finish] |> Enum.at(index), fallback)
    end)
  end

  defp count("single"), do: 1
  defp count("range"), do: 2

  defp flatten(nil), do: []
  defp flatten(""), do: []
  defp flatten(%Date.Range{first: first, last: last}), do: [first, last]
  defp flatten({from, to}), do: [from, to]
  defp flatten(%{from: from, to: to}), do: [from, to]
  defp flatten(list) when is_list(list), do: list
  defp flatten(one), do: [one]

  defp moment(%NaiveDateTime{} = at), do: wall(at)
  defp moment(%DateTime{} = at), do: wall(at)
  defp moment(%Date{} = date), do: Date.to_iso8601(date)

  defp moment(text) when is_binary(text) do
    case Regex.run(@moment, String.trim(text)) do
      [_all, date] -> day(date)
      [_all, date, hour, minute] -> day(date) && time(date, hour, minute)
      nil -> nil
    end
  end

  defp moment(_other), do: nil

  defp wall(at), do: Calendar.strftime(at, "%Y-%m-%dT%H:%M")

  defp day(date) do
    case Date.from_iso8601(date) do
      {:ok, _date} -> date
      {:error, _reason} -> nil
    end
  end

  defp time(date, hour, minute) do
    case clock("#{hour}:#{minute}") do
      nil -> nil
      time -> date <> "T" <> time
    end
  end

  defp clock(nil), do: nil

  defp clock(text) do
    with [_all, hour, minute] <- Regex.run(@clock, String.trim(text)),
         {hour, ""} when hour < 24 <- Integer.parse(hour),
         {minute, ""} when minute < 60 <- Integer.parse(minute) do
      pad(hour) <> ":" <> pad(minute)
    else
      _invalid -> nil
    end
  end

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  defp default_times(nil), do: {nil, nil}

  defp default_times(text) do
    case text |> String.split("/") |> Enum.map(&clock/1) do
      [start] -> {start, start}
      [start, finish | _rest] -> {start, finish || start}
    end
  end

  defp complete(moment, _default, _fallback) when byte_size(moment) > 10, do: moment
  defp complete(date, default, fallback), do: date <> "T" <> (default || fallback)

  defp display(values, "single", format, names, _separator),
    do: values |> Enum.map_join(&text(&1, format, names))

  defp display([_start, _finish] = values, "range", format, names, separator),
    do: values |> Enum.map_join(separator, &text(&1, format, names))

  defp display(_values, "range", _format, _names, _separator), do: ""

  defp text(moment, format, names) do
    [date, time] = String.split(moment, "T")
    Shell.format(date, time, format, names)
  end

  defp limit(nil), do: nil
  defp limit(%Date{} = date), do: Date.to_iso8601(date)
  defp limit(%NaiveDateTime{} = at), do: wall(at)
  defp limit(%DateTime{} = at), do: wall(at)
  defp limit(text) when is_binary(text), do: text

  defp unavailable(text) when is_binary(text), do: unavailable([text])

  defp unavailable(list) when is_list(list),
    do: Enum.flat_map(list, &entries/1)

  defp entries(%Date{} = date), do: [Date.to_iso8601(date)]
  defp entries(%NaiveDateTime{} = at), do: [wall(at)]
  defp entries(%DateTime{} = at), do: [wall(at)]

  defp entries({%Time{} = from, %Time{} = to}),
    do: ["#{Calendar.strftime(from, "%H:%M")}-#{Calendar.strftime(to, "%H:%M")}"]

  defp entries(text) when is_binary(text),
    do: text |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

  defp entries(_other), do: []

  defp render_picker(assigns) do
    ~H"""
    <Form.field as="div" id={@id} label={@label} help={@help} errors={@errors}>
      <div
        id={@id}
        phx-hook="LineaUI.DatetimePicker"
        phx-target={@target}
        class={["relative", @label && "mt-1.5"]}
        data-mode={@mode}
        data-time-mode={@time}
        data-interval={@interval}
        data-default-time={@default_time}
        data-hour12={bool(@hour12)}
        data-format={@format}
        data-date-format={@date_format}
        data-separator={@range_separator}
        data-names={Phoenix.json_library().encode!(@names)}
        data-labels={Phoenix.json_library().encode!(@text)}
        data-value={Phoenix.json_library().encode!(@values)}
        data-name={@input_name}
        data-start-name={@split && @start_name}
        data-end-name={@split && @end_name}
        data-today={@today}
        data-min={@min}
        data-max={@max}
        data-min-time={@min_time}
        data-max-time={@max_time}
        data-unavailable={Phoenix.json_library().encode!(@unavailable)}
        data-week-start={@week_start}
        data-placement={@placement}
        data-fallbacks={fallbacks(@placement)}
        data-offset="6"
        data-padding="10"
        data-popup="dialog"
        data-disabled={bool(@disabled)}
        data-icons={icon_set()}
        data-on-change={@on_change}
        {@rest}
      >
        <div data-trigger class={@trigger == [] && "relative flex w-full"}>
          <div
            :if={@trigger == []}
            id={@id <> "-field"}
            phx-update="ignore"
            class="relative flex w-full"
          >
            <input
              type="text"
              id={@id <> "-display"}
              class={@input_class}
              placeholder={@placeholder || placeholder(@text, @mode)}
              value={@display}
              disabled={@disabled}
              readonly
              aria-haspopup="dialog"
              aria-expanded="false"
              aria-controls={@id <> "-panel"}
              aria-labelledby={@label && @id <> "-label"}
              aria-invalid={@errors != [] && "true"}
              data-display
            />
            <span :if={@show_icon or @icon != []} class={icon_class()}>
              {render_slot(@icon) || default_icon()}
            </span>
          </div>
          {render_slot(@trigger)}
        </div>
        <div id={@id <> "-hidden"} phx-update="ignore" data-hidden>
          <input
            :for={{name, value} <- @hidden}
            type="hidden"
            name={name}
            value={value}
            disabled={@disabled}
          />
        </div>
        <div
          id={@id <> "-panel"}
          class="popper-root fixed left-0 top-0 w-max"
          popover="manual"
          role="dialog"
          aria-hidden="true"
          aria-label={dialog_label(@text, @mode)}
          data-panel
          phx-update="ignore"
        >
          <div class="popper-box rounded-lg border border-slate-150 bg-white font-inter shadow-soft dark:border-navy-500 dark:bg-navy-700 dark:shadow-none">
            <div data-surface></div>
          </div>
        </div>
        <p class="sr-only" role="status" aria-live="polite" data-status></p>
      </div>
    </Form.field>
    """
  end

  defp fallbacks("bottom" <> rest), do: "top" <> rest
  defp fallbacks("top" <> rest), do: "bottom" <> rest
  defp fallbacks("left" <> rest), do: "right" <> rest
  defp fallbacks("right" <> rest), do: "left" <> rest

  defp placeholder(text, "single"), do: text.datetime_placeholder
  defp placeholder(text, "range"), do: text.datetime_placeholder_range

  defp dialog_label(text, "single"), do: text.datetime_dialog
  defp dialog_label(text, "range"), do: text.datetime_dialog_range

  defp icon_class, do: @icon

  defp default_icon do
    assigns = %{}

    ~H"""
    <.glyph name={:calendar} class="size-5 transition-colors duration-200" stroke_width="1.5" />
    """
  end
end
