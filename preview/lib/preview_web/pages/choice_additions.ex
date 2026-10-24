defmodule PreviewWeb.Pages.ChoiceAdditions do
  use PreviewWeb.Page, title: "Choice Additions", category: :forms, lineone: "forms-radio"

  @tags [
    %{value: "t1", label: "Urgent"},
    %{value: "t2", label: "Wholesale"},
    %{value: "t3", label: "Retail"},
    %{value: "t4", label: "Export"}
  ]

  def mount(socket) do
    form =
      to_form(
        %{"status" => "all", "channels" => ["email"], "plan" => "basic", "tag_ids" => ["t3"]},
        as: :f
      )

    assign(socket, form: form, tags: @tags)
  end

  def handle_event("change", %{"f" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :f))}

  def handle_event("search_tags", %{"query" => query}, socket) do
    found =
      Enum.filter(@tags, &String.contains?(String.downcase(&1.label), String.downcase(query)))

    {:noreply, assign(socket, tags: found)}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="choice-form" phx-change="change">
      <.example title="Radio chips" text="Status filter chips with counts.">
        <.radio_group
          field={@form[:status]}
          variant="chip"
          color="primary"
          options={[
            %{label: "Todos", value: "all", count: 128},
            %{label: "Rascunho", value: "draft", count: 4},
            %{label: "Confirmado", value: "confirmed", count: 12},
            %{label: "Entregue", value: "delivered"}
          ]}
        />
      </.example>
      <.example title="Radio cards" text="A card per option." class="mt-5 max-w-xl">
        <.radio_group field={@form[:plan]} variant="card" color="primary" class="grid-cols-2">
          <:radio value="basic" description="One store, one user" icon="huge-store-01">
            Basic
          </:radio>
          <:radio value="pro" description="Unlimited stores" icon="huge-rocket-01" count={3}>
            Pro
          </:radio>
        </.radio_group>
      </.example>
      <.example title="Checkbox chips and cards" text="Several values." class="mt-5 space-y-4">
        <.checkbox_group
          field={@form[:channels]}
          variant="chip"
          color="success"
          options={[%{label: "E-mail", value: "email", count: 3}, {"SMS", "sms"}, {"WhatsApp", "wa"}]}
        />
        <.checkbox_group
          field={@form[:channels]}
          variant="card"
          options={[
            %{label: "E-mail", value: "email", description: "Daily digest"},
            %{label: "SMS", value: "sms", description: "Only urgent"}
          ]}
          class="max-w-sm"
        />
      </.example>
      <.example title="Tags from a searched list" text="Option-picking mode." class="mt-5 max-w-md">
        <.tags_input
          field={@form[:tag_ids]}
          options={@tags}
          selected_options={[%{value: "t3", label: "Retail"}]}
          create={false}
          on_search="search_tags"
          removable
          placeholder="Search tags"
        />
      </.example>
      <.example title="Date range" text="Two fields, presets, pt-BR." class="mt-5 max-w-md">
        <.date_picker
          id="range"
          start_name="from"
          end_name="to"
          locale="pt_BR"
          week_start={1}
          value={{~D[2026-10-01], ~D[2026-10-31]}}
          today={~D[2026-10-24]}
          placeholder="Período"
          presets={[
            {"Hoje", "today"},
            {"Últimos 7 dias", "last_7_days"},
            {"Este mês", "this_month"},
            {"Mês passado", "last_month"}
          ]}
        />
      </.example>
    </.form>
    """
  end
end
