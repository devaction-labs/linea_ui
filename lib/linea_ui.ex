defmodule LineaUI do
  @moduledoc """
  Phoenix LiveView components with the LineOne design.

      use LineaUI

  imports every component. Pick or drop some with `:only` and `:except`, which take the
  keys of `components/0`:

      use LineaUI, only: [:button, :modal]
      use LineaUI, except: [:table]

  `avoid_conflicts: true` drops the names Phoenix's generated `CoreComponents` and `Layouts` also define
  (`button`, `input`, `table`, `label`, `error`, `header`, `icon` and `theme_toggle`).

  ## Overlays

  A modal, drawer, popover, dropdown or tooltip is opened, closed and toggled by its `id`,
  in three shapes:

  | Call | Returns | Use in |
  |---|---|---|
  | `LineaUI.open("id")` | `%JS{}` | `phx-click` |
  | `LineaUI.open(socket, "id")` | socket | `handle_event/3`, `handle_info/2` |
  | `LineaUI.open(%JS{}, "id")` | `%JS{}` | a JS pipeline |

  The same holds for `close` and `toggle`. `"id"` and `"#id"` are both accepted.
  """

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  @components %{
    accordion: LineaUI.Components.Accordion,
    alert: LineaUI.Components.Alert,
    app_shell: LineaUI.Components.AppShell,
    autocomplete: LineaUI.Components.Autocomplete,
    avatar: LineaUI.Components.Avatar,
    badge: LineaUI.Components.Badge,
    breadcrumb: LineaUI.Components.Breadcrumb,
    card_table: LineaUI.Components.CardTable,
    bulk_bar: LineaUI.Components.BulkBar,
    button: LineaUI.Components.Button,
    calendar: LineaUI.Components.Calendar,
    card: LineaUI.Components.Card,
    carousel: LineaUI.Components.Carousel,
    chart: LineaUI.Components.Chart,
    checkbox: LineaUI.Components.Checkbox,
    clipboard: LineaUI.Components.Clipboard,
    command_palette: LineaUI.Components.CommandPalette,
    collapse: LineaUI.Components.Collapse,
    color_picker: LineaUI.Components.ColorPicker,
    data_table: LineaUI.Components.DataTable,
    date_picker: LineaUI.Components.DatePicker,
    datetime_picker: LineaUI.Components.DatetimePicker,
    divider: LineaUI.Components.Divider,
    drawer: LineaUI.Components.Drawer,
    dropdown: LineaUI.Components.Dropdown,
    email: LineaUI.Components.Email,
    empty_state: LineaUI.Components.EmptyState,
    connection_banner: LineaUI.Components.ConnectionBanner,
    fab: LineaUI.Components.Fab,
    filter_menu: LineaUI.Components.FilterMenu,
    form: LineaUI.Components.Form,
    icon: LineaUI.Components.Icon,
    input: LineaUI.Components.Input,
    input_group: LineaUI.Components.InputGroup,
    kanban: LineaUI.Components.Kanban,
    mask: LineaUI.Components.Mask,
    menu_list: LineaUI.Components.MenuList,
    modal: LineaUI.Components.Modal,
    number_input: LineaUI.Components.NumberInput,
    otp_input: LineaUI.Components.OtpInput,
    pagination: LineaUI.Components.Pagination,
    phone_input: LineaUI.Components.PhoneInput,
    popover: LineaUI.Components.Popover,
    progress: LineaUI.Components.Progress,
    radio: LineaUI.Components.Radio,
    range: LineaUI.Components.Range,
    scroll_area: LineaUI.Components.ScrollArea,
    segmented: LineaUI.Components.Segmented,
    select: LineaUI.Components.Select,
    signature_pad: LineaUI.Components.SignaturePad,
    skeleton: LineaUI.Components.Skeleton,
    spinner: LineaUI.Components.Spinner,
    steps: LineaUI.Components.Steps,
    switch: LineaUI.Components.Switch,
    table: LineaUI.Components.Table,
    tabs: LineaUI.Components.Tabs,
    tag: LineaUI.Components.Tag,
    tags_input: LineaUI.Components.TagsInput,
    text_editor: LineaUI.Components.TextEditor,
    textarea: LineaUI.Components.Textarea,
    time_picker: LineaUI.Components.TimePicker,
    timeline: LineaUI.Components.Timeline,
    timer: LineaUI.Components.Timer,
    toast: LineaUI.Components.Toast,
    tooltip: LineaUI.Components.Tooltip,
    treeview: LineaUI.Components.Treeview,
    typography: LineaUI.Components.Typography,
    upload: LineaUI.Components.Upload
  }

  @core_conflicts %{
    button: [button: 1],
    input: [input: 1],
    table: [table: 1],
    form: [label: 1, error: 1],
    app_shell: [header: 1, theme_toggle: 1],
    icon: [icon: 1]
  }

  @doc "The component modules `use LineaUI` imports, by key."
  @spec components() :: %{atom() => module()}
  def components, do: @components

  defmacro __using__(opts) do
    only = Keyword.get(opts, :only, Map.keys(@components))
    except = Keyword.get(opts, :except, [])
    conflicts = conflicts(Keyword.get(opts, :avoid_conflicts, false))

    @components
    |> Enum.filter(fn {key, _module} -> key in only and key not in except end)
    |> Enum.map(fn {key, module} -> import_quote(module, Map.get(conflicts, key, [])) end)
  end

  defp conflicts(true), do: @core_conflicts
  defp conflicts(false), do: %{}

  defp import_quote(module, []), do: quote(do: import(unquote(module)))
  defp import_quote(module, skip), do: quote(do: import(unquote(module), except: unquote(skip)))

  @doc "Opens the overlay with `id`."
  @spec open(String.t()) :: JS.t()
  @spec open(Socket.t() | JS.t(), String.t()) :: Socket.t() | JS.t()
  def open(id), do: open(%JS{}, id)
  def open(target, id), do: command(target, "open", id)

  @doc "Closes the overlay with `id`."
  @spec close(String.t()) :: JS.t()
  @spec close(Socket.t() | JS.t(), String.t()) :: Socket.t() | JS.t()
  def close(id), do: close(%JS{}, id)
  def close(target, id), do: command(target, "close", id)

  @doc "Opens the overlay with `id` when it is closed and closes it when it is open."
  @spec toggle(String.t()) :: JS.t()
  @spec toggle(Socket.t() | JS.t(), String.t()) :: Socket.t() | JS.t()
  def toggle(id), do: toggle(%JS{}, id)
  def toggle(target, id), do: command(target, "toggle", id)

  defp command(%JS{} = js, action, id),
    do: JS.dispatch(js, "linea:#{action}", to: selector(id))

  defp command(%Socket{} = socket, action, id),
    do: Phoenix.LiveView.push_event(socket, "linea:#{action}", %{id: selector(id)})

  @doc false
  @spec selector(String.t()) :: String.t()
  def selector("#" <> _ = id), do: id
  def selector(id), do: "#" <> id
end
