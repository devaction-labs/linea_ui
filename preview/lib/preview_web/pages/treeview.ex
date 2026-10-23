defmodule PreviewWeb.Pages.Treeview do
  use PreviewWeb.Page, title: "Treeview", category: :components, lineone: "components-treeview"

  @text "A tree view component presents a hierarchical list. Check out code for detail of usage."

  def mount(socket), do: assign(socket, selected: nil, toggled: nil)

  def handle_event("select", %{"id" => id}, socket), do: {:noreply, assign(socket, selected: id)}

  def handle_event("toggle", %{"id" => id, "expanded" => expanded}, socket),
    do: {:noreply, assign(socket, toggled: {id, expanded})}

  def render(assigns) do
    assigns = assign(assigns, :text, @text)

    ~H"""
    <.example title="Basic Treeview" class="max-w-xl">
      <p>{@text}</p>
      <div class="mt-5">
        <.treeview id="tree1" on_select="select" on_toggle="toggle">
          <.tree_item id="tree1-application" label="Application">
            <.tree_item :for={name <- ["Chrome", "VS Code", "Mail App", "Firefox"]} label={name} />
          </.tree_item>
          <.tree_item id="tree1-document" label="Document" expanded>
            <.tree_item id="tree1-react" label="React App" expanded>
              <.tree_item id="tree1-src" label="src" expanded>
                <.tree_item id="tree1-components" label="Components" expanded>
                  <.tree_item
                    :for={file <- ~w(Button.js Treeview.js Menu.js Avatar.js)}
                    id={"tree1-#{file}"}
                    label={file}
                  />
                </.tree_item>
              </.tree_item>
            </.tree_item>
          </.tree_item>
        </.treeview>
      </div>
    </.example>
    <.example title="Advanced Treeview" class="max-w-xl">
      <p>{@text}</p>
      <div class="mt-5">
        <.treeview id="tree2">
          <.tree_item label="Design">
            <:icon><.folder /></:icon>
            <.tree_item label="Web Apps">
              <:icon><.folder /></:icon>
            </.tree_item>
            <.tree_item label="CRM Apps">
              <:icon><.folder /></:icon>
              <.tree_item :for={name <- ["LMS App", "Ecommerce", "Dashboard"]} label={name}>
                <:icon><.folder /></:icon>
              </.tree_item>
            </.tree_item>
            <.tree_item :for={name <- ["Desktop Apps", "Mobile Apps"]} label={name}>
              <:icon><.folder /></:icon>
            </.tree_item>
          </.tree_item>
          <.tree_item label="Backup Files">
            <:icon><.folder /></:icon>
          </.tree_item>
          <.tree_item label="CRM Apps">
            <:icon><.folder /></:icon>
            <.tree_item :for={name <- ~w(Sheets Slides Words)} label={name}>
              <:icon><.folder /></:icon>
            </.tree_item>
          </.tree_item>
          <.tree_item label="Applications">
            <:icon><.folder /></:icon>
            <.tree_item label="Web Apps">
              <:icon><.folder /></:icon>
            </.tree_item>
            <.tree_item label="CRM Apps">
              <:icon><.folder /></:icon>
              <.tree_item :for={name <- ["LMS App", "Ecommerce", "Dashboard"]} label={name}>
                <:icon><.folder /></:icon>
              </.tree_item>
            </.tree_item>
            <.tree_item :for={name <- ["Desktop Apps", "Mobile Apps"]} label={name}>
              <:icon><.folder /></:icon>
            </.tree_item>
          </.tree_item>
          <.tree_item label="Archives">
            <:icon><.folder outline /></:icon>
          </.tree_item>
        </.treeview>
      </div>
    </.example>
    """
  end

  attr :outline, :boolean, default: false

  defp folder(%{outline: true} = assigns) do
    ~H"""
    <svg class="size-6 text-warning" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="1.5"
        d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
      />
    </svg>
    """
  end

  defp folder(assigns) do
    ~H"""
    <svg class="size-6 text-warning" viewBox="0 0 20 20" fill="currentColor">
      <path d="M2 6a2 2 0 012-2h5l2 2h5a2 2 0 012 2v6a2 2 0 01-2 2H4a2 2 0 01-2-2V6z" />
    </svg>
    """
  end
end
