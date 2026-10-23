defmodule PreviewWeb.Pages.NarrowExample do
  @moduledoc "`PreviewWeb.Page.example/1` with the `max-w-xl` description the overlay pages of LineOne use."

  use Phoenix.Component
  import PreviewWeb.Page, only: [example: 1]

  attr :title, :string, required: true
  attr :text, :string, required: true
  attr :class, :any, default: "mt-5"
  slot :inner_block, required: true

  def narrow(assigns) do
    ~H"""
    <.example title={@title} class="">
      <p class="max-w-xl">{@text}</p>
      <div class={@class}>{render_slot(@inner_block)}</div>
    </.example>
    """
  end
end
