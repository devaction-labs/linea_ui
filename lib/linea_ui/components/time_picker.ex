defmodule LineaUI.Components.TimePicker do
  @moduledoc """
  LineOne's time picker (flatpickr with no calendar): an input with a clock icon that opens
  a card with the hour and the minute as two columns (an up arrow, a number box and a down
  arrow each) and, on a 12-hour clock with AM/PM, the AM/PM button beside them (or a 24-hour
  clock), held inside a minimum and a maximum.

      <.time_picker field={@form[:opens_at]} placeholder="Choose time..." />
      <.time_picker name="alarm" time_24hr min_time="15:00" max_time="22:30" />
      <.time_picker name="lunch" value="13:13" />

  The form gets `"HH:MM"` (24-hour) through a hidden input named like the field, and every
  change fires a bubbling `input` event for `phx-change`. The popup is an overlay:
  `LineaUI.open/close/toggle("id")` work on it.

  ## Keyboard and screen readers

  The popup is a dialog with a name, and the hour and minute boxes, the arrows over them and the
  AM/PM toggle are real controls you reach with `Tab`: `↑`/`↓` in a box step it, and the buttons
  have names ("Increase hour"...). An arrow that cannot move because `min_time` or `max_time`
  stop it is dimmed and `aria-disabled`. `Esc` closes the popup and gives the focus back to the
  input.
  """

  use LineaUI.Component

  @doc """
  Renders a time input.

      <.time_picker name="start" label="Start" minute_step={15} />

  Events: `on_change` is pushed with `%{"id" => id, "value" => "HH:MM"}` after each change, to
  `target` or to the LiveView/LiveComponent the picker is in.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :any, doc: "A `Time` or `\"HH:MM\"`."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :time_24hr, :boolean, default: false, doc: "Hours 0-23 instead of 1-12 with AM/PM."
  attr :min_time, :string, default: nil, doc: "The earliest time, `\"HH:MM\"`."
  attr :max_time, :string, default: nil, doc: "The latest time, `\"HH:MM\"`."
  attr :minute_step, :integer, default: 5, doc: "Minutes added by the arrows and the arrow keys."
  attr :hour_step, :integer, default: 1
  attr :default_hour, :integer, default: 12, doc: "The hour shown when the input is empty."

  attr :display_format, :string,
    default: nil,
    doc:
      "The text of the input in flatpickr tokens; `h:i K` (`9:30 AM`) by default, `H:i` with `time_24hr`."

  attr :locale, :string,
    default: "en",
    values: ~w(en pt_BR),
    doc: "The language of the texts of the popup (`labels`); the clock is set by `time_24hr`."

  attr :labels, :map,
    default: %{},
    doc:
      "Single texts of the popup, over the `locale` ones: `:picker_time_dialog` (its name), `:picker_hour`, `:picker_minute`, `:picker_hour_up`, `:picker_hour_down`, `:picker_minute_up`, `:picker_minute_down`, `:picker_toggle_period` (the AM/PM button)."

  attr :show_icon, :boolean, default: true
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Classes of the input."
  attr :rest, :global

  slot :icon, doc: "Replaces the clock icon."
  slot :trailing, doc: "Buttons joined to the right of the input."

  def time_picker(assigns) do
    assigns
    |> assign(
      mode: "single",
      min: nil,
      max: nil,
      disabled_dates: [],
      disabled_weekdays: [],
      week_start: 0,
      months: nil,
      weekdays: nil,
      today: nil,
      inline: false
    )
    |> LineaUI.Components.DatePicker.Shell.render_picker(:time, "LineaUI.TimePicker")
  end
end
