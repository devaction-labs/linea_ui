defmodule LineaUI.Components.Dropdown do
  @moduledoc """
  LineOne's dropdown menu: a white box under its button with links and actions, groups split by
  separators, icons, a header, a search field, people.

      <.dropdown id="actions" label="Dropdown">
        <.dropdown_item href="#">Action</.dropdown_item>
        <.dropdown_item phx-click="archive">Archive</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item color="error" phx-click="delete">
          <:icon><svg>…</svg></:icon>
          Delete item
        </.dropdown_item>
      </.dropdown>

  `toggle_icon` draws LineOne's flat round icon button with the three dots (the menu of a card):

      <.dropdown id="card-menu" toggle_icon="dots" placement="bottom-end">
        <.dropdown_item href="#">Action</.dropdown_item>
      </.dropdown>

  `label` draws LineOne's button with its turning chevron (`color` and `shape` style it); any
  other trigger goes in the `:toggle` slot:

      <.dropdown id="more">
        <:toggle><.button icon variant="flat" shape="pill" aria-label="More">⋮</.button></:toggle>
        …
      </.dropdown>

  A `dropdown_submenu` nests a menu that opens to the side, on hover, on click, or with → (←
  or Esc goes back to its parent):

      <.dropdown id="row" toggle_icon="dots">
        <.dropdown_item phx-click="edit">Edit</.dropdown_item>
        <.dropdown_submenu label="Move to">
          <.dropdown_item phx-click="move" phx-value-to="archive">Archive</.dropdown_item>
          <.dropdown_item phx-click="move" phx-value-to="trash">Trash</.dropdown_item>
        </.dropdown_submenu>
      </.dropdown>

  A long menu scrolls inside a `scroll_area` (`LineaUI.Components.ScrollArea`); keep submenus out
  of a scrolling box, which would clip them.

  The keyboard works as in a menu (↑ ↓ Home End, letters, Esc, Tab). It opens and closes from
  the browser (`LineaUI.toggle("actions")`), from the server (`LineaUI.close(socket, "actions")`)
  or from `open`; `on_open` / `on_close` run whoever opened or closed it.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Button
  alias LineaUI.Components.Overlay

  @placements ~w(bottom-start bottom bottom-end top-start top top-end left-start left left-end right-start right right-end)

  @doc """
  Renders a dropdown menu.

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true
  attr :label, :string, default: nil, doc: "Draws LineOne's dropdown button with this text."

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error),
    doc: "The color of the `label` button."

  attr :toggle_icon, :string,
    default: nil,
    values: [nil, "dots", "dots-vertical"],
    doc:
      "Draws LineOne's flat icon-button trigger with three dots, horizontal (`dots`) or vertical (`dots-vertical`). It inherits the parent's text color and is `size-8` and round; `label` and the `:toggle` slot win over it."

  attr :toggle_class, :any,
    default: nil,
    doc: "Merged into the `toggle_icon` button (`-mr-2 size-7`...)."

  attr :toggle_label, :string,
    default: "Menu",
    doc: "The accessible name of the `toggle_icon` button."

  attr :shape, :string,
    default: nil,
    values: [nil, "rounded", "pill", "square"],
    doc:
      "The shape of the trigger button. `nil` is `rounded` for the `label` button and `pill` for the `toggle_icon` one."

  attr :open, :boolean, default: false
  attr :placement, :string, default: "bottom-start", values: @placements
  attr :offset, :integer, default: 4, doc: "Pixels between the trigger and the menu."
  attr :close_on_select, :boolean, default: true
  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_open` / `on_close` events."

  attr :class, :any,
    default: nil,
    doc: "Merged into the menu box (`w-72`, `h-36 overflow-y-auto`...)."

  attr :rest, :global
  slot :toggle, doc: "A trigger of your own instead of the `label` button."
  slot :inner_block, required: true

  def dropdown(assigns) do
    assigns =
      assigns
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <div
      id={@id}
      class="relative inline-flex"
      phx-hook="LineaUI.Dropdown"
      data-popup="menu"
      data-open={bool(@open)}
      data-placement={@placement}
      data-offset={@offset}
      data-close-on-select={bool(@close_on_select)}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <div data-trigger class="inline-flex">
        <Button.button
          :if={@toggle == [] and @toggle_icon == nil}
          color={@color}
          shape={@shape || "rounded"}
          class="space-x-2"
          id={"#{@id}-button"}
        >
          <span>{@label}</span>
          <Overlay.chevron_icon />
        </Button.button>
        <Button.button
          :if={@toggle == [] and @toggle_icon != nil}
          icon
          variant="flat"
          color="current"
          shape={@shape || "pill"}
          class={merge(["size-8", @toggle_class])}
          id={"#{@id}-button"}
          aria-label={@toggle_label}
        >
          <.dots_icon name={@toggle_icon} />
        </Button.button>
        {render_slot(@toggle)}
      </div>
      <div
        id={"#{@id}-menu"}
        class="popper-root absolute left-0 top-0 w-max"
        data-panel
        aria-hidden="true"
        phx-mounted={JS.ignore_attributes(["class", "style", "data-popper-placement", "aria-hidden"])}
      >
        <div
          class={
            merge([
              "popper-box rounded-md border border-slate-150 bg-white py-1.5 font-inter dark:border-navy-500 dark:bg-navy-700",
              @class
            ])
          }
          role="menu"
          aria-labelledby={@toggle == [] && "#{@id}-button"}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true

  defp dots_icon(%{name: "dots"} = assigns) do
    ~H"""
    <.glyph name={:dots_horizontal} class="size-5" />
    """
  end

  defp dots_icon(%{name: "dots-vertical"} = assigns) do
    ~H"""
    <.glyph name={:dots_vertical} class="size-5" />
    """
  end

  @item_styles %{
    "default" => %{
      "neutral" =>
        "flex h-8 items-center px-3 pr-8 font-medium tracking-wide outline-hidden transition-all hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100",
      "primary" =>
        "flex h-8 items-center px-3 pr-8 font-medium tracking-wide outline-hidden transition-all hover:bg-primary hover:text-white focus:bg-primary focus:text-white dark:hover:bg-accent dark:focus:bg-accent",
      "error" =>
        "flex h-8 items-center px-3 pr-8 font-medium tracking-wide text-error outline-hidden transition-all hover:bg-error/20 focus:bg-error/20"
    },
    "media" => %{
      "neutral" =>
        "flex items-center space-x-3.5 px-4 py-2 pr-8 tracking-wide outline-hidden transition-all hover:bg-slate-100 focus:bg-slate-100 dark:hover:bg-navy-600 dark:focus:bg-navy-600",
      "primary" =>
        "flex items-center space-x-3.5 px-4 py-2 pr-8 tracking-wide outline-hidden transition-all hover:bg-primary/10 focus:bg-primary/10 dark:hover:bg-accent-light/10 dark:focus:bg-accent-light/10",
      "error" =>
        "flex items-center space-x-3.5 px-4 py-2 pr-8 tracking-wide text-error outline-hidden transition-all hover:bg-error/20 focus:bg-error/20"
    }
  }

  @doc """
  An item of the menu: a link with `href`, `navigate` or `patch`, a button otherwise
  (`phx-click`, `type="submit"`...). A link takes `target`, `rel`, `download`, `hreflang` and
  `referrerpolicy`, so it can open in a new tab or download a file:

      <.dropdown_item href={@danfe_url} target="_blank" rel="noopener">Open DANFE</.dropdown_item>
      <.dropdown_item href={@xml_url} download="nfe.xml">Download XML</.dropdown_item>
  """
  attr :color, :string, default: "neutral", values: ~w(neutral primary error)

  attr :variant, :string,
    default: "default",
    values: ~w(default media),
    doc: "`media` is the taller row LineOne uses for people (an avatar and two lines)."

  attr :disabled, :boolean, default: false
  attr :type, :string, default: "button"
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(href navigate patch method replace download target rel hreflang referrerpolicy form name value)

  slot :icon, doc: "Drawn before the text, as in LineOne's \"Dropdown Icons\"."
  slot :inner_block, required: true

  def dropdown_item(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        merge([
          @item_styles[assigns.variant][assigns.color],
          assigns.icon != [] && "space-x-3",
          assigns.disabled && "pointer-events-none opacity-60",
          "w-full text-left",
          assigns.class
        ])
      )

    render_item(assigns)
  end

  defp render_item(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link
      class={@classes}
      role="menuitem"
      tabindex="-1"
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}
    </.link>
    """
  end

  defp render_item(assigns) do
    ~H"""
    <button
      type={@type}
      class={@classes}
      role="menuitem"
      tabindex="-1"
      disabled={@disabled}
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  An item that opens a nested menu to its side, holding `dropdown_item`s (and separators,
  headers, or further submenus). It opens when the pointer rests on it, on click, and with →,
  Enter or Space, which also move the focus into it; ← and Esc close it and give the focus back.
  It opens on the `placement` side, or the other one when the screen has no room there.

      <.dropdown_submenu label="Export">
        <:icon><.icon name="huge-download-04" class="size-4.5" /></:icon>
        <.dropdown_item phx-click="export" phx-value-format="csv">CSV</.dropdown_item>
        <.dropdown_item phx-click="export" phx-value-format="pdf">PDF</.dropdown_item>
      </.dropdown_submenu>
  """
  attr :id, :string, default: nil, doc: "Generated when not given."
  attr :label, :string, required: true

  attr :placement, :string,
    default: "right",
    values: ~w(right left),
    doc: "The side it opens to, when there is room."

  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil, doc: "Merged into the nested menu box (`w-48`...)."
  attr :trigger_class, :any, default: nil, doc: "Merged into the item that opens it."
  attr :rest, :global
  slot :icon, doc: "Drawn before the label."
  slot :inner_block, required: true

  def dropdown_submenu(assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || gen_id("submenu"))
      |> assign(:item_class, @item_styles["default"]["neutral"])

    ~H"""
    <div
      id={@id}
      class="relative"
      data-submenu
      data-open="false"
      data-placement={@placement}
      data-side={@placement}
      phx-mounted={JS.ignore_attributes(["data-open", "data-side"])}
      {@rest}
    >
      <button
        id={"#{@id}-trigger"}
        type="button"
        class={
          merge([
            @item_class,
            "w-full pr-3 text-left",
            @icon != [] && "space-x-3",
            @disabled && "pointer-events-none opacity-60",
            @trigger_class
          ])
        }
        role="menuitem"
        tabindex="-1"
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-menu"}
        aria-disabled={@disabled && "true"}
        disabled={@disabled}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        data-submenu-trigger
      >
        {render_slot(@icon)}<span class="flex-1">{@label}</span>
        <.glyph name={:chevron_right} class="ml-4 size-4 shrink-0 text-slate-400 dark:text-navy-300" />
      </button>
      <div class="linea-submenu" data-submenu-panel>
        <div
          id={"#{@id}-menu"}
          class={
            merge([
              "w-max min-w-40 rounded-md border border-slate-150 bg-white py-1.5 font-inter shadow-soft dark:border-navy-500 dark:bg-navy-700 dark:shadow-soft-dark",
              @class
            ])
          }
          role="menu"
          aria-labelledby={"#{@id}-trigger"}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc "A title over the items, as in LineOne's \"HTML Content\" dropdown."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_header(assigns) do
    ~H"""
    <h3
      class={merge(["px-4 py-3 font-medium tracking-wide text-slate-700 dark:text-navy-100", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc "The line between two groups of items."
  attr :class, :any, default: nil
  attr :rest, :global

  def dropdown_separator(assigns) do
    ~H"""
    <div
      class={merge(["my-1 h-px bg-slate-150 dark:bg-navy-500", @class])}
      role="separator"
      {@rest}
    >
    </div>
    """
  end

  @doc """
  The search field across the menu, with LineOne's magnifier. Typing in it is not taken by the
  menu's keys; `phx-change`, `phx-debounce` and `name` pass through.
  """
  attr :placeholder, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-debounce phx-throttle autocomplete form)

  def dropdown_search(assigns) do
    ~H"""
    <label class="relative flex">
      <input
        type="text"
        name={@name}
        value={@value}
        placeholder={@placeholder}
        class={
          merge([
            "form-input peer w-full border-y border-slate-150 bg-transparent px-4 py-2 pl-9 text-xs-plus placeholder:text-slate-400/70 dark:border-navy-600",
            @class
          ])
        }
        {@rest}
      />
      <span class="pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent">
        <.glyph name={:search_solid} class="size-4.5 transition-colors duration-200" />
      </span>
    </label>
    """
  end
end
