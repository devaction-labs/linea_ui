defmodule PreviewWeb.Pages.Tag do
  use PreviewWeb.Page, title: "Tag", category: :elements, lineone: "elements-tag"

  @colors ~w(neutral primary secondary info success warning error)

  def render(assigns) do
    assigns = assign(assigns, :colors, @colors)

    ~H"""
    <.example
      title="Tag"
      text="Tags are compact elements that represent an input, attribute, or action. tags allow users to enter information, make selections, filter content, or trigger actions. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.tag :for={color <- @colors ++ ["light"]} href="#" color={color}>{color_label(color)}</.tag>
    </.example>

    <.example title="Rounded Tag" class="">
      <.text class="max-w-2xl">
        Tags can have a rounded-sm shape. To do this, you should use the
        <.inline_code>rounded-full</.inline_code>
        utility Check out code for detail of usage.
      </.text>
      <div class="inline-space mt-5">
        <.tag :for={color <- @colors ++ ["light"]} href="#" color={color} shape="pill">
          {color_label(color)}
        </.tag>
      </div>
    </.example>

    <.example
      title="Bordered Tag"
      text="Tags can have a border. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.tag :for={color <- tl(@colors)} href="#" color={color} variant="bordered" shape="pill">
        {color_label(color)}
      </.tag>
    </.example>

    <.example
      title="Tag Group"
      text="Tag group are an easy way to group a series of tags together. Check out code for detail of usage."
      class="inline-space mt-5 flex flex-wrap"
    >
      <.tag_group>
        <.tag href="#">Primary</.tag>
        <.tag href="#" color="primary">55</.tag>
      </.tag_group>
      <.tag_group>
        <.tag href="#" color="info" variant="soft">Message</.tag>
        <.tag href="#" color="info">65</.tag>
      </.tag_group>
      <.tag_group>
        <.tag href="#" color="warning" variant="outline" shape="pill">Warnings</.tag>
        <.tag
          href="#"
          color="warning"
          variant="bordered"
          shape="pill"
          class="border-warning"
        >
          35
        </.tag>
      </.tag_group>
      <.tag_group>
        <.tag href="#" color="success" variant="soft">Message</.tag>
        <.badge color="success" class="shadow-lg shadow-success/50">14</.badge>
      </.tag_group>
      <.tag_group>
        <.tag href="#" class="px-4">Star</.tag>
        <.tag href="#" color="secondary" aria-label="Star">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-4"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
          </svg>
        </.tag>
      </.tag_group>
      <.tag_group>
        <.badge color="error" variant="outline">Remove</.badge>
        <.tag href="#" color="error" aria-label="Remove">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </.tag>
      </.tag_group>
      <.badge id="biking" shape="pill" on_remove={JS.hide(to: "#biking")}>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-4 text-slate-600 dark:text-navy-200"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path d="M13 4.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM4.5 11a3.5 3.5 0 100 7 3.5 3.5 0 000-7zm0 1.5a2 2 0 110 4 2 2 0 010-4zm11-1.5a3.5 3.5 0 100 7 3.5 3.5 0 000-7zm0 1.5a2 2 0 110 4 2 2 0 010-4zM9.3 7.2a1 1 0 011.4.1l1.6 1.9h2.2a.75.75 0 010 1.5h-2.55a.75.75 0 01-.57-.27l-.86-1.02-1.4 1.4 1.66 1.24a.75.75 0 01.3.6V16a.75.75 0 01-1.5 0v-3.1L7.2 11.4a1 1 0 01-.1-1.5l2.2-2.7z" />
        </svg>
        <span>Default</span>
      </.badge>
    </.example>
    """
  end

  defp color_label("neutral"), do: "Default"
  defp color_label(color), do: String.capitalize(color)
end
