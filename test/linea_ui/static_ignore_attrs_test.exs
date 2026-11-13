defmodule LineaUI.StaticIgnoreAttrsTest do
  use ExUnit.Case, async: true

  # Components write `phx-mounted='[["ignore_attrs",{"attrs":[...]}]]'` as a literal, so the markup is
  # static (sent once, not once per row of a comprehension). This pins the literal to what
  # `JS.ignore_attributes/1` encodes, so a LiveView upgrade that changes the format fails here.
  @literal ~r/phx-mounted='(\[\["ignore_attrs"[^']*)'/

  test "every literal equals the JS.ignore_attributes encoding" do
    literals =
      "lib/linea_ui/components/**/*.ex"
      |> Path.wildcard()
      |> Enum.flat_map(&(&1 |> File.read!() |> then(fn s -> Regex.scan(@literal, s) end)))
      |> Enum.map(&List.last/1)
      |> Enum.uniq()

    assert literals != []

    for literal <- literals do
      attrs =
        literal |> Phoenix.json_library().decode!() |> hd() |> List.last() |> Map.fetch!("attrs")

      expected =
        attrs |> Phoenix.LiveView.JS.ignore_attributes() |> Phoenix.json_library().encode!()

      assert literal == expected
    end
  end
end
