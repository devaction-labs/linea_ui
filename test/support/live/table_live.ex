defmodule LineaUI.Test.TableLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  @people for n <- 1..40, do: %{id: n, name: "Person #{n}"}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(selected: MapSet.new(), sort_by: "name", sort_dir: "asc", opened: nil)
     |> assign(page: 1, per_page: 15)
     |> stream(:people, Enum.take(@people, 3))}
  end

  def render(assigns) do
    ~H"""
    <.table id="people" variant="hoverable" rounded="top">
      <.table_head
        on_sort="sort"
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_select_all="select_all"
        all_selected={MapSet.size(@selected) == 3}
        some_selected={MapSet.size(@selected) > 0}
        select_all_id="people-all"
      >
        <:col sort_key="name">Name</:col>
      </.table_head>
      <.table_body id="people-body" phx-update="stream">
        <.table_row
          :for={{dom_id, person} <- @streams.people}
          id={dom_id}
          selected={MapSet.member?(@selected, person.id)}
          on_select="select"
          select_value={person.id}
          on_click="open"
          phx-value-id={person.id}
        >
          <:cell>{person.name}</:cell>
        </.table_row>
        <.table_empty id="people-empty">No people.</.table_empty>
      </.table_body>
    </.table>
    <p id="state">{@sort_by}:{@sort_dir} opened={@opened} page={@page} per_page={@per_page}</p>
    <.pagination
      id="pager"
      page={@page}
      page_size={@per_page}
      total_entries={40}
      page_sizes={[15, 30]}
      on_change="paginate"
      on_page_size="per_page"
    />
    """
  end

  def handle_event("sort", %{"column" => column, "direction" => dir}, socket),
    do: {:noreply, assign(socket, sort_by: column, sort_dir: dir)}

  def handle_event("open", %{"id" => id}, socket),
    do: {:noreply, assign(socket, opened: id)}

  def handle_event("select", %{"id" => id, "selected" => selected}, socket) do
    id = String.to_integer(id)
    person = Enum.find(@people, &(&1.id == id))

    selected =
      case selected do
        "true" -> MapSet.put(socket.assigns.selected, id)
        "false" -> MapSet.delete(socket.assigns.selected, id)
      end

    {:noreply, socket |> assign(selected: selected) |> stream_insert(:people, person)}
  end

  def handle_event("select_all", %{"selected" => selected}, socket) do
    rows = Enum.take(@people, 3)

    set =
      case selected do
        "true" -> MapSet.new(rows, & &1.id)
        "false" -> MapSet.new()
      end

    {:noreply, socket |> assign(selected: set) |> stream(:people, rows, reset: true)}
  end

  def handle_event("paginate", %{"page" => page}, socket),
    do: {:noreply, assign(socket, page: String.to_integer(page))}

  def handle_event("per_page", %{"page_size" => size}, socket),
    do: {:noreply, assign(socket, per_page: String.to_integer(size), page: 1)}
end
