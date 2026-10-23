defmodule Mix.Tasks.LineaUi.Install do
  @shortdoc "Sets LineaUI up in a Phoenix app and writes its Claude Code skill"

  @moduledoc """
  Run once after adding `{:linea_ui, ...}` to `mix.exs`, and again after each upgrade:

      mix linea_ui.install

  It writes the Claude Code skill (`mix linea_ui.gen.skill`), points `AGENTS.md` and
  `CLAUDE.md` (those that exist) at it, and prints the lines to add to `app.css`, `app.js`
  and the endpoint. Running it twice changes nothing the second time.
  """

  use Mix.Task

  @marker "<!-- linea_ui -->"
  @pointer """

  #{@marker}
  ## UI

  UI is LineaUI. Load `.claude/skills/linea-ui/SKILL.md` before writing or changing HEEx, and read
  the component's reference before using it. Regenerate it with `mix linea_ui.install` after upgrading.
  """

  @impl true
  def run(args) do
    Mix.Task.run("linea_ui.gen.skill", args)
    Enum.each(~w(AGENTS.md CLAUDE.md), &point/1)
    Mix.shell().info(instructions())
  end

  defp point(file) do
    case File.read(file) do
      {:ok, contents} -> append_once(file, contents)
      {:error, :enoent} -> :ok
    end
  end

  defp append_once(file, contents) do
    case String.contains?(contents, @marker) do
      true -> :ok
      false -> File.write!(file, String.trim_trailing(contents) <> "\n" <> @pointer)
    end
  end

  defp instructions do
    """

    Finish the setup by hand (once):

      assets/css/app.css, after @import "tailwindcss":
        @import "../../deps/linea_ui/assets/css/fonts.css";
        @import "../../deps/linea_ui/assets/css/linea_ui.css";

      assets/js/app.js:
        import {Hooks as LineaHooks} from "linea_ui"
        hooks: {...colocatedHooks, ...LineaHooks}

      lib/<app>_web/endpoint.ex:
        plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}

      lib/<app>_web.ex, in html_helpers/0:
        use LineaUI, avoid_conflicts: true
    """
  end
end
