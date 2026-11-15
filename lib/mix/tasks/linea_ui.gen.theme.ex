defmodule Mix.Tasks.LineaUi.Gen.Theme do
  @shortdoc "Generates a named theme (light and dark) for the app"

  @moduledoc """
  Builds a theme in the spirit of daisyUI's theme generator: give it an accent and it derives the grays, lines,
  text, the soft and ink versions of the accent, charts, focus ring and corners, in a light and a dark version.

      mix linea_ui.gen.theme acme --accent "#7c3aed"
      mix linea_ui.gen.theme acme --accent "#7c3aed" --dark-accent "#a78bfa" --neutral cool --radius lg
      mix linea_ui.gen.theme paper --accent "#b4532a" --neutral 80 --chroma 0.016 --paper --radius sm

  It writes the CSS to `assets/css/themes/<id>.css` (`--out` changes it; `--print` only prints it). Import it in
  `app.css` after the kit:

      @import "./themes/acme.css";

  and list the theme in the picker:

      config :linea_ui, :themes, extra: [%{id: "acme", label: "Acme"}]

  ## Options

    * `--accent` - the accent of the light version (required), `#rrggbb`
    * `--dark-accent` - the accent of the dark version (default: the light one, lifted to read on dark)
    * `--neutral` - the hue of the grays: degrees, or `neutral`, `cool`, `slate`, `warm`, `stone`
    * `--chroma` - how tinted the grays are, 0 to about 0.03 (default 0.008)
    * `--radius` - `none`, `sm`, `md` (default) or `lg`
    * `--paper` - tints the cards too, not only the page
    * `--dark-lift` - lighter dark surfaces, 0 (default) to about 0.12
    * `--label` - the name in the picker (default: the id, capitalized)
  """

  use Mix.Task

  @switches [
    accent: :string,
    dark_accent: :string,
    neutral: :string,
    chroma: :float,
    radius: :string,
    paper: :boolean,
    dark_lift: :float,
    label: :string,
    out: :string,
    print: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, rest} = OptionParser.parse!(args, strict: @switches)

    id =
      case rest do
        [id] -> id
        _ -> Mix.raise("usage: mix linea_ui.gen.theme <id> --accent \"#rrggbb\" [options]")
      end

    seed =
      try do
        LineaUI.Theme.seed(id, opts)
      rescue
        error in ArgumentError -> Mix.raise(error.message)
      end

    css = LineaUI.Theme.css(seed)

    if opts[:print] do
      Mix.shell().info(css)
    else
      path = opts[:out] || Path.join(["assets", "css", "themes", "#{id}.css"])
      File.mkdir_p!(Path.dirname(path))

      File.write!(
        path,
        "/* #{seed.label}: mix linea_ui.gen.theme #{Enum.join(args, " ")} */\n" <> css
      )

      Mix.shell().info("""
      wrote #{path}

      Import it in app.css, after the kit:

          @import "./themes/#{id}.css";

      and offer it in the picker:

          config :linea_ui, :themes, extra: [%{id: "#{id}", label: "#{seed.label}"}]
      """)
    end
  end
end
