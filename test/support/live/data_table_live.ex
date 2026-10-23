defmodule LineaUI.Test.DataTableLive do
  @moduledoc false

  use Phoenix.LiveView
  use LineaUI

  @rows Enum.map(1..12, &%{id: Integer.to_string(&1), name: "Name #{&1}"})

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(search: "", sort_by: nil, sort_dir: "asc", page: 1, selected: [], events: [])
     |> stream(:people, Enum.take(@rows, 3))}
  end

  def handle_event("search", %{"search" => search} = params, socket),
    do: {:noreply, socket |> log("search", params) |> assign(search: search, page: 1)}

  def handle_event("sort", %{"column" => column, "direction" => dir} = params, socket),
    do: {:noreply, socket |> log("sort", params) |> assign(sort_by: column, sort_dir: dir)}

  def handle_event("page", %{"page" => page} = params, socket),
    do: {:noreply, socket |> log("page", params) |> assign(page: String.to_integer(page))}

  def handle_event("select", %{"id" => id, "selected" => "true"} = params, socket),
    do: {:noreply, socket |> log("select", params) |> update(:selected, &[id | &1])}

  def handle_event("select", %{"id" => id, "selected" => "false"} = params, socket),
    do: {:noreply, socket |> log("select", params) |> update(:selected, &List.delete(&1, id))}

  def handle_event("select_all", %{"selected" => "true"} = params, socket),
    do: {:noreply, socket |> log("select_all", params) |> assign(selected: ids(socket))}

  def handle_event("select_all", params, socket),
    do: {:noreply, socket |> log("select_all", params) |> assign(selected: [])}

  def handle_event("add", _params, socket),
    do: {:noreply, stream_insert(socket, :people, %{id: "99", name: "Streamed"})}

  defp log(socket, event, params), do: update(socket, :events, &[{event, params} | &1])

  defp ids(socket), do: socket.assigns |> rows() |> Enum.map(& &1.id)

  defp rows(%{search: search, sort_by: sort_by, sort_dir: dir, page: page}) do
    @rows
    |> Enum.filter(&String.contains?(&1.name, search))
    |> sort(sort_by, dir)
    |> Enum.slice((page - 1) * 5, 5)
  end

  defp total(%{search: search}), do: Enum.count(@rows, &String.contains?(&1.name, search))

  defp sort(rows, nil, _dir), do: rows
  defp sort(rows, "name", "asc"), do: Enum.sort_by(rows, & &1.name, :asc)
  defp sort(rows, "name", "desc"), do: Enum.sort_by(rows, & &1.name, :desc)

  def render(assigns) do
    assigns = assign(assigns, rows: rows(assigns), total: total(assigns))

    ~H"""
    <.data_table
      id="people"
      variant="grid"
      rows={@rows}
      row_key={& &1.id}
      search={@search}
      on_search="search"
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      page={@page}
      page_size={5}
      total={@total}
      on_page="page"
      selected={@selected}
      on_select="select"
      on_select_all="select_all"
    >
      <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
    </.data_table>

    <.table id="streamed" rows={@streams.people}>
      <:col :let={{_id, row}} label="Name">{row.name}</:col>
    </.table>
    <button id="add" phx-click="add">Add</button>
    <pre id="events">{inspect(Enum.reverse(@events))}</pre>
    """
  end
end
