defmodule LineaUI.Components.Progress do
  @moduledoc """
  LineOne's linear progress bar, solid or soft, in every size, with the active shimmer or the
  indeterminate slide.

      <.progress value={42} />
      <.progress value={70} color="success" variant="soft" />
      <.progress value={50} color="primary" active />
      <.progress indeterminate color="info" size="sm" />
      <.progress indeterminate shine color="primary" />
      <.progress value={30} color="warning" variant="soft" height="1.5" />
      <.progress value={60} color="white" />

  `value` is read against `max` (100 by default) and updates with the assign.

  It draws the canvas's `sg-meter`: `primary` is the accent bar, `success`, `warning`, `error` and `info`
  the canvas's positive, warning, negative and info colors, `neutral` the ink one.

  `progress_stack/1` is the canvas's stacked bar (`sg-stack`), the parts of a total side by side:

      <.progress_stack label="Sales by channel">
        <:segment value={46} label="Counter" />
        <:segment value={33} label="Online" />
        <:segment value={21} label="Reps" />
      </.progress_stack>
  """

  use LineaUI.Component

  @doc """
  Renders a progress bar.

      <.progress value={@uploaded} max={@total} color="success" variant="soft" active />
  """
  attr(:value, :any, default: 0, doc: "A number between 0 and `max`.")
  attr(:max, :any, default: 100)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white),
    doc: "The bar's color; `white` is a white bar on a translucent track, for colored cards."
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid soft),
    doc:
      "`soft` tints the track with the bar's color (`bg-{color}/15`); `solid` uses the gray track."
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg xl))

  attr(:height, :string,
    default: nil,
    values: [nil, "1", "1.5", "2", "3", "4"],
    doc:
      "A Tailwind height step (`h-1`, `h-1.5`...) that wins over `size`; `1.5` is the one `size` lacks."
  )

  attr(:active, :boolean, default: false, doc: "A light sweeping over the bar.")

  attr(:indeterminate, :boolean,
    default: false,
    doc: "A bar sliding across the track, when the end is not known."
  )

  attr(:shine, :boolean,
    default: false,
    doc:
      "With `indeterminate`, a light of the bar's color runs over the track instead of the bar sliding across it."
  )

  attr(:label, :string, default: nil, doc: "The `aria-label` of the progress bar.")
  attr(:class, :any, default: nil)
  attr(:bar_class, :any, default: nil)
  attr(:rest, :global)

  def progress(assigns) do
    assigns = assign(assigns, :percent, percent(assigns.value, assigns.max))

    ~H"""
    <div
      role="progressbar"
      aria-label={@label}
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={!@indeterminate && @value}
      class={merge(["sg-meter", tone(@color), @class])}
      {@rest}
    >
      <i
        class={merge([@indeterminate && "is-indeterminate relative w-4/12", @bar_class])}
        style={!@indeterminate && "width: #{@percent}%"}
      ></i>
    </div>
    """
  end

  defp tone("primary"), do: "acc"
  defp tone("success"), do: "pos"
  defp tone("warning"), do: "warn"
  defp tone("error"), do: "neg"
  defp tone("info"), do: "info"
  defp tone(_color), do: nil

  @doc """
  Renders the canvas's stacked bar (`sg-stack`): one segment per part, its width the part's share of `max`
  (100 by default), in the chart colors `--c1`, `--c2`... in order unless a segment sets `color`.

      <.progress_stack label="Sales by channel: counter 46%, online 33%, reps 21%">
        <:segment value={46} />
        <:segment value={33} />
        <:segment value={21} color="c4" />
      </.progress_stack>

  It is one image for screen readers (`role="img"`), named by `label`; a segment's `label` is its `title`.
  """
  attr(:max, :any, default: 100, doc: "The total the segments are read against.")
  attr(:label, :string, default: nil, doc: "The `aria-label`: say the parts and their values.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :segment, required: true, doc: "A part of the total." do
    attr(:value, :any, required: true, doc: "The part's amount, against `max`.")

    attr(:color, :string,
      doc: "A chart color of the canvas, `c1` to `c5` (by default the segment's position)."
    )

    attr(:label, :string, doc: "The segment's `title`.")
  end

  def progress_stack(assigns) do
    ~H"""
    <div role="img" aria-label={@label} class={merge(["sg-stack", @class])} {@rest}>
      <i
        :for={{segment, index} <- Enum.with_index(@segment)}
        title={segment[:label]}
        style={"width: #{percent(segment.value, @max)}%; background: var(--#{segment[:color] || "c#{rem(index, 5) + 1}"})"}
      ></i>
    </div>
    """
  end

  defp percent(value, limit) when is_number(value) and is_number(limit) and limit > 0,
    do: (value / limit * 100) |> min(100.0) |> max(0.0) |> Float.round(4)

  defp percent(_value, _max), do: 0
end
