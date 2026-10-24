defmodule LineaUI.Components.Toast do
  @moduledoc """
  LineOne's notifications: a small colored note at a corner or an edge of the screen that leaves by
  itself after a few seconds.

  Mount the toaster once, in the layout every LiveView renders (it reads the flash):

      <.toaster flash={@flash} />

  Then, from the server:

      conn |> put_toast("Saved", color: "success") |> redirect(to: ~p"/orders")
      socket |> put_toast("Saved", color: "success") |> push_navigate(to: ~p"/orders")
      socket |> send_toast("Copied", color: "info", position: "center-top")

  `put_toast/3` goes through the flash, so it survives a redirect; `send_toast/3` pushes the toast to
  the page at once. From the browser, without a round trip:

      <.button phx-click={show_toast("This is a simple notification", color: "primary")}>Primary</.button>

  Options: `color` (`neutral primary secondary info success warning error light dark`), `position`
  (`left-top left-bottom center-top center-bottom right-top right-bottom`), `duration` in
  milliseconds (`0` keeps it until closed), `close` (a close button) and `template`, the id of a
  `<template>` on the page whose first element is shown instead of the message (an element with
  `data-toast-dismiss` inside it closes the toast).

  The toasts of a corner are stacked: the newest is shown in full and the older ones sit behind it,
  smaller, as slivers (three at most). With the pointer over the stack it opens, every toast in its own
  size, and their timers wait; when the pointer leaves they go on with the time they had left. Set
  `stack={false}` on the toaster to keep them always open, one above the other.
  """

  use LineaUI.Component

  @flash_key "linea_toast"
  @colors ~w(neutral primary secondary info success warning error light dark)
  @positions ~w(left-top left-bottom center-top center-bottom right-top right-bottom)

  @doc "The colors a toast takes."
  @spec toast_colors() :: [String.t()]
  def toast_colors, do: @colors

  @doc "The positions a toast takes."
  @spec toast_positions() :: [String.t()]
  def toast_positions, do: @positions

  @doc """
  The place the toasts are drawn. Mount it once per page, inside the LiveView (the layout that
  receives `@flash`).
  """
  attr :id, :string, default: "linea-toaster"
  attr :flash, :map, default: %{}, doc: "The `@flash`, where `put_toast/3` leaves its toasts."

  attr :position, :string,
    default: "right-bottom",
    values: @positions,
    doc: "The default position."

  attr :duration, :integer, default: 5000, doc: "The default duration, in milliseconds."

  attr :stack, :boolean,
    default: true,
    doc: "Pile the toasts of a corner behind the newest and open the pile under the pointer."

  attr :close_label, :string, default: "Close"
  attr :rest, :global

  def toaster(assigns) do
    assigns = assign(assigns, :toasts, flash_toasts(assigns.flash))

    ~H"""
    <div
      id={@id}
      class="contents"
      phx-hook="LineaUI.Toast"
      phx-update="ignore"
      aria-live="polite"
      data-linea-toaster
      data-flash={Jason.encode!(@toasts)}
      data-position={@position}
      data-duration={@duration}
      data-stack={to_string(@stack)}
      data-close-label={@close_label}
      {@rest}
    >
    </div>
    """
  end

  @doc """
  Leaves a toast in the flash of a `Plug.Conn` (after `fetch_flash`) or a LiveView socket. The
  toaster shows it on the next page, so it survives `redirect/2`, `push_navigate/2` and
  `push_patch/2`. Several calls pile up.
  """
  @spec put_toast(Plug.Conn.t() | Phoenix.LiveView.Socket.t(), String.t(), keyword()) ::
          Plug.Conn.t() | Phoenix.LiveView.Socket.t()
  def put_toast(conn_or_socket, message, opts \\ [])

  def put_toast(%Plug.Conn{} = conn, message, opts) do
    toasts = flash_toasts(conn.assigns.flash) ++ [payload(message, opts)]
    Phoenix.Controller.put_flash(conn, @flash_key, toasts)
  end

  def put_toast(%Phoenix.LiveView.Socket{} = socket, message, opts) do
    toasts = flash_toasts(socket.assigns.flash) ++ [payload(message, opts)]
    Phoenix.LiveView.put_flash(socket, @flash_key, toasts)
  end

  @doc """
  Shows a toast now, from `handle_event/3` or `handle_info/2`: it is pushed to the page as the
  `linea:toast` event, which the toaster's hook handles.
  """
  @spec send_toast(Phoenix.LiveView.Socket.t(), String.t(), keyword()) ::
          Phoenix.LiveView.Socket.t()
  def send_toast(%Phoenix.LiveView.Socket{} = socket, message, opts \\ []) do
    Phoenix.LiveView.push_event(socket, "linea:toast", payload(message, opts))
  end

  @doc """
  A `%JS{}` that shows a toast in the browser, without a round trip. Takes the same options as
  `put_toast/3`.
  """
  @spec show_toast(String.t() | nil) :: JS.t()
  @spec show_toast(JS.t() | String.t() | nil, String.t() | keyword() | nil) :: JS.t()
  @spec show_toast(JS.t(), String.t() | nil, keyword()) :: JS.t()
  def show_toast(message), do: show_toast(%JS{}, message, [])

  def show_toast(%JS{} = js, message), do: show_toast(js, message, [])
  def show_toast(message, opts) when is_list(opts), do: show_toast(%JS{}, message, opts)

  def show_toast(%JS{} = js, message, opts) do
    JS.dispatch(js, "linea:toast", to: "[data-linea-toaster]", detail: payload(message, opts))
  end

  @doc false
  @spec payload(String.t() | nil, keyword()) :: map()
  def payload(message, opts) do
    color = Keyword.get(opts, :color, "neutral")
    position = Keyword.get(opts, :position)

    %{
      "id" => Keyword.get_lazy(opts, :id, fn -> gen_id("toast") end),
      "message" => message,
      "color" => check!(color, @colors, :color),
      "position" => position && check!(position, @positions, :position),
      "duration" => Keyword.get(opts, :duration),
      "close" => Keyword.get(opts, :close, false),
      "template" => Keyword.get(opts, :template)
    }
  end

  defp check!(value, allowed, key) do
    case value in allowed do
      true ->
        value

      false ->
        raise ArgumentError,
              "invalid toast #{key} #{inspect(value)}, expected one of #{inspect(allowed)}"
    end
  end

  defp flash_toasts(flash) do
    case Phoenix.Flash.get(flash, @flash_key) do
      toasts when is_list(toasts) -> toasts
      _none -> []
    end
  end
end
