defmodule PreviewWeb.Pages.Collapse do
  use PreviewWeb.Page, title: "Collapse", category: :components, lineone: "components-collapse"

  def render(assigns) do
    ~H"""
    <PreviewWeb.Pages.AccordionDemo.sections
      prefix="collapse"
      word="Collapse"
      text="The Collapse component allows the user to show and hide sections of related content on a page. Check out code for detail of usage."
      others="The collapse component allows the user to show and hide sections of related content on a page. Check out code for detail of usage."
      multiple={true}
    />
    """
  end
end
