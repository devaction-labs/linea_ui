defmodule LineaUI.Components.Alert do
  @moduledoc """
  daisyUI's alert (`alert`, `alert-soft`, `alert-outline`, `alert-{color}`): filled, outlined, soft and
  bordered, with an icon, an accent bar or a close button.

      <.alert>This is simple alert</.alert>
      <.alert color="primary" variant="soft" shape="pill">Saved</.alert>
      <.alert color="secondary" variant="soft" accent="left">With a bar</.alert>
      <.alert color="info" variant="outline">
        <:icon boxed><svg>…</svg></:icon>
        This is simple alert
      </.alert>
      <.alert id="notice" color="info" variant="outline" dismissible>Closable</.alert>

  The `canvas` variant (the default) is a soft `alert` tinted by `color` (`primary`, `warning`, `error`, `info`,
  `success`; `neutral` is daisyUI's plain one), the icon at the top left, the content growing beside it (write it
  as `<b>` and `<p>`), the `:action` buttons in a row under the text and a ghost round close button
  (`variant="solid"`, `outline`, `soft` and `bordered` give the other daisyUI styles):

      <.alert variant="canvas" color="warning">
        <:icon><.icon name="huge-alert-02" class="size-4" /></:icon>
        <b>Certificate expires in 12 days</b>
        <p>Renew it to keep issuing invoices.</p>
        <:action><.button color="mono" size="sm">Renew now</.button></:action>
      </.alert>

  `dismiss_alert/1` fades out and hides the alert around the element that runs it, for close
  buttons placed by hand:

      <.button phx-click={dismiss_alert()}>Remind me later</.button>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  # daisyUI's `alert`: its color and style (`alert-soft`, `alert-outline`); `flex` keeps the kit's own layouts
  @base "alert flex"
  @colors ~w(primary secondary info success warning error)

  @shapes %{"rounded" => nil, "pill" => "rounded-full"}

  @bars %{
    "neutral" => "w-1.5 bg-base-300",
    "primary" => "w-1.5 bg-primary",
    "secondary" => "w-1.5 bg-secondary",
    "info" => "w-1.5 bg-info",
    "success" => "w-1.5 bg-success",
    "warning" => "w-1.5 bg-warning",
    "error" => "w-1.5 bg-error",
    "dark" => "w-1.5 bg-neutral"
  }

  @icon_boxes %{
    "neutral" => "bg-base-content/15 p-3 text-base-content",
    "primary" => "bg-primary p-3 text-primary-content",
    "secondary" => "bg-secondary p-3 text-secondary-content",
    "info" => "bg-info p-3 text-info-content",
    "success" => "bg-success p-3 text-success-content",
    "warning" => "bg-warning p-3 text-warning-content",
    "error" => "bg-error p-3 text-error-content",
    "dark" => "bg-neutral p-3 text-neutral-content"
  }

  @doc """
  Renders an alert.

  With `accent` or a boxed `:icon` the alert is split into parts and its padding moves to the
  content; otherwise the content sits in the padded alert itself, after an inline icon.

      <.alert id="saved" color="success" variant="soft" dismissible on_dismiss="hide_notice">
        <:icon><svg class="size-5">…</svg></:icon>
        Changes saved.
      </.alert>

  With `on_dismiss="hide_notice"` the server gets `handle_event("hide_notice", %{"id" => "saved"}, socket)`.
  """
  attr(:id, :string, default: nil)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error dark)
  )

  attr(:variant, :string,
    default: "canvas",
    values: ~w(canvas solid outline soft bordered),
    doc:
      "`canvas` (the default) is the soft alert with the icon, body and actions laid out (see the module doc); `solid`, `outline`, `soft` and `bordered` are daisyUI's styles."
  )

  attr(:shape, :string, default: "rounded", values: ~w(rounded pill))

  attr(:accent, :string,
    default: nil,
    values: [nil, "left", "right"],
    doc: "A colored bar on one side of the alert."
  )

  attr(:dismissible, :boolean,
    default: false,
    doc: "Adds LineOne's close button, which fades the alert out."
  )

  attr(:on_dismiss, :any,
    default: nil,
    doc:
      "An event name or a `JS` command run when the close button is pressed. The event's payload is `%{\"id\" => id}`."
  )

  attr(:target, :any, default: nil, doc: "The `phx-target` of `on_dismiss`.")
  attr(:close_label, :string, default: "Close", doc: "The `aria-label` of the close button.")

  attr(:open, :boolean,
    default: true,
    doc: "`false` renders the alert hidden; the close button hides it in the browser."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:icon, doc: "An icon before the content.") do
    attr(:boxed, :boolean, doc: "Draws the icon on a filled block at the edge of the alert.")
  end

  slot(:action,
    doc:
      "Controls after the content, such as a menu or a button (under the text, in a row, in the `canvas` variant)."
  )

  slot(:inner_block, required: true)

  def alert(%{variant: "canvas"} = assigns) do
    ~H"""
    <div
      id={@id}
      role="alert"
      hidden={!@open}
      class={merge(["alert alert-soft flex items-start gap-3", tone(@color), @class])}
      {@rest}
    >
      {render_slot(@icon)}
      <div class="flex min-w-0 flex-1 flex-col gap-0.5 [&_b]:font-semibold [&_p]:opacity-80">
        {render_slot(@inner_block)}
        <div :if={@action != []} class="mt-2 flex flex-wrap gap-2">{render_slot(@action)}</div>
      </div>
      <button
        :if={@dismissible}
        type="button"
        class="btn btn-ghost btn-sm btn-circle -my-1 -mr-1"
        aria-label={@close_label}
        phx-click={dismiss_alert(dismiss_js(@on_dismiss, @target, @id))}
      >
        <.glyph name={:close} class="size-4" />
      </button>
    </div>
    """
  end

  def alert(assigns) do
    assigns
    |> assign(:layout, layout(assigns))
    |> assign(:boxed, boxed?(assigns.icon))
    |> assign(:base_classes, [
      @base,
      variant_class(assigns.variant),
      tone(assigns.color),
      @shapes[assigns.shape]
    ])
    |> render_alert()
  end

  defp tone(color) when color in @colors, do: "alert-" <> color
  defp tone("dark"), do: "border-neutral bg-neutral text-neutral-content"
  defp tone(_neutral), do: nil

  defp variant_class("outline"), do: "alert-outline"
  defp variant_class("soft"), do: "alert-soft"
  defp variant_class("bordered"), do: "alert-soft border-current/25"
  defp variant_class(_solid), do: nil

  defp boxed?([%{boxed: true} | _]), do: true
  defp boxed?(_icon), do: false

  defp layout(%{accent: accent}) when is_binary(accent), do: :split
  defp layout(%{icon: icon}), do: icon_layout(boxed?(icon))

  defp icon_layout(true), do: :split
  defp icon_layout(false), do: :padded

  defp render_alert(%{layout: :padded} = assigns) do
    ~H"""
    <div
      id={@id}
      role="alert"
      hidden={!@open}
      class={
        merge([
          @base_classes,
          "px-4 py-4 sm:px-5",
          @icon != [] && "gap-2",
          (@dismissible or @action != []) && "items-center justify-between",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@icon)}
      <div>
        {render_slot(@inner_block)}
      </div>
      {render_slot(@action)}
      <.close_button
        :if={@dismissible}
        color={close_color(@color, @variant)}
        label={@close_label}
        on_dismiss={dismiss_js(@on_dismiss, @target, @id)}
      />
    </div>
    """
  end

  defp render_alert(assigns) do
    ~H"""
    <div
      id={@id}
      role="alert"
      hidden={!@open}
      class={
        merge([
          @base_classes,
          "overflow-hidden",
          (@dismissible or @action != []) && "items-center justify-between",
          @class
        ])
      }
      {@rest}
    >
      <div class="flex flex-1">
        <div :if={@accent == "left"} class={bar(@color)}></div>
        <div :if={@boxed} class={icon_box(@color)}>{render_slot(@icon)}</div>
        <div class={split_content(@accent, @boxed, @icon)}>
          {render_slot(unboxed(@icon, @boxed))}
          <div class="flex-1">{render_slot(@inner_block)}</div>
        </div>
      </div>
      {render_slot(@action)}
      <div :if={@dismissible} class="px-2">
        <.close_button
          color={close_color(@color, @variant)}
          label={@close_label}
          on_dismiss={dismiss_js(@on_dismiss, @target, @id)}
        />
      </div>
      <div :if={@accent == "right"} class={bar(@color)}></div>
    </div>
    """
  end

  defp unboxed(icon, false), do: icon
  defp unboxed(_icon, true), do: []

  defp split_content(nil, true, _icon), do: "flex-1 px-4 py-3 sm:px-5"
  defp split_content(_accent, true, _icon), do: "flex-1 px-4 py-3 sm:px-5"
  defp split_content(_accent, false, []), do: "flex flex-1 p-4"
  defp split_content(_accent, false, _icon), do: "flex flex-1 items-center gap-3 p-4"

  defp bar(color), do: @bars[color]
  defp icon_box(color), do: @icon_boxes[color]

  defp close_color("dark", "solid"), do: "white"
  defp close_color("neutral", _variant), do: "neutral"
  defp close_color(_color, "solid"), do: "white"
  defp close_color(color, _variant), do: color

  attr(:color, :string, required: true)
  attr(:label, :string, required: true)
  attr(:on_dismiss, JS, required: true)

  defp close_button(assigns) do
    ~H"""
    <button
      type="button"
      aria-label={@label}
      phx-click={dismiss_alert(@on_dismiss)}
      class={["btn btn-ghost btn-sm btn-circle shrink-0", @color == "white" && "text-white"]}
    >
      <.glyph name={:close} class="size-4" />
    </button>
    """
  end

  defp dismiss_js(nil, _target, _id), do: %JS{}
  defp dismiss_js(%JS{} = js, _target, _id), do: js
  defp dismiss_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp dismiss_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})

  @doc """
  Fades out and hides the alert that holds the element running it, the way LineOne removes a
  dismissed alert.

      <button phx-click={dismiss_alert()}>Close</button>
  """
  @spec dismiss_alert(JS.t()) :: JS.t()
  def dismiss_alert(js \\ %JS{}) do
    JS.hide(js,
      to: {:closest, "[role=alert]"},
      time: 300,
      transition: {"transition-opacity duration-300", "opacity-100", "opacity-0"}
    )
  end
end
