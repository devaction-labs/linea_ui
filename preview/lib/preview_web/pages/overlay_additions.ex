defmodule PreviewWeb.Pages.OverlayAdditions do
  use PreviewWeb.Page,
    title: "Overlay Additions",
    category: :components,
    lineone: "components-drawer"

  def handle_event("send", _params, socket) do
    Process.send_after(self(), :authorized, 1500)
    {:noreply, send_toast(socket, id: "nfe", kind: :loading, title: "Sending the invoice…")}
  end

  def handle_event("undo", _params, socket),
    do: {:noreply, send_toast(socket, "Undone", kind: :info)}

  def handle_info(:authorized, socket) do
    {:noreply,
     send_toast(socket, "Invoice authorized",
       id: "nfe",
       kind: :success,
       description: "NF-e 1234 was authorized by SEFAZ.",
       actions: [[label: "Undo", event: "undo"], [label: "Close", dismiss: true]]
     )}
  end

  def render(assigns) do
    ~H"""
    <.example title="Sheet" text="A drawer with a title, a scrolling body and a footer, stacked.">
      <.button color="primary" phx-click={LineaUI.open("detail")} id="open-detail">Detail</.button>
      <.button phx-click={LineaUI.open("small")} id="open-small">Small, left</.button>
    </.example>

    <.example title="Toasts" text="Kinds, a description, actions, loading then the answer.">
      <.button
        :for={kind <- ~w(info success warning error)}
        id={"toast-#{kind}"}
        phx-click={show_toast("Something happened", kind: kind, description: "With a second line.")}
      >
        {kind}
      </.button>
      <.button id="toast-send" color="primary" phx-click="send">Send invoice</.button>
      <.button id="toast-clear" phx-click={clear_toasts()}>Clear</.button>
    </.example>

    <.example
      title="Submenu and scroll area"
      text="A nested menu and a long list."
      class="mt-5 flex flex-wrap items-start gap-4"
    >
      <.dropdown id="row-menu" label="Actions">
        <.dropdown_item>Edit</.dropdown_item>
        <.dropdown_submenu id="move" label="Move to">
          <.dropdown_item>Archive</.dropdown_item>
          <.dropdown_item>Trash</.dropdown_item>
          <.dropdown_submenu id="move-more" label="Folder">
            <.dropdown_item>Invoices</.dropdown_item>
            <.dropdown_item>Orders</.dropdown_item>
          </.dropdown_submenu>
        </.dropdown_submenu>
        <.dropdown_separator />
        <.dropdown_item color="error">Delete</.dropdown_item>
      </.dropdown>
      <.scroll_area class="h-40 w-56 rounded-lg border border-slate-150 p-3 dark:border-navy-500">
        <p :for={n <- 1..20} class="py-1">Row {n}</p>
      </.scroll_area>
    </.example>

    <.drawer
      id="detail"
      placement="right"
      size="md"
      title="BB outubro/2026"
      description="Banco do Brasil · Ag 1523 · CC 48210-7"
    >
      <:actions>
        <.button size="sm" color="primary" phx-click={LineaUI.open("combine")} id="open-combine">
          Combine
        </.button>
      </:actions>
      <p :for={n <- 1..30}>Statement line {n}</p>
      <:footer>
        <.button variant="outline" phx-click={LineaUI.open("confirm")} id="open-confirm">
          Cancel reconciliation
        </.button>
        <.button color="primary" phx-click={LineaUI.open("edit")} id="open-edit">Edit</.button>
      </:footer>
    </.drawer>

    <.drawer id="edit" placement="right" size="lg" title="Edit" description="Over the detail.">
      <p>The edit form.</p>
      <:footer>
        <.button phx-click={LineaUI.close("edit")}>Cancel</.button>
        <.button color="primary" phx-click={LineaUI.close("edit")}>Save</.button>
      </:footer>
    </.drawer>

    <.drawer
      id="combine"
      placement="right"
      size="xl"
      title="Combine line"
      description="Pick ledger transactions."
    >
      <:back>
        <.button
          icon
          variant="flat"
          shape="pill"
          class="size-8"
          aria-label="Back"
          phx-click={LineaUI.close("combine")}
          id="combine-back"
        >
          <.glyph name={:chevron_left} class="size-4.5" />
        </.button>
      </:back>
      <p>Candidates.</p>
    </.drawer>

    <.drawer id="small" size="sm" title="Filters" lock_scroll>
      <p>Left, 400px.</p>
    </.drawer>

    <.modal id="confirm">
      <:header>Cancel the reconciliation?</:header>
      <p>Opened from the sheet, drawn above it.</p>
      <:footer>
        <.button phx-click={LineaUI.close("confirm")}>Back</.button>
      </:footer>
    </.modal>
    """
  end
end
