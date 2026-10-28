defmodule LineaUI.Components.Autocomplete do
  @moduledoc """
  A text input with a list of suggestions under it, in LineOne's Tom Select look: the person
  types, the list narrows (or the server searches), and choosing a suggestion sets the field.

      <.autocomplete field={@form[:customer_id]} label="Customer" options={@customers}
                     on_search="search_customers" placeholder="Pick a customer" clearable />

      <.autocomplete field={@form[:product_id]} options={@products} on_search="search_products"
                     no_results="Nothing for \\"%{query}\\"" open_on_focus target={@myself}>
        <:option :let={product}>{product.label} <small>{product.data.sku}</small></:option>
      </.autocomplete>

      <.autocomplete field={@form[:city]} options={["Salvador", "Santos", "São Paulo"]} free_text />

  Options are strings, `{label, value}` tuples or maps with `:label` and `:value` (other keys
  reach the `:option` slot as `option.data`), as in `LineaUI.Components.Select.Options`.

  The choice is submitted through a hidden input named like the field; the visible input only
  shows the chosen option's label. A bubbling `input` event fires from the hidden input when
  the value changes, so a surrounding `phx-change` runs. Leaving the input with text that is
  not an option puts the chosen label back; leaving it empty clears the value.

  With `free_text` the typed text itself is the value (the suggestions only complete it):
  every keystroke updates the hidden input, and choosing a suggestion writes its value.

  Without `on_search` the list filters itself on the client (ignoring case and accents). With
  it, the hook pushes the query to the server, shows `loading_text` until the reply, and the
  server answers by re-rendering `options`.

  The text typed shows in bold primary colour inside each suggestion (no background). While the
  server searches the list is `aria-busy` and `loading_text` shows with a 16px spinner as a
  `role="status"`; "no results" is a status too. The clear button is a real button
  (`clear_label` names it) that can be reached with `Tab` and pressed with `Enter` or `Space`.

  The behavior lives in the `LineaUI.Autocomplete` hook, so the field needs a stable `id` (it
  gets one from `field` or `name`).
  """

  use LineaUI.Component

  alias LineaUI.Components.Pickers
  alias LineaUI.Components.Select.Options

  @sizes %{
    "sm" =>
      "[&_.ts-control]:py-1 [&_.ts-control]:text-xs-plus [&_.ts-control_input]:text-xs-plus",
    "md" => nil,
    "lg" => "[&_.ts-control]:py-2.5 [&_.ts-control]:text-base [&_.ts-control_input]:text-base"
  }

  @doc """
  Renders the autocomplete.

  Events: with `on_search`, typing pushes `on_search` with `%{"id" => id, "query" => text}`
  (after `debounce` ms, once the query has `search_threshold` characters) to `target` or to the
  LiveView/LiveComponent the field is in. Choosing, clearing or (with `free_text`) typing fires
  the form's `phx-change` with the field's value.
  """
  attr :id, :string, doc: "Defaults to the field id, then `name`, then a generated one."
  attr :name, :string, doc: "Defaults to the field name."
  attr :value, :any, doc: "The chosen value. Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: [], doc: "The suggestions, see the module doc."
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false

  attr :display_value, :string,
    default: nil,
    doc:
      "The text shown for `value` when it is not among `options` (a chosen customer the current search no longer returns)."

  attr :free_text, :boolean,
    default: false,
    doc: "The typed text is the value; the suggestions only complete it."

  attr :on_search, :string,
    default: nil,
    doc: "The event pushed with the query: the server searches."

  attr :debounce, :integer,
    default: 300,
    doc: "Milliseconds between the last keystroke and the push."

  attr :search_threshold, :integer, default: 0, doc: "How many characters before searching."
  attr :target, :any, default: nil

  attr :open_on_focus, :boolean,
    default: false,
    doc: "Show the suggestions as soon as the input has focus."

  attr :clearable, :boolean, default: false, doc: "A button that empties the field."

  attr :clear_label, :string,
    default: "Clear",
    doc: "The name of the clear button, for screen readers and its tooltip."

  attr :no_results, :string,
    default: "No results found",
    doc: "Shown when nothing matches; `%{query}` is replaced by what was typed."

  attr :loading_text, :string, default: "Searching…", doc: "Shown while the server searches."
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(autofocus form required),
    doc:
      "Goes to the visible input (`aria-label`...), except `phx-debounce`/`phx-throttle`, which go to the hidden one."

  slot :option,
    doc: "How a suggestion shows in the list; gets the option map (`label`, `value`, `data`)."

  slot :prefix, doc: "An icon inside the control, before the text."

  def autocomplete(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("autocomplete") end))
    |> assign_new(:value, fn -> nil end)
    |> prepare()
    |> render_autocomplete()
  end

  defp prepare(assigns) do
    entries = Options.normalize(assigns.options)
    value = assigns.value |> Options.values() |> List.first()

    assign(assigns,
      entries: entries,
      value: value,
      text: text(value, Options.flat(entries), assigns.display_value, assigns.free_text),
      forwarded: Pickers.forwarded(assigns.rest),
      input_rest: Map.drop(assigns.rest, [:"phx-debounce", :"phx-throttle"])
    )
  end

  defp text(nil, _options, _display, _free), do: ""
  defp text(value, _options, _display, true), do: value

  defp text(value, options, display, false) do
    case Enum.find(options, &(&1.value == value)) do
      nil -> display || value
      option -> option.label
    end
  end

  defp render_autocomplete(assigns) do
    ~H"""
    <Pickers.field label={@label} help={@help} errors={@errors} for={@id <> "-input"}>
      <div
        id={@id}
        phx-hook="LineaUI.Autocomplete"
        phx-mounted={JS.ignore_attributes(["class"])}
        phx-target={@target}
        class={
          merge([
            "ts-wrapper autocomplete w-full",
            @label && "mt-1.5",
            @clearable && "plugin-clear_button",
            @value && "has-items",
            @disabled && "disabled",
            @errors != [] && "is-invalid",
            size_class(@size),
            @class
          ])
        }
        data-value={@value || ""}
        data-label={@text}
        data-free-text={bool(@free_text)}
        data-on-search={@on_search}
        data-debounce={@debounce}
        data-threshold={@search_threshold}
        data-open-on-focus={bool(@open_on_focus)}
      >
        <input
          type="hidden"
          id={@id <> "-value"}
          name={@name}
          value={@value}
          disabled={@disabled}
          phx-update="ignore"
          data-value-input
          {@forwarded}
        />
        <div id={@id <> "-control"} class="ts-control items-center" phx-update="ignore">
          <span
            :for={prefix <- @prefix}
            class="flex shrink-0 items-center pr-2 text-slate-400 dark:text-navy-300"
          >
            {render_slot(prefix)}
          </span>
          <input
            type="text"
            id={@id <> "-input"}
            value={@text}
            role="combobox"
            aria-autocomplete="list"
            aria-haspopup="listbox"
            aria-expanded="false"
            aria-controls={@id <> "-listbox"}
            aria-invalid={@errors != [] && "true"}
            autocomplete="off"
            placeholder={@placeholder}
            disabled={@disabled}
            data-query
            {@input_rest}
          />
          <button
            :if={@clearable}
            type="button"
            class="clear-button"
            title={@clear_label}
            aria-label={@clear_label}
            data-clear
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="3"
              stroke-linecap="round"
              class="size-2.5"
              aria-hidden="true"
            >
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </button>
        </div>
        <div
          id={@id <> "-dropdown"}
          class="ts-dropdown"
          phx-mounted={JS.ignore_attributes(["hidden"])}
          hidden
          data-dropdown
        >
          <div
            id={@id <> "-listbox"}
            class="ts-dropdown-content"
            role="listbox"
            aria-busy="false"
            phx-mounted={JS.ignore_attributes(["aria-busy"])}
            data-listbox
          >
            <.entry :for={entry <- @entries} entry={entry} id={@id} option_slot={@option} />
            <div id={@id <> "-status"} phx-update="ignore" data-status></div>
          </div>
        </div>
        <div hidden data-no-results>{@no_results}</div>
        <div hidden data-loading>{@loading_text}</div>
      </div>
    </Pickers.field>
    """
  end

  defp size_class(size), do: @sizes[size]

  attr :entry, :map, required: true
  attr :id, :string, required: true
  attr :option_slot, :list, required: true

  defp entry(%{entry: %{type: :group}} = assigns) do
    ~H"""
    <div class="optgroup" role="group" data-group>
      <div class="optgroup-header">{@entry.label}</div>
      <.entry :for={option <- @entry.options} entry={option} id={@id} option_slot={@option_slot} />
    </div>
    """
  end

  defp entry(assigns) do
    ~H"""
    <div
      class="option"
      role="option"
      id={option_id(@id, @entry.value)}
      data-value={@entry.value}
      data-label={@entry.label}
      data-selectable={not @entry.disabled && "true"}
      data-disabled={@entry.disabled && "true"}
      aria-disabled={@entry.disabled && "true"}
      aria-selected="false"
    >
      <span :if={@option_slot == []} data-text>{@entry.label}</span>
      {render_slot(@option_slot, @entry)}
    </div>
    """
  end

  defp option_id(id, value), do: "#{id}-opt-#{Base.url_encode64(value, padding: false)}"
end
