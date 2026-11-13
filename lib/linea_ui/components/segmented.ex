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

  Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, and optionally `:icon` (a `huge-*`
  icon before the label), `:count` (a mono number in a small box after the label) and `:disabled`.

      <.segmented id="view" value="board" options={[
        %{label: "Quadro", value: "board", icon: "huge-kanban"},
        %{label: "Lista", value: "list", icon: "huge-list-view"}
      ]} />

  The chosen segment is white on a gray track, both with rounded corners; `shape="pill"` gives round ends
  (or `data-shape="pill"` on the `<html>`, for the whole app).

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

  import LineaUI.Components.Icon, only: [icon: 1]

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form
  alias LineaUI.Components.Overlay
  alias LineaUI.Components.Select.Options

  @sizes %{
    "sm" => "h-6 px-2.5 text-xs",
    "md" => "h-[30px] px-3.5 text-[13.5px]",
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

  attr :shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc:
      "`rounded` (a track with 11px corners and the chosen segment at 8px, the default) or `pill` (round ends, opt-in)."

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
    |> assign_id()
    |> then(&assign_derived(&1, :value, [:value], fn -> value(&1.value) end))
    |> then(&assign_derived(&1, :segments, [:options, :id], fn -> segments(&1) end))
    |> then(
      &assign_derived(&1, :on_change_js, [:on_change, :id, :target], fn ->
        Overlay.callback(&1.on_change, &1.id, &1.target)
      end)
    )
    |> render_segmented()
  end

  # Without id and name, the id is derived from the label (stable across renders).
  defp assign_id(%{id: nil, name: nil} = assigns),
    do: assign(assigns, :id, stable_id("segmented", assigns))

  defp assign_id(assigns),
    do: assign_derived(assigns, :id, [:id, :name], fn -> assigns.id || assigns.name end)

  defp render_segmented(assigns) do
    ~H"""
    <Form.field id={@id} label={@label} help={@help} errors={@errors} as="div" class={@wrapper_class}>
      <div
        id={@id}
        role="group"
        aria-labelledby={@label && "#{@id}-label"}
        phx-hook="LineaUI.Segmented"
        phx-target={@target}
        class={
          merge(["sg-seg", @size == "sm" && "sm", @full && "flex w-full", @label && "mt-1.5", @class])
        }
        data-value={@value}
        data-shape={@shape == "pill" && "pill"}
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
          :for={{segment, pressed} <- pressed(@segments, @value)}
          type="button"
          id={segment.id}
          aria-pressed={bool(pressed)}
          disabled={@disabled || segment.disabled}
          class={merge([@full && "flex-1 justify-center"])}
          phx-mounted='[["ignore_attrs",{"attrs":["aria-pressed","tabindex"]}]]'
          data-value={segment.value}
        >
          <.icon :if={segment.icon} name={segment.icon} class="size-4 shrink-0" />
          {segment.label}
          <span :if={segment.count != nil} class="font-mono font-normal text-(--faint)">
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
        count: count(option.data),
        icon: icon_name(option.data)
      }
    end)
  end

  # Each segment with whether it is the chosen one, as comprehension variables: a new value
  # sends the two segments that changed.
  defp pressed(segments, value), do: Enum.map(segments, &{&1, &1.value == value})

  defp count(%{count: count}), do: count
  defp count(_data), do: nil

  defp icon_name(%{icon: icon}) when is_binary(icon), do: icon
  defp icon_name(_data), do: nil

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
