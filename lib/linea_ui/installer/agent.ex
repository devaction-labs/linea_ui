if Code.ensure_loaded?(Igniter) do
  defmodule LineaUI.Installer.Agent do
    @moduledoc """
    The step of `mix linea_ui.install` that teaches Claude Code the components: it writes the
    skill under `.claude/skills/linea-ui/` and points `AGENTS.md` and `CLAUDE.md` at it.

    The files show up in the diff the user confirms. Running it again rewrites the skill with
    the installed version's docs, drops references of components that no longer exist and leaves
    the pointer alone.
    """

    alias LineaUI.Skill
    alias Sourceror.Zipper

    @root ".claude/skills/linea-ui"
    @compiler :linea_ui_skill
    @instruction_files ~w(AGENTS.md CLAUDE.md)

    @doc "Writes the skill and the pointer block."
    @spec skill(Igniter.t()) :: Igniter.t()
    def skill(igniter) do
      files =
        Enum.map(Skill.files(), fn {relative, contents} -> {skill_path(relative), contents} end)

      igniter
      |> write(files)
      |> remove_stale(files)
      |> point()
      |> keep_current()
    end

    defp keep_current(igniter) do
      Igniter.Project.MixProject.update(igniter, :project, [:compilers], &add_compiler/1)
    end

    defp add_compiler(nil), do: {:ok, {:code, quote(do: Mix.compilers() ++ [unquote(@compiler)])}}

    defp add_compiler(zipper) do
      node = Zipper.node(zipper)

      cond do
        Macro.to_string(node) =~ Atom.to_string(@compiler) -> {:ok, zipper}
        Igniter.Code.List.list?(zipper) -> Igniter.Code.List.append_new_to_list(zipper, @compiler)
        true -> {:ok, {:code, append_to_concatenation(node)}}
      end
    end

    defp append_to_concatenation({:++, _meta, [left, right]}) do
      quote do: unquote(left) ++ unquote(append_to_concatenation(right))
    end

    defp append_to_concatenation(node), do: quote(do: unquote(node) ++ [unquote(@compiler)])

    defp skill_path(relative), do: Path.join(@root, relative)

    defp write(igniter, files) do
      Enum.reduce(files, igniter, fn {path, contents}, igniter ->
        Igniter.create_new_file(igniter, path, contents, on_exists: :overwrite)
      end)
    end

    defp remove_stale(igniter, files) do
      kept = Enum.map(files, &elem(&1, 0))
      igniter = Igniter.include_glob(igniter, Path.join(@root, "references/*.md"))

      igniter.rewrite
      |> Rewrite.paths()
      |> Enum.filter(&String.starts_with?(&1, Path.join(@root, "references/")))
      |> Enum.reject(&(&1 in kept))
      |> Enum.reduce(igniter, &Igniter.rm(&2, &1))
    end

    defp point(igniter) do
      igniter
      |> instruction_files()
      |> Enum.reduce(igniter, &point_file(&2, &1))
    end

    defp instruction_files(igniter) do
      case Enum.filter(@instruction_files, &Igniter.exists?(igniter, &1)) do
        [] -> ["AGENTS.md"]
        existing -> existing
      end
    end

    defp point_file(igniter, path) do
      Igniter.create_or_update_file(igniter, path, Skill.pointer(), fn source ->
        Rewrite.Source.update(source, :content, &append_once/1)
      end)
    end

    defp append_once(contents) do
      case String.contains?(contents, Skill.marker()) do
        true -> contents
        false -> String.trim_trailing(contents) <> "\n\n" <> Skill.pointer()
      end
    end
  end
end
