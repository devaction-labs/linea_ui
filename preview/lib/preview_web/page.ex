defmodule PreviewWeb.Page do
  @moduledoc """
  A preview page: one per LineOne demo page, rendered inside `PreviewWeb.PageLive`.

      defmodule PreviewWeb.Pages.Button do
        use PreviewWeb.Page, title: "Button", category: :elements, lineone: "elements-button"

        def render(assigns) do
          ~H\"""
          <.example title="Button" text="Use Button component for actions...">
            <.button>Default</.button>
          </.example>
          \"""
        end
      end

  Every module under `PreviewWeb.Pages` is listed in the sidebar and served at `/<slug>`,
  where the slug is the module name in kebab case (`ButtonGroup` → `button-group`).
  `lineone` names the original page, served at `/lineone/<name>.html` for comparison.

  A page with state overrides `mount/1` (takes and returns the socket), `handle_event/3`
  and `handle_info/2` (both return `{:noreply, socket}`).
  """

  @callback render(map()) :: Phoenix.LiveView.Rendered.t()
  @callback mount(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  @callback handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}
  @callback handle_info(term(), Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}

  defmacro __using__(opts) do
    quote do
      use PreviewWeb, :html
      import PreviewWeb.Page, only: [example: 1]
      import Phoenix.LiveView, only: [push_event: 3, put_flash: 3]

      @behaviour PreviewWeb.Page

      def __page__, do: Map.new(unquote(opts))

      @impl PreviewWeb.Page
      def mount(socket), do: socket

      @impl PreviewWeb.Page
      def handle_event(_event, _params, socket), do: {:noreply, socket}

      @impl PreviewWeb.Page
      def handle_info(_message, socket), do: {:noreply, socket}

      defoverridable mount: 1, handle_event: 3, handle_info: 2
    end
  end

  use Phoenix.Component

  @doc "A demo card the way LineOne's pages draw one: title, description and the examples."
  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: "inline-space mt-5 flex flex-wrap"
  slot :inner_block, required: true

  def example(assigns) do
    ~H"""
    <div class="card px-4 pb-4 sm:px-5" id={@id}>
      <div class="my-3 flex h-8 items-center justify-between">
        <h2 class="font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100 lg:text-base">
          {@title}
        </h2>
      </div>
      <div>
        <p :if={@text} class="max-w-2xl">{@text}</p>
        <div class={@class}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end
end
