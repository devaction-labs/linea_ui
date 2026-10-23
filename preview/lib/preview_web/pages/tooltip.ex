defmodule PreviewWeb.Pages.Tooltip do
  use PreviewWeb.Page, title: "Tooltip", category: :elements, lineone: "elements-tooltip"

  @colors ~w(neutral light primary secondary info success warning error)
  @placements ~w(top top-start top-end right right-end right-start bottom bottom-start bottom-end left left-start left-end)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, placements: @placements)

    ~H"""
    <.example
      title="Basic Tooltip"
      text="A tooltip is often used to specify extra information about something when the user moves the mouse pointer over an element. Check out code for detail of usage."
    >
      <.tooltip :for={color <- @colors} id={"tip-#{color}"} text={color_label(color)} color={color}>
        <.button
          color={button_color(color)}
          class={
            color == "light" &&
              "dark:bg-slate-150 dark:text-slate-800 dark:hover:bg-slate-200 dark:focus:bg-slate-200"
          }
        >
          {color_label(color)}
        </.button>
      </.tooltip>
    </.example>

    <.example
      title="Tooltip Position"
      text="Tooltip can be placed in four base ways in relation to the reference element. Check out code for detail of usage."
    >
      <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <.tooltip
          :for={placement <- @placements}
          id={"tip-#{placement}"}
          text={placement_label(placement)}
          color="success"
          placement={placement}
          class="flex"
        >
          <.button color="primary" variant="outline" class="w-full">
            {placement_label(placement)}
          </.button>
        </.tooltip>
      </div>
    </.example>

    <.example
      title="Tooltip Delay, Duration"
      text="Tooltip can delay hiding or showing after a trigger. Check out code for detail of usage."
    >
      <.tooltip id="tip-delay" text="Debounce 500 millisecond" delay={500}>
        <.button>Delay</.button>
      </.tooltip>
      <.tooltip id="tip-duration" text="Duration 500 millisecond animate tooltip" duration={500}>
        <.button>Duration</.button>
      </.tooltip>
    </.example>

    <.example
      title="Tooltip Trigger"
      text="Tooltip can be triggered by a variety of different events, including click, focus, or any other even. Check out code for detail of usage."
    >
      <.tooltip id="tip-hover" text="Hover me"><.button>Hover</.button></.tooltip>
      <.tooltip id="tip-click" text="Click me" trigger="click"><.button>Click</.button></.tooltip>
      <.tooltip id="tip-focus" text="Focus me" trigger="focus"><.button>Focus</.button></.tooltip>
    </.example>

    <.example
      title="Follow Cursor"
      text="Tooltip can follow the mouse cursor and abide by a certain axis. Additionally, the tooltip can follow the cursor until it shows, at which point it will stop following. Check out code for detail of usage."
    >
      <.tooltip id="tip-cursor" text="Follow Cursor" follow_cursor="both">
        <.button>Cursor</.button>
      </.tooltip>
      <.tooltip id="tip-cursor-x" text="Follow Cursor horizontal" follow_cursor="horizontal">
        <.button>Horizontal</.button>
      </.tooltip>
      <.tooltip id="tip-cursor-y" text="Follow Cursor Vertical" follow_cursor="vertical">
        <.button>Vertical</.button>
      </.tooltip>
      <.tooltip
        id="tip-cursor-initial"
        text="Follow Cursor initial"
        follow_cursor="initial"
        trigger="click"
      >
        <.button>Click me</.button>
      </.tooltip>
    </.example>

    <.example
      title="HTML Content Tooltip"
      text="Tooltip tippy can contain HTML. Check out code for detail of usage."
    >
      <.tooltip id="tip-content">
        <.button>Content</.button>
        <:content>
          <div class="flex space-x-3 rounded-lg bg-slate-150 p-3 dark:bg-navy-500">
            <.avatar src="/lineone/images/avatar/avatar-13.jpg" alt="image" />
            <div>
              <.text class="font-medium text-slate-700 dark:text-navy-100">John Doe</.text>
              <.text size="xs" class="text-slate-500 dark:text-navy-200">Product Manager</.text>
            </div>
          </div>
        </:content>
      </.tooltip>
    </.example>
    """
  end

  defp color_label("neutral"), do: "Default"
  defp color_label(color), do: String.capitalize(color)

  defp button_color("light"), do: "neutral"
  defp button_color(color), do: color

  defp placement_label(placement) do
    placement |> String.split("-") |> Enum.map_join(" ", &String.capitalize/1)
  end
end
