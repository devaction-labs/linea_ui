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
  """

  use LineaUI.Component

  alias LineaUI.Components.Checkbox
  alias LineaUI.Components.Choice
  alias LineaUI.Components.Form

  @shapes %{
    "circle" => "rounded-full",
    "squircle" => "rounded-md"
  }

  @colors ~w(neutral primary secondary info success warning error)

  @doc """
  Renders a set of radios. Options are `{label, value}` tuples, plain values, or `:radio`
  slots, which may override `color`, `disabled` and `description` one by one.
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string)
  attr(:name, :string)
  attr(:value, :any, doc: "The value of the checked radio.")
  attr(:options, :list, default: [])
  attr(:color, :string, default: "neutral", values: @colors)
  attr(:variant, :string, default: "basic", values: ~w(basic outline))
  attr(:filled, :boolean, default: false)
  attr(:shape, :string, default: "circle", values: ~w(circle squircle))
  attr(:size, :string, default: "md", values: Choice.sizes())
  attr(:label, :string, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:help, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:disabled, :boolean, default: false)
  attr(:wrapper_class, :any, default: nil)
  attr(:radio_class, :any, default: nil, doc: "Extra classes of every radio input.")
  attr(:class, :any, default: nil, doc: "Classes of the container that lays the radios out.")
  attr(:rest, :global, include: ~w(form required))

  slot :radio do
    attr(:value, :any, required: true)
    attr(:label, :string)
    attr(:color, :string)
    attr(:disabled, :boolean)
    attr(:description, :string)
    attr(:class, :any)
  end

  def radio_group(assigns) do
    assigns
    |> Form.assign_control()
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
            Choice.classes("form-radio", %{assigns | color: entry.color || assigns.color}),
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
        class: Map.get(slot, :class),
        content: [slot]
      }
    end)
  end

  defp entries(%{options: options}), do: Enum.map(options, &option/1)

  defp option({label, value}) do
    %{
      value: value,
      label: to_string(label),
      color: nil,
      disabled: nil,
      description: nil,
      class: nil,
      content: []
    }
  end

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
        class={merge(["inline-space flex flex-wrap", @label && "mt-1.5", @class])}
      >
        <Checkbox.choice_label
          :for={item <- @items}
          label={item.label}
          description={item.description}
          content={Checkbox.slot_content(item.content)}
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
        </Checkbox.choice_label>
      </div>
    </Form.field>
    """
  end
end
