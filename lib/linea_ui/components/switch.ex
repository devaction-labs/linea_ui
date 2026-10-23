defmodule LineaUI.Components.Switch do
  @moduledoc """
  LineOne's switches: solid or outline (plain or filled track), pill or squircle, three sizes,
  four thumb sizes, in every theme color.

      <.switch name="notify" label="Notifications" color="primary" />
      <.switch field={@form[:public]} label="Public" variant="outline" color="success" />
      <.switch name="dense" size="sm" shape="squircle" thumb_inset={4} checked />
  """

  use LineaUI.Component

  alias LineaUI.Components.Choice
  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @variants %{
    {"basic", false} =>
      "form-switch bg-slate-300 before:bg-slate-50 checked:before:bg-white dark:bg-navy-900 dark:before:bg-navy-300 dark:checked:before:bg-white",
    {"basic", true} =>
      "form-switch bg-slate-300 before:bg-slate-50 checked:before:bg-white dark:bg-navy-900 dark:before:bg-navy-300 dark:checked:before:bg-white",
    {"outline", false} =>
      "form-switch is-outline border border-slate-400/70 bg-transparent before:bg-slate-300 dark:border-navy-400 dark:before:bg-navy-300",
    {"outline", true} =>
      "form-switch is-outline border border-slate-400/70 bg-slate-100 before:bg-slate-300 dark:border-navy-500 dark:bg-navy-900 dark:before:bg-navy-400"
  }

  @colors %{
    "basic" => %{
      "neutral" => "checked:bg-slate-500 dark:checked:bg-navy-400",
      "primary" => "checked:bg-primary dark:checked:bg-accent",
      "secondary" => "checked:bg-secondary dark:checked:bg-secondary-light",
      "info" => "checked:!bg-info",
      "success" => "checked:!bg-success",
      "warning" => "checked:!bg-warning",
      "error" => "checked:!bg-error"
    },
    "outline" => %{
      "neutral" =>
        "checked:border-slate-500 checked:before:bg-slate-500 dark:checked:border-navy-200 dark:checked:before:bg-navy-200",
      "primary" =>
        "checked:border-primary checked:before:bg-primary dark:checked:border-accent dark:checked:before:bg-accent",
      "secondary" =>
        "checked:border-secondary checked:before:bg-secondary dark:checked:border-secondary-light dark:checked:before:bg-secondary-light",
      "info" => "checked:!border-info checked:before:!bg-info",
      "success" => "checked:!border-success checked:before:!bg-success",
      "warning" => "checked:!border-warning checked:before:!bg-warning",
      "error" => "checked:!border-error checked:before:!bg-error"
    }
  }

  @shapes %{
    "pill" => "rounded-full before:rounded-full",
    "squircle" => "rounded-lg before:rounded-md"
  }

  @sizes %{
    "sm" => "h-3.5 w-7",
    "md" => "h-5 w-10",
    "lg" => "h-7 w-14"
  }

  @label_sizes %{
    "sm" => "text-xs",
    "md" => nil,
    "lg" => "text-base"
  }

  @thumbs %{
    2 => nil,
    3 => "[--thumb-border:3px]",
    4 => "[--thumb-border:4px]",
    5 => "[--thumb-border:5px]",
    6 => "[--thumb-border:6px]"
  }

  @disabled "disabled:pointer-events-none disabled:select-none disabled:opacity-60"

  @doc """
  Renders a switch: a checkbox drawn as a track and thumb. Like `checkbox`, it sends
  `unchecked_value` through a hidden input when off.
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any)
  attr(:checked, :boolean, doc: "Defaults to whether `value` (or the field's value) is true.")
  attr(:checked_value, :string, default: "true")
  attr(:unchecked_value, :string, default: "false")
  attr(:hidden_input, :boolean, default: true)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error)
  )

  attr(:variant, :string, default: "basic", values: ~w(basic outline))
  attr(:filled, :boolean, default: false, doc: "A tinted track, for `outline`.")
  attr(:shape, :string, default: "pill", values: ~w(pill squircle))
  attr(:size, :string, default: "md", values: ~w(sm md lg))

  attr(:thumb_inset, :integer,
    default: 2,
    values: [2, 3, 4, 5, 6],
    doc: "Pixels between the thumb and the track edge: the higher, the smaller the thumb."
  )

  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:description, :string, default: nil, doc: "A smaller grey line under the label.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show; `field` adds its own once the input was used."
  )

  attr(:disabled, :boolean, default: false)

  attr(:wrapper_class, :any,
    default: nil,
    doc: "Classes of the outer block (grid placement, spacing)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form required))
  slot(:inner_block, doc: "Label content, instead of `label`.")

  def switch(assigns) do
    assigns
    |> Control.assign_control()
    |> assign_new(:checked, fn %{value: value} ->
      Phoenix.HTML.Form.normalize_value("checkbox", value)
    end)
    |> then(&assign(&1, :classes, classes(&1)))
    |> then(&assign(&1, :text_class, @label_sizes[&1.size]))
    |> render_switch()
  end

  defp classes(assigns) do
    merge([
      @variants[{assigns.variant, assigns.filled}],
      @colors[assigns.variant][assigns.color],
      @sizes[assigns.size],
      @shapes[assigns.shape],
      @thumbs[assigns.thumb_inset],
      @disabled,
      assigns.class
    ])
  end

  defp render_switch(assigns) do
    ~H"""
    <input
      :if={@hidden_input && @name}
      type="hidden"
      name={@name}
      value={@unchecked_value}
      disabled={@disabled}
      form={@rest[:form]}
    />
    <Choice.label
      label={@label}
      label_class={@label_class}
      text_class={@text_class}
      description={@description}
      content={@inner_block}
      class={@wrapper_class}
    >
      <input
        type="checkbox"
        role="switch"
        id={@id}
        name={@name}
        value={@checked_value}
        checked={@checked}
        disabled={@disabled}
        class={@classes}
        aria-invalid={@errors != [] && "true"}
        {@rest}
      />
    </Choice.label>
    <Form.error :for={message <- @errors}>{message}</Form.error>
    """
  end
end
