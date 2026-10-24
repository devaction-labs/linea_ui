defmodule LineaUI.Components.DatePicker do
  @moduledoc """
  LineOne's date pickers (flatpickr's calendar in LineOne's skin): one date, several dates or a
  range, with limits, disabled days, a custom text format, a time row, and a calendar that pops
  under the input or stays inline.

      <.date_picker field={@form[:due_on]} placeholder="Choose date..." />
      <.date_picker name="trip" mode="range" value={{~D[2026-10-10], ~D[2026-10-20]}} />
      <.date_picker name="days" mode="multiple" disabled_weekdays={[0, 6]} week_start={1} />
      <.datetime_picker field={@form[:starts_at]} min_time="16:00" max_time="22:00" />
      <.date_picker name="due" display_format="M j, Y" show_icon={false} placeholder="Due date" />

  The input shows the date in `display_format` (flatpickr tokens: `Y-m-d`, `F j, Y`, `H:i`...);
  the form gets ISO text through hidden inputs named like the field: `2026-10-23` (one date),
  `2026-10-23 16:30` (date and time), and `name[]` per date for `multiple` and `range` (with an
  empty `name[]` first so an empty choice still reaches the server). A pick fires a bubbling
  `input` event, so `phx-change` runs; the server re-rendering the same value changes nothing,
  a different value replaces the one in the browser.

  The calendar is an overlay: `LineaUI.open/close/toggle("id")` work on it, and
  `date_picker_clear/1` empties it.
  """

  use LineaUI.Component

  alias LineaUI.Components.DatePicker.Shell

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
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :any, doc: "A `Date`, ISO text, a list of them, `{from, to}` or a `Date.Range`."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :mode, :string, default: "single", values: ~w(single multiple range)
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
    |> Shell.render_picker(:date, "LineaUI.DatePicker")
  end

  @doc """
  Renders a date and time input: the calendar with flatpickr's hour and minute row.

      <.datetime_picker name="meeting" placeholder="Choose datetime..." min_time="16:00" max_time="22:00" />

  Takes every attr of `date_picker/1` (in `single` mode) and the time attrs below. The form
  gets `2026-10-23 16:30`.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :any, doc: "A `NaiveDateTime`, `DateTime` or `\"2026-10-23 16:30\"`."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :disabled_dates, :list, default: []
  attr :disabled_weekdays, :list, default: []
  attr :week_start, :integer, default: 0
  attr :display_format, :string, default: nil, doc: "`Y-m-d H:i` by default."
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :today, :any, default: nil
  attr :inline, :boolean, default: false
  attr :show_icon, :boolean, default: true
  attr :time_24hr, :boolean, default: false, doc: "Hours 0-23 instead of 1-12 with AM/PM."
  attr :min_time, :string, default: nil, doc: "The earliest time, `\"HH:MM\"`."
  attr :max_time, :string, default: nil, doc: "The latest time, `\"HH:MM\"`."
  attr :minute_step, :integer, default: 5
  attr :hour_step, :integer, default: 1
  attr :default_hour, :integer, default: 12, doc: "The hour a first pick starts at."
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon
  slot :trailing

  def datetime_picker(assigns) do
    assigns
    |> assign(:mode, "single")
    |> Shell.render_picker(:datetime, "LineaUI.DatePicker")
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
