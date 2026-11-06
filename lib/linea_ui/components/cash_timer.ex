defmodule LineaUI.Components.CashTimer do
  @moduledoc """
  The canvas status card of a cash register shift: an icon in the color of the state, a title and
  a line under it, and at the right the time the register has been open (ticking in the browser),
  a difference, or an action.

      <.cash_timer id="register-2" state="open" title="Caixa 2 aberto" subtitle="desde 08:00 · Marina"
        elapsed={24_130} amount="R$ 6.412,30" />

      <.cash_timer id="register-2" state="closed" title="Caixa 2 fechado" subtitle="ontem às 18:04 · Rafael">
        <:action><.button size="sm" color="mono">Abrir caixa</.button></:action>
      </.cash_timer>

      <.cash_timer id="check-2" state="alert" title="Conferência do caixa 2" subtitle="08:00 às 18:00"
        difference="− R$ 12,50">
        <:stat label="Esperado">R$ 6.412,30</:stat>
        <:stat label="Contado">R$ 6.399,80</:stat>
      </.cash_timer>

  `state` colors the icon: `open` green, `closed` neutral, `alert` amber (the `difference` takes
  the same amber). `elapsed` (seconds) shows the clock, which counts up in the browser with the
  `LineaUI.Timer` hook while `running`; a new `elapsed` from the server resets it. `:stat` slots
  add a row of figures under the card's head.
  """

  use LineaUI.Component

  @tones %{"open" => "pos", "closed" => nil, "alert" => "warn"}

  attr(:id, :string, required: true)
  attr(:state, :string, default: "open", values: ~w(open closed alert))
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)

  attr(:elapsed, :integer,
    default: nil,
    doc: "Seconds the register has been open: shows the clock."
  )

  attr(:running, :boolean, default: true, doc: "Whether the clock counts.")
  attr(:amount, :string, default: nil, doc: "The balance under the clock.")

  attr(:difference, :string,
    default: nil,
    doc: "A difference at the right, in the `alert` color."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:action, doc: "A button at the right.")

  slot :stat, doc: "A figure in the row under the head." do
    attr(:label, :string, required: true)
  end

  def cash_timer(assigns) do
    assigns = assign(assigns, :tone, @tones[assigns.state])

    ~H"""
    <div
      id={@id}
      class={merge(["sg-card linea-cash", @stat != [] && "has-stats", @class])}
      data-state={@state}
      phx-hook={@elapsed && "LineaUI.Timer"}
      data-elapsed={@elapsed}
      data-running={@elapsed && bool(@running and @state == "open")}
      data-total={@elapsed && 86_400}
      data-direction={@elapsed && "up"}
      data-format={@elapsed && "hms"}
      {@rest}
    >
      <div class="linea-cash-head">
        <span class={["sg-ic", @tone]} aria-hidden="true">
          <svg class="linea-cash-icon" viewBox="0 0 24 24">
            <path d="M3 7h18v10H3zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6 10v4M18 10v4" />
          </svg>
        </span>
        <div class="linea-cash-text">
          <b class="linea-cash-title">{@title}</b>
          <span :if={@subtitle} class="linea-cash-sub">{@subtitle}</span>
        </div>
        <div :if={@elapsed} class="linea-cash-clock">
          <b class="linea-cash-time" data-time role="timer">{clock(@elapsed)}</b>
          <span :if={@amount} class="linea-cash-amount">{@amount}</span>
        </div>
        <b :if={@difference} class="linea-cash-diff">{@difference}</b>
        {render_slot(@action)}
      </div>
      <dl :if={@stat != []} class="linea-cash-stats">
        <div :for={stat <- @stat} class="sg-stat">
          <dt class="l">{stat.label}</dt>
          <dd class="v">{render_slot(stat)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  defp clock(seconds) do
    seconds = max(seconds, 0)
    pad = &String.pad_leading(Integer.to_string(&1), 2, "0")
    "#{pad.(div(seconds, 3600))}:#{pad.(div(rem(seconds, 3600), 60))}:#{pad.(rem(seconds, 60))}"
  end
end
