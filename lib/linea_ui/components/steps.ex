defmodule LineaUI.Components.Steps do
  @moduledoc """
  LineOne's steps: numbered or plain points joined by a line, horizontal or vertical.

      <.steps>
        <:step label="Cart">1</:step>
        <:step label="Shipping">2</:step>
        <:step label="Payment">3</:step>
      </.steps>

      <.steps color="primary" orientation="vertical" line_space>
        <:step label="Ordered">1</:step>
        <:step label="Shipped">2</:step>
      </.steps>

      <.steps size="xs" line_space>
        <:step label="Done" color="primary" />
        <:step label="Now" color="secondary" ping />
        <:step label="Next" />
      </.steps>

  `color` paints every point and the line between them; a step's own `color` paints only its
  point. The content of a step is what its point shows (a number, an icon or nothing). A step's
  `state` (`done`, `current`, `error`, `todo`) picks its color and marks the current one.

  `stepper/1` is the progress version for wizards and checklists: states drawn as a bar and a
  numbered, checked or flagged dot, with a sub line and room for an action.

      <.stepper current={1}>
        <:step label="Company" sub="Tax id and address" />
        <:step label="Certificate" sub="File and password" />
        <:step label="Tax profile" sub="Regime and operations" />
      </.stepper>

      <.stepper orientation="vertical" current={3}>
        <:step label="Company data" sub="Signetum Ltda" />
        <:step label="Register products" sub="12 registered">
          <.button size="sm" color="primary">Import sheet</.button>
        </:step>
      </.stepper>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @sizes %{
    "xs" => "[--line:1px] [--size:.75rem]",
    "sm" => "[--size:1rem] [--line:1px]",
    "md" => nil,
    "lg" => "[--size:2.75rem] [--line:.5rem]"
  }

  @labels %{
    "xs" => "text-xs-plus text-slate-600 dark:text-navy-100",
    "sm" => "text-xs-plus text-slate-600 dark:text-navy-100",
    "md" => "text-slate-600 dark:text-navy-100",
    "lg" => "text-slate-600 dark:text-navy-100"
  }

  @lines %{
    "neutral" => "before:bg-slate-200 dark:before:bg-navy-500",
    "primary" => "before:bg-primary dark:before:bg-accent",
    "secondary" => "before:bg-secondary dark:before:bg-secondary-light",
    "accent" => "before:bg-accent dark:before:bg-accent",
    "info" => "before:bg-info",
    "success" => "before:bg-success",
    "warning" => "before:bg-warning",
    "error" => "before:bg-error"
  }

  @points %{
    "neutral" => "bg-slate-200 text-slate-800 dark:bg-navy-500 dark:text-white",
    "primary" => "bg-primary text-white dark:bg-accent",
    "secondary" => "bg-secondary text-white dark:bg-secondary-light",
    "accent" => "bg-accent text-white dark:bg-accent",
    "info" => "bg-info text-white",
    "success" => "bg-success text-white",
    "warning" => "bg-warning text-white",
    "error" => "bg-error text-white"
  }

  @pings %{
    "neutral" => "bg-slate-200 dark:bg-navy-500",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary dark:bg-secondary-light",
    "accent" => "bg-accent dark:bg-accent",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @state_colors %{"done" => "primary", "current" => nil, "error" => "error", "todo" => nil}

  @stepper_bars %{
    "done" => "bg-primary dark:bg-accent",
    "current" =>
      "bg-[linear-gradient(90deg,var(--color-primary)_50%,var(--color-slate-150)_50%)] dark:bg-[linear-gradient(90deg,var(--color-accent)_50%,var(--color-navy-600)_50%)]",
    "error" => "bg-error",
    "todo" => "bg-slate-150 dark:bg-navy-600"
  }

  @stepper_dots %{
    "done" => "bg-primary text-white dark:bg-accent",
    "current" =>
      "bg-white text-primary ring-2 ring-inset ring-primary dark:bg-navy-700 dark:text-accent-light dark:ring-accent",
    "error" => "bg-error text-white",
    "todo" => "bg-slate-150 text-slate-400 dark:bg-navy-600 dark:text-navy-300"
  }

  @stepper_labels %{
    "done" => "font-medium text-slate-700 dark:text-navy-50",
    "current" => "font-semibold text-slate-700 dark:text-navy-50",
    "error" => "font-semibold text-error",
    "todo" => "font-medium text-slate-500 dark:text-navy-200"
  }

  @stepper_links %{
    "done" => "before:bg-primary dark:before:bg-accent",
    "current" => "before:bg-slate-200 dark:before:bg-navy-500",
    "error" => "before:bg-slate-200 dark:before:bg-navy-500",
    "todo" => "before:bg-slate-200 dark:before:bg-navy-500"
  }

  @state_names %{
    "done" => "Completed",
    "current" => "Current",
    "error" => "Needs attention",
    "todo" => "Upcoming"
  }

  @vertical_gaps %{
    false => "space-x-4 not-last:pb-8",
    true => "space-x-4 not-last:pb-12"
  }

  @doc """
  Renders a list of steps. Each `:step` is a point (showing the slot's content) with an
  optional `label` under it, or beside it when vertical.

      <.steps color="primary">
        <:step label="Cart">1</:step>
        <:step label="Shipping" current>2</:step>
        <:step label="Payment">3</:step>
      </.steps>
  """
  attr(:color, :string,
    default: "neutral",
    doc: "Paints every point and the line between them.",
    values: ~w(neutral primary secondary accent info success warning error)
  )

  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg),
    doc: "`xs` and `sm` are bare dots with small labels."
  )

  attr(:line_space, :boolean,
    default: false,
    doc: "Leaves a gap between the points and the line."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :step, required: true, doc: "One step; its content is what the point shows." do
    attr(:label, :string, doc: "The text under (or beside) the point.")
    attr(:color, :string, doc: "The color of this step's point.")
    attr(:ping, :boolean, doc: "A pulsing ring around the point.")
    attr(:current, :boolean, doc: "Marks the step as the current one (`aria-current`).")

    attr(:state, :string,
      values: ~w(done current error todo),
      doc:
        "`done` paints the point primary and `error` red; `current` marks the step as the current one."
    )

    attr(:class, :any)
  end

  def steps(assigns) do
    ~H"""
    <ol
      class={
        merge([
          "steps",
          @orientation == "vertical" && "is-vertical",
          @line_space && "line-space",
          size_class(@size),
          @class
        ])
      }
      {@rest}
    >
      <li
        :for={step <- @step}
        class={
          merge(["step", step_class(@orientation, @line_space), line_class(@color), step[:class]])
        }
        aria-current={current?(step) && "step"}
      >
        <div class={["step-header rounded-full", point_class(point_color(step, @color))]}>
          <span
            :if={step[:ping]}
            class={[
              "inline-flex h-full w-full animate-ping rounded-full opacity-80",
              ping_class(point_color(step, @color))
            ]}
          ></span>
          {step.inner_block && render_slot(step)}
        </div>
        <h3 :if={step[:label]} class={label_class(@size)}>{step.label}</h3>
      </li>
    </ol>
    """
  end

  @doc """
  Renders a stepper: the steps of a wizard or a checklist, each `done`, `current`, `error` or `todo`.

  Give `current` (the index of the step being worked on, from 0) and the others follow: the ones before are done,
  the ones after are to do, and with `error` the current one is flagged. A `:step` can also carry its own `state`.
  The current step (and a flagged one) has `aria-current="step"`; every step has its state as hidden text for
  screen readers.

      <.stepper current={@step} error={@failed}>
        <:step label="Company" sub="Tax id and address" />
        <:step label="Certificate" sub="File and password" />
      </.stepper>

  `horizontal` draws a bar over each step; `vertical` joins the dots with a line, and a step's content (a button, a
  link) sits at its right end.
  """
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:current, :integer,
    default: nil,
    doc:
      "The index of the current step, from 0. The steps before it are `done`, the ones after `todo`."
  )

  attr(:error, :boolean, default: false, doc: "Flags the current step as `error`.")

  attr(:state_names, :map,
    default: @state_names,
    doc:
      "The hidden text read for each state, by `done`, `current`, `error` and `todo`; translate it with this."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :step, required: true, doc: "One step; its content is shown after its text." do
    attr(:label, :string, required: true)
    attr(:sub, :string, doc: "A smaller line under the label.")

    attr(:state, :string,
      values: ~w(done current error todo),
      doc: "Overrides the state `current` gives the step."
    )

    attr(:marker, :string, doc: "What the dot shows instead of the step number.")
    attr(:class, :any)
  end

  def stepper(assigns) do
    assigns = assign(assigns, :entries, entries(assigns))

    ~H"""
    <ol
      class={
        merge([
          "m-0 list-none p-0",
          @orientation == "horizontal" && "grid gap-3.5",
          @orientation == "vertical" && "flex flex-col",
          @class
        ])
      }
      style={columns(@orientation, length(@step))}
      {@rest}
    >
      <li
        :for={entry <- @entries}
        class={merge([stepper_item(@orientation, entry.state), entry.class])}
        aria-current={entry.state in ~w(current error) && "step"}
        data-state={entry.state}
      >
        <span
          :if={@orientation == "horizontal"}
          class={["h-1 rounded-sm", bar_class(entry.state)]}
        ></span>
        <span class={["flex gap-2.5", @orientation == "horizontal" && "items-center"]}>
          <span class={[
            "relative z-1 flex shrink-0 items-center justify-center rounded-full font-inter font-semibold",
            @orientation == "horizontal" && "size-7.5 text-xs-plus",
            @orientation == "vertical" && "size-7 text-xs",
            dot_class(entry.state)
          ]}>
            <.stepper_marker state={entry.state} number={entry.number} marker={entry.marker} />
          </span>
          <span class="min-w-0 flex-1 text-sm">
            <span class={["block", stepper_label(entry.state)]}>
              <span class="sr-only">{Map.fetch!(@state_names, entry.state)}: </span>{entry.label}
            </span>
            <span :if={entry.sub} class="block text-xs text-slate-400 dark:text-navy-300">
              {entry.sub}
            </span>
          </span>
          <span :if={@orientation == "vertical" && entry.content != []} class="shrink-0">
            {render_slot(entry.content)}
          </span>
        </span>
        <span :if={@orientation == "horizontal" && entry.content != []}>
          {render_slot(entry.content)}
        </span>
      </li>
    </ol>
    """
  end

  attr(:state, :string, required: true)
  attr(:number, :integer, required: true)
  attr(:marker, :string, required: true)

  defp stepper_marker(%{marker: marker} = assigns) when is_binary(marker), do: ~H"{@marker}"

  defp stepper_marker(%{state: "done"} = assigns) do
    ~H"""
    <.glyph name={:check} class="size-3.5" stroke_width="2.4" />
    """
  end

  defp stepper_marker(%{state: "error"} = assigns), do: ~H"!"
  defp stepper_marker(assigns), do: ~H"{@number}"

  defp entries(assigns) do
    assigns.step
    |> Enum.with_index()
    |> Enum.map(fn {step, index} ->
      %{
        label: step.label,
        sub: Map.get(step, :sub),
        marker: Map.get(step, :marker),
        class: Map.get(step, :class),
        content: (step.inner_block && [step]) || [],
        number: index + 1,
        state: Map.get(step, :state) || derived_state(index, assigns.current, assigns.error)
      }
    end)
  end

  defp derived_state(_index, nil, _error), do: "todo"
  defp derived_state(index, current, _error) when index < current, do: "done"
  defp derived_state(index, current, true) when index == current, do: "error"
  defp derived_state(index, current, false) when index == current, do: "current"
  defp derived_state(_index, _current, _error), do: "todo"

  defp columns("horizontal", count), do: "grid-template-columns: repeat(#{count}, minmax(0, 1fr))"
  defp columns("vertical", _count), do: nil

  defp bar_class(state), do: Map.fetch!(@stepper_bars, state)
  defp dot_class(state), do: Map.fetch!(@stepper_dots, state)
  defp stepper_label(state), do: Map.fetch!(@stepper_labels, state)

  defp stepper_item("horizontal", _state), do: "flex flex-col gap-2.5"

  defp stepper_item("vertical", state),
    do:
      merge([
        "relative flex flex-col pb-5 last:pb-0 before:absolute before:bottom-0.5 before:left-3.25 before:top-7.5 before:w-0.5 last:before:hidden",
        Map.fetch!(@stepper_links, state)
      ])

  defp current?(step), do: step[:current] == true or step[:state] == "current"

  defp point_color(step, default),
    do: step[:color] || Map.get(@state_colors, step[:state]) || default

  defp size_class(size), do: @sizes[size]
  defp label_class(size), do: @labels[size]
  defp line_class(color), do: @lines[color]
  defp point_class(color), do: @points[color]
  defp ping_class(color), do: @pings[color]

  defp step_class("vertical", line_space), do: @vertical_gaps[line_space]
  defp step_class("horizontal", _line_space), do: nil
end
