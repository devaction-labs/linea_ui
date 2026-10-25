defmodule LineaShowcaseWeb.Templates.Apps.AiChat do
  @moduledoc """
  LineOne's AI Chat: a prompt typed or picked from the suggestion cards gets a canned reply that
  streams in word by word (`handle_info/2` ticks), recent chats reopen their conversation, a new
  chat starts over, the engine is picked from a dropdown, and each answer can be copied or rated.
  """

  use LineaShowcaseWeb.Template,
    title: "Ai Chat App",
    section: :apps,
    lineone: "apps-ai-chat",
    order: 2

  import LineaShowcaseWeb.Templates.Apps.Parts

  alias LineaShowcaseWeb.Templates.Apps.AiChat.Data

  @engines ["GPT 3", "GPT 4", "Copilot", "Copilot Pro"]

  def mount(socket) do
    assign(socket,
      messages: [],
      engine: "GPT 4",
      engines: @engines,
      recent: Data.recent(),
      active: nil,
      streaming: false,
      sent: 0,
      rated: %{},
      prompt: to_form(%{"text" => ""}, as: :prompt)
    )
  end

  def handle_event("send", %{"prompt" => %{"text" => text}}, socket) do
    {:noreply, ask(socket, String.trim(text))}
  end

  def handle_event("suggest", %{"text" => text}, socket), do: {:noreply, ask(socket, text)}

  def handle_event("new-chat", _params, socket),
    do: {:noreply, assign(socket, messages: [], active: nil, streaming: false)}

  def handle_event("open-chat", %{"index" => index}, socket) do
    {title, answer} = Enum.at(socket.assigns.recent, String.to_integer(index))

    {:noreply,
     assign(socket,
       messages: [message(:user, title, 1), message(:ai, answer, 2)],
       active: String.to_integer(index),
       streaming: false
     )}
  end

  def handle_event("engine", %{"engine" => engine}, socket),
    do: {:noreply, assign(socket, engine: engine)}

  def handle_event("rate", %{"id" => id, "rating" => rating}, socket) do
    socket
    |> update(:rated, &Map.put(&1, id, rating))
    |> send_toast("Thanks for the feedback", color: "success")
    |> then(&{:noreply, &1})
  end

  def handle_event("menu", %{"action" => action}, socket),
    do: {:noreply, send_toast(socket, action, color: "info")}

  def handle_info({:stream, id, words, shown}, socket) do
    text = words |> Enum.take(shown) |> Enum.join(" ")

    socket =
      update(socket, :messages, fn messages ->
        Enum.map(messages, &((&1.id == id && %{&1 | text: text}) || &1))
      end)

    {:noreply, continue(socket, id, words, shown)}
  end

  defp continue(socket, _id, words, shown) when shown >= length(words),
    do: assign(socket, streaming: false)

  defp continue(socket, id, words, shown) do
    Process.send_after(self(), {:stream, id, words, shown + 2}, 60)
    socket
  end

  defp ask(socket, ""), do: socket

  defp ask(%{assigns: %{streaming: true}} = socket, _text), do: socket

  defp ask(socket, text) do
    sent = socket.assigns.sent
    replies = Data.replies()
    reply = Enum.at(replies, rem(sent, length(replies)))
    id = "ai-#{sent}"
    words = String.split(reply, " ")
    Process.send_after(self(), {:stream, id, words, 2}, 500)

    socket
    |> update(:messages, &(&1 ++ [message(:user, text, "u-#{sent}"), message(:ai, "", id)]))
    |> assign(
      sent: sent + 1,
      streaming: true,
      active: nil,
      prompt: to_form(%{"text" => ""}, as: :prompt)
    )
  end

  defp message(role, text, id), do: %{role: role, text: text, id: to_string(id)}

  defp rated(rated, id), do: Map.get(rated, id)

  def render(assigns) do
    ~H"""
    <.app_layout full>
      <:panel><.ai_panel recent={@recent} active={@active} /></:panel>
      <div class="chat-app flex h-full min-w-0 flex-col">
        <div class="relative z-10 flex h-[61px] w-full shrink-0 items-center justify-between border-b border-slate-150 bg-white px-[calc(var(--margin-x)-.5rem)] shadow-xs dark:border-navy-700 dark:bg-navy-800">
          <.dropdown id="engine-selector" placement="bottom-start">
            <:toggle>
              <.button variant="flat" class="space-x-2 font-medium text-slate-700 dark:text-navy-100">
                <span>{@engine}</span>
                <.icon name="huge-arrow-down-01" class="size-4" />
              </.button>
            </:toggle>
            <.dropdown_item
              :for={engine <- @engines}
              phx-click="engine"
              phx-value-engine={engine}
              class={engine == @engine && "text-primary dark:text-accent-light"}
            >
              {engine}
            </.dropdown_item>
          </.dropdown>
          <.button
            color="success"
            class="space-x-2 bg-gradient-to-r from-emerald-500 to-blue-600 text-white dark:bg-gradient-to-r"
            phx-click="menu"
            phx-value-action="Ai Pro is coming soon"
          >
            <.icon name="huge-rocket-01" class="size-4" />
            <span class="max-sm:hidden"> Try Ai Pro </span>
          </.button>
        </div>
        <.scroll_area
          id="ai-messages"
          stick_bottom
          class="mx-auto w-full max-w-screen-lg grow space-y-8 py-4 xl:px-12"
        >
          <.welcome :if={@messages == []} />
          <div :if={@messages != []} class="space-y-8 px-2 pt-6 sm:px-4 lg:pt-12">
            <div
              :for={{pair, index} <- @messages |> Enum.chunk_every(2) |> Enum.with_index()}
              id={"pair-#{index}"}
              class="space-y-4"
            >
              <.exchange
                :for={message <- pair}
                message={message}
                rating={rated(@rated, message.id)}
                streaming={@streaming}
              />
            </div>
          </div>
        </.scroll_area>
        <div class="mx-auto w-full max-w-screen-lg px-3 pb-4 sm:px-4 xl:px-16">
          <.form
            for={@prompt}
            id="prompt-form"
            phx-submit="send"
            class="flex h-14 items-center justify-between rounded-full bg-slate-150 px-4 dark:bg-navy-700 sm:px-6"
          >
            <.input
              id={"prompt-input-#{@sent}"}
              field={@prompt[:text]}
              phx-mounted={@sent > 0 && JS.focus()}
              variant="plain"
              placeholder="Ask me anything..."
              autocomplete="off"
              class="h-9"
              wrapper_class="w-full"
            />
            <div class="flex">
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-9 shrink-0 text-slate-500 dark:text-navy-200"
                phx-click="menu"
                phx-value-action="Image upload"
                aria-label="Image"
              >
                <.icon name="huge-image-01" class="size-5" />
              </.button>
              <.button
                icon
                variant="flat"
                shape="pill"
                class="size-9 shrink-0 text-slate-500 dark:text-navy-200"
                phx-click="menu"
                phx-value-action="Voice input"
                aria-label="Voice"
              >
                <.icon name="huge-mic-01" class="size-5" />
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </.app_layout>
    """
  end

  defp welcome(assigns) do
    ~H"""
    <div class="px-4 pt-6 text-[clamp(2.2rem,3.75vw,3.75rem)] font-medium leading-[1.1] tracking-tight">
      <span
        class="block animate-shimmer bg-gradient-to-r from-violet-400 via-red-400 to-fuchsia-400 bg-clip-text font-semibold text-transparent"
        style="animation-duration: 5s; background-size: 200% 100%"
      >
        Welcome, John Doe
      </span>
      <span class="block text-slate-400 dark:text-navy-300">May I be of assistance today?</span>
    </div>
    <div class="flex w-full shrink-0 gap-5 px-4 pt-8 max-lg:overflow-x-auto lg:grid lg:grid-cols-4 lg:pt-16">
      <button
        :for={{text, index} <- Enum.with_index(Data.suggestions())}
        type="button"
        id={"suggestion-#{index}"}
        phx-click="suggest"
        phx-value-text={text}
        class={[
          "group relative flex shrink-0 flex-col rounded-lg bg-white p-3 text-left shadow-soft dark:bg-navy-700 dark:shadow-none max-lg:w-48",
          (rem(index, 2) == 0 && "lg:-rotate-3") || "lg:rotate-3"
        ]}
      >
        <span class="grow">{text}</span>
        <span class="flex justify-end pt-6">
          <.avatar size="xs" class="size-8">
            <.icon name="huge-arrow-up-right-01" class="size-4" />
          </.avatar>
        </span>
        <span class="absolute inset-0 rounded-lg bg-black/10 opacity-0 transition-colors group-hover:opacity-100"></span>
      </button>
    </div>
    """
  end

  attr :message, :map, required: true
  attr :rating, :string, default: nil
  attr :streaming, :boolean, required: true

  defp exchange(%{message: %{role: :user}} = assigns) do
    ~H"""
    <div id={"msg-#{@message.id}"} class="ml-4 flex items-end justify-end gap-2.5 sm:ml-10">
      <div class="relative max-w-lg break-words rounded-2xl rounded-br bg-slate-150 p-3 dark:bg-navy-700">
        {@message.text}
      </div>
      <.avatar src={LineaShowcaseWeb.Templates.Apps.Chat.Data.me()} class="max-sm:hidden" />
    </div>
    """
  end

  defp exchange(assigns) do
    ~H"""
    <div id={"msg-#{@message.id}"} class="mr-4 flex items-end justify-start gap-2.5 sm:mr-10">
      <.avatar color="info" class="size-10 shrink-0 max-sm:hidden">
        <.icon name="huge-robot-01" class="size-5" />
      </.avatar>
      <div class="relative w-full max-w-lg break-words rounded-2xl rounded-bl border border-slate-200 p-3 dark:border-navy-600">
        <div class="text-sm-plus">
          <span :if={@message.text == ""}><.spinner size="sm" color="primary" /></span>
          {@message.text}
        </div>
        <div class="-mx-1 flex justify-between pt-8">
          <div class="flex space-x-1">
            <.clipboard
              id={"copy-#{@message.id}"}
              value={@message.text}
              variant="flat"
              color="neutral"
              size="xs"
              class="size-8 rounded-full p-0"
              aria-label="Copy"
            >
              <.icon name="huge-copy-01" class="size-5" />
            </.clipboard>
            <.button
              icon
              variant="flat"
              shape="pill"
              class="size-8 text-inherit"
              phx-click="menu"
              phx-value-action="Link copied"
              aria-label="Share"
            >
              <.icon name="huge-share-01" class="size-5" />
            </.button>
            <.button
              icon
              variant="flat"
              shape="pill"
              class="size-8 text-inherit"
              phx-click="menu"
              phx-value-action="Issue reported"
              aria-label="Report issue"
            >
              <.icon name="huge-flag-01" class="size-5" />
            </.button>
          </div>
          <div class="flex">
            <.button
              :for={
                {rating, icon, label} <- [
                  {"bad", "huge-thumbs-down", "Bad Response"},
                  {"good", "huge-thumbs-up", "Good Response"}
                ]
              }
              icon
              variant="flat"
              shape="pill"
              class={[
                "size-8",
                (@rating == rating && "text-primary dark:text-accent-light") || "text-inherit"
              ]}
              phx-click="rate"
              phx-value-id={@message.id}
              phx-value-rating={rating}
              aria-label={label}
              aria-pressed={to_string(@rating == rating)}
            >
              <.icon name={icon} class="size-4" />
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :recent, :list, required: true
  attr :active, :integer, default: nil

  defp ai_panel(assigns) do
    ~H"""
    <.panel_header title="Ai Chat" color="warning">
      <.icon name="huge-robot-01" class="size-5" />
    </.panel_header>
    <div class="flex min-h-0 grow flex-col">
      <.panel_button phx-click="new-chat">
        <.icon name="huge-plus-sign" class="size-4.5" />
        <span> New Chat </span>
      </.panel_button>
      <ul class="mt-4 space-y-1.5 px-2">
        <li :for={{label, count, icon} <- links()}>
          <.panel_item href="#" count={count}>
            <:icon>
              <.icon name={icon} class="size-4.5" />
            </:icon>
            {label}
          </.panel_item>
        </li>
      </ul>
      <.divider class="mx-4 my-3" />
      <div class="flex items-center justify-between px-4">
        <span class="text-xs font-medium uppercase">Recent chats</span>
        <.icon name="huge-search-01" class="size-3.5" />
      </div>
      <div class="is-scrollbar-hidden mt-2 grow overflow-y-auto px-2 pb-2">
        <button
          :for={{{title, answer}, index} <- Enum.with_index(@recent)}
          id={"recent-#{index}"}
          type="button"
          phx-click="open-chat"
          phx-value-index={index}
          class={[
            "flex w-full items-start space-x-2 rounded-lg px-2 py-2 text-left hover:bg-slate-100 dark:hover:bg-navy-600",
            @active == index && "bg-primary/10 dark:bg-accent-light/10"
          ]}
        >
          <.icon
            name="huge-bubble-chat"
            class="mt-0.5 size-4.5 shrink-0 text-slate-400 dark:text-navy-300"
          />
          <span class="min-w-0">
            <span class="line-clamp-1 text-xs-plus font-medium text-slate-700 dark:text-navy-100">{title}</span>
            <span class="line-clamp-1 text-xs">{answer}</span>
          </span>
        </button>
      </div>
      <div class="flex shrink-0 items-center justify-between px-1.5 py-1">
        <.button
          icon
          variant="flat"
          shape="pill"
          class="size-8 text-inherit"
          phx-click="menu"
          phx-value-action="Settings"
          aria-label="Settings"
        >
          <.icon name="huge-settings-02" class="size-4.5" />
        </.button>
        <div class="flex">
          <.button
            icon
            variant="flat"
            shape="pill"
            class="size-8 text-inherit"
            phx-click="menu"
            phx-value-action="Feedback sent"
            aria-label="Feedback"
          >
            <.icon name="huge-message-01" class="size-4" />
          </.button>
          <.button
            icon
            variant="flat"
            shape="pill"
            class="size-8 text-inherit"
            phx-click="menu"
            phx-value-action="Help center"
            aria-label="Help"
          >
            <.icon name="huge-help-circle" class="size-4" />
          </.button>
        </div>
      </div>
    </div>
    """
  end

  defp links do
    [
      {"Favorites", 2, "huge-star"},
      {"Archived", 43, "huge-archive-01"},
      {"Plugins", nil, "huge-puzzle"}
    ]
  end
end
