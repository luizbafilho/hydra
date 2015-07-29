defmodule Hydra do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(HTTPoison, [arg1, arg2, arg3])
      supervisor(Task.Supervisor, [[name: Hydra.UsersSupervisor]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hydra.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def main(args) do
    args |> parse_args |> process
  end

  def process({[users: users, time: time], link}) do
    Hydra.UsersPool.start_users(users, "/ping")
    IO.puts "Running the benckmark..."
    :timer.sleep(time*1000)
    IO.puts "Benchmark Done!"
  end

  def parse_args(args) do
    {options, [link], _} =  OptionParser.parse(args,
      switches: [users: :integer, time: :integer],
      aliases: [u: :users, t: :time]
    )
    {options, link}
  end
end
