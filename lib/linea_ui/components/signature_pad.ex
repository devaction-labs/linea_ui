defmodule LineaUI.Components.SignaturePad do
  @moduledoc """
  A signature field: sign with a finger, a pen or the mouse (pointer events), or type a name that is set in
  a handwriting font. The signature leaves as SVG text.

      <.signature_pad field={@form[:signature]} label="Signature" />
      <.signature_pad name="receipt" mode="type" text="Marcos Oliveira" locale="pt_BR" />
      <.signature_pad name="sign" modes={["draw"]} height={220} />

  The form gets the SVG (`<svg xmlns=... viewBox="0 0 300 170"><path .../></svg>`, `""` while the pad is
  empty) through a hidden input named like the field. Every stroke, typed letter or Clear fires a bubbling `input`
  event from it, so `phx-change` runs. Give the field a stored SVG as `value` and the pad shows it; the server
  sending another value (or an empty one) replaces what is in the pad, re-rendering the same one changes
  nothing. Show a saved signature elsewhere as an image, never as raw markup:

      <img src={"data:image/svg+xml;base64," <> Base.encode64(@signature)} alt="Signature" />

  Drawing needs a pointer, so the `type` mode is the keyboard and screen reader way to sign; keep both
  modes unless the signature must be drawn. The pad is a white surface in both themes, because the SVG it
  exports has dark ink on a transparent background.

  The behavior lives in the `LineaUI.SignaturePad` hook, so the pad needs a stable `id`.
  """

  use LineaUI.Component

  alias LineaUI.Components.Badge
  alias LineaUI.Components.Button
  alias LineaUI.Components.Form
  alias LineaUI.Components.Input
  alias LineaUI.Components.Pickers
  alias LineaUI.Components.Segments
  alias LineaUI.Components.Strings

  @doc """
  Renders the signature pad.

  Events: `on_change` is pushed with `%{"id" => id, "value" => svg}` each time the signature changes, to `target` or
  to the LiveView/LiveComponent the pad is in.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :string, doc: "The saved signature as SVG text. Defaults to the field value."
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []

  attr :mode, :string,
    default: "draw",
    values: ~w(draw type),
    doc: "The mode the pad starts in."

  attr :modes, :list,
    default: ["draw", "type"],
    doc:
      "The modes offered, `[\"draw\"]` or `[\"type\"]` for just one (the switch is then hidden)."

  attr :text, :string, default: "", doc: "The name the `type` mode starts with."
  attr :ink, :string, default: "#0F172A", doc: "The color of the exported ink, as hex."
  attr :height, :integer, default: 170, doc: "The height of the pad in pixels."

  attr :locale, :string, default: "en", values: ~w(en pt_BR)

  attr :labels, :map,
    default: %{},
    doc:
      "Single texts: `:signature_draw`, `:signature_type`, `:signature_clear`, `:signature_area`, `:signature_hint`, `:signature_name`, `:signature_ready` and `:signature_empty`."

  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil, doc: "Classes of the block around the pad."
  attr :class, :any, default: nil, doc: "Classes of the drawing surface."
  attr :rest, :global

  def signature_pad(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("signature") end))
    |> assign_new(:value, fn -> nil end)
    |> prepare()
    |> render_pad()
  end

  defp prepare(assigns) do
    modes = Enum.filter(assigns.modes, &(&1 in ~w(draw type)))
    modes = (modes == [] && ["draw", "type"]) || modes

    assign(assigns,
      value: assigns.value || "",
      modes: modes,
      mode: (assigns.mode in modes && assigns.mode) || hd(modes),
      text: Strings.table(assigns.locale, assigns.labels),
      typed: assigns.text,
      forwarded: Pickers.forwarded(assigns.rest),
      root_rest: Map.drop(assigns.rest, [:"phx-debounce", :"phx-throttle"]),
      state: error_state(assigns.errors)
    )
  end

  defp error_state([]), do: nil
  defp error_state(_errors), do: "error"

  defp render_pad(assigns) do
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
      <div
        id={@id <> "-signature"}
        phx-hook="LineaUI.SignaturePad"
        phx-target={@target}
        class="flex w-full flex-col gap-2.5"
        data-value={@value}
        data-mode={@mode}
        data-modes={Enum.join(@modes, ",")}
        data-text={@typed}
        data-ink={@ink}
        data-disabled={bool(@disabled)}
        data-on-change={@on_change}
        {@root_rest}
      >
        <div :if={length(@modes) > 1} class="flex justify-end">
          <div role="group" aria-label={@text.signature_area} class={Segments.group()}>
            <button
              :for={{mode, label} <- [{"draw", @text.signature_draw}, {"type", @text.signature_type}]}
              :if={mode in @modes}
              type="button"
              class={Segments.item()}
              aria-pressed={bool(@mode == mode)}
              data-mode-button={mode}
              disabled={@disabled}
            >
              {label}
            </button>
          </div>
        </div>
        <div
          id={@id <> "-pad"}
          data-pad
          data-mode={@mode}
          role="img"
          aria-label={@text.signature_area}
          phx-update="ignore"
          style={"height: #{@height}px"}
          class={
            merge([
              "relative w-full touch-none overflow-hidden rounded-lg border border-slate-300 bg-white select-none data-[mode=draw]:cursor-crosshair dark:border-navy-450 dark:bg-navy-700",
              @disabled && "pointer-events-none opacity-60",
              @class
            ])
          }
        >
          <span class="pointer-events-none absolute inset-x-6 bottom-10.5 border-t border-dashed border-slate-300 dark:border-navy-450"></span>
          <span class="pointer-events-none absolute bottom-12 left-6 font-inter text-sm font-medium text-slate-400 dark:text-navy-300">×</span>
          <svg aria-hidden="true" class="pointer-events-none absolute inset-0 size-full">
            <path
              data-path
              class="dark:stroke-navy-50"
              fill="none"
              stroke={@ink}
              stroke-width="2.4"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
          <img
            data-existing
            hidden
            alt=""
            class="pointer-events-none absolute inset-0 size-full object-contain object-left-bottom dark:invert"
          />
          <span
            data-typed
            class="pointer-events-none absolute bottom-11.5 left-11 text-4xl text-slate-800 italic dark:text-navy-50 [font-family:'Brush_Script_MT','Segoe_Script','Snell_Roundhand',cursive]"
          ></span>
          <span
            data-hint
            class="pointer-events-none absolute inset-0 flex items-center justify-center text-xs-plus text-slate-400"
          >
            {@text.signature_hint}
          </span>
        </div>
        <div data-type-field hidden>
          <Input.input
            type="text"
            id={@id <> "-name"}
            value={@typed}
            size="sm"
            disabled={@disabled}
            autocomplete="off"
            placeholder={@text.signature_name}
            aria-label={@text.signature_name}
            data-type-input
          />
        </div>
        <div class="flex items-center justify-between gap-2">
          <span>
            <Badge.badge
              data-status-ready
              color="success"
              variant="soft"
              size="sm"
              class="font-inter text-tiny-plus"
              hidden
            >
              {@text.signature_ready}
            </Badge.badge>
            <Badge.badge
              data-status-empty
              color="neutral"
              variant="soft"
              size="sm"
              class="font-inter text-tiny-plus"
            >
              {@text.signature_empty}
            </Badge.badge>
          </span>
          <Button.button
            size="sm"
            variant="flat"
            data-clear
            disabled={@disabled}
          >
            {@text.signature_clear}
          </Button.button>
        </div>
        <input
          type="hidden"
          id={@id}
          name={@name}
          value={@value}
          disabled={@disabled}
          phx-update="ignore"
          data-value-input
          {@forwarded}
        />
      </div>
    </Form.field>
    """
  end
end
