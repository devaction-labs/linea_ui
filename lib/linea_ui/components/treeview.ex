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

  @header "flex cursor-pointer items-center rounded-sm px-2 py-1 tracking-wide outline-hidden transition-all hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100"

  @layouts %{
    basic: "space-x-1.5",
    advanced: "text-slate-800 dark:text-navy-100"
  }

  @doc """
  Renders the tree's root list.

  `on_toggle` (an event name or a `%JS{}`) is pushed with `%{"id" => item_id, "expanded" => boolean}`
  when the person opens or closes a branch. `on_select` is pushed with `%{"id" => item_id}` when a
  leaf is clicked. Both go to `target` when given.
  """
  attr(:id, :string, required: true)

  attr(:expanded, :list,
    default: [],
    doc: "Ids of the branches that are open, in addition to each item's own `expanded`."
  )

  attr(:on_toggle, :any, default: nil)
  attr(:on_select, :any, default: nil)
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
  """
  attr(:id, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:expanded, :boolean, default: false)
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
    assigns = assign(assigns, :classes, [@header, @layouts[assigns.layout]])

    ~H"""
    <.dynamic_tag tag_name={@tag} role={@tag == "div" && "none"} class={@class} {@rest}>
      <div
        tabindex="0"
        role="treeitem"
        class={@classes}
        data-tree-leaf={@item_id}
      >
        <div class={["flex size-5 items-center justify-center", @layout == :advanced && "mr-1"]}>
        </div>
        <span :for={icon <- @icon} class="mr-3 flex">{render_slot(icon)}</span>
        <span>{@label}</span>
      </div>
    </.dynamic_tag>
    """
  end

  defp render_item(assigns) do
    assigns =
      assign(assigns, :classes, ["tree-header list-none", @header, @layouts[assigns.layout]])

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
        <summary role="treeitem" class={@classes}>
          <span class={[
            "btn size-5 rounded-lg p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25",
            @layout == :advanced && "mr-1"
          ]}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="tree-chevron size-4.5 transition-transform"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"
              />
            </svg>
          </span>
          <span :for={icon <- @icon} class="mr-3 flex">{render_slot(icon)}</span>
          <span>{@label}</span>
        </summary>
        <ul role="group" class="pl-4">
          {render_slot(@inner_block)}
        </ul>
      </details>
    </.dynamic_tag>
    """
  end
end
