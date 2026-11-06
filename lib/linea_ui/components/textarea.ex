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
      "form-textarea w-full rounded-[11px] border-0 bg-white px-3 py-2.5 text-[14px] leading-[22px] text-slate-950 shadow-[inset_0_0_0_1px_var(--color-slate-300),0_1px_2px_rgb(23_23_26/.05)] placeholder:text-slate-400 hover:shadow-[inset_0_0_0_1px_var(--color-slate-400),0_1px_2px_rgb(23_23_26/.05)] focus:shadow-[inset_0_0_0_1px_var(--color-primary),0_0_0_4px_color-mix(in_oklab,var(--color-primary)_14%,transparent)] focus:ring-0 disabled:pointer-events-none disabled:select-none disabled:bg-zinc-100 dark:bg-navy-750 dark:text-navy-50 dark:shadow-[inset_0_0_0_1px_var(--color-navy-450)] dark:hover:shadow-[inset_0_0_0_1px_var(--color-navy-400)] dark:focus:shadow-[inset_0_0_0_1px_var(--color-accent),0_0_0_4px_color-mix(in_oklab,var(--color-accent)_16%,transparent)] dark:disabled:bg-navy-600",
    "filled" =>
      "form-textarea w-full rounded-md bg-slate-150 p-3 text-[13px] placeholder:text-slate-500 disabled:pointer-events-none disabled:select-none disabled:opacity-60 dark:bg-navy-900 dark:placeholder:text-navy-300",
    "plain" => "form-textarea w-full bg-transparent p-3 placeholder:text-slate-500"
  }

  @sizes %{
    "sm" => "p-2.5 text-xs",
    "md" => nil,
    "lg" => "p-4 text-sm"
  }

  @states %{
    {"outlined", "success"} =>
      "shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] hover:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] focus:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_14%,transparent)] dark:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)] dark:hover:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)] dark:focus:shadow-[inset_0_0_0_1px_var(--color-success),0_0_0_4px_color-mix(in_oklab,var(--color-success)_16%,transparent)]",
    {"outlined", "error"} =>
      "shadow-[inset_0_0_0_1px_var(--color-error),0_0_0_4px_color-mix(in_oklab,var(--color-error)_14%,transparent)] hover:shadow-[inset_0_0_0_1px_var(--color-error),0_0_0_4px_color-mix(in_oklab,var(--color-error)_14%,transparent)] focus:shadow-[inset_0_0_0_1px_var(--color-error),0_0_0_4px_color-mix(in_oklab,var(--color-error)_14%,transparent)] dark:shadow-[inset_0_0_0_1px_var(--color-error),0_0_0_4px_color-mix(in_oklab,var(--color-error)_16%,transparent)] dark:hover:shadow-[inset_0_0_0_1px_var(--color-error),0_0_0_4px_color-mix(in_oklab,var(--color-error)_16%,transparent)] dark:focus:shadow-[inset_0_0_0_1px_var(--color-error),0_0_0_4px_color-mix(in_oklab,var(--color-error)_16%,transparent)]",
    {"filled", "success"} => "ring-1 ring-success dark:ring-success",
    {"filled", "error"} => "ring-1 ring-error dark:ring-error"
  }

  @frame "rounded-md border border-slate-200 ring-primary/25 transition-colors duration-200 focus-within:!border-primary focus-within:ring-3 hover:border-slate-400 dark:border-navy-450 dark:ring-accent/30 dark:focus-within:!border-accent dark:hover:border-navy-400"

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

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Three paddings and text sizes: 10px and 12px, 12px and 13px, 16px and 14px."
  )

  attr(:resizable, :boolean, default: false)

  attr(:counter, :boolean,
    default: false,
    doc:
      "Shows a live character count under the text (\"68 / 200\" with `maxlength`, \"2 / 20 mín.\" below `min_length`). " <>
        "It warns from 90% of the limit and turns red past it; it updates while typing, without the server."
  )

  attr(:counter_format, :string,
    default: "%{count} / %{max}",
    doc:
      "The counter's text with a `maxlength`: `%{count}` and `%{max}` are replaced (`\"%{count} de %{max}\"` reads \"58 de 300\")."
  )

  attr(:counter_align, :string,
    default: "end",
    values: ~w(end start),
    doc:
      "`end` puts the counter at the right of the help line; `start` puts it right under the text, at the left, as a help line of its own."
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

  @classes_deps ~w(header footer variant size resizable autogrow state class)a

  def textarea(assigns) do
    assigns
    |> Control.assign_control()
    |> then(
      &assign_derived(&1, :state, [:state, :errors], fn -> Control.state(&1.state, &1.errors) end)
    )
    |> assign_id()
    |> then(&assign_derived(&1, :classes, @classes_deps, fn -> classes(&1) end))
    |> then(&assign_derived(&1, :length, [:value], fn -> length_of(&1) end))
    |> assign_derived(:frame, [], fn -> @frame end)
    |> render_textarea()
  end

  # The counter and autogrow hooks need an id: derived from the name, else from label/placeholder
  # (stable across renders; pass `id` to tell apart two nameless textareas with the same label).
  defp assign_id(%{id: nil} = assigns),
    do:
      assign(
        assigns,
        :id,
        ((assigns.counter or assigns.autogrow) && stable_id("textarea", assigns)) || nil
      )

  defp assign_id(assigns), do: assigns

  defp classes(%{header: [], footer: []} = assigns) do
    merge([
      @variants[assigns.variant],
      @sizes[assigns.size],
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
  defp counter_state(size, min, max, format) do
    cond do
      min && size > 0 && size < min -> {"#{size} / #{min} mín.", "bad"}
      is_nil(max) -> {to_string(size), "ok"}
      size > max -> {fill(format, size, max), "bad"}
      size >= max * @warn_at -> {fill(format, size, max), "warn"}
      true -> {fill(format, size, max), "ok"}
    end
  end

  defp fill(format, size, max),
    do:
      format
      |> String.replace("%{count}", to_string(size))
      |> String.replace("%{max}", to_string(max))

  # The help line keeps its muted color under `state="error"`; only error messages are red.
  defp help_state("error", []), do: nil
  defp help_state(state, _errors), do: state

  defp render_textarea(%{label: nil, help: nil, errors: [], header: [], footer: []} = assigns) do
    ~H"""
    <.control
      id={@id}
      name={@name}
      value={@value}
      rows={@rows}
      classes={@classes}
      disabled={@disabled}
      state={@state}
      rest={@rest}
      counter={@counter}
      min_length={@min_length}
      autogrow={@autogrow}
      max_rows={@max_rows}
      length={@length}
      counter_format={@counter_format}
      counter_align={@counter_align}
      aside={false}
    />
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
      state={help_state(@state, @errors)}
      class={@wrapper_class}
    >
      <.control
        id={@id}
        name={@name}
        value={@value}
        rows={@rows}
        classes={@classes}
        disabled={@disabled}
        state={@state}
        rest={@rest}
        counter={@counter}
        min_length={@min_length}
        autogrow={@autogrow}
        max_rows={@max_rows}
        length={@length}
        counter_format={@counter_format}
        counter_align={@counter_align}
        aside={@counter_align == "end"}
      />
      <:aside :if={@counter and @counter_align == "end"}>
        <.counter
          id={@id}
          length={@length}
          min_length={@min_length}
          rest={@rest}
          counter_format={@counter_format}
        />
      </:aside>
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
      state={help_state(@state, @errors)}
      as="div"
      class={@wrapper_class}
    >
      <:aside :if={@counter}>
        <.counter
          id={@id}
          length={@length}
          min_length={@min_length}
          rest={@rest}
          counter_format={@counter_format}
        />
      </:aside>
      <div class={merge([@frame, @label && "mt-1.5", @frame_class])}>
        <div :for={header <- @header} class="flex justify-between">{render_slot(header)}</div>
        <label class="block"><.control
          id={@id}
          name={@name}
          value={@value}
          rows={@rows}
          classes={@classes}
          disabled={@disabled}
          state={@state}
          rest={@rest}
          counter={@counter}
          min_length={@min_length}
          autogrow={@autogrow}
          max_rows={@max_rows}
          length={@length}
          counter_format={@counter_format}
          counter_align={@counter_align}
          aside={true}
        /></label>
        <div :for={footer <- @footer} class="flex justify-between px-2.5 py-2">
          {render_slot(footer)}
        </div>
      </div>
    </Form.field>
    """
  end

  # With a caption, help or errors the counter shares their row (`Form.field`'s `:aside`); alone it
  # sits right under the control.
  defp control(%{counter: true, aside: false} = assigns) do
    ~H"""
    <div class="w-full">
      <.field_control
        id={@id}
        name={@name}
        value={@value}
        rows={@rows}
        classes={@classes}
        disabled={@disabled}
        state={@state}
        rest={@rest}
        counter={@counter}
        min_length={@min_length}
        autogrow={@autogrow}
        max_rows={@max_rows}
        counter_format={@counter_format}
        described_by={"#{@id}-counter"}
      />
      <div class={[
        "mt-1 flex px-0.5",
        (@counter_align == "start" && "justify-start") || "justify-end"
      ]}>
        <.counter
          id={@id}
          length={@length}
          min_length={@min_length}
          rest={@rest}
          counter_format={@counter_format}
        />
      </div>
    </div>
    """
  end

  defp control(%{counter: true} = assigns) do
    ~H"""
    <.field_control
      id={@id}
      name={@name}
      value={@value}
      rows={@rows}
      classes={@classes}
      disabled={@disabled}
      state={@state}
      rest={@rest}
      counter={@counter}
      min_length={@min_length}
      autogrow={@autogrow}
      max_rows={@max_rows}
      counter_format={@counter_format}
      described_by={"#{@id}-counter"}
    />
    """
  end

  defp control(assigns) do
    ~H"""
    <.field_control
      id={@id}
      name={@name}
      value={@value}
      rows={@rows}
      classes={@classes}
      disabled={@disabled}
      state={@state}
      rest={@rest}
      counter={@counter}
      min_length={@min_length}
      autogrow={@autogrow}
      max_rows={@max_rows}
      counter_format={@counter_format}
      described_by={nil}
    />
    """
  end

  defp counter(assigns) do
    deps = [:length, :min_length, :rest, :counter_format]

    {text, tone} =
      counter_state(
        assigns.length,
        assigns.min_length,
        limit(assigns.rest[:maxlength]),
        assigns.counter_format
      )

    assigns =
      assigns
      |> assign_derived(:text, deps, fn -> text end)
      |> assign_derived(:tone, deps, fn -> tone end)

    ~H"""
    <span
      id={"#{@id}-counter"}
      aria-live="polite"
      aria-atomic="true"
      data-tone={@tone}
      class="text-xs tabular-nums text-slate-400 data-[tone=bad]:text-error data-[tone=warn]:text-warning dark:text-navy-300"
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
      data-format={@counter && @counter_format}
      data-autogrow={@autogrow && ""}
      data-max-rows={@autogrow && @max_rows}
      {@rest}
    >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end
end
