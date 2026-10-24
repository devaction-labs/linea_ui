defmodule LineaUI.Components.CardTest do
  use LineaUI.ComponentCase, async: true

  test "the white card with a title and a body" do
    html =
      render(~H"""
      <.card>
        <:title>Simple Card</:title><p>Body</p>
      </.card>
      """)

    classes = classes(html, "div")
    assert "card" in classes
    assert "px-4" in classes
    assert [title] = find(html, "h2") |> Enum.to_list()
    assert String.trim(LazyHTML.text(title)) == "Simple Card"
    assert [_] = find(html, "div.pt-2 > p") |> Enum.to_list()
  end

  test "without a title the content fills the card, padded or not" do
    html =
      render(~H"""
      <.card padded={false} class="p-2"><span id="x"></span></.card>
      """)

    assert [_] = find(html, "div.card > span#x") |> Enum.to_list()
    refute "px-4" in classes(html, "div")
  end

  test "variants" do
    html =
      render(~H"""
      <.card id="b" variant="bordered" shape="xl">x</.card>
      <.card id="s" variant="solid" color="info">x</.card>
      <.card id="g" variant="glow" color="primary">x</.card>
      <.card id="r" variant="gradient" gradient="fuchsia-pink">x</.card>
      <.card id="o" variant="gradient_outline" gradient="sky-blue">x</.card>
      """)

    assert "border-slate-150" in classes(html, "#b")
    assert "rounded-2xl" in classes(html, "#b")
    assert "bg-info" in classes(html, "#s")
    assert "shadow-primary/50" in classes(html, "#g")
    assert "from-fuchsia-600" in classes(html, "#r")
    assert "p-1" in classes(html, "#o")
    assert [_] = find(html, "#o > div.bg-slate-50") |> Enum.to_list()
  end

  test "flat has no shadow" do
    html =
      render(~H"""
      <.card id="f" variant="flat"><:title>T</:title>x</.card>
      """)

    assert ["card", "shadow-none"] -- classes(html, "#f") == []
    assert "text-slate-700" in classes(html, "#f h2")
  end

  test "gradient_outline radius follows shape" do
    html =
      render(~H"""
      <.card id="a" variant="gradient_outline">x</.card>
      <.card id="b" variant="gradient_outline" shape="xl">x</.card>
      """)

    assert "rounded-lg" in classes(html, "#a")
    assert "rounded-lg" in classes(html, "#a > div")
    assert "rounded-2xl" in classes(html, "#b")
    refute "rounded-lg" in classes(html, "#b")
    assert "rounded-xl" in classes(html, "#b > div")
    refute "rounded-lg" in classes(html, "#b > div")
  end

  describe "surfaces" do
    test "outline, muted, soft and filled" do
      html =
        render(~H"""
        <.card id="o" variant="outline">x</.card>
        <.card id="m" variant="muted">x</.card>
        <.card id="s" variant="soft">x</.card>
        <.card id="f" variant="filled">x</.card>
        """)

      assert "bg-transparent" in classes(html, "#o")
      assert "border" in classes(html, "#o")
      assert "bg-slate-100" in classes(html, "#m")
      assert "border" in classes(html, "#m")
      assert "bg-slate-50" in classes(html, "#s")
      assert "border" in classes(html, "#s")
      assert "bg-slate-100" in classes(html, "#f")
      assert "dark:bg-navy-600/50" in classes(html, "#f")
      refute "border" in classes(html, "#f")
      assert "shadow-none" in classes(html, "#f")
    end

    test "new surfaces take the light heading" do
      html =
        render(~H"""
        <.card id="m" variant="muted"><:title>T</:title>x</.card>
        """)

      assert "text-slate-700" in classes(html, "#m h2")
    end
  end

  describe "sizes" do
    test "each size has its padding, corners and variables" do
      html =
        render(~H"""
        <.card id="xs" size="xs">x</.card>
        <.card id="sm" size="sm">x</.card>
        <.card id="md">x</.card>
        <.card id="lg" size="lg">x</.card>
        """)

      assert "px-2.5" in classes(html, "#xs")
      assert "rounded" in classes(html, "#xs")
      assert "[--card-px:0.875rem]" in classes(html, "#sm")
      assert "px-4" in classes(html, "#md")
      assert "rounded-lg" in classes(html, "#md")
      assert "sm:px-6" in classes(html, "#lg")
      assert "rounded-xl" in classes(html, "#lg")
    end

    test "shape xl wins over the size's corners and sets the radius variable" do
      html =
        render(~H"""
        <.card id="x" size="sm" shape="xl">x</.card>
        """)

      assert "rounded-2xl" in classes(html, "#x")
      refute "rounded-md" in classes(html, "#x")
      assert "[--card-r:1rem]" in classes(html, "#x")
      refute "[--card-r:0.375rem]" in classes(html, "#x")
    end
  end

  describe "body treatments" do
    test "each treatment publishes its own variables" do
      html =
        render(~H"""
        <.card id="a">x</.card>
        <.card id="d" body="divided">x</.card>
        <.card id="s" body="separated">x</.card>
        <.card id="i" body="inset">x</.card>
        <.card id="f" body="flush">x</.card>
        """)

      assert "[--p-line:0px]" in classes(html, "#a")
      assert "[--p-line:1px]" in classes(html, "#d")
      assert "dark:[--p-band:rgb(255_255_255/0.05)]" in classes(html, "#s")
      assert "[--b-r:calc(var(--card-r)_-_var(--card-inset))]" in classes(html, "#i")
      assert "p-(--card-inset)" in classes(html, "#i")
      refute "px-4" in classes(html, "#i")
      assert "[--b-line:1px]" in classes(html, "#f")
    end

    test "an unpadded card has no padding and leaves the parts to pad themselves" do
      html =
        render(~H"""
        <.card id="u" padded={false} body="divided">x</.card>
        """)

      refute "px-4" in classes(html, "#u")
      assert "[--p-px:1rem]" in classes(html, "#u")
      refute "[--p-line:1px]" in classes(html, "#u")
    end

    test "gradient_outline puts size and treatment on the inner panel" do
      html =
        render(~H"""
        <.card id="o" variant="gradient_outline" size="lg" body="divided">x</.card>
        """)

      assert "px-5" in classes(html, "#o > div")
      assert "[--p-line:1px]" in classes(html, "#o > div")
    end
  end

  describe "parts" do
    test "header, body and footer inside a card" do
      html =
        render(~H"""
        <.card id="c" body="divided">
          <.card_header>
            <.card_heading>Invoice</.card_heading>
            <.card_subheading>Due soon</.card_subheading>
            <.card_actions><button>Edit</button></.card_actions>
          </.card_header>
          <.card_body>Body</.card_body>
          <.card_footer align="between"><button>Pay</button></.card_footer>
        </.card>
        """)

      assert [_] = find(html, "#c > div.grid > h2") |> Enum.to_list()
      assert [_] = find(html, "#c > div.grid > p") |> Enum.to_list()
      assert [_] = find(html, "#c > div.grid > div.flex > button") |> Enum.to_list()
      assert [_] = find(html, "#c > div.flex-wrap") |> Enum.to_list()
      assert "justify-between" in classes(html, "#c > div.flex-wrap")
      assert "col-start-2" in classes(html, "h2")
      assert "col-start-3" in classes(html, "div.flex.items-center.gap-2.ms-3")
      assert "first:col-start-1" in classes(html, "div.ms-3")
    end

    test "actions do not make the header taller" do
      html =
        render(~H"""
        <.card_header>
          <.card_actions>a</.card_actions>
        </.card_header>
        """)

      assert "-my-1.5" in classes(html, "div > div")
    end

    test "parts take class and rest" do
      html =
        render(~H"""
        <.card_header id="h" class="px-2" data-x="1">x</.card_header>
        <.card_footer id="f" class="justify-center">x</.card_footer>
        """)

      assert "px-2" in classes(html, "#h")
      refute "px-[var(--p-px,1rem)]" in classes(html, "#h")
      assert "justify-center" in classes(html, "#f")
      refute "justify-end" in classes(html, "#f")
    end

    test "a header and footer nested in a body reset the part variables" do
      html =
        render(~H"""
        <.card_body id="b">
          <.card_header>h</.card_header>
          <.card_footer>f</.card_footer>
        </.card_body>
        """)

      assert "[--p-px:0px]" in classes(html, "#b")
      assert "[--p-line:0px]" in classes(html, "#b")
      assert [_, _] = find(html, "#b > div") |> Enum.to_list()
    end

    test "legacy title keeps working next to parts" do
      html =
        render(~H"""
        <.card>
          <:title>Old</:title>
          <.card_footer>f</.card_footer>
        </.card>
        """)

      assert [_] = find(html, "div.pt-2 > div") |> Enum.to_list()
    end
  end

  describe "card_bleed" do
    test "bleed edges cancel the card padding on their sides" do
      html =
        render(~H"""
        <.card_bleed id="a"><img src="x.png" alt="" /></.card_bleed>
        <.card_bleed id="t" edges="top">x</.card_bleed>
        <.card_bleed id="b" edges="bottom">x</.card_bleed>
        <.card_bleed id="x" edges="x">x</.card_bleed>
        """)

      assert "-my-[var(--card-py,1rem)]" in classes(html, "#a")
      assert "rounded-[var(--b-r,0px)]" in classes(html, "#a")
      assert "overflow-hidden" in classes(html, "#a")
      assert "-mt-[var(--card-py,1rem)]" in classes(html, "#t")
      assert "rounded-t-[var(--b-r,0px)]" in classes(html, "#t")
      assert "-mb-[var(--card-py,1rem)]" in classes(html, "#b")
      assert "-mx-[var(--card-px,1rem)]" in classes(html, "#x")
      refute "rounded-[var(--b-r,0px)]" in classes(html, "#x")
    end
  end
end
