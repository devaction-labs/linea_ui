defmodule LineaUI.Components.DisclosurePartsTest do
  use LineaUI.ComponentCase, async: true

  test "the parts carry the attributes Metronic's script reads" do
    html =
      render(~H"""
      <.disclosure_item id="i">
        <.disclosure_toggle target="#q1" aria-controls="q1">
          <.disclosure_title>Q</.disclosure_title>
        </.disclosure_toggle>
        <.disclosure_content id="q1">
          <.disclosure_wrapper>A</.disclosure_wrapper>
        </.disclosure_content>
      </.disclosure_item>
      """)

    assert [_] = find(html, "#i[data-kt-accordion-item=true]") |> Enum.to_list()

    assert [_] =
             find(html, "button[data-kt-accordion-toggle='#q1'][aria-controls=q1]")
             |> Enum.to_list()

    assert "hidden" in classes(html, "#q1")
  end
end
