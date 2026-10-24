defmodule LineaUI.Components.Input do
  @moduledoc """
  LineOne's text inputs: outlined or filled, rounded or pill, three sizes, icons inside,
  success and error states, and input masks.

      <.input name="username" placeholder="Username" />
      <.input field={@form[:email]} type="email" label="Email" help="We never share it" />
      <.input name="q" variant="filled" shape="pill" size="lg" placeholder="Search" />
      <.input name="company" label="Company name" placeholder="Your Company">
        <:prefix><svg>…</svg></:prefix>
      </.input>
      <.input name="username" value="taken" state="error" help="Username is invalid" />
      <.input name="amount" size="sm" align="right" />

  Without a caption, help or errors it renders the bare `<input>` (wrapped in a positioning
  span when it has icons), so it can sit inside an `input_group`.

  ## Masks

  `mask` formats what is typed, as LineOne's Cleave.js examples do. `mask_options` tunes it:

      <.input name="card" mask="credit_card" placeholder="xxxx xxxx xxxx xxxx" />
      <.input name="date" mask="date" mask_options={%{pattern: ~w(m d Y), delimiter: "-"}} />
      <.input name="time" mask="time" mask_options={%{pattern: ~w(h m s)}} />
      <.input name="phone" mask="phone" />
      <.input name="amount" mask="numeral" mask_options={%{thousands: "lakh"}} />
      <.input name="code" mask="blocks" mask_options={%{blocks: [3, 2, 3, 3], delimiters: [".", "_", "-"], uppercase: true}} />
      <.input name="ref" mask="blocks" mask_options={%{prefix: "Prefix", delimiter: "-", blocks: [6, 4, 4, 7]}} />

  | mask | options |
  |---|---|
  | `blocks` | `blocks`, `delimiter`, `delimiters`, `prefix`, `uppercase`, `lowercase`, `numeric` |
  | `credit_card` | `delimiter` (`" "`); blocks follow the card brand (Amex 4-6-5, Diners 4-6-4) |
  | `date` | `pattern` of `d m y Y` (`~w(d m Y)`), `delimiter` (`"/"`) |
  | `time` | `pattern` of `h m s` (`~w(h m s)`), `delimiter` (`":"`) |
  | `phone` | `blocks` (`[3, 3, 4]`), `delimiter` (`" "`) |
  | `numeral` | `thousands` (`thousand lakh wan none`), `decimals` (`2`), `delimiter` (`","`), `decimal_mark` (`"."`), `positive` |

  The input submits the masked text. `mask_submit="raw"` submits the unmasked value instead
  (digits, or a plain number like `1234.5` for `numeral`) through a hidden input that carries
  the field's name; `phx-debounce`/`phx-throttle` are copied onto it.

      <.input field={@form[:amount]} mask="numeral" mask_submit="raw" phx-debounce="300" />

  ## Clearing a focused input

  `clear_on_submit` makes the field take the server's `value` after its form is submitted even
  while it has focus:

      <.form for={@form} phx-submit="add">
        <.input id="todo" name="title" value={@title} clear_on_submit />
      </.form>

  The mask runs in the `LineaUI.InputMask` hook, so a masked input needs a stable `id` (it gets
  one from `field`; pass one otherwise when the input re-renders).
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @types ~w(text email password number search tel url date time datetime-local month week color file hidden)

  @variants %{
    "outlined" =>
      "form-input w-full rounded-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary disabled:pointer-events-none disabled:select-none disabled:border-none disabled:bg-zinc-100 dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent dark:disabled:bg-navy-600",
    "filled" =>
      "form-input w-full rounded-lg bg-slate-150 px-3 py-2 ring-primary/50 placeholder:text-slate-400 hover:bg-slate-200 focus:ring-3 disabled:pointer-events-none disabled:select-none disabled:opacity-60 dark:bg-navy-900/90 dark:ring-accent/50 dark:placeholder:text-navy-300 dark:hover:bg-navy-900 dark:focus:bg-navy-900",
    "plain" => "form-input w-full bg-transparent px-3 py-2 placeholder:text-slate-400/70"
  }

  @states %{
    {"outlined", "success"} =>
      "border-success hover:border-success focus:border-success dark:border-success dark:hover:border-success dark:focus:border-success",
    {"outlined", "error"} =>
      "border-error hover:border-error focus:border-error dark:border-error dark:hover:border-error dark:focus:border-error",
    {"filled", "success"} => "ring-1 ring-success focus:ring-success/50 dark:ring-success",
    {"filled", "error"} => "ring-1 ring-error focus:ring-error/50 dark:ring-error"
  }

  @sizes %{
    "sm" => "h-8 text-xs-plus",
    "md" => "",
    "lg" => "h-12 text-base"
  }

  @shapes %{
    "rounded" => "",
    "pill" => "rounded-full px-4"
  }

  @aligns %{"left" => nil, "right" => "text-right"}

  @icon "pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent"

  @doc """
  Renders a text-like `<input>`, with its caption, help and errors when given.
  """
  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."
  )

  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any)
  attr(:type, :string, default: "text", values: @types)

  attr(:variant, :string,
    default: "outlined",
    values: ~w(outlined filled plain),
    doc: "`plain` has no border nor background, for inputs inside a framed block."
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:shape, :string, default: "rounded", values: ~w(rounded pill))

  attr(:align, :string,
    default: "left",
    values: ~w(left right),
    doc: "`right` aligns the typed text to the right, for amounts."
  )

  attr(:state, :string,
    default: nil,
    values: [nil, "success", "error"],
    doc: "Paints the border and the help line. Errors set `error` on their own."
  )

  attr(:label, :string, default: nil, doc: "The caption.")
  attr(:label_class, :any, default: nil, doc: "Classes of the caption text.")
  attr(:help, :string, default: nil, doc: "The small line under the control.")

  attr(:errors, :list,
    default: [],
    doc: "Messages to show; `field` adds its own once the input was used."
  )

  attr(:disabled, :boolean, default: false)

  attr(:options, :list,
    default: [],
    doc: "Suggestions, rendered as the input's `<datalist>`."
  )

  attr(:mask, :string,
    default: nil,
    values: [nil, "blocks", "credit_card", "date", "time", "phone", "numeral"]
  )

  attr(:mask_options, :map, default: %{})

  attr(:mask_submit, :string,
    default: "formatted",
    values: ~w(formatted raw),
    doc: "`raw` submits the unmasked value (digits, a plain number) through a hidden input."
  )

  attr(:clear_on_submit, :boolean,
    default: false,
    doc:
      "LiveView never overwrites the value of a focused input, so a field that keeps focus after `phx-submit` (a todo or chat box) would keep its text. With this, the first server render after the surrounding form is submitted writes `value` into the input even while it has focus; render `value=\"\"` to clear it. Needs a stable `id`."
  )

  attr(:wrapper_class, :any, default: nil, doc: "Classes of the block around a captioned input.")
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(accept autocomplete autofocus form list max maxlength min minlength multiple pattern placeholder readonly required size step inputmode)
  )

  slot(:prefix, doc: "An icon inside the input, on the left.")
  slot(:suffix, doc: "An icon inside the input, on the right.")

  def input(assigns) do
    assigns
    |> Control.assign_control()
    |> assign_mask_id()
    |> then(&assign(&1, :state, Control.state(&1.state, &1.errors)))
    |> assign_list()
    |> then(&assign(&1, :raw, raw_input(&1)))
    |> then(&assign(&1, :attrs, attrs(&1)))
    |> render_input()
  end

  defp assign_mask_id(%{mask: nil, clear_on_submit: false} = assigns), do: assigns
  defp assign_mask_id(%{id: nil} = assigns), do: assign(assigns, :id, gen_id("input"))
  defp assign_mask_id(assigns), do: assigns

  defp assign_list(%{options: []} = assigns), do: assign(assigns, :list_id, nil)

  defp assign_list(%{id: nil} = assigns),
    do: assign(assigns, id: gen_id("input")) |> assign_list()

  defp assign_list(assigns), do: assign(assigns, :list_id, "#{assigns.id}-options")

  defp raw_input(%{mask: mask, mask_submit: "raw"} = assigns) when is_binary(mask) do
    Map.merge(
      %{
        id: "#{assigns.id}-raw",
        name: assigns.name,
        value: assigns.value,
        form: assigns.rest[:form]
      },
      Map.take(assigns.rest, [:"phx-debounce", :"phx-throttle"])
    )
  end

  defp raw_input(_assigns), do: nil

  defp attrs(assigns) do
    Map.merge(
      %{
        type: assigns.type,
        id: assigns.id,
        name: assigns.raw == nil && assigns.name,
        value: Phoenix.HTML.Form.normalize_value(assigns.type, assigns.value),
        class: classes(assigns),
        disabled: assigns.disabled,
        list: assigns.list_id,
        "aria-invalid": assigns.state == "error" && "true",
        "phx-hook": hook(assigns),
        "data-clear-on-submit": assigns.clear_on_submit && "",
        "data-value": assigns.clear_on_submit && sync_value(assigns),
        "data-mask": assigns.mask,
        "data-mask-submit": assigns.raw && "raw",
        "data-mask-options": assigns.mask && JSON.encode!(assigns.mask_options)
      },
      assigns.rest
    )
  end

  defp hook(%{mask: mask}) when is_binary(mask), do: "LineaUI.InputMask"
  defp hook(%{clear_on_submit: true}), do: "LineaUI.InputSync"
  defp hook(_assigns), do: nil

  defp sync_value(assigns),
    do: Phoenix.HTML.Form.normalize_value(assigns.type, assigns.value) || ""

  defp classes(assigns) do
    merge([
      @variants[assigns.variant],
      @sizes[assigns.size],
      @shapes[assigns.shape],
      @aligns[assigns.align],
      icon_padding(assigns),
      @states[{assigns.variant, assigns.state}],
      assigns.class
    ])
  end

  defp icon_padding(%{prefix: [], suffix: []}), do: nil
  defp icon_padding(%{prefix: [], suffix: _}), do: "peer pr-9"
  defp icon_padding(%{prefix: _, suffix: []}), do: "peer pl-9"
  defp icon_padding(_assigns), do: "peer px-9"

  defp render_input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  defp render_input(%{label: nil, help: nil, errors: [], options: []} = assigns) do
    ~H"""
    <.control attrs={@attrs} raw={@raw} prefix={@prefix} suffix={@suffix} />
    """
  end

  defp render_input(assigns) do
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
      <.control attrs={@attrs} raw={@raw} prefix={@prefix} suffix={@suffix} />
      <datalist :if={@list_id} id={@list_id}>
        <option :for={option <- @options} value={option}></option>
      </datalist>
    </Form.field>
    """
  end

  defp control(%{prefix: [], suffix: [], raw: nil} = assigns) do
    ~H"""
    <input {@attrs} />
    """
  end

  defp control(assigns) do
    assigns = assign(assigns, :icon, @icon)

    ~H"""
    <span class="relative flex w-full">
      <input {@attrs} />
      <input :if={@raw} type="hidden" {@raw} />
      <span :for={prefix <- @prefix} class={@icon}>{render_slot(prefix)}</span>
      <span :for={suffix <- @suffix} class={[@icon, "right-0"]}>{render_slot(suffix)}</span>
    </span>
    """
  end
end
