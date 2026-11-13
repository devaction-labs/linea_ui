defmodule LineaUI.Components.ActionMenu do
  @moduledoc """
  The actions of one item (a table row, a card, a message), opened by a "⋯" button, as the design canvas's
  ActionMenu. Unlike the generic `LineaUI.Components.Dropdown` it has a look of its own so it is not mistaken for the
  content behind it: a raised background, a stronger outline and a shadow, in the dark theme too. While it is open
  the button looks pressed and the item's row is tinted, so it is clear whose actions these are.

      <.action_menu id={"actions-" <> company.id} label={"Actions of " <> company.name}>
        <:title>{company.name}</:title>
        <.action_menu_item navigate={~p"/companies/\#{company.id}"} icon="huge-view" kbd="↵">
          Open company
        </.action_menu_item>
        <.action_menu_item phx-click="members" phx-value-id={company.id} icon="huge-user-multiple" kbd="M">
          Members
        </.action_menu_item>
        <.action_menu_separator />
        <.action_menu_item
          phx-click="invite"
          icon="huge-mail-01"
          disabled
          hint="Invite accepted on 02/18"
        >
          Resend invite
        </.action_menu_item>
        <.action_menu_item phx-click="delete" phx-value-id={company.id} icon="huge-delete-02" danger kbd="⌘⌫">
          Delete company
        </.action_menu_item>
      </.action_menu>

  `label` is the accessible name of the button. The optional `:title` slot is the header with the item's name.
  An item with `href`, `navigate` or `patch` is a link, any other is a button (`phx-click`...). `disabled` items stay
  in the menu and say why in their `hint`; the keys skip them and they carry `aria-disabled`. `danger` paints an
  item in the error color (put it last).

  It uses the Dropdown's machinery (hook `LineaUI.ActionMenu`, a Dropdown hook with the row marking): the menu
  sits in the top layer under the button, aligned to its right edge (`placement="bottom-end"`), flips upwards when there
  is no room below, follows scrolling, and closes with Esc (the focus goes back to the button), Tab or a click
  outside; ↑ ↓ Home End and letters move among the items. `LineaUI.open/close/toggle` work with its `id`.

  ## What is marked while it is open

  The hook sets `data-am-open` on the nearest `[data-am-row]`, `tr` or card-table row (`.linea-ctable-row`) above the
  button, and the CSS tints it (`color-mix(in srgb, var(--accent) 6%, var(--panel))`). Inside a `card_table` the
  row is marked with no work of yours. For any other item (a list entry, a message) give its element
  `data-am-row`; a card with no `data-am-row` is simply not marked. The button is pressed through
  `aria-expanded="true"`.

      <.card_table id="companies" rows={@companies}>
        <:col :let={c} label="Company">{c.name}</:col>
        <:action :let={c}>
          <.action_menu id={"actions-" <> c.id} label={"Actions of " <> c.name}>
            <.action_menu_item phx-click="members" phx-value-id={c.id} icon="huge-user-multiple">
              Members
            </.action_menu_item>
          </.action_menu>
        </:action>
      </.card_table>
  """

  use LineaUI.Component

  alias LineaUI.Components.Icon

  @doc """
  Renders the "⋯" button and its menu.
  """
  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "The accessible name of the \"⋯\" button."

  attr :placement, :string,
    default: "bottom-end",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc: "Where the menu opens, flipping when there is no room."

  attr :class, :any, default: nil, doc: "Merged into the menu box (`w-64`...)."
  attr :rest, :global
  slot :title, doc: "A header with the name of the item the actions belong to."
  slot :inner_block, required: true, doc: "`action_menu_item`s and `action_menu_separator`s."

  def action_menu(assigns) do
    ~H"""
    <div
      id={@id}
      class="linea-am-root"
      phx-hook="LineaUI.ActionMenu"
      data-popup="menu"
      data-placement={@placement}
      data-offset="6"
      data-open="false"
      {@rest}
    >
      <div data-trigger class="inline-flex">
        <button type="button" id={"#{@id}-button"} class="linea-am-trig" aria-label={@label}>
          <Icon.icon name="huge-more-horizontal" class="size-4" />
        </button>
      </div>
      <div
        id={"#{@id}-menu"}
        class="popper-root fixed left-0 top-0 w-max"
        popover="manual"
        data-panel
        aria-hidden="true"
        phx-mounted='[["ignore_attrs",{"attrs":["class","style","data-popper-placement","aria-hidden"]}]]'
      >
        <div
          class={merge(["popper-box linea-am", @class])}
          role="menu"
          aria-labelledby={"#{@id}-button"}
        >
          <div :if={@title != []} class="linea-am-h" role="presentation">{render_slot(@title)}</div>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  An item of the menu: a link with `href`, `navigate` or `patch`, a button otherwise (`phx-click`...).
  """
  attr :icon, :string,
    default: nil,
    doc: "A Hugeicons name (`huge-delete-02`) drawn before the text."

  attr :kbd, :string,
    default: nil,
    doc: "A shortcut shown at the end, as text only: it binds no key."

  attr :hint, :string,
    default: nil,
    doc: "A second, smaller line, for the reason an item is disabled."

  attr :danger, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :type, :string, default: "button"
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(href navigate patch method replace download target rel hreflang referrerpolicy form name value)

  slot :inner_block, required: true

  def action_menu_item(%{rest: rest} = assigns)
      when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link
      class={merge(["linea-am-i", @class])}
      role="menuitem"
      tabindex="-1"
      data-danger={@danger && ""}
      data-disabled={@disabled && ""}
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      <.item_body icon={@icon} kbd={@kbd} hint={@hint}>{render_slot(@inner_block)}</.item_body>
    </.link>
    """
  end

  def action_menu_item(assigns) do
    ~H"""
    <button
      type={@type}
      class={merge(["linea-am-i", @class])}
      role="menuitem"
      tabindex="-1"
      data-danger={@danger && ""}
      data-disabled={@disabled && ""}
      disabled={@disabled}
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      <.item_body icon={@icon} kbd={@kbd} hint={@hint}>{render_slot(@inner_block)}</.item_body>
    </button>
    """
  end

  attr :icon, :string, default: nil
  attr :kbd, :string, default: nil
  attr :hint, :string, default: nil
  slot :inner_block, required: true

  defp item_body(assigns) do
    ~H"""
    <Icon.icon :if={@icon} name={@icon} class="size-4 shrink-0" />
    <span class="linea-am-t">
      {render_slot(@inner_block)}<span :if={@hint} class="linea-am-hint">{@hint}</span>
    </span>
    <kbd :if={@kbd} class="linea-am-kbd">{@kbd}</kbd>
    """
  end

  @doc "The line between two groups of items."
  attr :class, :any, default: nil
  attr :rest, :global

  def action_menu_separator(assigns) do
    ~H"""
    <div class={merge(["linea-am-sep", @class])} role="separator" {@rest}></div>
    """
  end
end
