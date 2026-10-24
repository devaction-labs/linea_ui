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

  The menu floats above the page: opened, it sits in the browser's top layer (`popover="manual"`,
  `position: fixed`, placed from the trigger's rectangle), so a table's horizontal scroll area, a
  drawer's scrolling body or an ancestor's `z-index` / `transform` neither cut it off nor cover it,
  and the "…" menu in the last column of a table opens whole. It follows the page and any box
  around the trigger as they scroll, flips to the other side when there is no room, and closes
  when its trigger scrolls out of sight. It stays in the LiveView's DOM where it was rendered, so
  patches and `phx-click` on items work as usual. Without the Popover API (old browsers) it is a
  fixed box on `--linea-z-popover`.
  ## A filter menu

  `dropdown_checkbox` and `dropdown_radio` are items that keep the menu open while they are toggled
  (`menuitemcheckbox` and `menuitemradio`); a `dropdown_submenu` groups them and shows how many are
  checked; `dropdown_footer` ends the menu with Clear / Apply. `keep_submenus` leaves an open submenu
  open while the pointer moves elsewhere. Inside a form, an item with a `name` is a real (hidden) input, so
  the form's `phx-change` hears every tick and `phx-submit` gets the checked ones:

      <.form for={@form} phx-change="filter" phx-submit="apply">
        <.dropdown id="filters" label="Filter" keep_submenus close_on_select={false}>
          <.dropdown_submenu label="Status">
            <.dropdown_checkbox
              :for={status <- @statuses}
              name="filter[status][]"
              value={status}
              checked={status in @filter.status}
              count={@counts[status]}
            >
              {status}
            </.dropdown_checkbox>
          </.dropdown_submenu>
          <.dropdown_separator />
          <.dropdown_label>Sort by</.dropdown_label>
          <.dropdown_radio name="filter[sort]" value="recent" checked={@filter.sort == "recent"}>
            Most recent
          </.dropdown_radio>
          <.dropdown_radio name="filter[sort]" value="value" checked={@filter.sort == "value"}>
            Highest value
          </.dropdown_radio>
          <.dropdown_footer locale="pt_BR" />
        </.dropdown>
      </.form>

  Without a form, give an item `phx-click` and `phx-value-*`; the checked state is the item's `checked`
  (the server wins when it changes it, a patch that did not change it keeps what was ticked in the browser).

  A long menu scrolls inside a `scroll_area` (`LineaUI.Components.ScrollArea`); keep submenus out
  of a scrolling box inside the menu, which would clip them.

  The keyboard works as in a menu (↑ ↓ Home End, letters, Esc, Tab). It opens and closes from
  the browser (`LineaUI.toggle("actions")`), from the server (`LineaUI.close(socket, "actions")`)
  or from `open`; `on_open` / `on_close` run whoever opened or closed it.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Button
  alias LineaUI.Components.Overlay
  alias LineaUI.Components.Strings

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

  attr :keep_submenus, :boolean,
    default: false,
    doc:
      "An open submenu stays open when the pointer moves to another item, until another submenu opens or the menu closes."

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
      data-keep-submenus={bool(@keep_submenus)}
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
        class="popper-root fixed left-0 top-0 w-max"
        popover="manual"
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

  attr :count, :integer,
    default: nil,
    doc:
      "How many of its checkboxes are checked, in a round badge on the item; hidden at 0. The browser keeps it up to date as they are ticked."

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
            "h-9 w-full gap-2.5 pr-3 font-inter text-sm font-normal tracking-normal text-slate-600 dark:text-navy-100",
            "text-left",
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
        <span
          data-submenu-count
          hidden={@count in [nil, 0]}
          class="inline-flex h-4.5 min-w-4.5 items-center justify-center rounded-full bg-primary px-1.5 font-inter text-tiny-plus text-white dark:bg-accent"
        >
          {@count}
        </span>
        <.glyph name={:chevron_right} class="size-4 shrink-0 text-slate-400 dark:text-navy-300" />
      </button>
      <div class="linea-submenu" data-submenu-panel>
        <div
          id={"#{@id}-menu"}
          class={
            merge([
              "w-max min-w-40 rounded-md border border-slate-150 bg-white py-1.5 font-inter shadow-[0_10px_30px_-8px_rgb(48_46_56/0.18)] dark:border-navy-500 dark:bg-navy-700 dark:shadow-soft-dark",
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

  @choice_item "group flex h-9 w-full items-center gap-2.5 px-3 text-left font-inter text-sm font-normal text-slate-600 outline-hidden transition-colors hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:text-navy-100 dark:hover:bg-navy-600 dark:hover:text-navy-50 dark:focus:bg-navy-600 dark:focus:text-navy-50"

  @check_box "flex size-4 shrink-0 items-center justify-center rounded border border-slate-400 text-white transition-colors group-aria-checked:border-primary group-aria-checked:bg-primary dark:border-navy-300 dark:group-aria-checked:border-accent dark:group-aria-checked:bg-accent"

  @radio_box "size-4 shrink-0 rounded-full border border-slate-400 bg-white transition-all group-aria-checked:border-[5px] group-aria-checked:border-primary dark:border-navy-300 dark:bg-navy-700 dark:group-aria-checked:border-accent"

  @doc """
  A checkbox item (`menuitemcheckbox`). Choosing it flips it and leaves the menu open, for filters. With a
  `name` it is a real input too (`value` is what a checked one submits), so a surrounding `phx-change`
  hears it and `phx-submit` gets the checked ones; without one, give it `phx-click` and `phx-value-*`.

      <.dropdown_checkbox name="filter[status][]" value="paid" checked={"paid" in @status} count={3}>
        Paid
      </.dropdown_checkbox>
  """
  attr :checked, :boolean,
    default: false,
    doc:
      "The checked state. The server wins when it changes it; a patch that did not change it keeps the browser's choice."

  attr :name, :string, default: nil, doc: "The name of the input the item submits as."
  attr :value, :string, default: "true", doc: "What a checked item submits."

  attr :id, :string,
    default: nil,
    doc: "Of the input; derived from `name` and `value` when not given."

  attr :count, :any,
    default: nil,
    doc: "A muted number or text at the end (results for this option)."

  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)
  slot :inner_block, required: true

  def dropdown_checkbox(assigns) do
    assigns
    |> assign(:role, "menuitemcheckbox")
    |> assign(:box, @check_box)
    |> render_choice()
  end

  @doc """
  A radio item (`menuitemradio`): choosing it checks it and unchecks the other radios of its group (the ones
  with the same `name` in the same menu). The menu stays open.

      <.dropdown_radio name="filter[sort]" value="recent" checked={@sort == "recent"}>Most recent</.dropdown_radio>
  """
  attr :checked, :boolean, default: false, doc: "The checked state; as in `dropdown_checkbox/1`."
  attr :name, :string, default: nil, doc: "The group of the radio and the name of its input."
  attr :value, :string, default: "true", doc: "What the checked radio submits."

  attr :id, :string,
    default: nil,
    doc: "Of the input; derived from `name` and `value` when not given."

  attr :count, :any, default: nil, doc: "A muted number or text at the end."
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)
  slot :inner_block, required: true

  def dropdown_radio(assigns) do
    assigns
    |> assign(:role, "menuitemradio")
    |> assign(:box, @radio_box)
    |> render_choice()
  end

  defp render_choice(assigns) do
    assigns =
      assign(assigns,
        input_id: assigns.id || "choice-#{:erlang.phash2({assigns.name, assigns.value})}",
        input_type: (assigns.role == "menuitemradio" && "radio") || "checkbox",
        item_class:
          merge([
            @choice_item,
            assigns.disabled && "pointer-events-none opacity-60",
            assigns.class
          ])
      )

    ~H"""
    <div class="contents" role="none">
      <input
        :if={@name}
        type={@input_type}
        id={@input_id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        tabindex="-1"
        aria-hidden="true"
        class="sr-only"
        phx-update="ignore"
        data-choice-input
      />
      <button
        type="button"
        role={@role}
        class={@item_class}
        tabindex="-1"
        aria-checked={bool(@checked)}
        aria-disabled={@disabled && "true"}
        disabled={@disabled}
        data-server-checked={bool(@checked)}
        data-group={@name}
        phx-mounted={JS.ignore_attributes(["aria-checked"])}
        {@rest}
      >
        <span class={@box}>
          <.glyph
            :if={@role == "menuitemcheckbox"}
            name={:check}
            class="size-3 opacity-0 group-aria-checked:opacity-100"
          />
        </span>
        <span class="flex-1">{render_slot(@inner_block)}</span>
        <span :if={@count != nil} class="ml-4 font-inter text-xs text-slate-400 dark:text-navy-300">
          {@count}
        </span>
      </button>
    </div>
    """
  end

  @doc "A small caption over a group of items (\"Sort by\"), as in a filter menu."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_label(assigns) do
    ~H"""
    <div
      role="presentation"
      class={
        merge([
          "px-3 pt-2 pb-1 font-inter text-tiny-plus font-semibold tracking-widest text-slate-400 uppercase dark:text-navy-300",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The end of a filter menu: a Clear button, which unchecks every checkbox item (and fires their `phx-change`),
  and an Apply button, which closes the menu. Without `on_apply` the button submits the surrounding form;
  with one it runs that event (or `%JS{}`) instead.

      <.dropdown_footer locale="pt_BR" apply_count={@pending} on_apply="apply_filters" />

  The buttons are menu items, so the arrow keys reach them.
  """
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :clear_label, :string, default: nil, doc: "\"Clear\" (\"Limpar\" in pt_BR) by default."
  attr :apply_label, :string, default: nil, doc: "\"Apply\" (\"Aplicar\" in pt_BR) by default."
  attr :apply_count, :integer, default: nil, doc: "Written after Apply as `Apply (3)`."

  attr :on_clear, :any,
    default: nil,
    doc: "An event name or a `%JS{}` run after the checkboxes are cleared."

  attr :on_apply, :any,
    default: nil,
    doc: "An event name or a `%JS{}`; without it Apply submits the form."

  attr :close_on_apply, :boolean, default: true

  attr :target, :any,
    default: nil,
    doc: "The `phx-target` of `on_clear` and `on_apply` when they are event names."

  attr :class, :any, default: nil
  attr :rest, :global

  def dropdown_footer(assigns) do
    text = Strings.table(assigns.locale)

    assigns =
      assign(assigns,
        clear: assigns.clear_label || text.filter_clear,
        apply: assigns.apply_label || text.filter_apply,
        clear_js: action_js(assigns.on_clear, assigns.target),
        apply_js: action_js(assigns.on_apply, assigns.target),
        apply_suffix: (assigns.apply_count && " (#{assigns.apply_count})") || "",
        apply_type: (assigns.on_apply == nil && "submit") || "button"
      )

    ~H"""
    <div
      role="none"
      class={
        merge([
          "mt-1.5 flex justify-between gap-2 border-t border-slate-150 px-2.5 pt-2 pb-0.5 dark:border-navy-500",
          @class
        ])
      }
      {@rest}
    >
      <Button.button
        size="sm"
        variant="flat"
        role="menuitem"
        tabindex="-1"
        data-menu-action="clear"
        phx-click={@clear_js}
      >
        {@clear}
      </Button.button>
      <Button.button
        size="sm"
        color="primary"
        type={@apply_type}
        role="menuitem"
        tabindex="-1"
        data-menu-action="apply"
        data-close-on-apply={bool(@close_on_apply)}
        phx-click={@apply_js}
      >
        {@apply}{@apply_suffix}
      </Button.button>
    </div>
    """
  end

  defp action_js(nil, _target), do: nil
  defp action_js(%JS{} = js, _target), do: js
  defp action_js(event, nil), do: JS.push(event)
  defp action_js(event, target), do: JS.push(event, target: target)
end
