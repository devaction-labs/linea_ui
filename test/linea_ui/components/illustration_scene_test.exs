defmodule LineaUI.Components.IllustrationSceneTest do
  use LineaUI.ComponentCase, async: true

  for name <- ~w(voyage lighthouse balloons aurora) do
    test "scene #{name} renders cropped and decorative by default" do
      name = unquote(name)
      html = render(~H|<.scene name={name} />|)

      assert [svg] = find(html, "svg") |> Enum.to_list()
      assert LazyHTML.attribute(svg, "preserveAspectRatio") == ["xMidYMid slice"]
      assert LazyHTML.attribute(svg, "aria-hidden") == ["true"]
      assert "h-full" in classes(html, "svg")
    end
  end

  test "scene with a label, a crop and a class" do
    html =
      render(
        ~H|<.scene name="aurora" position="xMidYMax" label="Aurora <boreal>" class="size-40" />|
      )

    assert html |> find("svg") |> LazyHTML.attribute("aria-label") == ["Aurora <boreal>"]
    assert html |> find("svg") |> LazyHTML.attribute("preserveAspectRatio") == ["xMidYMax slice"]
    assert ["size-40"] == classes(html, "svg")
  end
end
