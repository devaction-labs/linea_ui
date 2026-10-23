defmodule PreviewWeb.Pages.Upload do
  use PreviewWeb.Page, title: "Input File", category: :forms, lineone: "forms-upload"

  alias Phoenix.LiveView

  @ponds ~w(files1 files2 files3 files4 files5 files6)a
  @circles ~w(avatar1 avatar2 avatar3)a

  def mount(socket) do
    socket =
      Enum.reduce(@ponds, socket, fn name, socket ->
        LiveView.allow_upload(socket, name, accept: :any, max_entries: 8, auto_upload: true)
      end)

    socket =
      Enum.reduce(@circles, socket, fn name, socket ->
        LiveView.allow_upload(socket, name,
          accept: ~w(.png .jpg .jpeg .gif),
          max_entries: 1,
          auto_upload: true
        )
      end)

    LiveView.allow_upload(socket, :document, accept: :any, auto_upload: true)
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel", %{"upload" => upload, "ref" => ref}, socket),
    do: {:noreply, LiveView.cancel_upload(socket, String.to_existing_atom(upload), ref)}

  def render(assigns) do
    ~H"""
    <.example title="Input File" class="max-w-xl">
      <p>
        Input elements with type
        <.inline_code>"file"</.inline_code>
        let the user choose one or more files from their device storage. Once chosen, the files can be uploaded to a server using form submission.
      </p>
      <form id="document-form" phx-change="validate" class="inline-space mt-5 flex flex-wrap">
        <.upload_button upload={@uploads.document}>
          <span class="flex items-center space-x-2">
            <.upload_icon />
            <span>Choose File</span>
          </span>
        </.upload_button>
        <.upload_button name="file2" color="primary">
          <span class="flex items-center space-x-2">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512" class="size-4 fill-current">
              <path d="M144 480C64.5 480 0 415.5 0 336c0-62.8 40.2-116.2 96.2-135.9c-.1-2.7-.2-5.4-.2-8.1c0-88.4 71.6-160 160-160c59.3 0 111 32.2 138.7 80.2C409.9 102 428.3 96 448 96c53 0 96 43 96 96c0 12.2-2.3 23.8-6.4 34.6C596 238.4 640 290.1 640 352c0 70.7-57.3 128-128 128H144zm79-217c-9.4 9.4-9.4 24.6 0 33.9s24.6 9.4 33.9 0l39-39V392c0 13.3 10.7 24 24 24s24-10.7 24-24V257.9l39 39c9.4 9.4 24.6 9.4 33.9 0s9.4-24.6 0-33.9l-80-80c-9.4-9.4-24.6-9.4-33.9 0l-80 80z" />
            </svg>
            <span>Choose File</span>
          </span>
        </.upload_button>
        <.upload_button name="file3" variant="outline" aria-label="Choose File">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
            />
          </svg>
        </.upload_button>
        <.upload_button
          name="file4"
          color="info"
          variant="glow"
          icon
          shape="pill"
          aria-label="Choose File"
        >
          <.upload_icon />
        </.upload_button>
      </form>
    </.example>
    <.pond title="Basic Filepond" upload={@uploads.files1} bordered />
    <.pond title="Filled Filepond" upload={@uploads.files2} filled />
    <.pond title="Filled & Bordered" upload={@uploads.files3} bordered filled />
    <.pond title="Two Grid" upload={@uploads.files4} bordered columns={2} />
    <.pond title="Three Grid" upload={@uploads.files5} bordered columns={3} />
    <.pond title="Four Grid" upload={@uploads.files6} bordered columns={4} />
    <.example title="Circle Filepond" class="max-w-xl">
      <.intro />
      <form id="circles-form" phx-change="validate" class="inline-space mt-5 flex flex-wrap items-end">
        <.circle upload={@uploads.avatar1} bordered class="w-28" />
        <.circle upload={@uploads.avatar2} bordered class="w-24" />
        <.circle upload={@uploads.avatar3} filled class="w-20" />
      </form>
    </.example>
    """
  end

  attr :title, :string, required: true
  attr :upload, :any, required: true
  attr :bordered, :boolean, default: false
  attr :filled, :boolean, default: false
  attr :columns, :integer, default: 1

  defp pond(assigns) do
    ~H"""
    <.example title={@title} class="max-w-xl">
      <.intro />
      <form id={"#{@upload.name}-form"} phx-change="validate" class="mt-5">
        <.upload
          upload={@upload}
          bordered={@bordered}
          filled={@filled}
          columns={@columns}
          on_cancel={JS.push("cancel", value: %{upload: @upload.name})}
        />
      </form>
    </.example>
    """
  end

  attr :upload, :any, required: true
  attr :bordered, :boolean, default: false
  attr :filled, :boolean, default: false
  attr :class, :string, required: true

  defp circle(assigns) do
    ~H"""
    <.upload
      upload={@upload}
      layout="circle"
      bordered={@bordered}
      filled={@filled}
      class={@class}
      on_cancel={JS.push("cancel", value: %{upload: @upload.name})}
    >
      <:label>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-8"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
          />
        </svg>
      </:label>
    </.upload>
    """
  end

  defp upload_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
      />
    </svg>
    """
  end

  defp intro(assigns) do
    ~H"""
    <p>
      Filepond a JavaScript library that can upload anything you throw at it, optimizes images for faster uploads, and offers a great, accessible, silky smooth user experience. You can check the plugin documentation on
      <a
        class="font-normal text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
        href="https://github.com/pqina/filepond"
      >Github.</a>
    </p>
    """
  end
end
