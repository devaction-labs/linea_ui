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

  @footers ~w(user version none)
  @statuses ~w(ok warning down)

  @doc """
  What the foot of the menu shows, as `"user"`, `"version"`, `"none"` or `"default"` (each format's own: the
  user card of the `tree`, the plan card of `sections`, the avatar of the `rail`). `version` is the
  already-normalised version (`version/1`) or `nil`.

  Order: the `footer` attribute, then the deprecated `show_user={false}`, then a `version` attribute, then the
  `:shell` config (`footer`, `show_user: false`, `version`).
  """
  @spec footer(term(), term(), term(), map() | nil) :: String.t()
  def footer(footer, show_user, version_attr, version) do
    cond do
      value = footer(footer) -> value
      show_user == false -> legacy(version)
      version_attr not in [nil, ""] -> "version"
      value = footer(config(:footer)) -> value
      show_user == nil and config(:show_user) == false -> legacy(version)
      version -> "version"
      true -> "default"
    end
  end

  defp footer(nil), do: nil

  defp footer(value) when is_atom(value) or is_binary(value) do
    case to_string(value) do
      footer when footer in @footers -> footer
      _other -> nil
    end
  end

  defp footer(_value), do: nil

  defp legacy(nil), do: "none"
  defp legacy(_version), do: "version"

  @doc """
  The version of the system as the foot draws it: a string (`"v1.4.2"`) or `%{version, build, href | navigate |
  patch, label, title, status}`, else the `version` of the `:shell` config. `nil` when there is none.
  """
  @spec version(term()) :: map() | nil
  def version(value), do: value |> Kernel.||(config(:version)) |> normalize_version()

  defp normalize_version(version) when is_binary(version) and version != "",
    do: normalize_version(%{version: version})

  defp normalize_version(%{version: version} = data) when is_binary(version) and version != "" do
    build = present(data[:build])

    %{
      version: version,
      build: build,
      aria: "Version " <> version <> if(build, do: " (#{build})", else: ""),
      link: if(Enum.any?([:navigate, :patch, :href], &is_binary(data[&1])), do: link_attrs(data)),
      label: present(data[:label]) || "What's new",
      title: present(data[:title]),
      status: status(data[:status])
    }
  end

  defp normalize_version(_none), do: nil

  defp present(value) when is_binary(value) and value != "", do: value
  defp present(_value), do: nil

  defp status(value) when is_atom(value) or is_binary(value) do
    case to_string(value) do
      status when status in @statuses -> status
      _other -> "ok"
    end
  end

  defp status(_value), do: "ok"

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

    collapsible = Map.get(group, :collapsible, true) != false
    active = Enum.any?(items, &(&1.active or &1.deep))

    %{
      kind: :group,
      id: id,
      label: label,
      icon: icon(group[:icon]),
      items: items,
      collapsible: collapsible,
      open: open?(group, collapsible, active),
      footer: group[:footer] == true,
      link: group_link(group, items),
      action: action(group[:action], current),
      try: tries(group[:try], current),
      active: active,
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
    active = active?(item, current)
    deep = active or Enum.any?(children, &(&1.active or &1.deep))

    collapsible =
      format == "tree" and children != [] and Map.get(item, :collapsible, true) != false

    %{
      kind: :item,
      tree_id: "#{id}-t",
      collapsible: collapsible,
      open: open?(item, collapsible, deep),
      label: item[:label],
      icon: icon(item[:icon]),
      link: link_attrs(item),
      count: item[:count],
      badge: item[:badge],
      color: color,
      style: style,
      children: children,
      branch: branch(children, format),
      active: active,
      deep: deep
    }
  end

  # A toggle starts closed unless it holds the active route; `open: true | false` overrides. What cannot be
  # toggled is always shown.
  defp open?(_entry, false, _holds_active), do: true
  defp open?(%{open: open}, true, _holds_active) when is_boolean(open), do: open
  defp open?(_entry, true, holds_active), do: holds_active

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
