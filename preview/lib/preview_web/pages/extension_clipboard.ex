defmodule PreviewWeb.Pages.ExtensionClipboard do
  use PreviewWeb.Page,
    title: "Clipboard",
    category: :components,
    lineone: "components-extension-clipboard"

  import PreviewWeb.Pages.NarrowExample

  @text "magic function that can be used to copy data to the user's clipboard. Check out code for detail of usage."

  @variants ~w(solid glow outline soft bordered flat)
  @colors ~w(neutral primary secondary info success warning error)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, text: @text, variants: @variants, colors: @colors, sizes: @sizes)

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

    <.narrow
      title="Button states"
      text="icon and copied_label: the icon turns into a check and the button into the success color for two seconds. Click one to see it; the middle one is held in that state."
      class="mt-5"
    >
      <div class="flex flex-wrap items-center gap-3">
        <.clipboard id="st-default" value="mix phx.new projetos --live" icon copied_label="Copiado">
          Copiar
        </.clipboard>
        <.clipboard
          id="st-copied"
          value="mix phx.new projetos --live"
          icon
          copied_label="Copiado"
          data-copied
        >
          Copiar
        </.clipboard>
        <.clipboard
          id="st-disabled"
          value="mix phx.new projetos --live"
          icon
          copied_label="Copiado"
          disabled
        >
          Copiar
        </.clipboard>
      </div>
    </.narrow>

    <.narrow
      title="Variants and colors"
      text="variant: solid, glow, outline, soft, bordered, flat. color: neutral, primary, secondary, info, success, warning, error."
      class="mt-5"
    >
      <div class="flex flex-wrap items-center gap-3">
        <.clipboard
          :for={variant <- @variants}
          id={"var-#{variant}"}
          value="mix phx.new demo"
          variant={variant}
        >
          Copiar
        </.clipboard>
      </div>
      <div class="mt-4 flex flex-wrap items-center gap-3">
        <.clipboard :for={color <- @colors} id={"col-#{color}"} value="mix phx.new demo" color={color}>
          Copiar
        </.clipboard>
      </div>
    </.narrow>

    <.narrow title="Sizes" text="size: xs, sm, md, lg, xl." class="mt-5">
      <div class="flex flex-wrap items-end gap-3">
        <.clipboard :for={size <- @sizes} id={"size-#{size}"} value="mix phx.new demo" size={size}>
          Copiar
        </.clipboard>
      </div>
    </.narrow>

    <.narrow
      title="Field with a button"
      text="clipboard_input: a real field and a joined button that copies what the field holds."
      class="mt-5"
    >
      <.clipboard_input
        id="invite-link"
        value="https://app.exemplo.com/convite/ana"
        label="Copiar"
        copied_label="Copiado"
        icon
        class="max-w-xl"
      />
    </.narrow>

    <.narrow
      title="Code snippet with a copy"
      text="Composition: icon_only points at the element whose text it copies, with from."
      class="mt-5"
    >
      <div class="max-w-xl space-y-3">
        <div class="flex items-center justify-between rounded-lg bg-slate-100 py-1.5 pl-3 pr-1.5 font-mono text-xs dark:bg-navy-600">
          <code id="cmd-1">mix phx.new projetos --live</code>
          <.clipboard
            id="cmd-1-copy"
            from="#cmd-1"
            icon_only
            variant="flat"
            size="xs"
            color="neutral"
            aria-label="Copiar comando"
          />
        </div>
        <div class="flex items-center justify-between rounded-lg bg-slate-100 py-1.5 pl-3 pr-1.5 font-mono text-xs dark:bg-navy-600">
          <code id="cmd-2">mix ecto.setup</code>
          <.clipboard
            id="cmd-2-copy"
            from="#cmd-2"
            icon_only
            variant="flat"
            size="xs"
            color="neutral"
            aria-label="Copiar comando"
          />
        </div>
      </div>
    </.narrow>

    <.narrow
      title="Feedback after copying"
      text="The success toast is the app's to word (toast); a failed copy shows error_toast."
      class="mt-5"
    >
      <div class="flex flex-wrap items-center gap-3">
        <.clipboard
          id="fb-1"
          value="https://app.exemplo.com/convite/ana"
          toast="Texto copiado"
          error_toast="Não foi possível copiar"
          icon
        >
          Copiar link
        </.clipboard>
      </div>
    </.narrow>
    """
  end
end
