defmodule LineaUI.Components.PhoneInput do
  @moduledoc """
  A phone number field with a country picker: a button at the left with the ISO code and the calling code
  (`BR +55`), and the number input. The number is written in the national format of the country as it is typed
  (`(11) 91234-5678`), and what the form submits is the E.164 number (`+5511912345678`).

      <.phone_input field={@form[:phone]} label="Phone number" />
      <.phone_input name="phone" country="US" label="Phone number" />
      <.phone_input field={@form[:phone]} country="PT" country_order={~w(PT BR)} />
      <.phone_input field={@form[:phone]} countries={~w(BR PT AR UY)} clearable />
      <.phone_input field={@form[:phone]} except={~w(KP)} locale="en" />
      <.phone_input name="phone" value="+5511912345678" size="lg" variant="filled" />

  `country` is the country the field starts with, an ISO 3166-1 alpha-2 code. It is `"BR"` unless said otherwise,
  because LineaUI's users are Brazilian; set it to the country of your own audience, or use `value` with an
  international number, which selects its own country.

  ## The picker

  The button opens a list with a search field, as wide as the field (at least 16rem), and a 1px divider separates
  the button from the number. Each entry shows the ISO code (in mono type), the country name and its calling code (`PT Portugal +351`); a country that
  shares its code with others and has its own area codes shows them after it (`+1 787, 939` for Puerto Rico).
  Typing narrows the list by name (in Portuguese or English, and common names such as `usa`), by ISO code (`br`) and
  by calling code (`55` or `+55`), ignoring case and accents. The arrows move, Enter chooses, Esc closes and gives the
  focus back to the button. The names are in the language of `locale`.

  `country_order` lists the countries to show first, in that order; the rest follow by name. `countries` limits the
  picker to a set and `except` removes some from it. The look is ISO codes because flag emoji do not render
  on Windows, which draws two letters in their place. `flags` brings the emoji back, in the button and in the rows,
  for apps whose users are on platforms that draw them.

  ## Typing and pasting

  The field shows the number in the national format as it is typed: the separators appear when a digit follows them,
  so a number that is still being typed stays as typed (`(11) 9`), and digits past the usual length are kept. Typing
  or pasting an international number (`+55 11 91234-5678`) switches the country to the one the calling code belongs
  to, and the field shows the rest in that country's format. Countries that share a calling code are told apart by
  the first digits: `+1 876` is Jamaica, `+1 416` is Canada, `+44 7911` is Guernsey. The trunk prefix people dial
  before a national number (`0` in Brazil, `1` in the United States) is not part of the number and is dropped.

  ## What the form submits

  A hidden input with the field's name carries the E.164 number (empty while there are no digits), and the visible
  input has no name. When the number changes the hidden input fires a bubbling `input` event, so the surrounding
  `phx-change` runs and gets `%{"phone" => "+5511912345678"}`; it does not fire again when the server only echoes
  the same value. `phx-debounce` and `phx-throttle` go to the hidden input.

  The value the server sends wins over the one in the browser, and re-rendering the same value does nothing. `value`
  is an E.164 number (its country is read from the calling code) or a national number (read as the number of
  `country`).

  ## Formatting is not validation

  The format only helps the person read what they typed. A person can submit anything, so the server must validate
  the value it gets. `LineaUI.Components.PhoneInput.Format` reads a submitted number the way the field does:

      case LineaUI.Components.PhoneInput.Format.e164(params["phone"], "BR") do
        {:ok, e164} -> e164
        {:error, reason} -> reason
      end

  It normalizes to E.164 and rejects what cannot be a number, but it does not know which numbers a carrier
  issues. For that, check the E.164 string with a library that has number metadata.

  The behavior lives in the `LineaUI.PhoneInput` hook, so the field needs a stable `id` (it gets one from `field` or
  `name`).
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Input
  alias LineaUI.Components.PhoneInput.Countries
  alias LineaUI.Components.PhoneInput.Format
  alias LineaUI.Components.Pickers

  @picker_sizes %{
    "sm" => "text-xs-plus",
    "md" => nil,
    "lg" => "text-base"
  }

  @input_padding "pl-[6.875rem]"

  # While the picker is open the number's border takes the focus color, as the field's own focus does.
  @open "[&:has([data-picker][aria-expanded=true])_[data-display]]:border-primary dark:[&:has([data-picker][aria-expanded=true])_[data-display]]:border-accent"

  @code "font-inter font-normal text-slate-400 dark:text-navy-300"

  @picker "flex h-full w-full items-center gap-1.5 rounded-l-lg pl-3 pr-1 text-slate-600 outline-hidden transition-colors hover:text-slate-800 focus-visible:text-primary disabled:pointer-events-none dark:text-navy-100 dark:hover:text-navy-50 dark:focus-visible:text-accent"

  @doc """
  Renders the phone input.

  Events: the hidden input dispatches a bubbling `input` event when the E.164 value changes, so the form's
  `phx-change` receives `%{"phone" => "+5511912345678"}` (`""` when the field is emptied). With `on_country_change`,
  choosing a country (or typing an international number of another one) also pushes that event with
  `%{"id" => id, "country" => "US", "code" => "1"}` to `target` or to the LiveView/LiveComponent the field is in.
  """
  attr :id, :string, doc: "The visible input's id. Defaults to the field id, then `name`."
  attr :name, :string, doc: "Defaults to the field name."

  attr :value, :any,
    doc: "An E.164 number or a national number (read as `country`). Defaults to the field value."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills `id`, `name`, `value` and `errors`."

  attr :country, :string,
    default: "BR",
    doc:
      "The country the field starts with, an ISO 3166-1 alpha-2 code (`\"BR\"`, `\"US\"`, `\"PT\"`). Brazil by default, because LineaUI's users are Brazilian. A `value` in E.164 selects its own country. A country the picker does not offer is replaced by the first of `country_order` it does, else by the first of its countries."

  attr :country_order, :list,
    default: [],
    doc: "ISO codes shown first in the picker, in this order, before the rest by name."

  attr :countries, :list,
    default: [],
    doc: "ISO codes the picker is limited to; empty offers every country."

  attr :except, :list, default: [], doc: "ISO codes removed from the picker."

  attr :locale, :string,
    default: "pt-BR",
    doc:
      "The language of the country names and their order: `pt-BR` (or any `pt`) for Portuguese, anything else for English. Both languages are searched."

  attr :flags, :boolean,
    default: false,
    doc:
      "Show the flag emoji of the country instead of its ISO code, in the button and in the picker. Off by default, because Windows does not draw flag emoji."

  attr :label, :string, default: nil, doc: "The caption."
  attr :label_class, :any, default: nil, doc: "Classes of the caption text."
  attr :help, :string, default: nil, doc: "The small line under the control."
  attr :errors, :list, default: [], doc: "Messages to show; `field` adds its own."
  attr :disabled, :boolean, default: false

  attr :variant, :string,
    default: "outlined",
    values: ~w(outlined filled),
    doc: "The input's look, as in `input`."

  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)

  attr :clearable, :boolean,
    default: false,
    doc: "A button that empties the number and keeps the country."

  attr :clear_label, :string, default: "Clear"

  attr :picker_label, :string,
    default: "Country",
    doc: "The accessible name of the picker button."

  attr :search_placeholder, :string,
    default: "Search…",
    doc: "The placeholder of the picker's search field."

  attr :no_results, :string,
    default: "No results found",
    doc: "Shown when the search matches no country; `%{query}` is replaced by what was typed."

  attr :on_country_change, :string,
    default: nil,
    doc: "An event pushed when the country changes in the browser, see above."

  attr :target, :any, default: nil, doc: "The `phx-target` of `on_country_change`."
  attr :wrapper_class, :any, default: nil, doc: "Classes of the block around the field."
  attr :class, :any, default: nil, doc: "Classes of the visible input."

  attr :rest, :global,
    include: ~w(autocomplete autofocus form placeholder readonly required),
    doc:
      "Goes to the visible input, except `phx-debounce`/`phx-throttle`, which go to the hidden one."

  def phone_input(assigns) do
    assigns
    |> assign_field()
    |> assign_new(:name, fn -> nil end)
    |> then(&assign_new(&1, :id, fn -> &1.name || gen_id("phone") end))
    |> assign_new(:value, fn -> nil end)
    |> prepare()
    |> render_phone()
  end

  defp prepare(assigns) do
    pool = pool(assigns.countries, assigns.except)
    initial = initial(assigns.country, pool, codes(assigns.country_order))
    state = state(assigns.value, initial, pool)

    assign(assigns,
      selected: state.country,
      display: state.display,
      e164: state.e164,
      only: codes(assigns.countries),
      excluded: codes(assigns.except),
      order: codes(assigns.country_order),
      state: error_state(assigns.errors),
      input_class: merge([@input_padding, assigns.clearable && "pe-9", assigns.class]),
      open: @open,
      code_class: @code,
      picker_class: merge([@picker, @picker_sizes[assigns.size]]),
      forwarded: Pickers.forwarded(assigns.rest),
      input_rest:
        Map.merge(
          %{autocomplete: "tel", inputmode: "tel"},
          Map.drop(assigns.rest, [:"phx-debounce", :"phx-throttle"])
        )
    )
  end

  defp codes(list), do: Enum.map(list, &(&1 |> to_string() |> String.upcase()))

  defp pool(only, except) do
    only = codes(only)
    except = codes(except)

    case Enum.filter(Countries.all(), &listed?(&1.iso, only, except)) do
      [] -> Countries.all()
      pool -> pool
    end
  end

  defp listed?(iso, [], except), do: iso not in except
  defp listed?(iso, only, except), do: iso in only and iso not in except

  defp initial(iso, pool, order) do
    [iso | order]
    |> Enum.map(fn code -> Enum.find(pool, &(&1.iso == String.upcase(code))) end)
    |> Enum.find(& &1) || List.first(pool)
  end

  defp state(value, initial, _pool) when value in [nil, ""],
    do: %{country: initial, display: "", e164: ""}

  defp state(value, initial, pool) do
    text = to_string(value)

    with {:ok, %{country: found, national: national}} <- Format.resolve(text, initial.iso),
         true <- Enum.any?(pool, &(&1.iso == found.iso)) do
      %{
        country: found,
        display: Format.display(national, found),
        e164: Format.number(national, found)
      }
    else
      _unreadable -> %{country: initial, display: text, e164: ""}
    end
  end

  defp error_state([]), do: nil
  defp error_state(_errors), do: "error"

  defp render_phone(assigns) do
    ~H"""
    <div
      id={@id <> "-phone"}
      class={merge(["ts-wrapper w-full", @open, @wrapper_class])}
      phx-hook="LineaUI.PhoneInput"
      phx-target={@target}
      data-country={@selected.iso}
      data-value={@e164}
      data-locale={@locale}
      data-flags={to_string(@flags)}
      data-only={Enum.join(@only, ",")}
      data-except={Enum.join(@excluded, ",")}
      data-order={Enum.join(@order, ",")}
      data-on-country-change={@on_country_change}
      data-picker-label={@picker_label}
    >
      <Input.input
        type="tel"
        id={@id}
        value={@display}
        label={@label}
        label_class={@label_class}
        help={@help}
        errors={@errors}
        variant={@variant}
        size={@size}
        shape={@shape}
        state={@state}
        disabled={@disabled}
        class={@input_class}
        data-display
        {@input_rest}
      >
        <:prefix interactive class="pointer-events-none w-full justify-start">
          <span
            aria-hidden="true"
            class="absolute top-1/2 left-[6.25rem] h-[18px] w-px -translate-y-1/2 bg-slate-300 dark:bg-navy-450"
          ></span>
          <div
            id={@id <> "-country"}
            class="pointer-events-auto flex h-full w-[6.25rem] items-center"
            phx-update="ignore"
          >
            <button
              type="button"
              id={@id <> "-picker"}
              class={@picker_class}
              aria-haspopup="listbox"
              aria-expanded="false"
              aria-controls={@id <> "-list"}
              aria-label={"#{@picker_label}: +#{@selected.code}"}
              disabled={@disabled}
              data-picker
            >
              <span :if={@flags} class="text-base leading-none" aria-hidden="true" data-flag>
                {Format.flag(@selected.iso)}
              </span>
              <span :if={!@flags} class="font-inter font-medium" data-iso-code>{@selected.iso}</span>
              <span class={@code_class} data-code>+{@selected.code}</span>
              <.glyph
                name={:chevron_down}
                class="ml-auto size-3.5 shrink-0 text-slate-400 dark:text-navy-300"
              />
            </button>
            <div
              id={@id <> "-dropdown"}
              class="ts-dropdown has-boxed-search w-full min-w-64 max-w-[calc(100vw-2rem)] text-left"
              hidden
              data-dropdown
            >
              <div class="ts-search">
                <.glyph name={:search} class="size-4 shrink-0" />
                <input
                  type="text"
                  id={@id <> "-search"}
                  role="combobox"
                  aria-expanded="true"
                  aria-controls={@id <> "-list"}
                  aria-label={@search_placeholder}
                  autocomplete="off"
                  placeholder={@search_placeholder}
                  data-search
                />
              </div>
              <div
                id={@id <> "-list"}
                class="ts-dropdown-content"
                role="listbox"
                aria-label={@picker_label}
                data-list
              >
              </div>
            </div>
            <div hidden data-no-results>{@no_results}</div>
          </div>
        </:prefix>
        <:suffix :if={@clearable} interactive>
          <button
            type="button"
            class="flex size-6 items-center justify-center rounded-full outline-hidden hover:text-slate-600 focus-visible:text-primary dark:hover:text-navy-100 dark:focus-visible:text-accent"
            tabindex="-1"
            title={@clear_label}
            aria-label={@clear_label}
            hidden={@display == ""}
            disabled={@disabled}
            data-clear
          >
            <.glyph name={:close} class="size-3.5" />
          </button>
        </:suffix>
      </Input.input>
      <input
        type="hidden"
        id={@id <> "-value"}
        name={@name}
        value={@e164}
        disabled={@disabled}
        phx-update="ignore"
        data-value-input
        {@forwarded}
      />
    </div>
    """
  end
end
