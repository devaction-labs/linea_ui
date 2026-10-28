defmodule LineaUI.Components.Radio do
  @moduledoc """
  LineOne's radios, in a group that shares one `name`: basic or outline, plain or filled box,
  circle or squircle, in every theme color.

      <.radio_group field={@form[:plan]} options={[{"Free", "free"}, {"Pro", "pro"}]} color="primary" />

      <.radio_group name="basic" value="primary" class="grid grid-cols-2 gap-6 sm:grid-cols-3">
        <:radio value="default">Default</:radio>
        <:radio value="primary" color="primary">Primary</:radio>
        <:radio value="error" color="error" disabled>Error</:radio>
      </.radio_group>

  A `md` radio is 18px with a 6px dot (`xs` 12px, `sm` 16px, `lg` 24px).

  `variant="card"` lays each option out as a bordered card (title, description, optional icon
  and count) with 14px of side padding that rings in `color` (1px border, 3px ring) when chosen; `variant="chip"` renders pill chips, the
  status filter of a list, with an optional count. Both keep a real radio underneath, so the
  arrow keys, the form and `phx-change` work as with plain radios.

      <.radio_group field={@form[:status]} variant="chip" color="primary" options={[
        %{label: "Todos", value: "all", count: 128},
        %{label: "Rascunho", value: "draft", count: 4},
        %{label: "Confirmado", value: "confirmed", count: 12}
      ]} />

      <.radio_group field={@form[:remember]} variant="card" color="primary">
        <:radio value="yes" description="Stay signed in for 30 days" icon="huge-laptop">This device</:radio>
        <:radio value="no" description="Sign out when the browser closes">Just this time</:radio>
      </.radio_group>
  """

  use LineaUI.Component

  alias LineaUI.Components.Choice
  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @shapes %{
    "circle" => "rounded-full",
    "squircle" => "rounded-md"
  }

  # A radio is 18px at `md` with a 6px dot (a checkbox of that size stays 20px); `is-md` carries the dot.
  @md "is-md size-[18px]"

  @colors ~w(neutral primary secondary info success warning error)

  @doc """
  Renders a set of radios. Options are `{label, value}` tuples, plain values, maps with
  `:label`, `:value` and optionally `:description`, `:count`, `:icon`, `:color`, `:disabled`,
  or `:radio` slots, which may override `color`, `disabled`, `description`, `count` and `icon`
  one by one.

  `variant` picks the look: `basic` and `outline` are LineOne's radios, `card` a bordered card
  per option, `chip` a pill per option. Choosing one fires the form's `phx-change` like any
  radio; on its own (outside a form) put `phx-click` or `phx-change` in `rest`.
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any, doc: "The value of the checked radio.")
  attr(:options, :list, default: [])
  attr(:color, :string, default: "neutral", values: @colors)

  attr(:variant, :string,
    default: "basic",
    values: Choice.variants(),
    doc: "`basic`/`outline` radios, `card` cards, `chip` pill chips."
  )

  attr(:filled, :boolean, default: false)
  attr(:shape, :string, default: "circle", values: ~w(circle squircle))
  attr(:size, :string, default: "md", values: Choice.sizes())
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

  attr(:radio_class, :any, default: nil, doc: "Extra classes of every radio input.")
  attr(:class, :any, default: nil, doc: "Classes of the container that lays the radios out.")
  attr(:rest, :global, include: ~w(form required))

  slot :radio do
    attr(:value, :any, required: true)
    attr(:label, :string)
    attr(:color, :string)
    attr(:disabled, :boolean)
    attr(:description, :string)
    attr(:count, :any, doc: "A number shown in a small badge (chip and card).")
    attr(:icon, :string, doc: "A `huge-*` icon name, shown in a card or a chip.")
    attr(:class, :any)
  end

  def radio_group(assigns) do
    assigns
    |> Control.assign_control()
    |> then(&assign(&1, :id, &1.id || gen_id("radio-group")))
    |> then(&assign(&1, :items, items(&1)))
    |> render_group()
  end

  defp items(assigns) do
    checked = to_string(assigns.value)

    assigns
    |> entries()
    |> Enum.with_index()
    |> Enum.map(fn {entry, index} ->
      Map.merge(entry, %{
        id: "#{assigns.id}-#{index}",
        checked: assigns.value != nil and to_string(entry.value) == checked,
        classes:
          merge([
            Choice.input_classes("form-radio", %{assigns | color: entry.color || assigns.color}),
            assigns.size == "md" && @md,
            @shapes[assigns.shape],
            assigns.radio_class,
            entry.class
          ])
      })
    end)
  end

  defp entries(%{radio: [_ | _] = slots}) do
    Enum.map(slots, fn slot ->
      %{
        value: slot.value,
        label: Map.get(slot, :label),
        color: Map.get(slot, :color),
        disabled: Map.get(slot, :disabled),
        description: Map.get(slot, :description),
        count: Map.get(slot, :count),
        icon: Map.get(slot, :icon),
        class: Map.get(slot, :class),
        content: [slot]
      }
    end)
  end

  defp entries(%{options: options}), do: Enum.map(options, &option/1)

  defp option(%{value: value} = option) do
    %{
      value: value,
      label: option |> Map.get(:label, value) |> to_string(),
      color: Map.get(option, :color),
      disabled: Map.get(option, :disabled),
      description: Map.get(option, :description),
      count: Map.get(option, :count),
      icon: Map.get(option, :icon),
      class: Map.get(option, :class),
      content: []
    }
  end

  defp option({label, value}), do: option(%{label: label, value: value})

  defp option(value), do: option({value, value})

  defp render_group(assigns) do
    ~H"""
    <Form.field
      id={@id}
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      as="div"
      class={@wrapper_class}
    >
      <div
        id={@id}
        role="radiogroup"
        aria-labelledby={@label && "#{@id}-label"}
        class={merge([Choice.layout(@variant), @label && "mt-1.5", @class])}
      >
        <Choice.item
          :for={item <- @items}
          variant={@variant}
          color={item.color || @color}
          label={item.label}
          description={item.description}
          count={item.count}
          icon={item.icon}
          content={Choice.slot_content(item.content)}
        >
          <input
            type="radio"
            id={item.id}
            name={@name}
            value={item.value}
            checked={item.checked}
            disabled={@disabled || item.disabled}
            class={item.classes}
            aria-invalid={@errors != [] && "true"}
            {@rest}
          />
        </Choice.item>
      </div>
    </Form.field>
    """
  end
end
