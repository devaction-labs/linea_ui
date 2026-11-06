defmodule LineaUI.Components.PillSelect do
  @moduledoc """
  A quick filter of pills: a row of 26px tags where the chosen ones take the accent tint. One choice by default,
  several with `multiple`.

      <.pill_select field={@form[:canal]} options={["Todos", "Balcão", "Online"]} />

      <.pill_select
        field={@form[:categorias]}
        multiple
        options={["Tintas", "Básico", "Ferramentas", "Acessórios"]}
      />

      <.pill_select
        name="canal"
        value="todos"
        options={[%{label: "Todos", value: "todos", count: 128}, %{label: "Balcão", value: "balcao", count: 64}]}
      />

  Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, and optionally `:count` (a faint
  number after the label) and `:disabled`.

  Each pill is a native radio (or checkbox with `multiple`) inside its label, so the choice is made in the browser,
  the keyboard works as in any radio group or set of checkboxes, and a surrounding form's `phx-change` gets the
  value under `name` (a list under `name[]` with `multiple`; a hidden empty entry keeps an empty choice
  submittable, and it is dropped from `value`).
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form
  alias LineaUI.Components.Select.Options

  @doc """
  Renders the pills.

  Events: inside a form, choosing fires the inputs' `change`, so `phx-change` runs. Without a form, `on_change`
  is pushed on each click with `%{"id" => id, "value" => value}` (the clicked option's value) to `target` when
  given.
  """
  attr :id, :string, doc: "Defaults to the field id, then `name`, then a generated one."
  attr :name, :string, doc: "Defaults to the field name. `multiple` appends `[]`."

  attr :value, :any,
    doc: "The chosen value, or a list of them with `multiple`. Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :options, :list, required: true, doc: "The pills, see the module doc."
  attr :multiple, :boolean, default: false, doc: "Several pills can be chosen (checkboxes)."
  attr :label, :string, default: nil, doc: "The caption above the pills; also the group's name."
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false

  attr :on_change, :string,
    default: nil,
    doc: "An event pushed when a pill is clicked, for use outside a form."

  attr :target, :any, default: nil, doc: "The `phx-target` of `on_change`."
  attr :wrapper_class, :any, default: nil, doc: "Classes of the outer block."
  attr :class, :any, default: nil, doc: "Merged into the row of pills."
  attr :rest, :global, include: ~w(form)

  def pill_select(assigns) do
    assigns
    |> Control.assign_control()
    |> then(&assign(&1, :id, &1.id || &1.name || stable_id("pills", &1)))
    |> then(&assign(&1, :chosen, chosen(&1.value)))
    |> then(&assign(&1, :input_name, input_name(&1.name, &1.multiple)))
    |> then(&assign(&1, :pills, pills(&1)))
    |> render_pills()
  end

  defp render_pills(assigns) do
    ~H"""
    <Form.field id={@id} label={@label} help={@help} errors={@errors} as="div" class={@wrapper_class}>
      <div
        id={@id}
        role={if @multiple, do: "group", else: "radiogroup"}
        aria-labelledby={@label && "#{@id}-label"}
        class={merge(["sg-pills", @label && "mt-1.5", @class])}
        {@rest}
      >
        <input
          :if={@multiple && @name}
          type="hidden"
          name={@input_name}
          value=""
          disabled={@disabled}
        />
        <label
          :for={pill <- @pills}
          class="sg-tag"
          data-value={pill.value}
        >
          <input
            type={if @multiple, do: "checkbox", else: "radio"}
            id={pill.id}
            name={@input_name || @id}
            value={pill.value}
            checked={pill.checked}
            disabled={@disabled || pill.disabled}
            phx-click={
              @on_change && JS.push(@on_change, value: %{id: @id, value: pill.value}, target: @target)
            }
          />
          {pill.label}<span :if={pill.count != nil} class="sg-pills-count">{pill.count}</span>
        </label>
      </div>
    </Form.field>
    """
  end

  defp pills(assigns) do
    assigns.options
    |> Options.normalize()
    |> Options.flat()
    |> Enum.with_index()
    |> Enum.map(fn {option, index} ->
      %{
        id: "#{assigns.id}-#{index}",
        label: option.label,
        value: option.value,
        disabled: option.disabled,
        checked: option.value in assigns.chosen,
        count: count(option.data)
      }
    end)
  end

  defp count(%{count: count}), do: count
  defp count(_data), do: nil

  defp chosen(nil), do: []

  defp chosen(values) when is_list(values),
    do: for(v <- values, v not in [nil, ""], do: to_string(v))

  defp chosen(value), do: [to_string(value)]

  defp input_name(nil, _multiple), do: nil
  defp input_name(name, true), do: if(String.ends_with?(name, "[]"), do: name, else: name <> "[]")
  defp input_name(name, false), do: name
end
