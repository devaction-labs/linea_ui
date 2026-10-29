defmodule LineaUI.Components.Pagination do
  @moduledoc ~S"""
  LineOne's pagination: a joined bar or `divided` buttons, `rounded` or `pill`, in three sizes.

      <.pagination page={@page} total_pages={10} patch={&"/orders?page=#{&1}"} />
      <.pagination page={@page} total_pages={10} navigate={&"/orders?page=#{&1}"} divided />
      <.pagination page={@page} total_pages={10} on_change="paginate" shape="pill" />

  Each page is a link when `patch`, `navigate` or `href` is given: a function from the page
  number to the path. Otherwise it is a button pushing `on_change` with `%{"page" => "3"}`
  (to `target` when given). Pages far from the current one collapse into an ellipsis:
  `siblings` pages are kept on each side of the current one and `boundaries` at each end.

  A list footer: `total_entries` and `page_size` add the "Showing 1–15 of 128" summary on
  the left (and work out `total_pages`), `page_sizes` a rows-per-page select pushing
  `on_page_size`.

      <.pagination
        page={@page}
        page_size={@per_page}
        total_entries={@total}
        page_sizes={[15, 30, 50]}
        on_change="paginate"
        on_page_size="per_page"
        summary="Mostrando %{first}–%{last} de %{total}"
        page_size_label="%{size} / página"
      />
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @item %{
    "sm" =>
      "flex h-7 min-w-[1.75rem] items-center justify-center px-2 text-xs-plus leading-tight transition-colors",
    "md" =>
      "flex h-8 min-w-[2rem] items-center justify-center px-3 leading-tight transition-colors",
    "lg" =>
      "flex h-10 min-w-[2.5rem] items-center justify-center px-3 text-sm-plus leading-tight transition-colors"
  }

  @arrow %{
    "sm" =>
      "flex size-7 items-center justify-center text-slate-500 transition-colors dark:text-navy-200",
    "md" =>
      "flex size-8 items-center justify-center text-slate-500 transition-colors dark:text-navy-200",
    "lg" =>
      "flex size-10 items-center justify-center text-slate-500 transition-colors dark:text-navy-200"
  }

  @icon %{"sm" => "size-4", "md" => "size-4", "lg" => "size-4.5"}

  @shapes %{"rounded" => "rounded-lg", "pill" => "rounded-full"}

  @focus "focus-visible:relative focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary/55 dark:focus-visible:outline-accent/55"

  @hover "hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"

  @fill "bg-slate-150 dark:bg-navy-500"

  @current "bg-primary text-white hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90"

  @disabled "pointer-events-none opacity-60"

  @page_size_select "form-select h-8 rounded-lg border border-slate-300 bg-white px-2.5 pr-8 text-xs-plus hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent"

  @joined_ends %{
    {"rounded", :first} => "rounded-l-lg",
    {"rounded", :last} => "rounded-r-lg",
    {"pill", :first} => "rounded-l-full",
    {"pill", :last} => "rounded-r-full",
    {"rounded", :middle} => nil,
    {"pill", :middle} => nil
  }

  @doc ~S"""
  Renders the page links between a previous and a next arrow.

      <.pagination page={@page} total_pages={@total} patch={&"/orders?page=#{&1}"} />
      <.pagination page={@page} total_pages={@total} on_change="paginate" target={@myself} />

  With `on_change="paginate"` every page and arrow is a button pushing
  `"paginate"` with `%{"page" => "3"}` (the page as a string):

      def handle_event("paginate", %{"page" => page}, socket),
        do: {:noreply, assign(socket, page: String.to_integer(page))}

  The arrow at either end and the ellipsis are inert `<span>`s.

  With `total_entries` or `page_sizes` the bar becomes a footer row: the summary
  (`role="status"`) on the left, the select and the pages on the right. The select sits in
  its own `<form>` and pushes `on_page_size` with `%{"page_size" => "30"}` (to `target`),
  so do not put the pagination inside another form.

      def handle_event("per_page", %{"page_size" => size}, socket),
        do: {:noreply, assign(socket, per_page: String.to_integer(size), page: 1)}
  """
  attr(:page, :integer, required: true, doc: "The current page, from 1.")

  attr(:total_pages, :integer,
    default: nil,
    doc:
      "How many pages there are. Worked out from `total_entries` and `page_size` when not given."
  )

  attr(:total_entries, :integer,
    default: nil,
    doc: "Rows across every page; shows the summary."
  )

  attr(:page_size, :integer, default: nil, doc: "Rows per page; the select's current value.")
  attr(:page_sizes, :list, default: [], doc: "Options of the rows-per-page select.")

  attr(:on_page_size, :any,
    default: nil,
    doc: ~S|Event name or `%JS{}` of the select's form, pushed with `%{"page_size" => "30"}`.|
  )

  attr(:summary, :string,
    default: "Showing %{first}–%{last} of %{total}",
    doc: "The summary text; `%{first}`, `%{last}` and `%{total}` are replaced."
  )

  attr(:page_size_label, :string,
    default: "%{size} / page",
    doc: "Text of each select option; `%{size}` is replaced."
  )

  attr(:page_size_aria, :string, default: "Rows per page", doc: "`aria-label` of the select.")
  attr(:siblings, :integer, default: 1, doc: "Pages kept on each side of the current one.")
  attr(:boundaries, :integer, default: 1, doc: "Pages kept at each end.")
  attr(:patch, :any, default: nil, doc: "A function from a page number to a path to patch to.")

  attr(:navigate, :any,
    default: nil,
    doc: "A function from a page number to a path to navigate to."
  )

  attr(:href, :any, default: nil, doc: "A function from a page number to a URL.")

  attr(:on_change, :any,
    default: nil,
    doc: """
    Used when no link function is given: an event name pushed with `%{"page" => "3"}`, or a
    `%JS{}` run on click (its `JS.push` carries the same `page` value).
    """
  )

  attr(:target, :any, default: nil, doc: "The `phx-target` of `on_change`.")
  attr(:divided, :boolean, default: false, doc: "Separate buttons instead of one joined bar.")
  attr(:shape, :string, default: "rounded", values: ~w(rounded pill))
  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:arrows, :boolean, default: true, doc: "Show the previous and next arrows.")
  attr(:prev_label, :string, default: "Previous page")
  attr(:next_label, :string, default: "Next page")

  attr(:page_label, :string,
    default: "Page %{page}",
    doc: "`aria-label` of each page; `%{page}` is replaced."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, default: %{"aria-label": "Pagination"})

  def pagination(assigns) do
    total = max(total_pages(assigns), 1)
    page = assigns.page |> max(1) |> min(total)

    items =
      [{:prev, page - 1, page == 1}]
      |> Enum.concat(
        Enum.map(window(page, total, assigns.siblings, assigns.boundaries), &to_item/1)
      )
      |> Enum.concat([{:next, page + 1, page == total}])
      |> Enum.filter(&shown?(&1, assigns.arrows))

    assigns
    |> assign(:page, page)
    |> assign(:icon, @icon)
    |> assign(:items, Enum.with_index(items))
    |> assign(:last, length(items) - 1)
    |> assign(:footer, footer?(assigns))
    |> render_pagination()
  end

  defp total_pages(%{total_pages: pages}) when is_integer(pages), do: pages

  defp total_pages(%{total_entries: total, page_size: size})
       when is_integer(total) and is_integer(size) and size > 0,
       do: div(total + size - 1, size)

  defp total_pages(_assigns), do: 1

  defp footer?(%{total_entries: nil, page_sizes: []}), do: false
  defp footer?(_assigns), do: true

  defp summary(%{total_entries: total, page_size: size, page: page, summary: text})
       when is_integer(size) do
    first = first_entry(total, page, size)

    text
    |> String.replace("%{first}", Integer.to_string(first))
    |> String.replace("%{last}", Integer.to_string(min(page * size, total)))
    |> String.replace("%{total}", Integer.to_string(total))
  end

  defp summary(%{total_entries: total, summary: text}) do
    text
    |> String.replace("%{first}", Integer.to_string(min(total, 1)))
    |> String.replace("%{last}", Integer.to_string(total))
    |> String.replace("%{total}", Integer.to_string(total))
  end

  defp first_entry(0, _page, _size), do: 0
  defp first_entry(_total, page, size), do: (page - 1) * size + 1

  defp size_label(label, size), do: String.replace(label, "%{size}", to_string(size))

  defp form_id(%{rest: %{id: id}}) when is_binary(id), do: id <> "-page-size"
  defp form_id(_assigns), do: nil

  defp to_item(:gap), do: {:gap, nil, true}
  defp to_item(number), do: {:page, number, false}

  defp shown?({kind, _number, _disabled}, false) when kind in [:prev, :next], do: false
  defp shown?(_item, _arrows), do: true

  @doc """
  The pages to show around `page` out of `total`: numbers, with `:gap` where pages are left out.

      iex> LineaUI.Components.Pagination.window(5, 10, 1, 1)
      [1, :gap, 4, 5, 6, :gap, 10]
  """
  @spec window(pos_integer(), pos_integer(), non_neg_integer(), non_neg_integer()) ::
          [pos_integer() | :gap]
  def window(page, total, siblings, boundaries) do
    low = page - siblings
    high = page + siblings

    1..total
    |> Enum.filter(fn n -> n <= boundaries or n > total - boundaries or n in low..high end)
    |> Enum.reduce([], &gap/2)
    |> Enum.reverse()
  end

  defp gap(n, [prev | _] = acc) when n == prev + 2, do: [n, prev + 1 | acc]
  defp gap(n, [prev | _] = acc) when n > prev + 2, do: [n, :gap | acc]
  defp gap(n, acc), do: [n | acc]

  defp render_pagination(%{footer: true} = assigns) do
    assigns = assign(assigns, :select_class, @page_size_select)

    ~H"""
    <div class={merge(["flex flex-wrap items-center justify-between gap-3 text-xs-plus", @class])}>
      <span
        :if={@total_entries}
        role="status"
        aria-live="polite"
        class="text-slate-500 dark:text-navy-200"
      >
        {summary(assigns)}
      </span>
      <span :if={!@total_entries}></span>
      <div class="flex flex-wrap items-center gap-3">
        <form
          :if={@page_sizes != []}
          id={form_id(assigns)}
          phx-change={@on_page_size}
          phx-target={@target}
        >
          <select name="page_size" aria-label={@page_size_aria} class={@select_class}>
            <option :for={size <- @page_sizes} value={size} selected={size == @page_size}>
              {size_label(@page_size_label, size)}
            </option>
          </select>
        </form>
        <.pager_nav {assigns} class={nil} />
      </div>
    </div>
    """
  end

  defp render_pagination(assigns), do: pager_nav(assigns)

  defp pager_nav(assigns) do
    ~H"""
    <nav class={@class} {@rest}>
      <ol class={["pagination", @divided && "space-x-1.5"]}>
        <li :for={{{kind, number, disabled}, index} <- @items} class={li_class(assigns, index)}>
          <.entry
            kind={kind}
            number={number}
            current={kind == :page and number == @page}
            class={entry_class(assigns, kind, number, disabled)}
            icon_class={@icon[@size]}
            label={entry_label(assigns, kind, number)}
            action={action(assigns, kind, number, disabled)}
          />
        </li>
      </ol>
    </nav>
    """
  end

  defp li_class(%{divided: true}, _index), do: nil

  defp li_class(%{shape: shape, last: last}, index),
    do: [@fill, @joined_ends[{shape, position(index, last)}]]

  defp position(0, _last), do: :first
  defp position(last, last), do: :last
  defp position(_index, _last), do: :middle

  defp entry_class(assigns, :gap, _number, _disabled),
    do: [@item[assigns.size], @shapes[assigns.shape], divided_fill(assigns)]

  defp entry_class(%{page: page} = assigns, :page, page, _disabled),
    do: [@item[assigns.size], @shapes[assigns.shape], @current, @focus]

  defp entry_class(assigns, :page, _number, _disabled),
    do: [@item[assigns.size], @shapes[assigns.shape], divided_fill(assigns), @hover, @focus]

  defp entry_class(assigns, _arrow, _number, disabled),
    do: [
      @arrow[assigns.size],
      @shapes[assigns.shape],
      divided_fill(assigns),
      @hover,
      @focus,
      disabled && @disabled
    ]

  defp divided_fill(%{divided: true}), do: @fill
  defp divided_fill(_assigns), do: nil

  defp entry_label(assigns, :prev, _number), do: assigns.prev_label
  defp entry_label(assigns, :next, _number), do: assigns.next_label

  defp entry_label(assigns, :page, number),
    do: String.replace(assigns.page_label, "%{page}", Integer.to_string(number))

  defp entry_label(_assigns, _kind, _number), do: nil

  defp action(_assigns, :gap, _number, _disabled), do: :none
  defp action(_assigns, _kind, _number, true), do: :none

  defp action(%{patch: fun}, _kind, n, _disabled) when is_function(fun, 1),
    do: {:link, %{patch: fun.(n)}}

  defp action(%{navigate: fun}, _kind, n, _disabled) when is_function(fun, 1),
    do: {:link, %{navigate: fun.(n)}}

  defp action(%{href: fun}, _kind, n, _disabled) when is_function(fun, 1),
    do: {:link, %{href: fun.(n)}}

  defp action(%{on_change: %JS{} = js} = assigns, _kind, n, _disabled),
    do: {:button, %{"phx-click" => js, "phx-value-page" => n, "phx-target" => assigns.target}}

  defp action(%{on_change: event} = assigns, _kind, n, _disabled) when is_binary(event),
    do: {:button, %{"phx-click" => event, "phx-value-page" => n, "phx-target" => assigns.target}}

  defp action(_assigns, _kind, _number, _disabled), do: :none

  defp entry(%{action: {:link, attrs}} = assigns) do
    assigns = assign(assigns, :attrs, attrs)

    ~H"""
    <.link
      class={@class}
      aria-label={@label}
      aria-current={@current && "page"}
      {@attrs}
    ><.entry_content kind={@kind} number={@number} icon_class={@icon_class} /></.link>
    """
  end

  defp entry(%{action: {:button, attrs}} = assigns) do
    assigns = assign(assigns, :attrs, attrs)

    ~H"""
    <button
      type="button"
      class={@class}
      aria-label={@label}
      aria-current={@current && "page"}
      {@attrs}
    ><.entry_content kind={@kind} number={@number} icon_class={@icon_class} /></button>
    """
  end

  defp entry(assigns) do
    ~H"""
    <span
      class={@class}
      aria-label={@label}
      aria-current={@current && "page"}
      aria-disabled={@kind in [:prev, :next] && "true"}
      aria-hidden={@kind == :gap && "true"}
    ><.entry_content kind={@kind} number={@number} icon_class={@icon_class} /></span>
    """
  end

  defp entry_content(%{kind: :prev} = assigns) do
    ~H"""
    <.glyph name={:chevron_left} class={@icon_class} />
    """
  end

  defp entry_content(%{kind: :next} = assigns) do
    ~H"""
    <.glyph name={:chevron_right} class={@icon_class} />
    """
  end

  defp entry_content(%{kind: :gap} = assigns), do: ~H"..."

  defp entry_content(assigns), do: ~H"{@number}"
end
