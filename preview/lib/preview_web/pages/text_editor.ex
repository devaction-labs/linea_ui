defmodule PreviewWeb.Pages.TextEditor do
  use PreviewWeb.Page, title: "Rich Text Editor", category: :forms, lineone: "forms-text-editor"

  def mount(socket), do: assign(socket, form: to_form(%{"body" => ""}, as: :post))

  def handle_event("post", %{"post" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :post))}

  def render(assigns) do
    ~H"""
    <.example title="Text Editor" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.form for={@form} id="editor1-form" phx-change="post">
          <.text_editor id="editor1" field={@form[:body]} placeholder="Enter your content..." />
        </.form>
      </div>
    </.example>
    <.example title="Minimal" class="max-w-xl">
      <.intro />
      <div class="mt-5 w-full">
        <.text_editor
          id="editor2"
          name="minimal"
          placeholder="Enter your content..."
          toolbar={[~w(bold italic underline), ~w(list-ordered list-bullet header-1 background)]}
        />
      </div>
    </.example>
    <.example title="Filled Header" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.text_editor id="editor3" name="filled" placeholder="Enter your content..." filled />
      </div>
    </.example>
    <.example title="Customizing" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.text_editor
          id="editor4"
          name="custom"
          placeholder="Enter your content..."
          filled
          toolbar={[
            ~w(bold italic underline strike),
            ~w(blockquote code-block),
            ~w(header),
            ~w(color background),
            ~w(clean)
          ]}
        />
      </div>
    </.example>
    """
  end

  defp intro(assigns) do
    ~H"""
    <p>
      The textarea provides a native and essential solution to almost any web application. But at some point you may need to add formatting to text input.
      <a
        href="https://github.com/quilljs/quill/"
        class="text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
      >Quill</a>
      is a free, open source WYSIWYG editor built for the modern web.
    </p>
    """
  end
end
