defmodule LineaUI.Components.Range do
  @moduledoc """
  LineOne's range slider: a rounded track with a round thumb in the theme color, in three sizes.

      <.range name="volume" value={50} color="primary" />
      <.range field={@form[:level]} label="Level" min={0} max={10} size="lg" />
      <.range name="opacity" phx-debounce="100" />

  It is a native `<input type="range">`, so it submits with its form, fires `phx-change` as it is dragged
  and takes the arrow keys, Home, End and Page Up and Down.

  ## Value, marks and steps

  `show_value` writes the value beside the label, `filled` paints the track up to the thumb, `marks` puts
  labels under the track (a click on one sets the value) and `steppers` adds minus and plus buttons:

      <.range
        field={@form[:markup]}
        label="Markup"
        min={0}
        max={200}
        step={5}
        show_value
        value_format="%{value}%"
        filled
        marks={[{0, "0%"}, {50, "50%"}, {100, "100%"}, {150, "150%"}, {200, "200%"}]}
      />

      <.range name="tolerance" min={0} max={3} marks={[{0, "R$ 0,00"}, {1, "R$ 0,01"}, {2, "R$ 0,10"}, {3, "R$ 1,00"}]} />

  A mark is a value or a `{value, label}` pair. The browser keeps the value text, the fill and the marks
  in step with the thumb without waiting for the server.

  ## A range of two values

  Two thumbs on one track send two fields, as `date_picker` does for a period; the thumbs never cross:

      <.range start_field={@form[:price_from]} end_field={@form[:price_to]} min={0} max={500} step={10}
        label="Price" show_value value_format="R$ %{value}" />
      <.range start_name="from" end_name="to" value={{40, 280}} min={0} max={500} />

  ## Vertical

  `orientation="vertical"` stands the slider up (the arrow keys still work, up raises the value); `height` sets its length.

      <.range name="weight" orientation="vertical" value={40} show_value value_format="%{value}%" steppers label="Price" />
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form
  alias LineaUI.Components.NumberInput.Format

  @colors %{
    "neutral" => "text-slate-500 dark:text-navy-300",
    "primary" => "text-primary dark:text-accent",
    "secondary" => "text-secondary dark:text-secondary-light",
    "info" => "text-info",
    "success" => "text-success",
    "warning" => "text-warning",
    "error" => "text-error"
  }

  @sizes %{
    "sm" => "[--range-track-h:3px] [--range-thumb-size:12px]",
    "md" => nil,
    "lg" => "[--range-track-h:8px] [--range-thumb-size:24px]"
  }

  @thumb_px %{"sm" => 12, "md" => 18, "lg" => 24}

  @stepper "inline-flex size-6 shrink-0 items-center justify-center rounded-md text-slate-500 outline-hidden transition-colors hover:bg-slate-150 hover:text-slate-700 focus-visible:bg-slate-150 disabled:pointer-events-none disabled:opacity-40 dark:text-navy-200 dark:hover:bg-navy-500 dark:hover:text-navy-50 dark:focus-visible:bg-navy-500"

  @mark "absolute whitespace-nowrap rounded-sm px-1 text-xs font-medium text-slate-400 outline-hidden transition-colors hover:text-slate-600 focus-visible:text-slate-600 aria-pressed:text-primary dark:text-navy-300 dark:hover:text-navy-100 dark:aria-pressed:text-accent-light"

  @doc "Renders a range slider."
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")

  attr(:value, :any,
    doc:
      "A number, or `{from, to}` for a range of two values (then `start_name` and `end_name` or the fields name the inputs)."
  )

  attr(:min, :any, default: nil)
  attr(:max, :any, default: nil)
  attr(:step, :any, default: nil)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error)
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg))

  attr(:start_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "The field of the lower thumb of a range of two; with `end_field`."
  )

  attr(:end_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "The field of the upper thumb of a range of two."
  )

  attr(:start_name, :string,
    default: nil,
    doc: "The input name of the lower thumb; with `end_name`."
  )

  attr(:end_name, :string, default: nil, doc: "The input name of the upper thumb.")

  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "`vertical` is for a single value."
  )

  attr(:height, :string, default: "8rem", doc: "The length of a vertical slider, any CSS length.")

  attr(:filled, :boolean,
    default: false,
    doc: "Paints the track from its start to the thumb in the color."
  )

  attr(:show_value, :boolean, default: false, doc: "The value written beside the label.")

  attr(:value_format, :string,
    default: "%{value}",
    doc:
      "The text of the value, with `%{value}` where it goes: `\"%{value}%\"`, `\"R$ %{value}\"`."
  )

  attr(:marks, :list,
    default: [],
    doc:
      "Labels under the track: values or `{value, label}` pairs. A click on one sets the value (the nearer thumb of a range of two)."
  )

  attr(:steppers, :boolean, default: false, doc: "Minus and plus buttons that move by `step`.")

  attr(:decrease_label, :string,
    default: "Decrease",
    doc: "The accessible name of the minus button."
  )

  attr(:increase_label, :string,
    default: "Increase",
    doc: "The accessible name of the plus button."
  )

  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:help, :string, default: nil, doc: "The small line under the control.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show; `field` adds its own once the input was used."
  )

  attr(:disabled, :boolean, default: false)

  attr(:wrapper_class, :any,
    default: nil,
    doc: "Classes of the outer block (grid placement, spacing)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form list))

  def range(assigns) do
    assigns
    |> pair_fields()
    |> prepare()
    |> render_range()
  end

  defp pair_fields(%{start_field: %{} = from, end_field: %{} = to} = assigns) do
    assigns
    |> assign(start_field: nil, end_field: nil)
    |> assign(:start_name, assigns.start_name || from.name)
    |> assign(:end_name, assigns.end_name || to.name)
    |> assign_new(:id, fn -> from.id <> "_range" end)
    |> assign_new(:value, fn -> {from.value, to.value} end)
    |> assign(:errors, field_errors(from) ++ field_errors(to) ++ assigns.errors)
    |> pair_fields()
  end

  defp pair_fields(assigns), do: Control.assign_control(assigns)

  defp field_errors(field) do
    case Phoenix.Component.used_input?(field) do
      true -> Enum.map(field.errors, &translate_error/1)
      false -> []
    end
  end

  defp prepare(assigns) do
    pair? = is_binary(assigns.start_name) and is_binary(assigns.end_name)
    {low, high} = pair_values(assigns.value, pair?)

    assigns
    |> assign(
      pair?: pair?,
      vertical?: assigns.orientation == "vertical" and not pair?,
      id: assigns.id || assigns.name || assigns.start_name || gen_id("range"),
      low: low,
      high: high,
      bounds: bounds(assigns.min, assigns.max),
      marks: Enum.map(assigns.marks, &mark/1),
      plain?:
        not (assigns.show_value or assigns.filled or assigns.marks != [] or pair? or
               assigns.steppers or assigns.orientation == "vertical")
    )
    |> then(&assign(&1, :classes, classes(&1)))
  end

  defp pair_values({low, high}, _pair?), do: {number(low), number(high)}
  defp pair_values(value, true), do: {number(value), nil}
  defp pair_values(value, false), do: {number(value), nil}

  defp number(nil), do: nil
  defp number(value) when is_number(value), do: value

  defp number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp number(%{__struct__: Decimal} = value), do: value |> Format.machine() |> number()
  defp number(_value), do: nil

  defp bounds(min, max), do: {number(min) || 0, number(max) || 100}

  defp mark({value, label}), do: %{value: format(value), label: label, number: number(value)}
  defp mark(value), do: %{value: format(value), label: format(value), number: number(value)}

  defp format(value) when is_float(value) and value == trunc(value),
    do: Integer.to_string(trunc(value))

  defp format(value), do: to_string(value)

  defp position(nil, _bounds), do: 0

  defp position(value, {min, max}) when max > min,
    do: ((value - min) / (max - min) * 100) |> max(0.0) |> min(100.0) |> Float.round(2)

  defp position(_value, _bounds), do: 0

  defp anchor(percent, true) when percent <= 0, do: "translate-y-0"
  defp anchor(percent, true) when percent >= 100, do: "translate-y-full"
  defp anchor(_percent, true), do: "translate-y-1/2"
  defp anchor(percent, false) when percent <= 0, do: "translate-x-0"
  defp anchor(percent, false) when percent >= 100, do: "-translate-x-full"
  defp anchor(_percent, false), do: "-translate-x-1/2"

  defp edge_offset(percent, _size) when percent <= 0 or percent >= 100, do: 0
  defp edge_offset(percent, size), do: offset(percent, size)

  defp offset(percent, size),
    do: Float.round((0.5 - percent / 100) * Map.fetch!(@thumb_px, size), 2)

  defp value_text(template, value), do: String.replace(template, "%{value}", format(value || 0))

  defp pair_text(template, low, high),
    do: value_text(template, low) <> " – " <> value_text(template, high)

  defp classes(assigns) do
    merge([
      "form-range disabled:pointer-events-none disabled:opacity-60",
      @colors[assigns.color],
      @sizes[assigns.size],
      assigns.filled && "linea-range-filled",
      assigns.vertical? && "linea-range-vertical [direction:rtl] [writing-mode:vertical-lr]",
      assigns.vertical? && "h-full w-(--range-thumb-size)",
      assigns.class
    ])
  end

  defp render_range(%{plain?: true} = assigns) do
    ~H"""
    <Form.field
      id={@id}
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      class={@wrapper_class}
    >
      <input
        type="range"
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("range", @value)}
        min={@min}
        max={@max}
        step={@step}
        disabled={@disabled}
        class={@classes}
        {@rest}
      />
    </Form.field>
    """
  end

  defp render_range(%{pair?: true} = assigns) do
    {min, max} = assigns.bounds
    low = assigns.low || min
    high = assigns.high || max
    from = position(low, assigns.bounds)
    to = position(high, assigns.bounds)

    assigns =
      assign(assigns,
        low: low,
        high: high,
        fill_style: "left: #{from}%; width: #{Float.round(to - from, 2)}%",
        text: pair_text(assigns.value_format, low, high),
        min_text: format(min),
        max_text: format(max),
        input_class: merge(["form-range", @colors[assigns.color], @sizes[assigns.size]]),
        pair_class:
          merge(["linea-range-pair", @colors[assigns.color], @sizes[assigns.size], assigns.class])
      )

    ~H"""
    <div
      id={@id <> "-pair"}
      phx-hook="LineaUI.RangePair"
      data-format={@value_format}
      data-pair
      class={merge(["flex flex-col gap-1.5", @wrapper_class])}
    >
      <.header
        id={@id}
        label={@label}
        label_class={@label_class}
        show_value={@show_value}
        text={@text}
        for={"#{@id}-low #{@id}-high"}
      />
      <div
        role="group"
        aria-labelledby={@label && @id <> "-label"}
        class={@pair_class}
      >
        <span class="linea-range-track" aria-hidden="true"></span>
        <span data-fill class="linea-range-fill" style={@fill_style} aria-hidden="true"></span>
        <input
          type="range"
          id={@id <> "-low"}
          name={@start_name}
          value={format(@low)}
          min={@min_text}
          max={@max_text}
          step={@step}
          disabled={@disabled}
          class={@input_class}
          data-low
          {@rest}
        />
        <input
          type="range"
          id={@id <> "-high"}
          name={@end_name}
          value={format(@high)}
          min={@min_text}
          max={@max_text}
          step={@step}
          disabled={@disabled}
          class={@input_class}
          data-high
          {@rest}
        />
      </div>
      <.marks
        marks={@marks}
        bounds={@bounds}
        size={@size}
        vertical={false}
        pressed={[format(@low), format(@high)]}
      />
      <.messages help={@help} errors={@errors} />
    </div>
    """
  end

  defp render_range(assigns) do
    {min, max} = assigns.bounds
    value = assigns.low || min
    percent = position(value, assigns.bounds)

    assigns =
      assign(assigns,
        current: value,
        percent: percent,
        text: value_text(assigns.value_format, value),
        min_text: format(min),
        max_text: format(max)
      )

    ~H"""
    <div
      id={@id <> "-slider"}
      phx-hook="LineaUI.Range"
      data-format={@value_format}
      data-slider
      class={merge(["flex flex-col gap-1.5", @vertical? && "items-center", @wrapper_class])}
    >
      <.header
        id={@id}
        label={@label}
        label_class={@label_class}
        show_value={@show_value and not @vertical?}
        text={@text}
        for={@id}
      />
      <div class={["flex gap-2", (@vertical? && "flex-col-reverse items-center") || "items-center"]}>
        <output
          :if={@show_value and @vertical?}
          data-output
          for={@id}
          class="font-mono text-xs-plus font-medium text-slate-700 dark:text-navy-100"
        >
          {@text}
        </output>
        <.stepper
          :if={@steppers}
          direction="down"
          vertical={@vertical?}
          label={@decrease_label}
          disabled={@disabled}
        />
        <div
          class={["relative", (@vertical? && "flex") || "flex-1"]}
          style={@vertical? && "height: #{@height}"}
        >
          <input
            type="range"
            id={@id}
            name={@name}
            value={format(@current)}
            min={@min_text}
            max={@max_text}
            step={@step}
            disabled={@disabled}
            aria-orientation={@vertical? && "vertical"}
            style={"--p: #{@percent}%"}
            class={@classes}
            data-input
            {@rest}
          />
          <.marks
            :if={@marks != []}
            marks={@marks}
            bounds={@bounds}
            size={@size}
            vertical={@vertical?}
            pressed={[format(@current)]}
          />
        </div>
        <.stepper
          :if={@steppers}
          direction="up"
          vertical={@vertical?}
          label={@increase_label}
          disabled={@disabled}
        />
      </div>
      <.messages help={@help} errors={@errors} />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :show_value, :boolean, required: true
  attr :text, :string, required: true
  attr :for, :string, required: true

  defp header(assigns) do
    ~H"""
    <div :if={@label || @show_value} class="flex items-center justify-between gap-2">
      <label :if={@label} id={@id <> "-label"} for={@id} class={@label_class}>{@label}</label>
      <output
        :if={@show_value}
        data-output
        for={@for}
        class="font-mono text-xs-plus font-medium text-slate-700 dark:text-navy-100"
      >
        {@text}
      </output>
    </div>
    """
  end

  attr :direction, :string, required: true
  attr :vertical, :boolean, required: true
  attr :label, :string, required: true
  attr :disabled, :boolean, required: true

  defp stepper(assigns) do
    assigns = assign(assigns, :stepper_class, @stepper)

    ~H"""
    <button
      type="button"
      class={@stepper_class}
      tabindex="-1"
      aria-label={@label}
      disabled={@disabled}
      data-step-by={@direction}
    >
      <.glyph name={stepper_glyph(@direction, @vertical)} class="size-4" />
    </button>
    """
  end

  defp stepper_glyph("up", true), do: :chevron_up
  defp stepper_glyph("down", true), do: :chevron_down
  defp stepper_glyph("up", false), do: :chevron_right
  defp stepper_glyph("down", false), do: :chevron_left

  attr :marks, :list, required: true
  attr :bounds, :any, required: true
  attr :size, :string, required: true
  attr :vertical, :boolean, required: true
  attr :pressed, :list, required: true

  defp marks(%{marks: []} = assigns) do
    ~H""
  end

  defp marks(assigns) do
    assigns =
      assign(assigns,
        placed:
          Enum.map(assigns.marks, fn mark ->
            percent = position(mark.number, assigns.bounds)

            Map.merge(mark, %{
              percent: percent,
              offset: edge_offset(percent, assigns.size),
              anchor: anchor(percent, assigns.vertical)
            })
          end),
        mark_class: @mark
      )

    ~H"""
    <div class={["relative", (@vertical && "ml-2 w-10") || "mt-0.5 h-5 w-full"]}>
      <button
        :for={mark <- @placed}
        type="button"
        tabindex="-1"
        aria-pressed={bool(mark.value in @pressed)}
        data-mark={mark.value}
        class={[@mark_class, mark.anchor, (@vertical && "left-0") || "top-0"]}
        style={
          (@vertical && "bottom: calc(#{mark.percent}% + #{mark.offset}px)") ||
            "left: calc(#{mark.percent}% + #{mark.offset}px)"
        }
      >
        {mark.label}
      </button>
    </div>
    """
  end

  attr :help, :string, default: nil
  attr :errors, :list, default: []

  defp messages(assigns) do
    ~H"""
    <Form.help_text :if={@help}>{@help}</Form.help_text>
    <Form.error :for={message <- @errors}>{message}</Form.error>
    """
  end
end
