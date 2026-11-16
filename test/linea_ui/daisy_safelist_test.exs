defmodule LineaUI.DaisySafelistTest do
  # Tailwind only generates a class it finds written out, and some components build daisyUI's classes
  # from an attr ("alert-" <> color). linea_ui.css lists those with @source inline; this keeps the list
  # covering every class those components can build.
  use ExUnit.Case, async: true

  @colors ~w(primary secondary info success warning error)
  @sizes ~w(xs sm md lg xl)

  @built for(
           color <- @colors,
           prefix <- ~w(btn badge alert progress toggle checkbox radio range step text),
           do: "#{prefix}-#{color}"
         ) ++
           for(
             size <- @sizes,
             prefix <- ~w(btn badge toggle checkbox radio range loading),
             do: "#{prefix}-#{size}"
           ) ++
           for(color <- @colors, do: "bg-#{color}/15") ++
           ~w(aria-invalid:checkbox-error aria-invalid:radio-error btn-neutral badge-neutral)

  test "every daisyUI class built from an attr is listed for Tailwind" do
    css = File.read!("assets/css/linea_ui.css")

    listed =
      ~r/@source inline\("([^"]+)"\)/
      |> Regex.scan(css, capture: :all_but_first)
      |> Enum.flat_map(fn [pattern] -> pattern |> String.split() |> Enum.flat_map(&expand/1) end)
      |> MapSet.new()

    assert Enum.reject(@built, &(&1 in listed)) == []
  end

  # "{a,b}-{x,y}" -> ["a-x", "a-y", "b-x", "b-y"]
  defp expand(pattern) do
    case Regex.run(~r/\{([^}]*)\}/, pattern, return: :index) do
      nil ->
        [pattern]

      [{start, len}, {inner_start, inner_len}] ->
        prefix = binary_part(pattern, 0, start)
        rest = binary_part(pattern, start + len, byte_size(pattern) - start - len)

        pattern
        |> binary_part(inner_start, inner_len)
        |> String.split(",")
        |> Enum.flat_map(&expand(prefix <> &1 <> rest))
    end
  end
end
