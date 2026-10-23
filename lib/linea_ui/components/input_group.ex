defmodule LineaUI.Components.InputGroup do
  @moduledoc """
  Joins inputs, addons, selects and buttons into one row with shared borders, as LineOne's
  input groups do. Only the outer ends keep their rounded corners.

      <.input_group>
        <.input_group_addon>@</.input_group_addon>
        <.input name="username" placeholder="Username" />
      </.input_group>

      <.input_group label="Price">
        <.input_group_addon variant="filled">$</.input_group_addon>
        <.input name="price" placeholder="Enter price" />
        <.input_group_addon variant="filled">.00</.input_group_addon>
      </.input_group>

      <.input_group shape="pill">
        <select class="form-select …">…</select>
        <.input name="price" placeholder="Price" />
        <.button>Purchase</.button>
      </.input_group>
  """

  use LineaUI.Component

  @base "flex -space-x-px [&>*]:rounded-none [&>*_.form-input]:rounded-none [&>*:hover]:z-10 [&>*:focus]:z-10 [&>*:focus-within]:z-10"

  @shapes %{
    "rounded" =>
      "[&>:first-child]:rounded-l-lg [&>:first-child_.form-input]:rounded-l-lg [&>:last-child]:rounded-r-lg [&>:last-child_.form-input]:rounded-r-lg",
    "pill" =>
      "[&>:first-child]:rounded-l-full [&>:first-child_.form-input]:rounded-l-full [&>:last-child]:rounded-r-full [&>:last-child_.form-input]:rounded-r-full"
  }

  @addons %{
    "outline" =>
      "flex shrink-0 items-center justify-center border border-slate-300 px-3.5 font-inter dark:border-navy-450",
    "filled" =>
      "flex shrink-0 items-center justify-center border border-slate-300 bg-slate-150 px-3.5 font-inter text-slate-800 dark:border-navy-450 dark:bg-navy-500 dark:text-navy-100"
  }

  @doc """
  Renders the row. `label` adds a caption above it.
  """
  attr(:shape, :string, default: "rounded", values: ~w(rounded pill))
  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")

  attr(:wrapper_class, :any,
    default: nil,
    doc: "Classes of the outer block (grid placement, spacing)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def input_group(%{label: nil} = assigns), do: render_group(assigns)

  def input_group(assigns) do
    ~H"""
    <div class={@wrapper_class}>
      <span class={@label_class}>{@label}</span>
      {render_group(assign(assigns, :class, merge(["mt-1.5", @class])))}
    </div>
    """
  end

  defp render_group(assigns) do
    assigns = assign(assigns, :classes, merge([@base, @shapes[assigns.shape], assigns.class]))

    ~H"""
    <div class={@classes} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  A text or icon box at either end (or between the inputs) of an `input_group`.
  """
  attr(:variant, :string, default: "outline", values: ~w(outline filled))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def input_group_addon(assigns) do
    ~H"""
    <span class={merge([addon_class(@variant), @class])} {@rest}>
      <span>{render_slot(@inner_block)}</span>
    </span>
    """
  end

  defp addon_class(variant), do: @addons[variant]
end
