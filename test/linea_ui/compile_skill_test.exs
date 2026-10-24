defmodule LineaUI.CompileSkillTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias LineaUI.Skill
  alias Mix.Tasks.Compile.LineaUiSkill

  @moduletag :tmp_dir

  defp stamp(dir, version) do
    file = Path.join(dir, "SKILL.md")

    File.write!(
      file,
      String.replace(File.read!(file), "# LineaUI #{Skill.version()}", "# LineaUI #{version}")
    )
  end

  test "installed_version reads the version a skill was written for", %{tmp_dir: dir} do
    Skill.write!(dir)

    assert Skill.installed_version(dir) == Skill.version()
    assert Skill.installed_version(Path.join(dir, "missing")) == nil
  end

  test "does nothing when the app has no skill", %{tmp_dir: dir} do
    path = Path.join(dir, "linea-ui")

    assert LineaUiSkill.refresh(:dev, path) == {:noop, []}
    refute File.exists?(path)
  end

  test "does nothing when the skill is already for the installed version", %{tmp_dir: dir} do
    Skill.write!(dir)
    File.write!(Path.join(dir, "references/button.md"), "edited")

    assert LineaUiSkill.refresh(:dev, dir) == {:noop, []}
    assert File.read!(Path.join(dir, "references/button.md")) == "edited"
  end

  test "regenerates a skill written for another version", %{tmp_dir: dir} do
    Skill.write!(dir)
    stamp(dir, "0.0.1")
    File.write!(Path.join(dir, "references/gone.md"), "old")

    output = capture_io(fn -> assert LineaUiSkill.refresh(:dev, dir) == {:ok, []} end)

    assert Skill.installed_version(dir) == Skill.version()
    refute File.exists?(Path.join(dir, "references/gone.md"))
    assert File.exists?(Path.join(dir, "references/button.md"))
    assert output =~ "LineaUI skill updated to #{Skill.version()}"
  end

  test "never touches the skill in prod", %{tmp_dir: dir} do
    Skill.write!(dir)
    stamp(dir, "0.0.1")

    assert LineaUiSkill.refresh(:prod, dir) == {:noop, []}
    assert Skill.installed_version(dir) == "0.0.1"
  end
end
