defmodule LineaUI.Components.Upload do
  @moduledoc """
  LineOne's file uploads, built on LiveView uploads: the drop panel of its FilePond demos
  (bordered, filled, in a grid, or a round avatar drop) with each file's progress, errors and
  cancel button, and the styled "Choose File" buttons of its Input File demo.

      # mount
      socket |> allow_upload(:photos, accept: ~w(.jpg .png), max_entries: 4)

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.upload upload={@uploads.photos} on_cancel="cancel-upload" bordered columns={2} />
      </.form>

      def handle_event("cancel-upload", %{"ref" => ref}, socket),
        do: {:noreply, cancel_upload(socket, :photos, ref)}

  The component renders `live_file_input` itself, so it must be inside the form that has the
  `phx-change` LiveView uploads need.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @error_texts %{
    too_large: "File is too large",
    not_accepted: "File of invalid type",
    too_many_files: "Too many files",
    external_client_failure: "Upload failed"
  }

  @doc """
  Renders the drop panel and the list of chosen files.

      <.upload upload={@uploads.avatar} layout="circle" bordered class="w-28" on_cancel="cancel">
        <:label><svg>…</svg></:label>
      </.upload>

  Events: the remove button of a file pushes `on_cancel` with `%{"ref" => entry_ref}` (to
  `target` when given); answer with `cancel_upload/3`.
  """
  attr :upload, Phoenix.LiveView.UploadConfig, required: true, doc: "`@uploads.name`."
  attr :id, :string, default: nil, doc: "Defaults to `<upload ref>-pond`."
  attr :bordered, :boolean, default: false, doc: "A dashed border (LineOne's `fp-bordered`)."
  attr :filled, :boolean, default: false, doc: "A filled panel (LineOne's `fp-bg-filled`)."

  attr :columns, :integer,
    default: 1,
    values: [1, 2, 3, 4],
    doc: "Files side by side, as LineOne's Two/Three/Four Grid."

  attr :layout, :string,
    default: "panel",
    values: ~w(panel circle),
    doc:
      "`circle` is the round single-file drop of LineOne's Circle Filepond; size it with `class`."

  attr :on_cancel, :any, default: nil, doc: "Event (or `%JS{}`) of the remove button."
  attr :target, :any, default: nil
  attr :previews, :boolean, default: true, doc: "A thumbnail for image files."

  attr :error_texts, :map,
    default: @error_texts,
    doc:
      "The text of each upload error atom. `%{max}` in a text is replaced by the `max_entries` of the upload (\"Only %{max} files\")."

  attr :browse_label, :string, default: "Browse"
  attr :drop_label, :string, default: "Drag & Drop your files or"
  attr :remove_label, :string, default: "Remove"
  attr :uploading_label, :string, default: "Uploading"
  attr :complete_label, :string, default: "Upload complete"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :label, doc: "Replaces the text of the drop panel (the circle layout shows an icon)."

  def upload(assigns) do
    assigns
    |> assign(:id, assigns.id || "#{assigns.upload.ref}-pond")
    |> assign(:upload_errors, Phoenix.Component.upload_errors(assigns.upload))
    |> render_upload()
  end

  defp render_upload(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.Upload"
      phx-drop-target={@upload.ref}
      class={
        merge([
          "filepond filepond--root",
          @bordered && "fp-bordered",
          @filled && "fp-bg-filled",
          @columns > 1 && "fp-grid",
          grid_var(@columns),
          @layout == "circle" && "label-icon",
          @class
        ])
      }
      data-layout={@layout}
      {@rest}
    >
      <div class="filepond--panel-root"></div>
      <div
        :if={@layout != "circle" or @upload.entries == []}
        class="filepond--drop-label"
        role="button"
        tabindex="0"
        data-browse
      >
        <label for={@upload.ref}>
          {render_slot(@label) ||
            default_label(%{drop: @drop_label, browse: @browse_label})}
        </label>
      </div>
      <.live_file_input upload={@upload} class="sr-only" tabindex="-1" />
      <ul :if={@upload.entries != []} class="filepond--list" role="list">
        <li
          :for={entry <- @upload.entries}
          class="filepond--item"
          data-state={state(@upload, entry)}
          id={"#{@id}-#{entry.ref}"}
        >
          <div class="filepond--item-panel"></div>
          <div class="filepond--file">
            <button
              type="button"
              class="filepond--file-action-button"
              title={@remove_label}
              aria-label={@remove_label}
              phx-click={@on_cancel}
              phx-value-ref={entry.ref}
              phx-target={@target}
            >
              <.glyph name={:close_solid} class={nil} />
            </button>
            <.live_img_preview
              :if={@previews and image?(entry)}
              entry={entry}
              class="filepond--file-preview"
            />
            <div class="filepond--file-info">
              <span class="filepond--file-info-main" title={entry.client_name}>
                {entry.client_name}
              </span>
              <span class="filepond--file-info-sub">{size(entry.client_size)}</span>
            </div>
            <div class="filepond--file-status">
              <span class="filepond--file-status-main">
                {status(@upload, entry, assigns)}
              </span>
              <span
                :if={not entry.done? and entry_errors(@upload, entry) == []}
                class="filepond--file-status-sub"
              >
                {entry.progress}%
              </span>
            </div>
            <div
              :if={not entry.done? and entry_errors(@upload, entry) == []}
              class="filepond--progress"
              role="progressbar"
              aria-valuenow={entry.progress}
              aria-valuemin="0"
              aria-valuemax="100"
            >
              <span style={"width: #{entry.progress}%"}></span>
            </div>
          </div>
        </li>
      </ul>
      <ul :if={@upload_errors != []} class="filepond--errors">
        <li :for={error <- @upload_errors}>
          {error_text(@error_texts, error, @upload.max_entries)}
        </li>
      </ul>
    </div>
    """
  end

  defp default_label(assigns) do
    ~H"""
    {@drop} <span class="filepond--label-action">{@browse}</span>
    """
  end

  defp grid_var(2), do: "[--fp-grid:2]"
  defp grid_var(3), do: "[--fp-grid:3]"
  defp grid_var(4), do: "[--fp-grid:4]"
  defp grid_var(_columns), do: nil

  defp entry_errors(upload, entry), do: Phoenix.Component.upload_errors(upload, entry)

  defp state(upload, entry) do
    cond do
      entry_errors(upload, entry) != [] -> "error"
      entry.done? -> "complete"
      true -> "processing"
    end
  end

  defp status(upload, entry, assigns) do
    case {entry_errors(upload, entry), entry.done?} do
      {[error | _], _done} -> error_text(assigns.error_texts, error, upload.max_entries)
      {[], true} -> assigns.complete_label
      {[], false} -> assigns.uploading_label
    end
  end

  defp error_text(texts, error, max),
    do: texts |> Map.get(error, to_string(error)) |> String.replace("%{max}", to_string(max))

  defp image?(%{client_type: "image/" <> _}), do: true
  defp image?(_entry), do: false

  defp size(bytes) when bytes < 1000, do: "#{bytes} bytes"
  defp size(bytes) when bytes < 1_000_000, do: "#{Float.round(bytes / 1000, 1)} KB"
  defp size(bytes), do: "#{Float.round(bytes / 1_000_000, 1)} MB"

  @button_styles %{
    {"solid", "neutral"} =>
      "bg-slate-150 text-slate-800 hover:bg-slate-200 focus:bg-slate-200 active:bg-slate-200/80 dark:bg-navy-500 dark:text-navy-50 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
    {"solid", "primary"} =>
      "bg-primary text-white hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90",
    {"solid", "info"} =>
      "bg-info text-white hover:bg-info-focus focus:bg-info-focus active:bg-info-focus/90",
    {"outline", "neutral"} =>
      "border border-slate-300 text-slate-600 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80 dark:border-navy-450 dark:text-navy-100 dark:hover:bg-navy-500 dark:focus:bg-navy-500 dark:active:bg-navy-500/90",
    {"outline", "primary"} =>
      "border border-primary text-primary hover:bg-primary hover:text-white focus:bg-primary focus:text-white active:bg-primary/90 dark:border-accent dark:text-accent-light dark:hover:bg-accent dark:hover:text-white dark:focus:bg-accent dark:focus:text-white dark:active:bg-accent/90",
    {"outline", "info"} =>
      "border border-info text-info hover:bg-info hover:text-white focus:bg-info focus:text-white active:bg-info/90",
    {"glow", "neutral"} =>
      "bg-slate-150 text-slate-800 hover:bg-slate-200 hover:shadow-lg hover:shadow-slate-200/50 focus:bg-slate-200 active:bg-slate-200/80 dark:bg-navy-500 dark:text-navy-50 dark:hover:bg-navy-450 dark:hover:shadow-navy-450/50 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
    {"glow", "primary"} =>
      "bg-primary text-white hover:bg-primary-focus hover:shadow-lg hover:shadow-primary/50 focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:hover:shadow-accent/50 dark:focus:bg-accent-focus dark:active:bg-accent/90",
    {"glow", "info"} =>
      "bg-info text-white hover:bg-info-focus hover:shadow-lg hover:shadow-info/50 focus:bg-info-focus active:bg-info-focus/90"
  }

  @doc """
  A button that opens the file chooser: LineOne's Input File, a `<label class="btn">` holding an
  invisible file input.

      <.upload_button upload={@uploads.avatar}>Choose File</.upload_button>
      <.upload_button name="doc" color="info" variant="glow" icon shape="pill" aria-label="Upload">
        <svg>…</svg>
      </.upload_button>

  With `upload` it renders `live_file_input`; otherwise a plain `<input type="file" name>`. The
  button shows a 2px primary outline while its input has keyboard focus.
  """
  attr :upload, Phoenix.LiveView.UploadConfig, default: nil
  attr :name, :string, default: nil, doc: "Name of the plain file input, without `upload`."
  attr :multiple, :boolean, default: false, doc: "Plain input only."
  attr :accept, :string, default: nil, doc: "Plain input only."

  attr :disabled, :boolean,
    default: false,
    doc: "Disables the input and dims the button (no pointer events)."

  attr :color, :string, default: "neutral", values: ~w(neutral primary info)
  attr :variant, :string, default: "solid", values: ~w(solid outline glow)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :icon, :boolean, default: false, doc: "A square button that holds only an icon."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def upload_button(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        merge([
          "btn relative font-medium",
          @button_styles[{assigns.variant, assigns.color}],
          "has-[input:focus-visible]:outline-2 has-[input:focus-visible]:outline-offset-2 has-[input:focus-visible]:outline-primary",
          assigns.icon && "size-9 p-0",
          assigns.disabled && "pointer-events-none opacity-55",
          assigns.shape == "pill" && "rounded-full",
          assigns.class
        ])
      )

    ~H"""
    <label class={@classes} {@rest}>
      <.live_file_input
        :if={@upload}
        upload={@upload}
        disabled={@disabled}
        tabindex="-1"
        class="pointer-events-none absolute inset-0 h-full w-full opacity-0"
      />
      <input
        :if={!@upload}
        type="file"
        name={@name}
        multiple={@multiple}
        accept={@accept}
        disabled={@disabled}
        tabindex="-1"
        class="pointer-events-none absolute inset-0 h-full w-full opacity-0"
      />
      {render_slot(@inner_block)}
    </label>
    """
  end
end
