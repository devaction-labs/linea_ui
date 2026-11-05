defmodule LineaUI.Components.ProgressParts do
  @moduledoc """
  A progress bar as two parts: a track and the fill inside it, whose width is set by the markup (`style="width: 80%"`).

      <.progress_track color="success" class="w-36">
        <.progress_fill style="width: 80%" />
      </.progress_track>

  Use `progress/1` for a bar that takes a `value` and draws the label.
  """

  use LineaUI.Component

  @colors %{
    "primary" => "[&>.progress-fill]:bg-primary",
    "success" => "[&>.progress-fill]:bg-green-500",
    "warning" => "[&>.progress-fill]:bg-yellow-500",
    "info" => "[&>.progress-fill]:bg-violet-500",
    "destructive" => "[&>.progress-fill]:bg-error",
    "mono" => "[&>.progress-fill]:bg-slate-900 dark:[&>.progress-fill]:bg-white"
  }

  @doc "The 4px track. `color` sets the color of the fill."
  attr :color, :string,
    default: "primary",
    values: ~w(primary success warning info destructive mono)

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def progress_track(assigns) do
    assigns = assign(assigns, :color_class, @colors[assigns.color])

    ~H"""
    <div
      class={
        merge([
          "relative h-1 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-navy-600",
          @color_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The fill of a `progress_track/1`; give it the width in `style`."
  attr :class, :any, default: nil
  attr :rest, :global

  def progress_fill(assigns) do
    ~H"""
    <div
      class={merge(["progress-fill h-full flex-1 rounded-full bg-primary transition-all", @class])}
      {@rest}
    >
    </div>
    """
  end
end
