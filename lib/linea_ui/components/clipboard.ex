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
  fails shows `error_toast`. With `copied_label` the button also turns success green and says it
  ("Copied") for those two seconds:

      <.clipboard value="mix phx.new demo" copied_label="Copied">Copy</.clipboard>

  `icon` puts a copy icon before the text (a check while copied) and `icon_only` makes a square
  button of it, for a code snippet:

      <.clipboard value="mix phx.new demo" icon copied_label="Copied">Copy</.clipboard>
      <.clipboard from="#cmd" icon_only variant="flat" aria-label="Copy command" />

  With `on_copy` as an event name the LiveView (or `target`) gets
  `handle_event(name, %{"id" => id}, socket)`.
  """

  use LineaUI.Component

  alias LineaUI.Components.Button
  alias LineaUI.Components.Overlay

  @square %{
    "xs" => "size-6",
    "sm" => "size-8",
    "md" => "size-[2.375rem]",
    "lg" => "size-11",
    "xl" => "size-[3.25rem]"
  }

  @copied_classes "group/clip data-copied:border-transparent data-copied:bg-success data-copied:text-white data-copied:shadow-none data-copied:hover:bg-success data-copied:hover:text-white data-copied:focus:bg-success data-copied:focus:text-white dark:data-copied:bg-success dark:data-copied:hover:bg-success dark:data-copied:focus:bg-success"

  @doc """
  A button that copies `value`, or what `from` points at.

  Events: `on_copy` pushes `%{"id" => id}` when it is an event name.
  """
  attr :id, :string, required: true, doc: "Needed by the hook."
  attr :value, :string, default: nil, doc: "The text to copy."

  attr :from, :string,
    default: nil,
    doc: "A selector of the field or element whose text is copied."

  attr :toast, :any, default: "Text Copied", doc: "Shown after a copy; `nil` or `\"\"` for none."
  attr :error_toast, :string, default: "Error"
  attr :on_copy, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil

  attr :copied_label, :string,
    default: nil,
    doc:
      "The text the button shows for the two seconds after a copy, in the success color (the design's \"Copiado\" state); `nil` leaves the button as it is, for you to style with `data-copied:`."

  attr :icon, :boolean,
    default: false,
    doc:
      "A copy icon before the text, which becomes a check for the two seconds after a copy (needs `copied_label` or `icon_only` to turn the button green too)."

  attr :icon_only, :boolean,
    default: false,
    doc:
      "Just the icon, a square button for a code snippet; give it an `aria-label`. After a copy it turns into the success check."

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
      |> assign(:copied_classes, @copied_classes)
      |> assign(:square, @square)

    assigns =
      assign(assigns,
        tinted: assigns.copied_label || assigns.icon_only,
        icon?: assigns.icon || assigns.icon_only
      )

    ~H"""
    <Button.button
      id={@id}
      color={@color}
      variant={@variant}
      size={@size}
      class={
        merge([
          @tinted && @copied_classes,
          @icon? && "gap-1.5",
          @icon_only && ["justify-center px-0", Map.fetch!(@square, @size)],
          @class
        ])
      }
      phx-hook="LineaUI.Clipboard"
      data-value={@value}
      data-from={@from}
      data-toast={@toast}
      data-error-toast={@error_toast}
      data-on-copy={@on_copy_js}
      {@rest}
    >
      <span :if={@icon?} class="group-data-copied/clip:hidden"><.copy_icon /></span>
      <span :if={@icon?} class="hidden group-data-copied/clip:inline"><.check_icon /></span>
      <%= cond do %>
        <% @icon_only -> %>
        <% @copied_label -> %>
          <span class="group-data-copied/clip:hidden">
            {default_label(@inner_block)}{render_slot(@inner_block)}
          </span>
          <span class="hidden group-data-copied/clip:inline" aria-live="polite">{@copied_label}</span>
        <% true -> %>
          {default_label(@inner_block)}{render_slot(@inner_block)}
      <% end %>
    </Button.button>
    """
  end

  defp copy_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class="size-4"
    >
      <rect x="9" y="9" width="11" height="11" rx="2.5" /><path d="M5 15V6.5A2.5 2.5 0 0 1 7.5 4H15" />
    </svg>
    """
  end

  defp check_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2.2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class="size-4"
    >
      <path d="m5 12.5 4.5 4.5L19 7.5" />
    </svg>
    """
  end

  defp default_label([]), do: "Copy"
  defp default_label(_inner_block), do: nil

  @doc """
  LineOne's "Advanced Usage": a text field with a copy button joined to its end. The field is a
  real input (`name`, `value`, `phx-change` work), and the button copies what it holds.
  """
  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :label, :string, default: "Copy", doc: "The button's text."

  attr :copied_label, :string,
    default: nil,
    doc: "What the button says, in the success color, for the two seconds after a copy."

  attr :icon, :boolean, default: false, doc: "A copy icon before the label."
  attr :toast, :any, default: "Text Copied", doc: "Shown after a copy; `nil` or `\"\"` for none."
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
        copied_label={@copied_label}
        icon={@icon}
        class="z-2 rounded-l-none"
      >
        {@label}
      </.clipboard>
    </div>
    """
  end
end
