defmodule LineaUI.Components.Ai do
  @moduledoc """
  The assistant ("Assistente (IA)"): the conversation, its messages, the proposals the user approves, the
  queries the assistant shows it made, the field to ask, the list of conversations and the starting suggestions.
  The assistant proposes and the user approves; nothing changes without a confirmation.

      <.ai_chat id="assistente" messages={@messages} user={@current_user}
        on_send="send" on_approve="approve" on_reject="reject" />

  Or piece by piece:

      <.ai_message role="user" name="Marina Costa">Quais pedidos têm linha sem produto?</.ai_message>

      <.ai_message>
        <:trace><.ai_tool_trace tools={@tools} duration_ms={3000} /></:trace>
        <p>Encontrei <b class="ink">1 pedido</b>.</p>
        <.ai_proposal id="p1" title="Sugestão: trocar o produto da linha" on_approve="approve" on_reject="reject">
          <:change label="Pedido">#2491 · Mercadinho Bom Preço</:change>
          <:change label="Linha 3" from="Cimento CP2 50" to="40011 · Cimento CP-II 50kg" />
        </.ai_proposal>
      </.ai_message>

      <.ai_composer field={@form[:pergunta]} context={[:pedidos]} phx-submit="send" />

      <.conversation_list conversations={@conversas} active={@conversa.id} on_select="open" />

      <.prompt_suggestions items={@sugestoes} on_pick="ask" />

  A message of `ai_chat` is a map: `:id`, `:role` (`:user` or `:assistant`), `:text` (paragraphs separated by a
  blank line, `**bold**` is bold), `:name` (of the user, for the avatar), `:trace` (`%{tools: [...],
  duration_ms: 3000, running: false}`), `:proposal` (`%{id:, title:, status:, changes: [%{label:, from:, to:,
  text:}], note:, editable:}`), `:streaming` and `:status`.
  """

  use LineaUI.Component

  import LineaUI.Components.Avatar, only: [avatar: 1]
  import LineaUI.Components.Badge, only: [badge: 1]
  import LineaUI.Components.Button, only: [button: 1]
  import LineaUI.Components.Icon, only: [icon: 1]
  import LineaUI.Components.Skeleton, only: [skeleton: 1]
  import LineaUI.Components.Spinner, only: [spinner: 1]

  @contexts %{
    pedidos: {"Pedidos", "huge-invoice-01"},
    catalogo: {"Catálogo", "huge-package"},
    clientes: {"Clientes", "huge-user-multiple"},
    financeiro: {"Financeiro", "huge-wallet-01"},
    fiscal: {"Fiscal", "huge-invoice-01"},
    banco: {"Banco", "huge-bank"}
  }

  # --------------------------------------------------------------------------------------------------
  # ai_tool_trace

  @doc """
  What the assistant consulted: one chip per query, how many and how long. `running` shows the spinner and
  "em andamento"; a tool with `failed: true` is marked in red; `expanded` lists each query with its filters.

      <.ai_tool_trace tools={[%{icon: "huge-invoice-01", label: "Pedidos", detail: "situação ≠ faturado · 14 linhas"}]} duration_ms={3000} />
  """
  attr :tools, :list,
    default: [],
    doc:
      "Maps `%{icon, label, title, detail, failed}`: the Hugeicons name, the name of the source (`title` is its name in the expanded list), what was asked and `failed: true` for a query that did not work."

  attr :running, :boolean, default: false, doc: "The queries are still going on."

  attr :expanded, :boolean,
    default: false,
    doc: "Lists each query with its filters under the chips."

  attr :duration_ms, :integer, default: nil, doc: "The total time, shown in seconds."
  attr :class, :any, default: nil
  attr :rest, :global

  def ai_tool_trace(assigns) do
    assigns =
      assign_derived(assigns, :summary, [:tools, :running, :duration_ms], fn ->
        summary(assigns.tools, assigns.running, assigns.duration_ms)
      end)

    ~H"""
    <div class={merge(["ai-trace", @class])} {@rest}>
      <div class="ai-trace-line">
        <span :if={@running} class="ai-trace-running">
          <.spinner variant="canvas" size="xs" class="size-3" label="Consultando" />Consultando
        </span>
        <span :if={!@running && failed?(@tools)} class="ai-trace-fail">Não conseguiu consultar</span>
        <span :if={!@running && !failed?(@tools)}>Consultou</span>
        <.chip :for={tool <- @tools} icon={tool[:icon]} failed={tool[:failed] == true}>
          {tool.label}
        </.chip>
        <span class="mono">{@summary}</span>
      </div>
      <div :if={@expanded} class="sg-card ai-trace-detail">
        <div :for={tool <- @tools} class="ai-trace-row">
          <.icon :if={tool[:icon]} name={tool.icon} class="i sm" boxed box_size="sm" />
          <b class="ink">{tool[:title] || tool.label}</b>
          <span :if={tool[:detail]} class="mono faint ai-trace-detail-text">{tool.detail}</span>
        </div>
      </div>
    </div>
    """
  end

  defp failed?(tools), do: Enum.any?(tools, &(&1[:failed] == true))

  defp summary(_tools, true, _duration), do: "em andamento"

  defp summary(tools, false, duration) do
    total = length(tools)

    case Enum.count(tools, &(&1[:failed] == true)) do
      0 -> count(total, "consulta", "consultas") <> seconds(duration)
      ^total -> "falhou"
      1 -> "1 de #{total} falhou"
      failed -> "#{failed} de #{total} falharam"
    end
  end

  defp count(1, one, _many), do: "1 #{one}"
  defp count(n, _one, many), do: "#{n} #{many}"

  defp seconds(nil), do: ""
  defp seconds(ms), do: " · #{max(round(ms / 1000), 1)} s"

  attr :icon, :string, default: nil
  attr :failed, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp chip(assigns) do
    ~H"""
    <span class={merge(["ai-chip", @failed && "neg", @class])}>
      <.icon :if={@icon} name={@icon} class="i sm" />{render_slot(@inner_block)}
    </span>
    """
  end

  # --------------------------------------------------------------------------------------------------
  # ai_message

  @doc """
  A message of the conversation. The user's is a bubble on the right with the avatar; the assistant's is a card
  with the spark, the queries it made (`trace` slot) and the content.

      <.ai_message role="user" name="Marina Costa">Quanto tenho para receber até sexta?</.ai_message>
      <.ai_message streaming><p>Os pedidos vencidos somam <b class="ink">R$ 12.300</b></p></.ai_message>
  """
  attr :role, :string, default: "assistant", values: ~w(user assistant)
  attr :streaming, :boolean, default: false, doc: "Shows the cursor after the last paragraph."

  attr :status, :string,
    default: "ok",
    values: ~w(ok error),
    doc:
      "`error` marks the message (`data-status`); the failed query itself is drawn by `ai_tool_trace`."

  attr :name, :string,
    default: nil,
    doc: "The user's name: the avatar of a `user` message shows its initials."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :trace, doc: "The queries the assistant made, above the content."
  slot :inner_block, required: true

  def ai_message(%{role: "user"} = assigns) do
    ~H"""
    <div class={merge(["ai-msg me", @class])} {@rest}>
      <div class="sg-bubble">{render_slot(@inner_block)}</div>
      <.avatar :if={@name} name={@name} size="24" tint="#8a5cd6" />
    </div>
    """
  end

  def ai_message(assigns) do
    ~H"""
    <div
      class={merge(["ai-msg", @class])}
      data-streaming={@streaming && "true"}
      data-status={@status}
      {@rest}
    >
      <.icon name="huge-sparkles" class="i sm" boxed tone="accent" box_class="ai-spark" />
      <div class="ai-body">
        {render_slot(@trace)}
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # --------------------------------------------------------------------------------------------------
  # ai_proposal

  @doc """
  An action the assistant proposes, which only happens when the user approves. `change` rows show the old
  value struck through and the new one in green; a row with content and no `from`/`to` is a plain fact.

      <.ai_proposal id="p1" title="Sugestão: trocar o produto da linha" status={:pending}
        on_approve="approve" on_reject="reject">
        <:change label="Pedido">#2491 · Mercadinho Bom Preço</:change>
        <:change label="Linha 3" from="Cimento CP2 50" to="40011 · Cimento CP-II 50kg" />
      </.ai_proposal>

  The events carry the proposal's `id` (`%{"id" => "p1"}`).
  """
  attr :id, :string, required: true
  attr :title, :string, required: true, doc: "What will be done."

  attr :status, :any,
    default: "pending",
    doc:
      "`pending` (Aprovar and Recusar), `applying`, `approved`, `rejected` or `failed`, as an atom or a string."

  attr :editable, :boolean, default: false, doc: "Shows Editar."
  attr :note, :string, default: nil, doc: "The line under the rows once decided."
  attr :on_approve, :any, default: nil, doc: "An event name or a `JS` command."
  attr :on_reject, :any, default: nil, doc: "An event name or a `JS` command."
  attr :on_undo, :any, default: nil, doc: "Shows Desfazer on an approved proposal."
  attr :on_edit, :any, default: nil, doc: "The event of Editar."
  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :change, doc: "A row: `label`, and `from` and `to` for a value that changes." do
    attr :label, :string, required: true
    attr :from, :string
    attr :to, :string
  end

  slot :impact, doc: "The effect in numbers; `label` defaults to Impacto." do
    attr :label, :string
  end

  slot :preview, doc: "A preview of the message or document; `label` defaults to Mensagem." do
    attr :label, :string
  end

  slot :action, doc: "A button in the line of a failed proposal."

  def ai_proposal(assigns) do
    assigns = assign(assigns, :state, to_string(assigns.status))

    ~H"""
    <div id={@id} class={merge(["sg-card flush ai-proposal", @class])} data-status={@state} {@rest}>
      <div class="ai-proposal-head">
        <span class="ai-proposal-spark"><.icon name="huge-sparkles" class="i sm" /></span>
        <b class="ink">{@title}</b>
        <span class="ai-proposal-state">
          <.badge :if={@state == "pending"} color="warning" dot>Aguardando você</.badge>
          <.badge :if={@state == "applying"} color="info" dot>Aplicando…</.badge>
          <.badge :if={@state == "approved"} color="success" dot>Aprovado</.badge>
          <.badge :if={@state == "rejected"}>Recusado</.badge>
          <.badge :if={@state == "failed"} color="error" dot>Falhou</.badge>
        </span>
      </div>
      <div class="ai-proposal-rows">
        <%= for row <- @change do %>
          <span class="faint">{row.label}</span>
          <span class="ai-proposal-value">
            <%= if row[:from] || row[:to] do %>
              <s class="mono faint ai-from">{row[:from]}</s>
              <.icon name="huge-arrow-right-01" class="i sm" />
              <span class="mono ai-to">{row[:to]}</span>
            <% else %>
              {render_slot(row)}
            <% end %>
          </span>
        <% end %>
        <%= for row <- @impact do %>
          <span class="faint">{row[:label] || "Impacto"}</span>
          <span class="ai-proposal-value">{render_slot(row)}</span>
        <% end %>
        <%= for row <- @preview do %>
          <span class="faint">{row[:label] || "Mensagem"}</span>
          <span class="ai-proposal-value">
            <span class="sg-bubble ai-preview">{render_slot(row)}</span>
          </span>
        <% end %>
      </div>
      <div :if={@state == "pending"} class="ai-proposal-foot actions">
        <.button
          :if={@editable}
          variant="ghost"
          size="sm"
          phx-click={click(@on_edit, @id, @target)}
        >
          <.icon name="huge-pencil-edit-01" class="i" />Editar
        </.button>
        <span :if={@editable} class="flex-1"></span>
        <.button size="sm" phx-click={click(@on_reject, @id, @target)}>Recusar</.button>
        <.button color="mono" size="sm" phx-click={click(@on_approve, @id, @target)}>
          <.icon name="huge-tick-02" class="i" />Aprovar
        </.button>
      </div>
      <div :if={@state == "applying"} class="ai-proposal-foot line">
        <.spinner variant="canvas" size="xs" label="Gravando" />{@note || "Gravando a alteração…"}
      </div>
      <div :if={@state == "approved"} class="ai-proposal-foot line">
        <.icon name="huge-tick-02" class="i sm" />{@note || "Aprovado"}
        <button
          :if={@on_undo}
          type="button"
          class="ink ai-proposal-link"
          phx-click={click(@on_undo, @id, @target)}
        >
          Desfazer
        </button>
      </div>
      <div :if={@state == "rejected"} class="ai-proposal-foot line">
        <.icon name="huge-cancel-01" class="i sm" />{@note || "Recusado · nada foi alterado"}
      </div>
      <div :if={@state == "failed"} class="ai-proposal-foot line neg">
        <.icon name="huge-alert-02" class="i sm" />{@note || "Não foi possível aplicar."}
        <span :if={@action != []} class="ai-proposal-link">{render_slot(@action)}</span>
      </div>
    </div>
    """
  end

  defp click(nil, _id, _target), do: nil
  defp click(%JS{} = js, _id, _target), do: js
  defp click(event, id, target), do: JS.push(event, push_opts(id, target))

  defp push_opts(id, target) do
    [value: id && %{id: id}, target: target] |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  # --------------------------------------------------------------------------------------------------
  # ai_composer

  @doc """
  The field to ask the assistant: the context chips, the text, the attachment and send (which becomes Stop while
  the assistant answers). It is a form: `phx-submit` and `phx-change` go on it.

      <.ai_composer field={@form[:pergunta]} context={[:pedidos]} phx-submit="send" phx-change="draft" />

  Enter sends, Shift+Enter breaks the line.
  """
  attr :id, :string, default: nil

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field; gives the name and value."

  attr :name, :string, default: nil, doc: "The name of the text without a `field`: `message`."
  attr :value, :string, default: nil

  attr :context, :list,
    default: [],
    doc:
      "Where the assistant looks: `:pedidos`, `:catalogo`, `:clientes`, `:financeiro`, `:fiscal`, `:banco`, a string or `%{label, icon}`. One shows as \"Contexto: Pedidos\"."

  attr :attachments, :list,
    default: [],
    doc: "Files shown above the field: `%{name, size}` (`size` in bytes or text)."

  attr :upload, :any,
    default: nil,
    doc: "A LiveView upload: the clip opens its file picker and its entries are the attachments."

  attr :streaming, :boolean, default: false, doc: "Swaps send for Parar."
  attr :on_stop, :any, default: nil, doc: "The event (or `JS`) of Parar."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_stop`."
  attr :placeholder, :string, default: "Pergunte sobre pedidos, estoque, fiscal ou financeiro"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-submit phx-change phx-target autocomplete)

  slot :chip,
    doc:
      "A custom chip, after the context ones (a slot cannot share the name of the `context` attr)."

  def ai_composer(assigns) do
    assigns =
      assigns
      |> assign_field()
      |> assign_derived(:contexts, [:context], fn -> Enum.map(assigns.context, &context/1) end)
      |> assign_derived(:files, [:attachments, :upload], fn ->
        files(assigns.attachments, assigns.upload)
      end)

    ~H"""
    <form
      id={@id}
      class={merge(["ai-composer", @class])}
      data-streaming={@streaming && "true"}
      {@rest}
    >
      <div :if={@files != []} class="ai-composer-files">
        <.chip :for={file <- @files} icon="huge-file-01">{file}</.chip>
      </div>
      <div class="ai-composer-row">
        <.chip :for={{label, icon} <- @contexts} icon={icon}>
          {(length(@contexts) == 1 && "Contexto: ") || ""}{label}
        </.chip>
        {render_slot(@chip)}
        <textarea
          id={@id && "#{@id}-text"}
          name={@name || "message"}
          rows="1"
          class="ai-input"
          placeholder={@placeholder}
          autocomplete="off"
          phx-hook="LineaUI.AiComposer"
        >{@value}</textarea>
        <label :if={@upload} class="sg-ib plain" aria-label="Anexar">
          <.icon name="huge-attachment" class="i" /><.live_file_input
            upload={@upload}
            class="sr-only"
          />
        </label>
        <.button :if={!@upload} icon variant="flat" aria-label="Anexar">
          <.icon name="huge-attachment" class="i" />
        </.button>
        <button
          :if={@streaming}
          type="button"
          class="ai-send stop"
          aria-label="Parar"
          phx-click={click(@on_stop, @id, @target)}
        >
          <i></i>
        </button>
        <button :if={!@streaming} type="submit" class="ai-send" aria-label="Enviar">
          <.icon name="huge-arrow-up-right-01" class="i" />
        </button>
      </div>
    </form>
    """
  end

  defp context({label, icon}), do: {label, icon}
  defp context(%{label: label} = ctx), do: {label, ctx[:icon]}
  defp context(key) when is_atom(key), do: Map.get(@contexts, key, {to_string(key), nil})
  defp context(label) when is_binary(label), do: {label, nil}

  defp files(attachments, upload) do
    entries = (upload && upload.entries) || []

    Enum.map(attachments, &file_label(&1.name, &1[:size])) ++
      Enum.map(entries, &file_label(&1.client_name, &1.client_size))
  end

  defp file_label(name, nil), do: name
  defp file_label(name, size) when is_binary(size), do: "#{name} · #{size}"
  defp file_label(name, bytes) when is_integer(bytes), do: "#{name} · #{kilobytes(bytes)}"

  defp kilobytes(bytes) when bytes < 1_048_576, do: "#{max(round(bytes / 1024), 1)} KB"
  defp kilobytes(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  # --------------------------------------------------------------------------------------------------
  # prompt_suggestions

  @doc """
  The starting suggestions: cards (slightly tilted) or pills. Choosing one sends `on_pick` with the text as
  `value` (and the `title`), for the app to fill the composer or ask.

      <.prompt_suggestions items={[%{title: "Resumo do dia", text: "Faça um resumo do dia."}]} on_pick="ask" />
      <.prompt_suggestions variant="pill" items={@next} on_pick="ask" />
  """
  attr :items, :list, required: true, doc: "Maps `%{title, text}`; a pill shows the `text`."

  attr :tilt, :boolean,
    default: true,
    doc: "Tilts the cards (decorative; turn it off in dense screens)."

  attr :variant, :string, default: "card", values: ~w(card pill)

  attr :on_pick, :any,
    default: nil,
    doc: "An event name (payload `%{value, title}`) or a `JS` command."

  attr :target, :any, default: nil, doc: "The `phx-target` of `on_pick`."
  attr :class, :any, default: nil
  attr :rest, :global

  def prompt_suggestions(%{variant: "pill"} = assigns) do
    ~H"""
    <div class={merge(["ai-suggestions pills", @class])} {@rest}>
      <button
        :for={item <- @items}
        type="button"
        class="sg-tag ai-pill"
        phx-click={pick(@on_pick, item.title, item.text, @target)}
      >
        <.icon name="huge-sparkles" class="i sm" />{item.text}
      </button>
    </div>
    """
  end

  def prompt_suggestions(assigns) do
    ~H"""
    <div class={merge(["ai-suggestions", !@tilt && "flat", @class])} {@rest}>
      <.suggestion_card
        :for={{item, index} <- Enum.with_index(@items)}
        title={item.title}
        prompt={item.text}
        tilt={@tilt && tilt(index)}
        on_pick={@on_pick}
        target={@target}
      >
        {item.text}
      </.suggestion_card>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :prompt, :string, required: true
  attr :tilt, :any, default: false
  attr :on_pick, :any, default: nil
  attr :target, :any, default: nil
  slot :inner_block, required: true

  defp suggestion_card(assigns) do
    ~H"""
    <button
      type="button"
      class="sg-card ai-suggestion"
      style={@tilt && "transform:rotate(#{@tilt}deg)"}
      phx-click={pick(@on_pick, @title, @prompt, @target)}
    >
      <span class="mono ai-suggestion-title">{@title}</span>
      <span class="ai-suggestion-text">{render_slot(@inner_block)}</span>
      <span class="sg-ib sm ai-suggestion-go">
        <.icon name="huge-arrow-up-right-01" class="i sm" />
      </span>
    </button>
    """
  end

  @tilts [-1.6, 1.2, -0.8, 1.6]
  defp tilt(index), do: Enum.at(@tilts, rem(index, length(@tilts)))

  defp pick(nil, _title, _prompt, _target), do: nil
  defp pick(%JS{} = js, _title, _prompt, _target), do: js

  defp pick(event, title, prompt, target) do
    opts = [value: %{value: prompt, title: title}]
    JS.push(event, (target && Keyword.put(opts, :target, target)) || opts)
  end

  @doc """
  The greeting of the assistant: the first line (the whole line) in a living gradient, whose colors drift
  across the text (6s, back and forth; 12s under `prefers-reduced-motion`), and the question under it.
  `tone="warm"` swaps the brand colors for pink, rose and orange.

      <.ai_greeting name="Marina" />
      <.ai_greeting name="Alex" tone="warm" greeting="Boa tarde, Alex" tagline="Vamos resolver o quê?" size="md" />
  """
  attr :name, :string,
    default: nil,
    doc: "Who is greeted; `Bom dia` / `Boa tarde` / `Boa noite` by the hour."

  attr :greeting, :string, default: nil, doc: "Replaces the whole first line."
  attr :tagline, :string, default: "Em que posso ajudar hoje?"
  attr :size, :string, default: "lg", values: ~w(sm md lg), doc: "30px, 36px or 40px."

  attr :tone, :string,
    default: "brand",
    values: ~w(brand warm),
    doc: "`brand` (accent, blue, violet, pink) or `warm` (pink, rose, orange, fuchsia)."

  attr :class, :any, default: nil
  attr :rest, :global

  def ai_greeting(assigns) do
    ~H"""
    <div
      class={merge(["ai-greeting", @size in ~w(sm md) && @size, @tone == "warm" && "warm", @class])}
      {@rest}
    >
      <h1>{@greeting || hello(@name)}</h1>
      <h2>{@tagline}</h2>
    </div>
    """
  end

  defp hello(name) do
    {{_, _, _}, {hour, _, _}} = :calendar.local_time()
    part = if hour < 12, do: "Bom dia", else: if(hour < 18, do: "Boa tarde", else: "Boa noite")
    (name && "#{part}, #{name}") || part
  end

  # --------------------------------------------------------------------------------------------------
  # conversation_list

  @doc """
  The conversations of the assistant, by day, with a button for a new one and a search. The open one is a
  card; a teal dot marks a conversation with an action waiting. Each item is a link (`navigate`, `patch` or
  `href`) or, with `on_select`, a button-like link that sends the id.

      <.conversation_list conversations={@conversas} active={@conversa.id} on_new="new" on_search="search" />

  A conversation is a map: `:id`, `:title`, `:status` (the line under the title), `:day` (the group, as
  "Hoje"), `:pending` (an action waits), `:content` (searched with the title) and the link.
  """
  attr :conversations, :list, required: true
  attr :active, :any, default: nil, doc: "The `id` of the open conversation."
  attr :search, :string, default: "", doc: "The text of the search: filters by title and content."
  attr :group_by, :atom, default: :day, values: [:day]

  attr :variant, :string,
    default: "card",
    values: ~w(card rail),
    doc: "`rail` is a full-height column with a divider."

  attr :title, :string, default: "Assistente"
  attr :shortcut, :string, default: "⌘ J", doc: "Shown on the new conversation button."
  attr :on_new, :any, default: nil, doc: "The event (or `JS`) of Nova conversa."
  attr :on_search, :any, default: nil, doc: "The `phx-change` event of the search field."

  attr :on_select, :any,
    default: nil,
    doc: "The event (or `JS`) of an item without a link; payload `%{id}`."

  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, doc: "The content of an item, in place of the title and status." do
    attr :conversation, :map
  end

  def conversation_list(assigns) do
    assigns =
      assign_derived(assigns, :groups, [:conversations, :search], fn ->
        groups(assigns.conversations, assigns.search)
      end)

    ~H"""
    <aside
      class={merge(["ai-conversations", @variant == "rail" && "rail", @class])}
      aria-label={@title}
      {@rest}
    >
      <%= if @conversations == [] do %>
        <.button class="block" phx-click={click(@on_new, nil, @target)}>
          <.icon name="huge-add-01" class="i" />Nova conversa
        </.button>
        <div class="ai-conversations-empty">
          <.icon name="huge-message-01" class="i" boxed tone="accent" />
          <b class="ink">Nenhuma conversa ainda</b>
          <span class="faint">Comece por uma sugestão ou pergunte qualquer coisa.</span>
        </div>
      <% else %>
        <div class="ai-conversations-head">
          <.icon name="huge-sparkles" class="i sm" boxed tone="accent" box_class="ai-spark" />
          <b class="ink">{@title}</b>
        </div>
        <.button class="block" phx-click={click(@on_new, nil, @target)}>
          <.icon name="huge-add-01" class="i" />Nova conversa<span class="sg-kbd">{@shortcut}</span>
        </.button>
        <form
          class="ai-conversations-search"
          phx-change={@on_search}
          phx-submit={@on_search || JS.dispatch("linea:noop")}
          phx-target={@target}
        >
          <label class="sg-input">
            <.icon name="huge-search-01" class="i" />
            <input
              type="search"
              name="search"
              value={@search}
              placeholder="Buscar conversas"
              autocomplete="off"
              phx-debounce="150"
              aria-label="Buscar conversas"
            />
          </label>
        </form>
        <nav class="ai-conversations-list">
          <%= for {day, items} <- @groups do %>
            <span :if={day} class="mono faint ai-conversations-day">{day}</span>
            <.link
              :for={c <- items}
              {link_attrs(c, @on_select, @target)}
              class={["ai-conv", c.id == @active && "on"]}
              aria-current={c.id == @active && "true"}
            >
              <span class="ai-conv-icon"><.icon name="huge-message-01" class="i sm" /></span>
              <%= if @item != [] do %>
                {render_slot(@item, c)}
              <% else %>
                <span class="ai-conv-text">
                  <span class="ai-conv-title">
                    <i :if={c[:pending]} class="ai-dot"></i>{c.title}
                  </span>
                  <span :if={c[:status]} class="faint ai-conv-status">{c.status}</span>
                </span>
              <% end %>
            </.link>
          <% end %>
        </nav>
      <% end %>
    </aside>
    """
  end

  defp groups(conversations, search) do
    needle = search |> to_string() |> String.trim() |> String.downcase()

    conversations
    |> Enum.filter(&matches?(&1, needle))
    |> Enum.chunk_by(& &1[:day])
    |> Enum.map(fn [first | _] = items -> {first[:day], items} end)
  end

  defp matches?(_conversation, ""), do: true

  defp matches?(conversation, needle) do
    [conversation[:title], conversation[:content]]
    |> Enum.any?(&(is_binary(&1) and String.contains?(String.downcase(&1), needle)))
  end

  defp link_attrs(%{navigate: to}, _on_select, _target), do: %{navigate: to}
  defp link_attrs(%{patch: to}, _on_select, _target), do: %{patch: to}
  defp link_attrs(%{href: to}, _on_select, _target), do: %{href: to}

  defp link_attrs(%{id: id}, on_select, target),
    do: %{"phx-click": click(on_select, to_string(id), target)}

  # --------------------------------------------------------------------------------------------------
  # ai_chat

  @doc """
  The whole conversation: greeting and suggestions before the first message, the messages with their proposals,
  and the field to ask. Messages are a list or a stream (see the module doc for the map).

      <.ai_chat id="assistente" messages={@messages} user={@current_user} on_send="send"
        on_approve="approve" on_reject="reject" on_pick="ask">
        <:header>
          <b class="ink">Linha sem produto no #2491</b>
          <span class="faint">iniciada em Pedidos, hoje 14:20</span>
        </:header>
        <:suggestion title="Resumo do dia">Faça um resumo do dia.</:suggestion>
      </.ai_chat>
  """
  attr :id, :string, required: true
  attr :messages, :any, default: [], doc: "A list of message maps or a stream of them."

  attr :user, :any,
    default: nil,
    doc: "The current user (a name or a map with `:name`): greeting and avatar."

  attr :streaming, :boolean,
    default: false,
    doc: "The answer is coming: the composer shows Parar."

  attr :context, :list,
    default: [],
    doc: "The initial context chips of the composer, as `ai_composer`."

  attr :variant, :string,
    default: "card",
    values: ~w(card bare page),
    doc: "`card` is framed with the header; `bare` is the content only; `page` fills a screen."

  attr :draft, :string, default: nil, doc: "The text in the composer."
  attr :greeting, :string, default: nil, doc: "Replaces the greeting line."

  attr :footnote, :string,
    default: nil,
    doc:
      "A small line under the composer (a notice about approvals, for instance). None unless given."

  attr :composer, :boolean,
    default: true,
    doc:
      "`false` leaves the composer out: a conversation shown as a record (an approved proposal)."

  attr :placeholder, :string, default: "Pergunte sobre pedidos, estoque, fiscal ou financeiro"
  attr :on_send, :any, default: nil, doc: "The `phx-submit` event of the composer."
  attr :on_change, :any, default: nil, doc: "The `phx-change` event of the composer."
  attr :on_stop, :any, default: nil
  attr :on_approve, :any, default: nil
  attr :on_reject, :any, default: nil
  attr :on_undo, :any, default: nil
  attr :on_pick, :any, default: nil, doc: "The event of a suggestion; payload `%{value, title}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :header, doc: "The title and subtitle of the conversation, in the header of the `card`."
  slot :empty, doc: "Shown above the messages in place of the greeting and suggestions."

  slot :suggestion, doc: "A starting card; the content is its text." do
    attr :title, :string, required: true
    attr :prompt, :string, doc: "What is sent when picked; the title when not given."
  end

  def ai_chat(assigns) do
    assigns =
      assign_derived(assigns, :entries, [:messages, :id], fn ->
        entries(assigns.messages, assigns.id)
      end)

    assigns =
      assigns
      |> assign_derived(:name, [:user], fn -> first_name(assigns.user) end)
      |> assign_derived(:full_name, [:user], fn -> full_name(assigns.user) end)
      |> assign_derived(:empty?, [:messages], fn -> assigns.messages == [] end)

    ~H"""
    <section
      id={@id}
      class={merge(["ai-chat", @variant, @empty? && "start", @class])}
      {@rest}
    >
      <header :if={@variant == "card"} class="ai-chat-head">
        <div class="ai-chat-title">{render_slot(@header)}</div>
        <.badge color="warning">
          <.icon name="huge-shield-01" class="i sm" />Propõe, você aprova
        </.badge>
      </header>
      <div
        id={"#{@id}-body"}
        class="ai-chat-body"
        phx-hook={@variant == "page" && "LineaUI.ScrollBottom"}
      >
        <%= if @empty != [] do %>
          {render_slot(@empty)}
        <% else %>
          <div :if={@empty?} class="ai-chat-intro">
            <.ai_greeting name={@name} greeting={@greeting} />
            <div :if={@suggestion != []} class="ai-suggestions">
              <.suggestion_card
                :for={{item, index} <- Enum.with_index(@suggestion)}
                title={item.title}
                prompt={item[:prompt] || item.title}
                tilt={tilt(index)}
                on_pick={@on_pick}
                target={@target}
              >
                {render_slot(item)}
              </.suggestion_card>
            </div>
          </div>
        <% end %>
        <div
          id={"#{@id}-messages"}
          class="ai-chat-messages"
          phx-update={!is_list(@messages) && "stream"}
        >
          <.chat_message
            :for={{dom_id, message} <- @entries}
            id={dom_id}
            message={message}
            name={@full_name}
            on_approve={@on_approve}
            on_reject={@on_reject}
            on_undo={@on_undo}
            target={@target}
          />
        </div>
      </div>
      <div :if={@composer} class="ai-chat-foot">
        <.ai_composer
          id={"#{@id}-composer"}
          value={@draft}
          context={@context}
          streaming={@streaming}
          on_stop={@on_stop}
          target={@target}
          placeholder={@placeholder}
          phx-submit={@on_send}
          phx-change={@on_change}
          phx-target={@target}
        />
        <p :if={@footnote} class="ai-chat-footnote">{@footnote}</p>
      </div>
    </section>
    """
  end

  defp entries(messages, id) when is_list(messages),
    do: Enum.map(messages, &{"#{id}-message-#{&1.id}", &1})

  defp entries(stream, _id), do: stream

  defp full_name(%{name: name}) when is_binary(name), do: name
  defp full_name(name) when is_binary(name), do: name
  defp full_name(_user), do: nil

  defp first_name(user), do: user |> full_name() |> then(&(&1 && &1 |> String.split() |> hd()))

  attr :id, :string, required: true
  attr :message, :map, required: true
  attr :name, :string, default: nil
  attr :on_approve, :any, default: nil
  attr :on_reject, :any, default: nil
  attr :on_undo, :any, default: nil
  attr :target, :any, default: nil

  defp chat_message(%{message: %{role: role}} = assigns) when role in [:user, "user"] do
    ~H"""
    <.ai_message id={@id} role="user" name={@message[:name] || @name}>{@message.text}</.ai_message>
    """
  end

  defp chat_message(assigns) do
    ~H"""
    <.ai_message
      id={@id}
      streaming={@message[:streaming] == true}
      status={@message[:status] || "ok"}
    >
      <:trace :if={@message[:trace]}>
        <.ai_tool_trace
          tools={@message.trace[:tools] || []}
          running={@message.trace[:running] == true}
          duration_ms={@message.trace[:duration_ms]}
        />
      </:trace>
      <div :if={@message[:streaming] && !@message[:text]} class="ai-pending">
        <.skeleton variant="canvas" class="h-2.5 w-[90%]" />
        <.skeleton variant="canvas" class="h-2.5 w-[70%]" />
      </div>
      <p :for={paragraph <- paragraphs(@message[:text])}>
        <.parts :for={part <- paragraph} part={part} />
      </p>
      <.ai_proposal
        :if={@message[:proposal]}
        id={@message.proposal.id}
        title={@message.proposal.title}
        status={@message.proposal[:status] || :pending}
        editable={@message.proposal[:editable] == true}
        note={@message.proposal[:note]}
        on_approve={@on_approve}
        on_reject={@on_reject}
        on_undo={@on_undo}
        target={@target}
      >
        <:change
          :for={change <- @message.proposal[:changes] || []}
          label={change.label}
          from={change[:from]}
          to={change[:to]}
        >
          {change[:text]}
        </:change>
      </.ai_proposal>
    </.ai_message>
    """
  end

  attr :part, :any, required: true
  defp parts(%{part: {true, _}} = assigns), do: ~H|<b class="ink">{elem(@part, 1)}</b>|
  defp parts(%{part: {false, _}} = assigns), do: ~H|{elem(@part, 1)}|

  # `text` as paragraphs (split on a blank line), each as `{bold?, text}` parts (`**bold**`).
  defp paragraphs(nil), do: []

  defp paragraphs(text) do
    text
    |> String.split(~r/\n{2,}/, trim: true)
    |> Enum.map(fn paragraph ->
      paragraph
      |> String.split("**")
      |> Enum.with_index()
      |> Enum.reject(fn {part, _} -> part == "" end)
      |> Enum.map(fn {part, index} -> {rem(index, 2) == 1, part} end)
    end)
  end
end
