defmodule LineaUI.Test.ChoiceLive do
  @moduledoc false

  use Phoenix.LiveView
  use LineaUI

  @tags [
    %{value: "t1", label: "Urgent"},
    %{value: "t2", label: "Wholesale"},
    %{value: "t3", label: "Retail"}
  ]

  def mount(_params, _session, socket) do
    form =
      to_form(
        %{"status" => "all", "channels" => [], "tag_ids" => ["t3"], "from" => nil, "to" => nil},
        as: :filter
      )

    {:ok, assign(socket, form: form, tags: Enum.take(@tags, 2), last: nil)}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="filter" phx-change="change">
      <.radio_group
        field={@form[:status]}
        variant="chip"
        color="primary"
        options={[
          %{label: "Todos", value: "all", count: 128},
          %{label: "Rascunho", value: "draft", count: 4}
        ]}
      />
      <.checkbox_group
        field={@form[:channels]}
        variant="card"
        options={[%{label: "E-mail", value: "email", description: "Daily digest"}]}
      />
      <.tags_input
        field={@form[:tag_ids]}
        options={@tags}
        selected_options={[%{value: "t3", label: "Retail"}]}
        create={false}
        on_search="search_tags"
        removable
      />
      <.date_picker
        start_field={@form[:from]}
        end_field={@form[:to]}
        locale="pt_BR"
        today={~D[2026-10-24]}
        presets={[{"Este mês", "this_month"}]}
      />
    </.form>
    <p id="last">{inspect(@last)}</p>
    """
  end

  def handle_event("change", %{"filter" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :filter), last: params)}

  def handle_event("search_tags", %{"query" => query}, socket) do
    found =
      Enum.filter(@tags, &String.contains?(String.downcase(&1.label), String.downcase(query)))

    {:noreply, assign(socket, tags: found, last: {:search, query})}
  end
end
