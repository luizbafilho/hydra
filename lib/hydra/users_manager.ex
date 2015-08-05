defmodule Hydra.UsersManager do
  def start_users(%{users: users} = benchmark) do
    Enum.flat_map(benchmark.nodes, fn node ->
      Enum.map(0..users, fn _ ->
        Task.Supervisor.async({Hydra.UsersSupervisor, node}, Hydra.User, :start, [benchmark])
      end)
    end)
  end

  def terminate_users do
    Supervisor.which_children(Hydra.UsersSupervisor) |> Enum.each(fn ({_,u, _, _}) -> Process.exit(u, :kill)  end)
  end
end
