defmodule LineaUI.Components.Switch do
  @moduledoc """
  daisyUI's toggle (`toggle`, `toggle-primary`, `toggle-sm`…): solid or outline (plain or filled track), pill or
  squircle, three sizes, in every theme color.

      <.switch name="notify" label="Notifications" color="primary" />
      <.switch field={@form[:public]} label="Public" variant="outline" color="success" />
      <.switch name="dense" size="sm" shape="squircle" thumb_inset={4} checked />
      <.switch name="email" label="Email" label_position="left" wrapper_class="w-full justify-between" />
  """

  use LineaUI.Component

  alias LineaUI.Components.Choice
  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @colors ~w(primary secondary info success warning error)
  @sizes %{"sm" => "toggle-sm", "md" => nil, "lg" => "toggle-lg"}

  @label_sizes %{
    "sm" => "text-xs",
    "md" => nil,
    "lg" => "text-base"
  }

  @label_positions %{"right" => nil, "left" => "flex-row-reverse space-x-reverse"}

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

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "daisyUI's `toggle-sm`, default and `toggle-lg`."
  )

  attr(:thumb_inset, :integer,
    default: 2,
    values: [2, 3, 4, 5, 6],
    doc: "Pixels between the thumb and the track edge: the higher, the smaller the thumb."
  )

  attr(:label, :string, default: nil, doc: "The caption.")

  attr(:label_position, :string,
    default: "right",
    values: ~w(right left),
    doc:
      "Which side of the switch the caption sits on. `left` puts the caption before the switch; add `wrapper_class=\"w-full justify-between\"` to push them to opposite ends."
  )

  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:description, :string, default: nil, doc: "A smaller grey line under the label.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show; `field` adds its own once the input was used."
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Dims the whole row (switch, label and description) and ignores the pointer."
  )

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
    |> then(
      &assign_derived(
        &1,
        :classes,
        [:variant, :filled, :color, :size, :shape, :thumb_inset, :class],
        fn -> classes(&1) end
      )
    )
    |> assign_derived(:text_class, [:size], fn -> @label_sizes[assigns.size] end)
    |> render_switch()
  end

  # daisyUI's `toggle`: its color and size; `outline` keeps the track clear until checked, `filled` tints it,
  # `squircle` rounds the corners less and `thumb_inset` sets the gap around the thumb (daisyUI's `--toggle-p`).
  defp classes(assigns) do
    merge([
      "toggle",
      assigns.color in @colors && "toggle-#{assigns.color}",
      @sizes[assigns.size],
      assigns.variant == "outline" && !assigns.filled && "bg-transparent",
      assigns.filled && "bg-base-200",
      assigns.shape == "squircle" && "[--radius-selector:calc(var(--radius-field)*.6)]",
      assigns.thumb_inset != 2 && "[--toggle-p:#{assigns.thumb_inset}px]",
      assigns.class
    ])
  end

  defp label_position(position), do: @label_positions[position]

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
      class={merge([label_position(@label_position), @wrapper_class])}
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
