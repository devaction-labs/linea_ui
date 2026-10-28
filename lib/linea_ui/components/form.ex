defmodule LineaUI.Components.Form do
  @moduledoc """
  The pieces LineOne's forms are made of: a caption, a help line, an error line and the
  `field` wrapper that puts them around any control.

      <.label for="email">Email</.label>
      <.help_text>We never share it.</.help_text>
      <.error>can't be blank</.error>

      <.field label="Country" help="Where you live" errors={@form[:country].errors}>
        <select class="form-select ...">…</select>
      </.field>

  `input`, `textarea`, `range` and the groups already render their own field, so `field` is
  for the controls LineaUI does not draw (a native `<select>`, a third-party widget).
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Control

  @help %{
    nil => "text-tiny-plus text-slate-400 dark:text-navy-300",
    "success" => "inline-flex items-center gap-1 text-tiny-plus text-success",
    "error" => "text-tiny-plus text-error"
  }

  @doc """
  A caption for the control with the id `for`.

      <.label for="username">Choose Username:</.label>
  """
  attr(:for, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class={merge(["block", @class])} {@rest}>{render_slot(@inner_block)}</label>
    """
  end

  @doc """
  A validation message, in LineOne's small red text. It has `role="alert"`, so a screen reader
  announces it when it appears.

      <.error>Username is invalid</.error>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <span role="alert" class={merge(["block text-tiny-plus text-error", @class])} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  The small line under a control that explains it. `state="success"` paints it green and
  `state="error"` red, as LineOne's validation examples do; the green one starts with a 14px
  check-circle icon.

      <.help_text>This is a help text</.help_text>
      <.help_text state="success">Username is valid</.help_text>
  """
  attr(:state, :string, default: nil, values: [nil, "success", "error"])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def help_text(assigns) do
    ~H"""
    <span class={merge([help_class(@state), @class])} {@rest}>
      <.glyph :if={@state == "success"} name={:check_circle} class="size-3.5 shrink-0" />
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp help_class(state), do: @help[state]

  @doc """
  Wraps a control with its caption, help line and errors, laid out the way LineOne's forms
  are: the caption on top, the control `mt-1.5` under it, then the help and the errors.

  With `as="label"` (the default) the whole block is a `<label>`, so a click on the caption
  focuses the control. Groups of checkboxes or radios use `as="div"`, and their own container
  then lays the options out.

      <.field label="Category" help="Pick one">
        <select class="form-select w-full ...">…</select>
      </.field>
  """
  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "Takes the errors from a form field.")
  attr(:id, :string, doc: "The id of the control, for the caption's `for`.")
  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:help, :string, default: nil, doc: "The small line under the control.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show; `field` adds its own once the input was used."
  )

  attr(:state, :string, default: nil, values: [nil, "success", "error"])
  attr(:as, :string, default: "label", values: ~w(label div))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  slot(:aside,
    doc:
      "A small piece (a character counter) on the same row as the help and the errors, at the right."
  )

  def field(assigns) do
    assigns
    |> Control.assign_control()
    |> render_field()
  end

  defp render_field(%{as: "label"} = assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <label class="block" for={@id}>
        <span :if={@label} class={@label_class}>{@label}</span>
        <span class={control_class(@label)}>{render_slot(@inner_block)}</span>
      </label>
      <.message_row help={@help} errors={@errors} state={@state} aside={@aside} />
    </div>
    """
  end

  defp render_field(%{as: "div"} = assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <span :if={@label} class={merge(["block", @label_class])} id={@id && "#{@id}-label"}>
        {@label}
      </span>
      {render_slot(@inner_block)}
      <.message_row help={@help} errors={@errors} state={@state} aside={@aside} />
    </div>
    """
  end

  defp control_class(nil), do: "flex"
  defp control_class(_label), do: "mt-1.5 flex"

  attr(:help, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:state, :string, default: nil)
  attr(:aside, :list, default: [])

  defp message_row(%{aside: []} = assigns) do
    ~H"""
    <.messages help={@help} errors={@errors} state={@state} />
    """
  end

  defp message_row(assigns) do
    ~H"""
    <div class="mt-1 flex items-start justify-between gap-3">
      <div class="min-w-0"><.messages help={@help} errors={@errors} state={@state} /></div>
      <div class="ml-auto shrink-0">{render_slot(@aside)}</div>
    </div>
    """
  end

  attr(:help, :string, default: nil, doc: "The small line under the control.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show; `field` adds its own once the input was used."
  )

  attr(:state, :string, default: nil)

  defp messages(assigns) do
    ~H"""
    <.help_text :if={@help} state={help_state(@state, @errors)}>{@help}</.help_text>
    <.error :for={message <- @errors}>{message}</.error>
    """
  end

  defp help_state(state, []), do: state
  defp help_state(_state, _errors), do: nil
end
