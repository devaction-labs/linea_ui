defmodule LineaUI.Components.EmptyState do
  @moduledoc """
  An empty state: what the area is, why it is empty and the one next step, with the icon on a quadriculated grid.

      <.empty_state
        icon="huge-money-bag-01"
        kicker="Receivables"
        title="No receivable yet"
      >
        A receivable is created when an invoice paid in installments is authorized.
        <:action>
          <.button color="primary" variant="solid">New order</.button>
        </:action>
      </.empty_state>

      <.empty_state variant="inline" icon="huge-search-01" title="Nothing for “dipirona 1 g”">
        Try another term or clear the filters.
      </.empty_state>

  `icon` is a Hugeicons name (`huge-*`), which needs the Tailwind plugin of the Icons section of the README;
  leave it out, or pass the `illustration` slot, to draw something else.

  The `card` variant is a centered block for a whole area; the `inline` one is a compact notice for inside
  tables, lists and search results, in a neutral, success or error color.
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [icon: 1]

  @icon_tones %{
    "default" =>
      "bg-white text-primary shadow-[0_0_0_1px_var(--color-slate-200),0_10px_24px_-10px_rgb(79_70_229/0.45)] dark:bg-navy-700 dark:text-accent-light dark:shadow-[0_0_0_1px_var(--color-navy-600),0_10px_24px_-10px_rgb(79_70_229/0.45)]",
    "gradient" =>
      "bg-gradient-to-br from-indigo-600 to-purple-500 text-white shadow-[0_10px_24px_-8px_rgb(124_58_237/0.6)]"
  }

  @inline_colors %{
    "neutral" =>
      "text-slate-600 ring-1 ring-inset ring-slate-150 dark:text-navy-100 dark:ring-[#2c3a55]",
    "success" => "bg-success/10 text-success dark:bg-success/15",
    "error" => "bg-error/10 text-error dark:bg-error/15"
  }

  @inline_titles %{
    "neutral" => "text-slate-800 dark:text-navy-50",
    "success" => "text-inherit",
    "error" => "text-inherit"
  }

  @doc """
  Renders an empty state.

  The content is the reason it is empty; `action` takes the one next step (a button, or a button and a quiet link).
  """
  attr :variant, :string,
    default: "card",
    values: ~w(card inline table),
    doc:
      "`card` fills an area, `inline` is a compact notice for lists and search results, `table` is the centered notice (a 48px disc, a title, the reason and the next step) for the body of an empty table."

  attr :title, :string, required: true, doc: "What is missing, as a short sentence."

  attr :kicker, :string,
    default: nil,
    doc: "The small uppercase line above the title (`card` only)."

  attr :icon, :string,
    default: nil,
    doc: "A `LineaUI.Components.Icon.icon/1` name; the `:illustration` slot replaces it."

  attr :tone, :string,
    default: "default",
    values: ~w(default gradient),
    doc:
      "The icon tile of the `card` variant: white with a glow, or the indigo to purple gradient."

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral success error),
    doc: "The color of the `inline` variant."

  attr :level, :integer,
    default: 2,
    values: [2, 3, 4],
    doc: "The heading level of the title of a `card`."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :illustration, doc: "Replaces the `icon`, for an illustration or a custom glyph."
  slot :inner_block, doc: "The reason it is empty."
  slot :action, doc: "The next step."

  def empty_state(%{variant: "card"} = assigns) do
    ~H"""
    <section
      class={
        merge([
          "relative flex flex-col items-center gap-2.5 overflow-hidden rounded-lg bg-white px-7 pb-7.5 pt-9 text-center shadow-soft dark:bg-navy-700 dark:shadow-none dark:ring-1 dark:ring-[#2c3a55]",
          @class
        ])
      }
      {@rest}
    >
      <span class="empty-grid pointer-events-none absolute inset-x-0 top-0 h-42.5" aria-hidden="true"></span>
      <span
        class={[
          "relative z-1 flex size-15 items-center justify-center rounded-2xl",
          tone_class(@tone)
        ]}
        aria-hidden="true"
      >
        <.icon :if={@icon && @illustration == []} name={@icon} class="size-6.5" />
        {render_slot(@illustration)}
      </span>
      <span
        :if={@kicker}
        class="relative z-1 mt-2.5 font-inter text-tiny-plus font-semibold uppercase tracking-widest text-slate-400 dark:text-navy-300"
      >
        {@kicker}
      </span>
      <.dynamic_tag
        tag_name={"h#{@level}"}
        class="relative z-1 text-[17px] font-semibold text-slate-800 dark:text-navy-50"
      >
        {@title}
      </.dynamic_tag>
      <p
        :if={@inner_block != []}
        class="relative z-1 max-w-75 text-xs-plus leading-5 text-slate-500 dark:text-navy-200"
      >
        {render_slot(@inner_block)}
      </p>
      <div :if={@action != []} class="relative z-1 mt-2 flex flex-wrap justify-center gap-2">
        {render_slot(@action)}
      </div>
    </section>
    """
  end

  def empty_state(%{variant: "table"} = assigns) do
    ~H"""
    <div
      class={merge(["flex flex-col items-center gap-1.5 px-5 pt-10 pb-11 text-center", @class])}
      {@rest}
    >
      <span
        class="mb-2 grid size-12 place-items-center rounded-full bg-slate-100 text-slate-400 dark:bg-navy-600 dark:text-navy-300"
        aria-hidden="true"
      >
        <.icon :if={@icon && @illustration == []} name={@icon} class="size-6" />
        {render_slot(@illustration)}
      </span>
      <b class="text-[15px] font-semibold text-slate-800 dark:text-navy-50">{@title}</b>
      <span :if={@inner_block != []} class="text-[13px] text-slate-500 dark:text-navy-200">
        {render_slot(@inner_block)}
      </span>
      <div :if={@action != []} class="mt-2.5 text-[13px] font-medium">{render_slot(@action)}</div>
    </div>
    """
  end

  def empty_state(assigns) do
    ~H"""
    <div
      class={
        merge([
          "flex items-center gap-3 rounded-lg px-4 py-3.5 text-xs-plus",
          inline_color(@color),
          @class
        ])
      }
      role={@color == "error" && "alert"}
      {@rest}
    >
      <span class="flex shrink-0 items-center" aria-hidden="true">
        <.icon :if={@icon && @illustration == []} name={@icon} class="size-5" />
        {render_slot(@illustration)}
      </span>
      <span class="min-w-0 flex-1">
        <b class={["block text-sm font-medium", inline_title(@color)]}>{@title}</b>
        <span :if={@inner_block != []} class="opacity-90">{render_slot(@inner_block)}</span>
      </span>
      <div :if={@action != []} class="shrink-0">{render_slot(@action)}</div>
    </div>
    """
  end

  defp tone_class(tone), do: Map.fetch!(@icon_tones, tone)
  defp inline_color(color), do: Map.fetch!(@inline_colors, color)
  defp inline_title(color), do: Map.fetch!(@inline_titles, color)
end
