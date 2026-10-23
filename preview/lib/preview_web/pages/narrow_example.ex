defmodule PreviewWeb.Pages.NarrowExample do
  @moduledoc "`PreviewWeb.Page.example/1` with the `max-w-xl` body the overlay pages of LineOne use."

  use Phoenix.Component
  import PreviewWeb.Page, only: [example: 1]

  attr :title, :string, required: true
  attr :text, :string, required: true
  attr :class, :any, default: "mt-5"

  attr :wide, :boolean,
    default: false,
    doc: "Only the text is `max-w-xl` (the modal and drawer pages)."

  slot :lead, doc: "Inline content before the text."
  slot :inner_block, required: true

  def narrow(assigns) do
    ~H"""
    <.example title={@title} class="">
      <div class={!@wide && "max-w-xl"}>
        <p class="max-w-xl">{render_slot(@lead)}{@text}</p>
        <div class={@class}>{render_slot(@inner_block)}</div>
      </div>
    </.example>
    """
  end
end
