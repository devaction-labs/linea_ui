defmodule LineaUI.Components.SideMenu do
  @moduledoc """
  The sidebar and the top bar of the `demo1` layout of `app_shell/1`: a 280px sidebar that collapses to an 80px
  rail (and opens again while the pointer is over it), a menu with section headings, links and groups that
  open on click, and the fixed header.

      <.app_shell id="shell" layout="demo1">
        <:sidebar>
          <.shell_sidebar shell="shell">
            <:brand><img src={~p"/images/logo.svg"} alt="Acme" /></:brand>
            <.side_menu_heading>Overview</.side_menu_heading>
            <.side_menu_link navigate={~p"/"} active><:icon><.icon name="home" /></:icon>Today</.side_menu_link>
            <.side_menu_group label="Account" open>
              <:icon><.icon name="user" /></:icon>
              <.side_menu_sublink navigate={~p"/profile"} active>Profile</.side_menu_sublink>
            </.side_menu_group>
          </.shell_sidebar>
        </:sidebar>
        <:header>
          <.shell_header shell="shell">
            <:nav><.shell_header_link navigate={~p"/"} active>Home</.shell_header_link></:nav>
            <:actions><.avatar name="Ana" /></:actions>
          </.shell_header>
        </:header>
        …
      </.app_shell>

  The collapsed state is the `data-collapsed` attribute of the `app_shell/1` element, flipped by the button on the
  edge of the sidebar with `Phoenix.LiveView.JS`.
  """

  use LineaUI.Component

  @link "flex w-full cursor-pointer items-center gap-2.5 rounded-lg border border-transparent px-2.5 py-1.5 outline-none focus-visible:ring-2 focus-visible:ring-primary/50 hover:bg-slate-950/5 dark:hover:bg-white/5"
  @active "bg-slate-950/7 border-slate-200 dark:bg-white/7 dark:border-navy-450"
  @label "truncate text-sm font-medium text-slate-950 group-data-[collapsed=true]/shell:not-group-hover/side:hidden dark:text-navy-50"
  @icon "flex w-5 shrink-0 items-start text-slate-500 dark:text-navy-300 [&>svg]:size-5 [&>span]:size-5"

  @doc """
  The sidebar: the brand and the collapse button on top, the menu below, scrolling on its own.

      <.shell_sidebar shell="shell" label="Main menu">…</.shell_sidebar>
  """
  attr :id, :string, default: "shell-sidebar"

  attr :shell, :string,
    default: "app-shell",
    doc: "The id of the `app_shell/1` this sidebar belongs to."

  attr :label, :string, default: "Main menu", doc: "The accessible name of the menu."
  attr :toggle_label, :string, default: "Collapse the menu"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :brand, doc: "The logo, shown at full width."

  slot :brand_small,
    doc: "The logo of the collapsed rail; the first letter of nothing when absent."

  slot :inner_block, required: true, doc: "The menu: headings, links and groups."

  def shell_sidebar(assigns) do
    ~H"""
    <aside
      id={@id}
      aria-label={@label}
      phx-hook="LineaUI.ShellSidebar"
      phx-mounted={JS.ignore_attributes(["data-animating"])}
      class={
        merge([
          "group/side fixed inset-y-0 start-0 z-20 hidden w-[280px] shrink-0 flex-col items-stretch border-e border-slate-200 bg-white transition-[width] duration-300 ease-in-out lg:flex dark:border-navy-450 dark:bg-navy-900",
          "group-data-[mobile=true]/shell:flex data-[animating=true]:pointer-events-none group-data-[collapsed=true]/shell:w-[80px] group-data-[collapsed=true]/shell:not-data-[animating=true]:hover:w-[280px]",
          @class
        ])
      }
      {@rest}
    >
      <div class="relative flex h-[70px] shrink-0 items-center justify-between px-6">
        <div class="min-w-0 overflow-hidden">
          <div class="group-data-[collapsed=true]/shell:not-group-hover/side:hidden">
            {render_slot(@brand)}
          </div>
          <div class="hidden group-data-[collapsed=true]/shell:not-group-hover/side:flex">
            {render_slot(@brand_small) || render_slot(@brand)}
          </div>
        </div>
        <button
          type="button"
          class="absolute start-full top-1/2 z-40 hidden size-[30px] -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-md border border-slate-200 bg-white text-slate-500 shadow-xs outline-none hover:bg-slate-100 hover:text-slate-950 focus-visible:ring-2 focus-visible:ring-primary/50 lg:inline-flex dark:border-navy-450 dark:bg-navy-900 dark:text-navy-300 dark:hover:bg-navy-600 dark:hover:text-navy-50"
          aria-label={@toggle_label}
          aria-controls={@shell}
          data-shell-toggle
          phx-click={JS.toggle_attribute({"data-collapsed", "true", "false"}, to: "#" <> @shell)}
        >
          <span
            class="ki-filled-black-left-line size-4 transition-all duration-300 group-data-[collapsed=true]/shell:rotate-180"
            aria-hidden="true"
          ></span>
        </button>
      </div>
      <nav
        data-shell-scroll
        class="flex min-h-0 grow flex-col gap-1 overflow-y-auto overflow-x-hidden py-5 ps-5 pe-3"
      >
        {render_slot(@inner_block)}
      </nav>
    </aside>
    """
  end

  @doc """
  A section title of the menu, in capitals; hidden in the rail.

      <.side_menu_heading>Account</.side_menu_heading>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def side_menu_heading(assigns) do
    ~H"""
    <div
      class={
        merge([
          "px-2.5 pt-2.5 pb-px text-xs font-medium text-slate-500 uppercase dark:text-navy-300",
          @class
        ])
      }
      {@rest}
    >
      <span class="group-data-[collapsed=true]/shell:not-group-hover/side:hidden">
        {render_slot(@inner_block)}
      </span>
      <span
        class="hidden text-center group-data-[collapsed=true]/shell:not-group-hover/side:block"
        aria-hidden="true"
      >
        ···
      </span>
    </div>
    """
  end

  @doc """
  A page of the menu: the icon and the label, with an optional tag such as "Soon". The link of the current page is
  `active`.

      <.side_menu_link navigate={~p"/orders"} active><:icon><.icon name="cart" /></:icon>Orders</.side_menu_link>
      <.side_menu_link href="#" tag="Soon">…</.side_menu_link>
  """
  attr :active, :boolean, default: false
  attr :tag, :string, default: nil, doc: "A small grey label at the end, such as `Soon`."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download target rel)
  slot :icon
  slot :inner_block, required: true

  def side_menu_link(assigns) do
    ~H"""
    <.link
      class={merge([link(), @active && active(), @class])}
      aria-current={@active && "page"}
      {@rest}
    >
      <span :if={@icon != []} class={icon()} aria-hidden="true">{render_slot(@icon)}</span>
      <span class={label()}>{render_slot(@inner_block)}</span>
      <span
        :if={@tag}
        class="ms-auto rounded-md bg-slate-100 px-1.5 py-0.5 text-xs font-medium text-slate-500 group-data-[collapsed=true]/shell:not-group-hover/side:hidden dark:bg-navy-600 dark:text-navy-300"
      >
        {@tag}
      </span>
    </.link>
    """
  end

  @doc """
  A group that opens on click and holds `side_menu_sublink/1` items or further groups. The branch of the current
  page is `open`.

      <.side_menu_group label="Account" open>
        <:icon><.icon name="user" /></:icon>
        <.side_menu_sublink navigate={~p"/profile"} active>Profile</.side_menu_sublink>
      </.side_menu_group>
  """
  attr :label, :string, required: true
  attr :open, :boolean, default: false

  attr :depth, :integer,
    default: 0,
    doc: "How deep the group sits (0 to 3), so its plus and minus follow its own state."

  attr :nested, :boolean,
    default: false,
    doc: "A group inside a group: no icon, the smaller text of a sub-item."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon
  slot :inner_block, required: true

  def side_menu_group(assigns) do
    ~H"""
    <details class={merge([depth_group(@depth), @class])} open={@open} {@rest}>
      <summary class={
        merge([
          link(),
          "list-none [&::-webkit-details-marker]:hidden",
          @nested && "py-2 ps-[31px]"
        ])
      }>
        <span :if={@icon != []} class={icon()} aria-hidden="true">{render_slot(@icon)}</span>
        <span class={
          merge([
            label(),
            @nested && "text-sm font-normal"
          ])
        }>
          {@label}
        </span>
        <span
          class="-me-2.5 ms-1 flex w-5 shrink-0 justify-end text-slate-500 group-data-[collapsed=true]/shell:not-group-hover/side:hidden dark:text-navy-300"
          aria-hidden="true"
        >
          <span class={["ki-filled-plus size-3.5", depth_plus(@depth)]}></span>
          <span class={["ki-filled-minus hidden size-3.5", depth_minus(@depth)]}></span>
        </span>
      </summary>
      <div class={[
        "relative mt-1 flex flex-col gap-1 ps-2.5 before:absolute before:inset-y-0 before:start-5 before:border-s before:border-slate-200 group-data-[collapsed=true]/shell:not-group-hover/side:hidden dark:before:border-navy-450",
        @nested && "ms-[11px] [&_a>span:first-child]:hidden [&_a]:gap-0 [&_a]:ps-[21px]"
      ]}>
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end

  @doc """
  A page inside a `side_menu_group/1`, with the bullet on the vertical line. The page open now is `active` (the
  bullet and the label turn to the action color).

      <.side_menu_sublink navigate={~p"/profile"} active>Profile</.side_menu_sublink>
  """
  attr :active, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download target rel)
  slot :inner_block, required: true

  def side_menu_sublink(assigns) do
    ~H"""
    <.link
      class={
        merge([
          "group/sub flex w-full items-center gap-3.5 rounded-lg border border-transparent px-2.5 py-2 outline-none focus-visible:ring-2 focus-visible:ring-primary/50 hover:bg-slate-950/5 dark:hover:bg-white/5",
          @active && "bg-slate-950/5 dark:border-navy-450 dark:bg-white/5",
          @class
        ])
      }
      aria-current={@active && "page"}
      {@rest}
    >
      <span class={[
        "relative -start-[3px] flex w-1.5 shrink-0 before:absolute before:top-0 before:size-1.5 before:-translate-y-1/2 before:rounded-full group-hover/sub:before:bg-primary",
        @active && "before:bg-primary"
      ]}></span>
      <span class={[
        "truncate text-[13px] leading-5 group-hover/sub:text-primary",
        @active && "font-semibold text-primary",
        !@active && "font-normal text-slate-950 dark:text-navy-50"
      ]}>
        {render_slot(@inner_block)}
      </span>
    </.link>
    """
  end

  @doc """
  The fixed header of the `demo1` layout: the hamburger on small screens, the navigation, and the actions at
  the end. It follows the width of the sidebar.

      <.shell_header shell="shell">
        <:brand><img src={~p"/images/mark.svg"} alt="Acme" /></:brand>
        <:nav><.shell_header_link navigate={~p"/"} active>Home</.shell_header_link></:nav>
        <:actions><.avatar name="Ana" /></:actions>
      </.shell_header>
  """
  attr :id, :string, default: "shell-header"
  attr :shell, :string, default: "app-shell", doc: "The id of the `app_shell/1`."
  attr :menu_label, :string, default: "Open the menu"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :brand, doc: "The mark shown beside the hamburger below `lg`."
  slot :nav, doc: "`shell_header_link/1` items, or a breadcrumb."
  slot :actions, doc: "Buttons and the person, at the end."

  def shell_header(assigns) do
    ~H"""
    <header
      id={@id}
      phx-hook="LineaUI.Sticky"
      phx-mounted={JS.ignore_attributes(["data-stuck", "class"])}
      data-offset="0"
      data-stuck-class="border-b border-slate-200 dark:border-navy-450"
      class={
        merge([
          "fixed inset-x-0 top-0 z-10 flex h-[60px] items-stretch bg-white transition-[inset] duration-300 lg:start-[280px] lg:h-[70px] group-data-[collapsed=true]/shell:lg:start-[80px] dark:bg-navy-900",
          @class
        ])
      }
      {@rest}
    >
      <div class="flex w-full items-stretch justify-between gap-4 px-4 lg:px-7.5">
        <div class="flex items-center gap-2.5 lg:hidden">
          {render_slot(@brand)}
          <button
            type="button"
            class="inline-flex size-9 items-center justify-center rounded-md text-slate-500 outline-none hover:bg-slate-100 focus-visible:ring-2 focus-visible:ring-primary/50 dark:text-navy-300 dark:hover:bg-navy-600"
            aria-label={@menu_label}
            aria-controls={@shell}
            phx-click={JS.toggle_attribute({"data-mobile", "true", "false"}, to: "#" <> @shell)}
          >
            <span class="ki-filled-burger-menu-2 size-5" aria-hidden="true"></span>
          </button>
        </div>
        <nav class="hidden items-stretch gap-7.5 lg:flex">{render_slot(@nav)}</nav>
        <div class="flex items-center gap-2 lg:gap-3.5">{render_slot(@actions)}</div>
      </div>
    </header>
    """
  end

  @doc """
  A link of the header navigation; the current one is `active`.

      <.shell_header_link navigate={~p"/"} active>Home</.shell_header_link>
  """
  attr :active, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download target rel)
  slot :inner_block, required: true

  def shell_header_link(assigns) do
    ~H"""
    <.link
      class={
        merge([
          "flex items-center text-sm font-medium text-nowrap text-slate-950 outline-none hover:text-primary focus-visible:text-primary dark:text-navy-50",
          @active && "font-semibold",
          @class
        ])
      }
      aria-current={@active && "page"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp depth_group(0), do: "group/g0"
  defp depth_group(1), do: "group/g1"
  defp depth_group(2), do: "group/g2"
  defp depth_group(_depth), do: "group/g3"

  defp depth_plus(0), do: "group-open/g0:hidden"
  defp depth_plus(1), do: "group-open/g1:hidden"
  defp depth_plus(2), do: "group-open/g2:hidden"
  defp depth_plus(_depth), do: "group-open/g3:hidden"

  defp depth_minus(0), do: "group-open/g0:block"
  defp depth_minus(1), do: "group-open/g1:block"
  defp depth_minus(2), do: "group-open/g2:block"
  defp depth_minus(_depth), do: "group-open/g3:block"

  defp link, do: @link
  defp active, do: @active
  defp label, do: @label
  defp icon, do: @icon
end
