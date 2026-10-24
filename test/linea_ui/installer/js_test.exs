defmodule LineaUI.Installer.JsTest do
  use ExUnit.Case, async: true

  alias LineaUI.Installer.Js

  @phoenix File.read!("test/fixtures/phoenix_1_8/app.js")
  @import_line ~s|import {Hooks as LineaHooks} from "linea_ui"|

  test "imports the hooks after the colocated hooks and spreads them next to them" do
    assert {:ok, js} = Js.register_hooks(@phoenix)

    assert js =~
             ~s|import {hooks as colocatedHooks} from "phoenix-colocated/e2e_app"\n#{@import_line}|

    assert js =~ "hooks: {...colocatedHooks, ...LineaHooks},"
  end

  test "registering twice changes nothing" do
    {:ok, once} = Js.register_hooks(@phoenix)
    assert Js.register_hooks(once) == :unchanged
  end

  test "imports after the LiveView import when there are no colocated hooks" do
    js = """
    import {Socket} from "phoenix"
    import {LiveSocket} from "phoenix_live_view"
    const liveSocket = new LiveSocket("/live", Socket, {hooks: {}})
    """

    assert {:ok, edited} = Js.register_hooks(js)
    assert edited =~ ~s|from "phoenix_live_view"\n#{@import_line}\n|
    assert edited =~ "{hooks: {...LineaHooks}}"
  end

  test "keeps the hooks already listed, with or without a trailing comma" do
    js = """
    import {LiveSocket} from "phoenix_live_view"
    const liveSocket = new LiveSocket("/live", Socket, {hooks: {Foo, Bar,}})
    """

    assert {:ok, edited} = Js.register_hooks(js)
    assert edited =~ "hooks: {Foo, Bar, ...LineaHooks}"
  end

  test "spreads a hooks variable" do
    js = """
    import {LiveSocket} from "phoenix_live_view"
    let Hooks = {}
    const liveSocket = new LiveSocket("/live", Socket, {params: {}, hooks: Hooks})
    """

    assert {:ok, edited} = Js.register_hooks(js)
    assert edited =~ "hooks: {...Hooks, ...LineaHooks}})"
  end

  test "adds the hooks option when there is none, on its own line in a multi-line object" do
    js = """
    import {LiveSocket} from "phoenix_live_view"
    const liveSocket = new LiveSocket("/live", Socket, {
      params: {_csrf_token: csrfToken},
    })
    """

    assert {:ok, edited} = Js.register_hooks(js)
    assert edited =~ "{\n  hooks: {...LineaHooks},\n  params: {_csrf_token: csrfToken},\n})"
  end

  test "adds the hooks option to a single-line object" do
    js = """
    import {LiveSocket} from "phoenix_live_view"
    const liveSocket = new LiveSocket("/live", Socket, {params: {}})
    """

    assert {:ok, edited} = Js.register_hooks(js)
    assert edited =~ "{hooks: {...LineaHooks}, params: {}})"
  end

  test "errors when there is no LiveSocket to register on" do
    assert Js.register_hooks(~s|import "phoenix_html"\n|) == :error
    refute Js.live_socket?("console.log(1)")
  end

  test "errors rather than guess when the hooks option is neither an object nor a name" do
    js = """
    import {LiveSocket} from "phoenix_live_view"
    const liveSocket = new LiveSocket("/live", Socket, {hooks: {Foo: {mounted() {}}}})
    """

    assert Js.register_hooks(js) == :error
  end
end
