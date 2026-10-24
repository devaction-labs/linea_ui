defmodule LineaUI.Components.CardTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name) do
    html |> find(selector) |> LazyHTML.attribute(name) |> List.first()
  end

  test "the white card with a title and a body" do
    html =
      render(~H"""
      <.card>
        <:title>Simple Card</:title><p>Body</p>
      </.card>
      """)

    assert "card" in classes(html, "div")
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
    assert attr_of(html, "div.card", "data-padded") == "false"
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
    test "each surface is named for the stylesheet" do
      html =
        render(~H"""
        <.card id="d">x</.card>
        <.card id="o" variant="outline">x</.card>
        <.card id="m" variant="muted">x</.card>
        <.card id="s" variant="soft">x</.card>
        <.card id="f" variant="filled">x</.card>
        <.card id="c" variant="solid">x</.card>
        """)

      assert attr_of(html, "#d", "data-variant") == "default"
      assert attr_of(html, "#o", "data-variant") == "outline"
      assert attr_of(html, "#m", "data-variant") == "muted"
      assert attr_of(html, "#s", "data-variant") == "soft"
      assert attr_of(html, "#f", "data-variant") == "filled"
      assert attr_of(html, "#c", "data-variant") == nil
    end

    test "new surfaces take the light heading" do
      html =
        render(~H"""
        <.card id="m" variant="muted"><:title>T</:title>x</.card>
        """)

      assert "text-slate-700" in classes(html, "#m h2")
    end

    test "highlight can be turned off" do
      html =
        render(~H"""
        <.card id="a">x</.card>
        <.card id="b" highlight={false}>x</.card>
        """)

      assert attr_of(html, "#a", "data-highlight") == "true"
      assert attr_of(html, "#b", "data-highlight") == "false"
    end
  end

  describe "sizes and treatments" do
    test "the card names its size, body and divider for the stylesheet" do
      html =
        render(~H"""
        <.card id="a">x</.card>
        <.card id="b" size="lg" body="divided" divider="inset">x</.card>
        <.card id="c" size="xs" body="flush">x</.card>
        """)

      assert attr_of(html, "#a", "data-size") == "md"
      assert attr_of(html, "#a", "data-body") == "seamless"
      assert attr_of(html, "#a", "data-divider") == "full"
      assert attr_of(html, "#b", "data-size") == "lg"
      assert attr_of(html, "#b", "data-body") == "divided"
      assert attr_of(html, "#b", "data-divider") == "inset"
      assert attr_of(html, "#c", "data-size") == "xs"
      assert attr_of(html, "#c", "data-body") == "flush"
    end

    test "shape xl wins over the size's radius" do
      html =
        render(~H"""
        <.card id="x" size="sm" shape="xl">x</.card>
        """)

      assert "rounded-2xl" in classes(html, "#x")
      assert "[--card-r:1rem]" in classes(html, "#x")
    end

    test "colored cards keep their own corners" do
      html =
        render(~H"""
        <.card id="s" variant="solid" size="lg">x</.card>
        """)

      assert "rounded-lg" in classes(html, "#s")
      assert "[--card-r:0.5rem]" in classes(html, "#s")
    end

    test "gradient_outline puts size and treatment on the inner panel" do
      html =
        render(~H"""
        <.card id="o" variant="gradient_outline" size="lg" body="divided">x</.card>
        """)

      assert attr_of(html, "#o > div", "data-size") == "lg"
      assert attr_of(html, "#o > div", "data-body") == "divided"
      assert "card" in classes(html, "#o > div")
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

      assert [_] = find(html, "#c > div.card-header > h2.card-heading") |> Enum.to_list()
      assert [_] = find(html, "#c > div.card-header > p.card-subheading") |> Enum.to_list()

      assert [_] =
               find(html, "#c > div.card-header > div.card-actions > button") |> Enum.to_list()

      assert [_] = find(html, "#c > div.card-body") |> Enum.to_list()
      assert [_] = find(html, "#c > div.card-footer") |> Enum.to_list()
      assert "justify-between" in classes(html, "#c > div.card-footer")
    end

    test "the footer takes a heading, a subheading and actions like a header" do
      html =
        render(~H"""
        <.card_footer>
          <.card_heading>Morning hike</.card_heading>
          <.card_subheading>Sept 12</.card_subheading>
          <.card_actions><button>More</button></.card_actions>
        </.card_footer>
        """)

      assert [_] = find(html, "div.card-footer > h2.card-heading") |> Enum.to_list()
      assert [_] = find(html, "div.card-footer > p.card-subheading") |> Enum.to_list()
      assert [_] = find(html, "div.card-footer > div.card-actions") |> Enum.to_list()
    end

    test "the heading takes a size and a level" do
      html =
        render(~H"""
        <.card_heading id="a" size="lg" level={3}>x</.card_heading>
        <.card_heading id="b" size="xl">x</.card_heading>
        <.card_heading id="c">x</.card_heading>
        """)

      assert [_] = find(html, "h3#a.text-base") |> Enum.to_list()
      assert [_] = find(html, "h2#b.text-xl") |> Enum.to_list()
      assert [_] = find(html, "h2#c.card-heading") |> Enum.to_list()
      refute "text-base" in classes(html, "#c")
    end

    test "header and footer outside a card take the size" do
      html =
        render(~H"""
        <.card_header id="h" size="lg">x</.card_header>
        <.card_footer id="f" size="xs">x</.card_footer>
        <.card_header id="n">x</.card_header>
        """)

      assert attr_of(html, "#h", "data-size") == "lg"
      assert attr_of(html, "#f", "data-size") == "xs"
      assert attr_of(html, "#n", "data-size") == nil
    end

    test "parts take class and rest" do
      html =
        render(~H"""
        <.card_header id="h" class="px-2" data-x="1">x</.card_header>
        <.card_footer id="f" class="justify-center">x</.card_footer>
        """)

      assert "px-2" in classes(html, "#h")
      assert attr_of(html, "#h", "data-x") == "1"
      assert "justify-center" in classes(html, "#f")
      refute "justify-end" in classes(html, "#f")
    end

    test "a header and footer can be nested in a body" do
      html =
        render(~H"""
        <.card_body id="b">
          <.card_header>h</.card_header>
          <.card_footer>f</.card_footer>
        </.card_body>
        """)

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
    test "is a bleed for the stylesheet and takes class" do
      html =
        render(~H"""
        <.card_bleed id="a" class="h-32"><img src="x.png" alt="" /></.card_bleed>
        """)

      assert "card-bleed" in classes(html, "#a")
      assert "h-32" in classes(html, "#a")
      assert [_] = find(html, "#a > img") |> Enum.to_list()
    end
  end
end
