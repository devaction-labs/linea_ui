defmodule LineaUI.Components.UploadTest do
  use LineaUI.ComponentCase, async: true

  defp config(opts \\ []) do
    socket = %Phoenix.LiveView.Socket{}
    socket = Phoenix.LiveView.allow_upload(socket, :photos, Keyword.merge([accept: :any], opts))
    socket.assigns.uploads.photos
  end

  test "the drop panel renders live_file_input and the drop target" do
    assigns = %{__changed__: nil, upload: config()}
    html = rendered_to_string(~H|<.upload upload={@upload} bordered filled columns={3} />|)
    ref = assigns.upload.ref

    assert find(html, "[phx-hook='LineaUI.Upload'][phx-drop-target='#{ref}']") |> Enum.count() ==
             1

    classes = classes(html, ".filepond--root")
    assert "fp-bordered" in classes
    assert "fp-bg-filled" in classes
    assert "fp-grid" in classes
    assert "[--fp-grid:3]" in classes
    assert find(html, "input[type=file][id='#{ref}']") |> Enum.count() == 1

    assert html |> find(".filepond--drop-label label") |> LazyHTML.text() =~
             "Drag & Drop your files or"

    assert html |> find(".filepond--label-action") |> LazyHTML.text() == "Browse"
  end

  test "the circle layout with an icon label" do
    assigns = %{__changed__: nil, upload: config(max_entries: 1)}

    html =
      rendered_to_string(~H"""
      <.upload upload={@upload} layout="circle" class="w-28">
        <:label><svg id="icon" /></:label>
      </.upload>
      """)

    assert find(html, ".filepond--root.label-icon.w-28[data-layout=circle] #icon") |> Enum.count() ==
             1
  end

  test "upload_button with a LiveView upload or a plain input" do
    assigns = %{__changed__: nil, upload: config()}
    html = rendered_to_string(~H|<.upload_button upload={@upload}>Choose File</.upload_button>|)
    assert "bg-slate-150" in classes(html, "label")
    assert find(html, "label input[type=file][id='#{assigns.upload.ref}']") |> Enum.count() == 1

    html =
      render(
        ~H|<.upload_button name="doc" color="info" variant="glow" icon shape="pill" multiple>i</.upload_button>|
      )

    classes = classes(html, "label")
    assert "bg-info" in classes
    assert "hover:shadow-info/50" in classes
    assert "size-9" in classes
    assert "rounded-full" in classes
    assert find(html, "input[type=file][name=doc][multiple]") |> Enum.count() == 1
  end

  defp too_many(max) do
    upload = config(max_entries: max)
    %{upload | errors: [{upload.ref, :too_many_files}]}
  end

  test "too_many_files keeps its default text" do
    assigns = %{__changed__: nil, upload: too_many(2)}
    html = rendered_to_string(~H|<.upload upload={@upload} />|)

    assert html |> find(".filepond--errors li") |> LazyHTML.text() |> String.trim() ==
             "Too many files"
  end

  test "an error text can interpolate the limit" do
    assigns = %{
      __changed__: nil,
      upload: too_many(3),
      texts: %{too_many_files: "Only %{max} files"}
    }

    html = rendered_to_string(~H|<.upload upload={@upload} error_texts={@texts} />|)

    assert html |> find(".filepond--errors li") |> LazyHTML.text() |> String.trim() ==
             "Only 3 files"
  end

  defp with_entries(entries, errors \\ []) do
    upload = config(max_entries: 4)

    entries =
      for {ref, name, size, progress, done?} <- entries do
        struct!(Phoenix.LiveView.UploadEntry,
          ref: ref,
          upload_ref: upload.ref,
          client_name: name,
          client_size: size,
          client_type: "application/pdf",
          progress: progress,
          done?: done?,
          valid?: true,
          upload_config: upload.name
        )
      end

    %{upload | entries: entries, errors: errors}
  end

  test "the panel does not cover the errors of the whole upload" do
    upload = with_entries([{"a", "a.pdf", 1000, 10, false}])
    upload = %{upload | errors: [{upload.ref, :too_many_files}]}
    assigns = %{__changed__: nil, upload: upload}
    html = rendered_to_string(~H|<.upload upload={@upload} />|)

    assert find(html, ".filepond--pond > .filepond--panel-root") |> Enum.count() == 1
    assert find(html, ".filepond--pond > .filepond--drop-label") |> Enum.count() == 1
    assert find(html, ".filepond--pond > .filepond--list .filepond--item") |> Enum.count() == 1
    assert find(html, ".filepond--root > .filepond--errors li") |> Enum.count() == 1
    assert find(html, ".filepond--pond .filepond--errors") |> Enum.count() == 0
    assert find(html, ".filepond--root > input[type=file]") |> Enum.count() == 1
  end

  test "an entry shows its state, progress and the error of its own" do
    upload =
      with_entries(
        [
          {"a", "a.pdf", 1_800_000, 62, false},
          {"b", "b.pdf", 420_000, 100, true},
          {"c", "c.xlsx", 14_200_000, 0, false}
        ],
        [{"c", :too_large}]
      )

    assigns = %{__changed__: nil, upload: upload}
    html = rendered_to_string(~H|<.upload upload={@upload} />|)

    assert find(html, ".filepond--item[data-state=processing]") |> Enum.count() == 1
    assert find(html, ".filepond--item[data-state=complete]") |> Enum.count() == 1
    assert find(html, ".filepond--item[data-state=error]") |> Enum.count() == 1
    assert find(html, "[role=progressbar][aria-valuenow='62']") |> Enum.count() == 1

    assert html
           |> find(".filepond--item[data-state=error] .filepond--file-status-main")
           |> LazyHTML.text() =~ "File is too large"
  end

  test "sizes drop a zero decimal" do
    upload =
      with_entries([
        {"a", "a", 210_000, 100, true},
        {"b", "b", 1_800_000, 100, true},
        {"c", "c", 500, 100, true}
      ])

    assigns = %{__changed__: nil, upload: upload}
    html = rendered_to_string(~H|<.upload upload={@upload} />|)

    sizes = html |> find(".filepond--file-info-sub") |> LazyHTML.text()
    assert sizes =~ "210 KB"
    assert sizes =~ "1.8 MB"
    assert sizes =~ "500 bytes"
    refute sizes =~ ".0"
  end

  test "data-dragging passes through to the drop panel" do
    assigns = %{__changed__: nil, upload: config()}
    html = rendered_to_string(~H|<.upload upload={@upload} bordered data-dragging />|)
    assert find(html, ".filepond--root[data-dragging]") |> Enum.count() == 1
  end

  test "upload_button is enabled by default and shows a focus outline" do
    html = render(~H|<.upload_button name="doc">Choose</.upload_button>|)
    assert find(html, "input[disabled]") |> Enum.count() == 0
    refute html =~ "opacity-55"
    assert html =~ "has-[input:focus-visible]:outline-primary/50"
    # .btn sets the outline style to none; the ring needs its own solid style to show
    assert html =~ "has-[input:focus-visible]:outline-solid"
  end

  test "a disabled upload_button disables its input and dims" do
    html = render(~H|<.upload_button name="doc" disabled>Choose</.upload_button>|)
    assert find(html, "input[disabled]") |> Enum.count() == 1
    assert html =~ "opacity-55"
    assert html =~ "pointer-events-none"

    assigns = %{__changed__: nil, upload: config()}

    html =
      rendered_to_string(~H|<.upload_button upload={@upload} disabled>Choose</.upload_button>|)

    assert find(html, "input[type=file][disabled]") |> Enum.count() == 1
  end
end
