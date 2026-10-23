defmodule LineaUI.Components.Checkbox do
  @moduledoc """
  LineOne's checkboxes: basic (filled when checked) or outline (a colored check on a clear
  box), on a plain or a filled box, square or circle, in every theme color.

      <.checkbox name="terms" label="I agree" />
      <.checkbox field={@form[:remember]} label="Remember me" color="primary" />
      <.checkbox name="news" color="success" variant="outline" shape="circle" filled />
      <.checkbox name="pro" label="Pro plan" description="Billed yearly" color="primary" checked />

  `checkbox_group` renders one checkbox per option for a list field:

      <.checkbox_group field={@form[:roles]} label="Roles" options={[{"Admin", "admin"}, {"Editor", "editor"}]} />
  """

  use LineaUI.Component

  alias LineaUI.Components.Choice
  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @shapes %{
    "square" => "rounded-sm",
    "circle" => "rounded-full"
  }

  @colors ~w(neutral primary secondary info success warning error)

  @doc """
  Renders a checkbox with its label. Inside a form it sends `unchecked_value` when unchecked,
  through a hidden input, so the field is always present in the params.
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any)
  attr(:checked, :boolean, doc: "Defaults to whether `value` (or the field's value) is true.")
  attr(:checked_value, :string, default: "true")
  attr(:unchecked_value, :string, default: "false")
  attr(:hidden_input, :boolean, default: true, doc: "Renders the hidden unchecked input.")
  attr(:color, :string, default: "neutral", values: @colors)
  attr(:variant, :string, default: "basic", values: ~w(basic outline))
  attr(:filled, :boolean, default: false, doc: "A tinted box while unchecked.")
  attr(:shape, :string, default: "square", values: ~w(square circle))
  attr(:size, :string, default: "md", values: Choice.sizes())
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

  def checkbox(assigns) do
    assigns
    |> Control.assign_control()
    |> assign_new(:checked, fn %{value: value} ->
      Phoenix.HTML.Form.normalize_value("checkbox", value)
    end)
    |> then(&assign(&1, :classes, classes(&1)))
    |> render_checkbox()
  end

  defp classes(assigns) do
    merge([Choice.classes("form-checkbox", assigns), @shapes[assigns.shape], assigns.class])
  end

  defp render_checkbox(assigns) do
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
      description={@description}
      content={@inner_block}
      class={@wrapper_class}
    >
      <input
        type="checkbox"
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

  @doc """
  Renders one checkbox per option, for a field that holds a list. Options are `{label, value}`
  tuples, plain values, or `:checkbox` slots (which may set their own `color`).

      <.checkbox_group name="days[]" value={["mon"]} options={[{"Monday", "mon"}, {"Tuesday", "tue"}]} />

      <.checkbox_group field={@form[:roles]} label="Roles" class="flex flex-col space-y-2">
        <:checkbox value="admin" color="primary">Admin</:checkbox>
        <:checkbox value="editor" color="success">Editor</:checkbox>
      </.checkbox_group>
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any)
  attr(:options, :list, default: [])
  attr(:color, :string, default: "neutral", values: @colors)
  attr(:variant, :string, default: "basic", values: ~w(basic outline))
  attr(:filled, :boolean, default: false)
  attr(:shape, :string, default: "square", values: ~w(square circle))
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

  attr(:class, :any, default: nil, doc: "Classes of the container that lays the options out.")
  attr(:rest, :global)

  slot :checkbox do
    attr(:value, :any, required: true)
    attr(:label, :string)
    attr(:color, :string)
    attr(:disabled, :boolean)
    attr(:description, :string)
  end

  def checkbox_group(assigns) do
    assigns
    |> assign(:multiple, true)
    |> Control.assign_control()
    |> then(&assign(&1, :id, &1.id || gen_id("checkbox-group")))
    |> then(&assign(&1, :items, items(&1)))
    |> render_group()
  end

  defp items(assigns) do
    selected = assigns.value |> List.wrap() |> Enum.map(&to_string/1)

    assigns
    |> entries()
    |> Enum.with_index()
    |> Enum.map(fn {entry, index} ->
      entry
      |> Map.put(:id, "#{assigns.id}-#{index}")
      |> Map.put(:checked, to_string(entry.value) in selected)
      |> Map.put(
        :classes,
        classes(%{
          assigns
          | color: entry.color || assigns.color,
            class: nil
        })
      )
    end)
  end

  defp entries(%{checkbox: [_ | _] = slots}) do
    Enum.map(slots, fn slot ->
      %{
        value: slot.value,
        label: Map.get(slot, :label),
        color: Map.get(slot, :color),
        disabled: Map.get(slot, :disabled),
        description: Map.get(slot, :description),
        content: [slot]
      }
    end)
  end

  defp entries(%{options: options}), do: Enum.map(options, &option/1)

  defp option({label, value}),
    do: %{
      value: value,
      label: to_string(label),
      color: nil,
      disabled: nil,
      description: nil,
      content: []
    }

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
      <input type="hidden" name={@name} value="" disabled={@disabled} />
      <div
        id={@id}
        role="group"
        aria-labelledby={@label && "#{@id}-label"}
        class={merge(["inline-space flex flex-wrap", @label && "mt-1.5", @class])}
        {@rest}
      >
        <Choice.label
          :for={item <- @items}
          label={item.label}
          description={item.description}
          content={Choice.slot_content(item.content)}
        >
          <input
            type="checkbox"
            id={item.id}
            name={@name}
            value={item.value}
            checked={item.checked}
            disabled={@disabled || item.disabled}
            class={item.classes}
          />
        </Choice.label>
      </div>
    </Form.field>
    """
  end
end
