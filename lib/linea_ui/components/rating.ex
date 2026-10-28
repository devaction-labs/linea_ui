defmodule LineaUI.Components.Rating do
  @moduledoc """
  A star rating: read-only, with a fractional value and the count of reviews, or interactive, as a group of
  native radios; and `rating_distribution`, the summary with the average and a bar per grade.

      <.rating value={4.5} />
      <.rating value={4.2} show_value count={38} />
      <.rating value={3} size="lg" />

      <.rating id="service" name="service" label="Como foi o atendimento?" value={@grade}
        on_change="rate" />
      <.rating field={@form[:grade]} label="Nota" />
      <.rating value={3} disabled show_value />

      <.rating_distribution average={4.5} counts={[800, 310, 110, 40, 24]} />

  A value is drawn star by star: each one is filled by the proportion left, so `4.5` has four full
  stars and half of the fifth. The read-only rating is one `role="img"` with the text
  `4,5 de 5 estrelas`; pass `aria_label` for another language.

  It is read-only unless it gets a `field`, a `name` or an `on_change` (or `interactive`). Then it is a
  `radiogroup` of native radios, `max` of them: Tab enters the group, the arrow keys choose, and the
  hover previews the grade. The choice is made in the browser; a new `value` from the server wins.
  Inside a form the radios submit with the field's `name` and the form's `phx-change` runs as with
  plain radios:

      <.form for={@form} phx-change="validate">
        <.rating field={@form[:grade]} label="Como foi o atendimento?" />
      </.form>
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @sizes %{
    "sm" => %{box: "size-3.5", gap: "gap-0.5", text: "text-xs-plus"},
    "md" => %{box: "size-5", gap: "gap-0.5", text: "text-sm"},
    "lg" => %{box: "size-7", gap: "gap-1", text: "text-base"}
  }

  @path "M11.48 3.5a.56.56 0 0 1 1.04 0l2.13 5.11a.56.56 0 0 0 .48.35l5.52.44c.5.04.7.66.32.99l-4.2 3.6a.56.56 0 0 0-.18.56l1.28 5.39a.56.56 0 0 1-.84.61l-4.73-2.89a.56.56 0 0 0-.59 0l-4.73 2.89a.56.56 0 0 1-.84-.61l1.28-5.39a.56.56 0 0 0-.18-.56l-4.2-3.6a.56.56 0 0 1 .32-.99l5.52-.44a.56.56 0 0 0 .48-.35z"

  @doc """
  Renders a rating.

  Events: `on_change` is run when a grade is chosen. An event name is pushed with
  `%{"id" => id, "value" => "4"}` (to `target` when given); a `%JS{}` is executed.
  """
  attr :id, :string, doc: "Defaults to the field id, then `name`, then a generated one."

  attr :name, :string, doc: "Defaults to the field name; the interactive radios submit with it."

  attr :value, :any,
    doc: "The grade, `0` to `max`; fractional when read-only. Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :max, :integer, default: 5, doc: "How many stars."
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :count, :integer, default: nil, doc: "How many reviews, shown as `(38)` after the stars."

  attr :show_value, :boolean,
    default: false,
    doc: "The grade as a number, `4,2`, before the count."

  attr :decimal, :string, default: ",", doc: "The decimal separator of the number shown."

  attr :interactive, :boolean,
    default: nil,
    doc:
      "Radios instead of an image. Defaults to true with a `field`, a `name` or an `on_change`."

  attr :label, :string,
    default: nil,
    doc: "The caption above the interactive group; also its accessible name."

  attr :aria_label, :string,
    default: nil,
    doc: "The text a read-only rating gives a screen reader. Defaults to `4,5 de 5 estrelas`."

  attr :help, :string, default: nil
  attr :errors, :list, default: []

  attr :disabled, :boolean,
    default: false,
    doc: "Keeps the grade visible and ignores the pointer."

  attr :on_change, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run when a grade is chosen."

  attr :target, :any, default: nil, doc: "The `phx-target` of the `on_change` event."
  attr :class, :any, default: nil, doc: "Merged into the row of stars."
  attr :rest, :global

  def rating(assigns) do
    assigns
    |> Control.assign_control()
    |> then(&assign(&1, :id, &1.id || &1.name || gen_id("rating")))
    |> then(&assign(&1, :value, number(&1.value)))
    |> then(&assign(&1, :interactive, interactive?(&1)))
    |> then(&assign(&1, :styles, Map.fetch!(@sizes, &1.size)))
    |> then(&assign(&1, :path, @path))
    |> render_rating()
  end

  defp render_rating(%{interactive: true} = assigns) do
    assigns = assign(assigns, :chosen, round(assigns.value))

    ~H"""
    <Form.field
      id={@id}
      label={@label}
      help={@help}
      errors={@errors}
      as="div"
      label_class="mb-2 text-xs-plus text-slate-500 dark:text-navy-200"
    >
      <div
        id={@id}
        role="radiogroup"
        aria-labelledby={@label && "#{@id}-label"}
        aria-label={!@label && (@aria_label || "Avaliação")}
        aria-disabled={@disabled && "true"}
        class={
          merge([
            "relative inline-flex flex-row-reverse justify-end",
            @styles.gap,
            @disabled && "pointer-events-none opacity-50",
            "[&_input:checked~label_svg]:text-warning [&_label:hover_svg]:text-warning [&_label:hover~label_svg]:text-warning [&_label:hover_svg]:scale-110",
            @class
          ])
        }
        {@rest}
      >
        <%= for n <- @max..1//-1 do %>
          <input
            type="radio"
            id={"#{@id}-#{n}"}
            name={@name || @id}
            value={n}
            checked={@chosen == n}
            disabled={@disabled}
            phx-click={on_change_js(@on_change, @id, n, @target)}
            class="peer sr-only"
          />
          <label
            for={"#{@id}-#{n}"}
            aria-label={"#{n} de #{@max}"}
            class="cursor-pointer leading-none peer-focus-visible:[&_svg]:rounded peer-focus-visible:[&_svg]:outline-2 peer-focus-visible:[&_svg]:outline-offset-2 peer-focus-visible:[&_svg]:outline-primary dark:peer-focus-visible:[&_svg]:outline-accent-light"
          >
            <svg
              viewBox="0 0 24 24"
              aria-hidden="true"
              fill="currentColor"
              class={[
                @styles.box,
                "text-slate-300 transition-[color,transform] duration-100 motion-reduce:transition-none dark:text-navy-500"
              ]}
            >
              <path d={@path} />
            </svg>
          </label>
        <% end %>
      </div>
    </Form.field>
    """
  end

  defp render_rating(assigns) do
    assigns = assign(assigns, :label_text, assigns.aria_label || summary(assigns))

    ~H"""
    <div
      class={merge(["inline-flex items-center gap-2.5", @disabled && "opacity-50"])}
      {@rest}
    >
      <span role="img" aria-label={@label_text} class={["inline-flex", @styles.gap, @class]}>
        <.star :for={n <- 1..@max//1} fill={fill(@value, n)} box={@styles.box} path={@path} />
      </span>
      <span
        :if={@show_value}
        class={["font-semibold tabular-nums text-slate-800 dark:text-navy-50", @styles.text]}
      >
        {format(@value, @decimal)}
      </span>
      <span :if={@count} class={["tabular-nums text-slate-500 dark:text-navy-200", @styles.text]}>
        ({@count})
      </span>
    </div>
    """
  end

  attr :fill, :float, required: true
  attr :box, :string, required: true
  attr :path, :string, required: true

  defp star(assigns) do
    ~H"""
    <span class={["relative inline-block shrink-0", @box]} aria-hidden="true">
      <span class="absolute inset-0 block overflow-hidden text-slate-300 dark:text-navy-500">
        <svg viewBox="0 0 24 24" fill="currentColor" class={["block", @box]}><path d={@path} /></svg>
      </span>
      <span
        :if={@fill > 0}
        class="absolute inset-0 block overflow-hidden text-warning"
        style={"width: #{percent(@fill)}%"}
      >
        <svg viewBox="0 0 24 24" fill="currentColor" class={["block", @box]}><path d={@path} /></svg>
      </span>
    </span>
    """
  end

  @doc """
  Renders the summary of a rating: the average, its stars, the total and a bar per grade.

      <.rating_distribution average={4.5} counts={[800, 310, 110, 40, 24]} />
      <.rating_distribution counts={%{5 => 62, 4 => 24, 3 => 9, 2 => 3, 1 => 2}} unit="votos" />

  `counts` is how many reviews each grade got: a list from the best grade to the worst, or a map
  keyed by the grade. The bars are the share of the total; `average` and `total` are worked out from
  the counts unless given.
  """
  attr :counts, :any,
    required: true,
    doc: "A list, best grade first, or a map `%{grade => count}`."

  attr :average, :any, default: nil, doc: "Defaults to the weighted average of `counts`."
  attr :total, :integer, default: nil, doc: "Defaults to the sum of `counts`."
  attr :unit, :string, default: "avaliações", doc: "The word after the total."
  attr :decimal, :string, default: ",", doc: "The decimal separator of the average."
  attr :class, :any, default: nil
  attr :rest, :global

  def rating_distribution(assigns) do
    rows = rows(assigns.counts)
    total = assigns.total || rows |> Enum.map(& &1.count) |> Enum.sum()
    average = number(assigns.average) |> average(rows, total)

    assigns =
      assign(assigns,
        rows: Enum.map(rows, &Map.put(&1, :percent, share(&1.count, total))),
        total_count: total,
        mean: average,
        max: length(rows)
      )

    ~H"""
    <div
      class={merge(["grid grid-cols-[minmax(7.5rem,10rem)_1fr] items-center gap-6", @class])}
      {@rest}
    >
      <div>
        <div class="text-4xl font-semibold leading-none tabular-nums text-slate-800 dark:text-navy-50">
          {format(@mean, @decimal)}
        </div>
        <div class="my-1.5"><.rating value={@mean} size="sm" max={@max} /></div>
        <span class="block text-xs-plus tabular-nums text-slate-500 dark:text-navy-200">
          {delimit(@total_count)} {@unit}
        </span>
      </div>
      <ul class="m-0 list-none space-y-1.5 p-0">
        <li
          :for={row <- @rows}
          class="grid grid-cols-[0.875rem_1fr_2.5rem] items-center gap-2.5 text-xs-plus text-slate-500 dark:text-navy-200"
        >
          <span class="tabular-nums">{row.grade}</span>
          <span
            role="meter"
            aria-label={"#{row.grade} estrelas"}
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={row.percent}
            class="h-2 overflow-hidden rounded bg-slate-150 dark:bg-navy-500"
          >
            <span class="block h-full rounded bg-warning" style={"width: #{row.percent}%"}></span>
          </span>
          <span class="text-right tabular-nums">{row.percent}%</span>
        </li>
      </ul>
    </div>
    """
  end

  defp interactive?(%{interactive: nil} = assigns),
    do: assigns.field != nil or assigns.name != nil or assigns.on_change != nil

  defp interactive?(assigns), do: assigns.interactive

  defp number(nil), do: 0.0
  defp number(n) when is_number(n), do: n * 1.0
  defp number(""), do: 0.0

  defp number(n) when is_binary(n) do
    case Float.parse(n) do
      {f, _rest} -> f
      :error -> 0.0
    end
  end

  defp fill(value, n), do: min(1.0, max(0.0, value - (n - 1)))

  defp percent(fill), do: fill |> Kernel.*(100) |> Float.round(1) |> trim()

  defp trim(f) when f == trunc(f), do: trunc(f)
  defp trim(f), do: f

  defp format(value, decimal),
    do:
      value
      |> Float.round(1)
      |> :erlang.float_to_binary(decimals: 1)
      |> String.replace(".", decimal)

  defp summary(%{value: value, max: max, decimal: decimal}),
    do: "#{format(value, decimal)} de #{max} estrelas"

  defp on_change_js(nil, _id, _n, _target), do: nil
  defp on_change_js(%JS{} = js, _id, _n, _target), do: js

  defp on_change_js(event, id, n, target) when is_binary(event),
    do: JS.push(event, value: %{id: id, value: n}, target: target)

  defp rows(counts) when is_map(counts) do
    max = counts |> Map.keys() |> Enum.max(fn -> 0 end)
    for grade <- max..1//-1, do: %{grade: grade, count: Map.get(counts, grade, 0)}
  end

  defp rows(counts) when is_list(counts) do
    n = length(counts)
    counts |> Enum.with_index() |> Enum.map(fn {count, i} -> %{grade: n - i, count: count} end)
  end

  defp average(value, rows, total) when value == 0.0 and total > 0,
    do: rows |> Enum.map(&(&1.grade * &1.count)) |> Enum.sum() |> Kernel./(total)

  defp average(value, _rows, _total), do: value

  defp share(_count, 0), do: 0
  defp share(count, total), do: round(count / total * 100)

  defp delimit(n),
    do: n |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ".")
end
