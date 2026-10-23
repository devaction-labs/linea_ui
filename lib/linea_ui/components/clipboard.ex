defmodule LineaUI.Components.Clipboard do
  @moduledoc """
  LineOne's copy to clipboard: a button that copies a text, and a field with a copy button
  joined to it.

      <.clipboard value="mix phx.new demo">Copy</.clipboard>
      <.clipboard from="#invite-link" size="xs">Copy</.clipboard>
      <.clipboard_input id="share" value={@url} />

  `from` is a selector: a field gives its value, any other element its text. After a copy the
  toaster shows `toast` ("Text Copied", in the success color, as LineOne does), the button keeps
  `data-copied` for two seconds (style it with `data-copied:`) and `on_copy` runs; a copy that
  fails shows `error_toast`. With `on_copy` as an event name the LiveView (or `target`) gets
  `handle_event(name, %{"id" => id}, socket)`.
  """

  use LineaUI.Component

  alias LineaUI.Components.Button
  alias LineaUI.Components.Overlay

  @doc """
  A button that copies `value`, or what `from` points at.

  Events: `on_copy` pushes `%{"id" => id}` when it is an event name.
  """
  attr :id, :string, required: true, doc: "Needed by the hook."
  attr :value, :string, default: nil, doc: "The text to copy."

  attr :from, :string,
    default: nil,
    doc: "A selector of the field or element whose text is copied."

  attr :toast, :string, default: "Text Copied", doc: "Shown after a copy; `nil` for none."
  attr :error_toast, :string, default: "Error"
  attr :on_copy, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil

  attr :color, :string,
    default: "primary",
    values: ~w(neutral primary secondary info success warning error)

  attr :variant, :string, default: "solid", values: ~w(solid glow outline soft bordered flat)
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def clipboard(assigns) do
    assigns =
      assigns
      |> assign(:on_copy_js, Overlay.callback(assigns.on_copy, assigns.id, assigns.target))

    ~H"""
    <Button.button
      id={@id}
      color={@color}
      variant={@variant}
      size={@size}
      class={@class}
      phx-hook="LineaUI.Clipboard"
      data-value={@value}
      data-from={@from}
      data-toast={@toast}
      data-error-toast={@error_toast}
      data-on-copy={@on_copy_js}
      {@rest}
    >
      {@inner_block == [] && "Copy"}{render_slot(@inner_block)}
    </Button.button>
    """
  end

  @doc """
  LineOne's "Advanced Usage": a text field with a copy button joined to its end. The field is a
  real input (`name`, `value`, `phx-change` work), and the button copies what it holds.
  """
  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :label, :string, default: "Copy", doc: "The button's text."
  attr :toast, :string, default: "Text Copied"
  attr :error_toast, :string, default: "Error"
  attr :on_copy, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Merged into the wrapper."
  attr :rest, :global, include: ~w(readonly disabled phx-debounce autocomplete form)

  def clipboard_input(assigns) do
    ~H"""
    <div class={merge(["flex -space-x-px", @class])}>
      <input
        id={@id}
        type="text"
        name={@name}
        value={@value}
        placeholder={@placeholder}
        class="form-input w-full rounded-l-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:z-10 hover:border-slate-400 focus:z-10 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"
        {@rest}
      />
      <.clipboard
        id={"#{@id}-copy"}
        from={"##{@id}"}
        toast={@toast}
        error_toast={@error_toast}
        on_copy={@on_copy}
        target={@target}
        class="z-2 rounded-l-none"
      >
        {@label}
      </.clipboard>
    </div>
    """
  end
end
