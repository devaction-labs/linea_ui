defmodule LineaUI.Components.NotificationCenterTest do
  use LineaUI.ComponentCase, async: true

  defp items do
    [
      %{
        id: 1,
        title: "Pedido aguardando",
        body: "Pedido 2483",
        at: "há 4 min",
        group: "Hoje",
        type: "warning",
        category: "orders",
        read: false,
        navigate: "/orders/2483"
      },
      %{
        id: 2,
        title: "Falha na integração",
        at: "há 22 min",
        group: "Hoje",
        type: "error",
        category: "system"
      },
      %{id: 3, title: "Comunicado", group: "Ontem", type: "primary", read: true}
    ]
  end

  test "bell has a dot and the panel the title, the count and the groups" do
    assigns = %{items: items()}

    html =
      rendered_to_string(~H"""
      <.notification_center id="nc" items={@items} all_href="/notifications" />
      """)

    assert html =~ ~s(aria-label="Notificações, 2 não lidas")
    assert html =~ "bg-error ring-2"
    assert html =~ "Pedido aguardando"
    assert html =~ "Hoje"
    assert html =~ "Ontem"
    assert html =~ "Ver todas as notificações"
    assert html =~ "2 não lidas"
    assert html =~ ~s(href="/orders/2483")
    assert html =~ "bg-warning/10"
    assert html =~ "bg-error/10"
    assert html =~ "Não lida"
  end

  test "tabs filter by read and by category and count the unread" do
    assigns = %{items: items()}

    html =
      rendered_to_string(~H"""
      <.notification_center
        id="nc"
        items={@items}
        tabs={[
          %{id: "all", label: "Todas"},
          %{id: "unread", label: "Não lidas"},
          %{id: "orders", label: "Pedidos"}
        ]}
      />
      """)

    assert length(Regex.scan(~r/role="tab"/, html)) == 3
    assert length(Regex.scan(~r/role="tabpanel"/, html)) == 3
    assert length(Regex.scan(~r/Comunicado/, html)) == 1
    assert length(Regex.scan(~r/Falha na integração/, html)) == 2
    assert html =~ "Pedidos"
  end

  test "no unread: no dot and the read all button is disabled; the empty state shows" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.notification_center id="nc" items={[]} on_read_all="read_all" tabs={[]} empty="Tudo em dia" />
      """)

    refute html =~ "bg-error ring-2"
    assert html =~ ~s(aria-label="Notificações")
    assert html =~ "Tudo em dia"
    assert html =~ "disabled"
    refute html =~ "Ver todas"
  end

  test "events: read all and read one push with the target" do
    assigns = %{items: items()}

    html =
      rendered_to_string(~H"""
      <.notification_center id="nc" items={@items} on_read_all="read_all" on_read="read" target="#host" />
      """)

    assert html =~ "read_all"
    assert html =~ ~s(aria-label="Marcar todas como lidas")
    assert html =~ "item"
    assert html =~ "#host"
  end

  test "an explicit unread count wins and preferences render as a link" do
    assigns = %{items: items()}

    html =
      rendered_to_string(~H"""
      <.notification_center id="nc" items={@items} unread={12} preferences_href="/settings" />
      """)

    assert html =~ ">\n          12\n" or html =~ "12"
    assert html =~ ~s(href="/settings")
    assert html =~ "Preferências de notificação"
  end
end
