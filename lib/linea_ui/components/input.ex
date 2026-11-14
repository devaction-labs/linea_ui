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
      <.input name="document" mask="cpf_cnpj" label="CPF ou CNPJ" mask_submit="raw" />
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
  | `cpf_cnpj` | none. Brazilian document: CPF (`000.000.000-00`) up to 11 digits, CNPJ (`00.000.000/0000-00`) beyond, switching by itself while typing, deleting and pasting; at most 14 digits. Sets `inputmode="numeric"` (override it with `inputmode`) |
  | `numeral` | `thousands` (`thousand lakh wan none`), `decimals` (`2`), `delimiter` (`","`), `decimal_mark` (`"."`), `positive`, `prefix` (`"R$ "`, shown before the figure and left out of the raw value) |

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

  ## Buttons inside the input

  `:prefix` and `:suffix` hold icons and let clicks fall through to the input. Mark one
  `interactive` to put a button there (send, clear, show the password):

      <.input name="message" value={@message} placeholder="Message">
        <:suffix interactive>
          <.button variant="flat" class="size-7 rounded-[var(--pill-in,8px)] p-0" type="submit" aria-label="Send">
            <.icon name="huge-sent" class="size-4" />
          </.button>
        </:suffix>
      </.input>

  A suffix that holds text (a unit, a count) takes `text`: the box sizes to its content and the
  input's right padding follows it (the `LineaUI.InputSuffix` hook publishes the width, 2.25rem
  until it runs, as for an icon). Icon suffixes are unchanged.

      <.input name="guests" type="number">
        <:suffix text>4 pessoas</:suffix>
      </.input>

  ## Beside the caption and under the box

  `:label_aside` puts content at the right of the caption (a "Forgot?" link, the word of a strength meter) and
  `:below` puts it between the box and the help line (the meter's bars). Both need the caption block, so they
  go with `label` (`below` also works without one).

      <.input field={@form[:password]} type="password" label="Senha" help="Mínimo de 8 caracteres">
        <:label_aside><.link navigate={~p"/forgot"}>Esqueci</.link></:label_aside>
        <:below><div class="sg-meter">…</div></:below>
      </.input>

  The mask runs in the `LineaUI.InputMask` hook, so a masked input needs a stable `id` (it gets
  one from `field`; pass one otherwise when the input re-renders).
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @types ~w(text email password number search tel url date time datetime-local month week color file hidden)

  @variants %{
    "outlined" =>
      "form-input w-full rounded-(--pill) border-0 bg-(--ctl) px-3 py-0 text-[14px] leading-[22px] text-(--fg) shadow-[inset_0_0_0_1px_var(--ctl-line),var(--shadow-xs)] placeholder:text-(--faint) hover:shadow-[inset_0_0_0_1px_var(--ctl-line-strong),var(--shadow-xs)] focus:shadow-[inset_0_0_0_1px_var(--accent),0_0_0_3px_color-mix(in_srgb,var(--accent)_22%,transparent)] focus:ring-0 disabled:pointer-events-none disabled:select-none disabled:opacity-50",
    "filled" =>
      "form-input w-full rounded-(--pill) border-0 bg-(--ctl-fill) px-3 py-0 text-[14px] leading-[22px] text-(--fg) placeholder:text-(--faint) hover:bg-(--ctl-fill-hover) focus:bg-(--ctl) focus:shadow-[inset_0_0_0_1px_var(--accent),0_0_0_3px_color-mix(in_srgb,var(--accent)_22%,transparent)] focus:ring-0 disabled:pointer-events-none disabled:select-none disabled:opacity-50",
    "plain" => "form-input w-full bg-transparent px-3 py-2 placeholder:text-(--faint)"
  }

  # The error paint is part of the variant (`aria-invalid:` utilities) instead of a class swap, so the
  # classes do not change when errors appear or go away on a keystroke.
  @error_states %{
    "outlined" => "linea-invalid",
    "filled" => "linea-invalid-filled"
  }

  @states %{
    {"outlined", "success"} =>
      "shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] hover:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] focus:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] dark:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)] dark:hover:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)] dark:focus:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)]",
    {"filled", "success"} =>
      "shadow-[inset_0_0_0_1px_var(--color-success)] focus:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_3px_color-mix(in_srgb,var(--color-success)_18%,transparent)]"
  }

  @sizes %{
    "sm" => "h-8 rounded-(--pill-in) px-2.5 text-[13px]",
    "md" => "h-10 text-sm",
    "lg" => "h-12 px-4 text-[15px]"
  }

  @shapes %{
    "rounded" => "",
    "pill" => "rounded-full px-4"
  }

  @aligns %{"left" => nil, "right" => "text-right"}

  @icon "pointer-events-none absolute flex h-full w-10 items-center justify-center text-(--faint) peer-focus:text-(--accent)"

  @interactive_icon "absolute flex h-full w-10 items-center justify-center text-(--faint) hover:text-(--ink)"

  @text_suffix "pointer-events-none absolute flex h-full items-center whitespace-nowrap pr-3 pl-1 text-[13px] text-(--faint) peer-focus:text-(--accent)"

  @interactive_text_suffix "absolute flex h-full items-center whitespace-nowrap pr-3 pl-1 text-[13px] text-(--faint) hover:text-(--ink)"

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

  attr(:label_hint, :string,
    default: nil,
    doc: "A dimmed note at the right of the caption, as the canvas's \"opcional\"."
  )

  attr(:layout, :string,
    default: "stacked",
    values: ~w(stacked inline),
    doc: "`inline` puts the caption at the left of the input instead of above it."
  )

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
    values: [nil, "blocks", "credit_card", "date", "time", "phone", "numeral", "cpf_cnpj"]
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

  slot(:label_aside,
    doc:
      "Content at the right of the caption (a \"Esqueci\" link, a strength word), on the caption's row."
  )

  slot(:below, doc: "Content between the input and the help line (strength bars).")

  slot :prefix, doc: "An icon inside the input, on the left." do
    attr(:interactive, :boolean,
      doc:
        "Its content takes clicks (a button): the box drops `pointer-events-none` and the focus color."
    )

    attr(:class, :any, doc: "Merged into the box around the content.")
  end

  slot :suffix,
    doc:
      "An icon inside the input, on the right; with `interactive`, a button (send, clear, show password)." do
    attr(:interactive, :boolean,
      doc:
        "Its content takes clicks (a button): the box drops `pointer-events-none` and the focus color."
    )

    attr(:text, :boolean,
      doc:
        "The content is text: the box sizes to it instead of the fixed icon box, and the input's right padding follows."
    )

    attr(:class, :any, doc: "Merged into the box around the content.")
  end

  # What `attrs/1` reads (`raw` and `list_id` are derived before it; `raw` itself follows `mask` and `mask_submit`). Nothing that changes on a
  # keystroke (`id`, `name`, `value`, `state`) is here: those are rendered apart from the blob.
  @attrs_deps ~w(type mask mask_submit disabled list_id clear_on_submit mask_options rest)a

  @classes_deps ~w(variant size shape align prefix suffix state class)a

  def input(assigns) do
    assigns
    |> Control.assign_control()
    |> assign_mask_id()
    |> then(&assign_derived(&1, :classes, @classes_deps, fn -> classes(&1) end))
    |> then(
      &assign_derived(&1, :state, [:state, :errors], fn -> Control.state(&1.state, &1.errors) end)
    )
    |> assign_list()
    |> then(
      &assign_derived(&1, :raw, [:mask, :mask_submit, :id, :name, :value, :rest], fn ->
        raw_input(&1)
      end)
    )
    |> then(&assign_derived(&1, :attrs, @attrs_deps, fn -> attrs(&1) end))
    |> render_input()
  end

  defp assign_mask_id(%{mask: nil, clear_on_submit: false, id: nil, suffix: [_ | _]} = assigns),
    do: assign_mask_id(assigns, text_suffix?(assigns.suffix))

  defp assign_mask_id(%{mask: nil, clear_on_submit: false} = assigns), do: assigns
  defp assign_mask_id(%{id: nil} = assigns), do: assign(assigns, :id, stable_id("input", assigns))
  defp assign_mask_id(assigns), do: assigns

  defp assign_mask_id(assigns, true), do: assign(assigns, :id, stable_id("input", assigns))
  defp assign_mask_id(assigns, false), do: assigns

  defp text_suffix?(suffix), do: Enum.any?(suffix, &(&1[:text] == true))

  defp assign_list(%{options: []} = assigns),
    do: assign_derived(assigns, :list_id, [:options], fn -> nil end)

  defp assign_list(%{id: nil} = assigns),
    do: assign(assigns, id: stable_id("input", assigns)) |> assign_list()

  defp assign_list(assigns),
    do: assign_derived(assigns, :list_id, [:options, :id], fn -> "#{assigns.id}-options" end)

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
        disabled: assigns.disabled,
        list: assigns.list_id,
        "phx-hook": hook(assigns),
        "data-clear-on-submit": assigns.clear_on_submit && "",
        inputmode: mask_inputmode(assigns.mask),
        "data-mask": assigns.mask,
        "data-mask-submit": assigns.raw && "raw",
        "data-mask-options": assigns.mask && JSON.encode!(assigns.mask_options)
      },
      assigns.rest
    )
  end

  defp mask_inputmode("cpf_cnpj"), do: "numeric"
  defp mask_inputmode(_mask), do: nil

  defp hook(%{mask: mask}) when is_binary(mask), do: "LineaUI.InputMask"
  defp hook(%{clear_on_submit: true}), do: "LineaUI.InputSync"
  defp hook(_assigns), do: nil

  defp sync_value(type, value), do: Phoenix.HTML.Form.normalize_value(type, value) || ""

  @doc false
  def classes(assigns) do
    merge([
      @variants[assigns.variant],
      Map.get(assigns, :error_paint, true) && @error_states[assigns.variant],
      @sizes[assigns.size],
      @shapes[assigns.shape],
      @aligns[assigns.align],
      icon_padding(assigns),
      @states[{assigns.variant, success(assigns.state)}],
      assigns.class
    ])
  end

  defp success("success"), do: "success"
  defp success(_state), do: nil

  defp icon_padding(%{prefix: [], suffix: []}), do: nil

  defp icon_padding(%{prefix: [], suffix: suffix}),
    do: suffix_padding(text_suffix?(suffix), "peer")

  defp icon_padding(%{prefix: _, suffix: []}), do: "peer pl-9"
  defp icon_padding(%{suffix: suffix}), do: suffix_padding(text_suffix?(suffix), "peer pl-9")

  defp suffix_padding(true, base), do: base <> " pr-[var(--linea-suffix-w,2.25rem)]"
  defp suffix_padding(false, "peer"), do: "peer pr-9"
  defp suffix_padding(false, "peer pl-9"), do: "peer px-9"

  defp render_input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  defp render_input(
         %{
           label: nil,
           help: nil,
           errors: [],
           options: [],
           label_aside: [],
           below: []
         } = assigns
       ) do
    ~H"""
    <.control
      id={@id}
      name={@name}
      value={@value}
      type={@type}
      state={@state}
      classes={@classes}
      clear_on_submit={@clear_on_submit}
      attrs={@attrs}
      raw={@raw}
      prefix={@prefix}
      suffix={@suffix}
    />
    """
  end

  defp render_input(assigns) do
    ~H"""
    <Form.field
      id={@id}
      label={@label}
      label_class={@label_class}
      label_hint={@label_hint}
      layout={@layout}
      help={@help}
      errors={@errors}
      state={@state}
      class={@wrapper_class}
    >
      <:label_aside :if={@label_aside != []}>{render_slot(@label_aside)}</:label_aside>
      <:below :if={@below != []}>{render_slot(@below)}</:below>
      <.control
        id={@id}
        name={@name}
        value={@value}
        type={@type}
        state={@state}
        classes={@classes}
        clear_on_submit={@clear_on_submit}
        attrs={@attrs}
        raw={@raw}
        prefix={@prefix}
        suffix={@suffix}
      />
      <datalist :if={@list_id} id={@list_id}>
        <option :for={option <- @options} value={option}></option>
      </datalist>
    </Form.field>
    """
  end

  @doc false
  # The `aria-invalid` the error paint reads: `"true"` while `state` is `error`, unless the caller set
  # `aria-invalid` itself in `rest` (it then rules, as every other attr of `rest` does, and the tag does not get it twice).
  @spec invalid(String.t() | nil, map()) :: String.t() | nil
  def invalid(state, rest) do
    if Map.has_key?(rest, :"aria-invalid"), do: nil, else: (state == "error" && "true") || nil
  end

  defp assign_invalid(assigns),
    do:
      assign_derived(assigns, :invalid, [:state, :attrs], fn ->
        invalid(assigns.state, assigns.attrs)
      end)

  defp control(%{prefix: [], suffix: [], raw: nil} = assigns) do
    assigns = assign_invalid(assigns)

    ~H"""
    <input
      id={@id}
      name={@raw == nil && @name}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      aria-invalid={@invalid}
      data-value={@clear_on_submit && sync_value(@type, @value)}
      class={@classes}
      {@attrs}
    />
    """
  end

  defp control(assigns) do
    assigns = assign_invalid(assigns)

    ~H"""
    <span
      id={text_suffix?(@suffix) && "#{@id}-field"}
      class="relative flex w-full"
      phx-hook={text_suffix?(@suffix) && "LineaUI.InputSuffix"}
    >
      <input
        id={@id}
        name={@raw == nil && @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        aria-invalid={@invalid}
        data-value={@clear_on_submit && sync_value(@type, @value)}
        class={@classes}
        {@attrs}
      />
      <input :if={@raw} type="hidden" {@raw} />
      <span :for={prefix <- @prefix} class={adornment(prefix, "left-0")} data-prefix>
        {render_slot(prefix)}
      </span>
      <span
        :for={suffix <- @suffix}
        class={adornment(suffix, "right-0")}
        data-suffix
        data-suffix-text={suffix[:text] == true && ""}
      >
        {render_slot(suffix)}
      </span>
    </span>
    """
  end

  @doc false
  # The classes of the box that holds a `:prefix` or `:suffix` entry (`side` is `left-0` or `right-0`).
  def adornment(entry, side),
    do:
      merge([
        adornment_base(entry[:interactive] == true, entry[:text] == true),
        side,
        entry[:class]
      ])

  defp adornment_base(true, false), do: @interactive_icon
  defp adornment_base(false, false), do: @icon
  defp adornment_base(true, true), do: @interactive_text_suffix
  defp adornment_base(false, true), do: @text_suffix
end
