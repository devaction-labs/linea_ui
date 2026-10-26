defmodule LineaUI.Components.Tabs do
  @moduledoc """
  LineOne's tabs: underlined (`line`), on a gray track (`boxed`), rounded (`pill`) and plain text (`text`), laid out
  horizontally or vertically, with or without icons.

      <.tabs id="profile-tabs" selected="home">
        <:tab name="home">Home</:tab>
        <:tab name="profile">Profile</:tab>
        <:panel name="home">…</:panel>
        <:panel name="profile">…</:panel>
      </.tabs>

      <.tabs id="boxed" variant="boxed">
        <:tab name="home"><svg class="size-4.5">…</svg><span>Home</span></:tab>
        <:panel name="home">…</:panel>
      </.tabs>

  The selected tab comes from `selected` and switching happens in the browser (click, ←/→ or ↑/↓,
  Home and End) without a round trip. A choice made in the browser survives patches; when the
  server changes `selected`, the server wins.

  `on_change` tells the server what was chosen:

      <.tabs id="server-tabs" selected={@tab} on_change="select_tab">…</.tabs>
      <.tabs id="period" variant="boxed" size="sm"><:tab name="month">Last month</:tab></.tabs>
      <.tabs id="range" variant="text"><:tab name="week">Last 7 days</:tab><:tab name="all">All time</:tab></.tabs>

      def handle_event("select_tab", %{"id" => "server-tabs", "value" => tab}, socket),
        do: {:noreply, assign(socket, tab: tab)}

  Every selection also dispatches a bubbling `linea:change` DOM event with
  `detail: %{id: id, value: name, tab: name}`.

  ## Navigation tabs

  Tabs without `:panel`s switch routes instead of panels: give each `:tab` a `patch`,
  `navigate` or `href` and it renders as a `<.link>`, so the browser goes there with no
  `handle_event` round trip, and `selected` (the current route's tab) carries
  `aria-current="page"`:

      <.tabs id="customer-tabs" variant="line" bordered selected={@live_action |> to_string()}>
        <:tab name="show" patch={~p"/customers/\#{@customer}"}>Details</:tab>
        <:tab name="orders" patch={~p"/customers/\#{@customer}/orders"}>Orders</:tab>
        <:tab name="history" navigate={~p"/customers/\#{@customer}/history"}>History</:tab>
      </.tabs>

  A tab only points at a panel (`aria-controls`) when a `:panel` with its `name` exists, so
  navigation tabs carry no dangling references. The arrow keys move the focus between link
  tabs; Enter follows the focused one.
  """

  use LineaUI.Component

  @tab_base %{
    {"line", "horizontal"} =>
      "btn gap-2 rounded-none border-b-2 px-3 py-2 font-medium aria-selected:border-primary aria-selected:text-primary dark:aria-selected:border-accent dark:aria-selected:text-accent-light not-aria-selected:border-transparent not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100",
    {"line", "vertical"} =>
      "btn justify-start gap-2 rounded-none border-r-2 px-3 py-2 text-left font-medium aria-selected:border-primary aria-selected:text-primary dark:aria-selected:border-accent dark:aria-selected:text-accent-light not-aria-selected:border-transparent not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100",
    {"boxed", "horizontal"} =>
      "btn gap-2 px-3 py-1.5 font-medium aria-selected:bg-white aria-selected:shadow-sm dark:aria-selected:bg-navy-500 dark:aria-selected:text-navy-100 not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100",
    {"boxed", "vertical"} =>
      "btn justify-start gap-2 px-3 py-1.5 text-left font-medium aria-selected:bg-white aria-selected:shadow-sm dark:aria-selected:bg-navy-500 dark:aria-selected:text-navy-100 not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100",
    {"pill", "horizontal"} =>
      "btn h-8 gap-2 rounded-full text-xs-plus font-medium not-aria-selected:hover:bg-slate-300/20 not-aria-selected:focus:bg-slate-300/20 not-aria-selected:active:bg-slate-300/25 not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:bg-navy-300/20 dark:not-aria-selected:focus:bg-navy-300/20 dark:not-aria-selected:active:bg-navy-300/25 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100",
    {"pill", "vertical"} =>
      "btn h-8 justify-start gap-2 rounded-full text-left text-xs-plus font-medium not-aria-selected:hover:bg-slate-300/20 not-aria-selected:focus:bg-slate-300/20 not-aria-selected:active:bg-slate-300/25 not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:bg-navy-300/20 dark:not-aria-selected:focus:bg-navy-300/20 dark:not-aria-selected:active:bg-navy-300/25 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100"
  }

  @text_base "btn gap-2 rounded-none p-0 font-medium tracking-wide not-aria-selected:hover:text-slate-800 not-aria-selected:focus:text-slate-800 dark:not-aria-selected:hover:text-navy-100 dark:not-aria-selected:focus:text-navy-100"

  @boxed_sizes %{
    "xs" => "px-2.5 py-0.5 text-xs",
    "sm" => "px-3 py-1 text-xs-plus",
    "md" => nil
  }

  @text_colors %{
    "primary" => "aria-selected:text-primary dark:aria-selected:text-accent-light",
    "neutral" => "aria-selected:text-slate-800 dark:aria-selected:text-navy-50"
  }

  @pill_colors %{
    "primary" =>
      "aria-selected:bg-primary/10 aria-selected:text-primary dark:aria-selected:bg-accent-light/10 dark:aria-selected:text-accent-light",
    "neutral" =>
      "aria-selected:bg-slate-150 aria-selected:text-slate-800 dark:aria-selected:bg-navy-600 dark:aria-selected:text-navy-50"
  }

  @text_tabs %{
    "horizontal" => @text_base,
    "vertical" => "justify-start text-left " <> @text_base
  }

  @root %{"horizontal" => "flex flex-col", "vertical" => "flex"}

  @scroll %{
    {"line", "horizontal"} => "is-scrollbar-hidden overflow-x-auto",
    {"line", "vertical"} => "shrink-0",
    {"boxed", "horizontal"} =>
      "is-scrollbar-hidden overflow-x-auto rounded-lg bg-slate-200 text-slate-600 dark:bg-navy-800 dark:text-navy-200",
    {"boxed", "vertical"} =>
      "shrink-0 self-start rounded-lg bg-slate-200 text-slate-600 dark:bg-navy-800 dark:text-navy-200",
    {"pill", "horizontal"} => "is-scrollbar-hidden overflow-x-auto",
    {"pill", "vertical"} => "shrink-0",
    {"text", "horizontal"} => "is-scrollbar-hidden overflow-x-auto",
    {"text", "vertical"} => "shrink-0"
  }

  @track %{
    {true, "horizontal"} => "border-b-2 border-slate-150 dark:border-navy-500",
    {true, "vertical"} => "h-full border-r-2 border-slate-150 dark:border-navy-500",
    {false, "horizontal"} => nil,
    {false, "vertical"} => nil
  }

  @list %{
    {"line", "horizontal"} => "flex",
    {"line", "vertical"} => "flex flex-col",
    {"boxed", "horizontal"} => "flex px-1.5 py-1",
    {"boxed", "vertical"} => "flex flex-col px-1.5 py-1",
    {"pill", "horizontal"} => "flex gap-2",
    {"pill", "vertical"} => "flex flex-col space-y-2",
    {"text", "horizontal"} => "flex gap-4",
    {"text", "vertical"} => "flex flex-col space-y-2"
  }

  @overlap %{
    {true, "horizontal"} => "-mb-0.5",
    {true, "vertical"} => "-mr-0.5",
    {false, "horizontal"} => nil,
    {false, "vertical"} => nil
  }

  @panels %{"horizontal" => "pt-4", "vertical" => "min-w-0 flex-1 pl-4"}

  @transitions %{
    "left" => "tab-content is-active tab-shift-left",
    "up" => "tab-content is-active tab-shift-up",
    "none" => nil
  }

  @doc """
  Renders a tab list and its panels. Each `:tab` is matched to the `:panel` with the same `name`.

      <.tabs id="settings" selected={@tab} variant="boxed" on_change="tab_changed">
        <:tab name="general">General</:tab>
        <:tab name="billing" disabled>Billing</:tab>
        <:panel name="general">…</:panel>
        <:panel name="billing">…</:panel>
      </.tabs>

  Events: with `on_change="tab_changed"` the hook pushes `"tab_changed"` with
  `%{"id" => "settings", "value" => "general", "tab" => "general"}` (to `target` or the closest LiveComponent)
  after the browser switched; with `on_change={%JS{}}` the commands run on the tabs element.
  Either way a bubbling `linea:change` DOM event carries `detail: %{id, value, tab}`; `tab` repeats `value`.
  """
  attr(:id, :string, required: true, doc: "Needed by the hook and for the tab/panel ids.")

  attr(:selected, :string,
    default: nil,
    doc: "The `name` of the selected tab; the first one when not given."
  )

  attr(:variant, :string,
    default: "line",
    values: ~w(line boxed pill text),
    doc:
      "`line` underlines the selected tab, `boxed` lifts it off a gray track, `pill` fills a rounded tab, `text` is plain text that only changes color (no border or background; spacing comes from `list_class`, `space-x-4` by default)."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md),
    doc:
      "For `boxed`: `md` is `px-3 py-1.5`, `sm` is LineOne's compact `px-3 py-1 text-xs-plus`, `xs` is `px-2.5 py-0.5 text-xs`."
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(primary neutral),
    doc: "The fill of the selected `pill` tab and the text color of the selected `text` tab."
  )

  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:bordered, :boolean,
    default: false,
    doc: "For `line`: draws the gray rule the tabs sit on."
  )

  attr(:overlap, :boolean,
    default: false,
    doc:
      "For a `bordered` line: the selected tab's line covers the gray rule instead of sitting on it."
  )

  attr(:grow, :boolean, default: false, doc: "The tabs share the whole width of the list.")

  attr(:transition, :string,
    default: "left",
    values: ~w(left up none),
    doc: "The way a panel comes in: sliding from the right (`left`) or from below (`up`)."
  )

  attr(:on_change, :any,
    default: nil,
    doc: """
    Run when a tab is chosen in the browser. An event name is pushed with
    `%{"id" => id, "value" => name, "tab" => name}`; a `%JS{}` is executed on the tabs element.
    """
  )

  attr(:target, :any, default: nil, doc: "The `phx-target` of `on_change`.")
  attr(:list_class, :any, default: nil, doc: "Extra classes for the tab list.")
  attr(:panels_class, :any, default: nil, doc: "Extra classes for the wrapper of the panels.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :tab, required: true, doc: "A tab button; its content is the label, icons included." do
    attr(:name, :string,
      required: true,
      doc: "Matches the `:panel` it shows and is the `on_change` value."
    )

    attr(:disabled, :boolean, doc: "Skipped by clicks and the arrow keys.")
    attr(:patch, :string, doc: "Renders the tab as a `<.link patch>` (navigation tabs).")
    attr(:navigate, :string, doc: "Renders the tab as a `<.link navigate>` (navigation tabs).")
    attr(:href, :string, doc: "Renders the tab as a `<.link href>` (navigation tabs).")
    attr(:replace, :boolean, doc: "With `patch` or `navigate`: replaces the history entry.")
    attr(:class, :any)
  end

  slot :panel, doc: "The content shown while the tab with the same `name` is selected." do
    attr(:name, :string, required: true, doc: "The `name` of its tab.")
    attr(:class, :any)
  end

  def tabs(assigns) do
    value = assigns.selected || assigns.tab |> List.first() |> Map.fetch!(:name)
    key = {assigns.variant, assigns.orientation}

    assigns
    |> assign(:selected, value)
    |> assign(:root_class, merge([@root[assigns.orientation], assigns.class]))
    |> assign(:scroll_class, @scroll[key])
    |> assign(
      :track_class,
      @track[{assigns.bordered and assigns.variant == "line", assigns.orientation}]
    )
    |> assign(
      :list_classes,
      merge([@list[key], @overlap[{assigns.overlap, assigns.orientation}], assigns.list_class])
    )
    |> assign(:tab_class, tab_class(assigns, key))
    |> assign(:panels_classes, merge([@panels[assigns.orientation], assigns.panels_class]))
    |> assign(:panel_class, @transitions[assigns.transition])
    |> assign(:event, event_name(assigns.on_change))
    |> assign(:on_change_js, on_change_js(assigns.on_change))
    |> assign(:panel_names, MapSet.new(assigns.panel, & &1.name))
    |> assign(
      :keep,
      JS.ignore_attributes(["aria-selected", "aria-current", "tabindex", "hidden"])
    )
    |> render_tabs()
  end

  defp tab_class(assigns, key) do
    [
      tab_base(assigns.variant, key),
      boxed_size(assigns),
      variant_color(assigns),
      grow_class(assigns.grow)
    ]
  end

  defp tab_base("text", {_variant, orientation}), do: @text_tabs[orientation]
  defp tab_base(_variant, key), do: @tab_base[key]

  defp boxed_size(%{variant: "boxed", size: size}), do: @boxed_sizes[size]
  defp boxed_size(_assigns), do: nil

  defp variant_color(%{variant: "pill", color: color}), do: @pill_colors[color]
  defp variant_color(%{variant: "text", color: color}), do: @text_colors[color]
  defp variant_color(_assigns), do: nil

  defp grow_class(true), do: "flex-1"
  defp grow_class(false), do: "shrink-0"

  defp event_name(event) when is_binary(event), do: event
  defp event_name(_on_change), do: nil

  defp on_change_js(%JS{} = js), do: js
  defp on_change_js(_on_change), do: nil

  defp render_tabs(assigns) do
    ~H"""
    <div
      id={@id}
      class={@root_class}
      phx-hook="LineaUI.Tabs"
      data-selected={@selected}
      data-event={@event}
      data-on-change={@on_change_js}
      phx-target={@target}
      data-orientation={@orientation}
      {@rest}
    >
      <div class={@scroll_class}>
        <div class={@track_class}>
          <div role="tablist" aria-orientation={@orientation} class={@list_classes}>
            <.tab_control
              :for={tab <- @tab}
              tab={tab}
              id={"#{@id}-tab-#{tab.name}"}
              controls={MapSet.member?(@panel_names, tab.name) && "#{@id}-panel-#{tab.name}"}
              selected={tab.name == @selected}
              keep={@keep}
              class={merge([@tab_class, tab[:class]])}
            />
          </div>
        </div>
      </div>
      <div :if={@panel != []} class={@panels_classes}>
        <div
          :for={panel <- @panel}
          role="tabpanel"
          id={"#{@id}-panel-#{panel.name}"}
          aria-labelledby={"#{@id}-tab-#{panel.name}"}
          tabindex="0"
          data-value={panel.name}
          hidden={panel.name != @selected}
          phx-mounted={@keep}
          class={merge([@panel_class, "outline-hidden", panel[:class]])}
        >
          {render_slot(panel)}
        </div>
      </div>
    </div>
    """
  end

  attr(:tab, :map, required: true)
  attr(:id, :string, required: true)
  attr(:controls, :any, required: true)
  attr(:selected, :boolean, required: true)
  attr(:keep, :any, required: true)
  attr(:class, :any, required: true)

  defp tab_control(%{tab: %{disabled: true}} = assigns), do: tab_button(assigns)

  defp tab_control(%{tab: tab} = assigns)
       when is_map_key(tab, :patch) or is_map_key(tab, :navigate) or is_map_key(tab, :href) do
    ~H"""
    <.link
      role="tab"
      id={@id}
      patch={@tab[:patch]}
      navigate={@tab[:navigate]}
      href={@tab[:href]}
      replace={@tab[:replace] || false}
      aria-controls={@controls}
      aria-selected={bool(@selected)}
      aria-current={@selected && "page"}
      tabindex={tabindex(@selected)}
      data-value={@tab.name}
      data-link
      phx-mounted={@keep}
      class={@class}
    >
      {render_slot(@tab)}
    </.link>
    """
  end

  defp tab_control(assigns), do: tab_button(assigns)

  defp tab_button(assigns) do
    ~H"""
    <button
      type="button"
      role="tab"
      id={@id}
      aria-controls={@controls}
      aria-selected={bool(@selected)}
      tabindex={tabindex(@selected)}
      data-value={@tab.name}
      disabled={@tab[:disabled]}
      phx-mounted={@keep}
      class={@class}
    >
      {render_slot(@tab)}
    </button>
    """
  end

  defp tabindex(true), do: "0"
  defp tabindex(false), do: "-1"
end
