defmodule LineaShowcaseWeb.Templates.Apps.Chat do
  @moduledoc """
  LineOne's Chat app, full height in the shell: contacts searched and switched from the app's
  panel, a conversation you write in (the contact answers a moment later, through
  `handle_info/2`), the chat info column that toggles, its images and files tabs, and the
  conversation menu (mute, clear).
  """

  use LineaShowcaseWeb.Template,
    title: "Chat App",
    section: :apps,
    lineone: "apps-chat",
    order: 1,
    layout: :shell

  import LineaShowcaseWeb.Templates.Apps.Parts

  alias LineaShowcaseWeb.Templates.Apps.Chat.Data

  def mount(socket) do
    assign(socket,
      contacts: Data.contacts(),
      current: "konnor",
      query: "",
      info: true,
      muted: MapSet.new(),
      typing: false,
      sent: 0,
      reply_index: 0,
      search: to_form(%{"q" => ""}, as: :search),
      message: to_form(%{"text" => ""}, as: :message)
    )
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, socket |> assign(current: id, typing: false) |> change(id, &%{&1 | unread: 0})}
  end

  def handle_event("search", %{"search" => %{"q" => query} = params}, socket),
    do: {:noreply, assign(socket, query: query, search: to_form(params, as: :search))}

  def handle_event("toggle-info", _params, socket), do: {:noreply, update(socket, :info, &(!&1))}

  def handle_event("send", %{"message" => %{"text" => text}}, socket) do
    case String.trim(text) do
      "" ->
        {:noreply, socket}

      text ->
        id = socket.assigns.current
        Process.send_after(self(), {:reply, id}, 1400)

        {:noreply,
         socket
         |> change(id, &add(&1, :me, text))
         |> update(:sent, &(&1 + 1))
         |> assign(typing: true, message: to_form(%{"text" => ""}, as: :message))}
    end
  end

  def handle_event("mute", _params, socket) do
    id = socket.assigns.current

    {:noreply,
     update(socket, :muted, fn muted ->
       (MapSet.member?(muted, id) && MapSet.delete(muted, id)) || MapSet.put(muted, id)
     end)}
  end

  def handle_event("clear", _params, socket) do
    socket
    |> change(socket.assigns.current, &%{&1 | messages: [], preview: "No messages"})
    |> send_toast("Chat cleared", color: "info")
    |> then(&{:noreply, &1})
  end

  def handle_event("menu", %{"action" => action}, socket),
    do: {:noreply, send_toast(socket, action, color: "info")}

  def handle_info({:reply, id}, socket) do
    replies = Data.replies()
    text = Enum.at(replies, rem(socket.assigns.reply_index, length(replies)))

    {:noreply,
     socket
     |> change(id, &add(&1, :them, text))
     |> update(:reply_index, &(&1 + 1))
     |> assign(typing: false)}
  end

  defp add(contact, from, text) do
    time = Calendar.strftime(Time.utc_now(), "%H:%M")
    message = %{from: from, text: text, time: time, images: []}
    %{contact | messages: contact.messages ++ [message], preview: text, time: time}
  end

  defp change(socket, id, fun) do
    update(socket, :contacts, fn contacts ->
      Enum.map(contacts, &((&1.id == id && fun.(&1)) || &1))
    end)
  end

  defp visible(contacts, query) do
    query = query |> String.trim() |> String.downcase()
    Enum.filter(contacts, &(query == "" or String.contains?(String.downcase(&1.name), query)))
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        contact: Enum.find(assigns.contacts, &(&1.id == assigns.current)),
        shown: visible(assigns.contacts, assigns.query)
      )

    ~H"""
    <.app_layout full>
      <:panel>
        <.chat_panel contacts={@shown} all={@contacts} current={@current} search={@search} />
      </:panel>
      <div class="flex h-full">
        <div class="flex min-w-0 grow flex-col">
          <.chat_header
            contact={@contact}
            info={@info}
            muted={MapSet.member?(@muted, @current)}
            typing={@typing}
          />
          <.scroll_area
            id="chat-messages"
            stick_bottom
            class="grow px-[calc(var(--margin-x)-.5rem)] py-5"
          >
            <div class="space-y-5">
              <div :if={@contact.messages != []} class="mx-4 flex items-center space-x-3">
                <.divider class="flex-1" />
                <p>Sunday</p>
                <.divider class="flex-1" />
              </div>
              <p :if={@contact.messages == []} class="py-10 text-center">
                No messages yet. Say hello!
              </p>
              <.bubble
                :for={{message, index} <- Enum.with_index(@contact.messages)}
                message={message}
                id={"msg-#{index}"}
                contact={@contact}
              />
              <div :if={@typing} id="typing" class="flex items-center space-x-2.5 sm:space-x-5">
                <.avatar src={@contact.avatar} />
                <.spinner size="sm" color="primary" />
              </div>
            </div>
          </.scroll_area>
          <.form
            for={@message}
            id="chat-form"
            phx-submit="send"
            class="flex h-14 shrink-0 items-center justify-between border-t border-slate-150 bg-white px-[calc(var(--margin-x)-.5rem)] dark:border-navy-600 dark:bg-navy-800"
          >
            <div class="-ml-1.5 flex flex-1 space-x-2">
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-9 shrink-0 text-slate-500 dark:text-navy-200"
                phx-click="menu"
                phx-value-action="Attachments are disabled in the demo"
                aria-label="Attach"
              >
                <.icon name="huge-attachment-01" class="size-5.5" />
              </.button>
              <.input
                id={"chat-input-#{@sent}"}
                field={@message[:text]}
                phx-mounted={@sent > 0 && JS.focus()}
                variant="plain"
                placeholder="Write the message"
                autocomplete="off"
                class="h-9 w-full px-2"
                wrapper_class="w-full"
              />
            </div>
            <div class="-mr-1.5 flex items-center">
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-9 text-slate-500 dark:text-navy-200"
                phx-click="menu"
                phx-value-action="Emoji picker"
                aria-label="Emoji"
              >
                <.icon name="huge-smile" class="size-5.5" />
              </.button>
              <.button
                icon
                type="submit"
                variant="flat"
                shape="pill"
                class="size-9 text-primary dark:text-accent-light"
                aria-label="Send"
              >
                <.icon name="huge-sent" class="size-5.5" />
              </.button>
            </div>
          </.form>
        </div>
        <.chat_info :if={@info} contact={@contact} />
      </div>
    </.app_layout>
    """
  end

  attr :contact, :map, required: true
  attr :info, :boolean, required: true
  attr :muted, :boolean, required: true
  attr :typing, :boolean, required: true

  defp chat_header(assigns) do
    ~H"""
    <div class="relative z-10 flex h-[61px] w-full shrink-0 items-center justify-between border-b border-slate-150 bg-white px-[calc(var(--margin-x)-.5rem)] shadow-xs dark:border-navy-700 dark:bg-navy-800">
      <button
        type="button"
        class="flex cursor-pointer items-center space-x-4 font-inter"
        phx-click="toggle-info"
      >
        <.avatar src={@contact.avatar} status={(@contact.online && "success") || nil} />
        <div class="text-left">
          <p class="line-clamp-1 font-medium text-slate-700 dark:text-navy-100">{@contact.name}</p>
          <p class="mt-0.5 text-xs">
            {(@typing && "typing...") || (@contact.online && "Online") || "Last seen recently"}
          </p>
        </div>
      </button>
      <div class="-mr-1 flex items-center">
        <.button
          icon
          variant="flat"
          shape="pill"
          class="size-9 text-slate-500 dark:text-navy-200"
          phx-click="menu"
          phx-value-action="Calling..."
        >
          <.icon name="huge-call" class="size-5.5" />
        </.button>
        <.button
          icon
          variant="flat"
          shape="pill"
          class="size-9 text-slate-500 dark:text-navy-200"
          phx-click={JS.focus(to: "#chat-form input")}
          aria-label="Search"
        >
          <.icon name="huge-search-01" class="size-5.5" />
        </.button>
        <.button
          icon
          variant="flat"
          shape="pill"
          class={[
            "size-9",
            (@info && "text-primary dark:text-accent-light") || "text-slate-500 dark:text-navy-200"
          ]}
          phx-click="toggle-info"
          aria-label="Chat info"
        >
          <.icon name="huge-sidebar-right" class="size-5.5" />
        </.button>
        <.dropdown id="chat-menu" placement="bottom-end">
          <:toggle>
            <.button icon variant="flat" shape="pill" class="size-9" aria-label="Chat menu">
              <.icon name="huge-more-vertical" class="size-5.5" />
            </.button>
          </:toggle>
          <.dropdown_item phx-click="mute">{(@muted && "Unmute") || "Mute"}</.dropdown_item>
          <.dropdown_item phx-click="menu" phx-value-action="Chat settings">
            Chat Setting
          </.dropdown_item>
          <.dropdown_item phx-click="menu" phx-value-action="User blocked">Block User</.dropdown_item>
          <.dropdown_item color="error" phx-click="clear">Delete chat</.dropdown_item>
        </.dropdown>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :message, :map, required: true
  attr :contact, :map, required: true

  defp bubble(%{message: %{from: :them}} = assigns) do
    ~H"""
    <div id={@id} class="flex items-start space-x-2.5 sm:space-x-5">
      <.avatar src={@contact.avatar} />
      <div class="flex flex-col items-start space-y-3.5">
        <div :if={@message.text} class="mr-4 max-w-lg sm:mr-10">
          <div class="rounded-2xl rounded-tl-none bg-white p-3 text-slate-700 shadow-xs dark:bg-navy-700 dark:text-navy-100">
            {@message.text}
          </div>
          <p class="ml-auto mt-1 text-right text-xs text-slate-400 dark:text-navy-300">
            {@message.time}
          </p>
        </div>
        <div :if={@message.images != []} class="mr-4 max-w-lg sm:mr-10">
          <div class="grid grid-cols-3 gap-2">
            <div
              :for={{image, index} <- Enum.with_index(@message.images)}
              class={["group relative", index == 0 && "row-span-2"]}
            >
              <img
                class="h-full rounded-lg object-cover"
                src={"/images/object/#{image}.jpg"}
                alt="image"
              />
              <div class="absolute top-0 flex h-full w-full items-center justify-center rounded-lg bg-black/30 opacity-0 transition-all duration-300 group-hover:opacity-100">
                <.button
                  icon
                  color="info"
                  shape="pill"
                  class="size-9"
                  phx-click="menu"
                  phx-value-action="Download started"
                  aria-label="Download"
                >
                  <.icon name="huge-download-01" class="size-5" />
                </.button>
              </div>
            </div>
          </div>
          <p class="ml-auto mt-1 text-right text-xs text-slate-400 dark:text-navy-300">
            {@message.time}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp bubble(assigns) do
    ~H"""
    <div id={@id} class="flex items-start justify-end space-x-2.5 sm:space-x-5">
      <div class="ml-4 max-w-lg sm:ml-10">
        <div class="rounded-2xl rounded-tr-none bg-info/10 p-3 text-slate-700 shadow-xs dark:bg-accent dark:text-white">
          {@message.text}
        </div>
        <p class="mt-1 text-left text-xs text-slate-400 dark:text-navy-300">{@message.time}</p>
      </div>
      <.avatar src={Data.me()} />
    </div>
    """
  end

  attr :contacts, :list, required: true
  attr :all, :list, required: true
  attr :current, :string, required: true
  attr :search, :any, required: true

  defp chat_panel(assigns) do
    ~H"""
    <.panel_header title="Chat" color="info">
      <.icon name="huge-bubble-chat" class="size-5" />
    </.panel_header>
    <div class="flex min-h-0 grow flex-col">
      <div class="flex items-center justify-between px-4">
        <span class="text-xs font-medium uppercase">History</span>
        <.button
          icon
          variant="flat"
          shape="pill"
          class="-mr-1.5 size-6 text-inherit"
          phx-click="menu"
          phx-value-action="New chat"
          aria-label="New chat"
        >
          <.icon name="huge-plus-sign" class="size-3.5" />
        </.button>
      </div>
      <div class="is-scrollbar-hidden mt-2 flex space-x-2.5 overflow-x-auto px-4 pb-1">
        <button
          :for={id <- Data.stories()}
          type="button"
          class="flex shrink-0 flex-col items-center text-xs"
          phx-click="select"
          phx-value-id={id}
        >
          <.avatar
            src={Enum.find(@all, &(&1.id == id)).avatar}
            gradient="fuchsia-pink"
            size="sm"
            class="size-12"
          />
          <span class="mt-0.5">{Enum.find(@all, &(&1.id == id)).name |> String.split() |> hd()}</span>
        </button>
      </div>
      <div class="mt-3 flex items-center space-x-1.5 px-3">
        <.form for={@search} id="chat-search" phx-change="search" class="flex-1">
          <.input
            field={@search[:q]}
            variant="filled"
            placeholder="Search chats"
            phx-debounce="150"
            autocomplete="off"
            class="h-9"
          >
            <:prefix><.icon name="huge-search-01" class="size-4.5" /></:prefix>
          </.input>
        </.form>
        <.button
          icon
          variant="flat"
          shape="pill"
          class="size-8 text-inherit"
          phx-click="menu"
          phx-value-action="Filters"
          aria-label="Filter"
        >
          <.icon name="huge-sliders-horizontal" class="size-5" />
        </.button>
      </div>
      <div class="is-scrollbar-hidden mt-3 grow overflow-y-auto px-2 pb-2">
        <button
          :for={contact <- @contacts}
          id={"contact-#{contact.id}"}
          type="button"
          phx-click="select"
          phx-value-id={contact.id}
          class={[
            "flex w-full items-center space-x-2.5 rounded-lg px-2 py-2 text-left transition-colors hover:bg-slate-100 dark:hover:bg-navy-600",
            contact.id == @current && "bg-primary/10 dark:bg-accent-light/10"
          ]}
        >
          <.avatar src={contact.avatar} status={(contact.online && "success") || "neutral"} />
          <div class="min-w-0 flex-1">
            <div class="flex items-center justify-between space-x-1.5">
              <p class="line-clamp-1 font-medium text-slate-700 dark:text-navy-100">{contact.name}</p>
              <span class="shrink-0 text-xs text-slate-400 dark:text-navy-300">{contact.time}</span>
            </div>
            <div class="flex items-center justify-between space-x-1">
              <p class="line-clamp-1 text-xs-plus">{contact.preview}</p>
              <.badge
                :if={contact.unread > 0}
                color="primary"
                shape="pill"
                class="h-5 min-w-5 justify-center px-1.5 text-tiny-plus"
              >
                {contact.unread}
              </.badge>
            </div>
          </div>
        </button>
        <p :if={@contacts == []} class="p-4 text-center">No chat matches.</p>
      </div>
    </div>
    """
  end

  attr :contact, :map, required: true

  defp chat_info(assigns) do
    ~H"""
    <aside class="hidden w-80 shrink-0 flex-col border-l border-slate-150 bg-white dark:border-navy-700 dark:bg-navy-750 xl:flex">
      <div class="flex h-[61px] shrink-0 items-center justify-between px-4">
        <h3 class="text-base font-medium text-slate-700 dark:text-navy-100">Chat Info</h3>
        <.button
          icon
          variant="flat"
          shape="pill"
          class="-mr-1.5 size-8 text-inherit"
          phx-click="toggle-info"
          aria-label="Close"
        >
          <.icon name="huge-arrow-right-01" class="size-5" />
        </.button>
      </div>
      <div class="is-scrollbar-hidden grow overflow-y-auto px-4 pb-4">
        <div class="flex flex-col items-center pt-2">
          <.avatar src={@contact.avatar} size="2xl" class="size-20" />
          <h4 class="mt-3 text-lg font-medium text-slate-700 dark:text-navy-100">{@contact.name}</h4>
          <p>{@contact.job}</p>
          <div class="mt-3 flex space-x-3">
            <.button
              :for={
                {icon, label} <- [
                  {"huge-call", "Call"},
                  {"huge-video-01", "Video"},
                  {"huge-mail-01", "Mail"}
                ]
              }
              icon
              variant="flat"
              shape="pill"
              class="size-9 text-slate-500 dark:text-navy-200"
              phx-click="menu"
              phx-value-action={label}
              aria-label={label}
            >
              <.icon name={icon} class="size-4.5" />
            </.button>
          </div>
        </div>
        <.tabs id="tab-media" class="mt-4" panels_class="pt-3" bordered>
          <:tab name="images">Images</:tab>
          <:tab name="files">Files</:tab>
          <:panel name="images">
            <div class="grid grid-cols-4 gap-2">
              <img
                :for={image <- Data.media()}
                class="aspect-square w-full rounded-md object-cover"
                src={"/images/object/#{image}.jpg"}
                alt="image"
              />
            </div>
          </:panel>
          <:panel name="files">
            <div class="space-y-3">
              <div :for={{name, size, icon} <- Data.files()} class="flex items-center space-x-3">
                <.avatar color="primary" variant="soft" size="sm">
                  <.icon name={icon} class="size-4.5" />
                </.avatar>
                <div>
                  <p class="text-slate-700 dark:text-navy-100">{name}</p>
                  <p class="text-xs">{size}</p>
                </div>
              </div>
            </div>
          </:panel>
        </.tabs>
      </div>
    </aside>
    """
  end
end
