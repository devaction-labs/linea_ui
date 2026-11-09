defmodule LineaUI.Components.Illustration do
  @moduledoc """
  The LineOne illustrations, drawn inline so the package needs no static images.

      <.empty_box class="h-28" />

  `empty_box` is the girl with a box that `notification_center` and `kanban_column` show when empty.
  `summit` is the landscape of `hero_card` (a snowy peak, green hills, a person looking at it); it
  fills its box, cropping the sides, so give it a width and a height.
  """

  use LineaUI.Component

  @empty_box_path Path.expand("../../../priv/illustrations/empty-girl-box.svg", __DIR__)
  @external_resource @empty_box_path
  @empty_box @empty_box_path
             |> File.read!()
             |> String.replace(
               ~r/<svg[^>]*>/,
               ~s(<svg viewBox="0 0 236 298" fill="none" xmlns="http://www.w3.org/2000/svg" class="CLASS" aria-hidden="true">),
               global: false
             )

  @summit_path Path.expand("../../../priv/illustrations/summit.svg", __DIR__)
  @external_resource @summit_path
  @summit @summit_path
          |> File.read!()
          |> String.replace(
            ~r/<svg[^>]*>/,
            ~s(<svg viewBox="0 0 640 320" fill="none" preserveAspectRatio="xMidYMax slice" xmlns="http://www.w3.org/2000/svg" class="CLASS" aria-hidden="true">),
            global: false
          )

  @doc """
  Renders the landscape (a snowy peak, hills, a person sitting), cropped to fill its box.
  """
  attr :class, :any, default: "h-full w-full"

  def summit(assigns) do
    assigns = assign(assigns, :svg, String.replace(@summit, "CLASS", Enum.join(List.wrap(assigns.class), " ")))

    ~H"""
    {Phoenix.HTML.raw(@svg)}
    """
  end

  @scenes for name <- ~w(voyage lighthouse balloons aurora), into: %{} do
             path = Path.expand("../../../priv/illustrations/#{name}.svg", __DIR__)
             @external_resource path

             svg =
               path
               |> File.read!()
               |> String.replace(
                 ~r/<svg[^>]*>/,
                 ~s(<svg viewBox="0 0 560 680" fill="none" preserveAspectRatio="POSITION slice" xmlns="http://www.w3.org/2000/svg" class="CLASS" role="img" aria-label="LABEL">),
                 global: false
               )

             {name, svg}
           end

  @doc """
  Renders one of the portrait scenes for the picture half of `auth_split` (or any tall picture), cropped to
  fill its box:

    * `voyage` — a sailing ship on the sea, clouds and palm leaves;
    * `lighthouse` — a lighthouse on a cliff at dusk, its beam over the sea;
    * `balloons` — hot air balloons over green hills in the morning;
    * `aurora` — the northern lights over snowy mountains and a cabin with its window lit.

  `position` is where the crop holds (`preserveAspectRatio`): `xMidYMid` (default), `xMidYMax` to keep the
  bottom, `xMinYMid` to keep the left. `label` is read by screen readers; leave it empty when the picture is
  only decoration.

      <.auth_split …><:art><.scene name="voyage" /></:art></.auth_split>
  """
  attr :name, :string, required: true, values: ~w(voyage lighthouse balloons aurora)
  attr :position, :string, default: "xMidYMid"
  attr :label, :string, default: ""
  attr :class, :any, default: "h-full w-full"

  def scene(assigns) do
    svg =
      @scenes
      |> Map.fetch!(assigns.name)
      |> String.replace("POSITION", assigns.position)
      |> String.replace("CLASS", Enum.join(List.wrap(assigns.class), " "))
      |> String.replace(~s(role="img" aria-label="LABEL"), label_attrs(assigns.label))

    assigns = assign(assigns, :svg, svg)

    ~H"""
    {Phoenix.HTML.raw(@svg)}
    """
  end

  defp label_attrs(""), do: ~s(aria-hidden="true")
  defp label_attrs(label), do: ~s(role="img" aria-label="#{Phoenix.HTML.html_escape(label) |> Phoenix.HTML.safe_to_string()}")

  @doc """
  Renders the girl with a box, for an empty area.
  """
  attr :class, :any, default: "h-36", doc: "Sets the size; the width follows the height."

  def empty_box(assigns) do
    assigns =
      assign(assigns, :svg, String.replace(@empty_box, "CLASS", "w-auto #{assigns.class}"))

    ~H"""
    {Phoenix.HTML.raw(@svg)}
    """
  end
end
