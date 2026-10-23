defmodule PreviewWeb.Pages.Accordion do
  use PreviewWeb.Page, title: "Accordion", category: :components, lineone: "components-accordion"

  @text "The accordion component allows the user to show and hide sections of related content on a page. Check out code for detail of usage."

  def render(assigns) do
    assigns = assign(assigns, text: @text)

    ~H"""
    <PreviewWeb.Pages.AccordionDemo.sections
      prefix="accordion"
      word="Accordion"
      text={@text}
      others={@text}
      multiple={false}
    />
    """
  end
end
