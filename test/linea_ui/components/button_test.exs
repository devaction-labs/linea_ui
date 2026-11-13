defmodule LineaUI.Components.ButtonTest do
  use LineaUI.ComponentCase, async: true

  test "a plain canvas button by default, typed as a plain button" do
    html = render(~H"<.button>Go</.button>")
    assert [button] = find(html, "button[type=button]") |> Enum.to_list()
    assert String.trim(LazyHTML.text(button)) == "Go"
    assert "sg-btn" in classes(html, "button")
    refute "solid" in classes(html, "button")
  end

  test "color and variant pick the canvas tone, size picks its height, and class is kept" do
    assert "solid" in classes(render(~H|<.button color="mono">Go</.button>|), "button")
    assert "accent" in classes(render(~H|<.button color="primary">Go</.button>|), "button")

    assert "soft" in classes(
             render(~H|<.button color="primary" variant="soft">Go</.button>|),
             "button"
           )

    assert "danger" in classes(
             render(~H|<.button color="error" variant="soft">Go</.button>|),
             "button"
           )

    assert "ghost" in classes(render(~H|<.button variant="flat">Go</.button>|), "button")
    assert "filled" in classes(render(~H|<.button variant="soft">Go</.button>|), "button")
    assert "subtle" in classes(render(~H|<.button variant="dim">Go</.button>|), "button")
    assert "xs" in classes(render(~H|<.button size="xs">Go</.button>|), "button")
    refute "sm" in classes(render(~H|<.button size="xs">Go</.button>|), "button")

    html = render(~H|<.button size="sm" class="px-8">Go</.button>|)
    assert "sm" in classes(html, "button")
    assert "px-8" in classes(html, "button")

    assert "lg" in classes(render(~H|<.button size="lg">Go</.button>|), "button")
    assert "sq" in classes(render(~H|<.button shape="square">Go</.button>|), "button")
    assert "pill" in classes(render(~H|<.button shape="pill">Go</.button>|), "button")
    refute "pill" in classes(render(~H|<.button>Go</.button>|), "button")

    assert "pill" in classes(
             render(~H|<.button icon shape="pill" aria-label="More">⋮</.button>|),
             "button"
           )

    refute "pill" in classes(render(~H|<.button icon aria-label="More">⋮</.button>|), "button")
  end

  test "icon makes the round canvas icon button" do
    html = render(~H|<.button icon aria-label="More">+</.button>|)
    assert "sg-ib" in classes(html, "button")
    assert "plain" in classes(render(~H|<.button icon variant="flat">+</.button>|), "button")
    assert "sm" in classes(render(~H|<.button icon size="sm">+</.button>|), "button")
  end

  test "icon button sizes follow the canvas: md 36, sm 32, xs 24, lg and xl as md" do
    cls = &classes(&1, "button")
    assert cls.(render(~H|<.button icon aria-label="a">+</.button>|)) == ["sg-ib"]
    assert cls.(render(~H|<.button icon size="md" aria-label="a">+</.button>|)) == ["sg-ib"]
    assert cls.(render(~H|<.button icon size="sm" aria-label="a">+</.button>|)) == ["sg-ib", "sm"]
    assert cls.(render(~H|<.button icon size="xs" aria-label="a">+</.button>|)) == ["sg-ib", "xs"]
    assert cls.(render(~H|<.button icon size="lg" aria-label="a">+</.button>|)) == ["sg-ib"]
    assert cls.(render(~H|<.button icon size="xl" aria-label="a">+</.button>|)) == ["sg-ib"]
  end

  test "icon button variants: flat, ghost and dim are plain, the rest the bordered control" do
    for variant <- ~w(flat ghost dim) do
      assert ["sg-ib", "plain"] == icon_classes(variant, "neutral")
    end

    for variant <- ~w(solid glow outline soft bordered glass),
        color <- ~w(neutral primary error mono) do
      assert ["sg-ib"] == icon_classes(variant, color)
    end
  end

  defp icon_classes(variant, color) do
    assigns = %{variant: variant, color: color, __changed__: nil}

    ~H|<.button icon variant={@variant} color={@color} aria-label="a">+</.button>|
    |> rendered_to_string()
    |> classes("button")
  end

  test "icon button combines plain, size and pill" do
    html =
      render(~H|<.button icon variant="ghost" size="xs" shape="pill" aria-label="a">+</.button>|)

    assert ["sg-ib", "xs", "plain", "pill"] == classes(html, "button")
  end

  test "navigate renders a link, and disabled marks it" do
    html = render(~H|<.button navigate="/x" disabled>Go</.button>|)
    assert [link] = find(html, "a") |> Enum.to_list()
    assert LazyHTML.attribute(link, "aria-disabled") == ["true"]
    assert LazyHTML.attribute(link, "tabindex") == ["-1"]
  end

  test "loading disables the button, marks it busy and shows a spinner" do
    html = render(~H|<.button loading>Save</.button>|)
    assert [button] = find(html, "button") |> Enum.to_list()
    assert LazyHTML.attribute(button, "disabled") == [""]
    assert LazyHTML.attribute(button, "aria-busy") == ["true"]
    assert [_ | _] = find(html, "button [role=status]") |> Enum.to_list()
    assert "sg-spin" in classes(html, "button [role=status]")
    assert "xs" in classes(html, "button [role=status]")
  end

  test "pip puts the accent dot on an icon button" do
    html = render(~H|<.button icon pip aria-label="Notices">+</.button>|)
    assert [_] = find(html, "button.sg-ib span.pip") |> Enum.to_list()

    assert find(render(~H|<.button icon aria-label="Notices">+</.button>|), ".pip")
           |> Enum.empty?()
  end

  test "an idle button has no spinner nor aria-busy" do
    html = render(~H|<.button>Save</.button>|)
    assert attr_of(html, "button", "aria-busy") == []
    assert find(html, "button [role=status]") |> Enum.to_list() == []
  end

  defp attr_of(html, selector, name) do
    html |> find(selector) |> LazyHTML.attribute(name)
  end
end
