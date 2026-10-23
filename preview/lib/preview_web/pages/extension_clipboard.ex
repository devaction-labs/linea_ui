defmodule PreviewWeb.Pages.ExtensionClipboard do
  use PreviewWeb.Page,
    title: "Clipboard",
    category: :components,
    lineone: "components-extension-clipboard"

  import PreviewWeb.Pages.NarrowExample

  @text "magic function that can be used to copy data to the user's clipboard. Check out code for detail of usage."

  def render(assigns) do
    assigns = assign(assigns, text: @text)

    ~H"""
    <.narrow title="Basic Usage" text={@text} class="mt-5">
      <:lead><code class="inline-code">$clipboard</code>{" "}</:lead>
      <div class="alert flex items-center justify-between rounded-lg bg-primary px-4 py-3 text-white dark:bg-accent sm:px-5">
        <p id="clipboardContent1">Lorem ipsum dolor sit amet consectetur.</p>
        <.clipboard
          id="getContent1"
          from="#clipboardContent1"
          size="xs"
          class="shrink-0 bg-white/20 px-2 text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25 dark:bg-white/20 dark:hover:bg-white/20 dark:focus:bg-white/20 dark:active:bg-white/25"
        />
      </div>
    </.narrow>
    <.narrow title="Advanced Usage" text={@text} class="mt-5">
      <:lead><code class="inline-code">$clipboard</code>{" "}</:lead>
      <.clipboard_input id="clipboardContent2" placeholder="Enter text" />
    </.narrow>
    """
  end
end
