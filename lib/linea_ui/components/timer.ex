defmodule LineaUI.Components.Timer do
  @moduledoc """
  A timer that ticks in the browser: a ring with the time in the middle for a cash register shift, a countdown or
  any stretch of time, and a small pill of it for a top bar.

      <.timer id="shift" elapsed={@shift_seconds} running={@running} kicker="Register open"
        kicker_paused="Paused" label="Register 01 · Ana Souza" on_toggle="shift_toggled">
        <:actions>
          <.button variant="soft" phx-click={LineaUI.Timer.toggle("shift")}>Pause</.button>
          <.button variant="outline" phx-click={LineaUI.Timer.add("shift", 900)}>+15 min</.button>
        </:actions>
      </.timer>

      <.timer id="break" direction="down" total={900} elapsed={0} color="warning" on_finish="break_over" />

  The `mini` variant is the pill for the top bar of a screen, with a pulsing dot while it runs:

      <header class="flex h-14 items-center justify-between px-5">
        <span>PDV</span>
        <.timer id="shift-mini" variant="mini" elapsed={@shift_seconds} running={@running} label="Shift time" />
      </header>

  The server owns the time: `elapsed` is the seconds counted so far, `running` whether it counts, and `total` the
  seconds the ring stands for (8 hours by default). The browser counts from there without a round trip, from a
  monotonic clock, so a background tab never loses a second. A new `elapsed`, `running`, `total` or `direction` from
  the server replaces what the browser counted; a patch that changes none of them leaves the count alone.

  `format` is `hms` (`03:12:45`), `hm` (`3h12`) or `hh:mm` (`03:12`), the mini clock of a top bar.

  `direction="up"` shows the time elapsed and fills the ring as it passes; `direction="down"` shows the time left
  (`total - elapsed`) and empties it. The ring is drawn in `color` while it runs and in warning when paused; the
  kicker under it is green while it runs and orange when paused.

  The timer has `role="timer"` and the accessible name `label` ("Timer" when there is none); the ticking text is not
  a live region, so a screen reader is not interrupted every second.

  ## Controls

  The buttons are the caller's, in the `actions` slot. They run in the browser, with no round trip, through
  `LineaUI.Timer`, which also pushes from the server:

      phx-click={LineaUI.Timer.pause("shift")}
      phx-click={LineaUI.Timer.resume("shift")}
      phx-click={LineaUI.Timer.toggle("shift")}
      phx-click={LineaUI.Timer.add("shift", 900)}

      LineaUI.Timer.add(socket, "shift", 900)

  `pause`, `resume` and `toggle` push `on_toggle` when the state changes; `add` takes time away with a negative number.
  Keep a server `running` assign in step with `on_toggle` so a later patch does not undo the choice:

      def handle_event("shift_toggled", %{"running" => running, "elapsed" => elapsed}, socket),
        do: {:noreply, assign(socket, running: running, shift_seconds: elapsed)}

  ## Events

  Each takes an event name or a `%JS{}` and goes to `target` when there is one.

    * `on_toggle` - a command paused or resumed it: `%{"id" => id, "running" => boolean, "elapsed" => seconds}`.
    * `on_tick` - every second: `%{"id" => id, "elapsed" => seconds, "remaining" => seconds}`. It is a round trip a
      second, leave it out unless the server needs it.
    * `on_finish` - once, when a countdown reaches zero (or a count up reaches `total` with `stop_at_total`); the
      timer stops: `%{"id" => id, "elapsed" => seconds}`.
  """

  use LineaUI.Component

  alias LineaUI.Components.Overlay

  @circumference 326.7

  @colors ~w(neutral primary secondary info success warning error)

  @rings %{
    "neutral" =>
      "group-data-[state=running]:stroke-slate-500 dark:group-data-[state=running]:stroke-navy-300",
    "primary" =>
      "group-data-[state=running]:stroke-primary dark:group-data-[state=running]:stroke-accent",
    "secondary" => "group-data-[state=running]:stroke-secondary",
    "info" => "group-data-[state=running]:stroke-info",
    "success" => "group-data-[state=running]:stroke-success",
    "warning" =>
      "group-data-[state=running]:stroke-warning-focus dark:group-data-[state=running]:stroke-warning",
    "error" => "group-data-[state=running]:stroke-error"
  }

  @ring_paused "group-data-[state=paused]:stroke-warning-focus dark:group-data-[state=paused]:stroke-warning"

  @ring_sizes %{
    "sm" => %{
      box: "size-32",
      time: "text-base leading-6",
      kicker: "text-[10px]",
      label: "text-[11px]"
    },
    "md" => %{
      box: "size-42",
      time: "text-[22px] leading-8",
      kicker: "text-[11px]",
      label: "text-xs"
    },
    "lg" => %{
      box: "size-52",
      time: "text-[28px] leading-10",
      kicker: "text-xs",
      label: "text-[13px]"
    }
  }

  @mini_sizes %{
    "sm" => "h-6.5 gap-1.5 rounded-[13px] pl-2 pr-2.5 text-xs",
    "md" => "h-8 gap-2 rounded-2xl pl-2 pr-3 text-[13px]",
    "lg" => "h-10 gap-2.5 rounded-[20px] pl-3 pr-4 text-[15px]"
  }

  @doc """
  Renders a timer.

      <.timer id="shift" elapsed={@seconds} running={@running} kicker="Register open" kicker_paused="Paused">
        <:actions>
          <.button phx-click={LineaUI.Timer.toggle("shift")}>Pause</.button>
        </:actions>
      </.timer>
  """
  attr :id, :string, required: true, doc: "Needed by the hook and by `LineaUI.Timer`."

  attr :elapsed, :integer,
    default: 0,
    doc: "The seconds counted so far. A new value from the server replaces the browser's count."

  attr :total, :integer,
    default: 28_800,
    doc: "The seconds the ring stands for, and where a countdown ends (8 hours by default)."

  attr :running, :boolean,
    default: true,
    doc: "Whether it counts. A change from the server replaces the browser's state."

  attr :direction, :string,
    default: "up",
    values: ~w(up down),
    doc: "`up` shows the time elapsed, `down` the time left (`total - elapsed`)."

  attr :variant, :string,
    default: "ring",
    values: ~w(ring mini),
    doc: "`ring` is the card with the ring, `mini` the pill for a top bar."

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "The ring's diameter (128, 168 or 208 px), or the pill's height."

  attr :color, :string,
    default: "primary",
    values: @colors,
    doc: "The ring while it runs (`ring` only); paused is always warning."

  attr :format, :string,
    default: "auto",
    values: ~w(auto hms hm hh:mm),
    doc:
      "`hms` is `03:12:45`, `hm` is `3h12`, `hh:mm` is `03:12`, `auto` is `hms` for the ring and `hm` for the pill."

  attr :kicker, :string,
    default: nil,
    doc: "The small uppercase text over the time while it runs (`ring` only)."

  attr :kicker_paused, :string,
    default: nil,
    doc: "The kicker while it is paused; the kicker itself when not set."

  attr :label, :string,
    default: nil,
    doc: "The line under the time, and the accessible name of the timer."

  attr :stop_at_total, :boolean,
    default: false,
    doc: "Counting up, stop at `total` and fire `on_finish`, instead of going past it."

  attr :on_toggle, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_tick, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_finish, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "The controls under the ring, the caller's buttons (`ring` only)."

  slot :caption,
    doc:
      "Replaces the `label` line under the time (`ring` only); the accessible name stays `label`."

  def timer(assigns) do
    {name, rest} = Map.pop(assigns.rest, :"aria-label")

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:name, name || assigns.label || "Timer")
      |> assign(:format, format_of(assigns.format, assigns.variant))

    assigns
    |> assign(:data, data(assigns))
    |> assign(:shown, shown(assigns))
    |> assign(:fraction, fraction(assigns))
    |> render()
  end

  defp render(%{variant: "mini"} = assigns) do
    ~H"""
    <span
      id={@id}
      role="timer"
      aria-label={@name}
      phx-hook="LineaUI.Timer"
      data-state={state(@running)}
      class={
        merge([
          "group inline-flex items-center bg-white font-mono font-medium text-slate-800 shadow-[inset_0_0_0_1px_var(--color-slate-300)] dark:bg-navy-700 dark:text-navy-50 dark:shadow-[inset_0_0_0_1px_var(--color-navy-450)]",
          mini_size(@size),
          @class
        ])
      }
      {@data}
      {@rest}
    >
      <i class="timer-dot size-2 shrink-0 rounded-full not-italic" aria-hidden="true"></i>
      <span data-time>{format_time(@shown, @format)}</span>
    </span>
    """
  end

  defp render(assigns) do
    ~H"""
    <div
      id={@id}
      role="timer"
      aria-label={@name}
      phx-hook="LineaUI.Timer"
      data-state={state(@running)}
      class={
        merge([
          "timer-checker group relative flex flex-col items-center rounded-lg bg-slate-50 px-5 py-6.5 shadow-[inset_0_0_0_1px_var(--color-slate-150)] dark:bg-navy-750 dark:shadow-[inset_0_0_0_1px_var(--color-navy-700)]",
          @class
        ])
      }
      {@data}
      {@rest}
    >
      <div class="relative z-1 flex flex-col items-center gap-3">
        <div class={["relative", ring_size(@size, :box)]}>
          <svg viewBox="0 0 120 120" class="size-full -rotate-90" aria-hidden="true">
            <circle
              cx="60"
              cy="60"
              r="52"
              fill="none"
              stroke-width="8"
              class="stroke-slate-150 dark:stroke-navy-800"
            />
            <circle
              data-ring
              cx="60"
              cy="60"
              r="52"
              fill="none"
              stroke-width="8"
              stroke-linecap="round"
              stroke-dasharray={circumference()}
              stroke-dashoffset={dash_offset(@fraction)}
              class={["transition-[stroke] duration-200", ring_color(@color), ring_paused()]}
            />
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span
              :if={@kicker}
              data-kicker-text
              class={[
                "font-inter font-semibold uppercase tracking-widest group-data-[state=running]:text-success-focus group-data-[state=paused]:text-warning-focus dark:group-data-[state=running]:text-success dark:group-data-[state=paused]:text-warning",
                ring_size(@size, :kicker)
              ]}
            >
              {kicker_text(@running, @kicker, @kicker_paused)}
            </span>
            <span
              data-time
              class={[
                "font-mono font-medium tracking-[0.02em] text-slate-800 dark:text-navy-50",
                ring_size(@size, :time)
              ]}
            >
              {format_time(@shown, @format)}
            </span>
            <span
              :if={@label != nil or @caption != []}
              class={["font-inter text-slate-400 dark:text-navy-300", ring_size(@size, :label)]}
            >
              {@label}{render_slot(@caption)}
            </span>
          </div>
        </div>
        <div :if={@actions != []} class="flex flex-wrap items-center justify-center gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  defp data(assigns) do
    %{
      "data-elapsed" => assigns.elapsed,
      "data-total" => assigns.total,
      "data-running" => to_string(assigns.running),
      "data-direction" => assigns.direction,
      "data-format" => assigns.format,
      "data-kicker" => assigns.kicker,
      "data-kicker-paused" => assigns.kicker_paused,
      "data-stop-at-total" => to_string(assigns.stop_at_total),
      "data-on-toggle" => callback(assigns.on_toggle, assigns),
      "data-on-tick" => callback(assigns.on_tick, assigns),
      "data-on-finish" => callback(assigns.on_finish, assigns)
    }
  end

  defp callback(event, assigns), do: Overlay.callback(event, assigns.id, assigns.target)

  defp format_of("auto", "mini"), do: "hm"
  defp format_of("auto", _variant), do: "hms"
  defp format_of(format, _variant), do: format

  defp state(true), do: "running"
  defp state(false), do: "paused"

  defp kicker_text(true, kicker, _paused), do: kicker
  defp kicker_text(false, kicker, nil), do: kicker
  defp kicker_text(false, _kicker, paused), do: paused

  defp shown(%{direction: "down"} = assigns), do: max(assigns.total - assigns.elapsed, 0)
  defp shown(assigns), do: max(assigns.elapsed, 0)

  defp fraction(%{total: total}) when total <= 0, do: 0.0

  defp fraction(%{direction: direction, elapsed: elapsed, total: total}) do
    done = min(1.0, max(elapsed, 0) / total)

    case direction do
      "down" -> 1.0 - done
      "up" -> done
    end
  end

  defp circumference, do: @circumference

  defp dash_offset(fraction), do: Float.round(@circumference * (1 - fraction), 1)

  defp format_time(seconds, "hm"),
    do: "#{div(seconds, 3600)}h#{pad(div(rem(seconds, 3600), 60))}"

  defp format_time(seconds, "hh:mm"),
    do: "#{pad(div(seconds, 3600))}:#{pad(div(rem(seconds, 3600), 60))}"

  defp format_time(seconds, "hms"),
    do: "#{pad(div(seconds, 3600))}:#{pad(div(rem(seconds, 3600), 60))}:#{pad(rem(seconds, 60))}"

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  defp ring_color(color), do: Map.fetch!(@rings, color)
  defp ring_paused, do: @ring_paused
  defp ring_size(size, part), do: @ring_sizes |> Map.fetch!(size) |> Map.fetch!(part)
  defp mini_size(size), do: Map.fetch!(@mini_sizes, size)
end
