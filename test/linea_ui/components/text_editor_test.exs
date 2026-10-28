defmodule LineaUI.Components.TextEditorTest do
  use LineaUI.ComponentCase, async: true

  test "LineOne's full toolbar, the editable area and the hidden input" do
    html =
      render(
        ~H|<.text_editor id="e" name="body" value="<p>Hi</p>" placeholder="Enter your content..." />|
      )

    assert find(html, "#e[phx-hook='LineaUI.TextEditor']") |> Enum.count() == 1
    assert html |> find("#e") |> LazyHTML.attribute("data-value") == ["<p>Hi</p>"]
    assert find(html, "#e .ql-toolbar.ql-snow .ql-formats") |> Enum.count() == 13
    assert find(html, "#e button.ql-bold[data-tool=bold] svg") |> Enum.count() == 1
    assert find(html, "#e button.ql-header[data-tool=header-1]") |> Enum.count() == 1

    assert find(html, "#e .ql-header.ql-picker[data-picker=header] .ql-picker-item")
           |> Enum.count() == 7

    assert find(html, "#e .ql-color.ql-color-picker .ql-picker-item") |> Enum.count() == 35
    assert find(html, "#e .ql-align.ql-icon-picker .ql-picker-item svg") |> Enum.count() == 4

    assert find(
             html,
             "#e-container.ql-container.h-48[phx-update=ignore] [data-editor][contenteditable=true]"
           )
           |> Enum.count() == 1

    assert html |> find("[data-editor]") |> LazyHTML.attribute("data-placeholder") == [
             "Enter your content..."
           ]

    assert find(html, "input[type=hidden][name=body][value='<p>Hi</p>']") |> Enum.count() == 1
  end

  test "a custom toolbar, filled header, height and disabled" do
    html =
      render(~H"""
      <.text_editor
        id="e"
        name="b"
        toolbar={[~w(bold link), ~w(size)]}
        filled
        content_class="h-72"
        disabled
      />
      """)

    assert find(html, "#e.ql-header-filled") |> Enum.count() == 1
    assert html |> find("#e [data-tool]") |> LazyHTML.attribute("data-tool") == ["bold", "link"]
    assert find(html, "#e [data-picker=size] .ql-picker-item") |> Enum.count() == 4
    assert find(html, "#e-container.h-72") |> Enum.count() == 1
    assert find(html, "[data-editor][contenteditable=false]") |> Enum.count() == 1
    assert find(html, "button[data-tool=bold][disabled]") |> Enum.count() == 1
  end

  test "field wiring and on_change" do
    assigns = %{
      __changed__: nil,
      form: Phoenix.Component.to_form(%{"body" => "<b>x</b>"}, as: :post)
    }

    html =
      rendered_to_string(
        ~H|<.text_editor field={@form[:body]} on_change="edited" debounce={50} label="Body" />|
      )

    assert find(html, "#post_body[data-on-change=edited][data-debounce='50']") |> Enum.count() ==
             1

    assert find(html, "input[type=hidden][name='post[body]']") |> Enum.count() == 1
    assert html |> find("label > span") |> LazyHTML.text() == "Body"
  end

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the slash menu, variables, the assistant button and the footer" do
    html =
      render(~H"""
      <.text_editor
        id="e"
        name="b"
        slash
        variables={~w(cliente preço)}
        footer
        hint="Markdown works"
        on_ai="write"
        slash_title="Inserir"
      >
        <:ai>Write with the assistant</:ai>
      </.text_editor>
      """)

    assert [slash] = attr_of(html, "#e", "data-slash")
    assert [%{"key" => "paragraph"} | _] = Jason.decode!(slash)
    assert attr_of(html, "#e", "data-variables") == [~s(["cliente","preço"])]
    assert attr_of(html, "#e", "data-slash-title") == ["Inserir"]
    assert attr_of(html, "#e", "data-on-ai") == ["write"]
    assert find(html, "#e .ql-toolbar button.ql-ai[data-ai]") |> LazyHTML.text() =~ "Write with"
    assert find(html, "#e .ql-footer") |> LazyHTML.text() =~ "Markdown works"
    assert [_] = find(html, "#e .ql-footer [data-count]") |> Enum.to_list()
    assert [_] = find(html, "#e #e-menu[phx-update=ignore][data-menu][hidden]") |> Enum.to_list()
  end

  test "the slash menu takes custom entries and the event they push" do
    assigns = %{
      items: [
        %{key: "paragraph", label: "Text"},
        %{key: "image", label: "Image", hint: "Upload a picture"}
      ]
    }

    html =
      rendered_to_string(
        ~H|<.text_editor id="e" name="b" slash slash_items={@items} on_slash="slash" />|
      )

    assert attr_of(html, "#e", "data-on-slash") == ["slash"]
    assert [slash] = attr_of(html, "#e", "data-slash")

    assert [_, %{"key" => "image", "hint" => "Upload a picture"}] = Jason.decode!(slash)

    assert attr_of(render(~H|<.text_editor id="e" name="b" slash />|), "#e", "data-on-slash") ==
             []
  end

  test "without slash there is no slash menu, and no assistant button without its slot" do
    html = render(~H|<.text_editor id="e" name="b" />|)

    assert attr_of(html, "#e", "data-slash") == []
    assert find(html, "#e .ql-ai") |> Enum.to_list() == []
    assert find(html, "#e .ql-footer") |> Enum.to_list() == []
  end

  test "a comment has no toolbar, a bar with mention and submit, and the mentions" do
    html =
      render(~H"""
      <.text_editor
        id="c"
        name="c"
        variant="comment"
        on_submit="comment"
        mentions={[%{handle: "juliana", label: "Juliana Moraes"}]}
        submit_label="Comentar"
      >
        <:actions><button id="attach" type="button">Attach</button></:actions>
      </.text_editor>
      """)

    assert find(html, "#c [data-toolbar]") |> Enum.to_list() == []
    assert "ql-comment" in classes(html, "#c")
    assert "min-h-16" in classes(html, "#c-container")
    assert attr_of(html, "#c", "data-on-submit") == ["comment"]

    assert attr_of(html, "#c", "data-mentions") == [
             ~s([{"handle":"juliana","label":"Juliana Moraes"}])
           ]

    assert [_] = find(html, "#c [data-comment-bar] > #attach") |> Enum.to_list()
    assert [_] = find(html, "#c [data-comment-bar] [data-mention-button]") |> Enum.to_list()
    assert find(html, "#c [data-comment-bar] .ql-kbd") |> LazyHTML.text() == "Ctrl ↵"
    assert find(html, "#c [data-submit]") |> LazyHTML.text() =~ "Comentar"
  end

  test "image, variable and mark are not in the default toolbar" do
    html = render(~H|<.text_editor id="e" name="b" />|)

    for tool <- ~w(image variable mark),
        do: assert(find(html, "#e [data-tool=#{tool}]") |> Enum.to_list() == [])

    assert attr_of(html, "#e", "data-images") == ["false"]
    assert find(html, "#e [data-image-box]") |> Enum.to_list() == []
  end

  test "the mark, variable and image buttons, with names that can be overridden" do
    html =
      render(~H"""
      <.text_editor
        id="e"
        name="b"
        variables={~w(cliente)}
        toolbar={[~w(mark variable image)]}
        tool_labels={%{"mark" => "Destacar", "image" => "Imagem"}}
      />
      """)

    assert attr_of(html, "#e", "data-images") == ["true"]
    assert attr_of(html, "#e", "data-variable-title") == ["Insert variable"]
    assert find(html, "#e button.ql-mark[data-tool=mark] svg") |> Enum.count() == 1

    assert html |> find("#e [data-tool=mark]") |> LazyHTML.attribute("aria-label") == ["Destacar"]
    assert html |> find("#e [data-tool=mark]") |> LazyHTML.attribute("aria-pressed") == ["false"]
    assert html |> find("#e [data-tool=image]") |> LazyHTML.attribute("aria-label") == ["Imagem"]

    assert html |> find("#e [data-tool=variable]") |> LazyHTML.attribute("aria-label") ==
             ["Variable"]

    assert html |> find("#e [data-tool=variable]") |> LazyHTML.attribute("disabled") == []
    assert [_] = find(html, "#e [data-image-box] [data-image-input]") |> Enum.to_list()
    assert [_] = find(html, "#e [data-image-box] [data-image-alt]") |> Enum.to_list()
    assert find(html, "#e [data-image-save]") |> LazyHTML.text() == "Insert"
  end

  test "the variable button is disabled without variables" do
    html = render(~H|<.text_editor id="e" name="b" toolbar={[~w(variable)]} />|)

    assert html |> find("#e [data-tool=variable]") |> LazyHTML.attribute("disabled") == [""]
  end

  test "on_image replaces the address field, and turns images on" do
    html =
      render(~H|<.text_editor id="e" name="b" on_image="image" toolbar={[~w(image)]} />|)

    assert attr_of(html, "#e", "data-on-image") == ["image"]
    assert attr_of(html, "#e", "data-images") == ["true"]
    assert find(html, "#e [data-image-box]") |> Enum.to_list() == []

    html = render(~H|<.text_editor id="e" name="b" images />|)
    assert attr_of(html, "#e", "data-images") == ["true"]
  end

  test "insert_image pushes an escaped img to the editor" do
    socket =
      LineaUI.Components.TextEditor.insert_image(
        %Phoenix.LiveView.Socket{},
        "e",
        "/a.png?x=1&y=\"2",
        "A <b>photo</b>"
      )

    assert [["linea:editor-insert", %{id: "e", html: html}]] =
             socket.private.live_temp.push_events

    assert html == ~s(<img src="/a.png?x=1&amp;y=&quot;2" alt="A &lt;b&gt;photo&lt;/b&gt;">)
  end

  test "insert_html pushes the answer to the editor" do
    socket =
      LineaUI.Components.TextEditor.insert_html(%Phoenix.LiveView.Socket{}, "e", "<p>x</p>")

    assert %{"linea:editor-insert" => _} =
             Map.new(socket.private.live_temp.push_events, fn [e, p] -> {e, p} end)
  end
end
