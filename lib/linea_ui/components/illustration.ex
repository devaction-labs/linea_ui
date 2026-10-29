defmodule LineaUI.Components.Illustration do
  @moduledoc """
  The LineOne illustrations, drawn inline so the package needs no static images.

      <.empty_box class="h-28" />

  `empty_box` is the girl with a box that `notification_center` and `kanban_column` show when empty.
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
