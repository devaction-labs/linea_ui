defmodule LineaUI.Components.StepGroupTest do
  use LineaUI.ComponentCase, async: true

  defp deploy(assigns) do
    ~H"""
    <.step_group id="deploy" title="Deploy logs" status={:failed} duration="1m 04s">
      <:step title="Prepare" status={:ok} result="12s" />
      <:step title="Transmit" status={:failed} result="Rejected" open>
        <.step_group_line n={1} at="09:41:02" tone="dim">Connecting</.step_group_line>
        <.step_group_line n={2} at="09:41:04" tone="err">Rejected</.step_group_line>
        <.step_group_line n={3} at="09:41:05">Try again</.step_group_line>
      </:step>
      <:step title="Authorize" status={:skipped} result="Skipped" />
    </.step_group>
    """
  end

  test "status classes on the header and on the rows" do
    html = render(~H"<.deploy />")

    assert "fail" in classes(html, ".sg-sgp-h .sg-sgs")
    assert "ok" in classes(html, ".sg-sgp-r:nth-of-type(1)")
    assert find(html, ".sg-sgp-r.ok") |> Enum.count() == 1
    assert find(html, ".sg-sgp-r.fail") |> Enum.count() == 1
    assert find(html, ".sg-sgp-r.skip") |> Enum.count() == 1
    assert find(html, ".sg-sgp-r.lead .sg-sgs[aria-hidden=true]") |> Enum.count() == 3
  end

  test "every status maps to its class" do
    html =
      render(~H"""
      <div>
        <.step_group
          :for={s <- [:ok, :running, :waiting, :failed, :skipped, :canceled]}
          id={"g-#{s}"}
          title="T"
          status={s}
        />
      </div>
      """)

    for c <- ~w(ok run wait fail skip cancel) do
      assert find(html, ".sg-sgp-h .sg-sgs.#{c}") |> Enum.count() == 1
    end
  end

  test "canceled rows have no icon and no lead" do
    html =
      render(~H"""
      <.step_group id="c" title="Build" status={:canceled}>
        <:step title="Prepare" status={:canceled} result="Canceled" />
      </.step_group>
      """)

    assert find(html, ".sg-sgp-r.cancel") |> Enum.count() == 1
    assert find(html, ".sg-sgp-r.lead") |> Enum.count() == 0
    assert find(html, ".sg-sgp-r .sg-sgs") |> Enum.count() == 0
  end

  test "the duration is shown only when given" do
    assert render(~H"<.deploy />") |> find(".sg-sgp-h .m") |> LazyHTML.text() == "1m 04s"

    html = render(~H|<.step_group id="g" title="T" status={:ok} />|)
    assert find(html, ".sg-sgp-h .m") |> Enum.count() == 0
    assert find(html, ".sg-sgp-h .t") |> LazyHTML.text() == "T"
  end

  test "expanded by default, collapsed on request" do
    html = render(~H"<.deploy />")
    refute "is-collapsed" in classes(html, "section")
    assert find(html, ".sg-sgp-h") |> LazyHTML.attribute("aria-expanded") == ["true"]
    assert find(html, ".sg-sgp-b") |> LazyHTML.attribute("hidden") == []

    html = render(~H|<.step_group id="g" title="T" status={:ok} collapsed />|)
    assert "is-collapsed" in classes(html, "section")
    assert find(html, ".sg-sgp-h") |> LazyHTML.attribute("aria-expanded") == ["false"]
    assert find(html, ".sg-sgp-b") |> LazyHTML.attribute("hidden") == [""]
  end

  test "a step with a log renders its lines" do
    html = render(~H"<.deploy />")

    assert find(html, ".sg-sgp-log") |> Enum.count() == 1
    assert find(html, ".sg-sgp-log > div") |> Enum.count() == 3
    assert find(html, ".sg-sgp-log .n") |> Enum.map(&LazyHTML.text/1) == ["1", "2", "3"]

    assert find(html, ".sg-sgp-log .ts") |> Enum.map(&LazyHTML.text/1) ==
             ["09:41:02", "09:41:04", "09:41:05"]

    assert find(html, ".sg-sgp-log .dim") |> LazyHTML.text() == "Connecting"
    assert find(html, ".sg-sgp-log .err") |> LazyHTML.text() == "Rejected"

    assert find(html, ".sg-sgp-log span:not(.n):not(.ts):not(.dim):not(.err)") |> LazyHTML.text() ==
             "Try again"
  end

  test "an open step has open and aria-expanded true, the log is visible" do
    html = render(~H"<.deploy />")

    assert "open" in classes(html, "button.sg-sgp-r")
    assert find(html, "button.sg-sgp-r") |> LazyHTML.attribute("aria-expanded") == ["true"]
    assert find(html, ".sg-sgp-log") |> LazyHTML.attribute("hidden") == []

    assert find(html, "button.sg-sgp-r") |> LazyHTML.attribute("aria-controls") == [
             "deploy-step-2-log"
           ]

    assert find(html, ".sg-sgp-log") |> LazyHTML.attribute("id") == ["deploy-step-2-log"]
  end

  test "a closed step with a log keeps it hidden" do
    html =
      render(~H"""
      <.step_group id="g" title="T" status={:ok}>
        <:step title="A" status={:ok} result="1s">
          <.step_group_line n={1}>x</.step_group_line>
        </:step>
      </.step_group>
      """)

    refute "open" in classes(html, "button.sg-sgp-r")
    assert find(html, "button.sg-sgp-r") |> LazyHTML.attribute("aria-expanded") == ["false"]
    assert find(html, ".sg-sgp-log") |> LazyHTML.attribute("hidden") == [""]
  end

  test "rows without a log are plain, with no log and no chevron" do
    html = render(~H"<.deploy />")

    assert find(html, "button.sg-sgp-r") |> Enum.count() == 1
    assert find(html, "div.sg-sgp-r") |> Enum.count() == 2
    assert find(html, "div.sg-sgp-r[aria-expanded]") |> Enum.count() == 0
    assert find(html, "div.sg-sgp-r .c svg") |> Enum.count() == 0
  end

  test "the toggles are client-side JS and keep the browser's state" do
    html = render(~H"<.deploy />")

    [group_click] = find(html, ".sg-sgp-h") |> LazyHTML.attribute("phx-click")
    assert group_click =~ "toggle_class"
    assert group_click =~ "is-collapsed"
    assert group_click =~ "aria-expanded"
    assert group_click =~ "#deploy-body"

    [row_click] = find(html, "button.sg-sgp-r") |> LazyHTML.attribute("phx-click")
    assert row_click =~ "open"
    assert row_click =~ "#deploy-step-2-log"

    assert find(html, "section") |> LazyHTML.attribute("phx-mounted") |> hd() =~ "ignore_attrs"

    assert find(html, "button.sg-sgp-r") |> LazyHTML.attribute("phx-mounted") |> hd() =~
             "ignore_attrs"
  end
end
