defmodule Mix.Tasks.LineaUi.Gen.Skill do
  @shortdoc "Writes the Claude Code skill for the installed LineaUI"

  @moduledoc """
  Writes `.claude/skills/linea-ui/`: a short `SKILL.md` index and one reference per component,
  generated from the components' attrs, slots and docs.

      mix linea_ui.gen.skill
      mix linea_ui.gen.skill --path priv/skills/linea-ui

  Files of a previous run are replaced, and references of components that no longer exist are
  removed, so running it after an upgrade keeps the skill exact.
  """

  use Mix.Task

  @default_path ".claude/skills/linea-ui"

  @impl true
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [path: :string])
    path = Keyword.get(opts, :path, @default_path)

    Mix.Task.run("app.config")
    {:ok, _} = Application.ensure_all_started(:linea_ui)

    files = LineaUI.Skill.write!(path)

    Mix.shell().info(
      "LineaUI skill written to #{path} (#{length(files) - 1} component references)"
    )
  end
end
