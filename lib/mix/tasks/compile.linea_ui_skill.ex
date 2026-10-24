defmodule Mix.Tasks.Compile.LineaUiSkill do
  @shortdoc "Keeps the Claude Code skill of LineaUI in step with the installed version"

  @moduledoc """
  A Mix compiler that regenerates `.claude/skills/linea-ui/` when the installed `linea_ui` is not the version the
  skill was written for, so `mix deps.update linea_ui` and a compile leave the skill exact.

  `mix linea_ui.install` adds it to the `compilers` of the app's `mix.exs`. It does nothing when the app has no
  skill yet, when the skill is already for this version and in the `:prod` environment.
  """

  use Mix.Task.Compiler

  alias LineaUI.Skill

  @path ".claude/skills/linea-ui"

  @impl true
  def run(_args), do: refresh(Mix.env(), @path)

  @doc false
  def refresh(:prod, _path), do: {:noop, []}
  def refresh(_env, path), do: refresh(Skill.installed_version(path), Skill.version(), path)

  defp refresh(nil, _version, _path), do: {:noop, []}
  defp refresh(version, version, _path), do: {:noop, []}

  defp refresh(_stale, version, path) do
    files = Skill.write!(path)

    Mix.shell().info(
      "LineaUI skill updated to #{version} (#{length(files) - 1} component references)"
    )

    {:ok, []}
  end
end
