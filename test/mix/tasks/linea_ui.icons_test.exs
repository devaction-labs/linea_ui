defmodule Mix.Tasks.LineaUi.IconsTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.LineaUi.Icons

  @ref String.duplicate("a", 40)
  @svg ~s|<svg width="24" height="24" stroke="#141B34"></svg>|
  @tree Jason.encode!(%{
          "tree" => [
            %{"path" => "icons/search-01.svg", "type" => "blob"},
            %{"path" => "icons/search-02.svg", "type" => "blob"},
            %{"path" => "icons/tick-02.svg", "type" => "blob"},
            %{"path" => "README.md", "type" => "blob"}
          ]
        })

  setup do
    base = Path.join(System.tmp_dir!(), "linea_icons_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)
    on_exit(fn -> File.rm_rf!(base) end)

    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)

    {:ok, base: base, dir: Path.join(base, "icons")}
  end

  # the injected HTTP layer: icons search-01, search-02 and tick-02 exist; "boom" fails the network
  defp http(url) do
    send(self(), {:http, url})

    cond do
      String.contains?(url, "/git/trees/") -> {:ok, @tree}
      String.ends_with?(url, "LICENSE.md") -> {:ok, "MIT License"}
      String.ends_with?(url, "boom.svg") -> {:error, :timeout}
      Regex.match?(~r{/icons/(search-01|search-02|tick-02)\.svg\z}, url) -> {:ok, @svg}
      true -> {:error, :not_found}
    end
  end

  defp ctx(dir, extra \\ %{}) do
    Map.merge(%{dir: dir, ref: @ref <> "", prune: false, roots: [], http: &http/1}, extra)
  end

  describe "normalize!/1" do
    test "accepts bare, prefixed, uppercase and .svg names" do
      for raw <- ["search-01", "huge-search-01", " Huge-Search-01 ", "search-01.svg"] do
        assert Icons.normalize!(raw) == "search-01"
      end
    end

    test "rejects anything that is not a name" do
      for raw <- ["", "../x", "a/b", "a_b", "huge-"] do
        assert_raise Mix.Error, fn -> Icons.normalize!(raw) end
      end
    end
  end

  describe "scanning" do
    test "extracts huge-* names and ignores css variables and wildcards", %{base: base} do
      File.mkdir_p!(Path.join(base, "lib"))
      File.mkdir_p!(Path.join(base, "lib/vendor"))

      File.write!(
        Path.join(base, "lib/a.heex"),
        ~s|<.icon name="huge-search-01" /> <i class="huge-tick-02 size-4">|
      )

      File.write!(
        Path.join(base, "lib/b.js"),
        ~s|const x = "huge-search-01"; `--huge-skipped`; "huge-*"|
      )

      File.write!(Path.join(base, "lib/notes.txt"), "huge-ignored-01")
      File.write!(Path.join(base, "lib/vendor/c.js"), "huge-vendored-01")

      assert Icons.scan([Path.join(base, "lib")]) == ["search-01", "tick-02"]
    end

    test "names_in/1 keeps multi-part names" do
      assert Icons.names_in("huge-arrow-down-01 and huge-a1") == ["arrow-down-01", "a1"]
    end
  end

  describe "prune selection" do
    test "is what is vendored and not wanted" do
      assert Icons.prunable(["a", "b", "c"], ["b"]) == ["a", "c"]
    end

    test "sync --prune removes unreferenced icons", %{base: base, dir: dir} do
      File.mkdir_p!(Path.join(base, "lib"))
      File.write!(Path.join(base, "lib/a.ex"), ~s|"huge-tick-02"|)
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "old-01.svg"), "x")

      Icons.command(["sync"], ctx(dir, %{prune: true, roots: [Path.join(base, "lib")]}))

      assert Icons.vendored(dir) == ["tick-02"]
      assert Icons.manifest(dir)["names"] == ["tick-02"]
    end

    test "refuses to prune when the sources name no icon", %{base: base, dir: dir} do
      File.mkdir_p!(Path.join(base, "lib"))
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "old-01.svg"), "x")

      assert_raise Mix.Error, ~r/refusing to prune/, fn ->
        Icons.command(["sync"], ctx(dir, %{prune: true, roots: [Path.join(base, "lib")]}))
      end

      assert Icons.vendored(dir) == ["old-01"]
    end
  end

  describe "get" do
    test "downloads icons, the license and the manifest", %{dir: dir} do
      Icons.command(["get", "huge-search-01", "tick-02"], ctx(dir))

      assert Icons.vendored(dir) == ["search-01", "tick-02"]
      assert File.read!(Path.join(dir, "LICENSE.md")) == "MIT License"

      assert %{"ref" => @ref, "names" => ["search-01", "tick-02"], "license" => "LICENSE.md"} =
               Icons.manifest(dir)

      assert_received {:http, "https://raw.githubusercontent.com/hugeicons/hugeicons/" <> _}
    end

    test "reports unknown names with suggestions and exits non-zero, keeping the good ones", %{
      dir: dir
    } do
      assert_raise Mix.Error, ~r/Unknown icons: search-03/, fn ->
        Icons.command(["get", "search-03", "tick-02"], ctx(dir))
      end

      assert Icons.vendored(dir) == ["tick-02"]
      assert_received {:mix_shell, :error, [message]}
      assert message =~ "huge-search-03" and message =~ "huge-search-01"
    end

    test "a network failure raises and leaves no partial file", %{dir: dir} do
      assert_raise Mix.Error, ~r/Network failure for boom/, fn ->
        Icons.command(["get", "boom"], ctx(dir))
      end

      assert Icons.vendored(dir) == []
      assert Path.wildcard(Path.join(dir, "*.tmp*")) == []
    end
  end

  describe "sync, search, update" do
    test "sync downloads only the missing icons", %{base: base, dir: dir} do
      File.mkdir_p!(Path.join(base, "lib"))
      File.write!(Path.join(base, "lib/a.ex"), ~s|"huge-search-01" "huge-tick-02"|)
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "search-01.svg"), "kept")

      Icons.command(["sync"], ctx(dir, %{roots: [Path.join(base, "lib")]}))

      assert File.read!(Path.join(dir, "search-01.svg")) == "kept"
      assert File.read!(Path.join(dir, "tick-02.svg")) == @svg
    end

    test "search lists upstream names containing the term", %{dir: dir} do
      Icons.command(["search", "search"], ctx(dir, %{ref: String.duplicate("b", 40)}))

      assert_received {:mix_shell, :info, ["huge-search-01"]}
      assert_received {:mix_shell, :info, ["huge-search-02"]}
      refute_received {:mix_shell, :info, ["huge-tick-02"]}
    end

    test "update re-downloads every vendored icon", %{dir: dir} do
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "tick-02.svg"), "old")

      Icons.command(["update"], ctx(dir))

      assert File.read!(Path.join(dir, "tick-02.svg")) == @svg
    end

    test "an unknown command prints the usage", %{dir: dir} do
      assert_raise Mix.Error, ~r/Usage/, fn -> Icons.command(["nope"], ctx(dir)) end
    end
  end

  test "parse_tree/1 keeps only icons/*.svg names" do
    assert Icons.parse_tree(@tree) == {:ok, ["search-01", "search-02", "tick-02"]}
    assert {:error, _} = Icons.parse_tree(~s|{"message": "rate limit"}|)
  end
end
