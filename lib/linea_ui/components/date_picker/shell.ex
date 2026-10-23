defmodule LineaUI.Components.DatePicker.Shell do
  @moduledoc false

  use LineaUI.Component

  alias LineaUI.Components.Pickers

  @months ~w(January February March April May June July August September October November December)
  @weekdays ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

  @input "form-input flatpickr-input peer w-full rounded-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"
  @input_grouped "form-input flatpickr-input w-full rounded-l-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:z-10 hover:border-slate-400 focus:z-10 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"

  @doc false
  def months, do: @months

  @doc false
  def weekdays, do: @weekdays

  @doc false
  @spec prepare(map(), :date | :datetime | :time) :: map()
  def prepare(assigns, kind) do
    assigns =
      assigns
      |> assign_field()
      |> assign_new(:id, fn -> gen_id("picker") end)
      |> then(&assign_new(&1, :name, fn -> &1.id end))
      |> assign_new(:value, fn -> nil end)
      |> assign(:kind, kind)

    values = hidden_values(assigns.value, kind, assigns.mode)
    format = assigns.display_format || default_format(kind)
    names = %{months: assigns.months || @months, weekdays: assigns.weekdays || @weekdays}

    assign(assigns,
      values: values,
      format: format,
      names: names,
      display: display(values, kind, assigns.mode, format, names),
      input_name: input_name(assigns.name, assigns.mode),
      grouped: assigns.trailing != []
    )
  end

  defp default_format(:date), do: "Y-m-d"
  defp default_format(:datetime), do: "Y-m-d H:i"
  defp default_format(:time), do: "H:i"

  defp input_name(name, mode) when mode in ["multiple", "range"], do: name <> "[]"
  defp input_name(name, _mode), do: name

  @doc false
  @spec hidden_values(term(), :date | :datetime | :time, String.t()) :: [String.t()]
  def hidden_values(nil, _kind, _mode), do: []
  def hidden_values("", _kind, _mode), do: []

  def hidden_values(%Date.Range{first: first, last: last}, kind, mode),
    do: hidden_values([first, last], kind, mode)

  def hidden_values({from, to}, kind, mode), do: hidden_values([from, to], kind, mode)
  def hidden_values(%{from: from, to: to}, kind, mode), do: hidden_values([from, to], kind, mode)

  def hidden_values(list, kind, _mode) when is_list(list),
    do: list |> Enum.reject(&(&1 in [nil, ""])) |> Enum.map(&one(&1, kind))

  def hidden_values(value, kind, _mode), do: [one(value, kind)]

  defp one(%Date{} = date, _kind), do: Date.to_iso8601(date)
  defp one(%Time{} = time, _kind), do: hm(time)
  defp one(%NaiveDateTime{} = at, :datetime), do: "#{Date.to_iso8601(at)} #{hm(at)}"
  defp one(%DateTime{} = at, :datetime), do: "#{Date.to_iso8601(at)} #{hm(at)}"
  defp one(%NaiveDateTime{} = at, :time), do: hm(at)
  defp one(%DateTime{} = at, :time), do: hm(at)
  defp one(%NaiveDateTime{} = at, :date), do: Date.to_iso8601(at)
  defp one(%DateTime{} = at, :date), do: Date.to_iso8601(at)
  defp one(text, kind) when is_binary(text), do: text |> String.replace("T", " ") |> trim(kind)

  defp trim(text, :date), do: String.slice(text, 0, 10)
  defp trim(text, :datetime), do: String.slice(text, 0, 16)
  defp trim(text, :time), do: String.slice(text, 0, 5)

  defp hm(at), do: at |> Calendar.strftime("%H:%M")

  defp display(values, :time, _mode, format, names),
    do: values |> Enum.map(&format(nil, &1, format, names)) |> Enum.join(", ")

  defp display(values, kind, "range", format, names),
    do: values |> Enum.map(&format_value(&1, kind, format, names)) |> Enum.join(" to ")

  defp display(values, kind, _mode, format, names),
    do: values |> Enum.map(&format_value(&1, kind, format, names)) |> Enum.join(", ")

  defp format_value(value, :datetime, format, names) do
    [date | time] = String.split(value, " ")
    format(date, List.first(time), format, names)
  end

  defp format_value(value, :date, format, names), do: format(value, nil, format, names)

  @doc """
  A date and time written in flatpickr's tokens (`Y y m n d j F M l D H G h i K`), the same
  the browser uses, so the first render already shows the text.
  """
  @spec format(String.t() | nil, String.t() | nil, String.t(), map()) :: String.t()
  def format(iso, time, format, names) do
    date = Date.from_iso8601!(iso || "1970-01-01")
    {hour, minute} = clock(time)

    format
    |> String.graphemes()
    |> Enum.map_join(&token(&1, date, hour, minute, names))
  end

  defp clock(nil), do: {0, 0}

  defp clock(text) do
    [hour, minute] = text |> String.split(":") |> Enum.take(2) |> Enum.map(&String.to_integer/1)
    {hour, minute}
  end

  defp token("Y", date, _h, _m, _n), do: Integer.to_string(date.year)
  defp token("y", date, _h, _m, _n), do: date.year |> Integer.to_string() |> String.slice(-2, 2)
  defp token("m", date, _h, _m, _n), do: pad(date.month)
  defp token("n", date, _h, _m, _n), do: Integer.to_string(date.month)
  defp token("d", date, _h, _m, _n), do: pad(date.day)
  defp token("j", date, _h, _m, _n), do: Integer.to_string(date.day)
  defp token("F", date, _h, _m, names), do: Enum.at(names.months, date.month - 1)

  defp token("M", date, _h, _m, names),
    do: names.months |> Enum.at(date.month - 1) |> String.slice(0, 3)

  defp token("l", date, _h, _m, names), do: Enum.at(names.weekdays, weekday(date))

  defp token("D", date, _h, _m, names),
    do: names.weekdays |> Enum.at(weekday(date)) |> String.slice(0, 3)

  defp token("H", _date, hour, _m, _n), do: pad(hour)
  defp token("G", _date, hour, _m, _n), do: Integer.to_string(hour)
  defp token("h", _date, hour, _m, _n), do: Integer.to_string(twelve(rem(hour, 12)))
  defp token("i", _date, _h, minute, _n), do: pad(minute)
  defp token("K", _date, hour, _m, _n) when hour < 12, do: "AM"
  defp token("K", _date, _hour, _m, _n), do: "PM"
  defp token(char, _date, _h, _m, _n), do: char

  defp twelve(0), do: 12
  defp twelve(hour), do: hour

  defp weekday(date), do: rem(Date.day_of_week(date), 7)

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  @doc false
  def iso(nil), do: nil
  def iso(%Date{} = date), do: Date.to_iso8601(date)
  def iso(text) when is_binary(text), do: text

  @doc false
  def render_picker(assigns, kind, hook) do
    assigns
    |> assign(:hook, hook)
    |> assign(:today, assigns.today || Date.utc_today())
    |> prepare(kind)
    |> shell()
  end

  @doc false
  def shell(assigns) do
    assigns =
      assign(assigns,
        input_class:
          merge([
            input_base(assigns.grouped),
            icon_pad(assigns.grouped, assigns.show_icon or assigns.icon != []),
            assigns.errors != [] && "border-error",
            assigns.class
          ])
      )

    ~H"""
    <Pickers.field label={@label} help={@help} errors={@errors} for={@id <> "-display"}>
      <div
        id={@id}
        phx-hook={@hook}
        phx-target={@target}
        class={["relative", @label && "mt-1.5"]}
        data-kind={@kind}
        data-mode={@mode}
        data-value={Pickers.json(@values)}
        data-name={@input_name}
        data-format={@format}
        data-names={Pickers.json(@names)}
        data-today={iso(@today)}
        data-min={iso(@min)}
        data-max={iso(@max)}
        data-min-time={@min_time}
        data-max-time={@max_time}
        data-time24={bool(@time_24hr)}
        data-minute-step={@minute_step}
        data-hour-step={@hour_step}
        data-default-hour={@default_hour}
        data-disabled-dates={Pickers.json(Enum.map(@disabled_dates, &iso/1))}
        data-disabled-weekdays={Pickers.json(@disabled_weekdays)}
        data-week-start={@week_start}
        data-inline={bool(@inline)}
        data-on-change={@on_change}
        {@rest}
      >
        <div id={@id <> "-field"} phx-update="ignore" class={field_class(@grouped)}>
          <input
            type="text"
            id={@id <> "-display"}
            class={@input_class}
            placeholder={@placeholder}
            value={@display}
            disabled={@disabled}
            readonly
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls={@id <> "-calendar"}
            aria-invalid={@errors != [] && "true"}
            data-display
          />
          <span
            :if={not @grouped and (@show_icon or @icon != [])}
            class="pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent"
          >
            {render_slot(@icon) || default_icon(@kind)}
          </span>
          {render_slot(@trailing)}
          <div data-hidden>
            <input
              :if={@values == [] or @input_name != @name}
              type="hidden"
              name={@input_name}
              value=""
              disabled={@disabled}
            />
            <input
              :for={value <- @values}
              type="hidden"
              name={@input_name}
              value={value}
              disabled={@disabled}
            />
          </div>
        </div>
        <div
          id={@id <> "-calendar"}
          phx-update="ignore"
          role="dialog"
          tabindex="-1"
          class={calendar_class(@kind, @mode, @inline)}
          style={calendar_style(@inline)}
          data-calendar
        >
        </div>
      </div>
    </Pickers.field>
    """
  end

  defp icon_pad(false, true), do: "pl-9"
  defp icon_pad(_grouped, _icon), do: nil

  defp input_base(true), do: @input_grouped
  defp input_base(false), do: @input

  defp field_class(true), do: "flex -space-x-px"
  defp field_class(false), do: "relative flex"

  defp calendar_class(kind, mode, inline) do
    [
      "flatpickr-calendar animate arrowTop arrowLeft",
      kind != :date && "hasTime",
      kind == :time && "noCalendar",
      mode == "range" && "rangeMode",
      inline && "open"
    ]
  end

  defp calendar_style(true), do: "position: relative; top: 2px; display: block;"
  defp calendar_style(false), do: "top: calc(100% + 2px); left: 0;"

  defp default_icon(:time) do
    assigns = %{}

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
    """
  end

  defp default_icon(_kind) do
    assigns = %{}

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-5 transition-colors duration-200"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      />
    </svg>
    """
  end
end
