defmodule LineaUI.Components.Tool do
  @moduledoc """
  A tool call an agent makes (running a command, reading a file), from input to output, as a line of a
  `trace/1`: a plain line while it runs, a step that opens on its output once it has one, red when it fails.
  A call that waits for the user is a `tool_approval/1` card with Deny and Approve. It is the canvas's `Tool`,
  in the spirit of the shadcn/ui AI Elements Tool, built on `trace/1` and `code_block/1`.

      <.trace>
        <.tool id="t1" state="running" subject="pnpm install" />
        <.tool id="t2" state="done" subject="node --version" output="v24.18.0" />
        <.tool id="t3" state="error" subject="pnpm lint" output={@stderr} />
      </.trace>

  ## States

  `state` is where the call stands; it picks the status of the line and the verb before `subject`:

  | `state`   | line                | title (en / pt_BR)             |
  |-----------|---------------------|--------------------------------|
  | `running` | `running` (shimmer) | Running … / Rodando …          |
  | `waiting` | `pending` (faded)   | Waiting to run … / Aguardando … |
  | `done`    | plain               | Ran … / Rodou …                |
  | `error`   | `error` (red)       | Failed to run … / Falhou ao rodar … |
  | `denied`  | plain               | Denied … / Negado …            |

  `verbs` overrides them per state (`verbs={%{done: "Read", running: "Reading"}}` for a file tool) and `title`
  replaces the whole title. `subject` is drawn as code. Map an AI SDK part with its state: `input-streaming`
  and `input-available` are `running` while the chat streams (`error` once it stopped, or `waiting` for a tool
  that runs on the client), `output-available` is `done`, `output-error` is `error` and `output-denied` is
  `denied`.

  ## Output

  With `output` (or `input`, shown above it) the line opens on a small `code_block/1` that wraps and caps at
  256px; `open` starts it open. `description` sits after the title (a duration, say).

  ## Approval

      <.tool_approval id="a1" subject="rm -rf tmp" input={@args} on_approve="approve" on_deny="deny" value={@call_id} />

  The card asks "Run `rm -rf tmp`?" (`title` replaces it), shows the input, and its buttons send `on_approve`
  and `on_deny` with `%{"value" => value}`.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [icon: 1]

  alias LineaUI.Components.{Button, CodeBlock, Trace}

  @verbs %{
    "en" => %{running: "Running", waiting: "Waiting to run", done: "Ran", error: "Failed to run", denied: "Denied"},
    "pt_BR" => %{running: "Rodando", waiting: "Aguardando para rodar", done: "Rodou", error: "Falhou ao rodar", denied: "Negado"}
  }

  @approval %{
    "en" => %{ask: "Run", approve: "Approve", deny: "Deny"},
    "pt_BR" => %{ask: "Rodar", approve: "Aprovar", deny: "Negar"}
  }

  @status %{"running" => "running", "waiting" => "pending", "error" => "error"}

  @doc "One tool call, as a line of a `trace/1`."
  attr :id, :string, required: true, doc: "Names the output block."
  attr :state, :string, default: "done", values: ~w(running waiting done error denied)
  attr :subject, :string, default: nil, doc: "What the tool acted on (a command, a file), drawn as code."
  attr :title, :string, default: nil, doc: "The whole title, in place of verb and subject."
  attr :verbs, :map, default: %{}, doc: "Verbs per state (atom keys), over the `locale` ones."
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :icon, :string, default: "huge-command-line"
  attr :description, :any, default: nil
  attr :input, :string, default: nil, doc: "The call's input, shown above the output."
  attr :output, :string, default: nil, doc: "What the tool returned, or its error text."
  attr :open, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  def tool(assigns) do
    verbs = Map.merge(@verbs[assigns.locale], assigns.verbs)

    assigns =
      assigns
      |> assign(:verb, Map.fetch!(verbs, String.to_existing_atom(assigns.state)))
      |> assign(:status, @status[assigns.state])

    ~H"""
    <Trace.trace_step
      :if={@output || @input}
      icon={@icon}
      status={@status}
      description={@description}
      open={@open}
      class={merge(["linea-tool", @class])}
      data-state={@state}
      {@rest}
    >
      <:summary><.tool_title title={@title} verb={@verb} subject={@subject} /></:summary>
      <div class="linea-tool-io">
        <CodeBlock.code_block :if={@input} id={"#{@id}-input"} code={@input} size="sm" wrap max_height={256} />
        <CodeBlock.code_block
          :if={@output}
          id={"#{@id}-output"}
          code={@output}
          size="sm"
          wrap
          max_height={256}
          variant={if(@state == "error", do: "destructive", else: "default")}
        />
      </div>
    </Trace.trace_step>
    <Trace.trace_line
      :if={!@output && !@input}
      icon={@icon}
      status={@status}
      description={@description}
      class={merge(["linea-tool", @class])}
      data-state={@state}
      {@rest}
    >
      <.tool_title title={@title} verb={@verb} subject={@subject} />
    </Trace.trace_line>
    """
  end

  attr :title, :string, default: nil
  attr :verb, :string, required: true
  attr :subject, :string, default: nil

  defp tool_title(%{title: nil} = assigns) do
    ~H"{@verb} <code :if={@subject}>{@subject}</code>"
  end

  defp tool_title(assigns), do: ~H"{@title}"

  @doc """
  A tool call that waits for the user: the question, the input and Deny / Approve.

  Events: `on_approve` and `on_deny` receive `%{"value" => value}`.
  """
  attr :id, :string, required: true
  attr :subject, :string, default: nil, doc: "What would run, drawn as code in the question."
  attr :title, :string, default: nil, doc: "The question, in place of \"Run `subject`?\"."
  attr :description, :string, default: nil, doc: "A line under the question."
  attr :input, :string, default: nil, doc: "The call's input, in a small code block."
  attr :icon, :string, default: "huge-command-line"
  attr :value, :any, default: nil, doc: "Sent with both events."
  attr :on_approve, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_deny, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil
  attr :approve_label, :string, default: nil
  attr :deny_label, :string, default: nil
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :class, :any, default: nil
  attr :rest, :global

  def tool_approval(assigns) do
    assigns = assign(assigns, :t, @approval[assigns.locale])

    ~H"""
    <div id={@id} class={merge(["linea-tool-ask", @class])} role="group" aria-labelledby={"#{@id}-q"} {@rest}>
      <span class="linea-tool-ask-icon"><.icon name={@icon} class="size-4" /></span>
      <div class="linea-tool-ask-body">
        <p id={"#{@id}-q"} class="linea-tool-ask-q">
          <%= if @title do %>{@title}<% else %>{@t.ask} <code :if={@subject}>{@subject}</code>?<% end %>
        </p>
        <p :if={@description} class="linea-tool-ask-d">{@description}</p>
        <CodeBlock.code_block :if={@input} id={"#{@id}-input"} code={@input} size="sm" wrap max_height={160} />
      </div>
      <div class="linea-tool-ask-actions">
        <Button.button
          type="button"
          variant="outline"
          size="sm"
          phx-click={@on_deny}
          phx-value-value={@value}
          phx-target={@target}
        >
          {@deny_label || @t.deny}
        </Button.button>
        <Button.button
          type="button"
          color="mono"
          size="sm"
          phx-click={@on_approve}
          phx-value-value={@value}
          phx-target={@target}
        >
          {@approve_label || @t.approve}
        </Button.button>
      </div>
    </div>
    """
  end
end
