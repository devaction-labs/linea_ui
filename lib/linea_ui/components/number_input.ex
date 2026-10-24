defmodule LineaUI.Components.NumberInput do
  @moduledoc """
  A numeric field for money and quantities that shows the number the way the person's locale
  writes it (`1.234,56` in pt-BR, `1,234.56` in en) and submits the plain machine value
  (`1234.56`).

      <.number_input field={@form[:price]} label="Price" prefix="R$" decimals={2} min={0} />
      <.number_input field={@form[:quantity]} label="Quantity" steppers min={1} step={1} suffix="un" />
      <.number_input name="discount" value={Decimal.new("12.5")} suffix="%" max_decimals={2} max={100} />
      <.number_input field={@form[:amount]} locale="en" align="right" />

  The visible input has no `name`: a hidden input named like the field carries the machine
  value, and a bubbling `input` event fires from it whenever that value changes, so a
  surrounding `phx-change` runs. `phx-debounce`/`phx-throttle` go to the hidden input.

  `value` may be an integer, a float, a numeric string or a `Decimal`. The server formats it
  for the first paint; a value the server sends later wins over the one in the browser, and
  re-rendering the same value does nothing.

  Typing keeps what the person writes (digits, the decimal separator, the grouping separator
  and a leading `-` when negatives are allowed); leaving the field clamps it to `min`/`max`,
  rounds it to `decimals`/`max_decimals` and writes it grouped. Arrow up and down (and the
  steppers) move by `step`, Page up and down by ten steps.

  The behavior lives in the `LineaUI.NumberInput` hook, so the field needs a stable `id` (it
  gets one from `field` or `name`).
  """

  use LineaUI.Component

  alias LineaUI.Components.Form
  alias LineaUI.Components.Input
  alias LineaUI.Components.InputGroup
  alias LineaUI.Components.NumberInput.Format
  alias LineaUI.Components.Pickers

  @group "flex w-full -space-x-px [&>*]:rounded-none [&>*_.form-input]:rounded-none [&>*:hover]:z-10 [&>*:focus]:z-10 [&>*:focus-within]:z-10"

  @shapes %{
    "rounded" =>
      "[&>:first-child]:rounded-l-lg [&>:first-child_.form-input]:rounded-l-lg [&>:last-child]:rounded-r-lg [&>:last-child_.form-input]:rounded-r-lg",
    "pill" =>
      "[&>:first-child]:rounded-l-full [&>:first-child_.form-input]:rounded-l-full [&>:last-child]:rounded-r-full [&>:last-child_.form-input]:rounded-r-full"
  }

  @stepper "flex shrink-0 items-center justify-center border border-slate-300 px-3 text-slate-600 outline-hidden transition-colors hover:bg-slate-100 hover:text-slate-800 focus-visible:bg-slate-100 active:bg-slate-150 disabled:pointer-events-none disabled:opacity-35 dark:border-navy-450 dark:text-navy-100 dark:hover:bg-navy-600 dark:hover:text-navy-50 dark:focus-visible:bg-navy-600 dark:active:bg-navy-500"

  @stepper_sizes %{"sm" => "h-8", "md" => "h-[2.375rem]", "lg" => "h-12"}

  @addon_sizes %{"sm" => "h-8 text-xs-plus", "md" => nil, "lg" => "h-12 text-base"}

  @doc """
  Renders the number input.

  Events: none of its own. The hidden input dispatches a bubbling `input` event when the
  machine value changes, so the form's `phx-change` receives `%{"name" => "1234.56"}`
  (`""` when the field is emptied; the typed text when it is not a number, so the server can
  reject it).
  """
  attr :id, :string, doc: "The visible input's id. Defaults to the field id, then `name`."
  attr :name, :string, doc: "Defaults to the field name."

  attr :value, :any,
    doc: "A number, a numeric string or a `Decimal`. Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :label, :string, default: nil, doc: "The caption."
  attr :label_class, :any, default: nil, doc: "Classes of the caption text."
  attr :help, :string, default: nil, doc: "The small line under the control."
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false

  attr :locale, :string,
    default: "pt-BR",
    doc: "Picks the separators: `pt-BR` writes `1.234,56`, `en` writes `1,234.56`."

  attr :decimal_separator, :string, default: nil, doc: "Overrides the locale's decimal separator."

  attr :thousands_separator, :string,
    default: nil,
    doc: "Overrides the locale's grouping separator; `\"\"` turns grouping off."

  attr :decimals, :integer,
    default: nil,
    doc: "Always this many decimals (`2` for money: `10` shows `10,00`)."

  attr :max_decimals, :integer,
    default: nil,
    doc: "At most this many decimals; fewer are shown as typed. Ignored when `decimals` is set."

  attr :min, :any,
    default: nil,
    doc: "The lowest value; a negative sign can be typed only when it is below zero or absent."

  attr :max, :any, default: nil, doc: "The highest value."
  attr :step, :any, default: 1, doc: "What the arrow keys and the steppers add or take away."
  attr :steppers, :boolean, default: false, doc: "`−` and `+` buttons on either side."
  attr :decrement_label, :string, default: "Decrease", doc: "The accessible name of `−`."
  attr :increment_label, :string, default: "Increase", doc: "The accessible name of `+`."
  attr :prefix, :string, default: nil, doc: "A box before the input, like `R$`."
  attr :suffix, :string, default: nil, doc: "A box after the input, like `%` or `un`."

  attr :variant, :string,
    default: "outlined",
    values: ~w(outlined filled),
    doc: "The input's look, as in `input`."

  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :align, :string, default: "left", values: ~w(left right center)

  attr :wrapper_class, :any, default: nil, doc: "Classes of the block around the field."
  attr :class, :any, default: nil, doc: "Classes of the visible input."

  attr :rest, :global,
    include: ~w(autocomplete autofocus form placeholder readonly required),
    doc:
      "Goes to the visible input, except `phx-debounce`/`phx-throttle`, which go to the hidden one."

  def number_input(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("number") end))
    |> assign_new(:value, fn -> nil end)
    |> assign_format()
    |> render_number()
  end

  defp assign_format(assigns) do
    {decimal, group} = Format.separators(assigns.locale)
    decimal = assigns.decimal_separator || decimal
    group = thousands(assigns.thousands_separator, group)

    opts = %{
      decimal: decimal,
      group: group,
      decimals: assigns.decimals,
      max_decimals: assigns.max_decimals
    }

    machine = Format.machine(assigns.value)
    min = Format.machine(assigns.min)
    max = Format.machine(assigns.max)

    assign(assigns,
      decimal: decimal,
      group: group,
      machine: Format.submitted(machine, opts),
      display: Format.display(machine, opts),
      min: min,
      max: max,
      step: Format.machine(assigns.step) || "1",
      negative: negative?(min),
      inputmode: inputmode(assigns.decimals, assigns.max_decimals),
      state: error_state(assigns.errors),
      forwarded: Pickers.forwarded(assigns.rest),
      input_rest: Map.drop(assigns.rest, [:"phx-debounce", :"phx-throttle"])
    )
  end

  defp thousands(nil, group), do: group
  defp thousands(given, _group), do: given

  defp negative?(nil), do: true
  defp negative?("-" <> _rest), do: true
  defp negative?(_min), do: false

  defp inputmode(0, _max), do: "numeric"
  defp inputmode(nil, 0), do: "numeric"
  defp inputmode(_decimals, _max), do: "decimal"

  defp error_state([]), do: nil
  defp error_state(_errors), do: "error"

  defp render_number(%{label: nil, help: nil, errors: []} = assigns) do
    ~H"""
    <div class={@wrapper_class}><.control {assigns} /></div>
    """
  end

  defp render_number(assigns) do
    ~H"""
    <Form.field
      id={@id}
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      state={@state}
      class={@wrapper_class}
    >
      <.control {assigns} />
    </Form.field>
    """
  end

  defp control(assigns) do
    assigns =
      assign(assigns,
        group_class: merge([@group, @shapes[assigns.shape]]),
        stepper_class: merge([@stepper, @stepper_sizes[assigns.size]]),
        field_height: @stepper_sizes[assigns.size],
        addon_class: @addon_sizes[assigns.size]
      )

    ~H"""
    <div
      id={@id <> "-number"}
      class="w-full"
      phx-hook="LineaUI.NumberInput"
      data-value={@machine}
      data-decimal={@decimal}
      data-group={@group}
      data-decimals={@decimals}
      data-max-decimals={@max_decimals}
      data-min={@min}
      data-max={@max}
      data-step={@step}
      data-negative={bool(@negative)}
    >
      <div class={@group_class}>
        <button
          :if={@steppers}
          type="button"
          class={@stepper_class}
          tabindex="-1"
          aria-label={@decrement_label}
          aria-controls={@id}
          disabled={@disabled}
          data-step-by="down"
        >
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M20 12H4" />
          </svg>
        </button>
        <InputGroup.input_group_addon :if={@prefix} variant="filled" class={@addon_class}>
          {@prefix}
        </InputGroup.input_group_addon>
        <div class="relative min-w-0 flex-1 [&_.form-input]:w-full">
          <Input.input
            type="text"
            id={@id}
            value={@display}
            variant={@variant}
            size={@size}
            shape={@shape}
            align={align(@align)}
            state={@state}
            disabled={@disabled}
            class={
              merge([
                @align == "center" && "text-center",
                @steppers && @field_height,
                @steppers && "font-mono text-sm-plus font-medium text-slate-800 dark:text-navy-50",
                @steppers && @suffix && "pe-9",
                @class
              ])
            }
            role="spinbutton"
            inputmode={@inputmode}
            autocomplete="off"
            aria-valuenow={@machine}
            aria-valuemin={@min}
            aria-valuemax={@max}
            data-display
            {@input_rest}
          />
          <span
            :if={@steppers && @suffix}
            class="pointer-events-none absolute inset-y-0 end-3 flex items-center font-inter text-xs-plus text-slate-400 dark:text-navy-300"
          >
            {@suffix}
          </span>
        </div>
        <InputGroup.input_group_addon
          :if={@suffix && !@steppers}
          variant="filled"
          class={@addon_class}
        >
          {@suffix}
        </InputGroup.input_group_addon>
        <button
          :if={@steppers}
          type="button"
          class={@stepper_class}
          tabindex="-1"
          aria-label={@increment_label}
          aria-controls={@id}
          disabled={@disabled}
          data-step-by="up"
        >
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </div>
      <input
        type="hidden"
        id={@id <> "-value"}
        name={@name}
        value={@machine}
        disabled={@disabled}
        phx-update="ignore"
        data-value-input
        {@forwarded}
      />
    </div>
    """
  end

  defp align("right"), do: "right"
  defp align(_align), do: "left"
end
