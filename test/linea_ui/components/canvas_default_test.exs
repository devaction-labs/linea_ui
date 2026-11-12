defmodule LineaUI.Components.CanvasDefaultTest do
  use LineaUI.ComponentCase, async: true

  defp has?(html, selector), do: find(html, selector) |> Enum.count() > 0

  defp upload do
    socket = Phoenix.LiveView.allow_upload(%Phoenix.LiveView.Socket{}, :photos, accept: :any)
    socket.assigns.uploads.photos
  end

  test "alert: canvas by default, solid is the old look" do
    assert has?(render(~H"<.alert>Hi</.alert>"), ".sg-alert")
    refute has?(render(~H"<.alert variant=\"solid\">Hi</.alert>"), ".sg-alert")
  end

  test "accordion: canvas by default, basic is the old look" do
    html = render(~H"<.accordion id=\"a\">
  <.accordion_item id=\"i\" title=\"T\">x</.accordion_item>
</.accordion>")
    assert LazyHTML.attribute(find(html, "#a"), "data-variant") == ["canvas"]

    old = render(~H"<.accordion id=\"a\" variant=\"basic\">
  <.accordion_item id=\"i\" title=\"T\">x</.accordion_item>
</.accordion>")
    assert LazyHTML.attribute(find(old, "#a"), "data-variant") == ["basic"]
  end

  test "breadcrumb: canvas by default, plain is the old look" do
    assert has?(
             render(~H"<.breadcrumb>
  <:item>A</:item>
</.breadcrumb>"),
             ".sg-crumb"
           )

    refute has?(
             render(~H"<.breadcrumb variant=\"plain\">
  <:item>A</:item>
</.breadcrumb>"),
             ".sg-crumb"
           )
  end

  test "collapse: canvas by default, classic is the old look" do
    html = render(~H"<.collapse id=\"c\"><:trigger>T</:trigger>x</.collapse>")
    assert LazyHTML.attribute(find(html, "#c"), "data-variant") == ["canvas"]

    old = render(~H"<.collapse id=\"c\" variant=\"classic\"><:trigger>T</:trigger>x</.collapse>")
    assert LazyHTML.attribute(find(old, "#c"), "data-variant") == []
  end

  test "fab: canvas by default, pill is the old look" do
    assert has?(render(~H"<.fab id=\"f\" label=\"Go\" />"), ".sg-fab")
    refute has?(render(~H"<.fab id=\"f\" variant=\"pill\" label=\"Go\" />"), ".sg-fab")

    assert has?(
             render(~H"<.fab_dial id=\"d\" label=\"Go\">
  <:action label=\"A\">a</:action>
</.fab_dial>"),
             ".sg-fab-dial"
           )

    refute has?(
             render(~H"<.fab_dial id=\"d\" variant=\"pill\" label=\"Go\">
  <:action label=\"A\">a</:action>
</.fab_dial>"),
             ".sg-fab-dial"
           )
  end

  test "pagination: canvas by default, rounded is the old look" do
    html = render(~H"<.pagination page={2} total_pages={5} on_change=\"go\" />")
    assert has?(html, "button[class*='rounded-[9px]']")

    old = render(~H"<.pagination page={2} total_pages={5} on_change=\"go\" shape=\"rounded\" />")
    refute has?(old, "[class*='rounded-[9px]']")
  end

  test "skeleton: canvas by default, lineone is the old look" do
    assert has?(render(~H"<.skeleton />"), ".sg-skel")
    refute has?(render(~H"<.skeleton variant=\"lineone\" />"), ".sg-skel")
  end

  test "spinner: canvas by default, border is the old look" do
    assert has?(render(~H"<.spinner />"), ".sg-spin")
    refute has?(render(~H"<.spinner variant=\"border\" />"), ".sg-spin")
  end

  test "stepper: canvas by default, classic is the old look" do
    assert has?(render(~H"<.stepper current={1}><:step label=\"A\" /></.stepper>"), ".sg-steps")

    refute has?(
             render(
               ~H"<.stepper variant=\"classic\" current={1}><:step label=\"A\" /></.stepper>"
             ),
             ".sg-steps"
           )
  end

  test "treeview: canvas by default, lineone is the old look" do
    assert has?(
             render(~H"<.treeview id=\"t\"><.tree_item id=\"a\" label=\"A\" /></.treeview>"),
             ".tree-canvas"
           )

    refute has?(
             render(
               ~H"<.treeview id=\"t\" variant=\"lineone\"><.tree_item id=\"a\" label=\"A\" /></.treeview>"
             ),
             ".tree-canvas"
           )
  end

  test "upload: canvas by default, pond is the old look" do
    assigns = %{__changed__: nil, upload: upload()}
    assert has?(rendered_to_string(~H|<.upload upload={@upload} />|), ".lu-upload-canvas")
    old = rendered_to_string(~H|<.upload variant="pond" upload={@upload} />|)
    refute has?(old, ".lu-upload-canvas")
    assert has?(old, ".filepond--root")
  end

  test "range: canvas by default, classic is the old look" do
    assert has?(render(~H"<.range name=\"r\" />"), ".lu-range-canvas")
    refute has?(render(~H"<.range name=\"r\" variant=\"classic\" />"), ".lu-range-canvas")
  end

  test "signature_pad: canvas by default, classic is the old look" do
    assert has?(render(~H"<.signature_pad name=\"s\" />"), ".lu-sign-foot")
    refute has?(render(~H"<.signature_pad name=\"s\" variant=\"classic\" />"), ".lu-sign-foot")
  end

  test "notification_center: canvas by default, classic is the old look" do
    assert has?(render(~H"<.notification_center id=\"n\" items={[]} />"), ".nc-canvas")

    refute has?(
             render(~H"<.notification_center id=\"n\" variant=\"classic\" items={[]} />"),
             ".nc-canvas"
           )
  end

  test "command_palette: canvas by default, classic is the old look" do
    assert has?(render(~H"<.command_palette id=\"p\" items={[]} />"), ".palette-canvas")

    refute has?(
             render(~H"<.command_palette id=\"p\" variant=\"classic\" items={[]} />"),
             ".palette-canvas"
           )
  end

  test "carousel: canvas by default, classic is the old look" do
    html = render(~H"<.carousel id=\"c\">
  <.carousel_slide>A</.carousel_slide>
</.carousel>")
    assert LazyHTML.attribute(find(html, "#c"), "data-variant") == ["canvas"]

    old = render(~H"<.carousel id=\"c\" variant=\"classic\">
  <.carousel_slide>A</.carousel_slide>
</.carousel>")
    assert LazyHTML.attribute(find(old, "#c"), "data-variant") == []
  end

  test "empty_state: canvas by default, card is the old look" do
    assert has?(render(~H"<.empty_state title=\"Nada\" />"), ".sg-empty")
    refute has?(render(~H"<.empty_state variant=\"card\" title=\"Nada\" />"), ".sg-empty")
  end
end
