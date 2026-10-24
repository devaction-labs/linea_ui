defmodule LineaUI.Components.Tooltip do
  @moduledoc """
  LineOne's tooltip (its tippy.js look and options): a hint around a trigger, in every theme
  color, on twelve placements, after a delay, on hover, click or focus, following the cursor,
  or holding HTML.

      <.tooltip id="save-tip" text="Save the draft">
        <.button>Save</.button>
      </.tooltip>

      <.tooltip id="top-start" text="Top Start" color="success" placement="top-start">
        <.button variant="outline" color="primary">Top Start</.button>
      </.tooltip>

      <.tooltip id="profile" trigger="click">
        <.button>Content</.button>
        <:content>
          <div class="flex space-x-3 p-3">…</div>
        </:content>
      </.tooltip>

  A tooltip is an overlay: `LineaUI.open/close/toggle` show and hide it by `id`, and `open`
  drives it from the server (when the assign changes, the server wins).

  The hint is shown in the browser's top layer (`popover="manual"`), so a table's scroll area, a
  drawer's body or an ancestor's `z-index` / `transform` neither clip nor cover it; it follows
  scrolling and hides when its trigger scrolls out of sight.
  """

  use LineaUI.Component

  @themes %{
    "neutral" => nil,
    "light" => "light",
    "primary" => "primary",
    "secondary" => "secondary",
    "info" => "info",
    "success" => "success",
    "warning" => "warning",
    "error" => "error"
  }

  @placements ~w(top top-start top-end right right-start right-end bottom bottom-start bottom-end left left-start left-end)

  @doc """
  Renders a trigger and its tooltip.

  `on_open` and `on_close` take an event name or a `JS` command; an event's payload is
  `%{"id" => id}` and it goes to `target` when given.

      <.tooltip id="delete-tip" text="Delete forever" color="error" placement="bottom-end" delay={300}>
        <.button color="error" icon aria-label="Delete">×</.button>
      </.tooltip>

  From the server: `LineaUI.open(socket, "delete-tip")`, or bind `open={@show_tip}`.
  """
  attr(:id, :string, required: true)
  attr(:text, :string, default: nil, doc: "The hint, when there is no `:content`.")

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral light primary secondary info success warning error)
  )

  attr(:placement, :string, default: "top", values: @placements)

  attr(:trigger, :string,
    default: "hover",
    values: ~w(hover click focus manual),
    doc: "`hover` also shows the hint when the trigger gets the keyboard focus."
  )

  attr(:delay, :integer, default: 0, doc: "Milliseconds before the hint shows or hides.")
  attr(:duration, :integer, default: 300, doc: "Milliseconds the animation lasts.")

  attr(:follow_cursor, :string,
    default: nil,
    values: [nil, "both", "horizontal", "vertical", "initial"],
    doc: "`initial` places the hint where the pointer was when it showed."
  )

  attr(:arrow, :boolean, default: true)

  attr(:interactive, :boolean,
    default: nil,
    doc: "Whether the pointer can move onto the hint; on by default with `:content`."
  )

  attr(:open, :boolean, default: false)
  attr(:on_open, :any, default: nil)
  attr(:on_close, :any, default: nil)
  attr(:target, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:tip_class, :any, default: nil, doc: "Classes for the hint's box.")
  attr(:rest, :global)
  slot(:inner_block, required: true)
  slot(:content, doc: "HTML content: drawn without padding, LineOne's `content` theme.")

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign(:theme, theme(assigns))
      |> assign(:interactive?, interactive?(assigns))

    ~H"""
    <div
      id={@id}
      class={merge(["inline-flex", @class])}
      phx-hook="LineaUI.Tooltip"
      data-placement={@placement}
      data-trigger={@trigger}
      data-delay={@delay}
      data-duration={@duration}
      data-follow-cursor={@follow_cursor}
      data-interactive={bool(@interactive?)}
      data-open={bool(@open)}
      data-on-open={event_js(@on_open, @target, @id)}
      data-on-close={event_js(@on_close, @target, @id)}
      {@rest}
    >
      {render_slot(@inner_block)}
      <div
        id={"#{@id}-tip"}
        role="tooltip"
        data-tippy-root
        popover="manual"
        hidden
        class="linea-tip"
        phx-mounted={JS.ignore_attributes(["hidden", "style"])}
      >
        <div
          class={merge(["tippy-box", @tip_class])}
          data-state="hidden"
          data-animation="shift-away"
          data-placement={@placement}
          data-theme={@theme}
          tabindex="-1"
          phx-mounted={JS.ignore_attributes(["data-state", "data-placement", "style"])}
        >
          <div class="tippy-content">{@text}{render_slot(@content)}</div>
          <div
            :if={@arrow}
            class="tippy-svg-arrow"
            phx-mounted={JS.ignore_attributes(["style"])}
          >
            <svg width="16" height="6" xmlns="http://www.w3.org/2000/svg">
              <path d="M0 6s1.796-.013 4.67-3.615C5.851.9 6.93.006 8 0c1.07-.006 2.148.887 3.343 2.385C14.233 6.005 16 6 16 6H0z" />
            </svg>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp theme(%{content: [_ | _], color: color}),
    do: Enum.join(Enum.reject(["content", @themes[color]], &is_nil/1), " ")

  defp theme(%{color: color}), do: @themes[color]

  defp interactive?(%{interactive: interactive}) when is_boolean(interactive), do: interactive
  defp interactive?(%{content: content}), do: content != []

  defp event_js(nil, _target, _id), do: %JS{}
  defp event_js(%JS{} = js, _target, _id), do: js
  defp event_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp event_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})
end
