defmodule LineaUI.Components.Clipboard do
  @moduledoc """
  LineOne's copy to clipboard: a button that copies a text, and a field with a copy button
  joined to it.

      <.clipboard value="mix phx.new demo">Copy</.clipboard>
      <.clipboard from="#invite-link" size="xs">Copy</.clipboard>
      <.clipboard_input id="share" value={@url} />

  `from` is a selector: a field gives its value, any other element its text. After a copy the
  toaster shows `toast` (by default "Text Copied", or "Texto copiado" with `locale="pt_BR"`, in the
  success color, as LineOne does), the button keeps `data-copied` for two seconds (style it with
  `data-copied:`) and `on_copy` runs; a copy that fails shows `error_toast`. With `copied_label` the
  button says it ("Copiado") for those two seconds:

      <.clipboard value="mix phx.new demo" copied_label="Copied">Copy</.clipboard>
      <.clipboard value={@pix} locale="pt_BR" variant="soft" icon copied_label="Copiado">Copiar Pix</.clipboard>

  `icon` puts a copy icon before the text (a check while copied) and `icon_only` makes the round
  canvas icon button (`sg-ib`) of it, for a value already on screen:

      <.clipboard value="mix phx.new demo" icon copied_label="Copied">Copy</.clipboard>
      <.clipboard from="#cmd" icon_only variant="flat" size="sm" aria-label="Copy command" />

  `copied` renders the button already in its copied state (until the next copy ends), to show it.

  With `on_copy` as an event name the LiveView (or `target`) gets
  `handle_event(name, %{"id" => id}, socket)`.
  """

  use LineaUI.Component

  alias LineaUI.Components.Button
  alias LineaUI.Components.Overlay

  @texts %{
    "en" => %{toast: "Text Copied", error: "Error", label: "Copy"},
    "pt_BR" => %{toast: "Texto copiado", error: "Erro ao copiar", label: "Copiar"}
  }

  @doc """
  A button that copies `value`, or what `from` points at.

  Events: `on_copy` pushes `%{"id" => id}` when it is an event name.
  """
  attr :id, :string, required: true, doc: "Needed by the hook."
  attr :value, :string, default: nil, doc: "The text to copy."

  attr :from, :string,
    default: nil,
    doc: "A selector of the field or element whose text is copied."

  attr :locale, :string,
    default: "en",
    values: ~w(en pt_BR),
    doc: "The language of the default `toast`, `error_toast` and label."

  attr :toast, :any,
    default: :default,
    doc:
      "Shown after a copy; `nil` or `\"\"` for none. By default the `locale`'s \"Text Copied\" / \"Texto copiado\"."

  attr :error_toast, :string,
    default: nil,
    doc: "Shown when the copy fails; by default the `locale`'s \"Error\" / \"Erro ao copiar\"."

  attr :copied, :boolean,
    default: false,
    doc: "Renders the button in its copied state (`data-copied`), as after a copy."

  attr :on_copy, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil

  attr :copied_label, :string,
    default: nil,
    doc:
      "The text the button shows for the two seconds after a copy (the canvas's \"Copiado\" state, with the check when `icon`); `nil` leaves the button as it is, for you to style with `data-copied:`."

  attr :icon, :boolean,
    default: false,
    doc: "A copy icon before the text, which becomes a check for the two seconds after a copy."

  attr :icon_only, :boolean,
    default: false,
    doc:
      "Just the icon, the round canvas icon button (`sg-ib`; `size` `xs`/`sm` is the small one, `flat` the borderless one); give it an `aria-label`. After a copy it shows the check."

  attr :color, :string,
    default: "primary",
    values: ~w(neutral primary secondary info success warning error)

  attr :variant, :string, default: "solid", values: ~w(solid glow outline soft bordered flat)
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def clipboard(assigns) do
    text = Map.fetch!(@texts, assigns.locale)

    assigns =
      assigns
      |> assign(:on_copy_js, Overlay.callback(assigns.on_copy, assigns.id, assigns.target))
      |> assign(:icon?, assigns.icon || assigns.icon_only)
      |> assign(:toast, if(assigns.toast == :default, do: text.toast, else: assigns.toast))
      |> assign(:error_toast, assigns.error_toast || text.error)
      |> assign(:default_label, text.label)

    ~H"""
    <Button.button
      id={@id}
      color={@color}
      variant={@variant}
      size={@size}
      icon={@icon_only}
      class={merge(["group/clip", @class])}
      phx-hook="LineaUI.Clipboard"
      data-value={@value}
      data-from={@from}
      data-toast={@toast}
      data-error-toast={@error_toast}
      data-on-copy={@on_copy_js}
      data-copied={@copied}
      {@rest}
    >
      <span :if={@icon?} class="group-data-copied/clip:hidden"><.copy_icon /></span>
      <span :if={@icon?} class="hidden group-data-copied/clip:inline"><.check_icon /></span>
      <%= cond do %>
        <% @icon_only -> %>
        <% @copied_label -> %>
          <span class="group-data-copied/clip:hidden">
            {default_label(@inner_block, @default_label)}{render_slot(@inner_block)}
          </span>
          <span class="hidden group-data-copied/clip:inline" aria-live="polite">{@copied_label}</span>
        <% true -> %>
          {default_label(@inner_block, @default_label)}{render_slot(@inner_block)}
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

  defp default_label([], label), do: label
  defp default_label(_inner_block, _label), do: nil

  @doc """
  LineOne's "Advanced Usage": a text field with a copy button joined to its end. The field is a
  real input (`name`, `value`, `phx-change` work), and the button copies what it holds.
  """
  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :placeholder, :string, default: nil

  attr :label, :string,
    default: nil,
    doc: "The button's text; by default the `locale`'s \"Copy\" / \"Copiar\"."

  attr :copied_label, :string,
    default: nil,
    doc: "What the button says, in the success color, for the two seconds after a copy."

  attr :icon, :boolean, default: false, doc: "A copy icon before the label."

  attr :locale, :string,
    default: "en",
    values: ~w(en pt_BR),
    doc: "The language of the default `label`, `toast` and `error_toast`."

  attr :toast, :any,
    default: :default,
    doc: "Shown after a copy; `nil` or `\"\"` for none. By default the `locale`'s text."

  attr :error_toast, :string, default: nil
  attr :on_copy, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Merged into the wrapper."
  attr :rest, :global, include: ~w(readonly disabled phx-debounce autocomplete form)

  def clipboard_input(assigns) do
    assigns =
      assign(assigns, :label, assigns.label || Map.fetch!(@texts, assigns.locale).label)

    ~H"""
    <div class={merge(["flex -space-x-px", @class])}>
      <input
        id={@id}
        type="text"
        name={@name}
        value={@value}
        placeholder={@placeholder}
        class="form-input w-full rounded-l-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-500 hover:z-10 hover:border-slate-400 focus:z-10 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"
        {@rest}
      />
      <.clipboard
        id={"#{@id}-copy"}
        from={"##{@id}"}
        locale={@locale}
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
