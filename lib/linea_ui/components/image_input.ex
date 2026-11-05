defmodule LineaUI.Components.ImageInput do
  @moduledoc """
  An image field: the picture (an avatar, a logo) in a round or rounded frame with a camera strip at the bottom and a
  small button to remove or revert it.

      <.image_input name="avatar" value={@user.avatar_url} size="lg" />

  Clicking the picture opens the file picker. The chosen file shows at once (the hook `LineaUI.ImageInput` reads it);
  the button then puts the first picture back, and, with nothing chosen, empties the field and sets the hidden
  `<name>_remove` input to `1` so the form can tell it was removed. The frame has a green edge while it holds a
  picture and the field edge while it is empty.
  """

  use LineaUI.Component

  @sizes %{"sm" => "size-12", "md" => "size-16", "lg" => "size-24", "xl" => "size-32"}
  @shapes %{"circle" => "rounded-full", "rounded" => "rounded-xl"}

  @doc """
  Renders the image field.

      <.image_input name="logo" value="/images/logo.png" shape="rounded" />
  """
  attr :id, :string, default: nil, doc: "Defaults to `name`."

  attr :name, :string,
    required: true,
    doc: "The name of the file input; `<name>_remove` is the hidden one."

  attr :value, :string, default: nil, doc: "The address of the picture it holds now."
  attr :accept, :string, default: ".png,.jpg,.jpeg,.webp"
  attr :size, :string, default: "md", values: ~w(sm md lg xl)
  attr :shape, :string, default: "circle", values: ~w(circle rounded)
  attr :label, :string, default: "Choose a picture", doc: "The accessible name of the picker."
  attr :remove_label, :string, default: "Remove or revert the picture"
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  def image_input(assigns) do
    assigns =
      assign(assigns,
        id: assigns.id || assigns.name,
        size_class: @sizes[assigns.size],
        shape_class: @shapes[assigns.shape]
      )

    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.ImageInput"
      phx-mounted={JS.ignore_attributes(["data-state", "data-initial"])}
      data-state={(@value && "filled") || "empty"}
      data-initial={@value}
      class={merge(["group/img relative inline-block", @size_class, @class])}
      {@rest}
    >
      <input
        type="file"
        id={@id <> "-file"}
        name={@name}
        accept={@accept}
        disabled={@disabled}
        class="sr-only"
        data-file
      />
      <input type="hidden" name={@name <> "_remove"} value="" data-remove-flag />
      <label
        for={@id <> "-file"}
        aria-label={@label}
        data-frame
        style={@value && "background-image: url('#{@value}')"}
        class={
          merge([
            "relative block size-full cursor-pointer overflow-hidden border-2 bg-slate-100 bg-cover bg-center transition-colors dark:bg-navy-600",
            "border-slate-200 group-data-[state=filled]/img:border-success dark:border-navy-450 dark:group-data-[state=filled]/img:border-success",
            @shape_class
          ])
        }
      >
        <span class="absolute inset-x-0 bottom-0 flex h-5 items-center justify-center bg-black/25 text-white/80">
          <svg viewBox="0 0 14 12" class="h-3 w-3.5 fill-current" aria-hidden="true">
            <path d="M11.67 2.65h-.44a.66.66 0 0 1-.65-.4l-.53-1.05A1.6 1.6 0 0 0 8.6.31H5.39A1.6 1.6 0 0 0 3.95 1.2l-.52 1.05a.66.66 0 0 1-.65.4h-.44A1.6 1.6 0 0 0 .73 4.25v5.83a1.6 1.6 0 0 0 1.6 1.6h9.34a1.6 1.6 0 0 0 1.6-1.6V4.25a1.6 1.6 0 0 0-1.6-1.6ZM7 9.65a3.06 3.06 0 1 1 0-6.12 3.06 3.06 0 0 1 0 6.12Z" />
            <circle cx="7" cy="6.58" r="2.19" />
          </svg>
        </span>
      </label>
      <button
        type="button"
        data-remove
        aria-label={@remove_label}
        title={@remove_label}
        class="absolute -end-1.5 -top-1.5 z-10 hidden size-5 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-600 shadow-xs outline-none hover:text-slate-950 focus-visible:ring-2 focus-visible:ring-primary/50 group-data-[state=filled]/img:flex dark:border-navy-450 dark:bg-navy-900 dark:text-navy-200"
      >
        <svg
          viewBox="0 0 24 24"
          class="size-3"
          fill="none"
          stroke="currentColor"
          stroke-width="2.5"
          stroke-linecap="round"
          aria-hidden="true"
        >
          <path d="M6 6l12 12M18 6 6 18" />
        </svg>
      </button>
    </div>
    """
  end
end
