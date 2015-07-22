defmodule Hydra do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(HTTPoison, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hydra.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def main(args) do
    args |> parse_args
  end

  def parse_args(args) do
    {_, [num, link], _} = OptionParser.parse(args)
    HTTPoison.start
    {n, _} = Integer.parse(num)
    {time, _} = :timer.tc(fn ->
      Enum.reduce(1..n, 0, fn(_, _) ->
        HTTPoison.get!(link,%{}, stream_to: self)
        0
      end)
    end, [])

    IO.puts inspect time/1000000
  end
end
