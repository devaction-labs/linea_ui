defmodule PreviewWeb.Pages.BulkBar do
  use PreviewWeb.Page, title: "Bulk bar", category: :components

  @statuses [{"Pending", "pending"}, {"In separation", "separation"}, {"Shipped", "shipped"}]

  def mount(socket), do: assign(socket, count: 3, status: nil, statuses: @statuses)

  def handle_event("clear", _params, socket), do: {:noreply, assign(socket, count: 0)}
  def handle_event("pick", %{"status" => status}, socket), do: {:noreply, assign(socket, status: status)}
  def handle_event("show", _params, socket), do: {:noreply, assign(socket, count: 3, status: nil)}
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    assigns = assign(assigns, statuses: @statuses, stage: "relative overflow-hidden rounded-lg bg-slate-100 p-4 [transform:translateZ(0)] dark:bg-navy-900")

    ~H"""
    <.example title="Change an attribute, then apply" text="Apply is off until a status is chosen. Esc or the close clears the selection." class="mt-5">
      <div class={[@stage, "min-h-40"]}>
        <.button :if={@count == 0} phx-click="show">Select 3 orders</.button>
        <form phx-change="pick">
          <.bulk_bar
            id="bulk-main"
            count={@count}
            label="order selected"
            label_plural="orders selected"
            floating={false}
            on_clear="clear"
          >
            <:field>
              <.select name="status" options={@statuses} value={@status} search="none" placeholder="Change status" />
            </:field>
            <:action variant="primary" disabled={is_nil(@status)} phx-click="clear">
              Apply to {@count}
            </:action>
          </.bulk_bar>
        </form>
      </div>
    </.example>

    <.example title="Several actions" text="The destructive one is last, in red. Select all shows when there is more than this page." class="mt-5">
      <div class={@stage}>
        <.bulk_bar id="bulk-actions" count={12} total={128} on_select_all="noop" on_clear="noop" label="order selected" label_plural="orders selected" select_all_label="Select all %{total}" floating={false}>
          <:action icon="huge-download-04" phx-click="noop">Export</:action>
          <:action icon="huge-menu-01" phx-click="noop">Change status</:action>
          <:action variant="danger" icon="huge-delete-02" phx-click="noop">Delete</:action>
        </.bulk_bar>
      </div>
    </.example>

    <.example title="Soft" text="The page's own surface, for when the inverted bar weighs too much." class="mt-5">
      <div class={@stage}>
        <.bulk_bar id="bulk-soft" count={1} variant="soft" floating={false} label="order selected" on_clear="noop">
          <:action variant="primary" phx-click="noop">Apply</:action>
        </.bulk_bar>
      </div>
    </.example>
    """
  end
end
