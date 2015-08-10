defmodule Hydra.Errors do
  def start_link do
    {:ok, pid} = Agent.start_link(fn -> [] end)
    :global.register_name(:errors, pid)
    :global.sync
  end

  def insert(error) do
    Agent.cast(name, Enum, :into, [[error]])
  end

  def all do
    Agent.get(name, &(&1), :infinity)
  end

  defp name do
    :global.whereis_name(:errors)
  end
end
