defmodule LineaUI.Components.FlowTest do
  use LineaUI.ComponentCase, async: true

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the stage, the hook and one element per edge" do
    assigns = %{
      edges: [
        %{from: "a", to: "b"},
        %{from: "b", to: "c", label: "variance > 2%", active: true},
        %{from: "b", to: "d", label: "ok", status: "done"}
      ]
    }

    html =
      render(~H"""
      <.flow id="triage" edges={@edges} aria-label="Triage">
        <.flow_node id="a" title="Invoice received" />
        <:toolbar><button id="add">Add node</button></:toolbar>
        <:panel><.flow_panel title="Approval gate" /></:panel>
      </.flow>
      """)

    assert ["linea-flow"] == classes(html, "#triage")
    assert attr_of(html, "#triage", "phx-hook") == ["LineaUI.Flow"]
    assert attr_of(html, "#triage", "aria-label") == ["Triage"]
    assert attr_of(html, "svg#triage-edges", "phx-update") == ["ignore"]
    assert attr_of(html, ".linea-flow-edge", "data-from") == ["a", "b", "b"]
    assert attr_of(html, ".linea-flow-edge", "data-to") == ["b", "c", "d"]
    assert text(html, ".linea-flow-edge") == ["", "variance > 2%", "ok"]
    assert [_] = find(html, ".linea-flow-edge[data-active]") |> Enum.to_list()
    assert attr_of(html, ".linea-flow-edge[data-status]", "data-status") == ["done"]
    assert [_] = find(html, ".linea-flow-stage #a") |> Enum.to_list()
    assert [_] = find(html, ".linea-flow-toolbar #add") |> Enum.to_list()
    assert [_] = find(html, "#triage > .linea-flow-panel") |> Enum.to_list()
  end

  test "a node: the kind tab, the header, sections, chips and metrics" do
    html =
      render(~H"""
      <.flow_node id="match" x={320} y={480} width={360} kind="Agent" title="Match & reconcile">
        <:kind_icon><i id="ki"></i></:kind_icon>
        <:icon><i id="ti"></i></:icon>
        <:section label="Instructions">Run a 3-way match.</:section>
        <:section label="Tools"><.flow_chip>erp.lookup_po</.flow_chip></:section>
        <:metric label="cost" value="$0.04/run" navigate="/costs" />
        <:metric label="p95" value="6.2s" />
      </.flow_node>
      """)

    assert attr_of(html, "article#match", "style") == ["left:320px;top:480px;width:360px"]
    assert text(html, ".linea-flow-kind") == ["Agent"]
    assert [_] = find(html, ".linea-flow-kind #ki") |> Enum.to_list()
    assert [_] = find(html, ".linea-flow-head #ti") |> Enum.to_list()
    assert text(html, ".linea-flow-head h3") == ["Match & reconcile"]
    assert text(html, ".linea-flow-sec .l") == ["Instructions", "Tools"]
    assert text(html, "code.linea-flow-chip") == ["erp.lookup_po"]
    assert text(html, ".linea-flow-metrics b") == ["$0.04/run", "6.2s"]
    assert attr_of(html, ".linea-flow-metrics a", "href") == ["/costs"]
    assert find(html, ".linea-flow-metrics > span") |> Enum.count() == 1
    assert attr_of(html, ".linea-flow-card", "aria-label") == ["Match & reconcile"]
    assert find(html, ".linea-flow-add") |> Enum.to_list() == []
    assert find(html, ".linea-flow-kind .st") |> Enum.to_list() == []
  end

  test "selected shows the actions; status and the add button" do
    html =
      render(~H"""
      <.flow_node id="gate" title="Approval gate" kind="Human step" selected status="waiting" on_add="add_after">
        <:actions><button id="del">Delete</button></:actions>
      </.flow_node>
      """)

    assert attr_of(html, "#gate", "data-selected") == [""]
    assert attr_of(html, "#gate", "data-status") == ["waiting"]
    assert attr_of(html, "#gate", "aria-current") == ["true"]
    assert [_] = find(html, ".linea-flow-kind .st") |> Enum.to_list()
    assert [_] = find(html, ".linea-flow-actions #del") |> Enum.to_list()
    assert attr_of(html, ".linea-flow-add", "phx-click") == ["add_after"]
    assert attr_of(html, ".linea-flow-add", "phx-value-id") == ["gate"]

    html = render(~H|<.flow_node id="n" title="N"><:actions><button id="del">x</button></:actions></.flow_node>|)
    assert find(html, ".linea-flow-actions") |> Enum.to_list() == []
    assert find(html, ".linea-flow-kind") |> Enum.to_list() == []
  end

  test "flow_panel: header, tabs, body and footer" do
    html =
      render(~H"""
      <.flow_panel title="Approval gate" on_close="close">
        <:icon><i id="pi"></i></:icon>
        <:tabs><nav id="tabs"></nav></:tabs>
        <p id="body">Fields</p>
        <:footer><button id="save">Save node</button></:footer>
      </.flow_panel>
      """)

    assert text(html, ".linea-flow-panel-head h2") == ["Approval gate"]
    assert [_] = find(html, ".linea-flow-panel-head .ic #pi") |> Enum.to_list()
    assert attr_of(html, ".linea-flow-panel-head button", "phx-click") == ["close"]
    assert attr_of(html, ".linea-flow-panel-head button", "aria-label") == ["Close"]
    assert [_] = find(html, ".linea-flow-panel-tabs #tabs") |> Enum.to_list()
    assert [_] = find(html, ".linea-flow-panel-body #body") |> Enum.to_list()
    assert [_] = find(html, ".linea-flow-panel-foot #save") |> Enum.to_list()
  end

  test "height sets the bound the stage scrolls inside" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.flow id="f" height="640px">
        <.flow_node id="a" x={0} y={0} title="A" />
      </.flow>
      """)

    assert html =~ ~s(style="--linea-flow-height:640px")
  end
end
