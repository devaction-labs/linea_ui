{:ok, _} = Supervisor.start_link([LineaUI.TestEndpoint], strategy: :one_for_one)
ExUnit.start()
