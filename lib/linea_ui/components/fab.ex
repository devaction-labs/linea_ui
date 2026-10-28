defmodule LineaUI.Components.Fab do
  @moduledoc """
  A floating action button that retracts: a navy pill holding a round icon tile and a label, which shrinks to
  just the round bubble when it is not in use.

      <.fab id="ask" label="Ask the assistant" phx-click="open_assistant" />

  The label is always in the DOM and is the button's `aria-label`. `color` picks the look (`assistant` is the
  indigo to purple tile on navy, `primary`, `dark`, `light`), `position` the corner, `size` `md` or `lg`. Extra
  offset goes in `class` (`class="bottom-24"`). With `href`, `navigate` or `patch` it renders a link.

  ## Retracting

  `retract` says when the pill shows its label. On a device without hover (touch) every mode but `never` is
  the bubble, and a tap runs the action directly.

  `hover` (default) is the bubble at rest; it expands on pointer hover and keyboard focus:

      <.fab id="ask" label="Ask the assistant" phx-click="open_assistant" />

  `auto` starts expanded, retracts after `retract_after` ms (4000 by default) or as soon as the page scrolls,
  and expands again on hover or focus:

      <.fab id="help" label="Need a hand?" retract="auto" retract_after={6000} navigate={~p"/help"} />

  `never` is always expanded:

      <.fab id="new" label="New invoice" retract="never" color="primary" patch={~p"/invoices/new"}>
        <:icon><.icon name="hero-plus" class="size-5" /></:icon>
      </.fab>

  `always` is always the bubble; the label is only the `aria-label` and the native tooltip:

      <.fab id="chat" label="Chat with us" retract="always" color="light" position="bottom-left" badge={3} />

  `expanded` lets the server force the pill open whatever `retract` says, for a hint or an onboarding step:

      <.fab id="ask" label="Ask the assistant" expanded={@show_hint} phx-click="open_assistant" />

  A button with several actions is a speed-dial, `fab_dial/1`.

  The button sits under modals and drawers and above the page (`--linea-z-fab`, 90 by default; an app raises it in
  its own CSS like the other `--linea-z-*` layers).
  """

  use LineaUI.Component

  @base "linea-fab fixed z-(--linea-z-fab) inline-flex items-center rounded-full p-2 shadow-[0_12px_32px_-6px_rgba(25,33,50,.45),0_4px_10px_rgba(25,33,50,.18)] outline-none transition-shadow duration-200 hover:shadow-[0_16px_40px_-6px_rgba(25,33,50,.5),0_6px_14px_rgba(25,33,50,.2)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60 dark:shadow-[0_14px_36px_-6px_rgba(0,0,0,.6),0_4px_10px_rgba(0,0,0,.3)] dark:focus-visible:outline-accent-light"

  @positions %{
    "bottom-right" => "bottom-6 right-6",
    "bottom-left" => "bottom-6 left-6",
    "top-right" => "top-6 right-6",
    "top-left" => "top-6 left-6"
  }

  @colors %{
    "assistant" => %{
      root: "bg-navy-900 text-white dark:bg-navy-700 dark:ring-1 dark:ring-white/10",
      tile: "bg-linear-to-br from-primary to-purple-500 text-white",
      label: "text-white"
    },
    "primary" => %{
      root: "bg-primary text-white dark:bg-accent dark:ring-1 dark:ring-white/10",
      tile: "bg-white/20 text-white",
      label: "text-white"
    },
    "dark" => %{
      root: "bg-navy-900 text-white dark:bg-navy-700 dark:ring-1 dark:ring-white/10",
      tile: "bg-white/10 text-white",
      label: "text-white"
    },
    "light" => %{
      root:
        "bg-white text-slate-800 ring-1 ring-slate-200 dark:bg-navy-700 dark:text-navy-50 dark:ring-navy-500",
      tile: "bg-slate-100 text-slate-600 dark:bg-navy-500 dark:text-navy-100",
      label: "text-slate-800 dark:text-navy-50"
    }
  }

  @sizes %{
    "md" => %{tile: "size-10", icon: "size-5", label: "text-sm"},
    "lg" => %{tile: "size-12", icon: "size-6", label: "text-base"}
  }

  @doc """
  Renders the floating button, or a link when `href`, `navigate` or `patch` is given.

  The server action is the usual `phx-click` (it comes through the global attributes):

      <.fab id="ask" label="Ask the assistant" phx-click="open_assistant" />
      <.fab id="ask" label="Ask the assistant" retract="auto" position="bottom-left" size="lg" navigate={~p"/assistant"} />

  `data-state` (`expanded` or `collapsed`) tells which shape it has; with `retract="auto"` the `LineaUI.Fab`
  hook owns it, so a server patch does not undo a retraction.
  """
  attr(:id, :string, required: true)
  attr(:label, :string, required: true, doc: "Always rendered, and the `aria-label`.")

  attr(:position, :string,
    default: "bottom-right",
    values: ~w(bottom-right bottom-left top-right top-left),
    doc: "The viewport corner; add offset with `class`, e.g. `class=\"bottom-24\"`."
  )

  attr(:color, :string,
    default: "assistant",
    values: ~w(assistant primary dark light),
    doc:
      "`assistant` is the indigo to purple icon tile on navy; `primary` the theme color; `dark` navy with a quiet tile; `light` a white pill."
  )

  attr(:size, :string, default: "md", values: ~w(md lg))

  attr(:retract, :string,
    default: "hover",
    values: ~w(hover auto never always),
    doc:
      "`hover`: the bubble at rest, expanded on hover or keyboard focus. `auto`: expanded at first, retracts after `retract_after` or on scroll, expands on hover or focus. `never`: always expanded. `always`: always the bubble. Touch devices show the bubble in every mode but `never`."
  )

  attr(:retract_after, :integer,
    default: 4000,
    doc: "Milliseconds before `retract=\"auto\"` retracts."
  )

  attr(:expanded, :boolean,
    default: false,
    doc: "`true` forces the pill open, whatever `retract` says."
  )

  attr(:badge, :any,
    default: nil,
    doc: "A count or short text in a dot on the bubble's corner; `nil` shows none."
  )

  attr(:type, :string, default: "button")
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(href navigate patch method download target rel form name value)
  )

  slot(:icon, doc: "The glyph in the tile; the sparkle of the assistant by default.")
  slot(:inner_block, doc: "Replaces the visible label text (`label` stays the `aria-label`).")

  def fab(assigns) do
    assigns
    |> assign(:classes, classes(assigns))
    |> assign(:look, @colors[assigns.color])
    |> assign(:dims, @sizes[assigns.size])
    |> assign(:state, state(assigns.retract, assigns.expanded))
    |> assign(:hook, hook(assigns.retract, assigns.expanded))
    |> assign(:tooltip, tooltip(assigns.retract, assigns.label))
    |> render_fab()
  end

  @dial_base "linea-fab-dial fixed z-(--linea-z-fab) flex gap-2.5"

  @dial_positions %{
    "bottom-right" => "bottom-6 right-6 flex-col items-end",
    "bottom-left" => "bottom-6 left-6 flex-col items-start",
    "top-right" => "top-6 right-6 flex-col-reverse items-end",
    "top-left" => "top-6 left-6 flex-col-reverse items-start"
  }

  @dial_item "linea-fab-dial-item flex cursor-pointer items-center gap-2.5 rounded-full outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60 dark:focus-visible:outline-accent-light"

  @doc """
  A speed-dial: a round button that opens a column of mini actions, each with its label beside it. The button
  turns its plus into a cross while it is open.

      <.fab_dial id="quick" label="Quick actions">
        <:action label="New contact" phx-click="new_contact"><.icon name="hero-user-plus" class="size-4.5" /></:action>
        <:action label="Upload a file" phx-click={JS.push("upload")}><.icon name="hero-arrow-up-tray" class="size-4.5" /></:action>
        <:action label="New proposal" navigate={~p"/proposals/new"}><.icon name="hero-document-plus" class="size-4.5" /></:action>
      </.fab_dial>

  Each `:action` takes `label` (the visible text and the item's name), the icon as its content, and one of
  `phx-click` (an event name or a `%JS{}`, with `phx-target`), `href`, `navigate` or `patch` (a link);
  `disabled` turns it off. The first action is the one nearest the button.

  It opens and closes by click. Escape closes it and gives the focus back to the button; with the dial open the
  up and down arrows walk the actions (from the button, down is the first and up the last, both wrap; Home and
  End go to the ends), a click on an action, a click outside or the focus leaving close it, and the arrows on the
  closed button open it. The button has `aria-expanded`, `aria-haspopup="menu"` and `aria-controls`; the actions
  are the `menuitem`s of a `menu` named after `label`. `open` sets the initial state only (the `LineaUI.FabDial`
  hook owns `data-state`, so a server patch does not undo the person's choice). The motion is off under
  `prefers-reduced-motion`.

  `color`, `size` and `position` are the ones of `fab/1`; `class` adds offset (`class="bottom-24"`).
  """
  attr(:id, :string, required: true)

  attr(:label, :string,
    required: true,
    doc: "The button's `aria-label` and the name of the menu."
  )

  attr(:position, :string,
    default: "bottom-right",
    values: ~w(bottom-right bottom-left top-right top-left),
    doc: "The viewport corner; the actions open away from it."
  )

  attr(:color, :string, default: "primary", values: ~w(assistant primary dark light))
  attr(:size, :string, default: "md", values: ~w(md lg))
  attr(:open, :boolean, default: false, doc: "The initial state; after mount the hook owns it.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:icon,
    doc: "The glyph of the button, a plus by default; it turns 45 degrees (a cross) while open."
  )

  slot :action, required: true, doc: "A mini action: the icon is its content." do
    attr(:label, :string, required: true)
    attr(:href, :string)
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:"phx-click", :any)
    attr(:"phx-target", :any)
    attr(:disabled, :boolean)
    attr(:class, :any)
  end

  def fab_dial(assigns) do
    assigns
    |> assign(:classes, merge([@dial_base, @dial_positions[assigns.position], assigns.class]))
    |> assign(:look, @colors[assigns.color])
    |> assign(:dims, @sizes[assigns.size])
    |> assign(:state, if(assigns.open, do: "open", else: "closed"))
    |> assign(:item_class, @dial_item)
    |> render_dial()
  end

  defp render_dial(assigns) do
    ~H"""
    <div
      id={@id}
      class={@classes}
      data-state={@state}
      data-side={if String.starts_with?(@position, "top"), do: "down", else: "up"}
      phx-hook="LineaUI.FabDial"
      phx-mounted={JS.ignore_attributes(["data-state"])}
      {@rest}
    >
      <div
        id={"#{@id}-menu"}
        role="menu"
        aria-label={@label}
        class={[
          "linea-fab-dial-menu flex gap-2.5",
          if(String.ends_with?(@position, "left"), do: "items-start", else: "items-end"),
          "flex-col"
        ]}
      >
        <.dial_item
          :for={action <- @action}
          action={action}
          id={@id}
          class={@item_class}
          left={String.ends_with?(@position, "left")}
        />
      </div>
      <button
        id={"#{@id}-trigger"}
        type="button"
        data-fab-dial-trigger
        aria-label={@label}
        aria-haspopup="menu"
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-menu"}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        class={
          merge([
            "inline-flex items-center rounded-full p-2 shadow-[0_12px_32px_-6px_rgba(25,33,50,.45),0_4px_10px_rgba(25,33,50,.18)] outline-none transition-shadow duration-200 hover:shadow-[0_16px_40px_-6px_rgba(25,33,50,.5),0_6px_14px_rgba(25,33,50,.2)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary dark:shadow-[0_14px_36px_-6px_rgba(0,0,0,.6),0_4px_10px_rgba(0,0,0,.3)] dark:focus-visible:outline-accent-light",
            @look.root
          ])
        }
      >
        <span class={
          merge([
            "relative flex shrink-0 items-center justify-center rounded-full",
            @look.tile,
            @dims.tile
          ])
        }>
          <span class="linea-fab-dial-icon flex" aria-hidden="true">
            {render_slot(@icon) || plus(assigns)}
          </span>
        </span>
      </button>
    </div>
    """
  end

  defp dial_item(%{action: action} = assigns) do
    assigns =
      assign(assigns, :link?, Enum.any?([:href, :navigate, :patch], &Map.has_key?(action, &1)))

    ~H"""
    <.link
      :if={@link?}
      role="menuitem"
      class={merge([@class, @left && "flex-row-reverse", @action[:class]])}
      aria-disabled={@action[:disabled] && "true"}
      tabindex={@action[:disabled] && "-1"}
      href={@action[:href]}
      navigate={@action[:navigate]}
      patch={@action[:patch]}
      phx-click={@action[:"phx-click"]}
      phx-target={@action[:"phx-target"]}
    >
      <.dial_item_body action={@action} />
    </.link>
    <button
      :if={!@link?}
      type="button"
      role="menuitem"
      class={merge([@class, @left && "flex-row-reverse", @action[:class]])}
      disabled={@action[:disabled]}
      phx-click={@action[:"phx-click"]}
      phx-target={@action[:"phx-target"]}
    >
      <.dial_item_body action={@action} />
    </button>
    """
  end

  defp dial_item_body(assigns) do
    ~H"""
    <span class="linea-fab-dial-label rounded-lg bg-navy-900 px-2.5 py-1.25 text-xs-plus font-medium whitespace-nowrap text-white shadow-[0_4px_10px_rgba(25,33,50,.2)] dark:bg-navy-50 dark:text-navy-900">
      {@action.label}
    </span>
    <span
      class="linea-fab-dial-mini flex size-10 shrink-0 items-center justify-center rounded-full bg-white text-primary ring-1 ring-slate-200 shadow-[0_6px_14px_-4px_rgba(25,33,50,.3)] transition-colors hover:bg-primary/10 dark:bg-navy-700 dark:text-accent-light dark:ring-navy-500 dark:hover:bg-navy-600"
      aria-hidden="true"
    >
      {render_slot(@action)}
    </span>
    """
  end

  defp plus(assigns) do
    ~H"""
    <svg
      class={@dims.icon}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <path d="M12 4.5v15m7.5-7.5h-15" />
    </svg>
    """
  end

  defp classes(assigns) do
    merge([@base, @colors[assigns.color].root, @positions[assigns.position], assigns.class])
  end

  defp state(_retract, true), do: "expanded"
  defp state("never", _expanded), do: "expanded"
  defp state("auto", _expanded), do: "expanded"
  defp state(_retract, _expanded), do: "collapsed"

  defp hook("auto", false), do: "LineaUI.Fab"
  defp hook(_retract, _expanded), do: nil

  defp tooltip("always", label), do: label
  defp tooltip(_retract, _label), do: nil

  defp render_fab(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link
      id={@id}
      class={@classes}
      aria-label={@label}
      title={@tooltip}
      aria-disabled={@disabled && "true"}
      tabindex={@disabled && "-1"}
      data-retract={@retract}
      data-state={@state}
      data-retract-after={@retract_after}
      phx-hook={@hook}
      phx-mounted={@hook && JS.ignore_attributes(["data-state"])}
      {@rest}
    >
      <.fab_body
        look={@look}
        dims={@dims}
        label={@label}
        badge={@badge}
        icon={@icon}
        inner_block={@inner_block}
      />
    </.link>
    """
  end

  defp render_fab(assigns) do
    ~H"""
    <button
      id={@id}
      type={@type}
      class={@classes}
      aria-label={@label}
      title={@tooltip}
      disabled={@disabled}
      data-retract={@retract}
      data-state={@state}
      data-retract-after={@retract_after}
      phx-hook={@hook}
      phx-mounted={@hook && JS.ignore_attributes(["data-state"])}
      {@rest}
    >
      <.fab_body
        look={@look}
        dims={@dims}
        label={@label}
        badge={@badge}
        icon={@icon}
        inner_block={@inner_block}
      />
    </button>
    """
  end

  defp fab_body(assigns) do
    ~H"""
    <span class={
      merge([
        "relative flex shrink-0 items-center justify-center rounded-full",
        @look.tile,
        @dims.tile
      ])
    }>
      {render_slot(@icon) || sparkle(assigns)}
      <span
        :if={@badge}
        class="absolute -top-1 -right-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-error px-1 text-[11px] leading-none font-semibold text-white ring-2 ring-white dark:ring-navy-900"
      >
        {@badge}
      </span>
    </span>
    <span class="linea-fab-label" aria-hidden="true">
      <span>
        <% content = render_slot(@inner_block) %>
        <span class={
          merge(["block pr-4 pl-3 font-semibold whitespace-nowrap", @dims.label, @look.label])
        }>
          {label_or(content, @label)}
        </span>
      </span>
    </span>
    """
  end

  defp label_or(content, label), do: label_or(content, blank?(content), label)
  defp label_or(_content, true, label), do: label
  defp label_or(content, false, _label), do: content

  defp blank?(nil), do: true

  defp blank?(content),
    do: content |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary() |> String.trim() == ""

  defp sparkle(assigns) do
    ~H"""
    <svg
      class={@dims.icon}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.6"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <path d="M12 3l1.8 4.2L18 9l-4.2 1.8L12 15l-1.8-4.2L6 9l4.2-1.8z" />
    </svg>
    """
  end
end
