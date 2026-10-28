defmodule LineaUI.Components.BulkBar do
  @moduledoc """
  A floating bar of bulk actions for a table with selection: the count of what is selected in a badge, a
  field to change one attribute (a status, an owner, a label), buttons for the actions and a close that
  clears the selection. It appears only while `count` is above zero.

      <.bulk_bar
        id="orders-bulk"
        count={@count}
        label="order selected"
        label_plural="orders selected"
        total={@total}
        on_select_all="select_all"
        on_clear="clear_selection"
      >
        <:field>
          <.select name="status" options={@statuses} value={@status} search="none" placeholder="Change status" />
        </:field>
        <:action variant="primary" disabled={is_nil(@status)} phx-click="apply">Apply to {@count}</:action>
        <:action variant="danger" icon="huge-delete-02" phx-click="delete">Delete</:action>
      </.bulk_bar>

  The texts come from outside: `label` and `label_plural` (the part after the badge), `select_all_label`
  (`%{total}` is replaced) and `clear_label`. Nothing is pluralized here, so any language works.

  ## Looks

  `variant="inverse"` (default) is the opposite of the page: a dark bar on a light page, a light one on a dark
  page. `soft` is the page's own surface with a ring, for when the inverted bar weighs too much. `floating`
  (default) pins the bar to the bottom center of the viewport above the page; `floating={false}` lays it out
  where it is, for a bar inside a card or a toolbar.

  ## Slots

  `:field` holds a control (a `select`, an `input`); it is skinned as a quiet field the height of the buttons,
  and a listbox inside it opens upwards when the bar is floating. `:action` is a button: `variant` is
  `default`, `primary` (the one main action, `disabled` until there is something to apply) or `danger` (last,
  in red; it only looks the part, so confirm in your handler or with `data-confirm`); `icon` is a Hugeicons
  name; every other attribute (`phx-click`, `phx-value-*`, `data-*`) goes to the button. A `disabled` action
  keeps the focus (it is `aria-disabled`, not a native `disabled`) and does nothing: its `phx-*` attributes
  are not rendered.

  ## Keyboard

  Esc clears the selection (it presses the close button), unless it was meant for an open list or another
  control. `show_esc` writes the key as a chip in the close button. The bar is a labelled region and announces the count as it changes.
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1, icon: 1]

  @variants ~w(inverse soft)

  @doc "The variants of the bar."
  @spec bulk_bar_variants() :: [String.t()]
  def bulk_bar_variants, do: @variants

  attr :id, :string, required: true

  attr :count, :integer,
    required: true,
    doc: "How many are selected; the bar shows only above zero."

  attr :label, :string,
    default: "selected",
    doc: "The text after the badge, for one selected."

  attr :label_plural, :string,
    default: nil,
    doc: "The text after the badge for several; `label` when it is `nil`."

  attr :total, :integer,
    default: nil,
    doc:
      "How many there are in all (every page); with `on_select_all`, offers to select them all."

  attr :select_all_label, :string,
    default: "Select all %{total}",
    doc: "The select all link; `%{total}` is replaced."

  attr :on_clear, :any,
    default: nil,
    doc: "An event name or a `%JS{}` run by the close button and Esc."

  attr :on_select_all, :any,
    default: nil,
    doc: "An event name or a `%JS{}` run by the select all link."

  attr :target, :any, default: nil, doc: "The `phx-target` of both."
  attr :clear_label, :string, default: "Clear selection"

  attr :show_esc, :boolean,
    default: false,
    doc:
      "Writes a visible `Esc` key chip in the close button (the button is always labelled with it)."

  attr :variant, :string, default: "inverse", values: @variants

  attr :floating, :boolean,
    default: true,
    doc: "Pin the bar to the bottom center of the viewport."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :field, doc: "A control, skinned as a quiet field."

  slot :action, doc: "A button." do
    attr :variant, :string, values: ~w(default primary danger)
    attr :disabled, :boolean
    attr :icon, :string
    attr :id, :string
    attr :title, :string
    attr :"aria-label", :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-disable-with", :string
    attr :"phx-value-id", :any
  end

  def bulk_bar(assigns) do
    assigns =
      assigns
      |> assign(:caption, caption(assigns))
      |> assign(:select_all?, select_all?(assigns))

    ~H"""
    <div
      :if={@count > 0}
      id={@id}
      role="region"
      aria-label={@caption}
      phx-hook="LineaUI.BulkBar"
      data-variant={@variant}
      data-floating={bool(@floating)}
      class={
        merge([
          "linea-bulk",
          @floating &&
            "fixed bottom-6 left-1/2 z-(--linea-z-fab) max-w-[calc(100vw-1.5rem)] -translate-x-1/2",
          @class
        ])
      }
      {@rest}
    >
      <span class="linea-bulk-count" aria-live="polite">
        <span class="linea-bulk-badge">{@count}</span>
        <span>{label_for(@count, @label, @label_plural)}</span>
      </span>
      <button
        :if={@select_all?}
        type="button"
        class="linea-bulk-link"
        phx-click={@on_select_all}
        phx-target={@target}
      >
        {String.replace(@select_all_label, "%{total}", to_string(@total))}
      </button>
      <span :if={@field != [] or @action != []} class="linea-bulk-sep" aria-hidden="true"></span>
      <div :for={field <- @field} class="linea-bulk-field">{render_slot(field)}</div>
      <button
        :for={action <- @action}
        type="button"
        aria-disabled={action[:disabled] && "true"}
        class="linea-bulk-btn"
        data-variant={action[:variant] || "default"}
        {action_attrs(action)}
      >
        <.icon :if={action[:icon]} name={action[:icon]} class="size-4 shrink-0" />{render_slot(action)}
      </button>
      <span class="linea-bulk-sep" aria-hidden="true"></span>
      <button
        type="button"
        class="linea-bulk-clear"
        aria-label={@clear_label <> " (Esc)"}
        title={@clear_label <> " (Esc)"}
        phx-click={@on_clear}
        phx-target={@target}
        data-bulk-clear
      >
        <.glyph name={:close} class="size-4" />
        <kbd :if={@show_esc} class="linea-bulk-esc" aria-hidden="true">Esc</kbd>
      </button>
    </div>
    """
  end

  # a disabled action stays focusable (aria-disabled) but runs nothing: its phx-* bindings are left out
  defp action_attrs(action) do
    attrs = assigns_to_attributes(action, [:variant, :disabled, :icon])

    case action[:disabled] do
      true -> Enum.reject(attrs, fn {name, _} -> String.starts_with?(to_string(name), "phx-") end)
      _ -> attrs
    end
  end

  defp label_for(1, label, _plural), do: label
  defp label_for(_count, label, nil), do: label
  defp label_for(_count, _label, plural), do: plural

  defp caption(assigns),
    do: "#{assigns.count} #{label_for(assigns.count, assigns.label, assigns.label_plural)}"

  defp select_all?(%{on_select_all: nil}), do: false
  defp select_all?(%{total: nil}), do: false
  defp select_all?(%{total: total, count: count}), do: total > count
end
