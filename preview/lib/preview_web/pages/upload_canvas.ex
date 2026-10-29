defmodule PreviewWeb.Pages.UploadCanvas do
  @moduledoc """
  The "Upload de arquivos" artboard. `<.upload>` only renders the entries LiveView builds from a
  real browser upload, so each state that needs a file in flight (uploading, complete, error) is
  drawn from a hand-built `Phoenix.LiveView.UploadEntry` put in the config's `entries` and
  `errors`: the markup is still the package's own. The only decoration of the page is the
  thumbnail gradients (the previews are `<img>` the browser fills from a real file).
  """

  use PreviewWeb.Page, title: "Upload (canvas)", category: :components

  alias Phoenix.LiveView
  alias Phoenix.LiveView.UploadEntry

  @names ~w(idle1 idle2 idle3 drag1 drag2 files circle1 circle2 circle3 grid btn)a

  @texts [
    browse_label: "Procurar",
    drop_label: "Arraste e solte os arquivos ou",
    remove_label: "Remover",
    uploading_label: "Enviando",
    complete_label: "Envio concluído",
    error_texts: %{
      too_large: "Arquivo grande demais",
      not_accepted: "Tipo inválido",
      too_many_files: "Há arquivos demais, o limite é %{max}."
    }
  ]

  def mount(socket) do
    Enum.reduce(@names, socket, fn name, socket ->
      LiveView.allow_upload(socket, name, accept: :any, max_entries: 4, auto_upload: true)
    end)
  end

  def render(assigns) do
    uploads = assigns.uploads

    assigns =
      assign(assigns,
        texts: @texts,
        files: files(uploads.files),
        circle2: circle(uploads.circle2, "c2", 45, false),
        circle3: circle(uploads.circle3, "c3", 100, true),
        grid: grid(uploads.grid)
      )

    ~H"""
    <style>
      #circle-uploading .filepond--file-preview { background: linear-gradient(135deg, #a5b4fc, #4f46e5 70%); }
      #circle-complete .filepond--file-preview { background: linear-gradient(135deg, #6ee7b7, #0d9488 70%); }
      #grid-pond li:nth-child(1) .filepond--file-preview { background: linear-gradient(135deg, #a5b4fc, #6366f1); }
      #grid-pond li:nth-child(2) .filepond--file-preview { background: linear-gradient(135deg, #fcd34d, #f97316); }
      #grid-pond li:nth-child(3) .filepond--file-preview { background: linear-gradient(135deg, #6ee7b7, #0d9488); }
      #grid-pond li:nth-child(4) .filepond--file-preview { background: linear-gradient(135deg, #fda4af, #e11d48); }
    </style>

    <form id="canvas-form" phx-change="validate" class="flex flex-col gap-5">
      <div class="grid grid-cols-[repeat(auto-fit,minmax(min(100%,300px),1fr))] gap-5">
        <.example title="Ocioso" class="block" id="card-idle">
          <div class="flex flex-col gap-3.5">
            <.upload id="pond-plain" upload={@uploads.idle1} {@texts} class="!mb-0" />
            <.upload id="pond-bordered" upload={@uploads.idle2} bordered {@texts} class="!mb-0" />
            <.upload
              id="pond-focus"
              upload={@uploads.idle3}
              filled
              {@texts}
              class="!mb-0"
              phx-mounted={JS.focus(to: "#pond-focus [data-browse]")}
            />
          </div>
          <p class="mt-3 text-xs">
            A área também abre o seletor por teclado: Enter ou Espaço no rótulo. Aqui o terceiro mostra o anel de foco.
          </p>
        </.example>

        <.example title="Arrastando" class="block" id="card-drag">
          <div class="flex flex-col gap-3.5">
            <.upload
              id="pond-drag-bordered"
              upload={@uploads.drag1}
              bordered
              {@texts}
              class="!mb-0"
              data-dragging
            />
            <.upload
              id="pond-drag-filled"
              upload={@uploads.drag2}
              filled
              {@texts}
              class="!mb-0"
              data-dragging
            />
          </div>
          <p class="mt-3 text-xs">
            O hook marca a área enquanto há arquivo sobre ela e o fundo escurece. Contar entrada e saída dos filhos evita a piscada.
          </p>
        </.example>

        <.example title="Enviando, pronto e erro" class="block" id="card-files">
          <.upload id="pond-files" upload={@files} filled {@texts} class="!mb-0" />
          <p class="mt-3 text-xs">
            Cada linha tem remover, nome, tamanho, status e barra. Erros por arquivo aparecem na linha; os da lista, abaixo da área.
          </p>
        </.example>

        <.example title="layout circle" class="block" id="card-circle">
          <div class="flex flex-wrap items-center gap-5">
            <.upload
              id="circle-empty"
              upload={@uploads.circle1}
              layout="circle"
              bordered
              {@texts}
              class="!mb-0 w-28"
            >
              <:label>
                <.icon_image />
              </:label>
            </.upload>
            <.upload
              id="circle-uploading"
              upload={@circle2}
              layout="circle"
              {@texts}
              class="!mb-0 w-28"
            />
            <.upload
              id="circle-complete"
              upload={@circle3}
              layout="circle"
              {@texts}
              class="!mb-0 w-28"
            />
          </div>
          <p class="mt-3 text-xs">Um arquivo só, recortado em círculo; o tamanho vem do class.</p>
        </.example>
      </div>

      <.example title="columns 2: miniaturas de imagem" class="block" id="card-grid">
        <.upload id="grid-pond" upload={@grid} bordered columns={2} {@texts} class="!mb-0" />
      </.example>
      <.example title="upload_button: label com input invisível" class="block" id="card-buttons">
        <div class="flex flex-wrap items-center gap-3">
          <.upload_button upload={@uploads.btn} aria-label="Escolher arquivo">
            Escolher arquivo
          </.upload_button>
          <.upload_button name="b2" color="primary" aria-label="Enviar documento">
            <.icon_cloud /> Enviar documento
          </.upload_button>
          <.upload_button name="b3" color="primary" variant="outline" aria-label="Anexar">
            Anexar
          </.upload_button>
          <.upload_button name="b4" variant="outline" aria-label="Anexar">Anexar</.upload_button>
          <.upload_button
            name="b5"
            color="info"
            variant="glow"
            shape="pill"
            aria-label="Enviar imagem"
          >
            <.icon_image class="size-4" /> Imagem
          </.upload_button>
          <.upload_button name="b6" icon aria-label="Enviar" title="Enviar">
            <.icon_cloud />
          </.upload_button>
          <.upload_button
            name="b7"
            color="primary"
            aria-label="Com foco"
            class="outline-2 outline-solid outline-offset-2 outline-primary/50"
          >
            Com foco
          </.upload_button>
          <.upload_button name="b8" disabled aria-label="Desabilitado">Desabilitado</.upload_button>
        </div>
        <p class="mt-3 text-xs">
          solid, outline e glow em neutral, primary e info; shape pill e icon. O clique cai no input, que cobre o botão inteiro.
        </p>
      </.example>
    </form>
    """
  end

  defp files(config) do
    entries = [
      entry(config, "f1", "proposta-aurora.pdf", 1_800_000, "application/pdf", 62, false),
      entry(config, "f2", "contrato-assinado.pdf", 420_000, "application/pdf", 100, true),
      entry(
        config,
        "f3",
        "planilha-pedidos.xlsx",
        14_200_000,
        "application/vnd.ms-excel",
        0,
        false
      )
    ]

    %{config | entries: entries, errors: [{"f3", :too_large}, {config.ref, :too_many_files}]}
  end

  defp circle(config, ref, progress, done?) do
    %{config | entries: [entry(config, ref, "foto.png", 90_000, "image/png", progress, done?)]}
  end

  defp grid(config) do
    entries = [
      entry(config, "g1", "logo-clara.png", 210_000, "image/png", 100, true),
      entry(config, "g2", "banner-site.jpg", 1_200_000, "image/jpeg", 38, false),
      entry(config, "g3", "equipe.jpg", 880_000, "image/jpeg", 100, true),
      entry(config, "g4", "capa.png", 3_100_000, "image/png", 0, false)
    ]

    %{config | entries: entries, errors: [{"g4", :not_accepted}]}
  end

  defp entry(config, ref, name, size, type, progress, done?) do
    struct!(UploadEntry,
      ref: ref,
      upload_ref: config.ref,
      client_name: name,
      client_size: size,
      client_type: type,
      progress: progress,
      done?: done?,
      valid?: true,
      upload_config: config.name
    )
  end

  attr :class, :string, default: "size-8"

  defp icon_image(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.6"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class={@class}
    >
      <path d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
    </svg>
    """
  end

  defp icon_cloud(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.6"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class="size-4"
    >
      <path d="M12 16.5V9.75m0 0 3 3m-3-3-3 3M6.75 19.5a4.5 4.5 0 0 1-1.41-8.775 5.25 5.25 0 0 1 10.233-2.33 3 3 0 0 1 3.758 3.848A3.752 3.752 0 0 1 18 19.5H6.75Z" />
    </svg>
    """
  end
end
