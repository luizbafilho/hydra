defmodule Hydra do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Hydra.Stats, []),
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
    Hydra.UsersPool.start_users(users, link)
    IO.puts """
    Running #{time}s test with #{users} users @ #{link}
    """
    :timer.sleep(time*1000)
    Hydra.UsersPool.terminate_users
    print_stats(time)
    IO.puts "Benchmark Done!"
  end

  defp formatted_diff(diff) when diff > 1000 do
    time = diff/1000
    cond do
      is_float(time) ->
        [time |> Float.to_string(decimals: 2), "ms"]
      is_integer(time) ->
        [time |> Integer.to_string, "ms"]
    end
  end

  defp formatted_diff(diff) when is_float(diff), do: [diff |> Float.to_string(decimals: 2), "µs"]
  defp formatted_diff(diff) when is_integer(diff), do: [diff |> Integer.to_string, "µs"]

  def print_stats(time) do
    reqs = Hydra.Stats.all

    latency = Stream.map(reqs, fn ({latency, _}) -> latency end)
    count = Enum.count(reqs)

    IO.puts "Collecting Stats...\n"
    stdev = latency |> Statistics.stdev
    avg   = (latency |> Enum.sum)/count
    min   = latency |> Enum.min
    max   = latency |> Enum.max

    msg = """
      Latency:     #{formatted_diff(avg)} (Avg)
      Stdev:       #{formatted_diff(stdev)}
      Min:         #{formatted_diff(min)}
      Max:         #{formatted_diff(max)}
      Reqs/Sec:    #{count/time}

      #{count} requests in #{time}s
    """
    IO.puts msg
  end

  def parse_args(args) do
    {options, [link], _} =  OptionParser.parse(args,
      switches: [users: :integer, time: :integer],
      aliases: [u: :users, t: :time]
    )
    {options, link}
  end
end
