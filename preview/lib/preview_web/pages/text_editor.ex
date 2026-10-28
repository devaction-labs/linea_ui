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

    <.example
      title="Image, variable and highlight"
      text="Opt-in buttons: an inline field for the picture address, a menu of variables, and a toggle for the highlight."
      class="max-w-xl"
    >
      <.text_editor
        id="media-editor"
        name="media"
        variables={~w(cliente preço vendedor)}
        toolbar={[~w(bold italic underline mark), ~w(link image variable), ~w(clean)]}
        tool_labels={%{"image" => "Imagem", "variable" => "Variável", "mark" => "Destacar"}}
        image_label="Endereço da imagem:"
        image_alt_label="Descrição"
        image_save_label="Inserir"
        variable_title="Inserir variável"
        value="<p>Analgésico de <b>venda livre</b>, <mark>validade mínima de 18 meses</mark> na entrega para {cliente}.</p>"
        content_class="h-40"
      />
    </.example>

    <.example
      title="Commands, variables and comments"
      text="The / menu, {variables} as chips, the assistant, a footer with the word count, and the compact comment editor."
      class="mt-5 grid items-start gap-6 lg:grid-cols-2"
    >
      <.text_editor
        id="signetum-editor"
        name="description"
        label="Product description"
        slash
        variables={~w(cliente preço)}
        footer
        hint="Type / for the commands"
        on_ai="write"
        value="<p>Price for {cliente}: {preço} a box</p>"
        content_class="h-40"
      >
        <:ai>Write with the assistant</:ai>
      </.text_editor>
      <.text_editor
        id="signetum-comment"
        name="comment"
        variant="comment"
        on_submit="comment"
        placeholder="Write a comment. @ mentions, Ctrl+Enter sends"
        mentions={[
          %{handle: "juliana-moraes", label: "Juliana Moraes"},
          %{handle: "carlos-lima", label: "Carlos Lima"}
        ]}
      />
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
