defmodule Hydra do
  use Application

  @default_users 10
  @default_time 10

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
    args
    |> parse_args
    |> process
    |> run
    |> summarize
  end

  defp process({parsed, [url], _}) do
    users = Keyword.get(parsed, :users, @default_users)
    time  = Keyword.get(parsed, :time, @default_time)
    help  = Keyword.get(parsed, :help)

    if help, do: process(:true)

    {users, time, url}
  end

  defp process(:help) do
    IO.puts """
    Usage: hydra [options] url
      Options:
        -u, --users  Number of concurrent users. Default: 10 users
        -t, --time   Duration of benchmark in seconds. Default: 10 seconds
        -h, --help   Displays this help message
    """
    System.halt(0)
  end

  defp process(_) do
    process(:help)
  end

  defp run({users, time, url}) do
    IO.puts """
    Running #{time}s test with #{users} users @ #{url}
    """
    Hydra.UsersPool.start_users(users, url)
    :timer.sleep(time*1000)
    Hydra.UsersPool.terminate_users
    time
  end

  defp summarize(time) do
    IO.puts "Collecting Stats...\n"

    reqs = Hydra.Stats.all

    reqs_latency = Enum.map(reqs, fn ({_, latency, _, _}) -> latency end)
    data_received = Stream.map(reqs, fn ({_, _, _, data}) -> data end) |> Enum.sum

    reqs_latency
    |> average_response
    |> standard_deviation
    |> min_response
    |> max_response
    |> reqs_secs(time)

    status_codes(reqs)

    IO.puts "\n  #{length(reqs_latency)} requests in #{time}s, #{bytes_to_mb(data_received)} read\n"
  end

  defp status_codes(reqs) do
    codes_map =
    Enum.map(reqs, fn ({_, _, status_code, _}) -> status_code end)
    |> Enum.reduce(Map.new, fn (code, map) ->
        case code do
          200 -> map
          _ -> Map.update(map, code, 0, &(&1 + 1))
        end
      end)

    if Map.keys(codes_map) |> length > 0, do:
      IO.puts "  Non 200 responses: "
      codes_map |> Enum.each(fn({k, v}) -> IO.puts "    #{k} => #{v}" end)
  end

  defp average_response(reqs_latency) do
    avg = (reqs_latency |> Enum.sum) / (reqs_latency |> length)
    IO.puts "  Latency:     #{formatted_diff(avg)} (Avg)"
    reqs_latency
  end

  defp standard_deviation(reqs_latency) do
    stdev = reqs_latency |> Statistics.stdev
    IO.puts "  Stdev:       #{formatted_diff(stdev)}"
    reqs_latency
  end

  defp min_response(reqs_latency) do
    min = reqs_latency |> Enum.min
    IO.puts "  Min:         #{formatted_diff(min)}"
    reqs_latency
  end

  defp max_response(reqs_latency) do
    max = reqs_latency |> Enum.max
    IO.puts "  Max:         #{formatted_diff(max)}"
    reqs_latency
  end

  defp reqs_secs(reqs_latency, time) do
    IO.puts "  Reqs/Sec:    #{length(reqs_latency)/time}\n"
  end

  def parse_args(args) do
    OptionParser.parse(args,
      strict: [
        users: :integer,
        time: :integer,
        help: :boolean
      ],
      aliases: [
        u: :users,
        t: :time,
        h: :help
      ]
    )
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

  defp bytes_to_mb(bytes) do
    mb = 1024.0 * 1024.0
    Float.to_string(bytes / mb, [decimals: 2, compact: true]) <> "MB"
  end
end
