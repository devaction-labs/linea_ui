defmodule LineaUI.Components.Spinner do
  @moduledoc """
  daisyUI's loading indicator (`loading loading-spinner`, `loading-ring`, `loading-ball`), in every size and
  theme color.

      <.spinner />
      <.spinner color="primary" variant="soft" elastic />
      <.spinner color="success" variant="grow" size="lg" />
      <.spinner color="error" variant="svg" />

  `size` is daisyUI's `loading-xs` to `loading-xl`. In a button, a `current` spinner takes the text color of the
  button and sits before its label:

      <.button disabled>
        <.spinner color="current" size="xs" label="Saving" /> Saving
      </.button>

  Over a block that loads, the spinner is centered on a veil that covers it:

      <div class="relative">
        …the content…
        <div class="absolute inset-0 grid place-items-center bg-base-100/70">
          <.spinner color="primary" size="md" />
        </div>
      </div>
  """

  use LineaUI.Component

  @doc """
  Renders a spinner (`role="status"`, labelled by `label`).

      <.spinner color="primary" variant="soft" size="md" elastic />
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current),
    doc: "`white` and `current` (the text color) are for spinners inside filled buttons."
  )

  attr(:variant, :string,
    default: "canvas",
    values: ~w(canvas border soft grow svg),
    doc:
      "daisyUI's `loading`: `canvas`, `border` and `soft` are `loading-spinner`, `grow` is `loading-ring` and `svg` is `loading-ball`; the color is the text color (`current` keeps the parent's)."
  )

  attr(:size, :string,
    default: "sm",
    values: ~w(xs sm md lg xl),
    doc: "daisyUI's `loading-xs` to `loading-xl`."
  )

  attr(:elastic, :boolean, default: false, doc: "LineOne's elastic timing function.")
  attr(:label, :string, default: "Loading")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def spinner(assigns) do
    ~H"""
    <span
      role="status"
      aria-label={@label}
      class={
        merge([
          "loading",
          kind(@variant),
          "loading-#{@size}",
          color_class(@color),
          @elastic && "[animation-timing-function:cubic-bezier(.53,.21,.29,.67)]",
          @class
        ])
      }
      {@rest}
    ></span>
    """
  end

  defp kind("grow"), do: "loading-ring"
  defp kind("svg"), do: "loading-ball"
  defp kind(_spinner), do: "loading-spinner"

  defp color_class(color) when color in ~w(primary secondary info success warning error),
    do: "text-" <> color

  defp color_class("white"), do: "text-white"
  defp color_class("current"), do: nil
  defp color_class(_neutral), do: "text-base-content/60"
end
