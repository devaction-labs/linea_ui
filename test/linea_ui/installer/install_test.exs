defmodule LineaUI.Installer.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  @fixtures "test/fixtures/phoenix_1_8"

  @files %{
    "assets/css/app.css" => File.read!("#{@fixtures}/app.css"),
    "assets/js/app.js" => File.read!("#{@fixtures}/app.js"),
    "lib/e2e_app_web/endpoint.ex" => File.read!("#{@fixtures}/endpoint.ex"),
    "lib/e2e_app_web.ex" => File.read!("#{@fixtures}/e2e_app_web.ex"),
    "AGENTS.md" => "# Guidelines\n\nBe careful.\n",
    ".formatter.exs" => "[import_deps: [:phoenix], inputs: [\"{config,lib}/**/*.{ex,exs}\"]]\n"
  }

  defp project(files \\ %{}) do
    test_project(app_name: :e2e_app, files: Map.merge(@files, files))
  end

  defp install(igniter, args \\ []) do
    Igniter.compose_task(igniter, "linea_ui.install", args)
  end

  defp settle(igniter), do: apply_igniter!(igniter)

  defp content(igniter, path) do
    igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)
  end

  describe "app.css" do
    test "imports the fonts and styles and adds the @source for source(none)" do
      project()
      |> install()
      |> assert_has_patch("assets/css/app.css", """
      + |@import "../../deps/linea_ui/assets/css/fonts.css";
      + |@import "../../deps/linea_ui/assets/css/linea_ui.css";
      """)
      |> assert_has_patch("assets/css/app.css", """
      + |@source "../../deps/linea_ui/lib";
      """)
    end

    test "keeps daisyUI and warns that it can conflict" do
      igniter = install(project())

      assert content(igniter, "assets/css/app.css") =~ "daisyui"
      assert_has_warning(igniter, &(&1 =~ "daisyUI" and &1 =~ "--replace-daisyui"))
    end

    test "--replace-daisyui removes the daisyUI and heroicons plugins and does not warn" do
      igniter = install(project(), ["--replace-daisyui"])
      css = content(igniter, "assets/css/app.css")

      refute css =~ "daisyui"
      refute css =~ "heroicons"
      assert css =~ "linea_ui.css"
      refute Enum.any?(igniter.warnings, &(&1 =~ "daisyUI"))
    end

    test "no @source without source(none)" do
      css = ~s|@import "tailwindcss";\n|
      igniter = install(project(%{"assets/css/app.css" => css}))

      refute content(igniter, "assets/css/app.css") =~ "@source"
    end

    test "warns and goes on when app.css is missing" do
      igniter =
        install(test_project(app_name: :e2e_app, files: Map.delete(@files, "assets/css/app.css")))

      assert_has_warning(igniter, &(&1 =~ "assets/css/app.css was not found"))
      assert_has_patch(igniter, "assets/js/app.js", "+ |import {Hooks as LineaHooks}")
    end

    test "warns when app.css does not import Tailwind" do
      igniter = install(project(%{"assets/css/app.css" => "body { color: red }\n"}))

      assert_has_warning(igniter, &(&1 =~ ~s|no `@import "tailwindcss"`|))
      assert content(igniter, "assets/css/app.css") == "body { color: red }\n"
    end
  end

  describe "app.js" do
    test "imports the hooks and spreads them next to the colocated ones" do
      project()
      |> install()
      |> assert_has_patch("assets/js/app.js", """
      + |import {Hooks as LineaHooks} from "linea_ui"
      """)
      |> assert_has_patch("assets/js/app.js", """
      - |  hooks: {...colocatedHooks},
      + |  hooks: {...colocatedHooks, ...LineaHooks},
      """)
    end

    test "warns when it cannot find the LiveSocket" do
      igniter = install(project(%{"assets/js/app.js" => "console.log(1)\n"}))

      assert_has_warning(igniter, &(&1 =~ "LineaHooks was not registered"))
    end
  end

  describe "endpoint" do
    test "serves the fonts with a second Plug.Static after the app's own" do
      igniter = install(project())
      endpoint = content(igniter, "lib/e2e_app_web/endpoint.ex")

      assert endpoint =~
               ~s|plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}|

      {own, linea} = {index(endpoint, "from: :e2e_app"), index(endpoint, "/linea_ui")}
      assert own < linea
      assert linea < index(endpoint, "Plug.RequestId")
    end

    test "warns when there is no endpoint" do
      igniter = install(project(%{"lib/e2e_app_web/endpoint.ex" => "defmodule Other do\nend\n"}))

      assert_has_warning(igniter, &(&1 =~ "E2eAppWeb.Endpoint was not found"))
    end

    test "warns when the endpoint has no Plug.Static" do
      endpoint = """
      defmodule E2eAppWeb.Endpoint do
        use Phoenix.Endpoint, otp_app: :e2e_app

        plug Plug.RequestId
      end
      """

      igniter = install(project(%{"lib/e2e_app_web/endpoint.ex" => endpoint}))

      assert_has_warning(igniter, &(&1 =~ "no `plug Plug.Static`"))
    end
  end

  describe "web module" do
    test "uses LineaUI after the CoreComponents import in html_helpers/0" do
      igniter = install(project())
      web = content(igniter, "lib/e2e_app_web.ex")

      assert web =~ "use LineaUI, avoid_conflicts: true"
      assert index(web, "import E2eAppWeb.CoreComponents") < index(web, "use LineaUI")
      assert index(web, "use LineaUI") < index(web, "alias Phoenix.LiveView.JS")
    end

    test "falls back to the Phoenix.HTML import without CoreComponents" do
      web = """
      defmodule E2eAppWeb do
        defp html_helpers do
          quote do
            import Phoenix.HTML
            alias Phoenix.LiveView.JS
          end
        end
      end
      """

      igniter = install(project(%{"lib/e2e_app_web.ex" => web}))

      assert content(igniter, "lib/e2e_app_web.ex") =~
               "import Phoenix.HTML\n      use LineaUI, avoid_conflicts: true"
    end

    test "warns when html_helpers/0 is not where it expects" do
      web = "defmodule E2eAppWeb do\n  def other, do: :ok\nend\n"
      igniter = install(project(%{"lib/e2e_app_web.ex" => web}))

      assert_has_warning(igniter, &(&1 =~ "html_helpers/0"))
    end

    test "leaves a web module that already uses LineaUI alone" do
      web = """
      defmodule E2eAppWeb do
        defp html_helpers do
          quote do
            use LineaUI
          end
        end
      end
      """

      igniter = install(project(%{"lib/e2e_app_web.ex" => web}))

      assert content(igniter, "lib/e2e_app_web.ex") == web
    end
  end

  describe "skill" do
    test "creates SKILL.md and the component references" do
      project()
      |> install()
      |> assert_creates(".claude/skills/linea-ui/SKILL.md")
      |> assert_creates(".claude/skills/linea-ui/references/button.md")
    end

    test "points the existing AGENTS.md at it, once" do
      igniter = install(project())
      agents = content(igniter, "AGENTS.md")

      assert agents =~ "# Guidelines\n\nBe careful.\n\n<!-- linea_ui -->\n## UI"
      assert length(String.split(agents, "<!-- linea_ui -->")) == 2
    end

    test "points both AGENTS.md and CLAUDE.md when both exist" do
      igniter = install(project(%{"CLAUDE.md" => "# Claude\n"}))

      assert content(igniter, "CLAUDE.md") =~ "<!-- linea_ui -->"
      assert content(igniter, "AGENTS.md") =~ "<!-- linea_ui -->"
    end

    test "creates AGENTS.md when neither exists" do
      igniter = install(test_project(app_name: :e2e_app, files: Map.delete(@files, "AGENTS.md")))

      assert_creates(igniter, "AGENTS.md")
      assert content(igniter, "AGENTS.md") =~ "UI is LineaUI."
      refute Igniter.exists?(igniter, "CLAUDE.md")
    end

    test "--no-skill writes neither the skill nor the pointer" do
      igniter = install(project(), ["--no-skill"])

      refute_creates(igniter, ".claude/skills/linea-ui/SKILL.md")
      refute Igniter.changed?(igniter, "AGENTS.md")
    end

    test "removes references of components that no longer exist" do
      stale = ".claude/skills/linea-ui/references/gone.md"
      igniter = project() |> Igniter.create_new_file(stale, "old") |> install()

      assert stale in igniter.rms
    end
  end

  describe "--hugeicons" do
    test "adds the dependency, the config and the Tailwind plugin" do
      igniter = install(project(), ["--hugeicons"])

      assert content(igniter, "mix.exs") =~ ":hugeicons"
      assert content(igniter, "mix.exs") =~ ~s|sparse: "icons"|
      assert content(igniter, "config/config.exs") =~ "config :linea_ui, icons: :hugeicons"
      assert content(igniter, "assets/css/app.css") =~ "hugeicons.cjs"
    end

    test "is off by default" do
      igniter = install(project())

      refute content(igniter, "assets/css/app.css") =~ "hugeicons"

      refute Igniter.exists?(igniter, "config/config.exs") and
               content(igniter, "config/config.exs") =~ "hugeicons"
    end
  end

  describe "idempotence" do
    test "a second run changes nothing" do
      first = project() |> install() |> settle()

      first
      |> install()
      |> assert_unchanged()
    end

    test "a second run with every flag changes nothing" do
      args = ["--hugeicons", "--replace-daisyui"]
      first = project() |> install(args) |> settle()

      first
      |> install(args)
      |> assert_unchanged()
    end
  end

  test "--replace-daisyui adds a notice that CoreComponents and Layouts still use its classes" do
    igniter = install(project(), ["--replace-daisyui"])

    assert_has_notice(igniter, &(&1 =~ "CoreComponents" and &1 =~ "heroicons"))
  end

  test "ends with a notice that says how to use a component and how to refresh" do
    igniter = install(project())

    assert_has_notice(igniter, &(&1 =~ "<.badge" and &1 =~ "mix linea_ui.gen.skill"))
  end

  defp index(string, part) do
    {position, _length} = :binary.match(string, part)
    position
  end
end
