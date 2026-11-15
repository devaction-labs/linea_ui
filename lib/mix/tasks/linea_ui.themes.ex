defmodule Mix.Tasks.LineaUi.Themes do
  @shortdoc "Writes the kit's named themes to assets/css/parts/themes.css"

  @moduledoc """
  Rebuilds `assets/css/parts/themes.css` from the seeds in `LineaUI.Theme` (run it in the linea_ui repository
  after changing a seed). `--check` only compares and fails when the file is out of date.

      mix linea_ui.themes
      mix linea_ui.themes --check
  """

  use Mix.Task

  @path "assets/css/parts/themes.css"

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [check: :boolean])
    css = LineaUI.Theme.stylesheet()

    cond do
      opts[:check] && File.read(@path) == {:ok, css} -> Mix.shell().info("#{@path} is up to date")
      opts[:check] -> Mix.raise("#{@path} is out of date: run mix linea_ui.themes")
      true -> File.write!(@path, css) && Mix.shell().info("wrote #{@path}")
    end
  end
end
