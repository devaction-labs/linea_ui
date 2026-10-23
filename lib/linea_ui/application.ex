defmodule LineaUI.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([LineaUI.ClassMerge.Cache],
      strategy: :one_for_one,
      name: LineaUI.Supervisor
    )
  end
end
