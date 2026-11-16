defmodule LineaUI.Components.ButtonTest do
  use LineaUI.ComponentCase, async: true

  defmacrop cls(template) do
    quote do: classes(render(unquote(template)), "button")
  end

  test "daisyUI's plain btn by default, typed as a plain button" do
    html = render(~H"<.button>Go</.button>")
    assert [button] = find(html, "button[type=button]") |> Enum.to_list()
    assert String.trim(LazyHTML.text(button)) == "Go"
    assert ["btn" | neutral] = classes(html, "button")
    assert Enum.all?(neutral, &String.starts_with?(&1, "[--btn-"))
  end

  test "color, variant and size map to daisyUI's modifiers, and class is kept" do
    assert "btn-neutral" in cls(~H|<.button color="mono">Go</.button>|)
    assert "btn-primary" in cls(~H|<.button color="primary">Go</.button>|)
    assert "btn-error" in cls(~H|<.button color="error">Go</.button>|)

    assert ["btn", "btn-primary", "btn-soft"] ==
             cls(~H|<.button color="primary" variant="soft">Go</.button>|)

    assert ["btn", "btn-error", "btn-outline"] ==
             cls(~H|<.button color="error" variant="outline">Go</.button>|)

    assert "btn-ghost" in cls(~H|<.button variant="flat">Go</.button>|)
    assert "btn-ghost" in cls(~H|<.button variant="ghost">Go</.button>|)
    assert "btn-ghost" in cls(~H|<.button variant="dim">Go</.button>|)
    assert "btn-soft" in cls(~H|<.button variant="bordered">Go</.button>|)
    assert "glass" in cls(~H|<.button variant="glass">Go</.button>|)

    for size <- ~w(xs sm lg xl) do
      assigns = %{size: size, __changed__: nil}
      html = rendered_to_string(~H|<.button size={@size}>Go</.button>|)
      assert "btn-#{size}" in classes(html, "button")
    end

    refute Enum.any?(cls(~H|<.button size="md">Go</.button>|), &(&1 == "btn-md"))
    assert "px-8" in cls(~H|<.button size="sm" class="px-8">Go</.button>|)
    assert "rounded-full" in cls(~H|<.button shape="pill">Go</.button>|)
    refute "rounded-full" in cls(~H|<.button>Go</.button>|)
  end

  test "icon makes daisyUI's square button, pill its circle" do
    assert "btn-square" in cls(~H|<.button icon aria-label="More">+</.button>|)

    assert "btn-sm" in cls(~H|<.button icon size="sm" aria-label="a">+</.button>|)

    assert ["btn", "btn-ghost", "btn-xs", "btn-circle", "btn-square"] ==
             cls(
               ~H|<.button icon variant="ghost" size="xs" shape="pill" aria-label="a">+</.button>|
             )

    assert "btn-primary" in cls(~H|<.button icon color="primary" aria-label="a">+</.button>|)
  end

  test "navigate renders a link, and disabled marks it" do
    html = render(~H|<.button navigate="/x" disabled>Go</.button>|)
    assert [link] = find(html, "a") |> Enum.to_list()
    assert LazyHTML.attribute(link, "aria-disabled") == ["true"]
    assert LazyHTML.attribute(link, "tabindex") == ["-1"]
    assert "btn-disabled" in classes(html, "a")
  end

  test "loading disables the button, marks it busy and shows daisyUI's spinner" do
    html = render(~H|<.button loading>Save</.button>|)
    assert [button] = find(html, "button") |> Enum.to_list()
    assert LazyHTML.attribute(button, "disabled") == [""]
    assert LazyHTML.attribute(button, "aria-busy") == ["true"]
    assert ["loading", "loading-spinner", "loading-xs"] == classes(html, "button [role=status]")
    assert text(html, "button [role=status] .sr-only") == ["Loading"]
  end

  test "pip puts the status dot on the corner of the button" do
    html = render(~H|<.button icon pip aria-label="Notices">+</.button>|)
    assert "indicator" in classes(html, "button")
    assert [_] = find(html, "button span.indicator-item.status.status-primary") |> Enum.to_list()

    assert find(render(~H|<.button icon aria-label="Notices">+</.button>|), ".indicator-item")
           |> Enum.empty?()
  end

  test "an idle button has no spinner nor aria-busy" do
    html = render(~H"<.button>Save</.button>")
    assert attr_of(html, "button", "aria-busy") == []
    assert find(html, "button [role=status]") |> Enum.to_list() == []
  end

  test "control is accepted and changes nothing: buttons and fields share one height" do
    assert cls(~H"<.button control>Go</.button>") == cls(~H"<.button>Go</.button>")
  end

  test "button_group is daisyUI's join, pill rounds its ends" do
    html = render(~H|<.button_group><.button>A</.button><.button>B</.button></.button_group>|)
    assert classes(html, "div[role=group]") == ["join"]

    assert "[--join-r:9999px]" in classes(
             render(~H|<.button_group shape="pill"><.button>A</.button></.button_group>|),
             "div"
           )
  end

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
end
