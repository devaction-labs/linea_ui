defmodule LineaUI.Test.PickersLive do
  @moduledoc false

  use Phoenix.LiveView
  use LineaUI

  @authors [%{value: 1, label: "John Doe"}, %{value: 2, label: "Emilie Watson"}]

  def mount(_params, _session, socket) do
    form =
      to_form(%{"state" => "AL", "tags" => ["a"], "day" => nil, "at" => nil, "body" => ""},
        as: :trip
      )

    {:ok,
     socket
     |> assign(form: form, authors: @authors, last: nil)
     |> allow_upload(:photos, accept: ~w(.jpg .png .txt), max_entries: 2)}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="trip" phx-change="change" phx-submit="save">
      <.select field={@form[:state]} options={[{"Alabama", "AL"}, {"Alaska", "AK"}]} />
      <.tags_input field={@form[:tags]} />
      <.date_picker field={@form[:day]} />
      <.time_picker field={@form[:at]} on_change="time_changed" />
      <.text_editor field={@form[:body]} on_change="body_changed" />
      <.upload upload={@uploads.photos} on_cancel="cancel" />
    </.form>
    <.select id="authors" name="authors" options={@authors} multiple on_search="search" />
    <p id="last">{inspect(@last)}</p>
    <p id="state">{@form[:state].value}</p>
    <button id="server-set" phx-click="server-set">Set</button>
    """
  end

  def handle_event("change", %{"trip" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :trip), last: params)}

  def handle_event("save", _params, socket) do
    names =
      consume_uploaded_entries(socket, :photos, fn _meta, entry -> {:ok, entry.client_name} end)

    {:noreply, assign(socket, last: names)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    found =
      Enum.filter(@authors, &String.contains?(String.downcase(&1.label), String.downcase(query)))

    {:noreply, assign(socket, authors: found, last: {:search, query})}
  end

  def handle_event("cancel", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :photos, ref)}

  def handle_event("server-set", _params, socket) do
    params = Map.merge(socket.assigns.form.params, %{"state" => "AK", "day" => "2026-01-02"})
    {:noreply, assign(socket, form: to_form(params, as: :trip))}
  end

  def handle_event(event, params, socket) when event in ~w(time_changed body_changed),
    do: {:noreply, assign(socket, last: {event, params})}
end
