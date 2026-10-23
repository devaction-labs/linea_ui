defmodule LineaUI.Components.Textarea do
  @moduledoc """
  LineOne's textareas: outlined or filled, fixed or resizable, and framed with a header or a
  footer (a title input, a toolbar, a submit button).

      <.textarea name="bio" placeholder="Enter Text" />
      <.textarea field={@form[:bio]} label="Bio" variant="filled" resizable />

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

  alias LineaUI.Components.Form

  @variants %{
    "outlined" =>
      "form-textarea w-full rounded-lg border border-slate-300 bg-transparent p-2.5 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary disabled:pointer-events-none disabled:select-none disabled:border-none disabled:bg-zinc-100 dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent dark:disabled:bg-navy-600",
    "filled" =>
      "form-textarea w-full rounded-lg bg-slate-150 p-2.5 placeholder:text-slate-400 disabled:pointer-events-none disabled:select-none disabled:opacity-60 dark:bg-navy-900 dark:placeholder:text-navy-300",
    "plain" => "form-textarea w-full bg-transparent p-3 placeholder:text-slate-400/70"
  }

  @states %{
    {"outlined", "success"} =>
      "border-success hover:border-success focus:border-success dark:border-success dark:hover:border-success dark:focus:border-success",
    {"outlined", "error"} =>
      "border-error hover:border-error focus:border-error dark:border-error dark:hover:border-error dark:focus:border-error",
    {"filled", "success"} => "ring-1 ring-success dark:ring-success",
    {"filled", "error"} => "ring-1 ring-error dark:ring-error"
  }

  @frame "rounded-lg border border-slate-300 transition-colors duration-200 focus-within:!border-primary hover:border-slate-400 dark:border-navy-450 dark:focus-within:!border-accent dark:hover:border-navy-400"

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
  attr(:id, :string)
  attr(:name, :string)
  attr(:value, :any)
  attr(:rows, :integer, default: 4)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled plain))
  attr(:resizable, :boolean, default: false)
  attr(:state, :string, default: nil, values: [nil, "success", "error"])
  attr(:label, :string, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:help, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:disabled, :boolean, default: false)
  attr(:wrapper_class, :any, default: nil)
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
    |> Form.assign_control()
    |> then(&assign(&1, :state, Form.state(&1.state, &1.errors)))
    |> then(&assign(&1, :classes, classes(&1)))
    |> assign(:frame, @frame)
    |> render_textarea()
  end

  defp classes(%{header: [], footer: []} = assigns) do
    merge([
      @variants[assigns.variant],
      resize(assigns.resizable),
      @states[{assigns.variant, assigns.state}],
      assigns.class
    ])
  end

  defp classes(assigns) do
    merge([
      @variants["plain"],
      resize(assigns.resizable),
      @framed_padding[{assigns.header != [], assigns.footer != []}],
      assigns.class
    ])
  end

  defp resize(true), do: nil
  defp resize(false), do: "resize-none"

  defp render_textarea(%{label: nil, help: nil, errors: [], header: [], footer: []} = assigns) do
    ~H"""
    <.control {control_assigns(assigns)} />
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
      <.control {control_assigns(assigns)} />
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
      <div class={merge([@frame, @label && "mt-1.5", @frame_class])}>
        <div :for={header <- @header} class="flex justify-between">{render_slot(header)}</div>
        <label class="block"><.control {control_assigns(assigns)} /></label>
        <div :for={footer <- @footer} class="flex justify-between p-2.5">
          {render_slot(footer)}
        </div>
      </div>
    </Form.field>
    """
  end

  defp control_assigns(assigns) do
    Map.take(assigns, [:id, :name, :value, :rows, :classes, :disabled, :state, :rest])
  end

  defp control(assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      rows={@rows}
      class={@classes}
      disabled={@disabled}
      aria-invalid={@state == "error" && "true"}
      {@rest}
    >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end
end
