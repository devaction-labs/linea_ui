defmodule LineaUI.Components.Skeleton do
  @moduledoc """
  LineOne's skeleton: placeholder blocks shown while the content loads, with a light wave
  passing over them or a pulse.

      <.skeleton class="size-16" shape="circle" />
      <.skeleton class="h-3 w-full" />
      <.skeleton class="h-48 w-full" shape="square" />

  The wave and the pulse stop for people who prefer reduced motion.

  The blocks are `aria-hidden`; wrap a whole placeholder in `skeleton_group/1` so a screen
  reader hears that something is loading:

      <.skeleton_group label="Loading orders">
        <.skeleton class="h-3 w-full" />
        <.skeleton class="h-3 w-8/12" />
      </.skeleton_group>

  `variant="canvas"` (the default; `variant="lineone"` is the old slate block) draws the design canvas's `sg-skel` (the warm gray gradient of the Signetum
  screens, 8px corners); `shape` still rounds it (`circle` for an avatar):

      <.skeleton variant="canvas" shape="circle" class="size-8" />
      <.skeleton variant="canvas" class="h-2.5 w-1/2" />

  For the pulse, put `animation="none"` blocks inside an element with `animate-pulse` (as
  LineOne does), or give a single block `animation="pulse"`.
  """

  use LineaUI.Component

  @animations %{
    "wave" => "skeleton animate-wave",
    "pulse" => "animate-pulse",
    "none" => ""
  }

  @shapes %{
    "rounded" => "rounded-sm",
    "pill" => "rounded-full",
    "circle" => "rounded-full",
    "square" => "",
    "lg" => "rounded-lg"
  }

  @doc """
  Renders a placeholder block; its size comes from `class`.

      <.skeleton shape="circle" class="size-16" />
      <.skeleton class="h-3 w-8/12" />
  """
  attr(:animation, :string, default: "wave", values: ~w(wave pulse none))

  attr(:variant, :string,
    default: "canvas",
    values: ~w(canvas lineone),
    doc:
      "`canvas` (the default) is the canvas's `sg-skel`; `lineone` is the old LineOne slate block."
  )

  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded pill circle square lg),
    doc: "`rounded` is LineOne's small radius, `lg` the large one, `square` none."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def skeleton(%{variant: "canvas"} = assigns) do
    ~H"""
    <div
      aria-hidden="true"
      class={merge(["sg-skel", animation(@animation), @shape, @class])}
      {@rest}
    >
    </div>
    """
  end

  def skeleton(assigns) do
    ~H"""
    <div
      aria-hidden="true"
      class={
        merge([
          animation(@animation),
          "bg-slate-150 bg-[linear-gradient(90deg,var(--color-slate-150),var(--color-slate-100),var(--color-slate-150))] dark:bg-navy-500 dark:bg-none",
          shape(@shape),
          @class
        ])
      }
      {@rest}
    >
    </div>
    """
  end

  @doc """
  Wraps the skeleton blocks of one placeholder: `role="status"` and `aria-busy="true"` with
  a screen-reader-only `label`.

      <.skeleton_group label="Loading orders" class="space-y-2">
        <.skeleton class="h-3 w-full" />
      </.skeleton_group>
  """
  attr(:label, :string, default: "Loading…", doc: "Read by screen readers; not drawn.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def skeleton_group(assigns) do
    ~H"""
    <div role="status" aria-busy="true" class={@class} {@rest}>
      <span class="sr-only">{@label}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp animation(animation), do: @animations[animation]
  defp shape(shape), do: @shapes[shape]
end
