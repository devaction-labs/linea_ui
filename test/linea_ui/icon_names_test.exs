defmodule LineaUI.IconNamesTest do
  use ExUnit.Case, async: true

  @icons Path.expand("../../preview/deps/hugeicons/icons", __DIR__)
  @lib Path.expand("../../lib", __DIR__)
  @name ~r/\bhuge-[a-z0-9]+(?:-[a-z0-9]+)*\b/

  @tag :hugeicons
  test "every Hugeicons name written in lib exists in the free set" do
    missing =
      for file <- Path.wildcard(Path.join(@lib, "**/*.{ex,heex}")),
          [name] <- Regex.scan(@name, File.read!(file)),
          name != "huge",
          not File.exists?(Path.join(@icons, String.replace_prefix(name, "huge-", "") <> ".svg")),
          uniq: true,
          do: "#{Path.relative_to(file, @lib)}: #{name}"

    assert missing == []
  end
end
