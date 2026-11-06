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
  page. `soft` is the page's own surface with a ring, for when the inverted bar weighs too much. `solid` is the
  canvas bar: the `--solid` surface, the count written in bold ("3 selecionados") instead of a badge, no
  separators, rounded `sm` buttons (`soft`, `ghost`, `danger`...), and a close button only when there is an
  `on_clear`. `floating`
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

  ## Progress

  While a bulk action runs, `progress` (done) and `progress_max` (all) turn the bar into a progress bar: the
  `label` in bold as it is given (no count before it), a meter and the "5/12" fraction.

      <.bulk_bar id="emit" count={12} variant="solid" label="Emitindo 12 notas…" progress={5} progress_max={12} />

  ## Confirm

  An `:action` with `confirm` (a title) asks first: the button opens a small card under the bar (above it when
  floating) with `confirm_text`, a cancel and a confirm button; only the confirm button runs the action's
  `phx-click`.

      <:action variant="danger" icon="huge-delete-02" phx-click="delete" confirm="Excluir 3 pedidos?"
        confirm_text="Os rascunhos somem para todos." confirm_label="Excluir" cancel_label="Cancelar">
        Excluir
      </:action>

  ## Keyboard

  Esc clears the selection (it presses the close button), unless it was meant for an open list or another
  control. `show_esc` writes the key as a chip in the close button. The bar is a labelled region and announces the count as it changes.
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1, icon: 1]

  @variants ~w(inverse soft solid)

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

  attr :progress, :integer,
    default: nil,
    doc:
      "How many are done, for a running bulk action: shows a meter and `progress/progress_max`."

  attr :progress_max, :integer, default: nil, doc: "How many there are to do, with `progress`."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :field, doc: "A control, skinned as a quiet field."

  slot :action, doc: "A button." do
    attr :variant, :string, values: ~w(default primary soft ghost danger)
    attr :disabled, :boolean
    attr :icon, :string

    attr :confirm, :string,
      doc: "A title: the button opens a card that asks before running the action."

    attr :confirm_text, :string
    attr :confirm_label, :string, doc: "The confirm button (default `Confirm`)."
    attr :cancel_label, :string, doc: "The cancel button (default `Cancel`)."
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
      |> assign(:progress?, is_integer(assigns.progress) and is_integer(assigns.progress_max))
      |> assign(:canvas?, assigns.variant == "solid")
      |> assign(:actions, Enum.with_index(assigns.action))

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
          if(@floating,
            do:
              "fixed bottom-6 left-1/2 z-(--linea-z-fab) max-w-[calc(100vw-1.5rem)] -translate-x-1/2",
            else: "relative"
          ),
          @class
        ])
      }
      {@rest}
    >
      <b :if={@progress?} class="linea-bulk-text" aria-live="polite">{@label}</b>
      <b :if={!@progress? and @canvas?} class="linea-bulk-text" aria-live="polite">{@caption}</b>
      <span :if={!@progress? and !@canvas?} class="linea-bulk-count" aria-live="polite">
        <span class="linea-bulk-badge">{@count}</span>
        <span>{label_for(@count, @label, @label_plural)}</span>
      </span>
      <span
        :if={@progress?}
        class="linea-bulk-meter"
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax={@progress_max}
        aria-valuenow={@progress}
        aria-label={@label}
      >
        <i style={"width: #{percent(@progress, @progress_max)}%"}></i>
      </span>
      <span :if={@progress?} class="linea-bulk-fraction">{@progress}/{@progress_max}</span>
      <button
        :if={@select_all?}
        type="button"
        class="linea-bulk-link"
        phx-click={@on_select_all}
        phx-target={@target}
      >
        {String.replace(@select_all_label, "%{total}", to_string(@total))}
      </button>
      <span
        :if={!@canvas? and !@progress? and (@field != [] or @action != [])}
        class="linea-bulk-sep"
        aria-hidden="true"
      ></span>
      <div :for={field <- @field} class="linea-bulk-field">{render_slot(field)}</div>
      <%= for {action, index} <- @actions do %>
        <button
          :if={!action[:confirm]}
          type="button"
          aria-disabled={action[:disabled] && "true"}
          class="linea-bulk-btn"
          data-variant={action[:variant] || "default"}
          {action_attrs(action)}
        >
          <.icon :if={action[:icon]} name={action[:icon]} class="size-4 shrink-0" />{render_slot(
            action
          )}
        </button>
        <button
          :if={action[:confirm]}
          type="button"
          aria-disabled={action[:disabled] && "true"}
          aria-haspopup="dialog"
          aria-controls={"#{@id}-confirm-#{index}"}
          class="linea-bulk-btn"
          data-variant={action[:variant] || "default"}
          phx-click={!action[:disabled] && JS.toggle(to: "##{@id}-confirm-#{index}")}
          {confirm_trigger_attrs(action)}
        >
          <.icon :if={action[:icon]} name={action[:icon]} class="size-4 shrink-0" />{render_slot(
            action
          )}
        </button>
        <div
          :if={action[:confirm]}
          id={"#{@id}-confirm-#{index}"}
          role="alertdialog"
          aria-labelledby={"#{@id}-confirm-#{index}-title"}
          class="linea-bulk-confirm"
          style="display: none"
        >
          <b id={"#{@id}-confirm-#{index}-title"} class="linea-bulk-confirm-title">{action[:confirm]}</b>
          <p :if={action[:confirm_text]} class="linea-bulk-confirm-text">{action[:confirm_text]}</p>
          <div class="linea-bulk-confirm-actions">
            <button
              type="button"
              class="linea-bulk-btn"
              data-variant="ghost"
              phx-click={JS.hide(to: "##{@id}-confirm-#{index}")}
            >
              {action[:cancel_label] || "Cancel"}
            </button>
            <button
              type="button"
              class="linea-bulk-btn"
              data-variant={action[:variant] || "default"}
              phx-click={confirm_click(action[:"phx-click"], "##{@id}-confirm-#{index}")}
              {confirm_attrs(action)}
            >
              {action[:confirm_label] || "Confirm"}
            </button>
          </div>
        </div>
      <% end %>
      <span :if={!@canvas? and !@progress?} class="linea-bulk-sep" aria-hidden="true"></span>
      <button
        :if={!(@canvas? or @progress?) or @on_clear != nil}
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

  @confirm_attrs [
    :variant,
    :disabled,
    :icon,
    :confirm,
    :confirm_text,
    :confirm_label,
    :cancel_label
  ]

  # the trigger of a confirmed action keeps its id and labels, not its phx-* bindings
  defp confirm_trigger_attrs(action) do
    action
    |> assigns_to_attributes(@confirm_attrs)
    |> Enum.reject(fn {name, _} -> String.starts_with?(to_string(name), "phx-") end)
  end

  # the confirm button runs the action's phx-* bindings (phx-click is chained with closing the card)
  defp confirm_attrs(action) do
    action
    |> assigns_to_attributes([:"phx-click", :id, :title, :"aria-label" | @confirm_attrs])
    |> Enum.filter(fn {name, _} -> String.starts_with?(to_string(name), "phx-") end)
  end

  defp confirm_click(nil, card), do: JS.hide(to: card)
  defp confirm_click(%JS{} = js, card), do: JS.hide(js, to: card)

  defp confirm_click(event, card) when is_binary(event),
    do: event |> JS.push() |> JS.hide(to: card)

  defp percent(_done, max) when max <= 0, do: 0
  defp percent(done, max), do: Float.round(min(done, max) / max * 100, 2)

  defp label_for(1, label, _plural), do: label
  defp label_for(_count, label, nil), do: label
  defp label_for(_count, _label, plural), do: plural

  defp caption(%{progress: progress, progress_max: max, label: label})
       when is_integer(progress) and is_integer(max),
       do: label

  defp caption(assigns),
    do: "#{assigns.count} #{label_for(assigns.count, assigns.label, assigns.label_plural)}"

  defp select_all?(%{on_select_all: nil}), do: false
  defp select_all?(%{total: nil}), do: false
  defp select_all?(%{total: total, count: count}), do: total > count
end
