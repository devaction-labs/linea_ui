defmodule LineaUI.Components.Pagination do
  @moduledoc ~S"""
  The pagination: the design canvas pager by default (`shape="canvas"`), or LineOne's joined bar or
  `divided` buttons, `rounded` or `pill` (`shape="rounded"` is the old default), in three sizes.

      <.pagination page={@page} total_pages={10} patch={&"/orders?page=#{&1}"} />
      <.pagination page={@page} total_pages={10} navigate={&"/orders?page=#{&1}"} divided shape="rounded" />
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
      "flex h-7 min-w-[1.75rem] items-center justify-center px-2 text-[12.5px] leading-tight transition-colors",
    "md" =>
      "flex h-8 min-w-[2rem] items-center justify-center px-3 text-[13.5px] leading-tight transition-colors",
    "lg" =>
      "flex h-10 min-w-[2.5rem] items-center justify-center px-3.5 text-[14.5px] leading-tight transition-colors"
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

  @shapes %{"rounded" => "rounded-lg", "pill" => "rounded-full", "canvas" => "rounded-[9px]"}

  @focus "focus-visible:relative focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary/55 dark:focus-visible:outline-accent/55"

  @hover "hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"

  @fill "bg-slate-150 dark:bg-navy-500"

  @current "bg-slate-900 text-white hover:bg-slate-900 focus:bg-slate-900 active:bg-slate-900 dark:bg-navy-50 dark:text-navy-900 dark:hover:bg-navy-50 dark:focus:bg-navy-50 dark:active:bg-navy-50"

  @disabled "pointer-events-none opacity-60"

  @page_size_select "form-select h-8 rounded-lg border border-slate-300 bg-white pr-7 pl-3 text-[12.5px] font-medium text-slate-700 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:text-navy-100 dark:hover:border-navy-400 dark:focus:border-accent"

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

  The arrow at either end and the ellipsis (`…`) are inert `<span>`s.

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

  attr(:shape, :string,
    default: "canvas",
    values: ~w(canvas rounded pill),
    doc:
      "`canvas` (the default) is the design canvas pager: square-ish ink current page, mono numbers, the arrows as 28px bordered circles after the pages (not dimmed at either end). The old LineOne look is `rounded` (or `pill`)."
  )

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

  # What an entry of the bar reads; the entries are comprehension variables, so a new page
  # sends the entries that changed, not the bar.
  @item_deps ~w(siblings boundaries arrows shape size divided prev_label next_label page_label
                patch navigate href on_change target)a

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

    last = length(items) - 1
    page_deps = [:page, :total_pages, :total_entries, :page_size]

    assigns =
      assigns
      |> assign_derived(:page, page_deps, fn -> page end)
      |> assign_derived(:icon, [], fn -> @icon end)
      |> assign_derived(:last, page_deps ++ [:siblings, :boundaries, :arrows], fn -> last end)
      |> assign_derived(:footer, [:total_entries, :page_sizes], fn -> footer?(assigns) end)

    assigns
    |> assign_derived(:items, page_deps ++ @item_deps, fn ->
      items |> Enum.with_index() |> Enum.map(&item(assigns, &1))
    end)
    |> render_pagination()
  end

  # The comprehension key: the arrows and the pages keep theirs as the window moves.
  defp item_key(:page, number, _index), do: number
  defp item_key(:gap, _number, index), do: {:gap, index}
  defp item_key(arrow, _number, _index), do: arrow

  defp item(assigns, {{kind, number, disabled}, index}) do
    %{
      key: item_key(kind, number, index),
      kind: kind,
      number: number,
      current: kind == :page and number == assigns.page,
      li_class: li_class(assigns, index),
      class: entry_class(assigns, kind, number, disabled),
      label: entry_label(assigns, kind, number),
      action: action(assigns, kind, number, disabled)
    }
  end

  defp total_pages(%{total_pages: pages}) when is_integer(pages), do: pages

  defp total_pages(%{total_entries: total, page_size: size})
       when is_integer(total) and is_integer(size) and size > 0,
       do: div(total + size - 1, size)

  defp total_pages(_assigns), do: 1

  defp footer?(%{total_entries: nil, page_sizes: []}), do: false
  defp footer?(_assigns), do: true

  # `%{first}`, `%{last}` and `%{total}` of the summary are semibold and in the text color,
  # the words around them stay soft
  defp summary(total, size, page, text) when is_integer(size) do
    summary_html(text, %{
      "%{first}" => first_entry(total, page, size),
      "%{last}" => min(page * size, total),
      "%{total}" => total
    })
  end

  defp summary(total, _size, _page, text) do
    summary_html(text, %{"%{first}" => min(total, 1), "%{last}" => total, "%{total}" => total})
  end

  defp summary_html(text, numbers) do
    ~r/%\{(?:first|last|total)\}/
    |> then(&String.split(text, &1, include_captures: true))
    |> Enum.map(fn part ->
      case numbers do
        %{^part => number} ->
          "<b>#{number}</b>"

        _ ->
          part |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
      end
    end)
    |> Phoenix.HTML.raw()
  end

  defp first_entry(0, _page, _size), do: 0
  defp first_entry(_total, page, size), do: (page - 1) * size + 1

  defp size_label(label, size), do: String.replace(label, "%{size}", to_string(size))

  defp form_id(%{id: id}) when is_binary(id), do: id <> "-page-size"
  defp form_id(_rest), do: nil

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
    assigns = assign_derived(assigns, :select_class, [], fn -> @page_size_select end)

    ~H"""
    <div class={merge(["flex flex-wrap items-center justify-between gap-3 text-[12.5px]", @class])}>
      <span
        :if={@total_entries}
        role="status"
        aria-live="polite"
        class={[
          "text-slate-500 dark:text-navy-200",
          (@shape == "canvas" && "[&_b]:font-normal") ||
            "[&_b]:font-semibold [&_b]:text-slate-700 dark:[&_b]:text-navy-50"
        ]}
      >
        {summary(@total_entries, @page_size, @page, @summary)}
      </span>
      <span :if={!@total_entries}></span>
      <div class="flex flex-wrap items-center gap-3">
        <form
          :if={@page_sizes != []}
          id={form_id(@rest)}
          phx-change={@on_page_size}
          phx-target={@target}
        >
          <select name="page_size" aria-label={@page_size_aria} class={@select_class}>
            <option :for={size <- @page_sizes} value={size} selected={size == @page_size}>
              {size_label(@page_size_label, size)}
            </option>
          </select>
        </form>
        <.pager_nav
          class={nil}
          rest={@rest}
          divided={@divided}
          shape={@shape}
          items={@items}
          icon={@icon}
          size={@size}
        />
      </div>
    </div>
    """
  end

  defp render_pagination(assigns), do: pager_nav(assigns)

  defp pager_nav(assigns) do
    ~H"""
    <nav class={@class} {@rest}>
      <ol class={[
        "pagination",
        @divided && "space-x-1.5",
        @shape == "canvas" && "!flex items-center gap-x-1"
      ]}>
        <li :for={item <- @items} :key={item.key} class={item.li_class}>
          <.entry
            kind={item.kind}
            number={item.number}
            current={item.current}
            class={item.class}
            icon_class={@icon[@size]}
            label={item.label}
            action={item.action}
          />
        </li>
      </ol>
    </nav>
    """
  end

  defp li_class(%{shape: "canvas", last: last, arrows: true}, index) when index == 0,
    do: ["order-1 ml-1.5", last && nil]

  defp li_class(%{shape: "canvas", last: last, arrows: true}, last), do: "order-2 ml-1.5"
  defp li_class(%{shape: "canvas"}, _index), do: nil

  defp li_class(%{divided: true}, _index), do: nil

  defp li_class(%{shape: shape, last: last}, index),
    do: [@fill, @joined_ends[{shape, position(index, last)}]]

  defp position(0, _last), do: :first
  defp position(last, last), do: :last
  defp position(_index, _last), do: :middle

  defp entry_class(%{shape: "canvas", page: page}, :page, page, _disabled),
    do:
      "grid h-[30px] min-w-[30px] place-items-center rounded-[9px] bg-slate-900 px-2 font-mono text-[12.5px] font-medium text-white dark:bg-navy-50 dark:text-navy-900"

  defp entry_class(%{shape: "canvas"}, :page, _number, _disabled),
    do:
      "grid h-[30px] min-w-[30px] place-items-center rounded-[9px] px-2 font-mono text-[12.5px] font-medium text-slate-500 hover:bg-slate-100 dark:text-navy-200 dark:hover:bg-navy-600"

  defp entry_class(%{shape: "canvas"}, :gap, _number, _disabled),
    do: "grid h-[30px] min-w-[30px] place-items-center font-mono text-[12.5px] text-slate-500"

  # the canvas `sg-ib sm`: a 28px panel circle with an inset line; an arrow at either end stays
  # inert (a `<span aria-disabled>`) but is not dimmed, as on the canvas
  defp entry_class(%{shape: "canvas"}, _arrow, _number, _disabled),
    do:
      "grid size-7 place-items-center rounded-[var(--pill-in,8px)] bg-[var(--panel)] text-[var(--muted)] shadow-[inset_0_0_0_1px_var(--line)] hover:bg-[var(--hover)]"

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
    assigns = assign_derived(assigns, :attrs, [:action], fn -> attrs end)

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
    assigns = assign_derived(assigns, :attrs, [:action], fn -> attrs end)

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

  defp entry_content(%{kind: :gap} = assigns), do: ~H"…"

  defp entry_content(assigns), do: ~H"{@number}"
end
