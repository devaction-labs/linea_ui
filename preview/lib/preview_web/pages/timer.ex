defmodule PreviewWeb.Pages.Timer do
  use PreviewWeb.Page, title: "Timer", category: :components

  def mount(socket), do: assign(socket, running: true, elapsed: 11_565, finished: 0)

  def handle_event("shift-toggled", %{"running" => running, "elapsed" => elapsed}, socket),
    do: {:noreply, assign(socket, running: running, elapsed: elapsed)}

  def handle_event("break-over", _params, socket),
    do: {:noreply, assign(socket, finished: socket.assigns.finished + 1)}

  def render(assigns) do
    ~H"""
    <.example
      title="Shift timer"
      text="The ring counts in the browser; Pause and +15 min run without a round trip and the server hears the toggle."
      class="mt-5 grid gap-5 sm:grid-cols-2 lg:grid-cols-3"
    >
      <.timer
        id="shift"
        elapsed={@elapsed}
        running={@running}
        kicker="Register open"
        kicker_paused="Paused"
        label="Register 01 · Ana Souza"
        on_toggle="shift-toggled"
      >
        <:actions>
          <.button variant="soft" color="primary" phx-click={LineaUI.Timer.toggle("shift")}>
            {(@running && "Pause") || "Resume"}
          </.button>
          <.button variant="outline" color="neutral" phx-click={LineaUI.Timer.add("shift", 900)}>
            +15 min
          </.button>
        </:actions>
      </.timer>
      <div class="flex flex-col justify-between gap-4">
        <div class="flex items-center justify-between rounded-lg bg-white px-4 py-3 dark:bg-navy-700">
          <span class="font-mono text-xs text-slate-500 dark:text-navy-200">
            &lt;.timer&gt; · shift
          </span>
          <.timer
            id="shift-mini"
            variant="mini"
            elapsed={@elapsed}
            running={@running}
            label="Shift time"
          />
        </div>
        <p class="text-xs-plus text-slate-500 dark:text-navy-200">
          Server: running {inspect(@running)}, elapsed {@elapsed}s
        </p>
      </div>
    </.example>

    <.example
      title="Countdown"
      text="direction=down shows the time left and empties the ring; on_finish fires once at zero."
      class="mt-5 grid gap-5 sm:grid-cols-2 lg:grid-cols-3"
    >
      <.timer
        id="break"
        direction="down"
        total={20}
        elapsed={0}
        color="warning"
        kicker="Break"
        kicker_paused="Paused"
        label="Back in a moment"
        on_finish="break-over"
      >
        <:actions>
          <.button variant="outline" color="neutral" phx-click={LineaUI.Timer.toggle("break")}>
            Pause or resume
          </.button>
          <.button variant="outline" color="neutral" phx-click={LineaUI.Timer.add("break", -10)}>
            -10 s
          </.button>
        </:actions>
      </.timer>
      <p class="self-center text-xs-plus text-slate-500 dark:text-navy-200">
        Finished {@finished} time(s) on the server.
      </p>
    </.example>

    <.example
      title="Sizes and colors"
      text="Three diameters; the ring takes the color while it runs and is warning when paused."
      class="mt-5 flex flex-wrap items-start gap-5"
    >
      <.timer id="t-sm" size="sm" elapsed={7200} color="success" kicker="Open" />
      <.timer id="t-md" elapsed={14_400} color="info" kicker="Open" label="Register 02" />
      <.timer
        id="t-lg"
        size="lg"
        elapsed={21_600}
        running={false}
        kicker="Open"
        kicker_paused="Paused"
      />
    </.example>

    <.example
      title="Mini timer"
      text="The pill for the top bar of the PDV: a pulsing dot and the short time."
      class="mt-5 flex flex-wrap items-center gap-4"
    >
      <.timer id="m-sm" variant="mini" size="sm" elapsed={11_565} />
      <.timer id="m-md" variant="mini" elapsed={11_565} />
      <.timer id="m-lg" variant="mini" size="lg" elapsed={11_565} format="hms" />
      <.timer id="m-paused" variant="mini" elapsed={11_565} running={false} />
    </.example>
    """
  end
end
