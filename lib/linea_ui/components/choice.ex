defmodule LineaUI.Components.Choice do
  @moduledoc false

  use Phoenix.Component

  import LineaUI.ClassMerge, only: [merge: 1]
  import LineaUI.Components.Icon, only: [icon: 1]

  @tones %{
    {"basic", false} => %{
      "neutral" =>
        "border-slate-400/70 checked:border-slate-500 checked:bg-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-400 dark:checked:bg-navy-400",
      "primary" =>
        "border-slate-400/70 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 checked:border-secondary checked:bg-secondary hover:border-secondary focus:border-secondary dark:border-navy-400 dark:checked:border-secondary-light dark:checked:bg-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 checked:!border-info checked:bg-info hover:!border-info focus:!border-info dark:border-navy-400",
      "success" =>
        "border-slate-400/70 checked:!border-success checked:bg-success hover:!border-success focus:!border-success dark:border-navy-400",
      "warning" =>
        "border-slate-400/70 checked:!border-warning checked:bg-warning hover:!border-warning focus:!border-warning dark:border-navy-400",
      "error" =>
        "border-slate-400/70 checked:!border-error checked:bg-error hover:!border-error focus:!border-error dark:border-navy-400"
    },
    {"basic", true} => %{
      "neutral" =>
        "border-slate-400/70 bg-slate-100 checked:border-slate-500 checked:bg-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-500 dark:bg-navy-900 dark:checked:border-navy-400 dark:checked:bg-navy-400",
      "primary" =>
        "border-slate-400/70 bg-slate-100 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-500 dark:bg-navy-900 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 bg-slate-100 checked:border-secondary checked:bg-secondary hover:border-secondary focus:border-secondary dark:border-navy-500 dark:bg-navy-900 dark:checked:border-secondary-light dark:checked:bg-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 bg-slate-100 checked:!border-info checked:!bg-info hover:!border-info focus:!border-info dark:border-navy-500 dark:bg-navy-900",
      "success" =>
        "border-slate-400/70 bg-slate-100 checked:!border-success checked:!bg-success hover:!border-success focus:!border-success dark:border-navy-500 dark:bg-navy-900",
      "warning" =>
        "border-slate-400/70 bg-slate-100 checked:!border-warning checked:!bg-warning hover:!border-warning focus:!border-warning dark:border-navy-500 dark:bg-navy-900",
      "error" =>
        "border-slate-400/70 bg-slate-100 checked:!border-error checked:!bg-error hover:!border-error focus:!border-error dark:border-navy-500 dark:bg-navy-900"
    },
    {"outline", false} => %{
      "neutral" =>
        "border-slate-400/70 before:bg-slate-500 checked:border-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-400 dark:before:bg-navy-200 dark:checked:border-navy-200 dark:hover:border-navy-200 dark:focus:border-navy-200",
      "primary" =>
        "border-slate-400/70 before:bg-primary checked:border-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:before:bg-accent dark:checked:border-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 before:bg-secondary checked:border-secondary hover:border-secondary focus:border-secondary dark:border-navy-400 dark:before:bg-secondary-light dark:checked:border-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 before:!bg-info checked:!border-info hover:!border-info focus:!border-info dark:border-navy-400",
      "success" =>
        "border-slate-400/70 before:!bg-success checked:!border-success hover:!border-success focus:!border-success dark:border-navy-400",
      "warning" =>
        "border-slate-400/70 before:!bg-warning checked:!border-warning hover:!border-warning focus:!border-warning dark:border-navy-400",
      "error" =>
        "border-slate-400/70 before:!bg-error checked:!border-error hover:!border-error focus:!border-error dark:border-navy-400"
    },
    {"outline", true} => %{
      "neutral" =>
        "border-slate-400/70 bg-slate-100 before:bg-slate-500 checked:border-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-500 dark:bg-navy-900 dark:before:bg-navy-200 dark:checked:border-navy-200 dark:hover:border-navy-200 dark:focus:border-navy-200",
      "primary" =>
        "border-slate-400/70 bg-slate-100 before:bg-primary checked:border-primary hover:border-primary focus:border-primary dark:border-navy-500 dark:bg-navy-900 dark:before:bg-accent dark:checked:border-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 bg-slate-100 before:bg-secondary checked:border-secondary hover:border-secondary focus:border-secondary dark:border-navy-500 dark:bg-navy-900 dark:before:bg-secondary-light dark:checked:border-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 bg-slate-100 before:!bg-info checked:!border-info hover:!border-info focus:!border-info dark:border-navy-500 dark:bg-navy-900",
      "success" =>
        "border-slate-400/70 bg-slate-100 before:!bg-success checked:!border-success hover:!border-success focus:!border-success dark:border-navy-500 dark:bg-navy-900",
      "warning" =>
        "border-slate-400/70 bg-slate-100 before:!bg-warning checked:!border-warning hover:!border-warning focus:!border-warning dark:border-navy-500 dark:bg-navy-900",
      "error" =>
        "border-slate-400/70 bg-slate-100 before:!bg-error checked:!border-error hover:!border-error focus:!border-error dark:border-navy-500 dark:bg-navy-900"
    }
  }

  @variants %{
    "basic" => "is-basic",
    "outline" => "is-outline"
  }

  @sizes %{
    "xs" => "size-3",
    "sm" => "size-4",
    "md" => "size-5",
    "lg" => "size-6"
  }

  @disabled "disabled:pointer-events-none disabled:border-slate-300 disabled:opacity-60 dark:disabled:border-navy-450"

  @spec classes(String.t(), map()) :: [String.t()]
  def classes(base, %{variant: variant, filled: filled, color: color, size: size}) do
    [base, @variants[variant], @sizes[size], @tones[{variant, filled}][color], @disabled]
  end

  @chip "group/choice inline-flex h-[30px] cursor-pointer select-none items-center gap-1.5 rounded-full bg-slate-150 px-3 text-xs-plus font-medium tracking-wide text-slate-600 transition-colors duration-200 hover:not-has-checked:text-slate-800 has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary/50 has-disabled:pointer-events-none has-disabled:opacity-60 dark:bg-navy-800 dark:text-navy-200 dark:hover:not-has-checked:text-navy-50 dark:has-focus-visible:outline-accent/50"

  @chip_tones %{
    "neutral" =>
      "has-checked:bg-slate-700 has-checked:text-white dark:has-checked:bg-navy-450 dark:has-checked:text-white",
    "primary" =>
      "has-checked:bg-primary has-checked:text-white dark:has-checked:bg-accent dark:has-checked:text-white",
    "secondary" =>
      "has-checked:bg-secondary has-checked:text-white dark:has-checked:bg-secondary-light dark:has-checked:text-white",
    "info" => "has-checked:bg-info has-checked:text-white dark:has-checked:text-white",
    "success" => "has-checked:bg-success has-checked:text-white dark:has-checked:text-white",
    "warning" => "has-checked:bg-warning has-checked:text-white dark:has-checked:text-white",
    "error" => "has-checked:bg-error has-checked:text-white dark:has-checked:text-white"
  }

  @chip_count "inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-white px-1.5 text-tiny-plus font-semibold text-slate-600 group-has-checked/choice:bg-white/20 group-has-checked/choice:text-white dark:bg-navy-700 dark:text-navy-100 dark:group-has-checked/choice:bg-white/20 dark:group-has-checked/choice:text-white"

  @card "group/choice relative flex cursor-pointer items-start gap-3 rounded-lg border border-slate-300 px-4 py-3 transition-[border-color,box-shadow,background-color] duration-200 hover:border-slate-400 has-checked:ring-4 has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary/50 has-disabled:pointer-events-none has-disabled:opacity-60 dark:border-navy-450 dark:hover:border-navy-400 dark:has-focus-visible:outline-accent/50"

  @card_tones %{
    "neutral" =>
      "has-checked:border-slate-500 has-checked:bg-slate-500/5 has-checked:ring-slate-500/15 dark:has-checked:border-navy-300 dark:has-checked:bg-navy-300/5 dark:has-checked:ring-navy-300/15",
    "primary" =>
      "has-checked:border-primary has-checked:bg-primary/5 has-checked:ring-primary/15 dark:has-checked:border-accent dark:has-checked:bg-accent/10 dark:has-checked:ring-accent/20",
    "secondary" =>
      "has-checked:border-secondary has-checked:bg-secondary/5 has-checked:ring-secondary/15 dark:has-checked:border-secondary-light dark:has-checked:bg-secondary-light/10 dark:has-checked:ring-secondary-light/20",
    "info" =>
      "has-checked:border-info has-checked:bg-info/5 has-checked:ring-info/15 dark:has-checked:border-info dark:has-checked:bg-info/10",
    "success" =>
      "has-checked:border-success has-checked:bg-success/5 has-checked:ring-success/15 dark:has-checked:border-success dark:has-checked:bg-success/10",
    "warning" =>
      "has-checked:border-warning has-checked:bg-warning/5 has-checked:ring-warning/15 dark:has-checked:border-warning dark:has-checked:bg-warning/10",
    "error" =>
      "has-checked:border-error has-checked:bg-error/5 has-checked:ring-error/15 dark:has-checked:border-error dark:has-checked:bg-error/10"
  }

  @card_icons %{
    "neutral" =>
      "group-has-checked/choice:text-slate-700 dark:group-has-checked/choice:text-navy-100",
    "primary" =>
      "group-has-checked/choice:text-primary dark:group-has-checked/choice:text-accent-light",
    "secondary" =>
      "group-has-checked/choice:text-secondary dark:group-has-checked/choice:text-secondary-light",
    "info" => "group-has-checked/choice:text-info",
    "success" => "group-has-checked/choice:text-success",
    "warning" => "group-has-checked/choice:text-warning",
    "error" => "group-has-checked/choice:text-error"
  }

  @card_count "ml-auto inline-flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full bg-slate-150 px-1.5 text-tiny-plus font-semibold text-slate-600 dark:bg-navy-500 dark:text-navy-100"

  @layouts %{
    "basic" => "inline-space flex flex-wrap",
    "outline" => "inline-space flex flex-wrap",
    "card" => "grid gap-3",
    "chip" => "flex flex-wrap gap-2"
  }

  @doc false
  @spec variants() :: [String.t()]
  def variants, do: ~w(basic outline card chip)

  @doc false
  @spec layout(String.t()) :: String.t()
  def layout(variant), do: @layouts[variant]

  @doc false
  @spec input_classes(String.t(), map()) :: [String.t()] | String.t()
  def input_classes(_base, %{variant: "chip"}), do: "peer sr-only"

  def input_classes(base, %{variant: "card"} = assigns),
    do: classes(base, %{assigns | variant: "basic"})

  def input_classes(base, assigns), do: classes(base, assigns)

  @spec sizes() :: [String.t()]
  def sizes, do: ~w(xs sm md lg)

  @doc false
  attr(:label, :string, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:description, :string, default: nil)
  attr(:content, :list, default: [], doc: "Slot entries rendered as the label text.")
  attr(:text_class, :any, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def label(%{description: nil} = assigns) do
    ~H"""
    <label class={merge(["inline-flex items-center space-x-2", @class])}>
      {render_slot(@inner_block)}
      <span :if={@label || @content != []} class={merge([@text_class, @label_class])}>
        {@label}{render_slot(@content)}
      </span>
    </label>
    """
  end

  def label(assigns) do
    ~H"""
    <label class={merge(["inline-flex items-start space-x-2", @class])}>
      <span class="mt-0.5 flex">{render_slot(@inner_block)}</span>
      <span class="flex flex-col">
        <span class={merge([@text_class, @label_class])}>{@label}{render_slot(@content)}</span>
        <span class="text-xs text-slate-400 dark:text-navy-300">{@description}</span>
      </span>
    </label>
    """
  end

  @doc false
  @spec slot_content(list()) :: list()
  def slot_content([%{inner_block: nil}]), do: []
  def slot_content(slots), do: slots

  @doc false
  attr(:variant, :string, required: true)
  attr(:color, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:count, :any, default: nil)
  attr(:icon, :string, default: nil)
  attr(:content, :list, default: [])
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def item(%{variant: "chip"} = assigns) do
    assigns =
      assign(assigns, chip: @chip, tone: @chip_tones[assigns.color], count_class: @chip_count)

    ~H"""
    <label class={merge([@chip, @tone, @class])}>
      {render_slot(@inner_block)}
      <.icon :if={@icon} name={@icon} class="size-4" />
      <span>{@label}{render_slot(@content)}</span>
      <span :if={@count != nil} class={@count_class}>{@count}</span>
    </label>
    """
  end

  def item(%{variant: "card"} = assigns) do
    assigns =
      assign(assigns,
        card: @card,
        tone: @card_tones[assigns.color],
        icon_tone: @card_icons[assigns.color],
        count_class: @card_count
      )

    ~H"""
    <label class={merge([@card, @tone, @class])}>
      <span class="mt-0.5 flex shrink-0">{render_slot(@inner_block)}</span>
      <span
        :if={@icon}
        class={[
          "flex size-6 shrink-0 items-center justify-center text-slate-500 dark:text-navy-200",
          @icon_tone
        ]}
      >
        <.icon name={@icon} class="size-5" />
      </span>
      <span class="flex min-w-0 flex-col">
        <span class="font-medium text-slate-700 dark:text-navy-100">
          {@label}{render_slot(@content)}
        </span>
        <span :if={@description} class="mt-0.5 text-xs-plus text-slate-400 dark:text-navy-300">
          {@description}
        </span>
      </span>
      <span :if={@count != nil} class={@count_class}>{@count}</span>
    </label>
    """
  end

  def item(assigns) do
    ~H"""
    <.label label={@label} description={@description} content={@content} class={@class}>
      {render_slot(@inner_block)}
    </.label>
    """
  end
end
