defmodule Hydra.UsersManager do
  def start_users(%{users: users} = benchmark) do
    0..users |> Enum.map(fn(_) ->
      Task.Supervisor.async(Hydra.UsersSupervisor, Hydra.User, :start, [benchmark])
    end)
  end

  def terminate_users do
    Supervisor.which_children(Hydra.UsersSupervisor) |> Enum.each(fn ({_,u, _, _}) -> Process.exit(u, :kill)  end)
  end
end
