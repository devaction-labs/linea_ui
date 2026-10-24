defmodule LineaUI.Components.HugeiconsTest do
  use LineaUI.ComponentCase, async: false

  setup do
    previous = Application.fetch_env(:linea_ui, :icons)
    Application.put_env(:linea_ui, :icons, :hugeicons)

    on_exit(fn ->
      case previous do
        {:ok, set} -> Application.put_env(:linea_ui, :icons, set)
        :error -> Application.delete_env(:linea_ui, :icons)
      end
    end)
  end

  defp huge(html) do
    html
    |> find("[class*='huge-']")
    |> LazyHTML.attribute("class")
    |> Enum.flat_map(&String.split/1)
    |> Enum.filter(&String.starts_with?(&1, "huge-"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp svgs(html), do: html |> find("svg") |> Enum.count()

  defp upload_config do
    socket = Phoenix.LiveView.allow_upload(%Phoenix.LiveView.Socket{}, :photos, accept: :any)
    socket.assigns.uploads.photos
  end

  test "accordion draws the Hugeicons chevron" do
    html =
      render(~H"""
      <.accordion id="a">
        <.accordion_item id="a1" title="One">x</.accordion_item>
      </.accordion>
      """)

    assert huge(html) == ["huge-arrow-down-01"]
    assert svgs(html) == 0
  end

  test "alert dismissible draws the cross" do
    html = render(~H|<.alert id="a" color="info" dismissible>x</.alert>|)
    assert huge(html) == ["huge-cancel-01"]
    assert "size-4" in classes(html, "[class*='huge-']")
    assert svgs(html) == 0
  end

  test "badge remove draws the cross with its size and dark colour" do
    html = render(~H|<.badge on_remove="gone">x</.badge>|)
    assert huge(html) == ["huge-cancel-01"]
    assert "dark:text-navy-50" in classes(html, "[class*='huge-']")
    assert svgs(html) == 0
  end

  test "breadcrumb separates with the Hugeicons chevron" do
    html =
      render(~H"""
      <.breadcrumb>
        <:item href="/">Home</:item>
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert huge(html) == ["huge-arrow-right-01"]
    assert svgs(html) == 0
  end

  test "carousel arrows are the Hugeicons arrow with no size of their own" do
    html =
      render(~H"""
      <.carousel id="c" navigation>
        <.carousel_slide>A</.carousel_slide>
      </.carousel>
      """)

    assert huge(html) == ["huge-arrow-right-01"]
    assert classes(html, "button[data-carousel-prev] [class*='huge-']") == ["huge-arrow-right-01"]
    assert svgs(html) == 0
  end

  test "collapse chevrons keep their rotation classes" do
    html =
      render(~H"""
      <.collapse id="a" chevron="down"><:trigger>A</:trigger>x</.collapse>
      <.collapse id="b" chevron="right"><:trigger>B</:trigger>x</.collapse>
      """)

    assert huge(html) == ["huge-arrow-down-01", "huge-arrow-right-01"]
    assert "group-open/collapse:rotate-180" in classes(html, ".huge-arrow-down-01")
    assert "group-open/collapse:rotate-90" in classes(html, ".huge-arrow-right-01")
    assert svgs(html) == 0
  end

  test "data table draws the search and the pager arrows" do
    html =
      render(~H"""
      <.data_table id="a" rows={[%{n: 1}]} on_page="page" on_search="search">
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      """)

    assert "huge-search-01" in huge(html)
    assert "huge-arrow-left-01" in huge(html)
    assert "huge-arrow-right-01" in huge(html)
    assert svgs(html) == 0
  end

  test "date and time pickers draw the calendar and the clock, and tell the hook the set" do
    html =
      render(~H"""
      <.date_picker id="d" name="d" />
      <.time_picker id="t" name="t" />
      """)

    assert huge(html) == ["huge-calendar-03", "huge-clock-01"]
    assert svgs(html) == 0
    assert html |> find("#d") |> LazyHTML.attribute("data-icons") == ["hugeicons"]
    assert html |> find("#t") |> LazyHTML.attribute("data-icons") == ["hugeicons"]
  end

  test "dropdown draws its chevron, its dots and its search" do
    html =
      render(~H"""
      <.dropdown id="a" label="Menu">
        <.dropdown_item href="#">One</.dropdown_item>
      </.dropdown>
      <.dropdown id="b" toggle_icon="dots">
        <.dropdown_item href="#">One</.dropdown_item>
      </.dropdown>
      <.dropdown id="c" toggle_icon="dots-vertical">
        <.dropdown_item href="#">One</.dropdown_item>
      </.dropdown>
      <.dropdown_search name="q" />
      """)

    assert huge(html) == [
             "huge-arrow-down-01",
             "huge-more-horizontal",
             "huge-more-vertical",
             "huge-search-01"
           ]

    assert svgs(html) == 0
  end

  test "modal and drawer draw the Hugeicons cross" do
    html =
      render(~H"""
      <.modal id="m" close_button>x</.modal>
      <.drawer id="d" close_button>x</.drawer>
      """)

    assert huge(html) == ["huge-cancel-01"]
    assert svgs(html) == 0
  end

  test "pagination draws the Hugeicons arrows" do
    html = render(~H|<.pagination page={2} total_pages={5} on_change="go" />|)
    assert huge(html) == ["huge-arrow-left-01", "huge-arrow-right-01"]
    assert svgs(html) == 0
  end

  test "table expands with the Hugeicons chevron" do
    html =
      render(~H"""
      <.table id="t" rows={[%{id: 1}]} expand_label="More">
        <:col :let={row} label="Id">{row.id}</:col>
        <:expand :let={detail}>Detail {detail.row.id}</:expand>
      </.table>
      """)

    assert huge(html) == ["huge-arrow-down-01"]
    assert [_] = find(html, "[data-expand-icon]") |> Enum.to_list()
    assert svgs(html) == 0
  end

  test "treeview draws the Hugeicons chevron" do
    html =
      render(~H"""
      <.treeview id="t">
        <.tree_item id="a" label="A"><.tree_item label="B" /></.tree_item>
      </.treeview>
      """)

    assert huge(html) == ["huge-arrow-right-01"]
    assert "tree-chevron" in classes(html, "[class*='huge-']")
    assert svgs(html) == 0
  end

  test "upload draws the Hugeicons cross on a file it holds" do
    entry = %Phoenix.LiveView.UploadEntry{
      ref: "0",
      client_name: "a.png",
      client_size: 1,
      progress: 100
    }

    assigns = %{__changed__: nil, upload: %{upload_config() | entries: [entry]}}
    html = rendered_to_string(~H|<.upload upload={@upload} />|)
    assert huge(html) == ["huge-cancel-01"]
    assert svgs(html) == 0
  end

  test "the shell draws its small glyphs in the set" do
    html =
      render(~H"""
      <.theme_toggle />
      <.sidebar_nav_group label="Group">
        <:item navigate="/a">A</:item>
      </.sidebar_nav_group>
      <.page_header title="T" />
      """)

    assert "huge-moon-02" in huge(html)
    assert "huge-sun-03" in huge(html)
    assert "huge-arrow-right-01" in huge(html)
    assert "darkmode-moon" in classes(html, ".huge-moon-02")
    assert "darkmode-sun" in classes(html, ".huge-sun-03")
  end

  test "the text editor toolbar draws Hugeicons tools" do
    html = render(~H|<.text_editor id="e" name="body" />|)

    assert "huge-text-bold" in huge(html)
    assert "huge-text-italic" in huge(html)
    assert "huge-unfold-more" in huge(html)
    assert "huge-paint-bucket" in huge(html)
    assert "huge-left-to-right-block-quote" in huge(html)
    assert "huge-right-to-left-block-quote" in huge(html)
    assert svgs(html) == 0
    assert find(html, "#e button.ql-bold[data-tool=bold] .huge-text-bold") |> Enum.count() == 1
  end

  test "the toaster tells its hook the set" do
    html = render(~H|<.toaster flash={%{}} />|)
    assert html |> find("#linea-toaster") |> LazyHTML.attribute("data-icons") == ["hugeicons"]
  end

  test "the toaster says LineOne's set by default" do
    Application.delete_env(:linea_ui, :icons)
    html = render(~H|<.toaster flash={%{}} />|)
    assert html |> find("#linea-toaster") |> LazyHTML.attribute("data-icons") == ["lineone"]
  end
end
