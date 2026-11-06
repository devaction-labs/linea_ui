defmodule LineaUI.Components.ColorPicker do
  @moduledoc """
  A color picker that outputs hex text: a saturation and brightness area to drag, a hue slider, an
  optional opacity slider, a hex field and a row of preset swatches.

      <.color_picker field={@form[:color]} label="Stage color" />
      <.color_picker name="tag" value="#4C3FE0" presets={~w(#EB3B2F #F5A214 #18996E)} />
      <.color_picker field={@form[:overlay]} alpha locale="pt_BR" />

  The form gets `#6366F1` (upper case, `#RRGGBB`; with `alpha`, a color that is not fully opaque is
  `#RRGGBBAA`) through a hidden input named like the field. Every change fires a bubbling `input`
  event from it, so `phx-change` runs; the server re-rendering the same color changes nothing, a
  different color replaces the one in the browser. `phx-debounce` and `phx-throttle` go to the hidden input.

  The area is a slider: drag it, or use the arrow keys (Shift moves ten points). The hex field takes
  `#RGB`, `#RRGGBB` or `#RRGGBBAA` and applies it as soon as it is a color. `locale="pt_BR"` names the
  controls in Portuguese; `labels` overrides single texts.

  `variant="swatches"` is the canvas's brand palette: only the row of `presets`, the chosen one
  ringed in ink; `hex_field` adds the hex field under it (captioned `hex_label`):

      <.color_picker name="brand" value="#8A5CD6" variant="swatches"
                     presets={~w(#0D8F91 #2F5FD0 #8A5CD6)} />
      <.color_picker name="stage" value="#0D8F91" variant="swatches" hex_field swatch_size="md"
                     presets={~w(#0D8F91 #2F5FD0 #8A5CD6)} />

  The behavior lives in the `LineaUI.ColorPicker` hook, so the picker needs a stable `id`.
  """

  use LineaUI.Component

  alias LineaUI.Components.ColorPicker.Color
  alias LineaUI.Components.Form
  alias LineaUI.Components.Input
  alias LineaUI.Components.Pickers
  alias LineaUI.Components.Strings

  @presets ~w(#4C3FE0 #2763E6 #1693CC #18996E #31A35B #F5A214 #F06B0C #EB3B2F #DB428F #606A78)

  @checker "repeating-conic-gradient(#cbd5e1 0 25%, #fff 0 50%) 0 0/10px 10px"

  @doc """
  Renders the color picker.

  Events: `on_change` is pushed with `%{"id" => id, "value" => "#6366F1"}` each time the color changes,
  to `target` or to the LiveView/LiveComponent the picker is in.
  """
  attr :id, :string, doc: "Defaults to the field id, or a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :string, doc: "The color as hex text. Defaults to the field value, then `default`."
  attr :field, Phoenix.HTML.FormField, default: nil

  attr :default, :string,
    default: "#4C3FE0",
    doc: "The color shown while there is no valid value."

  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []

  attr :alpha, :boolean,
    default: false,
    doc: "Adds the opacity slider; the output has eight digits when the color is not opaque."

  attr :presets, :list,
    default: @presets,
    doc: "Swatches under the area, as hex text. `[]` hides them."

  attr :locale, :string,
    default: "en",
    values: ~w(en pt_BR),
    doc: "The language of the control names."

  attr :labels, :map,
    default: %{},
    doc:
      "Single texts: `:color_area`, `:color_area_text` (with `%{s}` and `%{v}`), `:color_hue`, `:color_alpha`, `:color_hex` and `:color_presets`."

  attr :variant, :string,
    default: "full",
    values: ~w(full swatches),
    doc: "`swatches` shows only the presets (and the hex field with `hex_field`)."

  attr :hex_field, :boolean,
    default: false,
    doc: "With `variant=\"swatches\"`: the hex field under the swatches."

  attr :hex_label, :string, default: "Hex", doc: "The caption of the hex field of `swatches`."

  attr :swatch_size, :string,
    default: nil,
    values: [nil | ~w(sm md lg)],
    doc:
      "The swatches: `sm` 26px (the full picker's default), `md` 30px, `lg` 34px (the default of `swatches`)."

  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil, doc: "Classes of the block around the picker."
  attr :class, :any, default: nil, doc: "Classes of the picker."
  attr :rest, :global

  def color_picker(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("color") end))
    |> assign_new(:value, fn -> nil end)
    |> prepare()
    |> render_picker()
  end

  defp prepare(assigns) do
    rgba = Color.parse(assigns.value) || Color.parse(assigns.default) || {0, 0, 0, 100}
    {hue, saturation, brightness, opacity} = Color.hsv(rgba)
    hex = Color.write(rgba, assigns.alpha)
    opaque = Color.write(put_elem(rgba, 3, 100), false)

    assign(assigns,
      hex: hex,
      opaque: opaque,
      hue: hue,
      saturation: saturation,
      brightness: brightness,
      opacity: if_alpha(assigns.alpha, opacity),
      text: Strings.table(assigns.locale, assigns.labels),
      presets: Enum.flat_map(assigns.presets, &List.wrap(Color.normalize(&1))),
      forwarded: Pickers.forwarded(assigns.rest),
      root_rest: Map.drop(assigns.rest, [:"phx-debounce", :"phx-throttle"]),
      state: error_state(assigns.errors),
      swatch: swatch_class(assigns.swatch_size, assigns.variant)
    )
  end

  defp if_alpha(true, opacity), do: opacity
  defp if_alpha(false, _opacity), do: 100

  defp swatch_class(nil, "swatches"), do: "lc-swatch lg"
  defp swatch_class(nil, _variant), do: "lc-swatch sm"
  defp swatch_class(size, _variant), do: "lc-swatch " <> size

  defp error_state([]), do: nil
  defp error_state(_errors), do: "error"

  defp render_picker(assigns) do
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
        id={@id <> "-picker"}
        phx-hook="LineaUI.ColorPicker"
        phx-target={@target}
        class={
          merge([
            "flex w-full flex-col",
            (@variant == "full" && "max-w-xs gap-3") || "gap-2.5",
            @class
          ])
        }
        data-value={@hex}
        data-alpha={bool(@alpha)}
        data-on-change={@on_change}
        data-area-text={@text.color_area_text}
        {@root_rest}
      >
        <div
          :if={@variant == "full"}
          data-area
          role="slider"
          tabindex={(!@disabled && "0") || nil}
          aria-label={@text.color_area}
          aria-valuemin="0"
          aria-valuemax="100"
          aria-valuenow={@saturation}
          aria-valuetext={Strings.fill(@text.color_area_text, %{s: @saturation, v: @brightness})}
          aria-disabled={@disabled && "true"}
          class={[
            "relative h-40 w-full touch-none cursor-crosshair overflow-hidden rounded-lg outline-hidden focus-visible:ring-2 focus-visible:ring-primary/60 focus-visible:ring-offset-2 dark:focus-visible:ring-accent/60 dark:ring-offset-navy-700",
            @disabled && "pointer-events-none opacity-60"
          ]}
          style={"background-color: hsl(#{@hue} 100% 50%)"}
        >
          <span class="absolute inset-0 bg-[linear-gradient(90deg,#fff,transparent)]"></span>
          <span class="absolute inset-0 bg-[linear-gradient(0deg,#000,transparent)]"></span>
          <span
            data-knob
            class="absolute size-4 -translate-x-1/2 -translate-y-1/2 rounded-full shadow-[0_0_0_2px_#fff,0_1px_4px_rgb(0_0_0/0.4)]"
            style={"left: #{@saturation}%; top: #{100 - @brightness}%; background-color: #{@opaque}"}
          ></span>
        </div>
        <input
          :if={@variant == "full"}
          type="range"
          data-hue
          min="0"
          max="359"
          value={@hue}
          disabled={@disabled}
          aria-label={@text.color_hue}
          class="linea-hue"
        />
        <input
          :if={@alpha and @variant == "full"}
          type="range"
          data-alpha-input
          min="0"
          max="100"
          value={@opacity}
          disabled={@disabled}
          aria-label={@text.color_alpha}
          class="linea-alpha"
          style={"background: linear-gradient(90deg, transparent, #{@opaque}), #{checker()}"}
        />
        <Input.input
          :if={@variant == "full"}
          type="text"
          id={@id}
          value={@hex}
          size="md"
          state={@state}
          disabled={@disabled}
          maxlength="9"
          autocomplete="off"
          spellcheck="false"
          aria-label={@text.color_hex}
          class="pl-10 font-mono text-slate-800 uppercase dark:text-navy-50"
          data-hex
        >
          <:prefix>
            <span
              data-chip
              class="size-4.5 rounded shadow-[inset_0_0_0_1px_rgb(0_0_0/0.12)]"
              style={"background-color: #{@opaque}; opacity: #{@opacity / 100}"}
            ></span>
          </:prefix>
        </Input.input>
        <div
          :if={@presets != []}
          role="group"
          aria-label={@text.color_presets}
          class="flex flex-wrap gap-2"
        >
          <button
            :for={preset <- @presets}
            type="button"
            data-preset={preset}
            aria-label={preset}
            aria-pressed={bool(preset == @hex)}
            disabled={@disabled}
            class={@swatch}
            style={"background-color: #{preset}"}
          ></button>
        </div>
        <Input.input
          :if={@variant == "swatches" and @hex_field}
          type="text"
          id={@id}
          label={@hex_label}
          value={@hex}
          state={@state}
          disabled={@disabled}
          maxlength="9"
          autocomplete="off"
          spellcheck="false"
          class="uppercase"
          data-hex
        />
        <input
          type="hidden"
          id={@id <> "-value"}
          name={@name}
          value={@hex}
          disabled={@disabled}
          phx-update="ignore"
          data-value-input
          {@forwarded}
        />
      </div>
    </Form.field>
    """
  end

  defp checker, do: @checker
end
