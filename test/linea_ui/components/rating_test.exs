defmodule LineaUI.Components.RatingTest do
  use LineaUI.ComponentCase, async: true

  defp fills(html) do
    html |> find("[data-fill]") |> LazyHTML.attribute("style")
  end

  test "read-only is an image that says the score" do
    html =
      render(~H"""
      <.rating id="r" value={4.5} count={1284} />
      """)

    assert find(html, "#r") |> LazyHTML.attribute("role") == ["img"]
    assert find(html, "#r") |> LazyHTML.attribute("aria-label") == ["4.5 of 5 stars"]
    assert find(html, "#r") |> LazyHTML.text() =~ "(1284)"
    assert find(html, "input") |> Enum.count() == 0
  end

  test "the stars are filled by the fraction of the score" do
    html =
      render(~H"""
      <.rating value={3.25} />
      """)

    assert fills(html) == [
             "width: 100.0%",
             "width: 100.0%",
             "width: 100.0%",
             "width: 25.0%",
             "width: 0.0%"
           ]
  end

  test "the score is clamped to 0..max and junk reads as zero" do
    over = render(~H"<.rating value={9} max={5} />")
    junk = render(~H|<.rating value="abc" />|)
    text = render(~H|<.rating value="2.5" />|)

    assert Enum.all?(fills(over), &(&1 == "width: 100.0%"))
    assert Enum.all?(fills(junk), &(&1 == "width: 0.0%"))
    assert Enum.at(fills(text), 2) == "width: 50.0%"
  end

  test "max sets how many stars there are and label overrides the aria-label" do
    html =
      render(~H"""
      <.rating id="r" value={7} max={10} label="Very good" />
      """)

    assert length(fills(html)) == 10
    assert find(html, "#r") |> LazyHTML.attribute("aria-label") == ["Very good"]
  end

  test "interactive is a group of radios, one per star, with the score checked" do
    html =
      render(~H"""
      <.rating id="r" name="score" value={3} readonly={false} label="How was it?" />
      """)

    assert find(html, "fieldset#r legend") |> LazyHTML.text() =~ "How was it?"
    assert find(html, "input[type=radio]") |> LazyHTML.attribute("name") == List.duplicate("score", 5)
    assert find(html, "input[type=radio]") |> LazyHTML.attribute("value") == ~w(5 4 3 2 1)
    assert find(html, "input[checked]") |> LazyHTML.attribute("value") == ["3"]

    assert find(html, "input[type=radio]") |> LazyHTML.attribute("aria-label") ==
             ["5 stars", "4 stars", "3 stars", "2 stars", "1 star"]

    assert find(html, "label[for=r-3]") |> Enum.count() == 1
  end

  test "interactive without a score has nothing checked, disabled disables every radio" do
    html =
      render(~H"""
      <.rating id="r" name="score" readonly={false} disabled />
      """)

    assert find(html, "input[checked]") |> Enum.count() == 0
    assert find(html, "input[disabled]") |> Enum.count() == 5
    assert find(html, "fieldset[disabled]") |> Enum.count() == 1
  end

  test "a form field gives the id, the name and the value" do
    field = Phoenix.Component.to_form(%{"score" => "4"}, as: :review)[:score]
    assigns = %{field: field}
    html = rendered_to_string(~H|<.rating field={@field} readonly={false} />|)

    assert find(html, "fieldset") |> LazyHTML.attribute("id") == ["review_score"]
    assert find(html, "input") |> LazyHTML.attribute("name") |> Enum.uniq() == ["review[score]"]
    assert find(html, "input[checked]") |> LazyHTML.attribute("value") == ["4"]
  end

  test "errors are announced" do
    html =
      render(~H"""
      <.rating name="score" readonly={false} errors={["can't be blank"]} />
      """)

    assert find(html, "p[role=alert]") |> LazyHTML.text() =~ "can't be blank"
  end
end
