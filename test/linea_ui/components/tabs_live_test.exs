defmodule LineaUI.Components.TabsLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.TabsLive

  test "the hook's on_change reaches the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TabsLive)
    view |> element("#t") |> render_hook("pick", %{"id" => "t", "value" => "profile"})
    assert view |> element("#picked") |> render() =~ "profile"
  end

  test "the server changes the selection through selected", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TabsLive)
    assert html =~ ~s(data-selected="home")
    html = view |> element("#server-pick") |> render_click()
    assert html |> find("#t[data-selected=profile]") |> Enum.count() == 1
    assert html |> find("#t-tab-profile[aria-selected=true]") |> Enum.count() == 1
    assert html |> find("#t-panel-home[hidden]") |> Enum.count() == 1
  end
end
