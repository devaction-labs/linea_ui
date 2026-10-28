defmodule PreviewWeb.Pages.Collapse do
  use PreviewWeb.Page, title: "Collapse", category: :components, lineone: "components-collapse"
  import PreviewWeb.Pages.NarrowExample

  def render(assigns) do
    ~H"""
    <PreviewWeb.Pages.AccordionDemo.sections
      prefix="collapse"
      word="Collapse"
      text="The Collapse component allows the user to show and hide sections of related content on a page. Check out code for detail of usage."
      others="The collapse component allows the user to show and hide sections of related content on a page. Check out code for detail of usage."
      multiple={true}
    />

    <.narrow
      title="Variants"
      text="framed, flat and section give the trigger a look without writing its classes."
      class="mt-5"
    >
      <div class="max-w-md space-y-4">
        <.collapse id="cv-framed" variant="framed" chevron="down" open>
          <:trigger>Framed</:trigger>
          Ships in two days to any address in the country.
        </.collapse>
        <.collapse id="cv-flat" variant="flat" chevron="down">
          <:trigger>Flat</:trigger>
          Only a rule under the trigger.
        </.collapse>
        <.collapse id="cv-section" variant="section" chevron="down" open>
          <:trigger>Section</:trigger>
          A small uppercase label.
        </.collapse>
      </div>
    </.narrow>
    """
  end
end
