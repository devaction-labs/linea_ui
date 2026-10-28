defmodule LineaUI.Components.Treeview do
  @moduledoc """
  LineOne's tree view: a hierarchical list whose branches expand and collapse.

      <.treeview id="files">
        <.tree_item id="app" label="Application" expanded>
          <.tree_item label="Chrome" />
          <.tree_item label="VS Code" />
        </.tree_item>
        <.tree_item id="docs" label="Document">
          <.tree_item label="React App" />
        </.tree_item>
      </.treeview>

  An item with children is a branch (a native `<details>`), one without is a leaf. Give an
  item an `:icon` slot and it takes LineOne's "advanced" look (folder icons, darker text):

      <.tree_item label="Design">
        <:icon><svg class="size-6 text-warning">…</svg></:icon>
        <.tree_item label="Web Apps"><:icon>…</:icon></.tree_item>
      </.tree_item>

  ## State

  A branch opens from its `expanded` attr, or from the treeview's `expanded` list of item ids,
  and toggles in the browser without a round trip. A branch the person toggled stays that way
  across patches; when the server changes `expanded` for it, the server wins.

  ## Events

  `on_toggle` runs when the person opens or closes a branch, `on_select` when they click a
  leaf (or press Enter on it). See `treeview/1` for the payloads.

  ## Streams

      <.treeview id="files" rows={@streams.files}>
        <:row :let={{_dom_id, file}}>
          <.tree_item tag="div" id={"file-\#{file.id}"} label={file.name} />
        </:row>
      </.treeview>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @header "flex min-w-0 cursor-pointer items-center rounded-sm px-2 py-1 tracking-wide outline-hidden transition-all hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100 focus-visible:ring-2 focus-visible:ring-primary/55 dark:focus-visible:ring-accent/55"

  @selected "bg-primary/10 text-primary hover:bg-primary/10 hover:text-primary focus:bg-primary/10 focus:text-primary dark:bg-accent/15 dark:text-accent-light dark:hover:bg-accent/15 dark:hover:text-accent-light dark:focus:bg-accent/15 dark:focus:text-accent-light"

  @layouts %{
    basic: "space-x-1.5",
    advanced: "text-slate-800 dark:text-navy-100"
  }

  @doc """
  Renders the tree's root list.

  `on_toggle` (an event name or a `%JS{}`) is pushed with `%{"id" => item_id, "expanded" => boolean}`
  when the person opens or closes a branch. `on_select` is pushed with `%{"id" => item_id}` when a
  leaf is clicked or gets Enter. Both go to `target` when given; a `%JS{}` is executed instead.

      <.treeview id="files" expanded={@open_ids} on_toggle="toggled" on_select="opened">
        <.tree_item id="src" label="src">
          <.tree_item id="src/app.ex" label="app.ex" />
        </.tree_item>
      </.treeview>

      def handle_event("toggled", %{"id" => id, "expanded" => open?}, socket), do: ...
      def handle_event("opened", %{"id" => id}, socket), do: ...
  """
  attr(:id, :string, required: true)

  attr(:expanded, :list,
    default: [],
    doc: "Ids of the branches that are open, in addition to each item's own `expanded`."
  )

  attr(:on_toggle, :any,
    default: nil,
    doc: "Event name or `%JS{}`; pushed with `%{\"id\" => id, \"expanded\" => boolean}`."
  )

  attr(:on_select, :any,
    default: nil,
    doc: "Event name or `%JS{}`; pushed with `%{\"id\" => id}` when a leaf is picked."
  )

  attr(:target, :any, default: nil, doc: "The `phx-target` the events go to.")
  attr(:rows, :list, default: nil, doc: "A list or a stream (`@streams.x`) rendered by `:row`.")
  attr(:row_id, :any, default: nil, doc: "A function giving each row's DOM id (streams give it).")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)
  slot(:row, doc: "Renders one row; takes the row (`{dom_id, item}` for a stream).")

  def treeview(assigns) do
    assigns
    |> assign(:stream?, match?(%Phoenix.LiveView.LiveStream{}, assigns.rows))
    |> assign(:row_id, row_id(assigns))
    |> render_treeview()
  end

  defp row_id(%{row_id: nil, rows: %Phoenix.LiveView.LiveStream{}}), do: fn {id, _row} -> id end
  defp row_id(%{row_id: row_id}), do: row_id

  defp render_treeview(assigns) do
    ~H"""
    <ul
      id={@id}
      role="tree"
      class={merge(["space-y-1 font-inter font-medium", @class])}
      phx-hook="LineaUI.Treeview"
      phx-update={@stream? && "stream"}
      phx-target={@target}
      data-expanded={Jason.encode!(@expanded)}
      data-on-toggle={@on_toggle}
      data-on-select={@on_select}
      {@rest}
    >
      {render_slot(@inner_block)}
      <li :for={row <- @rows || []} id={@row_id && @row_id.(row)} role="none">
        {render_slot(@row, row)}
      </li>
    </ul>
    """
  end

  @doc """
  Renders one item: a branch when it has children, a leaf when it does not.

  `id` names the item in events and in the treeview's `expanded` list. `tag="div"` renders it
  without its own `<li>`, for a treeview `:row` that already sits in one.

      <.tree_item id="design" label="Design" expanded>
        <:icon><svg class="size-6 text-warning">…</svg></:icon>
        <.tree_item id="web" label="Web Apps" />
      </.tree_item>
  """
  attr(:id, :string, default: nil, doc: "Names the item in events and in `expanded`.")
  attr(:label, :string, default: nil)
  attr(:expanded, :boolean, default: false, doc: "Whether the branch is open (server state).")

  attr(:selected, :boolean,
    default: false,
    doc: "Marks the item as the chosen one: `aria-selected` and a tinted header."
  )

  attr(:tag, :string, default: "li", values: ~w(li div))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:icon, doc: "An icon before the label; switches to LineOne's advanced look.")
  slot(:inner_block, doc: "The children; makes the item a branch.")

  def tree_item(assigns) do
    assigns
    |> assign(:item_id, assigns.id || gen_id("tree-item"))
    |> assign(:layout, layout(assigns))
    |> assign(:branch?, Enum.any?(assigns.inner_block, &filled?/1))
    |> render_item()
  end

  defp layout(%{icon: []}), do: :basic
  defp layout(_assigns), do: :advanced

  defp filled?(%{inner_block: render}) when is_function(render, 2),
    do: content?(render.(nil, nil))

  defp filled?(%{inner_block: rendered}), do: content?(rendered)

  defp content?(%Phoenix.LiveView.Rendered{static: [text]}), do: String.trim(text) != ""
  defp content?(_rendered), do: true

  defp render_item(%{branch?: false} = assigns) do
    assigns =
      assign(assigns, :classes, [@header, @layouts[assigns.layout], assigns.selected && @selected])

    ~H"""
    <.dynamic_tag tag_name={@tag} role={@tag == "div" && "none"} class={@class} {@rest}>
      <div
        tabindex="0"
        role="treeitem"
        class={@classes}
        aria-selected={@selected && "true"}
        data-tree-leaf={@item_id}
      >
        <div class={["flex size-5 items-center justify-center", @layout == :advanced && "mr-1"]}>
        </div>
        <span :for={icon <- @icon} class="mr-3 flex">{render_slot(icon)}</span>
        <span class="truncate">{@label}</span>
      </div>
    </.dynamic_tag>
    """
  end

  defp render_item(assigns) do
    assigns =
      assign(assigns, :classes, [
        "tree-header list-none",
        @header,
        @layouts[assigns.layout],
        assigns.selected && @selected
      ])

    ~H"""
    <.dynamic_tag tag_name={@tag} role={@tag == "div" && "none"} class={@class} {@rest}>
      <details
        id={@item_id}
        class="tree-item [&[open]>summary]:text-slate-800 [&[open]>summary_.tree-chevron]:rotate-90 dark:[&[open]>summary]:text-navy-100"
        open={@expanded}
        data-tree-item={@item_id}
        data-server-open={bool(@expanded)}
        phx-mounted={JS.ignore_attributes(["open"])}
      >
        <summary
          role="treeitem"
          class={@classes}
          aria-expanded={bool(@expanded)}
          aria-selected={@selected && "true"}
        >
          <span class={[
            "btn size-5 rounded-lg p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25",
            @layout == :advanced && "mr-1"
          ]}>
            <.glyph name={:chevron_right_solid} class="tree-chevron size-4 transition-transform" />
          </span>
          <span :for={icon <- @icon} class="mr-3 flex">{render_slot(icon)}</span>
          <span class="truncate">{@label}</span>
        </summary>
        <ul role="group" class="mt-1 space-y-1 pl-4">
          {render_slot(@inner_block)}
        </ul>
      </details>
    </.dynamic_tag>
    """
  end
end
