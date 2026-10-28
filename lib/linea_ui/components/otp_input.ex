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

  A filled box has a primary border (`data-filled`); with errors it keeps the error border and
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
    "sm" => "h-10 rounded-lg text-base",
    "md" => "h-[54px] rounded-xl text-[22px]",
    "lg" => "h-16 rounded-xl text-2xl"
  }

  @box "min-w-0 flex-1 px-0 text-center font-mono font-semibold shadow-soft"

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
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("otp") end))
    |> assign_new(:value, fn -> nil end)
    |> assign_code()
    |> render_otp()
  end

  defp assign_code(assigns) do
    cells = cells(assigns.value, assigns.length, assigns.mode)
    separators = separators(assigns.separator, assigns.length)

    assign(assigns,
      code: Enum.join(cells),
      boxes:
        cells
        |> Enum.with_index(1)
        |> Enum.map(fn {cell, number} ->
          %{number: number, cell: cell, separator: number in separators}
        end),
      state: Control.state(assigns.state, assigns.errors),
      callback: Overlay.callback(assigns.on_complete, assigns.id, assigns.target)
    )
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
    <div class={@wrapper_class}><.control {assigns} /></div>
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
      <.control {assigns} />
    </Form.field>
    """
  end

  defp control(assigns) do
    assigns =
      assign(assigns,
        box_class: merge([@box, @sizes[assigns.size], filled(assigns.state), assigns.class]),
        labelledby: assigns.label && assigns.id <> "-label",
        group_class: merge(["flex w-full items-center gap-2", assigns.label && "mt-1.5"]),
        group_label: assigns.label || assigns.aria_label
      )

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
        <Input.input
          type={mask_type(@mask)}
          id={"#{@id}-#{box.number}"}
          value={box.cell}
          state={@state}
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

  defp filled(state) when state in ["error", "success"], do: nil
  defp filled(_state), do: "data-filled:border-primary dark:data-filled:border-accent"

  defp mask_type(true), do: "password"
  defp mask_type(false), do: "text"

  defp inputmode("numeric"), do: "numeric"
  defp inputmode("alphanumeric"), do: "text"

  defp pattern("numeric"), do: "[0-9]*"
  defp pattern("alphanumeric"), do: "[A-Za-z0-9]*"
end
