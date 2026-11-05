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

    html = render(~H|<.button size="sm" class="px-8">Go</.button>|)
    assert "sm" in classes(html, "button")
    assert "px-8" in classes(html, "button")

    assert "lg" in classes(render(~H|<.button size="lg">Go</.button>|), "button")
    assert "sq" in classes(render(~H|<.button shape="square">Go</.button>|), "button")
  end

  test "icon makes the round canvas icon button" do
    html = render(~H|<.button icon aria-label="More">+</.button>|)
    assert "sg-ib" in classes(html, "button")
    assert "plain" in classes(render(~H|<.button icon variant="flat">+</.button>|), "button")
    assert "sm" in classes(render(~H|<.button icon size="sm">+</.button>|), "button")
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
