defmodule LineaUI.Components.FormsLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule SignupLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket) do
      {:ok, assign(socket, form: to_form(%{}, as: :signup), test: session["test"])}
    end

    def handle_event("validate", %{"signup" => params}, socket) do
      {:noreply, assign(socket, form: to_form(params, as: :signup, errors: errors(params)))}
    end

    def handle_event("save", %{"signup" => params}, socket) do
      send(socket.assigns.test, {:saved, params})
      {:noreply, socket}
    end

    defp errors(params) do
      case Map.get(params, "username", "") do
        "" ->
          [username: {"can't be blank", []}]

        name when byte_size(name) < 3 ->
          [username: {"should be at least %{count} character(s)", [count: 3]}]

        _name ->
          []
      end
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="signup" phx-change="validate" phx-submit="save">
        <.input field={@form[:username]} label="Username" phx-debounce="300" />
        <.textarea field={@form[:bio]} label="Bio" />
        <.radio_group field={@form[:plan]} options={[{"Free", "free"}, {"Pro", "pro"}]} />
        <.checkbox field={@form[:terms]} label="I agree" />
        <.switch field={@form[:notify]} label="Notify" />
        <.range field={@form[:volume]} min={0} max={100} />
        <.checkbox_group field={@form[:roles]} options={[{"Admin", "admin"}, {"Editor", "editor"}]} />
        <.input field={@form[:amount]} mask="numeral" mask_submit="raw" />
        <.input field={@form[:card]} mask="credit_card" />
      </.form>
      """
    end
  end

  test "errors follow used_input?: only the touched field shows its error", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, SignupLive, session: %{"test" => self()})
    refute html =~ "should be at least"

    html =
      view
      |> form("#signup", signup: %{username: "ab"})
      |> render_change(%{"_unused_bio" => ""})

    assert html =~ "should be at least 3 character"
    assert [_] = find(html, "input#signup_username[aria-invalid=true]") |> Enum.to_list()
    assert [_] = find(html, "input#signup_username[phx-debounce='300']") |> Enum.to_list()
    refute html =~ "can&#39;t be blank"
  end

  test "every control submits through its field name", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, SignupLive, session: %{"test" => self()})

    view
    |> form("#signup",
      signup: %{
        username: "alex",
        bio: "hi",
        plan: "pro",
        terms: "true",
        notify: "true",
        volume: "40",
        roles: ["editor"],
        card: "4111 1111"
      }
    )
    |> render_submit(%{"signup" => %{"amount" => "1234.5"}})

    assert_receive {:saved, saved}

    assert %{
             "username" => "alex",
             "bio" => "hi",
             "plan" => "pro",
             "terms" => "true",
             "notify" => "true",
             "volume" => "40",
             "roles" => ["editor"],
             "amount" => "1234.5",
             "card" => "4111 1111"
           } = saved
  end

  test "unchecked boxes and switches submit their unchecked value", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, SignupLive, session: %{"test" => self()})
    view |> form("#signup", signup: %{username: "alex"}) |> render_submit()
    assert_receive {:saved, %{"terms" => "false", "notify" => "false", "roles" => [""]}}
  end

  test "the server's values come back checked after a change", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, SignupLive, session: %{"test" => self()})

    html =
      view
      |> form("#signup", signup: %{plan: "free", terms: "true", roles: ["admin"]})
      |> render_change()

    assert [_] = find(html, "input[name='signup[plan]'][value=free][checked]") |> Enum.to_list()
    assert [_] = find(html, "input#signup_terms[checked]") |> Enum.to_list()

    assert [_] =
             find(html, "input[name='signup[roles][]'][value=admin][checked]") |> Enum.to_list()
  end

  test "a raw masked input carries the field in its hidden input", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, SignupLive, session: %{"test" => self()})
    html = view |> form("#signup") |> render_change(%{"signup" => %{"amount" => "99"}})

    assert [_] =
             find(html, "input#signup_amount-raw[type=hidden][name='signup[amount]'][value='99']")
             |> Enum.to_list()

    assert [_] =
             find(html, "input#signup_amount[phx-hook='LineaUI.InputMask']:not([name])")
             |> Enum.to_list()
  end
end
