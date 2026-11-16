defmodule LineaUI.Components.Timeline do
  @moduledoc """
  LineOne's timeline: events down a line, each marked by a filled, outlined or icon point.

      <.timeline class="max-w-sm">
        <.timeline_item title="Video Added" time="1 hour ago" color="primary"
          description="Mores Clarke added new video" />
        <.timeline_item title="Design Completed" time="3 hours ago" color="success" ping>
          <a href="#">File_final.fig</a>
        </.timeline_item>
      </.timeline>

      <.timeline size="lg" line_space>
        <.timeline_item title="Images Added" time="1 hour ago" color="primary" variant="icon">
          <:point><svg class="size-3">…</svg></:point>
        </.timeline_item>
      </.timeline>

  An avatar can be the point: give the timeline `size="xl"` (2rem) or `"2xl"` and the item
  `variant="avatar"`, with the avatar filling the point:

      <.timeline size="xl">
        <.timeline_item variant="avatar" title="Mores Clarke" time="1 hour ago">
          <:point><.avatar src="/mores.jpg" class="size-full" /></:point>
        </.timeline_item>
      </.timeline>

  The line is 2px and stops at the last item. `ping` stops for people who prefer reduced
  motion. An avatar point can also be a tinted disc with initials (`<.avatar initials="mc" color="info" class="size-full" />`).

  The inner block of an item comes after its description: images, links, tags, members.

  A `timeline_day` splits the events by day with a small label, the line running through it:

      <.timeline>
        <.timeline_day label="Today" />
        <.timeline_item title="Out for delivery" time="11:42" color="info" />
      </.timeline>

  The items can come from a list or a stream through `rows` and the `:item` slot, which gets
  `{dom_id, row}` and renders a `timeline_item` with that `id`:

      <.timeline id="events" rows={@streams.events}>
        <:item :let={{id, event}}>
          <.timeline_item id={id} title={event.title} time={event.ago} color={event.color} />
        </:item>
      </.timeline>

  Given a stream, the list renders with `phx-update="stream"` (and needs an `id`).

  Both are daisyUI's `timeline timeline-vertical timeline-compact`. `variant="canvas"` is a list of
  `timeline_event`s, each with a boxed icon tile, a title over a subtitle and the time at the right. It takes `rows` and the `:item` slot
  the same way:

      <.timeline variant="canvas" id="events" rows={@streams.events}>
        <:item :let={{id, event}}>
          <.timeline_event id={id} tone="pos" title={event.title} subtitle={event.by} time={event.at}>
            <:icon><.icon name="hero-check" class="size-4" /></:icon>
          </.timeline_event>
        </:item>
      </.timeline>
  """

  use LineaUI.Component

  @solid %{
    "neutral" => "bg-base-content/55",
    "primary" => "bg-primary",
    "secondary" => "bg-secondary",
    "accent" => "bg-accent",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @outline %{
    "neutral" => "border-2 border-base-content/40",
    "primary" => "border-2 border-primary",
    "secondary" => "border-2 border-secondary",
    "accent" => "border-2 border-accent",
    "info" => "border-2 border-info",
    "success" => "border-2 border-success",
    "warning" => "border-2 border-warning",
    "error" => "border-2 border-error"
  }

  @icon_disc "bg-[color-mix(in_srgb,currentColor_13%,transparent)] shadow-[inset_0_0_0_1px_color-mix(in_srgb,currentColor_38%,transparent)]"

  @icon %{
    "neutral" => "#{@icon_disc} text-base-content/65",
    "primary" => "#{@icon_disc} text-primary",
    "secondary" => "#{@icon_disc} text-secondary",
    "accent" => "#{@icon_disc} text-accent",
    "info" => "#{@icon_disc} text-info",
    "success" => "#{@icon_disc} text-success",
    "warning" => "#{@icon_disc} text-warning",
    "error" => "#{@icon_disc} text-error"
  }

  @avatar Map.new(~w(neutral primary secondary accent info success warning error), &{&1, nil})

  @variants %{"solid" => @solid, "outline" => @outline, "icon" => @icon, "avatar" => @avatar}

  @pings %{
    "neutral" => "bg-base-content/55",
    "primary" => "bg-primary",
    "secondary" => "bg-secondary",
    "accent" => "bg-accent",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @sizes %{
    "md" => "[--tl-point:0.75rem]",
    "lg" => "[--tl-point:1.5rem]",
    "xl" => "[--tl-point:2rem]",
    "2xl" => "[--tl-point:2.5rem]"
  }

  # daisyUI's vertical, compact timeline: the points on the line, the content at their right, the line's
  # ends trimmed at the first and the last item
  @timeline "timeline timeline-vertical timeline-compact timeline-snap-icon [&>li>hr]:bg-base-300 [&>li:first-child>hr:first-child]:invisible [&>li:last-child>hr:last-child]:invisible"

  @doc """
  Renders the line the `timeline_item`s hang on, either from its inner block or from `rows`.

      <.timeline line_space class="max-w-sm">
        <.timeline_item title="Video Added" time="1 hour ago" color="primary" />
      </.timeline>

      <.timeline id="events" rows={@streams.events}>
        <:item :let={{id, event}}>
          <.timeline_item id={id} title={event.title} time={event.ago} />
        </:item>
      </.timeline>
  """
  attr(:line_space, :boolean,
    default: false,
    doc: "Leaves a gap between the points and the line."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(md lg xl 2xl),
    doc:
      "The width of the points (and where the line runs): `md` 12px, `lg` 1.5rem for an icon, `xl` 2rem and `2xl` 2.5rem for avatar points."
  )

  attr(:density, :string,
    default: "default",
    values: ~w(default compact),
    doc:
      "`compact` is the tighter LineOne look of the canvas: 22px between items, 14px between the point and the text, a 13px semibold title, a 13px muted description and a 4px gap between a point and the line (as with `line_space`)."
  )

  attr(:variant, :string,
    default: "line",
    values: ~w(line canvas),
    doc:
      "`line` is the vertical line of points; `canvas` the list of `timeline_event`s with icon tiles."
  )

  attr(:id, :string, default: nil, doc: "Required with a stream.")
  attr(:rows, :any, default: nil, doc: "A list or a stream of rows rendered by the `:item` slot.")

  attr(:row_id, :any,
    default: nil,
    doc: "A function from a row to its DOM id, for a plain list (a stream brings its own ids)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)
  slot(:item, doc: "Renders one row; gets `{dom_id, row}`.")

  def timeline(assigns) do
    assigns =
      assigns
      |> assign(:size_class, @sizes[assigns.size])
      |> assign(:stream, stream_update(assigns.rows))
      |> assign(:timeline, @timeline)
      |> assign(:entries, entries(assigns.rows, assigns.row_id))

    render_timeline(assigns)
  end

  defp render_timeline(%{variant: "canvas"} = assigns) do
    ~H"""
    <ul
      id={@id}
      class={merge([@timeline, "[--tl-gap:1rem]", @class])}
      phx-update={@stream}
      {@rest}
    >
      {render_slot(@inner_block)}
      <%= for entry <- @entries do %>
        {render_slot(@item, entry)}
      <% end %>
    </ul>
    """
  end

  defp render_timeline(assigns) do
    ~H"""
    <ol
      id={@id}
      class={
        merge([
          @timeline,
          (@line_space || @density == "compact") && "line-space [&_.timeline-middle]:my-1",
          (@density == "compact" && "is-compact [--tl-gap:22px]") || "[--tl-gap:2rem]",
          @size_class,
          @class
        ])
      }
      phx-update={@stream}
      {@rest}
    >
      {render_slot(@inner_block)}
      <%= for entry <- @entries do %>
        {render_slot(@item, entry)}
      <% end %>
    </ol>
    """
  end

  defp stream_update(%Phoenix.LiveView.LiveStream{}), do: "stream"
  defp stream_update(_rows), do: nil

  defp entries(nil, _row_id), do: []
  defp entries(%Phoenix.LiveView.LiveStream{} = stream, _row_id), do: stream

  defp entries(rows, row_id) when is_function(row_id, 1),
    do: Enum.map(rows, &{row_id.(&1), &1})

  defp entries(rows, nil), do: Enum.map(rows, &{nil, &1})

  @doc """
  Renders one event: its point, title, time and description, then the inner block.

      <.timeline_item title="Images Added" time="1 hour ago" color="primary" variant="icon"
        description="Mores Clarke added new image gallery">
        <:point><svg class="size-3">…</svg></:point>
        <div class="mt-4 grid grid-cols-3 gap-3">…</div>
      </.timeline_item>
  """
  attr(:title, :string, default: nil, doc: "The bold first line.")
  attr(:time, :string, default: nil, doc: "Shown at the right of the title.")
  attr(:description, :string, default: nil, doc: "The line under the title.")

  attr(:color, :string,
    default: "neutral",
    doc: "The color of the point.",
    values: ~w(neutral primary secondary accent info success warning error)
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid outline icon avatar),
    doc:
      "`icon` is a disc tinted 13% with the color and ringed by 1px of it, holding the `:point` slot (an icon of 1rem on a `xl` timeline is the LineOne size); `avatar` draws no disc, so the `:point` slot can hold an avatar."
  )

  attr(:point_class, :any, default: nil, doc: "Merged into the point (`size-8` ...).")

  attr(:ping, :boolean, default: false, doc: "A pulsing ring around the point.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:point, doc: "What the point shows, usually an icon.")

  slot(:details,
    doc: "The description with markup (`<b>3 items</b>`); it replaces the `description` text."
  )

  slot(:inner_block)

  def timeline_item(assigns) do
    assigns =
      assigns
      |> assign(:point_extra, assigns.point_class)
      |> assign(:point_class, @variants[assigns.variant][assigns.color])
      |> assign(:ping_class, @pings[assigns.color])

    ~H"""
    <li class={merge(["timeline-item", @class])} {@rest}>
      <hr />
      <div class="timeline-middle">
        <div class={
          merge([
            "timeline-item-point relative grid size-(--tl-point) place-items-center rounded-full",
            @point_class,
            @point_extra
          ])
        }>
          <span
            :if={@ping}
            class={[
              "absolute inset-0 inline-flex motion-safe:animate-ping rounded-full opacity-80",
              @ping_class
            ]}
          ></span>
          {render_slot(@point)}
        </div>
      </div>
      <div class="timeline-end timeline-item-content mb-(--tl-gap) ms-4 w-full sm:ms-8">
        <div
          :if={@title || @time}
          class="flex flex-col justify-between pb-2 sm:flex-row sm:pb-0"
        >
          <p class="timeline-item-title pb-2 font-medium leading-none text-base-content/75 sm:pb-0">
            {@title}
          </p>
          <span :if={@time} class="timeline-item-time text-xs text-base-content/65">
            {@time}
          </span>
        </div>
        <p :if={@details != [] || @description} class="timeline-item-description py-1">
          {if @details == [], do: @description, else: render_slot(@details)}
        </p>
        {render_slot(@inner_block)}
      </div>
      <hr />
    </li>
    """
  end

  @tones %{
    "default" => "border-base-300 bg-base-200 text-base-content/70",
    "acc" => "border-primary/25 bg-primary/10 text-primary",
    "pos" => "border-success/25 bg-success/10 text-success",
    "neg" => "border-error/25 bg-error/10 text-error",
    "warn" => "border-warning/25 bg-warning/10 text-warning",
    "info" => "border-info/25 bg-info/10 text-info"
  }

  @doc """
  Renders one event of a `variant="canvas"` timeline: an icon tile, a title over a subtitle and
  the time at the right.

      <.timeline_event tone="warn" title="Fatura vencida" subtitle="Cliente Acme" time="10:42">
        <:icon><.icon name="hero-exclamation-triangle" class="size-4" /></:icon>
      </.timeline_event>
  """
  attr(:title, :string, default: nil, doc: "The first line.")
  attr(:subtitle, :string, default: nil, doc: "The faint line under the title.")
  attr(:time, :string, default: nil, doc: "Mono and faint, at the right.")

  attr(:tone, :string,
    default: "default",
    values: ~w(default acc pos neg warn info),
    doc: "Tints the icon tile with the primary, success, error, warning or info color."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:icon, doc: "The icon inside the tile.")
  slot(:inner_block, doc: "Free content after the title and the subtitle.")

  def timeline_event(assigns) do
    assigns = assign(assigns, :tone_class, @tones[assigns.tone])

    ~H"""
    <li class={merge(["timeline-event", @class])} {@rest}>
      <hr />
      <span class={[
        "timeline-middle grid size-8 place-items-center rounded-field border [&_svg]:size-4",
        @tone_class
      ]}>
        {render_slot(@icon)}
      </span>
      <div class="timeline-end mb-(--tl-gap) ms-3 flex w-full items-start gap-3 text-sm">
        <div class="grow">
          <div :if={@title} class="font-medium text-base-content">{@title}</div>
          <div :if={@subtitle} class="text-base-content/50">{@subtitle}</div>
          {render_slot(@inner_block)}
        </div>
        <span :if={@time} class="font-mono text-xs text-base-content/50">{@time}</span>
      </div>
      <hr />
    </li>
    """
  end

  @doc """
  Renders a label that splits the events by day, with the line running through it.

      <.timeline_day label="Yesterday" />
  """
  attr(:label, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def timeline_day(assigns) do
    ~H"""
    <li class={merge(["timeline-item timeline-day", @class])} {@rest}>
      <hr />
      <div class="timeline-middle size-(--tl-point)"></div>
      <div class="timeline-end timeline-item-content mb-3 ms-4 sm:ms-8">
        <span class="badge badge-sm border-0 bg-base-200 text-[11px] font-semibold tracking-wide text-base-content/65 uppercase">
          {@label}
        </span>
      </div>
      <hr />
    </li>
    """
  end
end
