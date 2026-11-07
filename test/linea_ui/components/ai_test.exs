defmodule LineaUI.Components.AiTest do
  use LineaUI.ComponentCase, async: true

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&String.trim(LazyHTML.text(&1)))

  test "the tool trace counts the queries and the seconds" do
    html =
      render(~H"""
      <.ai_tool_trace tools={[%{label: "Pedidos"}, %{label: "Catálogo"}]} duration_ms={3000} />
      """)

    assert "2 consultas · 3 s" in texts(html, ".mono")
    assert texts(html, ".ai-chip") == ["Pedidos", "Catálogo"]
  end

  test "a running trace says so and a failed tool is marked" do
    running = render(~H|<.ai_tool_trace tools={[%{label: "Pedidos"}]} running />|)
    assert "em andamento" in texts(running, ".mono")

    failed =
      render(~H|<.ai_tool_trace tools={[%{label: "A"}, %{label: "B", failed: true}]} />|)

    assert "1 de 2 falhou" in texts(failed, ".mono")
    assert [_] = find(failed, ".ai-chip.neg") |> Enum.to_list()
  end

  test "the user's message is a bubble and the assistant's a card with the trace" do
    user = render(~H|<.ai_message role="user" name="Marina Costa">Oi</.ai_message>|)
    assert [_] = find(user, ".sg-bubble") |> Enum.to_list()

    assistant =
      render(~H"""
      <.ai_message streaming>
        <:trace>trace</:trace>
        <p>texto</p>
      </.ai_message>
      """)

    assert [_] = find(assistant, ".ai-body") |> Enum.to_list()
    assert LazyHTML.attribute(find(assistant, ".ai-msg"), "data-streaming") == ["true"]
  end

  test "a pending proposal has Aprovar and Recusar that push the id" do
    html =
      render(~H"""
      <.ai_proposal id="p1" title="Trocar" on_approve="approve" on_reject="reject">
        <:change label="Linha 3" from="A" to="B" />
      </.ai_proposal>
      """)

    assert "Aguardando você" in texts(html, ".sg-badge")
    clicks = html |> find("button") |> Enum.flat_map(&LazyHTML.attribute(&1, "phx-click"))
    assert Enum.any?(clicks, &String.contains?(&1, "approve"))
    assert Enum.any?(clicks, &String.contains?(&1, "reject"))
    assert [_] = find(html, "s") |> Enum.to_list()
  end

  test "the states of a proposal" do
    approved =
      render(
        ~H|<.ai_proposal id="p" title="T" status={:approved} note="Aprovado por Ana" on_undo="undo" />|
      )

    assert "Aprovado" in texts(approved, ".sg-badge")

    assert String.contains?(
             LazyHTML.text(find(approved, ".ai-proposal-foot")),
             "Aprovado por Ana"
           )

    assert [_] = find(approved, "button.ai-proposal-link") |> Enum.to_list()

    rejected = render(~H|<.ai_proposal id="p" title="T" status="rejected" />|)

    assert String.contains?(
             LazyHTML.text(find(rejected, ".ai-proposal-foot")),
             "nada foi alterado"
           )

    assert find(rejected, ".ai-proposal-foot.actions") |> Enum.to_list() == []
  end

  test "the composer is a form with the text and passes phx-submit" do
    html =
      render(~H"""
      <.ai_composer id="c" context={[:pedidos]} value="oi" phx-submit="send" phx-change="draft" />
      """)

    assert LazyHTML.attribute(find(html, "form"), "phx-submit") == ["send"]
    assert LazyHTML.attribute(find(html, "textarea"), "name") == ["message"]
    assert String.trim(LazyHTML.text(find(html, "textarea"))) == "oi"
    assert "Contexto: Pedidos" in texts(html, ".ai-chip")
    assert [_] = find(html, "button[type=submit]") |> Enum.to_list()
  end

  test "streaming swaps send for Parar" do
    html = render(~H|<.ai_composer id="c" streaming on_stop="stop" />|)
    assert find(html, "button[type=submit]") |> Enum.to_list() == []
    assert [_] = find(html, "button[aria-label=Parar]") |> Enum.to_list()
  end

  test "suggestions are buttons that send the prompt" do
    html =
      render(~H"""
      <.prompt_suggestions items={[%{title: "Resumo", text: "Faça um resumo"}]} on_pick="ask" />
      """)

    assert [click] = LazyHTML.attribute(find(html, "button"), "phx-click")
    assert String.contains?(click, "Faça um resumo")
    assert String.contains?(click, "ask")
  end

  test "the conversation list marks the open one and groups by day" do
    conversations = [
      %{id: "a", title: "Primeira", day: "Hoje", pending: true, patch: "/a"},
      %{id: "b", title: "Segunda", day: "Ontem", status: "consulta", patch: "/b"}
    ]

    html = render(~H|<.conversation_list conversations={conversations} active="b" />|)

    assert texts(html, ".ai-conversations-day") == ["Hoje", "Ontem"]
    assert LazyHTML.attribute(find(html, "a.ai-conv.on"), "href") == ["/b"]
    assert [_] = find(html, ".ai-dot") |> Enum.to_list()
  end

  test "the search filters the conversations and none shows the empty state" do
    conversations = [
      %{id: "a", title: "Cimento", day: "Hoje"},
      %{id: "b", title: "ICMS", day: "Hoje"}
    ]

    html =
      render(
        ~H|<.conversation_list conversations={conversations} search="cim" on_select="open" />|
      )

    assert texts(html, ".ai-conv-title") == ["Cimento"]

    empty = render(~H|<.conversation_list conversations={[]} />|)
    assert [_] = find(empty, ".ai-conversations-empty") |> Enum.to_list()
  end

  test "the chat has a footnote only when given" do
    assert texts(render(~H|<.ai_chat id="c" />|), ".ai-chat-footnote") == []

    assert texts(render(~H|<.ai_chat id="c" footnote="Aviso" />|), ".ai-chat-footnote") ==
             ["Aviso"]
  end

  test "the chat shows the greeting, then the messages with their proposal" do
    start = render(~H|<.ai_chat id="c" greeting="Bom dia, Marina" />|)
    assert texts(start, "h1") == ["Bom dia, Marina"]

    messages = [
      %{id: 1, role: :user, name: "Marina Costa", text: "Pergunta"},
      %{
        id: 2,
        role: :assistant,
        text: "Achei **1 pedido**.",
        proposal: %{id: "p", title: "Trocar", changes: [%{label: "Linha", from: "A", to: "B"}]}
      }
    ]

    html = render(~H|<.ai_chat id="c" messages={messages} on_approve="approve" />|)
    assert [_] = find(html, ".ai-body > p b.ink") |> Enum.to_list()
    assert [_] = find(html, "#p.ai-proposal") |> Enum.to_list()
    assert find(html, "h1") |> Enum.to_list() == []
    assert "Propõe, você aprova" in texts(html, ".sg-badge")
  end
end
