defmodule LineaUI.Components.OtpInput do
  @moduledoc """
  A one-time code made of single-character boxes, for the second step of a sign-in, a phone or
  email confirmation, a recovery PIN.

      <.otp_input field={@form[:code]} label="6-digit code" />
      <.otp_input name="pin" length={4} mask autofocus />
      <.otp_input field={@form[:code]} separator={3} on_complete="verify" />
      <.otp_input name="invite" mode="alphanumeric" length={8} size="lg" />

  Typing fills a box and moves to the next, Backspace on an empty box goes back and empties the
  previous one, the arrows, Home and End move between boxes, and a paste or an autofill spreads its
  characters over the boxes (a text as long as the whole code always starts at the first box).
  Characters the `mode` does not allow are dropped.

  The boxes have no `name`: a hidden input named like the field carries the joined code, and a
  bubbling `input` event fires from it whenever the code changes, so a surrounding `phx-change`
  receives `%{"name" => "482913"}` (a partial code while it is typed). `phx-debounce` and
  `phx-throttle` go in `rest` of a form, not here. `value` may be an integer or a string; the
  server renders it into the boxes, a value the server sends later wins over the one in the
  browser (render `value=""` to clear a rejected code), and re-rendering what the browser sent
  does nothing.

  A filled box keeps the border of the others (it only carries `data-filled`); with errors it keeps the error border and
  with `state="success"` the success one. The error line has `role="alert"`; a `help` line under
  `state="success"` starts with a check-circle icon.

      <.otp_input field={@form[:code]} state="success" help="Code confirmed" />

  ## Accessibility

  The boxes are a `role="group"` named by the `label` (or by `aria_label`); each box is named
  `digit_label` plus its number (`Digit 1`), has `autocomplete="one-time-code"` so the keyboard
  offers the code from an SMS, and a numeric keypad on touch devices in `numeric` mode. The
  separator is hidden from assistive technology.

  The behavior lives in the `LineaUI.Otp` hook, so the component needs a stable `id` (it gets one
  from `field` or `name`).
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form
  alias LineaUI.Components.Input
  alias LineaUI.Components.Overlay

  @sizes %{
    "sm" => "size-8.5 rounded-md text-sm",
    "md" => "size-10 rounded-md text-base",
    "lg" => "h-[54px] w-[46px] rounded-xl font-mono text-[22px]"
  }

  @box "shrink-0 border-0 bg-white px-0 text-center font-semibold text-slate-950 shadow-[inset_0_0_0_1px_var(--color-slate-300)] focus:shadow-[inset_0_0_0_1.5px_var(--color-primary),0_0_0_4px_color-mix(in_oklab,var(--color-primary)_14%,transparent)] focus:ring-0 dark:bg-navy-750 dark:text-navy-50 dark:shadow-[inset_0_0_0_1px_var(--color-navy-450)] dark:focus:shadow-[inset_0_0_0_1.5px_var(--color-accent),0_0_0_4px_color-mix(in_oklab,var(--color-accent)_16%,transparent)]"

  @doc """
  Renders the boxes, with their caption, help and errors when given.

  Events: no event of its own besides `on_complete`. The hidden input dispatches a bubbling
  `input` event when the code changes. `on_complete` is an event name or a `%JS{}`, sent to
  `target` when there is one, each time the code changes while every box is filled, with
  `%{"id" => id, "name" => name, "value" => code}`.
  """
  attr :id, :string, doc: "The id of the group. Defaults to the field id, then `name`."
  attr :name, :string, doc: "Defaults to the field name."

  attr :value, :any,
    doc: "The code, a string or an integer. Defaults to the field value. Cut to `length`."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :label, :string, default: nil, doc: "The caption; it also names the group."
  attr :label_class, :any, default: nil, doc: "Classes of the caption text."
  attr :help, :string, default: nil, doc: "The small line under the boxes."
  attr :errors, :list, default: []

  attr :state, :string,
    default: nil,
    values: [nil, "success", "error"],
    doc: "`success` paints the boxes green and the help line gets a check-circle icon."

  attr :length, :integer, default: 6, doc: "How many boxes (a code of this many characters)."

  attr :mode, :string,
    default: "numeric",
    values: ~w(numeric alphanumeric),
    doc:
      "`numeric` takes digits only and opens the numeric keypad; `alphanumeric` takes letters and digits."

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "`md` is 54px tall, as in the Signetum canvas."

  attr :mask, :boolean,
    default: false,
    doc: "Shows dots instead of the characters, like a password."

  attr :disabled, :boolean, default: false
  attr :autofocus, :boolean, default: false, doc: "Focuses the first empty box when it mounts."

  attr :separator, :any,
    default: nil,
    doc:
      "A dash after this many boxes (`3` splits six boxes into 3 and 3), or a list of positions."

  attr :on_complete, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_complete`."

  attr :aria_label, :string,
    default: "One-time code",
    doc: "Names the group when there is no `label`."

  attr :digit_label, :string,
    default: "Digit",
    doc: "The accessible name of each box, followed by its number."

  attr :wrapper_class, :any, default: nil, doc: "Classes of the block around the field."
  attr :class, :any, default: nil, doc: "Classes of every box."
  attr :rest, :global, doc: "Goes to the element that holds the boxes."

  def otp_input(assigns) do
    assigns
    |> assign_field()
    |> put_default(:name, nil)
    |> assign_otp_id()
    |> put_default(:value, nil)
    |> assign_code()
    |> render_otp()
  end

  # The id defaults to the name; without one it is derived from the label (stable across renders).
  defp assign_otp_id(assigns) when is_map_key(assigns, :id), do: assigns
  defp assign_otp_id(%{name: nil} = assigns), do: assign(assigns, :id, stable_id("otp", assigns))
  defp assign_otp_id(assigns), do: assign_derived(assigns, :id, [:name], fn -> assigns.name end)

  defp assign_code(assigns) do
    cells = cells(assigns.value, assigns.length, assigns.mode)
    separators = separators(assigns.separator, assigns.length)

    deps = [:value, :length, :mode, :separator]

    assigns
    |> assign_derived(:code, deps, fn -> Enum.join(cells) end)
    |> assign_derived(:boxes, deps, fn ->
      cells
      |> Enum.with_index(1)
      |> Enum.map(fn {cell, number} ->
        %{number: number, cell: cell, separator: number in separators}
      end)
    end)
    |> assign_derived(:success, [:state], fn -> success(assigns.state) end)
    |> assign_derived(:state, [:state, :errors], fn ->
      Control.state(assigns.state, assigns.errors)
    end)
    |> assign_derived(:callback, [:on_complete, :id, :target], fn ->
      Overlay.callback(assigns.on_complete, assigns.id, assigns.target)
    end)
  end

  defp cells(value, length, mode) do
    chars =
      value
      |> to_string()
      |> String.graphemes()
      |> Enum.filter(&allowed?(mode, &1))
      |> Enum.take(length)

    chars ++ List.duplicate("", length - length(chars))
  end

  defp allowed?("numeric", char), do: String.match?(char, ~r/^[0-9]$/)
  defp allowed?("alphanumeric", char), do: String.match?(char, ~r/^[A-Za-z0-9]$/)

  defp separators(nil, _length), do: []
  defp separators(position, length) when is_integer(position), do: separators([position], length)

  defp separators(positions, length) when is_list(positions),
    do: Enum.filter(positions, &(&1 > 0 and &1 < length))

  defp render_otp(%{label: nil, help: nil, errors: []} = assigns) do
    ~H"""
    <div class={@wrapper_class}>
      <.control
        id={@id}
        name={@name}
        size={@size}
        state={@state}
        success={@success}
        class={@class}
        label={@label}
        aria_label={@aria_label}
        length={@length}
        mode={@mode}
        code={@code}
        autofocus={@autofocus}
        callback={@callback}
        boxes={@boxes}
        mask={@mask}
        disabled={@disabled}
        digit_label={@digit_label}
        rest={@rest}
      />
    </div>
    """
  end

  defp render_otp(assigns) do
    ~H"""
    <Form.field
      id={@id}
      as="div"
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      state={@state}
      class={@wrapper_class}
    >
      <.control
        id={@id}
        name={@name}
        size={@size}
        state={@state}
        success={@success}
        class={@class}
        label={@label}
        aria_label={@aria_label}
        length={@length}
        mode={@mode}
        code={@code}
        autofocus={@autofocus}
        callback={@callback}
        boxes={@boxes}
        mask={@mask}
        disabled={@disabled}
        digit_label={@digit_label}
        rest={@rest}
      />
    </Form.field>
    """
  end

  defp control(assigns) do
    assigns =
      assigns
      |> assign_derived(:box_class, [:size, :success, :class], fn ->
        box_class(assigns)
      end)
      |> assign_derived(:labelledby, [:label, :id], fn ->
        assigns.label && assigns.id <> "-label"
      end)
      |> assign_derived(:group_class, [:label], fn ->
        merge(["flex w-full items-center gap-2", assigns.label && "mt-1.5"])
      end)
      |> assign_derived(:group_label, [:label, :aria_label], fn ->
        assigns.label || assigns.aria_label
      end)

    ~H"""
    <div
      id={@id}
      role="group"
      phx-hook="LineaUI.Otp"
      aria-labelledby={@labelledby}
      aria-label={!@labelledby && @group_label}
      data-length={@length}
      data-mode={@mode}
      data-value={@code}
      data-autofocus={@autofocus}
      data-on-complete={@callback}
      class={@group_class}
      {@rest}
    >
      <div :for={box <- @boxes} class="contents">
        <input
          type={mask_type(@mask)}
          id={"#{@id}-#{box.number}"}
          value={box.cell}
          aria-invalid={@state == "error" && "true"}
          disabled={@disabled}
          class={@box_class}
          inputmode={inputmode(@mode)}
          pattern={pattern(@mode)}
          autocomplete="one-time-code"
          autocapitalize="off"
          spellcheck="false"
          aria-label={"#{@digit_label} #{box.number}"}
          data-otp-box
          data-filled={box.cell != ""}
        />
        <span
          :if={box.separator}
          aria-hidden="true"
          class="shrink-0 select-none text-lg text-slate-400 dark:text-navy-300"
        >
          –
        </span>
      </div>
      <input
        type="hidden"
        id={@id <> "-value"}
        name={@name}
        value={@code}
        disabled={@disabled}
        phx-update="ignore"
        data-otp-value
      />
    </div>
    """
  end

  # The boxes draw their border as a shadow, so the state ring has to come after it to win. The error
  # one is part of every box (`aria-invalid:`), so it does not change when errors come and go.
  @error_box "linea-invalid-box"

  defp filled("success"),
    do:
      "shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] focus:shadow-[inset_0_0_0_1.5px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] dark:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)] dark:focus:shadow-[inset_0_0_0_1.5px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)]"

  defp filled(_state), do: nil

  defp success("success"), do: "success"
  defp success(_state), do: nil

  # What `input/1` would give a box of its defaults, with the box's own classes on top.
  defp box_class(assigns) do
    Input.classes(%{
      variant: "outlined",
      error_paint: false,
      size: "md",
      shape: "rounded",
      align: "left",
      prefix: [],
      suffix: [],
      state: assigns.success,
      class:
        merge([
          @box,
          @sizes[assigns.size],
          filled(assigns.success),
          @error_box,
          assigns.class
        ])
    })
  end

  defp mask_type(true), do: "password"
  defp mask_type(false), do: "text"

  defp inputmode("numeric"), do: "numeric"
  defp inputmode("alphanumeric"), do: "text"

  defp pattern("numeric"), do: "[0-9]*"
  defp pattern("alphanumeric"), do: "[A-Za-z0-9]*"
end
