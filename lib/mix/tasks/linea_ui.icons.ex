defmodule Mix.Tasks.LineaUi.Icons do
  @shortdoc "Downloads Hugeicons SVGs into the app (get, sync, search, update)"

  @moduledoc """
  Vendors the [Hugeicons](https://hugeicons.com) Stroke Rounded icons the app uses into a folder
  (`assets/vendor/hugeicons` by default), where `assets/css/hugeicons.cjs` reads them. No extra
  dependency: it downloads from GitHub with `:httpc` and verified TLS.

      mix linea_ui.icons get search-01 tick-02     # also accepts huge-search-01
      mix linea_ui.icons sync                      # downloads every huge-* name found in the sources
      mix linea_ui.icons sync --prune              # ...and removes vendored icons nobody references
      mix linea_ui.icons search invoice            # lists upstream names containing the term
      mix linea_ui.icons update                    # re-downloads every vendored icon at the ref

  `sync` scans `lib`, `assets/js`, `assets/css` and `priv/templates` of the app, plus the `lib` and
  `assets/js` of the `linea_ui` dependency (so the icons the kit's own components use are included) for
  names like `huge-search-01`. A name that does not exist upstream is reported, not fatal.

  ## Options

    * `--dir` - the folder of the SVGs (default `assets/vendor/hugeicons`)
    * `--ref` - the commit, tag or branch of `hugeicons/hugeicons` to download from. Defaults to the ref
      in the folder's `.hugeicons.json`, else to a commit pinned in this task (#{inspect("28aee18")}...);
      `--ref main` follows upstream
    * `--prune` - only for `sync`: removes the SVGs that no source references

  The folder also gets `.hugeicons.json` (the ref and the names) and Hugeicons' `LICENSE.md` (MIT).
  Every file is written to a temporary name and renamed, so a failed download leaves no partial file;
  a network failure ends the task with a non-zero exit.

  Point the Tailwind plugin at the folder:

      @plugin "../../deps/linea_ui/assets/css/hugeicons.cjs" { dir: "assets/vendor/hugeicons"; }
  """

  use Mix.Task

  @default_ref "28aee18eb297ee81942dac4e03e68cccce8a0613"
  @default_dir "assets/vendor/hugeicons"
  @repo "hugeicons/hugeicons"
  @manifest ".hugeicons.json"
  @license "LICENSE.md"
  @extensions ~w(.ex .exs .heex .eex .leex .js .jsx .ts .tsx .mjs .cjs .css .html)
  @name_regex ~r/(?<![A-Za-z0-9_-])huge-([a-z0-9]+(?:-[a-z0-9]+)*)/

  @type http :: (String.t() -> {:ok, binary()} | {:error, :not_found | term()})

  @impl Mix.Task
  def run(args) do
    {opts, rest} =
      OptionParser.parse!(args, strict: [dir: :string, ref: :string, prune: :boolean])

    dir = Keyword.get(opts, :dir, @default_dir)
    ref = Keyword.get_lazy(opts, :ref, fn -> manifest(dir)["ref"] || @default_ref end)

    command(rest, %{
      dir: dir,
      ref: ref,
      prune: opts[:prune] || false,
      roots: roots(),
      http: &fetch/1
    })
  end

  @doc false
  @spec command([String.t()], map()) :: :ok
  def command(["get" | names], ctx) when names != [] do
    names = Enum.map(names, &normalize!/1)
    download(names, ctx, :report_unknown)
  end

  def command(["sync"], ctx) do
    wanted = scan(ctx.roots)
    have = vendored(ctx.dir)
    missing = wanted -- have

    Mix.shell().info(
      "#{length(wanted)} icon names in the sources, #{length(missing)} to download"
    )

    unless missing == [], do: download(missing, ctx, :warn_unknown)
    if ctx.prune, do: prune(wanted, ctx)
    write_manifest(ctx)
    :ok
  end

  def command(["search", term], ctx) do
    term = term |> normalize!() |> String.trim()
    found = ctx |> upstream_names() |> Enum.filter(&String.contains?(&1, term))

    case found do
      [] -> Mix.shell().info("No upstream icon contains #{inspect(term)}")
      _ -> Enum.each(found, &Mix.shell().info("huge-" <> &1))
    end

    :ok
  end

  def command(["update"], ctx) do
    names = Enum.uniq(vendored(ctx.dir) ++ (manifest(ctx.dir)["names"] || []))

    case names do
      [] -> Mix.shell().info("Nothing vendored in #{ctx.dir}; run `get` or `sync` first")
      _ -> download(names, ctx, :warn_unknown, true)
    end

    :ok
  end

  def command(_, _ctx) do
    Mix.raise("""
    Usage:
      mix linea_ui.icons get NAME [NAME...]
      mix linea_ui.icons sync [--prune]
      mix linea_ui.icons search TERM
      mix linea_ui.icons update
    Options: --dir (default #{@default_dir}), --ref (default #{@default_ref})
    """)
  end

  # --- names

  @doc "`\"huge-Search-01\"`, `\"search-01.svg\"` and `\"search-01\"` all become `\"search-01\"`."
  @spec normalize!(String.t()) :: String.t()
  def normalize!(raw) do
    name =
      raw
      |> String.trim()
      |> String.downcase()
      |> String.replace_suffix(".svg", "")
      |> String.replace_prefix("huge-", "")

    case Regex.match?(~r/\A[a-z0-9]+(-[a-z0-9]+)*\z/, name) do
      true -> name
      false -> Mix.raise("Not an icon name: #{inspect(raw)}")
    end
  end

  # --- scanning

  @doc "The folders `sync` scans: the app's and the `linea_ui` dependency's."
  @spec roots() :: [String.t()]
  def roots do
    app = ~w(lib assets/js assets/css priv/templates)

    kit =
      case Mix.Project.deps_paths()[:linea_ui] do
        nil -> []
        path -> [Path.join(path, "lib"), Path.join(path, "assets/js")]
      end

    Enum.filter(app ++ kit, &File.dir?/1)
  end

  @doc "Sorted, unique icon names (without the `huge-` prefix) written in the files under `roots`."
  @spec scan([String.t()]) :: [String.t()]
  def scan(roots) do
    roots
    |> Enum.flat_map(&source_files/1)
    |> Enum.flat_map(&names_in(File.read!(&1)))
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc false
  @spec names_in(String.t()) :: [String.t()]
  def names_in(text) do
    @name_regex |> Regex.scan(text, capture: :all_but_first) |> List.flatten()
  end

  defp source_files(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: false)
    |> Enum.reject(&String.contains?(&1, ["/node_modules/", "/vendor/", "/_build/"]))
    |> Enum.filter(&(Path.extname(&1) in @extensions and File.regular?(&1)))
  end

  # --- vendored folder

  @doc false
  @spec vendored(String.t()) :: [String.t()]
  def vendored(dir) do
    dir
    |> Path.join("*.svg")
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".svg"))
    |> Enum.sort()
  end

  @doc "The names to remove: vendored, but not in `wanted`."
  @spec prunable([String.t()], [String.t()]) :: [String.t()]
  def prunable(vendored, wanted), do: vendored -- wanted

  defp prune([], _ctx),
    do: Mix.raise("No icon names found in the sources; refusing to prune everything")

  defp prune(wanted, ctx) do
    stale = prunable(vendored(ctx.dir), wanted)
    Enum.each(stale, &File.rm!(Path.join(ctx.dir, &1 <> ".svg")))
    Mix.shell().info("Pruned #{length(stale)} unreferenced icons#{list(stale)}")
  end

  defp list([]), do: ""
  defp list(names), do: ": " <> Enum.join(names, ", ")

  @doc false
  @spec manifest(String.t()) :: map()
  def manifest(dir) do
    with {:ok, json} <- File.read(Path.join(dir, @manifest)),
         {:ok, %{} = map} <- Jason.decode(json) do
      map
    else
      _ -> %{}
    end
  end

  @doc false
  def write_manifest(ctx) do
    File.mkdir_p!(ctx.dir)

    json =
      Jason.encode!(
        %{
          "source" => "https://github.com/#{@repo}",
          "license" => @license,
          "ref" => ctx.ref,
          "names" => vendored(ctx.dir)
        },
        pretty: true
      )

    atomic_write(Path.join(ctx.dir, @manifest), json <> "\n")
  end

  # --- downloading

  defp download(names, ctx, unknown, force_license \\ false) do
    Mix.shell().info("Downloading #{length(names)} icons at #{ctx.ref} into #{ctx.dir}")

    results =
      names
      |> Task.async_stream(&{&1, ctx.http.(raw_url(ctx.ref, "icons/#{&1}.svg"))},
        max_concurrency: 8,
        timeout: 60_000,
        ordered: true
      )
      |> Enum.map(fn {:ok, result} -> result end)

    File.mkdir_p!(ctx.dir)

    {ok, failed} = Enum.split_with(results, &match?({_, {:ok, _}}, &1))

    Enum.each(ok, fn {name, {:ok, body}} ->
      atomic_write(Path.join(ctx.dir, name <> ".svg"), body)
    end)

    unknown_names = for {name, {:error, :not_found}} <- failed, do: name
    network = for {name, {:error, reason}} <- failed, reason != :not_found, do: {name, reason}

    Mix.shell().info("Downloaded #{length(ok)} icons")
    report_unknown(unknown_names, ctx, unknown)
    license(ctx, force_license or not File.exists?(Path.join(ctx.dir, @license)))
    write_manifest(ctx)

    case network do
      [] ->
        if unknown == :report_unknown and unknown_names != [],
          do: Mix.raise("Unknown icons: #{Enum.join(unknown_names, ", ")}")

        :ok

      _ ->
        Mix.raise(
          "Network failure for #{Enum.map_join(network, ", ", fn {n, r} -> "#{n} (#{inspect(r)})" end)}"
        )
    end
  end

  defp report_unknown([], _ctx, _), do: :ok

  defp report_unknown(names, ctx, _mode) do
    upstream = safe_upstream_names(ctx)

    Enum.each(names, fn name ->
      hint =
        case suggestions(name, upstream) do
          [] -> ""
          similar -> " Did you mean: " <> Enum.map_join(similar, ", ", &("huge-" <> &1)) <> "?"
        end

      Mix.shell().error("Unknown icon #{inspect("huge-" <> name)} at #{ctx.ref}.#{hint}")
    end)
  end

  @doc "Up to 5 upstream names close to `name`: containing it, or with a high string similarity."
  @spec suggestions(String.t(), [String.t()]) :: [String.t()]
  def suggestions(name, upstream) do
    {contain, rest} = Enum.split_with(upstream, &String.contains?(&1, name))

    similar =
      rest
      |> Enum.map(&{String.jaro_distance(name, &1), &1})
      |> Enum.filter(fn {score, _} -> score >= 0.85 end)
      |> Enum.sort_by(&elem(&1, 0), :desc)
      |> Enum.map(&elem(&1, 1))

    Enum.take(contain ++ similar, 5)
  end

  defp license(_ctx, false), do: :ok

  defp license(ctx, true) do
    case ctx.http.(raw_url(ctx.ref, @license)) do
      {:ok, body} -> atomic_write(Path.join(ctx.dir, @license), body)
      {:error, reason} -> Mix.raise("Could not download #{@license}: #{inspect(reason)}")
    end
  end

  defp atomic_write(path, body) do
    tmp = path <> ".tmp-#{System.unique_integer([:positive])}"

    try do
      File.write!(tmp, body)
      File.rename!(tmp, path)
    after
      File.rm(tmp)
    end
  end

  # --- upstream listing

  defp upstream_names(ctx) do
    case tree(ctx) do
      {:ok, names} -> names
      {:error, reason} -> Mix.raise("Could not list the upstream icons: #{inspect(reason)}")
    end
  end

  defp safe_upstream_names(ctx) do
    case tree(ctx) do
      {:ok, names} -> names
      {:error, _} -> []
    end
  end

  defp tree(ctx) do
    cache =
      Path.join(
        System.tmp_dir!(),
        "linea_ui_hugeicons_tree_#{String.replace(ctx.ref, ~r/[^A-Za-z0-9._-]/, "_")}.json"
      )

    case cached(cache, ctx.ref) do
      {:ok, names} ->
        {:ok, names}

      :miss ->
        with {:ok, body} <-
               ctx.http.("https://api.github.com/repos/#{@repo}/git/trees/#{ctx.ref}?recursive=1"),
             {:ok, names} <- parse_tree(body) do
          File.write(cache, Jason.encode!(names))
          {:ok, names}
        end
    end
  end

  # a pinned commit never changes; a branch name is cached for an hour
  defp cached(path, ref) do
    with {:ok, %{mtime: mtime}} <- File.stat(path, time: :posix),
         true <- ref =~ ~r/\A[0-9a-f]{40}\z/ or System.os_time(:second) - mtime < 3600,
         {:ok, json} <- File.read(path),
         {:ok, [_ | _] = names} <- Jason.decode(json) do
      {:ok, names}
    else
      _ -> :miss
    end
  end

  @doc false
  @spec parse_tree(binary()) :: {:ok, [String.t()]} | {:error, term()}
  def parse_tree(body) do
    case Jason.decode(body) do
      {:ok, %{"tree" => tree}} ->
        {:ok,
         for(
           %{"path" => "icons/" <> file} <- tree,
           String.ends_with?(file, ".svg"),
           do: String.replace_suffix(file, ".svg", "")
         )
         |> Enum.sort()}

      {:ok, other} ->
        {:error, {:unexpected_response, other["message"] || "no tree"}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp raw_url(ref, path), do: "https://raw.githubusercontent.com/#{@repo}/#{ref}/#{path}"

  # --- http

  @doc false
  @spec fetch(String.t()) :: {:ok, binary()} | {:error, :not_found | term()}
  def fetch(url) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    http_opts = [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 3,
        customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
      ],
      timeout: 30_000,
      connect_timeout: 10_000
    ]

    request = {String.to_charlist(url), [{~c"user-agent", ~c"linea_ui"}, {~c"accept", ~c"*/*"}]}

    case :httpc.request(:get, request, http_opts, body_format: :binary) do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, body}
      {:ok, {{_, 404, _}, _, _}} -> {:error, :not_found}
      {:ok, {{_, status, _}, _, _}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end
end
