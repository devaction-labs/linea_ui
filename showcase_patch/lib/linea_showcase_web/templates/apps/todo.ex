defmodule LineaShowcaseWeb.Templates.Apps.Todo do
  @moduledoc """
  LineOne's Todo app: todos added, completed, starred, edited in a drawer (title, labels, due
  date, person, description), deleted and restored, filtered by list, label and search, sorted,
  and reordered by dragging (the `LineaUI.Sortable` hook).
  """

  use LineaShowcaseWeb.Template,
    title: "Todo",
    section: :apps,
    lineone: "apps-todo",
    order: 6

  import LineaShowcaseWeb.Templates.Apps.Parts

  alias LineaShowcaseWeb.Templates.Apps.Todo.Data

  @lists [
    {"day", "My Day", "huge-sun-01"},
    {"important", "Important", "huge-star"},
    {"task", "Task", "huge-home-01"},
    {"assigned", "Assigned", "huge-user"}
  ]

  @titles %{
    "day" => "My Day",
    "important" => "Important",
    "task" => "Task",
    "assigned" => "Assigned",
    "deleted" => "Deleted"
  }

  def mount(socket) do
    socket
    |> assign(
      todos: Data.todos(),
      next_id: 9,
      list: "day",
      label: nil,
      query: "",
      sort: "manual",
      hide_done: false,
      editing: nil,
      search: to_form(%{"q" => ""}, as: :search)
    )
    |> assign_form(nil)
  end

  def handle_event("list", %{"value" => list}, socket),
    do: {:noreply, assign(socket, list: list, label: nil)}

  def handle_event("label", %{"value" => label}, socket),
    do: {:noreply, update(socket, :label, &((&1 != label && label) || nil))}

  def handle_event("search", %{"search" => %{"q" => query} = params}, socket),
    do: {:noreply, assign(socket, query: query, search: to_form(params, as: :search))}

  def handle_event("sort", _params, socket),
    do: {:noreply, update(socket, :sort, &next_sort/1)}

  def handle_event("hide-done", _params, socket),
    do: {:noreply, update(socket, :hide_done, &(!&1))}

  def handle_event("toggle", %{"id" => id}, socket),
    do: {:noreply, change(socket, id, &%{&1 | done: !&1.done})}

  def handle_event("star", %{"id" => id}, socket),
    do: {:noreply, change(socket, id, &%{&1 | starred: !&1.starred})}

  def handle_event("new", _params, socket) do
    socket
    |> assign(editing: :new)
    |> assign_form(nil)
    |> LineaUI.open("edit-todo-drawer")
    |> then(&{:noreply, &1})
  end

  def handle_event("edit", %{"id" => id}, socket) do
    socket
    |> assign(editing: id)
    |> assign_form(find(socket, id))
    |> LineaUI.open("edit-todo-drawer")
    |> then(&{:noreply, &1})
  end

  def handle_event("drawer-closed", _params, socket), do: {:noreply, assign(socket, editing: nil)}

  def handle_event("save", %{"todo" => params}, socket) do
    case String.trim(params["title"] || "") do
      "" ->
        {:noreply,
         assign(socket,
           form: to_form(params, as: :todo, errors: [title: {"Give the todo a title", []}])
         )}

      title ->
        socket
        |> save(socket.assigns.editing, Map.put(params, "title", title))
        |> assign(editing: nil)
        |> LineaUI.close("edit-todo-drawer")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("delete", _params, %{assigns: %{editing: :new}} = socket),
    do: {:noreply, LineaUI.close(socket, "edit-todo-drawer")}

  def handle_event("delete", _params, socket) do
    socket
    |> change(socket.assigns.editing, &%{&1 | deleted: !&1.deleted})
    |> assign(editing: nil)
    |> LineaUI.close("edit-todo-drawer")
    |> send_toast("Todo moved to Deleted", color: "error")
    |> then(&{:noreply, &1})
  end

  def handle_event("restore", %{"id" => id}, socket),
    do: {:noreply, change(socket, id, &%{&1 | deleted: false})}

  def handle_event("reorder", %{"id" => id, "index" => index}, socket) do
    visible = socket.assigns |> visible() |> Enum.map(& &1.id)
    moved = visible |> List.delete(id) |> List.insert_at(index, id)
    {:noreply, update(socket, :todos, &reorder(&1, visible, moved))}
  end

  def handle_event("menu", %{"action" => action}, socket),
    do: {:noreply, send_toast(socket, action, color: "info")}

  defp next_sort("manual"), do: "title"
  defp next_sort("title"), do: "time"
  defp next_sort("time"), do: "manual"

  defp find(socket, id), do: Enum.find(socket.assigns.todos, &(&1.id == id))

  defp change(socket, id, fun) do
    update(socket, :todos, fn todos -> Enum.map(todos, &apply_change(&1, id, fun)) end)
  end

  defp apply_change(%{id: id} = todo, id, fun), do: fun.(todo)
  defp apply_change(todo, _id, _fun), do: todo

  defp reorder(todos, visible, moved) do
    {result, _rest} =
      Enum.map_reduce(todos, moved, fn todo, queue ->
        case todo.id in visible do
          true -> {find_in(todos, hd(queue)), tl(queue)}
          false -> {todo, queue}
        end
      end)

    result
  end

  defp find_in(todos, id), do: Enum.find(todos, &(&1.id == id))

  defp assign_form(socket, nil) do
    assign(socket,
      form:
        to_form(
          %{
            "title" => "",
            "labels" => [],
            "date" => Date.to_iso8601(Data.today()),
            "time" => "09:00",
            "person" => "",
            "description" => ""
          },
          as: :todo
        )
    )
  end

  defp assign_form(socket, todo) do
    assign(socket,
      form:
        to_form(
          %{
            "title" => todo.title,
            "labels" => todo.labels,
            "date" => Date.to_iso8601(todo.date),
            "time" => todo.time,
            "person" => todo.person || "",
            "description" => todo.description
          },
          as: :todo
        )
    )
  end

  defp save(socket, :new, params) do
    todo = Map.merge(base(socket.assigns.next_id), fields(params))

    socket
    |> update(:todos, &(&1 ++ [todo]))
    |> update(:next_id, &(&1 + 1))
    |> assign(list: "day", label: nil)
    |> send_toast("Todo added", color: "success")
  end

  defp save(socket, id, params), do: change(socket, id, &Map.merge(&1, fields(params)))

  defp base(id) do
    %{
      id: Integer.to_string(id),
      done: false,
      starred: false,
      deleted: false,
      daily: false
    }
  end

  defp fields(params) do
    %{
      title: params["title"],
      labels: params |> Map.get("labels", []) |> List.wrap() |> Enum.reject(&(&1 == "")),
      date: parse_date(params["date"]),
      time: params["time"] || "09:00",
      person: blank(params["person"]),
      description: params["description"] || ""
    }
  end

  defp parse_date(text) do
    case Date.from_iso8601(text || "") do
      {:ok, date} -> date
      {:error, _} -> Data.today()
    end
  end

  defp blank(""), do: nil
  defp blank(value), do: value

  defp visible(assigns) do
    query = assigns.query |> String.trim() |> String.downcase()

    assigns.todos
    |> Enum.filter(&in_list?(&1, assigns.list))
    |> Enum.filter(&(is_nil(assigns.label) or assigns.label in &1.labels))
    |> Enum.filter(&(query == "" or String.contains?(String.downcase(&1.title), query)))
    |> Enum.reject(&(assigns.hide_done and &1.done))
    |> sort(assigns.sort)
  end

  defp in_list?(todo, "deleted"), do: todo.deleted
  defp in_list?(%{deleted: true}, _list), do: false
  defp in_list?(todo, "important"), do: todo.starred
  defp in_list?(todo, "assigned"), do: todo.person != nil
  defp in_list?(_todo, _list), do: true

  defp sort(todos, "manual"), do: todos
  defp sort(todos, "title"), do: Enum.sort_by(todos, &String.downcase(&1.title))
  defp sort(todos, "time"), do: Enum.sort_by(todos, &{&1.date, &1.time}, :asc)

  defp day(%{daily: true}), do: "Every Day"

  defp day(%{date: date}) do
    case Date.diff(date, Data.today()) do
      0 -> "Today"
      1 -> "Tomorrow"
      -1 -> "Yesterday"
      _ -> Calendar.strftime(date, "%b %-d")
    end
  end

  defp label_color(label), do: Data.labels() |> List.keyfind(label, 0) |> elem(1)

  defp icon_color("success"), do: "text-success"
  defp icon_color("warning"), do: "text-warning"
  defp icon_color("error"), do: "text-error"
  defp icon_color("info"), do: "text-info"

  defp person(id), do: Enum.find(Data.people(), &(&1.value == id))

  defp count(todos, list), do: Enum.count(todos, &in_list?(&1, list))

  def render(assigns) do
    assigns =
      assign(assigns,
        visible: visible(assigns),
        lists: @lists,
        title: Map.fetch!(@titles, assigns.list)
      )

    ~H"""
    <.app_layout>
      <:panel>
        <.todo_panel list={@list} label={@label} lists={@lists} todos={@todos} />
      </:panel>
      <div class="todo-app">
        <div class="flex items-center justify-between py-5">
          <div>
            <div class="flex space-x-2">
              <p class="text-xl font-medium text-slate-800 dark:text-navy-50">
                {@title}<span :if={@label} class="text-slate-400 dark:text-navy-300"> · {@label}</span>
              </p>
              <.more_menu
                id="top-header-menu"
                placement="bottom-start"
                on_select="menu"
                button_class="size-7"
              />
            </div>
            <p class="mt-1 text-xs">{Calendar.strftime(Data.today(), "%A, %b. %-d")}</p>
          </div>
          <div class="flex items-center space-x-2">
            <.form for={@search} id="todo-search" phx-change="search" class="hidden sm:flex">
              <.input
                field={@search[:q]}
                placeholder="Search todos..."
                phx-debounce="150"
                autocomplete="off"
                class="h-9 hover:z-10 focus:z-10"
              >
                <:prefix>
                  <.icon
                    name="huge-search-01"
                    class="size-4.5 transition-colors duration-200"
                  />
                </:prefix>
              </.input>
            </.form>
            <div class="flex">
              <.tooltip
                id="todo-filter-tip"
                text={(@hide_done && "Show completed") || "Hide completed"}
              >
                <.button
                  icon
                  variant="flat"
                  class={["size-9 text-inherit", @hide_done && "text-primary dark:text-accent-light"]}
                  phx-click="hide-done"
                  aria-label="Filter"
                >
                  <.icon name="huge-sliders-horizontal" class="size-5" />
                </.button>
              </.tooltip>
              <.tooltip id="todo-sort-tip" text={"Sort: #{@sort}"}>
                <.button
                  icon
                  variant="flat"
                  class={[
                    "size-9 text-inherit",
                    @sort != "manual" && "text-primary dark:text-accent-light"
                  ]}
                  phx-click="sort"
                  aria-label="Sort"
                >
                  <.icon name="huge-arrow-up-down" class="size-5" />
                </.button>
              </.tooltip>
            </div>
          </div>
        </div>
        <.card padded={false} class="px-4 pb-4 pt-2">
          <div
            id="todo-list"
            phx-hook="LineaUI.Sortable"
            data-event="reorder"
            data-list="todos"
          >
            <.todo_row :for={todo <- @visible} todo={todo} day={day(todo)} />
          </div>
          <p :if={@visible == []} class="py-8 text-center">Nothing here. Enjoy your day!</p>
        </.card>
      </div>
    </.app_layout>
    <.edit_drawer
      form={@form}
      editing={@editing}
      todo={@editing not in [nil, :new] && find_todo(@todos, @editing)}
    />
    """
  end

  defp find_todo(todos, id), do: Enum.find(todos, &(&1.id == id))

  attr :todo, :map, required: true
  attr :day, :string, required: true

  defp todo_row(assigns) do
    ~H"""
    <div
      id={"todo-#{@todo.id}"}
      data-id={@todo.id}
      class="cursor-pointer border-b border-slate-150 py-3 dark:border-navy-500"
      phx-click="edit"
      phx-value-id={@todo.id}
    >
      <div class="flex items-center space-x-2 sm:space-x-3">
        <.checkbox
          id={"todo-check-#{@todo.id}"}
          name={"done-#{@todo.id}"}
          checked={@todo.done}
          hidden_input={false}
          color="primary"
          variant="outline"
          shape="circle"
          class="size-5"
          phx-click="toggle"
          phx-value-id={@todo.id}
          aria-label="Completed"
        />
        <h2 class={[
          "line-clamp-1 text-slate-600 dark:text-navy-100",
          @todo.deleted && "line-through opacity-60"
        ]}>
          {@todo.title}
        </h2>
      </div>
      <div class="mt-1 flex items-end justify-between">
        <div class="flex flex-wrap items-center font-inter text-xs">
          <p>{@day}</p>
          <.divider orientation="vertical" class="m-1.5 self-stretch" />
          <span class="flex items-center space-x-1">
            <.icon name="huge-notification-01" class="size-3.5" />
            <span>{@todo.time}</span>
          </span>
          <%= for label <- @todo.labels do %>
            <.divider orientation="vertical" class="m-1.5 self-stretch" />
            <.badge variant="flat" color={label_color(label)} dot class="space-x-2.5 px-1">
              {label}
            </.badge>
          <% end %>
        </div>
        <div class="flex items-center space-x-1">
          <.button
            :if={@todo.deleted}
            size="xs"
            color="primary"
            variant="soft"
            shape="pill"
            phx-click="restore"
            phx-value-id={@todo.id}
          >
            Restore
          </.button>
          <.button
            icon
            variant="flat"
            shape="pill"
            class="size-7 text-inherit"
            phx-click="star"
            phx-value-id={@todo.id}
            aria-label="Important"
            aria-pressed={to_string(@todo.starred)}
          >
            <.icon
              name="huge-star"
              class={["size-5", @todo.starred && "text-primary dark:text-accent"]}
            />
          </.button>
          <.avatar :if={@todo.person} src={person(@todo.person).src} size="xs" class="size-6" />
        </div>
      </div>
    </div>
    """
  end

  attr :list, :string, required: true
  attr :label, :string, default: nil
  attr :lists, :list, required: true
  attr :todos, :list, required: true

  defp todo_panel(assigns) do
    ~H"""
    <.panel_header title="Todo" color="info">
      <.icon name="huge-task-done-02" class="size-5" />
    </.panel_header>
    <div class="flex grow flex-col">
      <div class="is-scrollbar-hidden grow overflow-y-auto">
        <.panel_button phx-click="new">
          <.icon name="huge-plus-sign" class="size-4.5" />
          <span> New Task </span>
        </.panel_button>
        <ul class="mt-5 space-y-1.5 px-2">
          <li :for={{value, label, icon} <- @lists}>
            <.panel_item
              value={value}
              on_select="list"
              active={@list == value}
            >
              <:icon>
                <.icon name={icon} class="size-4.5" />
              </:icon>
              {label}
            </.panel_item>
          </li>
          <li>
            <.panel_item
              value="deleted"
              on_select="list"
              active={@list == "deleted"}
              color={@list != "deleted" && "error"}
              count={count(@todos, "deleted") > 0 && count(@todos, "deleted")}
              class={@list != "deleted" && "hover:bg-error/20 focus:bg-error/20"}
            >
              <:icon><.icon name="huge-delete-02" class="size-4.5" /></:icon>
              Deleted
            </.panel_item>
          </li>
        </ul>
        <.divider class="mx-4 my-4" />
        <div class="flex items-center justify-between px-4">
          <span class="text-xs font-medium uppercase">Labels</span>
          <div class="-mr-1.5 flex">
            <.button
              icon
              variant="flat"
              shape="pill"
              class="size-6 text-inherit"
              phx-click={JS.focus(to: "#todo-search input")}
              aria-label="Search"
            >
              <.icon name="huge-search-01" class="size-3.5" />
            </.button>
            <.more_menu
              id="sidebar-label-menu"
              vertical
              on_select="menu"
              button_class="size-6 [&_span]:size-3.5"
            />
          </div>
        </div>
        <ul class="mt-1 space-y-1.5 px-2">
          <li :for={{label, color} <- Data.labels()}>
            <.panel_item value={label} on_select="label" active={@label == label}>
              <:icon>
                <.icon name="huge-left-to-right-list-bullet" class={["size-4.5", icon_color(color)]} />
              </:icon>
              {label}
            </.panel_item>
          </li>
        </ul>
      </div>
      <div class="flex shrink-0 justify-between px-1.5 py-1">
        <.tooltip :for={{slug, label, icon} <- app_links()} id={"todo-app-#{slug}"} text={label}>
          <.button
            icon
            variant="flat"
            shape="pill"
            class="size-9 text-inherit"
            navigate={"/apps/#{slug}"}
            aria-label={label}
          >
            <.icon name={icon} class="size-5" />
          </.button>
        </.tooltip>
      </div>
    </div>
    """
  end

  defp app_links do
    [
      {"mail", "Mail App", "huge-mail-01"},
      {"kanban", "Kanban App", "huge-kanban"},
      {"chat", "Chat App", "huge-bubble-chat"},
      {"pos", "POS App", "huge-credit-card-pos"},
      {"filemanager", "File Manager App", "huge-cloud"}
    ]
  end

  attr :form, :any, required: true
  attr :editing, :any, default: nil
  attr :todo, :any, default: nil

  defp edit_drawer(assigns) do
    ~H"""
    <.drawer id="edit-todo-drawer" side="right" on_close="drawer-closed" class="w-80">
      <.form for={@form} id="edit-todo-form" phx-submit="save" class="flex h-full w-full flex-col">
        <div class="flex h-14 shrink-0 items-center justify-between bg-slate-150 p-4 dark:bg-navy-800">
          <h3 class="text-base font-medium text-slate-700 dark:text-navy-100">
            {(@editing == :new && "New Todo") || "Edit Todo"}
          </h3>
          <div class="-mr-1.5 flex items-center space-x-2.5">
            <.checkbox
              :if={@todo}
              id="drawer-done"
              name="drawer-done"
              checked={@todo.done}
              hidden_input={false}
              color="primary"
              shape="circle"
              phx-click="toggle"
              phx-value-id={@todo.id}
              aria-label="Mark as Completed"
            />
            <div class="flex">
              <.button
                :if={@todo}
                icon
                variant="flat"
                shape="pill"
                class="size-7 text-inherit"
                phx-click="star"
                phx-value-id={@todo.id}
                aria-label="Important"
              >
                <.icon
                  name="huge-star"
                  class={["size-4.5", @todo.starred && "text-primary dark:text-accent"]}
                />
              </.button>
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-7 text-inherit"
                phx-click={LineaUI.close("edit-todo-drawer")}
                aria-label="Close"
              >
                <.icon name="huge-cancel-01" class="size-4.5" />
              </.button>
            </div>
          </div>
        </div>
        <div class="is-scrollbar-hidden flex grow flex-col space-y-4 overflow-y-auto p-4">
          <.input field={@form[:title]} label="Todo Title" placeholder="Enter todo title" class="h-9" />
          <.select
            field={@form[:labels]}
            label="Tags:"
            options={Enum.map(Data.labels(), &elem(&1, 0))}
            multiple
            removable
            placeholder="Select the tags"
          />
          <.date_picker field={@form[:date]} label="Due date:" placeholder="Choose date..." />
          <.select
            field={@form[:person]}
            label="Assigned to:"
            options={Data.people()}
            placeholder="Select the user"
          >
            <:option :let={person}>
              <div class="flex space-x-3">
                <.avatar src={person.data.src} size="xs" />
                <div class="flex flex-col">
                  <span>{person.label}</span>
                  <span class="text-xs opacity-80">{person.data.job}</span>
                </div>
              </div>
            </:option>
            <:item :let={person}>
              <span class="inline-flex items-center">
                <.avatar src={person.data.src} size="xs" class="size-6" />
                <span class="mx-2">{person.label}</span>
              </span>
            </:item>
          </.select>
          <input type="hidden" name="todo[time]" value={@form[:time].value} />
          <.text_editor
            field={@form[:description]}
            label="Description"
            placeholder="Enter your content..."
            toolbar={[~w(bold italic underline), ~w(list-ordered list-bullet header-1 background)]}
            content_class="h-36"
          />
        </div>
        <div class="flex items-center justify-between border-t border-slate-150 px-4 py-3 dark:border-navy-600">
          <div class="flex space-x-1">
            <.button
              icon
              variant="flat"
              color="error"
              shape="pill"
              class="size-8"
              phx-click="delete"
              aria-label="Delete"
            >
              <.icon name="huge-delete-02" class="size-5" />
            </.button>
          </div>
          <.button type="submit" color="primary" class="min-w-[7rem]">Save</.button>
        </div>
      </.form>
    </.drawer>
    """
  end
end
