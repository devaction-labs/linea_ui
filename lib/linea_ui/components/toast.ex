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
  milliseconds (`0` or `:infinity` keeps it until closed), `close` (a close button) and `template`,
  the id of a `<template>` on the page whose first element is shown instead of the message (an
  element with `data-toast-dismiss` inside it closes the toast; this is the way to put buttons of
  your own in a toast).

  ## Kinds, descriptions and actions

  `kind` (`neutral info success warning error loading`) draws the toast with an icon and a title,
  in the color of the kind unless `color` says otherwise; `description` adds a second line and
  `actions` a row of buttons:

      send_toast(socket, "Invoice sent",
        kind: :success,
        description: "NF-e 1234 was authorized.",
        actions: [
          [label: "Open", event: "open-invoice", value: %{id: 1234}],
          [label: "Undo", js: JS.push("undo")],
          [label: "See all", href: "/invoices"]
        ]
      )

  An action takes `label` and one of `event` (pushed to the LiveView with `value` merged with
  `%{"toast_id" => id}`, to `target` when given), `js` (a `%JS{}` run in the browser) or `href`
  (a link). It closes the toast unless `dismiss: false`; `[label: "Close", dismiss: true]` alone
  only closes it.

  ## Loading, then the answer

  A toast with a fixed `id` is updated in place when another one comes with the same `id`:

      socket = send_toast(socket, "Sending the invoice…", id: "nfe-42", kind: :loading)
      # later, in handle_info/2
      send_toast(socket, "Invoice authorized", id: "nfe-42", kind: :success)

  A `loading` toast never leaves by itself and has no close button; once it becomes another kind it
  takes its duration again. `update_toast/3` changes only the options it is given, keeping the rest
  (`update_toast(socket, "nfe-42", description: "Waiting for SEFAZ…")`); `dismiss_toast/2` and
  `clear_toasts/1` remove toasts. `send_toast/2` also takes the message as `title:`
  (`send_toast(socket, id: "x", kind: :loading, title: "Working…")`). Errors stay until closed when
  the toaster has `persist_errors`.

  The toasts of a corner are stacked: the newest is shown in full and the older ones sit behind it,
  smaller, as slivers (three at most). With the pointer over the stack it opens, every toast in its own
  size, and their timers wait; when the pointer leaves they go on with the time they had left. Set
  `stack={false}` on the toaster to keep them always open, one above the other.

  The toasts sit on the CSS layer `--linea-z-toast` (see the README).
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [icon_set: 0, glyph: 1]
  import LineaUI.Components.Spinner, only: [spinner: 1]

  @flash_key "linea_toast"
  @colors ~w(neutral primary secondary info success warning error light dark)
  @positions ~w(left-top left-bottom center-top center-bottom right-top right-bottom)
  @kinds ~w(neutral info success warning error loading)
  @kind_colors %{
    "neutral" => "neutral",
    "info" => "info",
    "success" => "success",
    "warning" => "warning",
    "error" => "error",
    "loading" => "neutral"
  }
  @kind_icons %{
    "info" => :info_circle,
    "success" => :check_circle,
    "warning" => :warning,
    "error" => :error_circle
  }

  @doc "The colors a toast takes."
  @spec toast_colors() :: [String.t()]
  def toast_colors, do: @colors

  @doc "The positions a toast takes."
  @spec toast_positions() :: [String.t()]
  def toast_positions, do: @positions

  @doc "The kinds a toast takes."
  @spec toast_kinds() :: [String.t()]
  def toast_kinds, do: @kinds

  @doc """
  The place the toasts are drawn. Mount it once per page, inside the LiveView (the layout that
  receives `@flash`).

  Events: an action with `event` pushes it with its `value` and `%{"toast_id" => id}`.
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

  attr :persist_errors, :boolean,
    default: false,
    doc: "Toasts of `kind: :error` without a `duration` stay until closed."

  attr :close_label, :string, default: "Close"
  attr :loading_label, :string, default: "Loading"
  attr :rest, :global

  def toaster(assigns) do
    assigns =
      assigns
      |> assign(:toasts, flash_toasts(assigns.flash))
      |> assign(:icons, @kind_icons)

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
      data-persist-errors={bool(@persist_errors)}
      data-close-label={@close_label}
      data-icons={icon_set()}
      {@rest}
    >
      <template :for={{kind, name} <- @icons} data-toast-icon={kind}>
        <.glyph name={name} class="size-5" />
      </template>
      <template data-toast-icon="loading">
        <.spinner color="current" size="xs" label={@loading_label} class="size-4.5" />
      </template>
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
  `linea:toast` event, which the toaster's hook handles. A toast with the `id` of one on the
  screen replaces it in place. The message can also go in the options, as `title:`.
  """
  @spec send_toast(Phoenix.LiveView.Socket.t(), String.t() | keyword()) ::
          Phoenix.LiveView.Socket.t()
  @spec send_toast(Phoenix.LiveView.Socket.t(), String.t() | nil, keyword()) ::
          Phoenix.LiveView.Socket.t()
  def send_toast(socket, message_or_opts)

  def send_toast(%Phoenix.LiveView.Socket{} = socket, opts) when is_list(opts),
    do: send_toast(socket, Keyword.get(opts, :title), opts)

  def send_toast(%Phoenix.LiveView.Socket{} = socket, message),
    do: send_toast(socket, message, [])

  def send_toast(%Phoenix.LiveView.Socket{} = socket, message, opts) do
    Phoenix.LiveView.push_event(socket, "linea:toast", payload(message, opts))
  end

  @doc """
  Changes the toast `id` in place, from the server: only the options given change (`title`,
  `description`, `kind`, `color`, `duration`, `close`, `actions`), the rest stay. Nothing
  happens when no toast has that `id`.
  """
  @spec update_toast(Phoenix.LiveView.Socket.t(), String.t(), keyword()) ::
          Phoenix.LiveView.Socket.t()
  def update_toast(%Phoenix.LiveView.Socket{} = socket, id, opts) do
    Phoenix.LiveView.push_event(socket, "linea:toast-update", changes(id, opts))
  end

  @doc """
  Removes the toast `id`: from the server with a socket, in the browser as a `%JS{}`
  (`phx-click={dismiss_toast("nfe-42")}`).
  """
  @spec dismiss_toast(String.t()) :: JS.t()
  @spec dismiss_toast(Phoenix.LiveView.Socket.t() | JS.t(), String.t()) ::
          Phoenix.LiveView.Socket.t() | JS.t()
  def dismiss_toast(id), do: dismiss_toast(%JS{}, id)

  def dismiss_toast(%Phoenix.LiveView.Socket{} = socket, id),
    do: Phoenix.LiveView.push_event(socket, "linea:toast-dismiss", %{"id" => id})

  def dismiss_toast(%JS{} = js, id),
    do: JS.dispatch(js, "linea:toast-dismiss", to: "[data-linea-toaster]", detail: %{"id" => id})

  @doc "Removes every toast: from the server with a socket, in the browser as a `%JS{}`."
  @spec clear_toasts() :: JS.t()
  @spec clear_toasts(Phoenix.LiveView.Socket.t() | JS.t()) :: Phoenix.LiveView.Socket.t() | JS.t()
  def clear_toasts, do: clear_toasts(%JS{})

  def clear_toasts(%Phoenix.LiveView.Socket{} = socket),
    do: Phoenix.LiveView.push_event(socket, "linea:toast-dismiss", %{"all" => true})

  def clear_toasts(%JS{} = js),
    do:
      JS.dispatch(js, "linea:toast-dismiss", to: "[data-linea-toaster]", detail: %{"all" => true})

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
    kind = opts |> Keyword.get(:kind) |> kind!()
    color = Keyword.get_lazy(opts, :color, fn -> kind_color(kind) end)
    position = Keyword.get(opts, :position)

    %{
      "id" => Keyword.get_lazy(opts, :id, fn -> gen_id("toast") end),
      "message" => message || Keyword.get(opts, :title),
      "description" => Keyword.get(opts, :description),
      "kind" => kind,
      "color" => check!(to_string(color), @colors, :color),
      "position" => position && check!(position, @positions, :position),
      "duration" => opts |> Keyword.get(:duration) |> duration(),
      "close" => Keyword.get(opts, :close, false),
      "template" => Keyword.get(opts, :template),
      "actions" => opts |> Keyword.get(:actions, []) |> Enum.map(&action!/1)
    }
  end

  @doc false
  @spec changes(String.t(), keyword()) :: map()
  def changes(id, opts) do
    opts
    |> Enum.map(&change/1)
    |> Map.new()
    |> Map.put("id", id)
  end

  defp change({:title, value}), do: {"message", value}
  defp change({:message, value}), do: {"message", value}
  defp change({:description, value}), do: {"description", value}
  defp change({:kind, value}), do: {"kind", kind!(value)}
  defp change({:color, value}), do: {"color", check!(to_string(value), @colors, :color)}
  defp change({:duration, value}), do: {"duration", duration(value)}
  defp change({:close, value}), do: {"close", value}
  defp change({:actions, value}), do: {"actions", Enum.map(value, &action!/1)}

  defp change({key, _value}),
    do: raise(ArgumentError, "update_toast/3 does not change #{inspect(key)}")

  defp kind!(nil), do: nil
  defp kind!(kind), do: check!(to_string(kind), @kinds, :kind)

  defp kind_color(nil), do: "neutral"
  defp kind_color(kind), do: Map.fetch!(@kind_colors, kind)

  defp duration(:infinity), do: 0
  defp duration(duration), do: duration

  defp action!(action) when is_list(action), do: action |> Map.new() |> action!()

  defp action!(%{label: label} = action) do
    %{
      "label" => label,
      "event" => Map.get(action, :event),
      "value" => Map.get(action, :value, %{}),
      "target" => Map.get(action, :target),
      "js" => Map.get(action, :js),
      "href" => Map.get(action, :href),
      "dismiss" => Map.get(action, :dismiss, true)
    }
  end

  defp action!(action),
    do: raise(ArgumentError, "a toast action needs a :label, got #{inspect(action)}")

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
