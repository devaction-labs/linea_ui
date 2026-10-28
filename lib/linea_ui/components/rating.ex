defmodule LineaUI.Components.Rating do
  @moduledoc """
  A star rating, to read a score or to collect one.

      <.rating value={4.5} count={1284} />
      <.rating value={@product.score} size="lg" label="Rated 4.2 out of 5" />
      <.rating field={@form[:score]} readonly={false} label="How was the service?" />

  Read-only (the default) it is a `role="img"` with an `aria-label` that says the score; `value` takes a fraction
  and the last star is filled by that fraction. Interactive (`readonly={false}`) it is a group of native radios,
  one per star, so the keyboard and screen readers work without script; the form's own `phx-change` receives the
  chosen score. Hovering previews a score, and the chosen star stays filled.

  The fill is a fixed amber and does not depend on the theme; the empty stars follow it.
  """

  use LineaUI.Component

  @sizes %{"sm" => "size-4", "md" => "size-5", "lg" => "size-6"}
  @count_sizes %{"sm" => "text-xs", "md" => "text-sm", "lg" => "text-base"}

  @star "M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z"

  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "A form field; sets `id`, `name`, `value`.")
  attr(:id, :string, default: nil, doc: "Defaults to the field's id.")
  attr(:name, :string, default: nil, doc: "Defaults to the field's name; needed to submit a score.")
  attr(:value, :any, default: nil, doc: "The score: a number from 0 to `max`, a fraction when read-only.")
  attr(:max, :integer, default: 5, doc: "How many stars there are.")

  attr(:readonly, :boolean,
    default: true,
    doc: "`false` makes it a group of radios that collects a score."
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:count, :any, default: nil, doc: "How many ratings the score comes from, shown after the stars as `(1284)`.")

  attr(:label, :string,
    default: nil,
    doc:
      "Read-only: the `aria-label` (default `\"4.5 of 5 stars\"`). Interactive: the question, as the legend of the group."
  )

  attr(:star_label, :string,
    default: "star",
    doc: "Interactive: the noun of each radio's `aria-label` (`\"3 stars\"`); the plural adds an `s`."
  )

  attr(:disabled, :boolean, default: false)
  attr(:errors, :list, default: [], doc: "Messages to show; `field` adds its own once the input was used.")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form required))

  def rating(assigns) do
    assigns =
      assigns
      |> assign_field()
      |> then(fn assigns ->
        assigns
        |> assign(:score, score(assigns.value, assigns.max))
        |> assign(:id, assigns.id || gen_id("rating"))
      end)

    if assigns.readonly, do: render_read(assigns), else: render_input(assigns)
  end

  defp render_read(assigns) do
    ~H"""
    <span
      id={@id}
      role="img"
      aria-label={@label || read_label(@score, @max)}
      class={merge(["inline-flex items-center gap-1.5", @class])}
      {@rest}
    >
      <span class="inline-flex gap-0.5" aria-hidden="true">
        <span :for={n <- 1..@max//1} class={["relative inline-block", size(@size)]}>
          <.star class="text-slate-300 dark:text-navy-500" />
          <span
            class="absolute inset-y-0 left-0 overflow-hidden"
            style={"width: #{fill(@score, n)}%"}
            data-fill
          >
            <.star class={"text-amber-400 " <> size(@size)} />
          </span>
        </span>
      </span>
      <span
        :if={@count}
        class={[
          "font-medium tabular-nums text-slate-500 dark:text-navy-300",
          count_size(@size)
        ]}
      >
        ({@count})
      </span>
    </span>
    """
  end

  defp render_input(assigns) do
    assigns = assign(assigns, :chosen, if(assigns.score > 0, do: round(assigns.score)))

    ~H"""
    <fieldset
      id={@id}
      disabled={@disabled}
      class={merge(["m-0 min-w-0 border-0 p-0", @class])}
      {@rest}
    >
      <legend :if={@label} class="mb-1.5 p-0 text-sm font-medium text-slate-700 dark:text-navy-100">
        {@label}
      </legend>
      <div class={[
        "inline-flex flex-row-reverse gap-0.5",
        "[&_input:checked~label]:text-amber-400 [&_label:hover]:text-amber-400 [&_label:hover~label]:text-amber-400",
        "[&_input:focus-visible+label]:rounded-sm [&_input:focus-visible+label]:outline-2 [&_input:focus-visible+label]:outline-offset-2 [&_input:focus-visible+label]:outline-primary dark:[&_input:focus-visible+label]:outline-accent",
        @disabled && "pointer-events-none opacity-50"
      ]}>
        <%= for n <- @max..1//-1 do %>
          <input
            type="radio"
            id={"#{@id}-#{n}"}
            name={@name}
            value={n}
            checked={@chosen == n}
            disabled={@disabled}
            aria-label={star_text(n, @star_label)}
            class="peer sr-only"
          />
          <label
            for={"#{@id}-#{n}"}
            class={[
              "inline-block cursor-pointer text-slate-300 transition-colors dark:text-navy-500",
              size(@size)
            ]}
          >
            <.star />
          </label>
        <% end %>
      </div>
      <p :for={error <- @errors} class="mt-1.5 text-xs text-error" role="alert">{error}</p>
    </fieldset>
    """
  end

  attr(:class, :any, default: nil)

  defp star(assigns) do
    assigns = assign(assigns, :path, @star)

    ~H"""
    <svg viewBox="0 0 24 24" fill="currentColor" class={merge(["block size-full", @class])}>
      <path d={@path} />
    </svg>
    """
  end

  defp score(value, max) when is_number(value), do: (value |> min(max) |> max(0)) / 1

  defp score(value, max) when is_binary(value) do
    case Float.parse(value) do
      {number, _rest} -> score(number, max)
      :error -> 0.0
    end
  end

  defp score(_value, _max), do: 0.0

  defp fill(score, n) do
    part = (score - (n - 1)) |> min(1.0) |> max(0.0)
    Float.round(part * 100, 2)
  end

  defp read_label(score, max) do
    shown = if score == Float.round(score), do: trunc(score), else: Float.round(score, 1)
    "#{shown} of #{max} stars"
  end

  defp star_text(1, noun), do: "1 #{noun}"
  defp star_text(n, noun), do: "#{n} #{noun}s"

  defp size(size), do: @sizes[size]
  defp count_size(size), do: @count_sizes[size]
end
