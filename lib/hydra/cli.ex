defmodule Hydra.CLI do
  @default_users    10
  @default_time     10
  @default_method   "GET"
  @default_payload  ""
  @default_slave    false
  @default_nodes    nil

  def main(args) do
    args
    |> parse_args
    |> process
    |> connect_nodes
    |> run
    |> summarize
  end

  defp process({parsed, [url], errors}) do
    users   = Keyword.get(parsed, :users,   @default_users)
    time    = Keyword.get(parsed, :time,    @default_time)
    method  = Keyword.get(parsed, :method,  @default_method)
    payload = Keyword.get(parsed, :payload, @default_payload)
    slave   = Keyword.get(parsed, :slave,   @default_slave)
    nodes   = Keyword.get(parsed, :nodes,   @default_nodes)
    help    = Keyword.get(parsed, :help)

    headers = Keyword.get_values(parsed, :headers)

    if length(errors) > 0, do: process(:help)
    if help, do: process(:help)

    %{users: users, time: time, url: url, method: method, payload: payload, headers: headers, slave: slave, nodes: nodes}
  end

  defp process(:help) do
    IO.puts """
    Usage: hydra [options] url
      Options:
        -u, --users    Number of concurrent users. Default: 10 users
        -t, --time     Duration of benchmark in seconds. Default: 10 seconds
        -m, --method   Defines the HTTP Method used. Default: GET
        -p, --payload  Sets a payload
        -H, --header   Extra header to include in the request. It can be called more than once.
        -h, --help     Displays this help message
    """
    System.halt(0)
  end

  defp process(_) do
    process(:help)
  end

  defp slave_mode do
    IO.puts """
      Slave mode enabled. Waiting master instructions.

      Press CTRL + C to exit.
    """
    Node.start(:"slave@127.0.0.1")
    :timer.sleep(:infinity)
  end

  defp connect_nodes(benchmark) do
    if benchmark.slave, do: slave_mode

    master = :"master@127.0.0.1"
    Node.start(master)

    case benchmark.nodes do
      nil  -> benchmark |> Map.put(:nodes, [master])
      nodes ->
        slaves = benchmark.nodes |> String.split(",") |> Enum.map(&("slave@" <> &1)) |> Enum.map(&String.to_atom/1)
        slaves |> Enum.each(fn (slave) ->
          case Node.connect(slave) do
            :false ->
              IO.puts """
              Node connection error:

                Hydra could not connect to: #{slave}
                Make sure that node is running Hydra in Slave Mode

                $ hydra --slave
              """
              System.halt(1)
            :true -> :ok
          end
        end)

        benchmark |> Map.put(:nodes, [master| slaves])
    end
  end

  defp run(benchmark) do
    IO.puts " Running #{benchmark.time}s test with #{benchmark.users} users @ #{benchmark.url}\n"
    Hydra.Stats.start_link

    tasks = Hydra.UsersManager.start_users(benchmark)
    tasks |> Enum.each(fn task ->
      Task.await(task, :infinity)
    end)

    benchmark
  end

  defp summarize(%{time: time}) do
    IO.puts "Collecting Stats...\n"

    reqs = Hydra.Stats.all

    reqs_latency = Enum.map(reqs, fn ({latency, _, _}) -> latency end)
    data_received = Stream.map(reqs, fn ({_, _, data}) -> data end) |> Enum.sum

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
    Enum.map(reqs, fn ({_, status_code, _}) -> status_code end)
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
        help: :boolean,
        headers: :keep,
        method: :string,
        payload: :string,
        slave: :boolean,
        nodes: :string
      ],
      aliases: [
        u: :users,
        t: :time,
        h: :help,
        H: :headers,
        m: :method,
        p: :payload
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
