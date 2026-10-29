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

      <.input_group size="sm" label="Amount" errors={["must be positive"]}>
        <.input_group_addon variant="filled">$</.input_group_addon>
        <.input name="amount" state="error" />
      </.input_group>

  `size` (`sm` 32px, `md` 38px, `lg` 44px) sizes the addons, selects, inputs and buttons
  together. `errors` turns the shared border red and shows the messages under the row.
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @base "flex -space-x-px [&>*]:rounded-none [&>*_.form-input]:rounded-none [&>*:hover]:z-10 [&>*:focus]:z-10 [&>*:focus-within]:z-10"

  @shapes %{
    "rounded" =>
      "[&>:first-child]:rounded-l-lg [&>:first-child_.form-input]:rounded-l-lg [&>:last-child]:rounded-r-lg [&>:last-child_.form-input]:rounded-r-lg",
    "pill" =>
      "[&>:first-child]:rounded-l-full [&>:first-child_.form-input]:rounded-l-full [&>:last-child]:rounded-r-full [&>:last-child_.form-input]:rounded-r-full"
  }

  @sizes %{
    "sm" =>
      "[&>*]:!h-8 [&>*]:!text-[13px] [&_.form-input]:!h-8 [&_.form-input]:!text-[13px] [&_.form-select]:!h-8 [&_.form-select]:!text-[13px]",
    "md" => nil,
    "lg" =>
      "[&>*]:!h-11 [&>*]:!text-base [&_.form-input]:!h-11 [&_.form-input]:!text-base [&_.form-select]:!h-11 [&_.form-select]:!text-base"
  }

  @invalid "[&>*]:!border-error [&>*_.form-input]:!border-error [&>*_.form-select]:!border-error"

  @addons %{
    "outline" =>
      "flex shrink-0 items-center justify-center border border-slate-300 px-3.5 font-inter text-slate-500 dark:border-navy-450 dark:text-navy-200",
    "filled" =>
      "flex shrink-0 items-center justify-center border border-slate-300 bg-slate-150 px-3.5 font-inter text-slate-800 dark:border-navy-450 dark:bg-navy-500 dark:text-navy-100"
  }

  @addon_sizes %{
    "sm" => "px-3 text-xs-plus",
    "md" => nil,
    "lg" => "px-4 text-base"
  }

  @doc """
  Renders the row. `label` adds a caption above it, `help` and `errors` a line below it.

  The row is a `role="group"` named by the caption (`aria-labelledby`; pass an `id` to keep the
  caption's id stable). With `errors` (or `state="error"`) every border of the row turns red
  and the row gets `aria-invalid` and an `aria-describedby` that points at the messages; to
  mark the control itself, give the `input` inside `state="error"` too.
  """
  attr(:id, :string,
    default: nil,
    doc:
      "The row's id; the caption and messages derive theirs. Without it the id comes from the label, so give each group its own `id` when two share a label (rows of a repeated form)."
  )

  attr(:shape, :string, default: "rounded", values: ~w(rounded pill))

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Sizes the addons, selects, inputs and buttons together: 32px, 38px or 44px high."
  )

  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:help, :string, default: nil, doc: "The small line under the row.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show under the row; the shared border turns red."
  )

  attr(:state, :string, default: nil, values: [nil, "success", "error"])

  attr(:wrapper_class, :any,
    default: nil,
    doc: "Classes of the outer block (grid placement, spacing)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def input_group(assigns) do
    assigns =
      assigns
      |> assign(:state, Control.state(assigns.state, assigns.errors))
      |> assign(:base_id, assigns.id || group_id(assigns.label))

    if assigns.label == nil and assigns.help == nil and assigns.errors == [] do
      render_group(assigns)
    else
      ~H"""
      <div class={@wrapper_class}>
        <span :if={@label} id={"#{@base_id}-label"} class={@label_class}>{@label}</span>
        {render_group(assign(assigns, :class, merge([@label && "mt-1.5", @class])))}
        <div :if={@help || @errors != []} id={"#{@base_id}-messages"}>
          <Form.help_text :if={@help} state={if @state == "success", do: "success"}>
            {@help}
          </Form.help_text>
          <Form.error :for={message <- @errors}>{message}</Form.error>
        </div>
      </div>
      """
    end
  end

  defp group_id(nil), do: nil
  defp group_id(label), do: "input-group-#{:erlang.phash2(label)}"

  defp render_group(assigns) do
    assigns =
      assigns
      |> assign(:has_messages, assigns.help != nil or assigns.errors != [])
      |> assign(
        :classes,
        merge([
          @base,
          @shapes[assigns.shape],
          @sizes[assigns.size],
          assigns.state == "error" && @invalid,
          assigns.class
        ])
      )

    ~H"""
    <div
      id={@id}
      role="group"
      class={@classes}
      aria-labelledby={@label && "#{@base_id}-label"}
      aria-invalid={@state == "error" && "true"}
      aria-describedby={@has_messages && "#{@base_id}-messages"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A text or icon box at either end (or between the inputs) of an `input_group`. `size` sets the text of
  the box to match the `size` of the inputs next to it.
  """
  attr(:variant, :string, default: "outline", values: ~w(outline filled))
  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def input_group_addon(assigns) do
    assigns = assign(assigns, :addon_sizes, @addon_sizes)

    ~H"""
    <span class={merge([addon_class(@variant), @addon_sizes[@size], @class])} {@rest}>
      <span>{render_slot(@inner_block)}</span>
    </span>
    """
  end

  defp addon_class(variant), do: @addons[variant]
end
