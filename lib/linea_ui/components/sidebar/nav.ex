defmodule LineaUI.Components.Sidebar.Nav do
  @moduledoc false
  # The menu data of the sidebar. Kept apart from `LineaUI.Components.Sidebar` because `use LineaUI`
  # imports that module into the host app, and these helpers must not leak into it.

  @formats ~w(sections rail tree)
  @palette ~w(blue green rose violet orange ink)

  @icons %{
    "home" => "huge-home-01",
    "spark" => "huge-sparkles",
    "cart" => "huge-shopping-cart-01",
    "doc" => "huge-file-01",
    "users" => "huge-user-multiple",
    "user" => "huge-user",
    "wallet" => "huge-wallet-01",
    "bank" => "huge-bank",
    "chart" => "huge-chart-histogram",
    "box" => "huge-package",
    "truck" => "huge-delivery-truck-01",
    "help" => "huge-information-circle",
    "settings" => "huge-settings-02",
    "bell" => "huge-notification-03",
    "tag" => "huge-tag-01",
    "kanban" => "huge-kanban",
    "invoice" => "huge-invoice-01",
    "cancel" => "huge-cancel-circle",
    "calendar" => "huge-calendar-03",
    "goal" => "huge-flag-02",
    "clock" => "huge-clock-01",
    "card" => "huge-credit-card",
    "trend" => "huge-chart-line-data-01",
    "money" => "huge-money-03",
    "message" => "huge-message-01",
    "flash" => "huge-flash",
    "pin" => "huge-location-01",
    "heart" => "huge-favourite",
    "globe" => "huge-globe-02",
    "filter" => "huge-filter-horizontal",
    "sidebar" => "huge-sidebar-left",
    "add" => "huge-add-01"
  }

  @icon_table "  | Name | Icon |\n  |---|---|\n" <>
                (@icons
                 |> Enum.sort()
                 |> Enum.map_join("\n", fn {name, huge} -> "  | `#{name}` | `#{huge}` |" end))

  @doc false
  def icon_table, do: @icon_table

  @doc false
  def icon_names, do: @icons

  @doc """
  The menu as the assigns of `sidebar/1` and `shell/1` read it: the `format` argument, else the one of
  `config :linea_ui, :shell, sidebar: …`, else `"sections"`.
  """
  @spec format(term()) :: String.t()
  def format(value) do
    case to_string(value || config(:sidebar) || "sections") do
      format when format in @formats -> format
      _other -> "sections"
    end
  end

  @doc false
  def nav(nil, assigns) do
    case config(:nav) do
      {module, function} -> apply(module, function, [assigns])
      list when is_list(list) -> list
      _none -> []
    end
  end

  def nav(list, _assigns) when is_list(list), do: list

  defp config(key), do: :linea_ui |> Application.get_env(:shell, []) |> Keyword.get(key)

  # ---------------------------------------------------------------- the menu data

  @doc false
  @spec build([map()], String.t() | nil, String.t(), String.t()) :: map()
  def build(nav, current, format, id) do
    entries =
      nav
      |> Enum.filter(&shown?(&1, format))
      |> Enum.with_index()
      |> Enum.map(fn {entry, index} -> entry(entry, current, "#{id}-g#{index}", format) end)

    {footer, body} = Enum.split_with(entries, &(&1.kind == :group and &1.footer))
    groups = Enum.filter(body, &(&1.kind == :group))
    {home, more} = body |> Enum.filter(&(&1.kind == :item)) |> List.pop_at(0)

    %{
      body: body,
      footer: footer,
      footer_label: footer |> List.first(%{}) |> Map.get(:label),
      footer_items: Enum.flat_map(footer, & &1.items),
      home: home,
      more: more,
      groups: groups,
      module: Enum.find(groups, & &1.active) || List.first(groups)
    }
  end

  defp shown?(%{formats: formats}, format) when is_list(formats),
    do: format in Enum.map(formats, &to_string/1)

  defp shown?(_entry, _format), do: true

  defp entry(%{group: label} = group, current, id, format) do
    items =
      group
      |> Map.get(:items, [])
      |> Enum.filter(&shown?(&1, format))
      |> Enum.with_index()
      |> Enum.map(fn {entry, index} -> entry(entry, current, "#{id}-#{index}", format) end)

    %{
      kind: :group,
      id: id,
      label: label,
      icon: icon(group[:icon]),
      items: items,
      collapsible: Map.get(group, :collapsible, true) != false,
      footer: group[:footer] == true,
      link: group_link(group, items),
      action: action(group[:action], current),
      try: tries(group[:try], current),
      active: Enum.any?(items, &(&1.active or &1.deep)),
      deep: false
    }
  end

  defp entry(item, current, id, format) do
    children =
      item
      |> Map.get(:children, [])
      |> Enum.filter(&shown?(&1, format))
      |> Enum.with_index()
      |> Enum.map(fn {child, index} -> entry(child, current, "#{id}-#{index}", format) end)

    {color, style} = color(item[:color])

    %{
      kind: :item,
      label: item[:label],
      icon: icon(item[:icon]),
      link: link_attrs(item),
      count: item[:count],
      badge: item[:badge],
      color: color,
      style: style,
      children: children,
      branch: branch(children, format),
      active: active?(item, current),
      deep: active?(item, current) or Enum.any?(children, &(&1.active or &1.deep))
    }
  end

  # The connector of the `tree` format, drawn once per group: a trunk, a rounded branch and a node per child,
  # and the way down to the active child in the accent. Rows are 34px plus 1px of gap, the first centre at 21.
  defp branch(children, "tree") when children != [] do
    centers = Enum.map(0..(length(children) - 1)//1, &(21 + &1 * 35))
    last = List.last(centers)
    active = Enum.find_index(children, & &1.active)

    %{
      height: last + 6,
      trunk: "M1 0V#{last - 8}.0" <> Enum.map_join(centers, &spur/1),
      path: active && "M1 0V#{Enum.at(centers, active) - 8}.0" <> curve(Enum.at(centers, active)),
      nodes:
        Enum.map(centers, &%{y: &1})
        |> Enum.with_index()
        |> Enum.map(fn {node, i} -> Map.put(node, :on, i == active) end)
    }
  end

  defp branch(_children, _format), do: nil

  defp spur(y), do: "M1 #{y - 8}.0" <> curve(y)
  defp curve(y), do: "Q1 #{y}.0 9 #{y}.0H12"

  defp action(nil, _current), do: nil

  defp action(action, _current),
    do: %{label: action[:label], icon: icon(action[:icon] || "add"), link: link_attrs(action)}

  defp tries(nil, _current), do: nil

  defp tries(try, current),
    do: %{
      label: try[:label],
      items: Enum.map(try[:items] || [], &entry(&1, current, "try", "rail"))
    }

  defp group_link(group, items) do
    case link_attrs(group) do
      %{href: "#"} -> items |> Enum.find_value(&first_link/1) || %{href: "#"}
      link -> link
    end
  end

  defp first_link(%{kind: :group, items: items}), do: Enum.find_value(items, &first_link/1)
  defp first_link(%{link: %{href: "#"}}), do: nil
  defp first_link(%{link: link}), do: link

  @doc false
  def link_attrs(%{navigate: to}) when is_binary(to), do: %{navigate: to}
  def link_attrs(%{patch: to}) when is_binary(to), do: %{patch: to}
  def link_attrs(%{href: to}) when is_binary(to), do: %{href: to}
  def link_attrs(_entry), do: %{href: "#"}

  defp icon(nil), do: nil
  defp icon(name) when is_binary(name), do: Map.get(@icons, name, name)

  defp color(nil), do: {nil, nil}
  defp color(name) when name in @palette, do: {name, nil}
  defp color(css) when is_binary(css), do: {nil, "background:" <> css}

  defp active?(%{active: true}, _current), do: true
  defp active?(_entry, nil), do: false

  defp active?(entry, current) do
    case entry[:navigate] || entry[:patch] || entry[:href] do
      url when is_binary(url) -> key(url) == key(current)
      _none -> false
    end
  end

  defp key(url) do
    uri = URI.parse(url)
    {uri.path, uri.query}
  end

  @doc false
  def initials(%{initials: initials}) when is_binary(initials), do: initials

  def initials(%{name: name}) when is_binary(name) do
    name |> String.split() |> Enum.take(2) |> Enum.map_join(&String.first/1) |> String.upcase()
  end

  def initials(_user), do: nil

  @doc false
  def dot(extra) do
    {color, style} = color(extra[:color])
    %{color: color, style: style, icon: icon(extra[:icon]), link: link_attrs(extra)}
  end
end
