defmodule LineaUI.SkillTest do
  use ExUnit.Case, async: false

  setup_all do
    {:ok, files: Map.new(LineaUI.Skill.files())}
  end

  test "SKILL.md has the frontmatter and lists every documented component", %{files: files} do
    index = files["SKILL.md"]
    assert index =~ ~r/\A---\nname: linea-ui\n/
    assert index =~ "[button.md](references/button.md)"
    assert index =~ "`<.button>` `<.button_group>`"
  end

  test "SKILL.md tells how the icon set is chosen", %{files: files} do
    assert files["SKILL.md"] =~ "config :linea_ui, :icons, :hugeicons"
    assert files["SKILL.md"] =~ ~S|<.icon name="huge-search-01"|
  end

  test "a reference lists attrs in declaration order with their values, without Phoenix's generated sections",
       %{files: files} do
    button = files["references/button.md"]
    assert button =~ "| `color` | `:string` | `\"neutral\"` | `neutral`, `primary`"
    assert :binary.match(button, "`color`") < :binary.match(button, "`class`")
    refute button =~ "## Attributes"
    assert button =~ "including `href`, `navigate`, `patch`"
  end

  test "components without public functions get no reference", %{files: files} do
    assert Enum.all?(
             Map.keys(files),
             &(&1 == "SKILL.md" or String.starts_with?(&1, "references/"))
           )
  end

  test "the pointer block starts with its marker and names the skill file" do
    assert String.starts_with?(LineaUI.Skill.pointer(), LineaUI.Skill.marker())
    assert LineaUI.Skill.pointer() =~ ".claude/skills/linea-ui/SKILL.md"
  end
end
