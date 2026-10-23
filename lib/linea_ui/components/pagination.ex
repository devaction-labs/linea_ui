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
  """

  use LineaUI.Component

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

  @hover "hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"

  @fill "bg-slate-150 dark:bg-navy-500"

  @current "bg-primary text-white hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90"

  @disabled "pointer-events-none opacity-60"

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
  """
  attr(:page, :integer, required: true, doc: "The current page, from 1.")
  attr(:total_pages, :integer, required: true, doc: "How many pages there are.")
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
  attr(:class, :any, default: nil)
  attr(:rest, :global, default: %{"aria-label": "Pagination"})

  def pagination(assigns) do
    total = max(assigns.total_pages, 1)
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
    |> render_pagination()
  end

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

  defp render_pagination(assigns) do
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
            label={entry_label(assigns, kind)}
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
    do: [@item[assigns.size], @shapes[assigns.shape], @current]

  defp entry_class(assigns, :page, _number, _disabled),
    do: [@item[assigns.size], @shapes[assigns.shape], divided_fill(assigns), @hover]

  defp entry_class(assigns, _arrow, _number, disabled),
    do: [
      @arrow[assigns.size],
      @shapes[assigns.shape],
      divided_fill(assigns),
      @hover,
      disabled && @disabled
    ]

  defp divided_fill(%{divided: true}), do: @fill
  defp divided_fill(_assigns), do: nil

  defp entry_label(assigns, :prev), do: assigns.prev_label
  defp entry_label(assigns, :next), do: assigns.next_label
  defp entry_label(_assigns, _kind), do: nil

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
    ><.entry_content kind={@kind} number={@number} icon_class={@icon_class} /></span>
    """
  end

  defp entry_content(%{kind: :prev} = assigns) do
    ~H"""
    <svg
      class={@icon_class}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
    </svg>
    """
  end

  defp entry_content(%{kind: :next} = assigns) do
    ~H"""
    <svg
      class={@icon_class}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
    </svg>
    """
  end

  defp entry_content(%{kind: :gap} = assigns), do: ~H"..."

  defp entry_content(assigns), do: ~H"{@number}"
end
