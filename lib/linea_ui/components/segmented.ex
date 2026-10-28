defmodule LineaUI.Components.Segmented do
  @moduledoc """
  A segmented control: a row of toggle buttons where exactly one is chosen, for filters, periods, views and
  two-way choices that do not deserve a select.

      <.segmented
        id="status"
        label="Order status"
        value={@status}
        on_change="set-status"
        options={[
          %{label: "All", value: "all", count: 128},
          %{label: "Draft", value: "draft", count: 9},
          %{label: "Approved", value: "approved", count: 31}
        ]}
      />

      <.segmented field={@form[:regime]} options={["Simples Nacional", "Regime normal"]} />

  Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, and optionally `:count` (a small
  number after the label) and `:disabled`.

  It is a `role="group"` of buttons with `aria-pressed`. The choice is made in the browser, without a round trip;
  a new `value` from the server wins, and a patch that does not change it leaves the person's choice alone. Arrow
  keys, Home and End move the focus between the segments (one segment is in the Tab order).

  Inside a form the control submits through a hidden input named like the field, which fires an `input` event
  when the choice changes, so `phx-change` runs (and not again when the server only echoes the same value):

      <.form for={@form} phx-change="validate">
        <.segmented field={@form[:view]} options={["List", "Kanban"]} />
      </.form>
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form
  alias LineaUI.Components.Overlay
  alias LineaUI.Components.Select.Options

  @sizes %{
    "sm" => "h-6 px-2.5 text-xs",
    "md" => "h-7.5 px-3 text-xs-plus",
    "lg" => "h-9.5 px-4.5 text-sm"
  }

  @doc """
  Renders the segmented control.

  Events: `on_change` pushes `%{"id" => id, "value" => value}` (to `target` when given) after the person chooses
  another segment. A form's `phx-change` hears the hidden input of a control that has a `name` (or a `field`).
  """
  attr :id, :string, doc: "Defaults to the field id, then `name`, then a generated one."

  attr :name, :string,
    doc: "Defaults to the field name; with it the control submits through a hidden input."

  attr :value, :any, doc: "The chosen value. Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :options, :list, required: true, doc: "The segments, see the module doc."

  attr :label, :string,
    default: nil,
    doc: "The caption above the control; also its accessible name."

  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :size, :string, default: "md", values: ~w(sm md lg)

  attr :full, :boolean,
    default: false,
    doc: "Stretches the control over the width, the segments sharing it."

  attr :disabled, :boolean, default: false

  attr :on_change, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run when another segment is chosen."

  attr :target, :any, default: nil, doc: "The `phx-target` of the `on_change` event."

  attr :wrapper_class, :any,
    default: nil,
    doc: "Classes of the outer block (caption, control and messages)."

  attr :class, :any, default: nil, doc: "Merged into the group of buttons."
  attr :rest, :global, include: ~w(form)

  def segmented(assigns) do
    assigns
    |> Control.assign_control()
    |> then(&assign(&1, :id, &1.id || &1.name || gen_id("segmented")))
    |> then(&assign(&1, :value, value(&1.value)))
    |> then(&assign(&1, :segments, segments(&1)))
    |> then(&assign(&1, :on_change_js, Overlay.callback(&1.on_change, &1.id, &1.target)))
    |> render_segmented()
  end

  defp render_segmented(assigns) do
    ~H"""
    <Form.field id={@id} label={@label} help={@help} errors={@errors} as="div" class={@wrapper_class}>
      <div
        id={@id}
        role="group"
        aria-labelledby={@label && "#{@id}-label"}
        phx-hook="LineaUI.Segmented"
        phx-target={@target}
        class={merge([track(@full), @label && "mt-1.5", @class])}
        data-value={@value}
        data-on-change={@on_change_js}
        {@rest}
      >
        <input
          :if={@name}
          type="hidden"
          id={@id <> "-value"}
          name={@name}
          value={@value}
          disabled={@disabled}
          phx-update="ignore"
          data-value-input
        />
        <button
          :for={segment <- @segments}
          type="button"
          id={segment.id}
          aria-pressed={bool(segment.value == @value)}
          disabled={@disabled || segment.disabled}
          class={
            merge([
              "group/segment inline-flex items-center justify-center whitespace-nowrap rounded-md font-medium text-slate-500 outline-hidden transition-colors duration-200 hover:text-slate-700 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary/50 disabled:pointer-events-none disabled:opacity-60 aria-pressed:bg-white aria-pressed:text-slate-800 aria-pressed:shadow-soft dark:text-navy-200 dark:hover:text-navy-50 dark:focus-visible:outline-accent/50 dark:aria-pressed:bg-navy-500 dark:aria-pressed:text-navy-50 dark:aria-pressed:shadow-soft-dark",
              size_class(@size),
              @full && "flex-1"
            ])
          }
          phx-mounted={JS.ignore_attributes(["aria-pressed", "tabindex"])}
          data-value={segment.value}
        >
          {segment.label}
          <span
            :if={segment.count != nil}
            class="ml-1.5 font-inter text-tiny-plus font-medium text-slate-400 group-aria-pressed/segment:text-primary dark:text-navy-300 dark:group-aria-pressed/segment:text-accent-light"
          >
            {segment.count}
          </span>
        </button>
      </div>
    </Form.field>
    """
  end

  defp segments(assigns) do
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
        count: count(option.data)
      }
    end)
  end

  defp count(%{count: count}), do: count
  defp count(_data), do: nil

  defp value(nil), do: ""
  defp value(value), do: to_string(value)

  # The track the segments sit on, shared with `radio_group variant="segmented"`.
  @doc false
  @spec track(boolean()) :: String.t()
  def track(full \\ false) do
    merge([
      "gap-0.5 rounded-lg bg-slate-150 p-0.75 dark:bg-navy-800",
      full && "flex w-full",
      !full && "inline-flex"
    ])
  end

  @doc false
  @spec size_class(String.t()) :: String.t()
  def size_class(size), do: Map.fetch!(@sizes, size)
end
