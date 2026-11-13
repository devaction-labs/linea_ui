defmodule LineaUI.Components.LandingNav do
  @moduledoc """
  The marketing-site top bar of the canvas "Navbar" board (the "Landing" examples): the logo on the left, the links
  in the center (one may open a mega menu), Entrar and the primary button on the right.

      <.landing_nav id="site-nav" brand={%{name: "Linea", logo: "L", navigate: ~p"/"}}>
        <:link label="Produto">
          <.landing_mega>
            <.landing_feature icon="huge-kanban" title="Projetos" description="Kanban, prazos e responsáveis" navigate={~p"/projetos"} />
            <.landing_feature icon="huge-shield-01" title="Segurança" description="2FA, sessões e auditoria" navigate={~p"/seguranca"} />
            <:side>
              <.landing_mega_side eyebrow="Novidade" title="Projetos com kanban" thumb link_label="Ver novidades" navigate={~p"/novidades"}>
                Arraste tarefas entre colunas.
              </.landing_mega_side>
            </:side>
          </.landing_mega>
        </:link>
        <:link label="Preços" navigate={~p"/precos"} active />
        <:link label="Docs" href="https://docs.example.com" />
        <:actions>
          <.landing_login navigate={~p"/entrar"}>Entrar</.landing_login>
          <.landing_cta navigate={~p"/cadastro"} icon="huge-arrow-right-01">Começar grátis</.landing_cta>
        </:actions>
      </.landing_nav>

  ## Variants

    * `default` - the classic bar, in the page flow.
    * `float` - a detached, centered pill of frosted glass (wrapped in `.sg-lp-floatwrap`).
    * `clear` - transparent over a hero image (white text); with `sticky` it turns solid, with border and shadow,
      once the page scrolls. Put the bar over the hero yourself (a negative margin on the hero, say).
    * `mobile` - the phone layout at any width: logo, Entrar and the menu button.

  `sticky` pins the bar to the top of the page (`position: sticky`) and mounts the `LineaUI.LandingNav` hook (register
  the kit's hooks), which sets `data-stuck` on the bar after `stuck_after` px of scroll (default 8); the CSS makes
  the bar solid while it is set. The server never resets that attribute.

  ## Links and the mega menu

  A `:link` with `href`, `navigate` or `patch` is a link (`active` marks the current page with `aria-current`). A
  `:link` with inner content is a trigger instead: a button with `aria-expanded` and `aria-controls` that opens the
  content as the mega menu under the bar, built with `Phoenix.LiveView.JS` (no round trip). A click outside the
  bar, or Escape, closes it. Fill it with `landing_mega/1`, `landing_feature/1` and `landing_mega_side/1`.

  ## Phone

  Below 768px (or with `variant="mobile"`) the links and the primary button leave the bar and a menu button
  (`.sg-ib`) appears; it opens a panel under the bar listing every `:link` as a row (a trigger row goes to its
  `href`, `"#"` when it has none) and the `:actions` again, stacked and full width. So `:actions` is rendered twice:
  do not put an `id` on what is inside it. The mega menu is not shown on a phone.

  ## Announcement

  `landing_announcement/1` is the thin strip to put above the bar. The slot of the actions is `:actions`
  (not `:end`, which is a reserved word).

  The brand is the `brand` map or, for something else, the `:logo` slot.

  Styles: `canvas-landing-nav.css` (`sg-lp-*`).
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [icon: 1, glyph: 1]

  attr :id, :string, required: true, doc: "The root id; the menu toggles and the hook use it."
  attr :variant, :string, default: "default", values: ~w(default float clear mobile)

  attr :sticky, :boolean,
    default: false,
    doc: "Pin to the top and mount the scroll hook (`data-stuck`)."

  attr :stuck_after, :integer, default: 8, doc: "The scroll in px after which the bar is stuck."

  attr :brand, :map,
    default: nil,
    doc:
      "`%{name:, logo:, src:, href:, navigate:}`: `logo` is a letter in the box, `src` an image."

  attr :label, :string, default: "Main", doc: "The accessible name of the links."
  attr :menu_label, :string, default: "Menu", doc: "The accessible name of the phone menu button."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :logo, doc: "The brand, instead of the `brand` map."

  slot :link, doc: "A link; with inner content, a trigger of the mega menu." do
    attr :label, :string, required: true
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
  end

  slot :actions, doc: "Entrar and the primary button (`landing_login/1`, `landing_cta/1`)."

  def landing_nav(assigns) do
    assigns =
      assigns
      |> assign_derived(:items, [:link], fn -> Enum.with_index(assigns.link, 1) end)
      |> assign_derived(:bar_class, [:class], fn -> merge(["sg-lp-bar", assigns.class]) end)
      |> assign_derived(:nav_class, [:variant], fn ->
        merge(["sg-lp-nb", nav_variant(assigns.variant)])
      end)
      |> assign_derived(:wrap_class, [:variant], fn ->
        assigns.variant == "float" && "sg-lp-floatwrap"
      end)
      |> assign_derived(:close, [:id], fn -> close_js(assigns.id) end)
      |> assign_derived(:mmenu, [:id], fn -> "#{assigns.id}-mmenu" end)
      |> assign_derived(:menu_toggle, [:id], fn -> menu_toggle_js(assigns.id) end)
      |> assign_derived(:hook, [:sticky], fn -> assigns.sticky && "LineaUI.LandingNav" end)

    ~H"""
    <div
      id={@id}
      class={@bar_class}
      data-variant={@variant}
      data-sticky={@sticky && ""}
      data-stuck-after={@sticky && @stuck_after}
      phx-hook={@hook}
      phx-mounted='[["ignore_attrs",{"attrs":["data-stuck"]}]]'
      phx-click-away={@close}
      phx-window-keydown={@close}
      phx-key="Escape"
      {@rest}
    >
      <div class={@wrap_class}>
        <header class={@nav_class}>
          {render_slot(@logo)}
          <.brand :if={@logo == [] && @brand} brand={@brand} />
          <nav class="sg-lp-links" aria-label={@label}>
            <%= for {link, i} <- @items do %>
              <button
                :if={link.inner_block}
                id={"#{@id}-trigger-#{i}"}
                type="button"
                aria-haspopup="true"
                aria-expanded="false"
                aria-controls={"#{@id}-mega-#{i}"}
                phx-click={mega_toggle_js(@id, i)}
              >
                {link.label}<.glyph name={:chevron_down} class="sg-lp-i" />
              </button>
              <.item_link
                :if={!link.inner_block}
                href={link[:href] || "#"}
                navigate={link[:navigate]}
                patch={link[:patch]}
                aria-current={link[:active] && "page"}
              >
                {link.label}
              </.item_link>
            <% end %>
          </nav>
          <div class="sg-nb-end">
            {render_slot(@actions)}
            <button
              type="button"
              class="sg-ib sm sg-lp-menubtn"
              aria-label={@menu_label}
              aria-expanded="false"
              aria-controls={@mmenu}
              phx-click={@menu_toggle}
            >
              <.icon name="huge-menu-01" class="sg-lp-i sg-lp-i-open" />
              <.icon name="huge-cancel-01" class="sg-lp-i sg-lp-i-close" />
            </button>
          </div>
        </header>
      </div>
      <div
        :for={{link, i} <- @items}
        :if={link.inner_block}
        id={"#{@id}-mega-#{i}"}
        class="sg-lp-mega"
        style="display: none"
      >
        {render_slot(link)}
      </div>
      <div id={@mmenu} class="sg-lp-mmenu" style="display: none">
        <.item_link
          :for={{link, _i} <- @items}
          href={link[:href] || "#"}
          navigate={link[:navigate]}
          patch={link[:patch]}
          class="sg-lp-mi"
          aria-current={link[:active] && "page"}
        >
          {link.label}<.glyph :if={link.inner_block} name={:chevron_down} class="sg-lp-i" /><.glyph
            :if={!link.inner_block}
            name={:chevron_right}
            class="sg-lp-i"
          />
        </.item_link>
        <div :if={@actions != []} class="sg-lp-mmenu-end">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  defp nav_variant("float"), do: "float"
  defp nav_variant("clear"), do: "clear"
  defp nav_variant("mobile"), do: "mob"
  defp nav_variant(_variant), do: nil

  # Closes every mega menu and the phone menu (a click outside the bar, Escape).
  defp close_js(id) do
    JS.hide(to: "##{id} .sg-lp-mega")
    |> JS.remove_class("open", to: "##{id} .sg-lp-links button.open")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id} .sg-lp-links button")
    |> JS.hide(to: "##{id}-mmenu")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id} .sg-lp-menubtn")
  end

  # Opens (or closes) one mega menu and closes the others.
  defp mega_toggle_js(id, i) do
    trigger = "##{id}-trigger-#{i}"
    others = "##{id} .sg-lp-links button:not(#{trigger})"

    JS.hide(to: "##{id} .sg-lp-mega:not(##{id}-mega-#{i})")
    |> JS.remove_class("open", to: others)
    |> JS.set_attribute({"aria-expanded", "false"}, to: others)
    |> JS.toggle(to: "##{id}-mega-#{i}", display: "flex")
    |> JS.toggle_class("open", to: trigger)
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: trigger)
  end

  defp menu_toggle_js(id) do
    JS.toggle(to: "##{id}-mmenu", display: "flex")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id} .sg-lp-menubtn")
  end

  attr :brand, :map, required: true

  defp brand(assigns) do
    ~H"""
    <.item_link
      href={@brand[:href] || (!@brand[:navigate] && "/") || nil}
      navigate={@brand[:navigate]}
      class="sg-lp-brand"
    >
      <img :if={@brand[:src]} src={@brand[:src]} alt="" />
      <span :if={!@brand[:src] && @brand[:logo]} class="sg-nb-logo">{@brand[:logo]}</span>
      <b :if={@brand[:name]} class="sg-nb-brand">{@brand[:name]}</b>
    </.item_link>
    """
  end

  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  defp item_link(%{navigate: to} = assigns) when is_binary(to) do
    ~H"""
    <.link navigate={@navigate} class={@class} {@rest}>{render_slot(@inner_block)}</.link>
    """
  end

  defp item_link(%{patch: to} = assigns) when is_binary(to) do
    ~H"""
    <.link patch={@patch} class={@class} {@rest}>{render_slot(@inner_block)}</.link>
    """
  end

  defp item_link(assigns) do
    ~H"""
    <.link href={@href} class={@class} {@rest}>{render_slot(@inner_block)}</.link>
    """
  end

  @doc """
  The "Entrar" link of the bar.

      <.landing_login navigate={~p"/entrar"}>Entrar</.landing_login>
  """
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def landing_login(assigns) do
    assigns =
      assign_derived(assigns, :classes, [:class], fn -> merge(["sg-lp-login", assigns.class]) end)

    ~H"""
    <.item_link href={@href} navigate={@navigate} patch={@patch} class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </.item_link>
    """
  end

  @doc """
  The primary button of the bar. A link when it has `href`, `navigate` or `patch`, else a `button`.
  `size="lg"` is the hero button, `block` makes it full width, `icon` a Hugeicons name after the text.

      <.landing_cta navigate={~p"/cadastro"} icon="huge-arrow-right-01">Começar grátis</.landing_cta>
  """
  attr :size, :string, default: "md", values: ~w(md lg)
  attr :block, :boolean, default: false
  attr :icon, :string, default: nil
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value phx-click)
  slot :inner_block, required: true

  def landing_cta(assigns) do
    assigns =
      assigns
      |> assign_derived(:classes, [:class, :size, :block], fn ->
        merge([
          "sg-lp-cta",
          assigns.size == "lg" && "lg",
          assigns.block && "block",
          assigns.class
        ])
      end)
      |> assign_derived(:linked, [:href, :navigate, :patch], fn ->
        Enum.any?([assigns.href, assigns.navigate, assigns.patch])
      end)

    ~H"""
    <.item_link
      :if={@linked}
      href={@href || "#"}
      navigate={@navigate}
      patch={@patch}
      class={@classes}
      {@rest}
    >
      {render_slot(@inner_block)}<.icon :if={@icon} name={@icon} class="sg-lp-i" />
    </.item_link>
    <button :if={!@linked} type="button" class={@classes} {@rest}>
      {render_slot(@inner_block)}<.icon :if={@icon} name={@icon} class="sg-lp-i" />
    </button>
    """
  end

  @doc """
  The mega menu content (inside a `:link` of `landing_nav/1`): the features in two columns and, optionally, a
  highlighted panel on the side.

      <.landing_mega>
        <.landing_feature icon="huge-kanban" title="Projetos" description="Kanban" navigate={~p"/projetos"} />
        <:side><.landing_mega_side title="Novidade" /></:side>
      </.landing_mega>
  """
  slot :inner_block, required: true, doc: "The `landing_feature/1` items."
  slot :side, doc: "A `landing_mega_side/1`."

  def landing_mega(assigns) do
    ~H"""
    <div class="sg-lp-grid">{render_slot(@inner_block)}</div>
    {render_slot(@side)}
    """
  end

  @doc """
  One feature of the mega menu: an icon in a box, the title and a line of description.
  """
  attr :icon, :string, default: nil, doc: "A Hugeicons name."
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def landing_feature(assigns) do
    assigns =
      assign_derived(assigns, :classes, [:class], fn -> merge(["sg-lp-feat", assigns.class]) end)

    ~H"""
    <.item_link href={@href} navigate={@navigate} patch={@patch} class={@classes} {@rest}>
      <span :if={@icon} class="ic"><.icon name={@icon} class="sg-lp-i" /></span>
      <span class="col">
        <b>{@title}</b>
        <span :if={@description}>{@description}</span>
      </span>
    </.item_link>
    """
  end

  @doc """
  The highlighted panel beside the features: an eyebrow, the title, the text (inner content), an optional thumbnail
  and a link.
  """
  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :thumb, :boolean, default: false, doc: "Draw the small placeholder picture."
  attr :link_label, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def landing_mega_side(assigns) do
    assigns =
      assign_derived(assigns, :classes, [:class], fn ->
        merge(["sg-lp-megaside", assigns.class])
      end)

    ~H"""
    <div class={@classes} {@rest}>
      <span :if={@eyebrow} class="sg-lp-eb">{@eyebrow}</span>
      <b>{@title}</b>
      <span :if={@inner_block != []}>{render_slot(@inner_block)}</span>
      <div :if={@thumb} class="sg-lp-thumb" aria-hidden="true"><i></i><i></i><i></i><i></i></div>
      <.item_link :if={@link_label} href={@href} navigate={@navigate}>
        {@link_label}<.icon name="huge-arrow-right-01" class="sg-lp-i" />
      </.item_link>
    </div>
    """
  end

  @doc """
  The thin announcement strip above the bar: an eyebrow tag, the text (inner content), a link and a close button
  that hides it (`JS.hide`, no round trip) when `dismissible`.

      <.landing_announcement id="ann" eyebrow="Novo" link_label="Ver novidades" navigate={~p"/novidades"}>
        Projetos com kanban chegaram ao Linea
      </.landing_announcement>
  """
  attr :id, :string, required: true
  attr :eyebrow, :string, default: nil
  attr :link_label, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :dismissible, :boolean, default: true
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def landing_announcement(assigns) do
    assigns =
      assigns
      |> assign_derived(:classes, [:class], fn -> merge(["sg-lp-ann", assigns.class]) end)
      |> assign_derived(:hide, [:id], fn -> JS.hide(to: "##{assigns.id}") end)

    ~H"""
    <div id={@id} class={@classes} {@rest}>
      <span :if={@eyebrow} class="sg-lp-eb light">{@eyebrow}</span>
      {render_slot(@inner_block)}
      <.item_link :if={@link_label} href={@href} navigate={@navigate}>
        {@link_label}<.icon name="huge-arrow-right-01" class="sg-lp-i" />
      </.item_link>
      <button :if={@dismissible} type="button" aria-label={@close_label} phx-click={@hide}>
        <.icon name="huge-cancel-01" class="sg-lp-i" />
      </button>
    </div>
    """
  end
end
