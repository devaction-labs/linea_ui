if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.LineaUi.Install do
    @shortdoc "Sets LineaUI up in a Phoenix app and writes its Claude Code skill"

    @moduledoc """
    Sets LineaUI up in a Phoenix app. The one command that adds the dependency and runs this is

        mix igniter.install linea_ui

    and running `mix linea_ui.install` again after an upgrade changes only what the new version
    changed. It edits the host app, showing the diff for you to confirm:

    * `assets/css/app.css`: imports LineaUI's fonts and styles (and `@source` for its templates when
      the file uses `source(none)`)
    * `assets/js/app.js`: imports LineaUI's hooks and spreads them into the `LiveSocket` `hooks`
    * the endpoint: `plug Plug.Static` for the fonts, after the app's own
    * `lib/my_app_web.ex`: `use LineaUI, avoid_conflicts: true` in `html_helpers/0`
    * `.claude/skills/linea-ui/`: the Claude Code skill, and a pointer to it in `AGENTS.md` and
      `CLAUDE.md` (`AGENTS.md` is created when neither exists)

    Every step skips what is already there, and warns instead of failing when it cannot find its place.

    ## Options

    * `--hugeicons` - draws the components' glyphs with Hugeicons: adds the `hugeicons` dependency,
      `config :linea_ui, :icons, :hugeicons` and the Tailwind plugin to `app.css`
    * `--replace-daisyui` - removes the daisyUI and heroicons plugins from `app.css`, which LineaUI's
      styles can conflict with. Without it they stay and a warning says so
    * `--no-skill` - does not write the Claude Code skill

    `mix linea_ui.gen.skill` refreshes only the skill. This task needs the `igniter` dependency; without
    it the task writes the skill and prints the lines to add by hand.
    """

    use Igniter.Mix.Task

    alias LineaUI.Installer.{Agent, Assets, Hugeicons, Web}

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :linea_ui,
        example: "mix igniter.install linea_ui",
        schema: [hugeicons: :boolean, replace_daisyui: :boolean, skill: :boolean],
        defaults: [hugeicons: false, replace_daisyui: false, skill: true]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = igniter.args.options

      igniter
      |> Assets.css(options)
      |> Assets.js()
      |> Web.endpoint()
      |> Web.html_helpers()
      |> hugeicons(options[:hugeicons])
      |> skill(options[:skill])
      |> Igniter.add_notice(notice())
    end

    defp hugeicons(igniter, true), do: Hugeicons.install(igniter)
    defp hugeicons(igniter, false), do: igniter

    defp skill(igniter, true), do: Agent.skill(igniter)
    defp skill(igniter, false), do: igniter

    defp notice do
      """
      LineaUI is set up. Use a component in any template:

          <.button color="primary">Save</.button>

      After upgrading the package, run `mix linea_ui.install` again, or `mix linea_ui.gen.skill`
      to refresh only the Claude Code skill.
      """
    end
  end
else
  defmodule Mix.Tasks.LineaUi.Install do
    @shortdoc "Writes LineaUI's Claude Code skill and prints the setup lines"

    @moduledoc """
    Writes the Claude Code skill (`mix linea_ui.gen.skill`), points `AGENTS.md` and `CLAUDE.md`
    (those that exist) at it, and prints the lines to add to `app.css`, `app.js`, the endpoint and
    the web module, and the lines for the optional Hugeicons icon set. Running it twice changes
    nothing the second time.

    With the `igniter` dependency this task makes those edits itself:

        mix igniter.install linea_ui
    """

    use Mix.Task

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
      case String.contains?(contents, LineaUI.Skill.marker()) do
        true ->
          :ok

        false ->
          File.write!(file, String.trim_trailing(contents) <> "\n\n" <> LineaUI.Skill.pointer())
      end
    end

    defp instructions do
      """

      Finish the setup by hand (once), or add {:igniter, "~> 0.6", only: :dev, runtime: false} and
      run `mix igniter.install linea_ui` to have it done for you:

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

      Optional: Hugeicons instead of LineOne's glyphs (the README, section "Icons"):

        mix.exs, in deps:
          {:hugeicons, github: "hugeicons/hugeicons", ref: "3365154e0ae2461fbfb6249b89649127207a4f9e",
           sparse: "icons", app: false, compile: false, depth: 1}

        config/config.exs:
          config :linea_ui, :icons, :hugeicons

        assets/css/app.css, after the linea_ui.css import:
          @plugin "../../deps/linea_ui/assets/css/hugeicons.cjs" { dir: "deps/hugeicons/icons"; }
      """
    end
  end
end
