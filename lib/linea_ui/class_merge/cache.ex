defmodule LineaUI.ClassMerge.Cache do
  @moduledoc false

  use GenServer

  @table __MODULE__
  @limit 20_000

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec fetch(String.t(), (String.t() -> String.t())) :: String.t()
  def fetch(classes, resolve) do
    case lookup(classes) do
      [{^classes, merged}] -> merged
      _ -> store(classes, resolve.(classes))
    end
  end

  defp lookup(classes) do
    case :ets.whereis(@table) do
      :undefined -> []
      _table -> :ets.lookup(@table, classes)
    end
  end

  defp store(classes, merged) do
    case :ets.whereis(@table) do
      :undefined -> merged
      _table -> insert_below_limit(classes, merged)
    end
  end

  # A full table is emptied and starts over, so the lists in use come back in and the ones
  # that are not (classes built from data, say) do not hold the space forever.
  defp insert_below_limit(classes, merged) do
    if :ets.info(@table, :size) >= @limit, do: :ets.delete_all_objects(@table)
    :ets.insert(@table, {classes, merged})
    merged
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, nil}
  end
end
