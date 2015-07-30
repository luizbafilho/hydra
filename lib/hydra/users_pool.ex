defmodule Hydra.UsersPool do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    supervise([], strategy: :one_for_one)
  end

  def start_users(0, _), do: IO.puts "All users started!"
  def start_users(n, link) do
    Task.Supervisor.start_child(Hydra.UsersSupervisor, fn ->
      Hydra.User.start(link)
    end)
    start_users(n - 1, link)
  end
end

