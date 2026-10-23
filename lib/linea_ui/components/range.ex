defmodule LineaUI.Components.Range do
  @moduledoc """
  LineOne's range slider: a rounded track with a round thumb in the theme color, in three sizes.

      <.range name="volume" value={50} color="primary" />
      <.range field={@form[:level]} label="Level" min={0} max={10} size="lg" />
      <.range name="opacity" phx-debounce="100" />

  It is a native `<input type="range">`, so it submits with its form and fires `phx-change`
  as it is dragged.
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @colors %{
    "neutral" => "text-slate-500 dark:text-navy-300",
    "primary" => "text-primary dark:text-accent",
    "secondary" => "text-secondary dark:text-secondary-light",
    "info" => "text-info",
    "success" => "text-success",
    "warning" => "text-warning",
    "error" => "text-error"
  }

  @sizes %{
    "sm" => "[--range-track-h:3px] [--range-thumb-size:12px]",
    "md" => nil,
    "lg" => "[--range-track-h:8px] [--range-thumb-size:24px]"
  }

  @doc "Renders a range slider."
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any)
  attr(:min, :any, default: nil)
  attr(:max, :any, default: nil)
  attr(:step, :any, default: nil)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error)
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:help, :string, default: nil, doc: "The small line under the control.")

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
  attr(:rest, :global, include: ~w(form list))

  def range(assigns) do
    assigns
    |> Control.assign_control()
    |> then(&assign(&1, :classes, classes(&1)))
    |> render_range()
  end

  defp classes(assigns) do
    merge([
      "form-range disabled:pointer-events-none disabled:opacity-60",
      @colors[assigns.color],
      @sizes[assigns.size],
      assigns.class
    ])
  end

  defp render_range(assigns) do
    ~H"""
    <Form.field
      id={@id}
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      class={@wrapper_class}
    >
      <input
        type="range"
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("range", @value)}
        min={@min}
        max={@max}
        step={@step}
        disabled={@disabled}
        class={@classes}
        {@rest}
      />
    </Form.field>
    """
  end
end
