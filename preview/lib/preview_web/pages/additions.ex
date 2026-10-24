defmodule PreviewWeb.Pages.Additions do
  use PreviewWeb.Page, title: "Additions", category: :elements, lineone: "elements-badge"

  @rows [
    %{label: "Satisfied", count: 120, share: "62%"},
    %{label: "Neutral", count: 48, share: "25%"}
  ]

  def mount(socket), do: assign(socket, rows: @rows, tags: ~w(Design Dev Ops), picked: ["Dev"])

  def handle_event("toggle_tag", %{"tag" => tag}, socket),
    do: {:noreply, update(socket, :picked, &toggle(&1, tag))}

  defp toggle(list, tag) do
    case tag in list do
      true -> List.delete(list, tag)
      false -> [tag | list]
    end
  end

  def render(assigns) do
    ~H"""
    <.example
      title="Avatar"
      text="Extra sizes, ring width and color, face_class, status, group overlap."
    >
      <.avatar src="/lineone/images/avatar/avatar-8.jpg" size="3xs" />
      <.avatar src="/lineone/images/avatar/avatar-8.jpg" size="2xs" />
      <.avatar src="/lineone/images/avatar/avatar-8.jpg" size="xs" />
      <.avatar src="/lineone/images/avatar/avatar-8.jpg" size="xs-plus" />
      <.avatar
        src="/lineone/images/avatar/avatar-8.jpg"
        status="success"
        status_position="bottom-right"
      />
      <.avatar
        src="/lineone/images/avatar/avatar-8.jpg"
        status="neutral"
        status_position="bottom-right"
      />
      <.avatar
        src="/lineone/images/avatar/avatar-8.jpg"
        size="lg"
        face_class="border-2 border-primary"
      />
      <.avatar_group overlap="3">
        <.avatar src="/lineone/images/avatar/avatar-5.jpg" size="xs" ring={4} ring_color="primary" />
        <.avatar src="/lineone/images/avatar/avatar-8.jpg" size="xs" ring={1} ring_color="success" />
        <.avatar initials="jd" color="info" size="2xs" ring />
      </.avatar_group>
    </.example>

    <.example
      title="Badge, button, progress on a colored card"
      text="White and glass variants."
      class=""
    >
      <.card variant="gradient" gradient="purple-indigo" class="max-w-sm">
        <.badge size="xs" color="white" variant="outline" shape="pill">xs outline</.badge>
        <.badge size="sm" color="white" variant="soft" shape="pill">sm soft</.badge>
        <.badge size="md" color="white" shape="pill">md solid</.badge>
        <div class="mt-3 flex items-center space-x-2">
          <.button variant="glass">Glass</.button>
          <.button variant="flat" color="white">Flat</.button>
          <.button variant="outline" color="white">Outline</.button>
        </div>
        <.progress value={60} color="white" height="1.5" class="mt-4" />
      </.card>
    </.example>

    <.example title="Tabs" text="Boxed sizes and the text variant.">
      <.tabs id="t-box" variant="boxed" size="sm">
        <:tab name="a">Last month</:tab>
        <:tab name="b">Last year</:tab>
      </.tabs>
      <.tabs id="t-box-xs" variant="boxed" size="xs">
        <:tab name="a">Last month</:tab>
        <:tab name="b">Last year</:tab>
      </.tabs>
      <.tabs id="t-text" variant="text" list_class="text-xs-plus">
        <:tab name="a">Last 7 days</:tab>
        <:tab name="b">All time</:tab>
      </.tabs>
    </.example>

    <.example title="Table" text="compact, headless, borderless, align." class="">
      <.card class="max-w-md">
        <.table id="sat" rows={@rows} compact headless borderless>
          <:col :let={row}>{row.label}</:col>
          <:col :let={row} align="right">{row.count}</:col>
          <:col :let={row} align="right">{row.share}</:col>
        </.table>
      </.card>
    </.example>

    <.example title="Card" text="flat and an xl gradient outline." class="">
      <.card variant="flat" class="w-56">Flat card</.card>
      <.card variant="gradient_outline" shape="xl" gradient="sky-blue" class="w-56">Outline xl</.card>
    </.example>

    <.example title="Dropdown, switch, input, select">
      <.dropdown id="d-dots" toggle_icon="dots" placement="bottom-end">
        <.dropdown_item href="#">Action</.dropdown_item>
      </.dropdown>
      <.dropdown id="d-dots-v" toggle_icon="dots-vertical" shape="square" placement="bottom-end">
        <.dropdown_item href="#">Action</.dropdown_item>
      </.dropdown>
      <.switch
        name="s"
        label="Email"
        label_position="left"
        color="primary"
        wrapper_class="w-48 justify-between"
      />
      <.input name="amount" size="sm" align="right" placeholder="0.00" class="w-32" />
      <.select native inline shape="pill" size="sm" name="p" options={~w(Week Month Year)} />
    </.example>

    <.example title="Accordion" text="The primary style in every theme color." class="">
      <.accordion id="acc-w" variant="primary" color="warning" class="max-w-md">
        <.accordion_item id="acc-w1" title="Warning item" open>Body</.accordion_item>
        <.accordion_item id="acc-w2" title="Another">Body</.accordion_item>
      </.accordion>
    </.example>

    <.example title="Tag, collapse, menu item, breadcrumb">
      <.tag
        :for={tag <- @tags}
        variant="soft"
        shape="pill"
        active={tag in @picked}
        phx-click="toggle_tag"
        phx-value-tag={tag}
      >
        {tag}
      </.tag>
      <.collapse id="c-chev" chevron="down" open class="w-56">
        <:trigger class="text-xs font-medium uppercase">My files</:trigger>
        Body
      </.collapse>
      <.menu_item navigate="#" variant="solid" active class="w-56">
        <:icon>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M3 8l9 6 9-6M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
        </:icon>
        Inbox
        <:count>12</:count>
      </.menu_item>
      <.breadcrumb>
        <:item phx-click="noop">Docs</:item>
        <:item phx-click="noop">Pictures</:item>
        <:item>Trip</:item>
      </.breadcrumb>
    </.example>

    <.example title="Timeline avatar point and carousel arrows outside" class="">
      <.timeline size="xl" class="max-w-sm">
        <.timeline_item
          variant="avatar"
          title="Mores Clarke"
          time="1 hour ago"
          description="Added a video"
        >
          <:point><.avatar src="/lineone/images/avatar/avatar-5.jpg" class="size-full" /></:point>
        </.timeline_item>
        <.timeline_item variant="avatar" title="Derrick Simmons" time="3 hours ago">
          <:point><.avatar src="/lineone/images/avatar/avatar-8.jpg" class="size-full" /></:point>
        </.timeline_item>
      </.timeline>
      <.carousel id="c-out" navigation="outside" pagination="bullets" class="mt-6 max-w-md">
        <.carousel_slide class="flex h-32 items-center justify-center bg-primary/10">
          One
        </.carousel_slide>
        <.carousel_slide class="flex h-32 items-center justify-center bg-success/10">
          Two
        </.carousel_slide>
      </.carousel>
    </.example>

    <.example title="Modal chip close button">
      <.button phx-click={LineaUI.open("m-chip")}>Open</.button>
      <.modal id="m-chip" close_variant="chip" class="overflow-hidden">
        <div class="h-40 bg-gradient-to-r from-sky-400 to-blue-600"></div>
        <p class="p-4">Close button keeps a backdrop over wide content.</p>
      </.modal>
    </.example>
    """
  end
end
