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
end
