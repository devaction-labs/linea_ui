defmodule LineaShowcaseWeb.Templates.Apps.Kanban do
  @moduledoc """
  LineOne's Kanban board, full height in the shell: cards dragged between columns and columns
  reordered by their header (the `LineaUI.Sortable` hook, the server keeps the order), cards and
  boards added in modals, checklists ticked, cards searched, three boards switched from the
  app's panel and a settings drawer whose activity log records each move.
  """

  use LineaShowcaseWeb.Template,
    title: "Kanban Board",
    section: :apps,
    lineone: "apps-kanban",
    order: 3

  import LineaShowcaseWeb.Templates.Apps.Parts

  alias LineaShowcaseWeb.Templates.Apps.Kanban.Data

  @colors ~w(info warning secondary success error primary)

  def mount(socket) do
    assign(socket,
      boards: Data.boards(),
      board: "banking",
      query: "",
      starred: MapSet.new(["banking"]),
      activities: Data.activities(),
      next_id: 1,
      adding_to: nil,
      card_form: to_form(%{"title" => "", "tag" => ""}, as: :card),
      board_form: to_form(%{"title" => "", "color" => "info"}, as: :column),
      search: to_form(%{"q" => ""}, as: :search)
    )
  end

  def handle_event("board", %{"value" => board}, socket),
    do:
      {:noreply,
       assign(socket, board: board, query: "", search: to_form(%{"q" => ""}, as: :search))}

  def handle_event("search", %{"search" => %{"q" => query} = params}, socket),
    do: {:noreply, assign(socket, query: query, search: to_form(params, as: :search))}

  def handle_event("star", _params, socket) do
    board = socket.assigns.board

    {:noreply,
     update(socket, :starred, fn starred ->
       (MapSet.member?(starred, board) && MapSet.delete(starred, board)) ||
         MapSet.put(starred, board)
     end)}
  end

  def handle_event(
        "move-card",
        %{"id" => id, "from" => from, "to" => to, "index" => index},
        socket
      ) do
    card =
      socket
      |> columns()
      |> Enum.find(&(&1.id == from))
      |> Map.fetch!(:cards)
      |> Enum.find(&(&1.id == id))

    target = socket |> columns() |> Enum.find(&(&1.id == to))

    socket
    |> update_columns(fn columns -> Enum.map(columns, &move(&1, card, to, index)) end)
    |> log(from != to && "moved “#{card.title}” to #{target.title}")
    |> then(&{:noreply, &1})
  end

  def handle_event("move-board", %{"id" => id, "index" => index}, socket) do
    socket
    |> update_columns(fn columns ->
      column = Enum.find(columns, &(&1.id == id))
      columns |> List.delete(column) |> List.insert_at(index, column)
    end)
    |> then(&{:noreply, &1})
  end

  def handle_event("check", %{"card" => card_id, "item" => item}, socket) do
    index = String.to_integer(item)

    socket
    |> update_cards(card_id, fn card ->
      %{
        card
        | checklist: List.update_at(card.checklist, index, fn {label, done} -> {label, !done} end)
      }
    end)
    |> then(&{:noreply, &1})
  end

  def handle_event("new-card", %{"column" => column}, socket) do
    socket
    |> assign(adding_to: column, card_form: to_form(%{"title" => "", "tag" => ""}, as: :card))
    |> LineaUI.open("kanban-card-modal")
    |> then(&{:noreply, &1})
  end

  def handle_event("add-card", %{"card" => %{"title" => title} = params}, socket) do
    case String.trim(title) do
      "" ->
        {:noreply,
         assign(socket,
           card_form: to_form(params, as: :card, errors: [title: {"Give the task a title", []}])
         )}

      title ->
        {:noreply, add_card(socket, title, params["tag"])}
    end
  end

  def handle_event("new-board", _params, socket) do
    socket
    |> assign(board_form: to_form(%{"title" => "", "color" => "info"}, as: :column))
    |> LineaUI.open("kanban-board-modal")
    |> then(&{:noreply, &1})
  end

  def handle_event("add-board", %{"column" => %{"title" => title} = params}, socket) do
    case String.trim(title) do
      "" ->
        {:noreply,
         assign(socket,
           board_form: to_form(params, as: :column, errors: [title: {"Name the board", []}])
         )}

      title ->
        column = %{
          id: "col-#{socket.assigns.next_id}",
          title: title,
          color: color(params["color"]),
          icon: :review,
          cards: []
        }

        socket
        |> update_columns(&(&1 ++ [column]))
        |> update(:next_id, &(&1 + 1))
        |> log("added the board “#{title}”")
        |> LineaUI.close("kanban-board-modal")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("menu", %{"action" => action}, socket),
    do: {:noreply, send_toast(socket, action, color: "info")}

  defp color(color) when color in @colors, do: color
  defp color(_color), do: "info"

  defp add_card(socket, title, tag) do
    id = "new-#{socket.assigns.next_id}"
    column = socket.assigns.adding_to

    card = %{
      id: id,
      title: title,
      tint: nil,
      flag: nil,
      subtitle: nil,
      image: nil,
      cover: nil,
      date: Calendar.strftime(Date.utc_today(), "%b %d"),
      tag: tag_for(tag),
      progress: nil,
      checklist: [],
      people: [],
      owner: %{avatar: "/images/avatar/avatar-12.jpg", name: "You"},
      photos: [],
      tags: nil,
      comments: nil
    }

    socket
    |> update_columns(fn columns -> Enum.map(columns, &append(&1, column, card)) end)
    |> update(:next_id, &(&1 + 1))
    |> log("added “#{title}”")
    |> LineaUI.close("kanban-card-modal")
  end

  defp tag_for(""), do: nil
  defp tag_for(nil), do: nil
  defp tag_for(tag), do: {tag, "primary"}

  defp append(%{id: id} = column, id, card), do: %{column | cards: column.cards ++ [card]}
  defp append(column, _id, _card), do: column

  defp move(column, card, to, index) do
    cards = Enum.reject(column.cards, &(&1.id == card.id))
    %{column | cards: (column.id == to && List.insert_at(cards, index, card)) || cards}
  end

  defp columns(socket),
    do: Enum.find(socket.assigns.boards, &(&1.id == socket.assigns.board)).columns

  defp update_columns(socket, fun) do
    board = socket.assigns.board

    update(socket, :boards, fn boards ->
      Enum.map(boards, &((&1.id == board && %{&1 | columns: fun.(&1.columns)}) || &1))
    end)
  end

  defp update_cards(socket, card_id, fun) do
    update_columns(socket, fn columns ->
      Enum.map(columns, fn column ->
        %{column | cards: Enum.map(column.cards, &((&1.id == card_id && fun.(&1)) || &1))}
      end)
    end)
  end

  defp log(socket, false), do: socket

  defp log(socket, what) do
    entry = %{who: "You", what: what, ago: "Just now", avatar: "/images/avatar/avatar-12.jpg"}
    update(socket, :activities, &Enum.take([entry | &1], 6))
  end

  defp visible(cards, ""), do: cards

  defp visible(cards, query) do
    query = String.downcase(String.trim(query))
    Enum.filter(cards, &String.contains?(String.downcase(&1.title), query))
  end

  def render(assigns) do
    assigns = assign(assigns, :current, Enum.find(assigns.boards, &(&1.id == assigns.board)))

    ~H"""
    <.app_layout full>
      <:panel><.kanban_panel boards={@boards} board={@board} /></:panel>
      <div class="kanban-app flex h-full flex-col">
        <div class="flex items-center justify-between space-x-2 px-[var(--margin-x)] py-5">
          <div class="flex items-center space-x-1">
            <h3 class="line-clamp-1 text-lg font-medium text-slate-700 dark:text-navy-50">
              {@current.name}
            </h3>
            <.button
              :if={@current.locked}
              icon
              variant="flat"
              color="error"
              shape="pill"
              class="hidden size-8 sm:inline-flex"
              aria-label="Private board"
            >
              <.icon name="huge-square-lock-02" class="size-4.5" />
            </.button>
          </div>
          <.form
            for={@search}
            id="kanban-search"
            phx-change="search"
            class="hidden w-full max-w-[16rem] sm:flex"
          >
            <.input
              field={@search[:q]}
              size="sm"
              placeholder="Search on boards"
              phx-debounce="150"
              autocomplete="off"
              class="h-8 pl-9 hover:z-10 focus:z-10"
            >
              <:prefix>
                <.icon name="huge-search-01" class="size-4 transition-colors duration-200" />
              </:prefix>
            </.input>
          </.form>
          <div class="flex space-x-1">
            <.avatar_group>
              <.avatar
                :for={member <- Data.members()}
                src={member}
                size="xs"
                class="size-6 sm:size-8 [&>img]:border-2 [&>img]:border-slate-50 dark:[&>img]:border-navy-900"
              />
              <.avatar
                initials="+5"
                color="info"
                size="xs"
                class="size-6 sm:size-8 [&>div]:border-2 [&>div]:border-slate-50 [&>div]:text-xs dark:[&>div]:border-navy-900"
              />
            </.avatar_group>
            <.button
              icon
              variant="flat"
              color="info"
              shape="pill"
              class="size-6 sm:size-8"
              aria-label="Invite"
              phx-click="menu"
              phx-value-action="Invite sent"
            >
              <.icon name="huge-user-add-01" class="size-4 sm:size-5" />
            </.button>
            <.divider orientation="vertical" class="my-1" />
            <div class="flex">
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-6 text-inherit sm:size-8"
                aria-label="Filter"
                phx-click={JS.focus(to: "#kanban-search input")}
              >
                <.icon name="huge-filter" class="size-4 sm:size-5" />
              </.button>
              <.button
                icon
                variant="flat"
                shape="pill"
                class="hidden size-6 text-inherit sm:inline-flex sm:size-8"
                phx-click="star"
                aria-label="Star board"
              >
                <.icon
                  name="huge-star"
                  class={[
                    "size-5",
                    MapSet.member?(@starred, @board) && "text-primary dark:text-accent"
                  ]}
                />
              </.button>
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-6 text-inherit sm:size-8"
                phx-click={LineaUI.open("kanban-setting-drawer")}
                aria-label="Settings"
              >
                <.icon name="huge-settings-02" class="size-4 sm:size-5" />
              </.button>
            </div>
          </div>
        </div>
        <div class="flex min-h-0 grow flex-col">
          <div class="kanban-scrollbar flex w-full grow items-start space-x-4 overflow-x-auto overflow-y-hidden px-[var(--margin-x)]">
            <div
              id={"tasks-group-#{@board}"}
              phx-hook="LineaUI.Sortable"
              data-event="move-board"
              data-list="columns"
              data-handle=".board-draggable-handler"
              data-axis="x"
              class="flex max-h-full items-start space-x-4"
            >
              <.column
                :for={column <- @current.columns}
                board={@board}
                column={column}
                cards={visible(column.cards, @query)}
              />
            </div>
            <div class="w-72 shrink-0">
              <.button class="w-full" phx-click="new-board">New Board</.button>
            </div>
          </div>
        </div>
      </div>
    </.app_layout>
    <.settings_drawer board={@current} activities={@activities} />
    <.modal id="kanban-card-modal" size="sm" animation="scale">
      <:header>New Task</:header>
      <.form for={@card_form} id="kanban-card-form" phx-submit="add-card" class="space-y-4">
        <.input
          field={@card_form[:title]}
          label="Title"
          placeholder="What needs doing?"
          autocomplete="off"
        />
        <.select
          field={@card_form[:tag]}
          label="Tag"
          options={~w(Update Create Design Blog Support Backup)}
          placeholder="No tag"
          clearable
        />
        <div class="flex justify-end space-x-2">
          <.button phx-click={LineaUI.close("kanban-card-modal")}>Cancel</.button>
          <.button type="submit" color="primary">Add Task</.button>
        </div>
      </.form>
    </.modal>
    <.modal id="kanban-board-modal" size="sm" animation="scale">
      <:header>New Board</:header>
      <.form for={@board_form} id="kanban-board-form" phx-submit="add-board" class="space-y-4">
        <.input
          field={@board_form[:title]}
          label="Board name"
          placeholder="Blocked"
          autocomplete="off"
        />
        <.radio_group field={@board_form[:color]} label="Color" variant="outline" class="mt-2">
          <:radio :for={color <- ~w(info warning secondary success error)} value={color} color={color}>
            {String.capitalize(color)}
          </:radio>
        </.radio_group>
        <div class="flex justify-end space-x-2">
          <.button phx-click={LineaUI.close("kanban-board-modal")}>Cancel</.button>
          <.button type="submit" color="primary">Add Board</.button>
        </div>
      </.form>
    </.modal>
    """
  end

  attr :board, :string, required: true
  attr :column, :map, required: true
  attr :cards, :list, required: true

  defp column(assigns) do
    ~H"""
    <div data-id={@column.id} class="relative flex max-h-[calc(100vh-11rem)] w-72 shrink-0 flex-col">
      <div class="board-draggable-handler flex cursor-move items-center justify-between px-0.5 pb-3">
        <div class="flex items-center space-x-2">
          <.avatar size="xs" shape="square" color={@column.color} variant="soft">
            <.column_icon icon={@column.icon} />
          </.avatar>
          <h3 class="text-base text-slate-700 dark:text-navy-100">{@column.title}</h3>
        </div>
        <.more_menu id={"tasks-#{@board}-#{@column.id}-menu"} on_select="menu" />
      </div>
      <div
        id={"tasks-#{@board}-#{@column.id}-list"}
        phx-hook="LineaUI.Sortable"
        data-group="board-cards"
        data-list={@column.id}
        data-event="move-card"
        class="is-scrollbar-hidden relative min-h-10 space-y-2.5 overflow-y-auto p-0.5"
      >
        <.task_card :for={card <- @cards} card={card} />
      </div>
      <div class="flex justify-center py-2">
        <.button
          variant="flat"
          class="space-x-2 text-slate-600 hover:bg-transparent hover:text-primary focus:bg-transparent focus:text-primary dark:text-navy-100 dark:hover:bg-transparent dark:hover:text-accent-light"
          phx-click="new-card"
          phx-value-column={@column.id}
        >
          <.icon name="huge-plus-sign" class="size-6" />
          <span>New Task</span>
        </.button>
      </div>
    </div>
    """
  end

  defp column_icon(%{icon: :spinner} = assigns),
    do: ~H|<.icon name="huge-loading-03" class="size-5" />|

  defp column_icon(%{icon: :clock} = assigns),
    do: ~H|<.icon name="huge-clock-01" class="size-5" />|

  defp column_icon(%{icon: :check} = assigns),
    do: ~H|<.icon name="huge-tick-02" class="size-5" />|

  defp column_icon(assigns) do
    ~H"""
    <.icon name="huge-file-search" class="size-5" />
    """
  end

  attr :card, :map, required: true

  defp task_card(assigns) do
    ~H"""
    <.card padded={false} data-id={@card.id} id={"card-#{@card.id}"} class="cursor-pointer shadow-xs">
      <div class={["flex space-x-3 rounded-lg px-2.5 pb-2 pt-1.5", tint(@card.tint)]}>
        <div :if={@card.image} class="w-10 shrink-0 py-1">
          <img class="w-full" src={"/images/illustrations/#{@card.image}"} alt="image" />
        </div>
        <div class="min-w-0 flex-1 space-y-2">
          <div>
            <div class="flex justify-between">
              <p class={["line-clamp-2 font-medium tracking-wide", title_color(@card.tint)]}>
                {@card.title}
              </p>
              <.icon
                :if={@card.flag}
                name="huge-flag-01"
                class={["-mr-1.5 size-3.5 shrink-0", flag_color(@card.flag)]}
              />
            </div>
            <p :if={@card.subtitle} class="mt-px text-xs text-slate-400 dark:text-navy-300">
              {@card.subtitle}
            </p>
          </div>
          <div :if={@card.date || @card.tag || @card.progress} class="flex flex-wrap gap-1">
            <.badge :if={@card.date} class="space-x-1 px-1.5 py-1">
              <.icon name="huge-calendar-03" class="size-3.5" /> <span>{@card.date}</span>
            </.badge>
            <.badge :if={@card.tag} color={elem(@card.tag, 1)} variant="soft" class="px-1.5 py-1">
              {elem(@card.tag, 0)}
            </.badge>
            <.badge
              :if={@card.progress}
              color={elem(@card.progress, 1)}
              variant="soft"
              class="space-x-1 px-1.5 py-1"
            >
              <.icon name="huge-tick-02" class="size-3.5" /> <span>{elem(@card.progress, 0)}</span>
            </.badge>
          </div>
          <div :if={@card.photos != []} class="grid grid-cols-3 gap-2">
            <img
              :for={photo <- @card.photos}
              class="h-16 w-full rounded-lg object-cover"
              src={"/images/object/#{photo}.jpg"}
              alt="image"
            />
          </div>
          <div :if={@card.cover} class="p-1">
            <img src={"/images/illustrations/#{@card.cover}"} alt="image" />
          </div>
          <div :if={@card.checklist != []} class="flex flex-col space-y-2 pt-1">
            <.checkbox
              :for={{{label, done}, index} <- Enum.with_index(@card.checklist)}
              id={"check-#{@card.id}-#{index}"}
              name={"check-#{@card.id}-#{index}"}
              checked={done}
              hidden_input={false}
              color="primary"
              shape="circle"
              label={label}
              phx-click="check"
              phx-value-card={@card.id}
              phx-value-item={index}
            />
          </div>
          <div class="flex items-end justify-between pt-1">
            <.avatar_group :if={@card.people != []} class="-space-x-1.5">
              <.person :for={person <- @card.people} person={person} />
            </.avatar_group>
            <div :if={@card.owner} class="flex items-center space-x-2">
              <.avatar src={@card.owner.avatar} size="xs" class="size-6" />
              <p>{@card.owner.name}</p>
            </div>
            <span :if={@card.people == [] and is_nil(@card.owner)}></span>
            <div class="flex items-center space-x-2 text-xs text-slate-400 dark:text-navy-300">
              <div :if={@card.tags} class="flex items-center space-x-0.5">
                <.icon name="huge-tag-01" class="size-3.5" />
                <span>{@card.tags}</span>
              </div>
              <div :if={@card.comments} class="flex items-center space-x-0.5">
                <.icon name="huge-comment-01" class="size-3.5" />
                <span>{@card.comments}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </.card>
    """
  end

  defp person(%{person: {:initials, initials}} = assigns) do
    assigns = assign(assigns, :initials, initials)

    ~H"""
    <.avatar
      initials={@initials}
      color="info"
      size="xs"
      ring
      class="size-5 [&>div]:text-tiny-plus [&>div]:ring-1"
    />
    """
  end

  defp person(assigns) do
    ~H"""
    <.avatar src={@person} size="xs" ring class="size-5 [&>img]:ring-1" />
    """
  end

  defp tint(nil), do: nil
  defp tint("success"), do: "bg-success/10"
  defp tint("warning"), do: "bg-warning/10"
  defp tint("info"), do: "bg-info/10"
  defp tint("error"), do: "bg-error/10"

  defp title_color(nil), do: "text-slate-600 dark:text-navy-100"
  defp title_color("success"), do: "text-success"
  defp title_color("warning"), do: "text-warning"
  defp title_color("info"), do: "text-info"
  defp title_color("error"), do: "text-error"

  defp flag_color("error"), do: "text-error"
  defp flag_color("info"), do: "text-info"
  defp flag_color("success"), do: "text-success"
  defp flag_color("warning"), do: "text-warning"
  defp flag_color("secondary"), do: "text-secondary dark:text-secondary-light"

  attr :boards, :list, required: true
  attr :board, :string, required: true

  defp kanban_panel(assigns) do
    ~H"""
    <.panel_header title="Kanban Board" color="success">
      <.icon name="huge-kanban" class="size-5" />
    </.panel_header>
    <div class="flex grow flex-col">
      <div class="is-scrollbar-hidden grow overflow-y-auto">
        <.panel_button phx-click="menu" phx-value-action="My Plan">
          <.icon name="huge-kanban" class="size-4.5" />
          <span>My Plan</span>
        </.panel_button>
        <div class="mt-4 flex items-center justify-between px-4">
          <span class="text-xs font-medium uppercase">Boards</span>
          <div class="-mr-1.5 flex">
            <.button
              icon
              variant="flat"
              shape="pill"
              class="size-6 text-inherit"
              phx-click="new-board"
              aria-label="New board column"
            >
              <.icon name="huge-plus-sign" class="size-3.5" />
            </.button>
            <.button
              icon
              variant="flat"
              shape="pill"
              class="size-6 text-inherit"
              phx-click={JS.focus(to: "#kanban-search input")}
              aria-label="Search"
            >
              <.icon name="huge-search-01" class="size-3.5" />
            </.button>
          </div>
        </div>
        <ul class="mt-1 space-y-1.5 px-2">
          <li :for={board <- @boards}>
            <.panel_item value={board.id} on_select="board" active={board.id == @board}>
              {board.name}
              <:suffix :if={board.locked}>
                <.icon name="huge-square-lock-02" class="size-4.5 text-error" />
              </:suffix>
            </.panel_item>
          </li>
        </ul>
        <.divider class="mx-4 my-4" />
        <.collapse id="sidebar-workspace" open class="group/ws">
          <:trigger class="flex cursor-pointer items-center justify-between px-4">
            <span class="text-xs font-medium uppercase">Workspace</span>
            <span class="-mr-1.5 flex">
              <span class="flex size-6 items-center justify-center"><.icon
                name="huge-plus-sign"
                class="size-3.5"
              /></span>
              <span class="flex size-6 items-center justify-center">
                <.icon
                  name="huge-arrow-down-01"
                  class="size-3.5 transition-transform group-open/ws:rotate-180"
                />
              </span>
            </span>
          </:trigger>
          <ul class="mt-1 space-y-1.5 px-2">
            <li :for={{label, count, icon} <- workspace()}>
              <.panel_item href="#" count={count}>
                <:icon>
                  <.icon name={icon} class="size-4.5" />
                </:icon>
                {label}
              </.panel_item>
            </li>
          </ul>
        </.collapse>
      </div>
      <div class="p-4">
        <.button
          color="primary"
          class="h-11 w-full justify-between bg-gradient-to-r from-purple-500 to-indigo-600 dark:bg-gradient-to-r"
          phx-click="menu"
          phx-value-action="Upgrade to Pro"
        >
          <span>Upgrade to Pro</span>
          <.icon name="huge-arrow-right-double" class="size-5" />
        </.button>
      </div>
    </div>
    """
  end

  defp workspace do
    [
      {"Inbox", 2, "huge-inbox"},
      {"Important", 1, "huge-star"},
      {"Members", nil, "huge-user-multiple"},
      {"Setting", nil, "huge-settings-02"},
      {"Timetable", nil, "huge-calendar-03"}
    ]
  end

  attr :board, :map, required: true
  attr :activities, :list, required: true

  defp settings_drawer(assigns) do
    ~H"""
    <.drawer id="kanban-setting-drawer" side="right" class="w-full sm:w-80">
      <div class="flex h-full w-full flex-col">
        <div class="flex h-14 shrink-0 items-center justify-between bg-slate-150 p-4 dark:bg-navy-800">
          <h3 class="text-base font-medium text-slate-700 dark:text-navy-100">{@board.name}</h3>
          <.button
            icon
            variant="flat"
            shape="pill"
            class="-mr-1.5 size-7 text-inherit"
            phx-click={LineaUI.close("kanban-setting-drawer")}
            aria-label="Close"
          >
            <.icon name="huge-cancel-01" class="size-4.5" />
          </.button>
        </div>
        <div class="is-scrollbar-hidden flex grow flex-col overflow-y-auto">
          <.collapse id="drawer-actions-collapse" open class="group/actions">
            <:trigger class="mt-3 flex cursor-pointer items-center justify-between px-4">
              <span class="text-xs-plus font-medium uppercase">Actions</span>
              <.icon
                name="huge-arrow-down-01"
                class="size-3.5 transition-transform group-open/actions:rotate-180"
              />
            </:trigger>
            <.menu_list class="mt-2 space-y-3 px-4" on_select="menu">
              <:item :for={{label, _} <- actions()} value={label}>
                <span class="inline-flex items-center space-x-2">{label}</span>
              </:item>
            </.menu_list>
          </.collapse>
          <.divider class="mx-4 my-4" />
          <.collapse id="drawer-activities-collapse" open class="group/activities">
            <:trigger class="flex cursor-pointer items-center justify-between px-4">
              <span class="text-xs-plus font-medium uppercase">Activities</span>
              <.icon
                name="huge-arrow-down-01"
                class="size-3.5 transition-transform group-open/activities:rotate-180"
              />
            </:trigger>
            <.timeline class="mt-4 px-4">
              <.timeline_item
                :for={activity <- @activities}
                title={activity.who}
                time={activity.ago}
                description={activity.what}
                color={(activity.who == "You" && "primary") || "neutral"}
              />
            </.timeline>
          </.collapse>
        </div>
      </div>
    </.drawer>
    """
  end

  defp actions do
    [
      {"Edit Board", nil},
      {"Archive", nil},
      {"Clone", nil},
      {"About Board", nil},
      {"Visibility", nil},
      {"Delete Board", nil}
    ]
  end
end
