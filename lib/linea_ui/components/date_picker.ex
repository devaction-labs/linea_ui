defmodule LineaUI.Components.DatePicker do
  @moduledoc """
  LineOne's date pickers (flatpickr's calendar in LineOne's skin): one date, several dates or a
  range, with limits, disabled days, a custom text format, and a calendar that pops under the
  input or stays inline. For a date and a time in one panel see `datetime_picker/1`.

      <.date_picker field={@form[:due_on]} placeholder="Choose date..." />
      <.date_picker name="trip" mode="range" value={{~D[2026-10-10], ~D[2026-10-20]}} />
      <.date_picker name="days" mode="multiple" disabled_weekdays={[0, 6]} week_start={1} />
      <.date_picker name="due" display_format="M j, Y" show_icon={false} placeholder="Due date" />

  The input shows the date in `display_format` (flatpickr tokens: `Y-m-d`, `F j, Y`, `H:i`...);
  the form gets ISO text through hidden inputs named like the field: `2026-10-23` (one date), and
  `name[]` per date for `multiple` and `range` (with an
  empty `name[]` first so an empty choice still reaches the server). A pick fires a bubbling
  `input` event, so `phx-change` runs; the server re-rendering the same value changes nothing,
  a different value replaces the one in the browser.

  The calendar is an overlay: `LineaUI.open/close/toggle("id")` work on it, and
  `date_picker_clear/1` empties it.

  ## A range in two fields

  A range can submit its two ends as two fields instead of `name[]`: give `start_field` and
  `end_field` (or `start_name` and `end_name`) and the form gets `start=2026-10-01` and
  `end=2026-10-31` (empty text for an end not picked yet). `presets` adds quick choices under
  the calendar, computed on the server from `today`:

      <.date_picker
        start_field={@form[:from]}
        end_field={@form[:to]}
        locale="pt_BR"
        week_start={1}
        placeholder="Período"
        presets={[
          {"Hoje", "today"},
          {"Últimos 7 dias", "last_7_days"},
          {"Este mês", "this_month"},
          {"Mês passado", "last_month"}
        ]}
      />

  `locale="pt_BR"` names the months and weekdays in Portuguese, shows `dd/mm/aaaa` and joins
  a range with "até"; `months`, `weekdays`, `display_format` and `range_separator` still
  override it one by one.
  """

  use LineaUI.Component

  alias LineaUI.Components.DatePicker.Shell
  alias Phoenix.HTML.FormField

  @doc """
  Renders a date input with its calendar.

      <.date_picker id="due" name="due" label="Due" min={Date.utc_today()} />
      <.date_picker id="when" name="when" placeholder="Choose date">
        <:trailing>
          <.button phx-click={LineaUI.toggle("when")}>…</.button>
          <.button phx-click={date_picker_clear("when")}>×</.button>
        </:trailing>
      </.date_picker>

  Events: `on_change` is pushed with `%{"id" => id, "value" => value}` after each pick, where
  `value` is the ISO text (or a list of them for `multiple` and `range`), to `target` or to the
  LiveView/LiveComponent the picker is in.

  A preset is `{label, key}` with a key of `date_range_preset/3` (`"today"`, `"yesterday"`,
  `"last_7_days"`, `"last_30_days"`, `"this_week"`, `"last_week"`, `"this_month"`,
  `"last_month"`, `"this_year"`, `"last_year"`), `{label, {from, to}}` or
  `%{label: label, from: from, to: to}` with `Date`s or ISO text. Picking one sets the range
  (or, in `single` mode, its first day), fires `phx-change` and `on_change`, and closes the
  calendar; the preset matching the current choice is highlighted.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :any, doc: "A `Date`, ISO text, a list of them, `{from, to}` or a `Date.Range`."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil

  attr :mode, :string,
    default: "single",
    values: ~w(single multiple range),
    doc: "Set to `range` by `start_field`/`end_field` and `start_name`/`end_name`."

  attr :start_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "The field the first day of a range goes to; with `end_field`."

  attr :end_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "The field the last day of a range goes to; with `start_field`."

  attr :start_name, :string,
    default: nil,
    doc: "The input name of the first day of a range (without fields); with `end_name`."

  attr :end_name, :string, default: nil, doc: "The input name of the last day of a range."

  attr :presets, :list,
    default: [],
    doc:
      "Quick choices under the calendar: `{label, key}`, `{label, {from, to}}` or `%{label:, from:, to:}`."

  attr :locale, :string,
    default: "en",
    values: ~w(en pt_BR),
    doc: "Month and weekday names, the default `display_format` and the range separator."

  attr :range_separator, :string,
    default: nil,
    doc: "The text between the two days of a range; \" to \" (en) or \" até \" (pt_BR)."

  attr :min, :any, default: nil, doc: "The first day that can be picked (`Date` or ISO text)."
  attr :max, :any, default: nil, doc: "The last day that can be picked."
  attr :disabled_dates, :list, default: [], doc: "Days that cannot be picked."
  attr :disabled_weekdays, :list, default: [], doc: "Weekdays that cannot be picked, 0 = Sunday."
  attr :week_start, :integer, default: 0, doc: "The first column of the calendar, 0 = Sunday."

  attr :display_format, :string,
    default: nil,
    doc:
      "The text of the input in flatpickr tokens; `Y-m-d` by default. `M j, Y` reads `Oct 23, 2026`, `D, M j` reads `Fri, Oct 23`, `F j, Y` reads `October 23, 2026`. Only the shown text changes: the form still gets ISO."

  attr :months, :list, default: nil, doc: "The twelve month names, for another language."

  attr :weekdays, :list,
    default: nil,
    doc: "The seven weekday names from Sunday; the calendar shows their first three letters."

  attr :today, :any,
    default: nil,
    doc: "The day marked as today; the server's UTC day by default."

  attr :inline, :boolean, default: false, doc: "The calendar always shows, under the input."

  attr :show_icon, :boolean,
    default: true,
    doc:
      "The calendar icon inside the input; `false` leaves a bare input (and drops the left padding)."

  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Classes of the input."
  attr :rest, :global

  slot :icon, doc: "Replaces the calendar icon."

  slot :trailing,
    doc:
      "Buttons joined to the right of the input (LineOne's External Elements); the icon is then left out."

  def date_picker(assigns) do
    assigns
    |> time_defaults()
    |> range_fields()
    |> then(&assign(&1, :today, &1.today || Date.utc_today()))
    |> then(&assign(&1, :presets, Enum.map(&1.presets, fn preset -> preset(preset, &1) end)))
    |> Shell.render_picker(:date, "LineaUI.DatePicker")
  end

  @preset_keys ~w(today yesterday last_7_days last_30_days this_week last_week this_month last_month this_year last_year)

  @doc """
  The `{first, last}` days of a named period around `today`, the way `date_picker/1`'s
  `presets` compute them. `week_start` is the first day of a week, 0 = Sunday. The `this_*`
  and `last_*` periods are whole weeks, months and years; `last_7_days` and `last_30_days`
  end today.

      iex> LineaUI.Components.DatePicker.date_range_preset("last_month", ~D[2026-10-24])
      {~D[2026-09-01], ~D[2026-09-30]}

      iex> LineaUI.Components.DatePicker.date_range_preset("this_week", ~D[2026-10-24], 1)
      {~D[2026-10-19], ~D[2026-10-25]}
  """
  @spec date_range_preset(String.t(), Date.t(), 0..6) :: {Date.t(), Date.t()}
  def date_range_preset(key, today, week_start \\ 0)
  def date_range_preset("today", today, _ws), do: {today, today}

  def date_range_preset("yesterday", today, _ws),
    do: {Date.add(today, -1), Date.add(today, -1)}

  def date_range_preset("last_7_days", today, _ws), do: {Date.add(today, -6), today}
  def date_range_preset("last_30_days", today, _ws), do: {Date.add(today, -29), today}

  def date_range_preset("this_week", today, ws) do
    first = Date.add(today, -rem(rem(Date.day_of_week(today), 7) - ws + 7, 7))
    {first, Date.add(first, 6)}
  end

  def date_range_preset("last_week", today, ws) do
    {first, last} = date_range_preset("this_week", today, ws)
    {Date.add(first, -7), Date.add(last, -7)}
  end

  def date_range_preset("this_month", today, _ws),
    do: {Date.beginning_of_month(today), Date.end_of_month(today)}

  def date_range_preset("last_month", today, ws),
    do: date_range_preset("this_month", today |> Date.beginning_of_month() |> Date.add(-1), ws)

  def date_range_preset("this_year", today, _ws),
    do: {Date.new!(today.year, 1, 1), Date.new!(today.year, 12, 31)}

  def date_range_preset("last_year", today, _ws),
    do: {Date.new!(today.year - 1, 1, 1), Date.new!(today.year - 1, 12, 31)}

  @doc false
  def preset_keys, do: @preset_keys

  defp preset({label, key}, assigns) when is_binary(key),
    do: preset({label, date_range_preset(key, assigns.today, assigns.week_start)}, assigns)

  defp preset({label, {from, to}}, _assigns),
    do: %{label: label, from: Shell.iso(from), to: Shell.iso(to)}

  defp preset(%{label: label, from: from, to: to}, assigns),
    do: preset({label, {from, to}}, assigns)

  @doc false
  def range_fields(%{start_field: %FormField{} = first, end_field: %FormField{} = last} = assigns) do
    assigns
    |> assign(start_field: nil, end_field: nil, mode: "range")
    |> assign(:start_name, assigns.start_name || first.name)
    |> assign(:end_name, assigns.end_name || last.name)
    |> assign_new(:id, fn -> first.id <> "_range" end)
    |> assign_new(:value, fn -> {first.value, last.value} end)
    |> assign(:errors, field_errors(first) ++ field_errors(last) ++ assigns.errors)
    |> range_fields()
  end

  def range_fields(%{start_name: first, end_name: last} = assigns)
      when is_binary(first) and is_binary(last) do
    assigns
    |> assign(:mode, "range")
    |> assign_new(:name, fn -> first end)
  end

  def range_fields(assigns), do: assigns

  defp field_errors(field) do
    case Phoenix.Component.used_input?(field) do
      true -> Enum.map(field.errors, &translate_error/1)
      false -> []
    end
  end

  @doc """
  A `%JS{}` that empties the picker with `id`, for a clear button.

      <.button phx-click={date_picker_clear("when")}>Clear</.button>
  """
  @spec date_picker_clear(JS.t(), String.t()) :: JS.t()
  def date_picker_clear(js \\ %JS{}, id),
    do: JS.dispatch(js, "linea:clear", to: LineaUI.selector(id))

  defp time_defaults(assigns) do
    assign(assigns,
      time_24hr: false,
      min_time: nil,
      max_time: nil,
      minute_step: 5,
      hour_step: 1,
      default_hour: 12
    )
  end
end
