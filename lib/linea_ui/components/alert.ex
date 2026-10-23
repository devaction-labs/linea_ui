defmodule LineaUI.Components.Alert do
  @moduledoc """
  LineOne's alerts: filled, outlined, soft and bordered, with an icon, an accent bar or a close
  button.

      <.alert>This is simple alert</.alert>
      <.alert color="primary" variant="soft" shape="pill">Saved</.alert>
      <.alert color="secondary" variant="soft" accent="left">With a bar</.alert>
      <.alert color="info" variant="outline">
        <:icon boxed><svg>…</svg></:icon>
        This is simple alert
      </.alert>
      <.alert id="notice" color="info" variant="outline" dismissible>Closable</.alert>

  `dismiss_alert/1` fades out and hides the alert around the element that runs it, for close
  buttons placed by hand:

      <.button phx-click={dismiss_alert()}>Remind me later</.button>
  """

  use LineaUI.Component

  @base "alert flex"

  @variants %{
    "solid" => %{
      "neutral" => "bg-slate-200 text-slate-600 dark:bg-navy-500 dark:text-navy-100",
      "primary" => "bg-primary text-white dark:bg-accent",
      "secondary" => "bg-secondary text-white",
      "info" => "bg-info text-white",
      "success" => "bg-success text-white",
      "warning" => "bg-warning text-white",
      "error" => "bg-error text-white",
      "dark" => "bg-navy-900 text-slate-200 dark:text-navy-100"
    },
    "outline" => %{
      "neutral" =>
        "border border-slate-300 text-slate-800 dark:border-navy-450 dark:text-navy-50",
      "primary" => "border border-primary text-primary dark:border-accent dark:text-accent-light",
      "secondary" =>
        "border border-secondary text-secondary dark:border-secondary dark:text-secondary-light",
      "info" => "border border-info text-info",
      "success" => "border border-success text-success",
      "warning" => "border border-warning text-warning",
      "error" => "border border-error text-error",
      "dark" => "border border-navy-900 text-navy-900 dark:border-navy-50 dark:text-navy-50"
    },
    "soft" => %{
      "neutral" => "bg-slate-150/60 text-slate-700 dark:bg-navy-500/40 dark:text-navy-100",
      "primary" => "bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light",
      "secondary" =>
        "bg-secondary/10 text-secondary dark:bg-secondary-light/15 dark:text-secondary-light",
      "info" => "bg-info/10 text-info dark:bg-info/15",
      "success" => "bg-success/10 text-success dark:bg-success/15",
      "warning" => "bg-warning/10 text-warning dark:bg-warning/15",
      "error" => "bg-error/10 text-error dark:bg-error/15",
      "dark" => "bg-navy-900/10 text-navy-900 dark:bg-navy-50/15 dark:text-navy-50"
    },
    "bordered" => %{
      "neutral" =>
        "border border-slate-300 bg-slate-150/60 text-slate-700 dark:border-navy-450 dark:bg-navy-500/40 dark:text-navy-100",
      "primary" =>
        "border border-primary/30 bg-primary/10 text-primary dark:border-accent-light/30 dark:bg-accent-light/15 dark:text-accent-light",
      "secondary" =>
        "border border-secondary/30 bg-secondary/10 text-secondary dark:border-secondary-light/30 dark:bg-secondary-light/15 dark:text-secondary-light",
      "info" => "border border-info/30 bg-info/10 text-info dark:bg-info/15",
      "success" => "border border-success/30 bg-success/10 text-success dark:bg-success/15",
      "warning" => "border border-warning/30 bg-warning/10 text-warning dark:bg-warning/15",
      "error" => "border border-error/30 bg-error/10 text-error dark:bg-error/15",
      "dark" =>
        "border border-navy-900/30 bg-navy-900/10 text-navy-900 dark:border-navy-50/30 dark:bg-navy-50/15 dark:text-navy-50"
    }
  }

  @shapes %{"rounded" => "rounded-lg", "pill" => "rounded-full"}

  @bars %{
    "neutral" => "w-1.5 bg-slate-400 dark:bg-navy-300",
    "primary" => "w-1.5 bg-primary dark:bg-accent",
    "secondary" => "w-1.5 bg-secondary",
    "info" => "w-1.5 bg-info",
    "success" => "w-1.5 bg-success",
    "warning" => "w-1.5 bg-warning",
    "error" => "w-1.5 bg-error",
    "dark" => "w-1.5 bg-navy-900"
  }

  @icon_boxes %{
    "neutral" => "bg-slate-300 p-3 text-slate-800 dark:bg-navy-450 dark:text-navy-50",
    "primary" => "bg-primary p-3 text-white dark:bg-accent",
    "secondary" => "bg-secondary p-3 text-white",
    "info" => "bg-info p-3 text-white",
    "success" => "bg-success p-3 text-white",
    "warning" => "bg-warning p-3 text-white",
    "error" => "bg-error p-3 text-white",
    "dark" => "bg-navy-900 p-3 text-white"
  }

  @close_buttons %{
    "neutral" =>
      "text-slate-700 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:text-navy-100 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25",
    "primary" =>
      "text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25",
    "secondary" =>
      "text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25",
    "info" => "text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25",
    "success" => "text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25",
    "warning" => "text-warning hover:bg-warning/20 focus:bg-warning/20 active:bg-warning/25",
    "error" => "text-error hover:bg-error/20 focus:bg-error/20 active:bg-error/25",
    "white" => "text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25"
  }

  @doc """
  Renders an alert.

  With `accent` or a boxed `:icon` the alert is split into parts and its padding moves to the
  content; otherwise the content sits in the padded alert itself, after an inline icon.
  """
  attr(:id, :string, default: nil)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error dark)
  )

  attr(:variant, :string, default: "solid", values: ~w(solid outline soft bordered))
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

  attr(:open, :boolean,
    default: true,
    doc: "`false` renders the alert hidden; the close button hides it in the browser."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:icon, doc: "An icon before the content.") do
    attr(:boxed, :boolean, doc: "Draws the icon on a filled block at the edge of the alert.")
  end

  slot(:action, doc: "Controls after the content, such as a menu or a button.")
  slot(:inner_block, required: true)

  def alert(assigns) do
    assigns
    |> assign(:layout, layout(assigns))
    |> assign(:boxed, boxed?(assigns.icon))
    |> assign(:base_classes, [
      @base,
      @variants[assigns.variant][assigns.color],
      @shapes[assigns.shape]
    ])
    |> render_alert()
  end

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
          @icon != [] && "space-x-2",
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
  defp split_content(_accent, false, _icon), do: "flex flex-1 items-center space-x-3 p-4"

  defp bar(color), do: @bars[color]
  defp icon_box(color), do: @icon_boxes[color]

  defp close_color("dark", "solid"), do: "white"
  defp close_color("neutral", _variant), do: "neutral"
  defp close_color(_color, "solid"), do: "white"
  defp close_color(color, _variant), do: color

  attr(:color, :string, required: true)
  attr(:on_dismiss, JS, required: true)

  defp close_button(assigns) do
    ~H"""
    <button
      type="button"
      aria-label="Close"
      phx-click={dismiss_alert(@on_dismiss)}
      class={["btn size-7 shrink-0 rounded-full p-0 font-medium", close_classes(@color)]}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="size-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M6 18L18 6M6 6l12 12"
        />
      </svg>
    </button>
    """
  end

  defp dismiss_js(nil, _target, _id), do: %JS{}
  defp dismiss_js(%JS{} = js, _target, _id), do: js
  defp dismiss_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp dismiss_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})

  defp close_classes(color), do: @close_buttons[color]

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
