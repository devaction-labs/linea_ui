defmodule LineaUI.IconNamesTest do
  use ExUnit.Case, async: true

  @icons Path.expand("../../preview/deps/hugeicons/icons", __DIR__)
  @lib Path.expand("../../lib", __DIR__)
  @js Path.expand("../../assets/js", __DIR__)
  @name ~r/\bhuge-[a-z0-9]+(?:-[a-z0-9]+)*\b/

  @tag :hugeicons
  test "every Hugeicons name written in lib and in the hooks exists in the free set" do
    missing =
      for file <-
            (Path.wildcard(Path.join(@lib, "**/*.{ex,heex}")) ++
               Path.wildcard(Path.join(@js, "**/*.js")))
            |> Enum.reject(&String.ends_with?(&1, ".test.js")),
          [name] <- Regex.scan(@name, File.read!(file)),
          name != "huge",
          not File.exists?(Path.join(@icons, String.replace_prefix(name, "huge-", "") <> ".svg")),
          uniq: true,
          do: "#{Path.relative_to(file, Path.expand("../..", __DIR__))}: #{name}"

    assert missing == []
  end
end
