defmodule Hydra.Stats do
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def insert(stat) do
    Agent.update(__MODULE__, &Enum.into(&1, [stat]))
  end

  def all do
    Agent.get(__MODULE__, &(&1), :infinity)
  end
end
