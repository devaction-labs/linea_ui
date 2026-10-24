defmodule LineaUI.Timer do
  @moduledoc """
  Commands for a `LineaUI.Components.Timer.timer/1`, by its `id`, in the same three shapes as `LineaUI.open/1`.

  | Call | Returns | Use in |
  |---|---|---|
  | `LineaUI.Timer.pause("id")` | `%JS{}` | `phx-click` |
  | `LineaUI.Timer.pause(socket, "id")` | socket | `handle_event/3`, `handle_info/2` |
  | `LineaUI.Timer.pause(%JS{}, "id")` | `%JS{}` | a JS pipeline |

  The same holds for `resume`, `toggle` and `add`. In the browser they run without a round trip, and `pause`,
  `resume` and `toggle` push the timer's `on_toggle`. `"id"` and `"#id"` are both accepted.

      <.button phx-click={LineaUI.Timer.toggle("shift")}>Pause</.button>
      <.button phx-click={LineaUI.Timer.add("shift", 900)}>+15 min</.button>
  """

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  @doc "Pauses the timer with `id`; nothing when it is paused."
  @spec pause(String.t()) :: JS.t()
  @spec pause(Socket.t() | JS.t(), String.t()) :: Socket.t() | JS.t()
  def pause(id), do: pause(%JS{}, id)
  def pause(target, id), do: command(target, id, %{action: "pause"})

  @doc "Resumes the timer with `id`; nothing when it runs."
  @spec resume(String.t()) :: JS.t()
  @spec resume(Socket.t() | JS.t(), String.t()) :: Socket.t() | JS.t()
  def resume(id), do: resume(%JS{}, id)
  def resume(target, id), do: command(target, id, %{action: "resume"})

  @doc "Pauses the timer with `id` when it runs and resumes it when it is paused."
  @spec toggle(String.t()) :: JS.t()
  @spec toggle(Socket.t() | JS.t(), String.t()) :: Socket.t() | JS.t()
  def toggle(id), do: toggle(%JS{}, id)
  def toggle(target, id), do: command(target, id, %{action: "toggle"})

  @doc "Adds `seconds` to the time elapsed of the timer with `id`; a negative number takes time away, down to zero."
  @spec add(String.t(), integer()) :: JS.t()
  @spec add(Socket.t() | JS.t(), String.t(), integer()) :: Socket.t() | JS.t()
  def add(id, seconds), do: add(%JS{}, id, seconds)
  def add(target, id, seconds), do: command(target, id, %{action: "add", seconds: seconds})

  defp command(%JS{} = js, id, detail),
    do: JS.dispatch(js, "linea:timer", to: LineaUI.selector(id), detail: detail)

  defp command(%Socket{} = socket, id, detail),
    do:
      Phoenix.LiveView.push_event(
        socket,
        "linea:timer",
        Map.put(detail, :id, LineaUI.selector(id))
      )
end
