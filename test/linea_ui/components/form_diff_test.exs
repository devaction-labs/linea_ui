defmodule LineaUI.FormDiffLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  @fields ~w(name bio kind pw code num phone ck)a

  def mount(_params, _session, socket), do: {:ok, assign(socket, as: :x, form: form(:x, %{}))}

  def handle_event("validate", %{"x" => params}, socket),
    do: {:noreply, assign(socket, form: form(socket.assigns.as, params))}

  def handle_event("rename", %{"as" => as}, socket) do
    as = String.to_atom(as)
    {:noreply, assign(socket, as: as, form: form(as, %{}))}
  end

  defp form(as, params) do
    params =
      Map.merge(
        %{
          "name" => "",
          "bio" => "",
          "kind" => "a",
          "pw" => "",
          "code" => "",
          "num" => "",
          "phone" => "",
          "ck" => "false"
        },
        params
      )

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
      <.number_input field={@form[:num]} label="Number" />
      <.phone_input field={@form[:phone]} label="Phone" clearable />
      <.checkbox field={@form[:ck]} label="Check" />
    </.form>
    """
  end
end

defmodule LineaUI.Components.FormDiffTest do
  use LineaUI.LiveCase, async: true

  alias Phoenix.LiveView.Diff

  @controls ~w(input#x_name textarea#x_bio select#x_kind input#pw input#x_code-1 input#x_num input#x_phone input#x_ck[type=checkbox])

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
    assert [_] = find(html, "input#x_num:not([name])") |> Enum.to_list()
    assert [_] = find(html, "#x_num-value[name='x[num]']") |> Enum.to_list()
    assert [_] = find(html, "input#x_phone:not([name])") |> Enum.to_list()
    assert [_] = find(html, "#x_phone-value[name='x[phone]']") |> Enum.to_list()
    assert [_] = find(html, "input#x_ck[name='x[ck]'][type=checkbox]") |> Enum.to_list()

    html = render_hook(view, "rename", %{"as" => "y"})
    assert [_] = find(html, "input#y_name[name='y[name]']") |> Enum.to_list()
    assert [_] = find(html, "textarea#y_bio[name='y[bio]']") |> Enum.to_list()
    assert [_] = find(html, "select#y_kind[name='y[kind]']") |> Enum.to_list()
    assert [_] = find(html, "#y_code-value[name='y[code]']") |> Enum.to_list()
    assert [_] = find(html, "input#y_num:not([name])") |> Enum.to_list()
    assert [_] = find(html, "#y_num-value[name='y[num]']") |> Enum.to_list()
    assert [_] = find(html, "input#y_phone:not([name])") |> Enum.to_list()
    assert [_] = find(html, "#y_phone-value[name='y[phone]']") |> Enum.to_list()
    assert [_] = find(html, "input#y_ck[name='y[ck]'][type=checkbox]") |> Enum.to_list()
    assert find(html, "#x_name") |> Enum.to_list() == []
    assert find(html, "#x_num") |> Enum.to_list() == []
    assert find(html, "#x_phone") |> Enum.to_list() == []
    assert find(html, "#x_ck") |> Enum.to_list() == []
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

    def k_number(assigns),
      do: ~H|<.form for={@form}><.number_input field={@form[:a]} label="A" /></.form>|

    def k_number_steppers(assigns),
      do: ~H|<.form for={@form}><.number_input field={@form[:a]} label="A" steppers /></.form>|

    def k_phone(assigns),
      do: ~H|<.form for={@form}><.phone_input field={@form[:a]} label="A" clearable /></.form>|

    def k_checkbox(assigns),
      do: ~H|<.form for={@form}><.checkbox field={@form[:a]} label="A" /></.form>|

    def k_otp(assigns), do: ~H|<.form for={@form}><.otp_input field={@form[:a]} /></.form>|

    def k_date(assigns),
      do: ~H|<.form for={@form}><.date_picker field={@form[:a]} today={~D[2026-01-01]} /></.form>|
  end

  defp keystroke_bytes(fun, values \\ {"", "1", "12"}) do
    {v0, v1, v2} = values
    form = fn value -> Phoenix.Component.to_form(%{"a" => value}, as: :x) end
    socket = %Phoenix.LiveView.Socket{}
    first = fun.(%{form: form.(v0), __changed__: nil})

    {_diff, prints, comps} =
      Diff.render(socket, first, Diff.new_fingerprints(), Diff.new_components())

    {_diff, prints, comps} =
      render_step(fun, form.(v1), prints, comps, socket)

    {diff, _prints, _comps} = render_step(fun, form.(v2), prints, comps, socket)
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
        date: 600,
        number: 400,
        number_steppers: 450,
        phone: 550
      ] do
    test "a keystroke in a #{name} with a field resends little, and no classes" do
      diff = keystroke_bytes(&apply(Keys, :"k_#{unquote(name)}", [&1]))
      assert byte_size(diff) < unquote(limit)
      refute diff =~ "form-"
      refute diff =~ "shadow-"
    end
  end

  test "a toggle of a checkbox with a field resends little, and no classes" do
    diff = keystroke_bytes(&Keys.k_checkbox/1, {"false", "true", "false"})
    assert byte_size(diff) < 200
    refute diff =~ "form-"
  end

  test "an error appearing on a number, a phone and a checkbox sends no classes" do
    for fun <- [&Keys.k_number/1, &Keys.k_phone/1, &Keys.k_checkbox/1] do
      form = fn errors -> Phoenix.Component.to_form(%{"a" => "1"}, as: :x, errors: errors) end
      socket = %Phoenix.LiveView.Socket{}
      first = fun.(%{form: form.([]), __changed__: nil})

      {_diff, prints, comps} =
        Diff.render(socket, first, Diff.new_fingerprints(), Diff.new_components())

      {diff, _prints, _comps} =
        render_step(fun, form.(a: {"is invalid", []}), prints, comps, socket)

      diff = Jason.encode!(diff)
      assert diff =~ ~s(aria-invalid=\\"true\\")
      refute diff =~ "form-"
      refute diff =~ "shadow-"
      refute diff =~ "linea-invalid"
    end
  end
end
