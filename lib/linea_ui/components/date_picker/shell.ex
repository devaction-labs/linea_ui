defmodule LineaUI.Components.DatePicker.Shell do
  @moduledoc false

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1, icon_set: 0]

  alias LineaUI.Components.Pickers
  alias LineaUI.Components.Strings

  @months ~w(January February March April May June July August September October November December)
  @weekdays ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

  @locales %{
    "en" => %{
      months: @months,
      weekdays: @weekdays,
      separator: " to ",
      formats: %{date: "Y-m-d", datetime: "Y-m-d H:i", time: "H:i"}
    },
    "pt_BR" => %{
      months:
        ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro),
      weekdays: ~w(Domingo Segunda Terça Quarta Quinta Sexta Sábado),
      separator: " até ",
      formats: %{date: "d/m/Y", datetime: "d/m/Y H:i", time: "H:i"}
    }
  }

  @preset "rounded-full bg-slate-150 px-2.5 py-1 text-xs-plus font-medium text-slate-600 transition-colors hover:bg-slate-200 hover:text-slate-800 focus-visible:outline-2 focus-visible:outline-primary/50 data-active:bg-primary data-active:text-white dark:bg-navy-500 dark:text-navy-100 dark:hover:bg-navy-450 dark:hover:text-navy-50 dark:data-active:bg-accent dark:data-active:text-white"

  @input "form-input flatpickr-input peer w-full rounded-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent disabled:cursor-not-allowed disabled:border-transparent disabled:bg-zinc-100 disabled:opacity-60 dark:disabled:bg-navy-600"
  @input_grouped "form-input flatpickr-input w-full rounded-l-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:z-10 hover:border-slate-400 focus:z-10 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent disabled:cursor-not-allowed disabled:border-transparent disabled:bg-zinc-100 disabled:opacity-60 dark:disabled:bg-navy-600"

  @doc false
  def months, do: @months

  @doc false
  def weekdays, do: @weekdays

  @doc false
  def locales, do: Map.keys(@locales)

  @doc false
  @spec names(String.t()) :: %{months: [String.t()], weekdays: [String.t()]}
  def names(locale), do: Map.take(Map.fetch!(@locales, locale), [:months, :weekdays])

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

    locale = @locales[Map.get(assigns, :locale, "en")]
    values = hidden_values(assigns.value, kind, assigns.mode)
    format = assigns.display_format || locale.formats[kind]
    separator = Map.get(assigns, :range_separator) || locale.separator

    names = %{
      months: assigns.months || locale.months,
      weekdays: assigns.weekdays || locale.weekdays
    }

    text = texts(Map.get(assigns, :locale, "en"), Map.get(assigns, :labels, %{}))

    assign(assigns,
      values: values,
      format: format,
      text: text,
      dialog: dialog_label(text, kind, assigns.mode),
      names: names,
      separator: separator,
      display: display(values, kind, assigns.mode, format, names, separator),
      input_name: input_name(assigns.name, assigns.mode),
      split: split(Map.get(assigns, :start_name), Map.get(assigns, :end_name), values),
      presets: Map.get(assigns, :presets, []),
      preset_class: @preset,
      grouped: assigns.trailing != []
    )
  end

  defp texts(locale, labels) do
    locale
    |> Strings.table(labels)
    |> Enum.filter(fn {key, _text} ->
      key |> Atom.to_string() |> String.starts_with?("picker_")
    end)
    |> Map.new()
  end

  defp dialog_label(text, :time, _mode), do: text.picker_time_dialog
  defp dialog_label(text, _kind, "range"), do: text.picker_period_dialog
  defp dialog_label(text, _kind, _mode), do: text.picker_date_dialog

  defp split(start, finish, values) when is_binary(start) and is_binary(finish),
    do: [{start, Enum.at(values, 0, "")}, {finish, Enum.at(values, 1, "")}]

  defp split(_start, _finish, _values), do: nil

  defp split_name(nil, _index), do: nil
  defp split_name(split, index), do: split |> Enum.at(index) |> elem(0)

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
    do: list |> Enum.map(&one(&1, kind)) |> Enum.reject(&is_nil/1)

  def hidden_values(value, kind, mode), do: hidden_values([value], kind, mode)

  defp one(%Date{} = date, _kind), do: Date.to_iso8601(date)
  defp one(%Time{} = time, _kind), do: hm(time)
  defp one(%NaiveDateTime{} = at, :datetime), do: "#{Date.to_iso8601(at)} #{hm(at)}"
  defp one(%DateTime{} = at, :datetime), do: "#{Date.to_iso8601(at)} #{hm(at)}"
  defp one(%NaiveDateTime{} = at, :time), do: hm(at)
  defp one(%DateTime{} = at, :time), do: hm(at)
  defp one(%NaiveDateTime{} = at, :date), do: Date.to_iso8601(at)
  defp one(%DateTime{} = at, :date), do: Date.to_iso8601(at)

  defp one(text, kind) when is_binary(text),
    do: text |> String.trim() |> String.replace("T", " ") |> trim(kind) |> valid(kind)

  defp one(_value, _kind), do: nil

  defp valid(text, kind) do
    case valid?(text, kind) do
      true -> text
      false -> nil
    end
  end

  defp valid?(text, :date), do: match?({:ok, _date}, Date.from_iso8601(text))

  defp valid?(text, :datetime) do
    case String.split(text, " ", parts: 2) do
      [date] -> valid?(date, :date)
      [date, time] -> valid?(date, :date) and valid?(time, :time)
    end
  end

  defp valid?(text, :time), do: clock(text) != :error

  defp trim(text, :date), do: String.slice(text, 0, 10)
  defp trim(text, :datetime), do: String.slice(text, 0, 16)
  defp trim(text, :time), do: String.slice(text, 0, 5)

  defp hm(at), do: at |> Calendar.strftime("%H:%M")

  defp display(values, :time, _mode, format, names, _separator),
    do: values |> Enum.map(&format(nil, &1, format, names)) |> Enum.join(", ")

  defp display(values, kind, "range", format, names, separator),
    do: values |> Enum.map(&format_value(&1, kind, format, names)) |> Enum.join(separator)

  defp display(values, kind, _mode, format, names, _separator),
    do: values |> Enum.map(&format_value(&1, kind, format, names)) |> Enum.join(", ")

  defp format_value(value, :datetime, format, names) do
    [date | time] = String.split(value, " ")
    format(date, List.first(time), format, names)
  end

  defp format_value(value, :date, format, names), do: format(value, nil, format, names)

  @doc """
  A date and time written in flatpickr's tokens (`Y y m n d j F M l D H G h i K`), the same
  the browser uses, so the first render already shows the text. A date or a time that does
  not parse gives `""`.
  """
  @spec format(String.t() | nil, String.t() | nil, String.t(), map()) :: String.t()
  def format(iso, time, format, names) do
    with {:ok, date} <- Date.from_iso8601(iso || "1970-01-01"),
         {hour, minute} <- clock(time) do
      format
      |> String.graphemes()
      |> Enum.map_join(&token(&1, date, hour, minute, names))
    else
      _invalid -> ""
    end
  end

  defp clock(nil), do: {0, 0}

  defp clock(text) do
    case Regex.run(~r/\A(\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?\z/, text) do
      [_all, hour, minute] -> in_day(String.to_integer(hour), String.to_integer(minute))
      nil -> :error
    end
  end

  defp in_day(hour, minute) when hour < 24 and minute < 60, do: {hour, minute}
  defp in_day(_hour, _minute), do: :error

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
    |> assign_new(:skin, fn -> nil end)
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
        data-skin={@skin}
        data-mode={@mode}
        data-value={Pickers.json(@values)}
        data-name={@input_name}
        data-format={@format}
        data-names={Pickers.json(@names)}
        data-labels={Pickers.json(@text)}
        data-separator={@separator}
        data-start-name={split_name(@split, 0)}
        data-end-name={split_name(@split, 1)}
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
        data-icons={icon_set()}
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
          <div :if={@split} data-hidden>
            <input
              :for={{name, value} <- @split}
              type="hidden"
              name={name}
              value={value}
              disabled={@disabled}
            />
          </div>
          <div :if={!@split} data-hidden>
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
          aria-label={@dialog}
          tabindex="-1"
          class={calendar_class(@kind, @mode, @inline)}
          style={calendar_style(@inline, @skin)}
          data-skin={@skin}
          data-calendar
        >
        </div>
        <template :if={@presets != []} data-presets>
          <div class="flatpickr-presets flex flex-wrap gap-1.5 rounded-b border-t border-slate-150 bg-white p-2 dark:border-navy-500 dark:bg-navy-700">
            <button
              :for={preset <- @presets}
              type="button"
              class={@preset_class}
              data-preset
              data-from={preset.from}
              data-to={preset.to}
            >
              {preset.label}
            </button>
          </div>
        </template>
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

  defp calendar_style(true, nil), do: "position: relative; top: 2px; display: block;"
  defp calendar_style(true, _skin), do: "position: relative; top: 6px; display: block;"
  defp calendar_style(false, nil), do: "top: calc(100% + 2px); left: 0;"
  defp calendar_style(false, _skin), do: "top: calc(100% + 6px); left: 0;"

  defp default_icon(:time) do
    assigns = %{}

    ~H"""
    <.glyph name={:clock} class="size-5" stroke_width="1.5" />
    """
  end

  defp default_icon(_kind) do
    assigns = %{}

    ~H"""
    <.glyph name={:calendar} class="size-5 transition-colors duration-200" stroke_width="1.5" />
    """
  end
end
