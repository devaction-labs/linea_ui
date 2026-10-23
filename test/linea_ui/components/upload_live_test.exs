defmodule LineaUI.Components.UploadLiveTest do
  use LineaUI.LiveCase, async: false

  alias LineaUI.Test.PickersLive

  setup_all do
    start_supervised!({Phoenix.PubSub, name: LineaUI.Test.UploadPubSub})
    Phoenix.Config.put(LineaUI.TestEndpoint, :pubsub_server, LineaUI.Test.UploadPubSub)
    :ok
  end

  test "uploads show their entries, progress and cancel", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, PickersLive)

    photo =
      file_input(view, "#trip", :photos, [
        %{name: "a.txt", content: "helloworld", type: "text/plain"}
      ])

    assert render_upload(photo, "a.txt", 50) =~ "a.txt"
    html = render(view)
    assert html |> find(".filepond--item[data-state=processing]") |> Enum.count() == 1
    assert html |> find(".filepond--file-status-sub") |> LazyHTML.text() =~ "50%"

    render_upload(photo, "a.txt", 50)
    html = render(view)
    assert html |> find(".filepond--item[data-state=complete]") |> Enum.count() == 1

    ref =
      html |> find(".filepond--file-action-button") |> LazyHTML.attribute("phx-value-ref") |> hd()

    view |> element(~s(.filepond--file-action-button[phx-value-ref="#{ref}"])) |> render_click()
    html = render(view)
    assert html |> find(".filepond--item") |> Enum.count() == 0
  end

  test "an upload error is shown on the entry", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, PickersLive)

    photo =
      file_input(view, "#trip", :photos, [%{name: "a.pdf", content: "x", type: "application/pdf"}])

    assert {:error, _} = render_upload(photo, "a.pdf")
    html = render(view)
    assert html |> find(".filepond--item[data-state=error]") |> Enum.count() == 1
    assert html =~ "File of invalid type"
  end
end
