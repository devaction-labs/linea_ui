{:ok, _} =
  Supervisor.start_link(
    [{Phoenix.PubSub, name: LineaUI.TestPubSub}, LineaUI.TestEndpoint],
    strategy: :one_for_one
  )

ExUnit.start()
