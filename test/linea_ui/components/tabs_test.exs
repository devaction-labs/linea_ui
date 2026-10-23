defmodule LineaUI.Components.TabsTest do
  use LineaUI.ComponentCase, async: true

  defp tabs_fixture(assigns) do
    ~H"""
    <.tabs id="t" {@opts}>
      <:tab name="home">Home</:tab>
      <:tab name="profile">Profile</:tab>
      <:tab name="off" disabled>Off</:tab>
      <:panel name="home">Home panel</:panel>
      <:panel name="profile">Profile panel</:panel>
    </.tabs>
    """
  end

  defp render_tabs(opts) do
    rendered_to_string(tabs_fixture(%{opts: opts, __changed__: nil}))
  end

  defp count(html, selector), do: html |> find(selector) |> Enum.count()

  test "wires the hook, the roles and the ids" do
    html = render_tabs(%{})
    assert count(html, "#t[phx-hook='LineaUI.Tabs'][data-selected=home]") == 1
    assert count(html, "[role=tablist][aria-orientation=horizontal]") == 1
    assert count(html, "button[role=tab]") == 3

    assert count(
             html,
             "#t-tab-home[aria-controls=t-panel-home][aria-selected=true][tabindex='0']"
           ) == 1

    assert count(html, "#t-tab-profile[aria-selected=false][tabindex='-1']") == 1
    assert count(html, "#t-tab-off[disabled]") == 1

    assert count(html, "#t-panel-profile[role=tabpanel][aria-labelledby=t-tab-profile][hidden]") ==
             1

    assert count(html, "#t-panel-home[hidden]") == 0
    assert html =~ "ignore_attrs"
  end

  test "selected picks the tab and panel" do
    html = render_tabs(%{selected: "profile"})
    assert count(html, "#t-tab-profile[aria-selected=true]") == 1
    assert count(html, "#t-panel-home[hidden]") == 1
  end

  test "variants change the tab look" do
    assert "border-b-2" in classes(render_tabs(%{}), "#t-tab-home")
    assert "aria-selected:bg-white" in classes(render_tabs(%{variant: "boxed"}), "#t-tab-home")
    assert "bg-slate-200" in classes(render_tabs(%{variant: "boxed"}), "#t > div")
    pill = classes(render_tabs(%{variant: "pill"}), "#t-tab-home")
    assert "rounded-full" in pill
    assert "aria-selected:bg-primary/10" in pill

    assert "aria-selected:bg-slate-150" in classes(
             render_tabs(%{variant: "pill", color: "neutral"}),
             "#t-tab-home"
           )

    assert "flex-1" in classes(render_tabs(%{grow: true}), "#t-tab-home")
  end

  test "bordered draws the rule, overlap pulls the list over it" do
    html = render_tabs(%{bordered: true, overlap: true})
    assert "border-slate-150" in classes(html, "#t > div > div")
    assert "-mb-0.5" in classes(html, "[role=tablist]")
  end

  test "vertical lays the list beside the panels" do
    html = render_tabs(%{orientation: "vertical"})
    assert count(html, "#t[data-orientation=vertical]") == 1
    assert "flex-col" in classes(html, "[role=tablist]")
    assert "border-r-2" in classes(html, "#t-tab-home")
    assert "pl-4" in classes(html, "#t > div:last-child")
  end

  test "transitions" do
    assert "tab-shift-up" in classes(render_tabs(%{transition: "up"}), "#t-panel-home")
    refute "tab-content" in classes(render_tabs(%{transition: "none"}), "#t-panel-home")
  end

  test "on_change as an event name or JS, with a target" do
    html = render_tabs(%{on_change: "pick", target: "#c"})
    assert count(html, "#t[data-event=pick][phx-target='#c']") == 1

    html = render_tabs(%{on_change: Phoenix.LiveView.JS.push("pick")})
    assert [js] = html |> find("#t") |> LazyHTML.attribute("data-on-change")
    assert js =~ "pick"
  end
end
