defmodule PreviewWeb.Pages.Pagination do
  use PreviewWeb.Page,
    title: "Pagination",
    category: :components,
    lineone: "components-pagination"

  @basic "Pagination is a group of buttons that allow the user to navigate between a set of related content. Check out code for detail of usage."

  def mount(socket) do
    assign(socket,
      pages: %{"basic" => 2, "rounded" => 2, "divided" => 2, "both" => 2, "size" => 2}
    )
  end

  def handle_event("page:" <> key, %{"page" => page}, socket) do
    {:noreply, update(socket, :pages, &Map.put(&1, key, String.to_integer(page)))}
  end

  def render(assigns) do
    assigns = assign(assigns, :basic, @basic)

    ~H"""
    <.example title="Basic Pagination" class="">
      <div class="max-w-xl">
        <p>{@basic}</p>
        <div class="mt-5">
          <.pagination page={@pages["basic"]} total_pages={5} on_change="page:basic" />
        </div>
      </div>
    </.example>
    <.example title="Rounded Pagination" class="">
      <div class="max-w-xl">
        <p>Pagination can have a rounded-sm shape. Check out code for detail of usage.</p>
        <div class="mt-5">
          <.pagination
            page={@pages["rounded"]}
            total_pages={5}
            on_change="page:rounded"
            shape="pill"
          />
        </div>
      </div>
    </.example>
    <.example title="Divided Pagination" class="">
      <div class="max-w-xl">
        <p>Pagination can be divided. Check out code for detail of usage.</p>
        <div class="mt-5">
          <.pagination page={@pages["divided"]} total_pages={5} on_change="page:divided" divided />
        </div>
      </div>
    </.example>
    <.example title="Rounded & Divided" class="">
      <div class="max-w-xl">
        <p>Pagination can be rounded-sm and divided. Check out code for detail of usage.</p>
        <div class="mt-5">
          <.pagination
            page={@pages["both"]}
            total_pages={5}
            on_change="page:both"
            shape="pill"
            divided
          />
        </div>
      </div>
    </.example>
    <.example title="Pagination Size" class="">
      <div class="max-w-xl">
        <p>{@basic}</p>
        <div class="mt-5 space-y-4">
          <.pagination
            :for={size <- ~w(sm md lg)}
            page={@pages["size"]}
            total_pages={5}
            on_change="page:size"
            size={size}
          />
        </div>
      </div>
    </.example>
    <.example title="Many Pages" class="">
      <div class="max-w-xl">
        <p>
          With many pages the ones far from the current page collapse into an ellipsis; each page can
          also be a patch or navigate link.
        </p>
        <div class="mt-5 space-y-4">
          <.pagination page={5} total_pages={20} patch={&"/pagination?page=#{&1}"} />
          <.pagination page={1} total_pages={20} patch={&"/pagination?page=#{&1}"} divided />
        </div>
      </div>
    </.example>
    """
  end
end
