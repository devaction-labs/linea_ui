defmodule PreviewWeb.Pages.Timeline do
  use PreviewWeb.Page, title: "Timeline", category: :components, lineone: "components-timeline"

  import Phoenix.LiveView, only: [stream: 3, stream_insert: 4]

  @text "The timeline displays a list of events in chronological order. Check out code for detail of usage."

  @events [
    {"neutral", "User Photo Changed", "12 minute ago", "John Doe changed his avatar photo"},
    {"primary", "Video Added", "1 hour ago", "Mores Clarke added new video"},
    {"success", "Design Completed", "3 hours ago",
     "Robert Nolan completed the design of the CRM application"},
    {"warning", "ER Diagram", "a day ago", "Team completed the ER diagram app"},
    {"error", "Weekly Report", "a day ago", "The weekly report was uploaded"}
  ]

  @tags [
    {"UI/UX",
     "tag rounded-full border border-secondary/30 bg-secondary/10 text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:border-secondary-light/30 dark:bg-secondary-light/10 dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25"},
    {"CRM",
     "tag rounded-full border border-info/30 bg-info/10 text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25"},
    {"Dashboard",
     "tag rounded-full border border-success/30 bg-success/10 text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25"}
  ]

  @icons %{
    "user" =>
      "M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z",
    "image" =>
      "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z",
    "leaf" => "M5 3c9 0 14 5 14 14v4h-4C6 21 3 14 3 9c0-3 2-6 2-6zm0 0c4 6 8 10 14 14",
    "diagram" => "M4 5h6v4H4zM14 15h6v4h-6zM14 5h6v4h-6zM7 9v4h10v2M17 9v2",
    "history" => "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
  }

  def mount(socket) do
    socket
    |> assign(:next_id, 3)
    |> stream(:live_events, [
      %{id: 1, color: "primary", title: "Order placed", time: "2 minutes ago"},
      %{id: 2, color: "success", title: "Payment confirmed", time: "1 minute ago"}
    ])
  end

  def handle_event("add_event", _params, socket) do
    id = socket.assigns.next_id
    event = %{id: id, color: "info", title: "Event #{id}", time: "just now"}

    {:noreply, socket |> assign(:next_id, id + 1) |> stream_insert(:live_events, event, at: 0)}
  end

  def render(assigns) do
    assigns = assign(assigns, text: @text, events: @events, tags: @tags, icons: @icons)

    ~H"""
    <.example title="Basic Timeline" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.timeline class="max-w-sm">
            <.timeline_item
              :for={{color, title, time, text} <- @events}
              color={color}
              title={title}
              time={time}
              description={text}
            />
          </.timeline>
        </div>
      </div>
    </.example>
    <.example title="With Linespace" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.timeline line_space class="max-w-sm">
            <.timeline_item
              :for={{color, title, time, text} <- @events}
              color={color}
              title={title}
              time={time}
              description={text}
            />
          </.timeline>
        </div>
      </div>
    </.example>
    <.example title="Outlined Point" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.timeline line_space class="max-w-sm">
            <.timeline_item
              :for={{color, title, time, text} <- @events}
              variant="outline"
              color={color}
              title={title}
              time={time}
              description={text}
            />
          </.timeline>
        </div>
      </div>
    </.example>
    <.example title="Timeline With Ping" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.timeline class="max-w-sm">
            <.timeline_item
              :for={{color, title, time, text} <- @events}
              color={color}
              ping={color == "success"}
              title={title}
              time={time}
              description={text}
            />
          </.timeline>
        </div>
      </div>
    </.example>
    <.example title="Ping & Linespace" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">
          <.timeline line_space class="max-w-sm">
            <.timeline_item
              :for={{color, title, time, text} <- @events}
              color={accent(color)}
              ping={color == "success"}
              title={title}
              time={time}
              description={text}
            />
          </.timeline>
        </div>
      </div>
    </.example>
    <.example title="Advanced Timeline" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">{advanced(%{line_space: false, tags: @tags, icons: @icons})}</div>
      </div>
    </.example>
    <.example title="Advanced Timeline" class="">
      <div class="max-w-xl">
        <p>{@text}</p>
        <div class="mt-5">{advanced(%{line_space: true, tags: @tags, icons: @icons})}</div>
      </div>
    </.example>
    <.example title="Streamed Timeline" class="">
      <div class="max-w-xl">
        <p>The items come from a LiveView stream; new events are inserted at the top.</p>
        <div class="mt-5 space-y-4">
          <.button id="add-event" color="primary" size="sm" phx-click="add_event">
            Add event
          </.button>
          <.timeline id="live-events" rows={@streams.live_events} class="max-w-sm">
            <:item :let={{id, event}}>
              <.timeline_item id={id} color={event.color} title={event.title} time={event.time} />
            </:item>
          </.timeline>
        </div>
      </div>
    </.example>
    """
  end

  defp accent("primary"), do: "accent"
  defp accent(color), do: color

  defp advanced(assigns) do
    ~H"""
    <.timeline line_space={@line_space} size="lg" class="max-w-sm">
      <.timeline_item
        variant="icon"
        color="secondary"
        title="User Photo Changed"
        time="12 minute ago"
        description="John Doe changed his avatar photo"
      >
        <:point>{icon(%{d: @icons["user"]})}</:point>
        <div class="avatar mt-2 size-20">
          <img class="mask is-squircle" src="/lineone/images/avatar/avatar-19.jpg" alt="avatar" />
        </div>
      </.timeline_item>
      <.timeline_item
        variant="icon"
        color="primary"
        title="Images Added"
        time="1 hour ago"
        description="Mores Clarke added new image gallery"
      >
        <:point>{icon(%{d: @icons["image"]})}</:point>
        <div class="mt-4 grid grid-cols-3 gap-3">
          <img
            :for={n <- 1..6}
            class="rounded-lg"
            src={"/lineone/images/object/object-#{n}.jpg"}
            alt="image"
          />
        </div>
        <div class="mt-4">
          <span class="font-medium text-slate-600 dark:text-navy-100">Category:</span>
          <a
            href="#"
            class="text-xs text-primary hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
          >
            #Tag
          </a>
          <a
            href="#"
            class="text-xs text-primary hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
          >
            #Category
          </a>
        </div>
      </.timeline_item>
      <.timeline_item
        variant="icon"
        color="success"
        title="Design Completed"
        time="3 hours ago"
        description="Robert Nolan completed the design of the CRM application"
      >
        <:point>{icon(%{d: @icons["leaf"]})}</:point>
        <a
          href="#"
          class="inline-flex items-center space-x-1 pt-2 text-slate-600 transition-colors hover:text-primary dark:text-navy-100 dark:hover:text-accent"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <span>File_final.fig</span>
        </a>
        <div class="pt-2">
          <%= for {label, class} <- @tags do %>
            <a href="#" class={class}>{label}</a>
          <% end %>
        </div>
      </.timeline_item>
      <.timeline_item
        variant="icon"
        color="warning"
        title="ER Diagram"
        time="a day ago"
        description="Team completed the ER diagram app"
      >
        <:point>{icon(%{d: @icons["diagram"]})}</:point>
        <div>
          <p class="text-xs text-slate-400 dark:text-navy-300">Members:</p>
          <div class="mt-2 flex justify-between">
            <div class="flex flex-wrap -space-x-2">
              <div class="avatar size-7 hover:z-10">
                <img
                  class="rounded-full ring-2 ring-white dark:ring-navy-700"
                  src="/lineone/images/avatar/avatar-16.jpg"
                  alt="avatar"
                />
              </div>
              <div class="avatar size-7 hover:z-10">
                <div class="is-initial rounded-full bg-info text-xs-plus uppercase text-white ring-2 ring-white dark:ring-navy-700">
                  jd
                </div>
              </div>
              <div :for={n <- [20, 8, 5]} class="avatar size-7 hover:z-10">
                <img
                  class="rounded-full ring-2 ring-white dark:ring-navy-700"
                  src={"/lineone/images/avatar/avatar-#{n}.jpg"}
                  alt="avatar"
                />
              </div>
            </div>
            <.button icon size="sm" shape="pill" class="size-7 text-sm" aria-label="Add member">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-5 rotate-45"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M7 11l5-5m0 0l5 5m-5-5v12"
                />
              </svg>
            </.button>
          </div>
        </div>
      </.timeline_item>
      <.timeline_item
        variant="icon"
        color="error"
        title="Weekly Report"
        time="a day ago"
        description="The weekly report was uploaded"
      >
        <:point>{icon(%{d: @icons["history"]})}</:point>
      </.timeline_item>
    </.timeline>
    """
  end

  defp icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-3"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d={@d} />
    </svg>
    """
  end
end
