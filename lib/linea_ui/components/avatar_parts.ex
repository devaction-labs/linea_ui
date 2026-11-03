defmodule LineaUI.Components.AvatarParts do
  @moduledoc """
  Metronic's avatar as parts: a frame that sets the size, a round picture, an optional corner indicator with a status dot.

      <.avatar_frame class="size-9">
        <.avatar_picture><img src="/me.png" alt="Me" /></.avatar_picture>
        <.avatar_indicator class="-end-2 -bottom-2">
          <.avatar_status status="online" class="size-2.5" />
        </.avatar_indicator>
      </.avatar_frame>

  Use `avatar/1` for an avatar that takes a `src`, initials, a ring and a status as attributes.
  """

  use LineaUI.Component

  @doc "The box of the avatar, 40px unless `class` sets another `size-*`."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_frame(assigns) do
    ~H"""
    <div class={merge(["relative flex size-10 shrink-0", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The round picture; its `img` is square and fills the frame."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_picture(assigns) do
    ~H"""
    <div
      class={merge(["overflow-hidden rounded-full [&_img]:aspect-square [&_img]:size-full", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Shown in place of the picture, usually initials."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_fallback(assigns) do
    ~H"""
    <div
      class={
        merge([
          "flex size-full items-center justify-center rounded-full border border-slate-200 bg-slate-100 text-[13px] dark:border-navy-450 dark:bg-navy-600",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A 24px box pinned to a corner of the frame (place it with `-end-2 -bottom-2` and the like)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_indicator(assigns) do
    ~H"""
    <div class={merge(["absolute flex size-6 items-center justify-center", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @status %{
    "online" => "bg-green-600",
    "offline" => "bg-slate-900/50 dark:bg-white/50",
    "busy" => "bg-yellow-600",
    "away" => "bg-blue-600"
  }

  @doc "The dot of the indicator: `online`, `offline`, `busy` or `away`."
  attr :status, :string, default: "online", values: ~w(online offline busy away)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def avatar_status(assigns) do
    assigns = assign(assigns, :color, @status[assigns.status])

    ~H"""
    <div
      class={
        merge([
          "flex size-2 items-center rounded-full border-2 border-white dark:border-navy-900",
          @color,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
