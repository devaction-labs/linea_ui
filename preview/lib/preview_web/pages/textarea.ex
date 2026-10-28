defmodule PreviewWeb.Pages.Textarea do
  use PreviewWeb.Page, title: "Textarea", category: :forms, lineone: "forms-textarea"

  import PreviewWeb.FormIcons

  def render(assigns) do
    ~H"""
    <.example
      title="Basic Textarea"
      text="The Textarea defines a multi-line text input control. The Textarea is often used in a form, to collect user inputs like comments or reviews."
      class="mt-5 max-w-xl"
    >
      <.textarea name="basic" placeholder=" Enter Text" />
    </.example>
    <.example
      title="Filled Textarea"
      text="The Textarea can be filled. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.textarea name="filled" variant="filled" placeholder=" Enter Text" />
    </.example>
    <.example
      title="Resizeabele Textarea"
      text="The textarea can be resizeabele. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.textarea name="resizable" resizable placeholder=" Enter Text" />
    </.example>
    <.example
      title="Counter"
      text="counter shows the characters typed, updated without a server round trip. maxlength gives the limit; it warns near it and turns red past it."
      class="mt-5 max-w-xl"
    >
      <.textarea
        name="counter"
        label="Description"
        help="Shown in reports."
        maxlength={200}
        counter
        rows={3}
        value="Review the project scope with Ana Souza before Thursday's meeting."
      />
    </.example>
    <.example
      title="Minimum Counter"
      text="min_length makes the counter ask for a minimum while the text is shorter."
      class="mt-5 max-w-xl"
    >
      <.textarea
        name="minimum"
        label="Justification"
        counter
        min_length={20}
        rows={3}
        value="Ok"
        errors={["Write at least 20 characters."]}
      />
    </.example>
    <.example
      title="Autogrow Textarea"
      text="autogrow follows the text from rows up to max_rows lines, then scrolls."
      class="mt-5 max-w-xl"
    >
      <.textarea name="autogrow" autogrow max_rows={8} rows={2} counter placeholder="Keep typing" />
    </.example>
    <.example
      title="Disabled Textarea"
      text="The textarea have their own style when disabled. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.textarea name="disabled" disabled class="px-3 py-2" placeholder=" Enter Text" />
    </.example>
    <.example
      title="With Header"
      text="The textare can have header. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.textarea name="with-header" rows={5} placeholder="Enter Text">
        <:header><.title_bar name="header-title" /></:header>
      </.textarea>
    </.example>
    <.example
      title="With Footer"
      text="The textare can have footer. Check out code for detail of usage."
      class="mt-5 flex max-w-xl space-x-4 overflow-x-auto"
    >
      <div class="avatar size-12">
        <img class="rounded-full" src="/lineone/images/avatar/avatar-20.jpg" alt="avatar" />
        <div class="absolute right-0 size-3.5 rounded-full border-2 border-white bg-info dark:border-navy-700">
        </div>
      </div>
      <.textarea
        name="with-footer"
        rows={5}
        placeholder="Write a comment"
        wrapper_class="w-full"
        frame_class="rounded-xl rounded-tl-none"
      >
        <:footer>
          <div class="flex items-end space-x-1">
            <.tool_button icon="clip" class="-ml-1" />
            <.tool_button icon="mic" />
            <.tool_button icon="smile" />
          </div>
          <.button color="primary" size="sm" class="h-auto">Comment</.button>
        </:footer>
      </.textarea>
    </.example>
    <.example
      title="With Header & Footer"
      text="The textare can have header and footer. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.textarea name="with-both" rows={5} placeholder="Write the post">
        <:header><.title_bar name="both-title" /></:header>
        <:footer>
          <div class="flex items-end space-x-1">
            <.tool_button icon="clip" class="-ml-1" />
            <.tool_button icon="at" class="-ml-1" />
          </div>
          <.button color="primary" variant="glow" size="sm" class="h-auto">Save Post</.button>
        </:footer>
      </.textarea>
    </.example>
    """
  end

  attr :name, :string, required: true

  defp title_bar(assigns) do
    ~H"""
    <label class="block w-full">
      <.input name={@name} variant="plain" class="p-3 text-lg font-medium" placeholder="Title" />
    </label>
    <div class="p-2">
      <.button variant="flat" icon shape="pill" class="size-8 text-current" aria-label="More">
        <.lineone_icon name="dots" class="size-5" stroke="2" />
      </.button>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :class, :any, default: nil

  defp tool_button(assigns) do
    ~H"""
    <.button
      variant="flat"
      icon
      shape="pill"
      class={["size-8 text-current", @class]}
      aria-label={@icon}
    >
      <.lineone_icon name={@icon} class="size-5" />
    </.button>
    """
  end
end
