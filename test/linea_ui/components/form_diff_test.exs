defmodule LineaUI.FormDiffLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  @fields ~w(name bio kind pw code)a

  def mount(_params, _session, socket), do: {:ok, assign(socket, as: :x, form: form(:x, %{}))}

  def handle_event("validate", %{"x" => params}, socket),
    do: {:noreply, assign(socket, form: form(socket.assigns.as, params))}

  def handle_event("rename", %{"as" => as}, socket) do
    as = String.to_atom(as)
    {:noreply, assign(socket, as: as, form: form(as, %{}))}
  end

  defp form(as, params) do
    params =
      Map.merge(%{"name" => "", "bio" => "", "kind" => "a", "pw" => "", "code" => ""}, params)

    errors =
      case params["name"] do
        "bad" -> Enum.map(@fields, &{&1, {"is invalid", []}})
        _ok -> []
      end

    to_form(params, as: as, errors: errors)
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="f" phx-change="validate">
      <.input field={@form[:name]} label="Name" />
      <.textarea field={@form[:bio]} label="Bio" />
      <.select native field={@form[:kind]} options={~w(a b)} label="Kind" />
      <.password_input field={@form[:pw]} id="pw" label="Password" />
      <.otp_input field={@form[:code]} length={4} />
    </.form>
    """
  end
end

defmodule LineaUI.Components.FormDiffTest do
  use LineaUI.LiveCase, async: true

  alias Phoenix.LiveView.Diff

  @controls ~w(input#x_name textarea#x_bio select#x_kind input#pw input#x_code-1)

  defp invalid?(html, selector),
    do: html |> find(selector) |> LazyHTML.attribute("aria-invalid") == ["true"]

  test "an error appearing and going away reaches the DOM of every control", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, LineaUI.FormDiffLive)
    refute Enum.any?(@controls, &invalid?(html, &1))
    before = Map.new(@controls, &{&1, classes(html, &1)})

    html = view |> form("#f", x: %{name: "bad"}) |> render_change()
    assert Enum.all?(@controls, &invalid?(html, &1))
    assert html =~ "is invalid"

    # The paint comes from `aria-invalid`: the classes are the same with and without the error.
    assert Map.new(@controls, &{&1, classes(html, &1)}) == before

    html = view |> form("#f", x: %{name: "good"}) |> render_change()
    assert Enum.filter(@controls, &invalid?(html, &1)) == []
    refute html =~ "is invalid"
  end

  test "a changed name and id (a reindexed inputs_for) reaches the DOM", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, LineaUI.FormDiffLive)
    assert [_] = find(html, "input#x_name[name='x[name]']") |> Enum.to_list()
    assert [_] = find(html, "textarea#x_bio[name='x[bio]']") |> Enum.to_list()
    assert [_] = find(html, "select#x_kind[name='x[kind]']") |> Enum.to_list()
    assert [_] = find(html, "#x_code-value[name='x[code]']") |> Enum.to_list()

    html = render_hook(view, "rename", %{"as" => "y"})
    assert [_] = find(html, "input#y_name[name='y[name]']") |> Enum.to_list()
    assert [_] = find(html, "textarea#y_bio[name='y[bio]']") |> Enum.to_list()
    assert [_] = find(html, "select#y_kind[name='y[kind]']") |> Enum.to_list()
    assert [_] = find(html, "#y_code-value[name='y[code]']") |> Enum.to_list()
    assert find(html, "#x_name") |> Enum.to_list() == []
  end

  # What one keystroke sends for a control with a `field`, as `Phoenix.LiveView.Diff` renders it.
  defmodule Keys do
    use Phoenix.Component
    use LineaUI

    def k_input(assigns),
      do: ~H|<.form for={@form}><.input field={@form[:a]} label="A" /></.form>|

    def k_textarea(assigns),
      do: ~H|<.form for={@form}><.textarea field={@form[:a]} label="A" /></.form>|

    def k_password(assigns),
      do: ~H|<.form for={@form}><.password_input field={@form[:a]} label="A" /></.form>|

    def k_native(assigns),
      do: ~H|<.form for={@form}><.select native field={@form[:a]} options={~w(a b)} /></.form>|

    def k_otp(assigns), do: ~H|<.form for={@form}><.otp_input field={@form[:a]} /></.form>|

    def k_date(assigns),
      do: ~H|<.form for={@form}><.date_picker field={@form[:a]} today={~D[2026-01-01]} /></.form>|
  end

  defp keystroke_bytes(fun) do
    form = fn value -> Phoenix.Component.to_form(%{"a" => value}, as: :x) end
    socket = %Phoenix.LiveView.Socket{}
    first = fun.(%{form: form.(""), __changed__: nil})

    {_diff, prints, comps} =
      Diff.render(socket, first, Diff.new_fingerprints(), Diff.new_components())

    {_diff, prints, comps} =
      render_step(fun, form.("1"), prints, comps, socket)

    {diff, _prints, _comps} = render_step(fun, form.("12"), prints, comps, socket)
    diff |> Jason.encode!()
  end

  defp render_step(fun, form, prints, comps, socket) do
    rendered = fun.(%{form: form, __changed__: %{form: true}})
    Diff.render(socket, rendered, prints, comps)
  end

  for {name, limit} <- [
        input: 250,
        textarea: 250,
        password: 250,
        native: 250,
        otp: 600,
        date: 600
      ] do
    test "a keystroke in a #{name} with a field resends little, and no classes" do
      diff = keystroke_bytes(&apply(Keys, :"k_#{unquote(name)}", [&1]))
      assert byte_size(diff) < unquote(limit)
      refute diff =~ "form-"
      refute diff =~ "shadow-"
    end
  end
end
