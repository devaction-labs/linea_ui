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
    <.narrow title="Copied state" text="With copied_label the button turns green and says so for two seconds." class="mt-5">
      <div class="flex flex-wrap gap-3">
        <.clipboard id="copiedState1" value="mix phx.new demo" copied_label="Copied">Copy</.clipboard>
        <.clipboard id="copiedState2" value="mix phx.new demo" variant="outline" copied_label="Copied">Copy</.clipboard>
      </div>
    </.narrow>

    <.narrow title="Icon and icon only" text="icon puts the copy icon before the text (a check while copied); icon_only is a square button for a snippet." class="mt-5">
      <div class="flex flex-wrap items-center gap-3">
        <.clipboard id="iconBtn" value="mix phx.new demo" icon copied_label="Copied">Copy</.clipboard>
        <code id="iconSnippet" class="rounded-lg bg-slate-150 px-3 py-2 text-sm dark:bg-navy-600">mix phx.new demo</code>
        <.clipboard id="iconOnly" from="#iconSnippet" icon_only variant="flat" aria-label="Copy command" />
      </div>
      <.clipboard_input id="iconField" value="https://app.example.com/invite/ana" copied_label="Copied" icon class="mt-4 max-w-xl" />
    </.narrow>
    """
  end
end
