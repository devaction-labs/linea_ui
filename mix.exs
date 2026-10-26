defmodule LineaUI.MixProject do
  use Mix.Project

  @version "0.8.0"
  @source_url "https://github.com/devaction-labs/linea_ui"

  def project do
    [
      app: :linea_ui,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      deps: deps(),
      aliases: aliases(),
      description: "Phoenix LiveView components with the LineOne design.",
      package: package(),
      source_url: @source_url,
      docs: [
        main: "LineaUI",
        extras: ["README.md", "CHANGELOG.md", "LICENSE"],
        source_ref: "v#{@version}"
      ]
    ]
  end

  def application do
    [mod: {LineaUI.Application, []}, extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.2"},
      {:igniter, "~> 0.6", optional: true},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "js.test": ["cmd node --test \"assets/js/linea_ui/**/*.test.js\""],
      precommit: ["compile --warnings-as-errors", "format", "test", "js.test"]
    ]
  end

  defp package do
    [
      licenses: ["LicenseRef-LineaUI"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/main/CHANGELOG.md"
      },
      files:
        ~w(lib assets/css assets/js priv package.json README.md LICENSE CHANGELOG.md mix.exs),
      exclude_patterns: [~r/\.test\.js$/]
    ]
  end
end
