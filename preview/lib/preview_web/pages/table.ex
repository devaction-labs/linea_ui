defmodule PreviewWeb.Pages.Table do
  use PreviewWeb.Page, title: "Table", category: :components, lineone: "components-table"

  @text "Tables display information in a way that's easy to scan, so that users can look for patterns and insights. Check out code for detail of usage."

  @people [
    %{id: 1, name: "Cy Ganderton", job: "Quality Control Specialist", color: "Blue"},
    %{id: 2, name: "Hart Hagerty", job: "Desktop Support Technician", color: "Purple"},
    %{id: 3, name: "Brice Swyre", job: "Tax Accountant", color: "Red"},
    %{id: 4, name: "Marjy Ferencz", job: "Office Assistant I", color: "Crimson"}
  ]

  def mount(socket), do: Phoenix.LiveView.stream(socket, :people, @people)

  def render(assigns) do
    assigns = assign(assigns, text: @text, people: @people)

    ~H"""
    <.example title="Basic Table" text={@text} class="mt-5">
      <.people id="basic-table" rows={@people} />
    </.example>
    <.example title="Bordered Table" text={@text} class="mt-5">
      <.people id="bordered-table" rows={@people} variant="bordered" />
    </.example>
    <.example title="Hoverable Rows" text={@text} class="mt-5">
      <.people id="hoverable-table" rows={@people} variant="hoverable" />
    </.example>
    <.example title="Zebra Table" text={@text} class="mt-5">
      <.people id="zebra-table" rows={@people} variant="zebra" />
    </.example>
    <.example title="Full Width Table" text={@text} class="mt-5 -mx-4 sm:-mx-5">
      <.people id="full-table" rows={@streams.people} variant="hoverable" rounded="none" />
    </.example>
    <.example title="Full Width Zebra Table" text={@text} class="mt-5 -mx-4 sm:-mx-5">
      <.people id="full-zebra-table" rows={@people} variant="zebra" rounded="none" />
    </.example>
    """
  end

  attr :id, :string, required: true
  attr :rows, :any, required: true
  attr :variant, :string, default: "basic"
  attr :rounded, :string, default: "row"

  defp people(assigns) do
    ~H"""
    <.table id={@id} rows={@rows} variant={@variant} rounded={@rounded} row_item={&person/1}>
      <:col :let={person} label="#">{person.id}</:col>
      <:col :let={person} label="Name">{person.name}</:col>
      <:col :let={person} label="Job">{person.job}</:col>
      <:col :let={person} label="Favorite Color">{person.color}</:col>
    </.table>
    """
  end

  defp person({_dom_id, person}), do: person
  defp person(person), do: person
end
