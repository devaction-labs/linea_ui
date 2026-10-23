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
  point. The content of a step is what its point shows (a number, an icon or nothing).
  """

  use LineaUI.Component

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
        aria-current={step[:current] && "step"}
      >
        <div class={["step-header rounded-full", point_class(step[:color] || @color)]}>
          <span
            :if={step[:ping]}
            class={[
              "inline-flex h-full w-full animate-ping rounded-full opacity-80",
              ping_class(step[:color] || @color)
            ]}
          ></span>
          {step.inner_block && render_slot(step)}
        </div>
        <h3 :if={step[:label]} class={label_class(@size)}>{step.label}</h3>
      </li>
    </ol>
    """
  end

  defp size_class(size), do: @sizes[size]
  defp label_class(size), do: @labels[size]
  defp line_class(color), do: @lines[color]
  defp point_class(color), do: @points[color]
  defp ping_class(color), do: @pings[color]

  defp step_class("vertical", line_space), do: @vertical_gaps[line_space]
  defp step_class("horizontal", _line_space), do: nil
end
