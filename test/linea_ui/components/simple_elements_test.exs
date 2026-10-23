defmodule LineaUI.Components.SimpleElementsTest do
  use LineaUI.ComponentCase, async: true

  describe "divider" do
    test "horizontal and vertical lines, with and without text" do
      html =
        render(~H"""
        <.divider id="h" />
        <.divider id="ht">OR</.divider>
        <.divider id="v" orientation="vertical" />
        <.divider id="vt" orientation="vertical">OR</.divider>
        """)

      assert "h-px" in classes(html, "#h")
      assert [_, _] = find(html, "#ht > div.h-px") |> Enum.to_list()
      assert "w-px" in classes(html, "#v")
      assert [_] = find(html, "#v[aria-orientation=vertical]") |> Enum.to_list()
      assert [_, _] = find(html, "#vt > div.w-px") |> Enum.to_list()
    end
  end

  describe "mask" do
    test "a masked image or a masked block" do
      html =
        render(~H"""
        <.mask id="i" shape="heart" src="/a.jpg" class="size-36" />
        <.mask id="b" shape="star-2"><span>JD</span></.mask>
        """)

      assert "size-36" in classes(html, "#i")
      assert [_] = find(html, "#i > img.mask.is-heart[src='/a.jpg']") |> Enum.to_list()
      assert "is-star-2" in classes(html, "#b")
      assert "heart" in mask_shapes()
    end
  end

  describe "progress" do
    test "the bar's width follows value and max" do
      html =
        render(~H"""
        <.progress value={5} max={10} color="success" />
        """)

      assert [_] = find(html, "[role=progressbar][aria-valuenow='5']") |> Enum.to_list()
      assert [bar] = find(html, "div.bg-success") |> Enum.to_list()
      assert LazyHTML.attribute(bar, "style") == ["width: 50.0%"]
      assert "h-2" in classes(html, "[role=progressbar]")
    end

    test "soft, sizes, active and indeterminate" do
      html =
        render(~H"""
        <.progress id="s" variant="soft" color="info" size="xl" value={10} />
        <.progress id="a" active value={10} />
        <.progress id="i" indeterminate />
        """)

      assert "bg-info/15" in classes(html, "#s")
      assert "h-4" in classes(html, "#s")
      assert "is-active" in classes(html, "#a > div")
      assert "is-indeterminate" in classes(html, "#i > div")
      assert [] = find(html, "#i[aria-valuenow]") |> Enum.to_list()
    end
  end

  describe "skeleton" do
    test "wave by default, pulse or none, shapes" do
      html =
        render(~H"""
        <.skeleton id="w" class="h-3 w-full" />
        <.skeleton id="p" animation="pulse" shape="circle" />
        <.skeleton id="n" animation="none" shape="square" />
        """)

      assert ["skeleton", "animate-wave" | _] = classes(html, "#w")
      assert "rounded-sm" in classes(html, "#w")
      assert "animate-pulse" in classes(html, "#p")
      assert "rounded-full" in classes(html, "#p")
      refute "skeleton" in classes(html, "#n")
    end
  end

  describe "spinner" do
    test "border, soft, grow and svg, with sizes and elastic timing" do
      html =
        render(~H"""
        <.spinner id="b" color="primary" />
        <.spinner id="s" variant="soft" color="info" size="lg" elastic />
        <.spinner id="g" variant="grow" color="error" />
        <.spinner id="v" variant="svg" color="success" />
        """)

      assert "border-r-transparent" in classes(html, "#b")
      assert "border-[3px]" in classes(html, "#b")
      assert "border-info/30" in classes(html, "#s")
      assert "is-elastic" in classes(html, "#s")
      assert "size-12" in classes(html, "#s")
      assert [_, _] = find(html, "#g > span.bg-error") |> Enum.to_list()
      assert [_] = find(html, "#v > svg") |> Enum.to_list()
      assert [_] = find(html, "#b[role=status][aria-label=Loading]") |> Enum.to_list()
    end
  end

  describe "button_group" do
    test "squares the inner corners, pill rounds the ends" do
      html =
        render(~H"""
        <.button_group shape="pill"><.button>a</.button></.button_group>
        """)

      classes = classes(html, "div[role=group]")
      assert "-space-x-px" in classes
      assert "[&>*:first-child]:rounded-l-full" in classes
    end
  end
end
