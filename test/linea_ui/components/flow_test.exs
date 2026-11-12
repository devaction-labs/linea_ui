defmodule LineaUI.Components.FlowTest do
  use LineaUI.ComponentCase, async: true

  @edges [
    %{from: "in", to: "match"},
    %{from: "match", to: "post", label: "diff <= 2%", status: "done"},
    %{from: "match", to: "gate", label: "diff > 2%"}
  ]

  defp edges, do: @edges

  defp weird_edges do
    [
      %{from: "a", to: "zz"},
      %{from: "a", to: "a"},
      %{from: "a", to: "b"},
      %{from: "b", to: "a"}
    ]
  end

  defp one(html, selector), do: assert(Enum.count(find(html, selector)) == 1)

  defp triage(assigns) do
    ~H"""
    <.flow id="triage" edges={edges()} on_add="add" aria-label="Triage">
      <:node
        id="in"
        kind="Trigger"
        kind_icon="huge-flash"
        icon="huge-mail-01"
        title="Invoice received"
        metrics={[%{label: "runs", value: "1,284/wk", href: "/runs"}, %{label: "p95", value: "0.3 s"}]}
      >
        <.flow_section label="Event">An invoice arrives.</.flow_section>
      </:node>
      <:node id="match" kind="Agent" kind_icon="huge-sparkles" title="Match">
        <.flow_section label="Tools">
          <.flow_chips>
            <.flow_chip>erp.lookup</.flow_chip>
          </.flow_chips>
        </.flow_section>
      </:node>
      <:node id="post" kind="Action" title="Post" status="skipped" />
      <:node id="gate" kind="Human" title="Approval" selected status="waiting" />
      <:actions :let={id}><button type="button" data-for={id}>Delete</button></:actions>
      <:toolbar><button type="button">Add node</button></:toolbar>
      <:panel label="Approval">
        <.flow_panel_head icon="huge-security-check" title="Approval" on_close="close" />
        <.flow_panel_tabs>tabs</.flow_panel_tabs>
        <.flow_panel_body>fields</.flow_panel_body>
        <.flow_panel_foot>foot</.flow_panel_foot>
      </:panel>
    </.flow>
    """
  end

  test "renders the board with its role and aria-label" do
    html = render(~H"<.triage />")
    one(html, "#triage.linea-flow[role=group][aria-label=Triage]")
    assert find(html, ".linea-flow-node") |> Enum.count() == 4
  end

  test "a node has its kind tab, titled card, sections and metrics footer" do
    html = render(~H"<.triage />")
    assert find(html, "#in .linea-flow-kind") |> LazyHTML.text() =~ "Trigger"
    assert find(html, "#in .linea-flow-head h3") |> LazyHTML.text() == "Invoice received"
    assert find(html, "#in .linea-flow-sec .l") |> LazyHTML.text() == "Event"
    assert find(html, "#match .linea-flow-chip") |> LazyHTML.text() == "erp.lookup"
    assert find(html, "#in .linea-flow-metrics a") |> Enum.count() == 1
    assert find(html, "#in .linea-flow-metrics span b") |> LazyHTML.text() == "0.3 s"
    assert find(html, "#match .linea-flow-metrics") |> Enum.count() == 0
  end

  test "every status marks the node and puts a dot on the tab" do
    html =
      render(~H"""
      <.flow id="s">
        <:node
          :for={s <- ~w(running done waiting error skipped)}
          id={"n-" <> s}
          kind="K"
          title={s}
          status={s}
        />
        <:node id="n-plain" kind="K" title="plain" />
      </.flow>
      """)

    for s <- ~w(running done waiting error skipped) do
      one(html, "#n-#{s}[data-status=#{s}] .linea-flow-kind .st")
    end

    assert find(html, "#n-plain .st") |> Enum.count() == 0
    assert find(html, "#n-plain[data-status]") |> Enum.count() == 0
  end

  test "selected adds data-selected and renders the actions beside that node only" do
    html = render(~H"<.triage />")
    one(html, "#gate[data-selected]")
    assert find(html, "[data-selected]") |> Enum.count() == 1
    one(html, "#gate .linea-flow-actions button[data-for=gate]")
    assert find(html, ".linea-flow-actions") |> Enum.count() == 1
  end

  test "edges are paths in a band above their target, with labels and dots" do
    html = render(~H"<.triage />")
    assert find(html, ".linea-flow-band") |> Enum.count() == 2
    assert find(html, ".linea-flow-edges path") |> Enum.count() == 3
    assert find(html, ".linea-flow-edges rect") |> Enum.count() == 6
    assert find(html, ".linea-flow-edge[data-to=post]") |> LazyHTML.text() == "diff <= 2%"
    assert find(html, ".linea-flow-edge[data-to=match]") |> LazyHTML.text() == ""
  end

  test "a done edge is marked and an edge into the selected node is active" do
    html = render(~H"<.triage />")
    one(html, ".linea-flow-edges path[data-status=done]")
    one(html, ".linea-flow-edge[data-to=post][data-status=done]")
    one(html, ".linea-flow-edges path[data-active]")
    one(html, ".linea-flow-edge[data-to=gate][data-active]")
    assert find(html, ".linea-flow-edge[data-to=post][data-active]") |> Enum.count() == 0
  end

  test "an edge without a status is the plain line (the branch not taken)" do
    html = render(~H"<.triage />")
    assert find(html, ".linea-flow-edge[data-to=gate][data-status]") |> Enum.count() == 0
  end

  test "children stand side by side and a parent is centred over them" do
    html = render(~H"<.triage />")
    [post] = find(html, "#post") |> LazyHTML.attribute("style")
    [gate] = find(html, "#gate") |> LazyHTML.attribute("style")
    [match] = find(html, "#match") |> LazyHTML.attribute("style")
    assert post =~ "margin-left:0"
    assert gate =~ "margin-left:76"
    assert match =~ "margin-left:188"

    assert find(html, ".linea-flow-edge[data-to=post]") |> LazyHTML.attribute("style") == [
             "left:150.0px;top:77.0px"
           ]
  end

  test "a plain edge has a short band and a branch a tall one" do
    html = render(~H"<.triage />")
    heights = find(html, ".linea-flow-band") |> LazyHTML.attribute("style")
    assert heights == ["height:14px", "height:97px"]
  end

  test "on_add draws the + under the leaves only" do
    html = render(~H"<.triage />")
    assert find(html, ".linea-flow-add") |> Enum.count() == 2

    one(
      html,
      "#post .linea-flow-add[phx-click=add][phx-value-id=post][aria-label='Add step after']"
    )

    assert find(html, "#match .linea-flow-add") |> Enum.count() == 0

    none =
      render(~H"""
      <.flow id="x"><:node id="a" title="A" /></.flow>
      """)

    assert find(none, ".linea-flow-add") |> Enum.count() == 0
  end

  test "a flow without edges is a free grid, four to a row, with the + on every node" do
    html =
      render(~H"""
      <.flow id="free" on_add="add">
        <:node :for={n <- 1..5} id={"n#{n}"} title={"N#{n}"} />
      </.flow>
      """)

    one(html, ".linea-flow-stage[data-free]")
    assert find(html, ".linea-flow-row") |> Enum.count() == 2
    assert find(html, ".linea-flow-band") |> Enum.count() == 0
    assert find(html, ".linea-flow-add") |> Enum.count() == 5
  end

  test "a node without kind has no tab" do
    html =
      render(~H"""
      <.flow id="k"><:node id="a" title="A" /></.flow>
      """)

    assert find(html, ".linea-flow-kind") |> Enum.count() == 0
  end

  test "the toolbar and the panel slots" do
    html = render(~H"<.triage />")
    one(html, ".linea-flow-main > .linea-flow-toolbar[role=toolbar] button")
    one(html, ".linea-flow > aside.linea-flow-panel[aria-label=Approval]")
    assert find(html, ".linea-flow-panel-head h2") |> LazyHTML.text() == "Approval"
    one(html, ".linea-flow-panel-head button[phx-click=close]")
    assert find(html, ".linea-flow-panel-tabs") |> LazyHTML.text() == "tabs"
    assert find(html, ".linea-flow-panel-body") |> LazyHTML.text() == "fields"
    assert find(html, ".linea-flow-panel-foot") |> LazyHTML.text() |> String.trim() == "foot"
  end

  test "without toolbar and panel neither is rendered" do
    html =
      render(~H"""
      <.flow id="k"><:node id="a" title="A" /></.flow>
      """)

    assert find(html, ".linea-flow-toolbar, .linea-flow-panel") |> Enum.count() == 0
  end

  test "the panel head has no close button without on_close" do
    html =
      render(~H"""
      <.flow_panel_head title="T" />
      """)

    assert find(html, "button") |> Enum.count() == 0
  end

  test "edges that name unknown nodes or themselves are ignored, and cycles do not hang" do
    html =
      render(~H"""
      <.flow id="c" edges={weird_edges()}>
        <:node id="a" title="A" />
        <:node id="b" title="B" />
      </.flow>
      """)

    assert find(html, ".linea-flow-node") |> Enum.count() == 2
  end

  test "node_width sets the card width" do
    html =
      render(~H"""
      <.flow id="k" node_width={288}><:node id="a" title="A" /></.flow>
      """)

    assert find(html, "#a") |> LazyHTML.attribute("style") == ["width:288px"]
  end
end
