defmodule LineaUI.Components.Skeleton do
  @moduledoc """
  LineOne's skeleton: placeholder blocks shown while the content loads, with a light wave
  passing over them or a pulse.

      <.skeleton class="size-16" shape="circle" />
      <.skeleton class="h-3 w-full" />
      <.skeleton class="h-48 w-full" shape="square" />

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

  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded pill circle square lg),
    doc: "`rounded` is LineOne's small radius, `lg` the large one, `square` none."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def skeleton(assigns) do
    ~H"""
    <div
      aria-hidden="true"
      class={merge([animation(@animation), "bg-slate-150 dark:bg-navy-500", shape(@shape), @class])}
      {@rest}
    >
    </div>
    """
  end

  defp animation(animation), do: @animations[animation]
  defp shape(shape), do: @shapes[shape]
end
