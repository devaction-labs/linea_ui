defmodule LineaUI.Components.RatingTest do
  use LineaUI.ComponentCase, async: true

  test "read-only rating is one image with the grade as text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating value={4.5} show_value count={38} />
      """)

    assert html =~ ~s(role="img")
    assert html =~ "4,5 de 5 estrelas"
    assert html =~ "4,5"
    assert html =~ "(38)"
    assert html =~ "width: 50%"
    refute html =~ "radio"
    assert length(Regex.scan(~r/<svg/, html)) == 10
  end

  test "sizes and a custom label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating value={3} size="lg" aria_label="3 of 5 stars" />
      """)

    assert html =~ "size-7"
    assert html =~ ~s(aria-label="3 of 5 stars")
  end

  test "interactive rating is a radiogroup from the best grade to the worst" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating id="service" name="service" label="Como foi?" value={4} on_change="rate" target="#form" />
      """)

    assert html =~ ~s(role="radiogroup")
    assert html =~ "Como foi?"
    assert length(Regex.scan(~r/type="radio"/, html)) == 5
    assert html =~ ~s(aria-label="5 de 5")
    assert html =~ ~s(name="service")
    assert [_, before_checked] = String.split(html, ~s(id="service-4"), parts: 2)
    assert before_checked =~ "checked"
    assert html =~ "phx-click"
    assert html =~ "rate"
    assert html =~ "#form"
  end

  test "takes a form field and disabled state" do
    assigns = %{form: Phoenix.Component.to_form(%{"grade" => "2"}, as: :review)}

    html =
      rendered_to_string(~H"""
      <.rating field={@form[:grade]} disabled />
      """)

    assert html =~ ~s(name="review[grade]")
    assert html =~ "disabled"
    assert html =~ "opacity-50"
    assert [_, tail] = String.split(html, ~s(id="review_grade-2"), parts: 2)
    assert tail =~ "checked"
  end

  test "distribution computes the average, the total and the shares" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating_distribution counts={[620, 240, 90, 30, 20]} />
      """)

    assert html =~ "1.000 avaliações"
    assert html =~ "62%"
    assert html =~ "24%"
    assert html =~ "width: 62%"
    assert html =~ "4,4"
  end

  test "distribution takes a map and given figures" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating_distribution counts={%{5 => 1, 4 => 1}} average={4.5} total={1284} unit="votos" />
      """)

    assert html =~ "1.284 votos"
    assert html =~ "4,5"
    assert html =~ "50%"
  end
end
