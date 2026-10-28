defmodule LineaUI.Components.Textarea do
  @moduledoc """
  LineOne's textareas: outlined or filled, fixed or resizable, and framed with a header or a
  footer (a title input, a toolbar, a submit button).

      <.textarea name="bio" placeholder="Enter Text" />
      <.textarea field={@form[:bio]} label="Bio" variant="filled" resizable />

      <.textarea name="note" maxlength={200} counter autogrow max_rows={8} />
      <.textarea name="why" counter min_length={20} />

      <.textarea name="post" rows={5} placeholder="Write the post">
        <:header>
          <.input name="title" variant="plain" class="p-3 text-lg font-medium" placeholder="Title" />
        </:header>
        <:footer>
          <span>…toolbar…</span>
          <.button color="primary" size="sm">Save Post</.button>
        </:footer>
      </.textarea>
  """

  use LineaUI.Component

  alias LineaUI.Components.Control
  alias LineaUI.Components.Form

  @variants %{
    "outlined" =>
      "form-textarea w-full rounded-lg border border-slate-300 bg-transparent p-2.5 placeholder:text-slate-400/70 ring-primary/25 hover:border-slate-400 focus:border-primary focus:ring-3 disabled:pointer-events-none disabled:select-none disabled:bg-slate-150 disabled:opacity-60 dark:border-navy-450 dark:ring-accent/30 dark:hover:border-navy-400 dark:focus:border-accent dark:disabled:bg-navy-600",
    "filled" =>
      "form-textarea w-full rounded-lg bg-slate-150 p-2.5 placeholder:text-slate-400 disabled:pointer-events-none disabled:select-none disabled:opacity-60 dark:bg-navy-900 dark:placeholder:text-navy-300",
    "plain" => "form-textarea w-full bg-transparent p-3 placeholder:text-slate-400/70"
  }

  @states %{
    {"outlined", "success"} =>
      "border-success ring-success/25 hover:border-success focus:border-success dark:border-success dark:ring-success/30 dark:hover:border-success dark:focus:border-success",
    {"outlined", "error"} =>
      "border-error ring-error/25 hover:border-error focus:border-error dark:border-error dark:ring-error/30 dark:hover:border-error dark:focus:border-error",
    {"filled", "success"} => "ring-1 ring-success dark:ring-success",
    {"filled", "error"} => "ring-1 ring-error dark:ring-error"
  }

  @frame "rounded-lg border border-slate-300 ring-primary/25 transition-colors duration-200 focus-within:!border-primary focus-within:ring-3 hover:border-slate-400 dark:border-navy-450 dark:ring-accent/30 dark:focus-within:!border-accent dark:hover:border-navy-400"

  @framed_padding %{
    {true, false} => "pt-0",
    {false, true} => "pb-0",
    {true, true} => "py-0"
  }

  @doc """
  Renders a `<textarea>`. With a `header` or `footer` slot it sits, borderless, inside a
  bordered frame that lights up while it has focus.
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, doc: "Defaults to the field's id.")
  attr(:name, :string, doc: "Defaults to the field's name.")
  attr(:value, :any)
  attr(:rows, :integer, default: 4)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled plain))
  attr(:resizable, :boolean, default: false)

  attr(:counter, :boolean,
    default: false,
    doc:
      "Shows a live character count under the text (\"68 / 200\" with `maxlength`, \"2 / 20 mín.\" below `min_length`). " <>
        "It warns from 90% of the limit and turns red past it; it updates while typing, without the server."
  )

  attr(:min_length, :integer,
    default: nil,
    doc: "Minimum characters the counter asks for. Only the counter uses it: it blocks nothing."
  )

  attr(:autogrow, :boolean,
    default: false,
    doc: "The height follows the text, from `rows` up to `max_rows`. Not resizable by hand."
  )

  attr(:max_rows, :integer,
    default: nil,
    doc: "With `autogrow`, the most lines it grows to before it scrolls."
  )

  attr(:state, :string, default: nil, values: [nil, "success", "error"])
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

  attr(:frame_class, :any, default: nil, doc: "Classes of the frame drawn around header/footer.")
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(autocomplete autofocus cols form maxlength minlength placeholder readonly required wrap)
  )

  slot(:header, doc: "Content above the text, laid out as a row.")
  slot(:footer, doc: "Content below the text, laid out as a row with space between.")

  def textarea(assigns) do
    assigns
    |> Control.assign_control()
    |> then(&assign(&1, :state, Control.state(&1.state, &1.errors)))
    |> then(&assign(&1, :id, &1.id || ((&1.counter or &1.autogrow) && gen_id("textarea")) || nil))
    |> then(&assign(&1, :classes, classes(&1)))
    |> then(&assign(&1, :length, length_of(&1)))
    |> assign(:frame, @frame)
    |> render_textarea()
  end

  defp classes(%{header: [], footer: []} = assigns) do
    merge([
      @variants[assigns.variant],
      resize(assigns.resizable and not assigns.autogrow),
      grow(assigns.autogrow),
      @states[{assigns.variant, assigns.state}],
      assigns.class
    ])
  end

  defp classes(assigns) do
    merge([
      @variants["plain"],
      resize(assigns.resizable and not assigns.autogrow),
      grow(assigns.autogrow),
      @framed_padding[{assigns.header != [], assigns.footer != []}],
      assigns.class
    ])
  end

  defp resize(true), do: nil
  defp resize(false), do: "resize-none"

  defp grow(true), do: "overflow-hidden"
  defp grow(false), do: nil

  # Characters the way the browser counts `maxlength`: UTF-16 code units.
  defp length_of(%{value: value}) do
    "text"
    |> Phoenix.HTML.Form.normalize_value(value)
    |> to_string()
    |> :unicode.characters_to_binary(:utf8, :utf16)
    |> byte_size()
    |> div(2)
  end

  @warn_at 0.9

  defp limit(value) do
    case Integer.parse(to_string(value || "")) do
      {number, _rest} when number > 0 -> number
      _other -> nil
    end
  end

  # Mirrors `counterState` of `lib/textarea_logic.js`, so the first paint already says the right thing.
  defp counter_state(size, min, max) do
    cond do
      min && size > 0 && size < min -> {"#{size} / #{min} mín.", "bad"}
      is_nil(max) -> {to_string(size), "ok"}
      size > max -> {"#{size} / #{max}", "bad"}
      size >= max * @warn_at -> {"#{size} / #{max}", "warn"}
      true -> {"#{size} / #{max}", "ok"}
    end
  end

  defp render_textarea(%{label: nil, help: nil, errors: [], header: [], footer: []} = assigns) do
    ~H"""
    <.control {control_assigns(assigns, false)} />
    """
  end

  defp render_textarea(%{header: [], footer: []} = assigns) do
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
      <.control {control_assigns(assigns, true)} />
      <:aside :if={@counter}><.counter {control_assigns(assigns, true)} /></:aside>
    </Form.field>
    """
  end

  defp render_textarea(assigns) do
    ~H"""
    <Form.field
      id={@id}
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      state={@state}
      as="div"
      class={@wrapper_class}
    >
      <:aside :if={@counter}><.counter {control_assigns(assigns, true)} /></:aside>
      <div class={merge([@frame, @label && "mt-1.5", @frame_class])}>
        <div :for={header <- @header} class="flex justify-between">{render_slot(header)}</div>
        <label class="block"><.control {control_assigns(assigns, true)} /></label>
        <div :for={footer <- @footer} class="flex justify-between px-2.5 py-2">
          {render_slot(footer)}
        </div>
      </div>
    </Form.field>
    """
  end

  defp control_assigns(assigns, aside) do
    assigns
    |> Map.take([
      :id,
      :name,
      :value,
      :rows,
      :classes,
      :disabled,
      :state,
      :rest,
      :counter,
      :min_length,
      :autogrow,
      :max_rows,
      :length
    ])
    |> Map.put(:aside, aside)
  end

  # With a caption, help or errors the counter shares their row (`Form.field`'s `:aside`); alone it
  # sits right under the control.
  defp control(%{counter: true, aside: false} = assigns) do
    ~H"""
    <div class="w-full">
      <.field_control {assigns} described_by={"#{@id}-counter"} />
      <div class="mt-1 flex justify-end px-0.5"><.counter {assigns} /></div>
    </div>
    """
  end

  defp control(%{counter: true} = assigns) do
    ~H"""
    <.field_control {assigns} described_by={"#{@id}-counter"} />
    """
  end

  defp control(assigns) do
    ~H"""
    <.field_control {assigns} described_by={nil} />
    """
  end

  defp counter(assigns) do
    {text, tone} =
      counter_state(assigns.length, assigns.min_length, limit(assigns.rest[:maxlength]))

    assigns = assign(assigns, text: text, tone: tone)

    ~H"""
    <span
      id={"#{@id}-counter"}
      aria-live="polite"
      aria-atomic="true"
      data-tone={@tone}
      class="text-tiny-plus tabular-nums text-slate-400 data-[tone=bad]:text-error data-[tone=warn]:text-warning dark:text-navy-300"
    >{@text}</span>
    """
  end

  defp field_control(assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      rows={@rows}
      class={@classes}
      disabled={@disabled}
      aria-invalid={@state == "error" && "true"}
      aria-describedby={@described_by}
      phx-hook={(@counter or @autogrow) && "LineaUI.Textarea"}
      data-counter={@counter && "#{@id}-counter"}
      data-min={@counter && @min_length}
      data-max={@counter && limit(@rest[:maxlength])}
      data-autogrow={@autogrow && ""}
      data-max-rows={@autogrow && @max_rows}
      {@rest}
    >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end
end
