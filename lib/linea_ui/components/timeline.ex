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
  """

  use LineaUI.Component

  @solid %{
    "neutral" => "bg-slate-300 dark:bg-navy-400",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary dark:bg-secondary-light",
    "accent" => "bg-accent dark:bg-accent",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @outline %{
    "neutral" => "border-2 border-slate-300 dark:border-navy-400",
    "primary" => "border-2 border-primary dark:border-accent",
    "secondary" => "border-2 border-secondary dark:border-secondary-light",
    "accent" => "border-2 border-accent dark:border-accent",
    "info" => "border-2 border-info",
    "success" => "border-2 border-success",
    "warning" => "border-2 border-warning",
    "error" => "border-2 border-error"
  }

  @icon_disc "bg-[color-mix(in_srgb,currentColor_13%,transparent)] shadow-[inset_0_0_0_1px_color-mix(in_srgb,currentColor_38%,transparent)]"

  @icon %{
    "neutral" => "#{@icon_disc} text-slate-400 dark:text-navy-300",
    "primary" => "#{@icon_disc} text-primary dark:text-accent",
    "secondary" => "#{@icon_disc} text-secondary dark:text-secondary-light",
    "accent" => "#{@icon_disc} text-accent",
    "info" => "#{@icon_disc} text-info",
    "success" => "#{@icon_disc} text-success",
    "warning" => "#{@icon_disc} text-warning",
    "error" => "#{@icon_disc} text-error"
  }

  @avatar Map.new(~w(neutral primary secondary accent info success warning error), &{&1, nil})

  @variants %{"solid" => @solid, "outline" => @outline, "icon" => @icon, "avatar" => @avatar}

  @pings %{
    "neutral" => "bg-slate-300 dark:bg-navy-400",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary dark:bg-secondary-light",
    "accent" => "bg-accent dark:bg-accent",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @sizes %{
    "md" => nil,
    "lg" => "[--size:1.5rem]",
    "xl" => "[--size:2rem]",
    "2xl" => "[--size:2.5rem]"
  }

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
      |> assign(:entries, entries(assigns.rows, assigns.row_id))

    ~H"""
    <ol
      id={@id}
      class={merge(["timeline", @line_space && "line-space", @size_class, @class])}
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
  slot(:inner_block)

  def timeline_item(assigns) do
    assigns =
      assigns
      |> assign(:point_extra, assigns.point_class)
      |> assign(:point_class, @variants[assigns.variant][assigns.color])
      |> assign(:ping_class, @pings[assigns.color])

    ~H"""
    <li class={merge(["timeline-item", @class])} {@rest}>
      <div class={merge(["timeline-item-point rounded-full", @point_class, @point_extra])}>
        <span
          :if={@ping}
          class={[
            "inline-flex h-full w-full motion-safe:animate-ping rounded-full opacity-80",
            @ping_class
          ]}
        ></span>
        {render_slot(@point)}
      </div>
      <div class="timeline-item-content flex-1 pl-4 sm:pl-8">
        <div
          :if={@title || @time}
          class="flex flex-col justify-between pb-2 sm:flex-row sm:pb-0"
        >
          <p class="pb-2 font-medium leading-none text-slate-600 dark:text-navy-100 sm:pb-0">
            {@title}
          </p>
          <span :if={@time} class="text-xs text-slate-400 dark:text-navy-300">{@time}</span>
        </div>
        <p :if={@description} class="py-1">{@description}</p>
        {render_slot(@inner_block)}
      </div>
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
    <li class={merge(["timeline-item timeline-day pb-3", @class])} {@rest}>
      <div class="timeline-item-point"></div>
      <div class="timeline-item-content flex-1 pl-4 sm:pl-8">
        <span class="inline-flex h-5.5 items-center rounded-full bg-slate-150 px-2.5 text-[11px] font-semibold uppercase tracking-wide text-slate-500 dark:bg-navy-500 dark:text-navy-200">
          {@label}
        </span>
      </div>
    </li>
    """
  end
end
