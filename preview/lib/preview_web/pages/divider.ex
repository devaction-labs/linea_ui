defmodule PreviewWeb.Pages.Divider do
  use PreviewWeb.Page, title: "Divider", category: :elements, lineone: "elements-divider"

  def render(assigns) do
    ~H"""
    <.example title="Divider Vertical" class="flex flex-col">
      <.content />
      <.divider>OR</.divider>
      <.content />
    </.example>

    <.example title="Without Text" class="flex flex-col">
      <.content />
      <.divider />
      <.content />
    </.example>

    <.example title="Divider Horizontal" class="flex">
      <.content />
      <.divider orientation="vertical">OR</.divider>
      <.content />
    </.example>

    <.example title="Without Text" class="flex">
      <.content />
      <.divider orientation="vertical" />
      <.content />
    </.example>
    """
  end

  defp content(assigns) do
    ~H"""
    <div class="flex h-20 w-full items-center justify-center rounded-lg bg-slate-200 dark:bg-navy-500">
      <.text size="xl">Content</.text>
    </div>
    """
  end
end
