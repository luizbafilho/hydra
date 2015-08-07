defmodule Hydra.Stats do
  def start_link do
    {:ok, pid} = Agent.start_link(fn -> [] end)
    :global.register_name(:stats, pid)
    :global.sync
  end

  def insert(stat) do
    Agent.cast(name, Enum, :into, [[stat]])
  end

  def all do
    Agent.get(name, &(&1), :infinity)
  end

  defp name do
    :global.whereis_name(:stats)
  end
end
