defmodule LineaUI.Components.Select.Listbox do
  @moduledoc false

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Pickers
  alias LineaUI.Components.Select.Options

  @doc false
  @spec prepare(map(), :select | :tags) :: map()
  def prepare(assigns, mode) do
    entries = Options.normalize(assigns.options)
    options = Options.flat(entries)
    known = known(options, Map.get(assigns, :selected_options, []))
    values = values(assigns.value, mode)
    multiple = mode == :tags or assigns.multiple
    count = length(values)

    assigns
    |> then(&assign(&1, :placeholder, Map.get(&1, :placeholder) || Map.get(&1, :prompt)))
    |> assign_new(:overflow, fn -> "wrap" end)
    |> assign_new(:size, fn -> "md" end)
    |> assign_new(:footer, fn -> false end)
    |> assign_new(:footer_count, fn -> "%{count} of %{total}" end)
    |> assign_new(:footer_hint, fn -> "Esc to close" end)
    |> assign_new(:more_label, fn -> "more" end)
    |> assign_new(:create_hint, fn -> nil end)
    |> assign_new(:limit_placeholder, fn -> nil end)
    |> assign_new(:create_position, fn -> "top" end)
    |> assign_new(:compact, fn -> false end)
    |> assign_new(:help, fn -> nil end)
    |> assign_new(:search, fn -> "control" end)
    |> assign_new(:search_placeholder, fn -> "Search…" end)
    |> assign(
      mode: mode,
      multiple: multiple,
      entries: entries,
      options: options,
      values: values,
      chosen: Enum.map(values, &Options.find(known, &1)),
      known: known,
      name: field_name(assigns.name, multiple),
      full: full?(multiple, count, assigns.max),
      removable: assigns.removable and not assigns.disabled,
      forwarded: Pickers.forwarded(assigns.rest)
    )
  end

  defp known(options, []), do: options

  defp known(options, selected) do
    listed = MapSet.new(options, & &1.value)
    extra = selected |> Options.normalize() |> Options.flat()
    options ++ Enum.reject(extra, &MapSet.member?(listed, &1.value))
  end

  defp values(value, :tags) when is_binary(value),
    do: value |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

  defp values(value, _mode), do: Options.values(value)

  defp field_name(name, true), do: ensure_brackets(name)
  defp field_name(name, false), do: name

  defp ensure_brackets(name) do
    case String.ends_with?(name, "[]") do
      true -> name
      false -> name <> "[]"
    end
  end

  defp full?(false, count, _max), do: count >= 1
  defp full?(true, _count, nil), do: false
  defp full?(true, count, max), do: count >= max

  @doc false
  def listbox(assigns) do
    ~H"""
    <Pickers.field label={@label} help={@help} errors={@errors} for={@id <> "-ts-control"}>
      <div
        id={@id}
        phx-hook="LineaUI.Select"
        phx-mounted={JS.ignore_attributes(["class"])}
        phx-target={@target}
        class={
          merge([
            "ts-wrapper w-full",
            @label && "mt-1.5",
            mode_class(@multiple),
            @removable && "plugin-remove_button",
            @compact && "compact",
            @clearable && "plugin-clear_button",
            @values != [] && "has-items",
            @full && "full",
            (@full and not @multiple) && "input-hidden",
            @disabled && "disabled",
            @errors != [] && "is-invalid",
            @class
          ])
        }
        data-mode={@mode}
        data-search-mode={@search}
        data-multiple={bool(@multiple)}
        data-create={bool(@create)}
        data-persist={bool(@persist)}
        data-restore={bool(@restore_on_backspace)}
        data-max={@max}
        data-overflow={@multiple && @overflow == "count" && "count"}
        data-size={@size != "md" && @size}
        data-more-label={@more_label}
        data-name={@name}
        data-value={Pickers.json(@values)}
        data-on-search={@on_search}
        data-debounce={@debounce}
        data-create-label={@create_label}
        data-create-hint={@create_hint}
        data-create-position={@create_position == "bottom" && "bottom"}
        data-placeholder={limited?(@mode, @max) && @placeholder}
        data-limit-placeholder={limited?(@mode, @max) && @limit_placeholder}
        data-remove-label={@removable && @remove_label}
        {@rest}
      >
        <select
          id={@id <> "-input"}
          name={@name}
          multiple={@multiple}
          disabled={@disabled}
          class="ts-hidden-accessible"
          tabindex="-1"
          aria-hidden="true"
          phx-update="ignore"
          data-input
          {@forwarded}
        >
          <option :if={@values == [] and not @multiple} value="" selected></option>
          <option :for={value <- @values} value={value} selected>{value}</option>
        </select>
        <input :if={@multiple} type="hidden" name={@name} value="" disabled={@disabled} />
        <div id={@id <> "-control"} class="ts-control" phx-update="ignore">
          <.chip
            :for={option <- @chosen}
            option={option}
            item={@item}
            removable={@removable}
            remove_label={@remove_label}
          />
          <input
            type="text"
            id={@id <> "-ts-control"}
            role="combobox"
            aria-haspopup="listbox"
            aria-expanded="false"
            aria-controls={@id <> "-listbox"}
            aria-invalid={@errors != [] && "true"}
            autocomplete="off"
            placeholder={if(limited?(@mode, @max) and @full, do: @limit_placeholder) || @placeholder}
            disabled={@disabled or (limited?(@mode, @max) and @full)}
            readonly={@search != "control"}
            data-search
          />
          <div
            :if={@clearable}
            class="clear-button"
            role="button"
            title={@clear_label}
            aria-label={@clear_label}
            data-clear
          >
            ⨯
          </div>
        </div>
        <div
          id={@id <> "-dropdown"}
          class={["ts-dropdown", mode_class(@multiple)]}
          phx-mounted={JS.ignore_attributes(["hidden"])}
          hidden
          data-dropdown
        >
          <div :if={@search == "panel"} class="ts-search" phx-update="ignore" id={@id <> "-panel"}>
            <.glyph name={:search} class="size-4 shrink-0" />
            <input
              type="text"
              id={@id <> "-panel-search"}
              role="searchbox"
              autocomplete="off"
              placeholder={@search_placeholder}
              aria-controls={@id <> "-listbox"}
              aria-label={@search_placeholder}
              data-search
              data-panel-search
            />
          </div>
          <div
            id={@id <> "-listbox"}
            class="ts-dropdown-content"
            role="listbox"
            aria-multiselectable={@multiple && "true"}
          >
            <div
              :if={@create_position != "bottom"}
              id={@id <> "-create"}
              phx-update="ignore"
              data-create-row
            >
            </div>
            <.entry :for={entry <- @entries} entry={entry} id={@id} option_slot={@option} />
            <div id={@id <> "-extra"} phx-update="ignore" data-extra></div>
            <div
              :if={@create_position == "bottom"}
              id={@id <> "-create"}
              phx-update="ignore"
              data-create-row
            >
            </div>
          </div>
          <div
            :if={@footer and @multiple}
            class="ts-footer"
            data-footer
            data-count-label={@footer_count}
          >
            <span data-footer-count></span>
            <span>{@footer_hint}</span>
          </div>
        </div>
        <div hidden data-templates>
          <template :for={option <- @known} data-value={option.value}>
            <.chip option={option} item={@item} removable={@removable} remove_label={@remove_label} />
          </template>
        </div>
        <div hidden data-no-results>{@no_results}</div>
        <div
          :if={limited?(@mode, @max)}
          class={[
            "text-tiny-plus tabular-nums text-slate-400 dark:text-navy-300",
            if(@help, do: "absolute end-0 top-full mt-1", else: "mt-1.5 text-end")
          ]}
          hidden={not @full}
          data-counter
        >
          {length(@values)} / {@max}
        </div>
      </div>
    </Pickers.field>
    """
  end

  # Only a tag input with a `max` shows its limit: the input goes off and a counter appears.
  defp limited?(:tags, max), do: max != nil
  defp limited?(_mode, _max), do: false

  defp mode_class(true), do: "multi"
  defp mode_class(false), do: "single"

  attr :option, :map, required: true
  attr :item, :list, required: true
  attr :removable, :boolean, required: true
  attr :remove_label, :string, required: true

  defp chip(%{item: []} = assigns) do
    ~H"""
    <div class="item" data-value={@option.value} data-ts-item>
      <span class="item-text">{@option.label}</span><button
        :if={@removable}
        type="button"
        class="remove"
        tabindex="-1"
        title={@remove_label}
        aria-label={@remove_label}
        data-remove
      >×</button>
    </div>
    """
  end

  defp chip(assigns) do
    ~H"""
    <span class="item" data-value={@option.value} data-ts-item>
      {render_slot(@item, @option)}
    </span>
    """
  end

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

  defp entry(%{option_slot: []} = assigns) do
    ~H"""
    <div
      class="option"
      role="option"
      id={option_id(@id, @entry.value)}
      data-value={@entry.value}
      data-label={@entry.label}
      data-keywords={Options.keywords(@entry) != "" && Options.keywords(@entry)}
      data-selectable={not @entry.disabled && "true"}
      data-disabled={@entry.disabled && "true"}
      aria-disabled={@entry.disabled && "true"}
      aria-selected="false"
    >
      <span data-text>{@entry.label}</span>
      <small :if={Options.hint(@entry)} data-hint>{Options.hint(@entry)}</small>
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
      data-keywords={Options.keywords(@entry) != "" && Options.keywords(@entry)}
      data-selectable={not @entry.disabled && "true"}
      data-disabled={@entry.disabled && "true"}
      aria-disabled={@entry.disabled && "true"}
      aria-selected="false"
    >
      {render_slot(@option_slot, @entry)}
    </div>
    """
  end

  defp option_id(id, value), do: "#{id}-opt-#{Base.url_encode64(value, padding: false)}"
end
