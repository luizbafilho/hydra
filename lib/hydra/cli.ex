defmodule Hydra.CLI do
  @default_users    10
  @default_time     10
  @default_method   "GET"
  @default_payload  ""
  @default_slave    false
  @default_nodes    nil

  def main(args) do
    start_epmd

    args
    |> parse_args
    |> process
    |> config_http_client
    |> validations
    |> connect_nodes
    |> run
    |> summarize
  end

  defp start_epmd do
    :os.cmd('$(which epmd) -daemon')
  end

  defp validations(benchmark) do
    benchmark
    |> file_limits
    |> url_connection
  end

  defp file_limits(%{users: users} = benchmark) do
    {limit, _} =:os.cmd('ulimit -n') |> :erlang.iolist_to_binary |> Integer.parse
    if users >= limit do
      IO.puts """
      Hydra is going to open more sockets than your max open files limits permits.
      That can crash the application. Please update the limit before continue.
      """
      System.halt(0)
    end
    benchmark
  end

  defp url_connection(%{url: url} = benchmark) do
    response = try do
      :hackney.get(url)
    catch
      :exit, :badarg -> halt "Invalid URL: #{url}"
    rescue
      ArgumentError -> halt "Invalid URL: #{url}"
    end

    case response do
      {:error, :econnrefused} ->
        halt "Unable to connect to #{url}. Connection refused."
      {:error, :nxdomain} ->
        halt "Invalid URL: #{url}"
      _ ->
        benchmark
    end
  end

  defp halt(message) do
    IO.puts message
    exit(:shutdown)
  end

  defp config_http_client(%{users: users} = benchmark) do
    options = [{:timeout, 150000}, {:max_connections, users}]
    :hackney_pool.start_pool(:connections_pool, options)
    benchmark
  end

  defp process({[slave: true], _, _errors}) do
    IO.puts """
    When running in slave mode yout must define your IP address using the --inet option.
      $ hydra --slave --inet 127.0.0.1
    """
    System.halt(0)
  end

  defp process({[slave: true, inet: inet], _, _errors}) do
    slave = "slave@" <> inet |> String.to_atom
    Node.start(slave)
    Node.set_cookie(:hydra)
    IO.puts """
    Slave mode enabled @ #{inet}. Waiting master instructions.

    Press CTRL + C to exit.
    """

    :timer.sleep(:infinity)
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
        -u, --users    Number of concurrent users. Default: 10
        -t, --time     Duration of benchmark in seconds. Default: 10
        -m, --method   Defines the HTTP Method used. Default: GET
        -p, --payload  Sets a payload.
        -H, --header   Extra header to include in the request. It can be called more than once.
            --nodes    Defines the slaves nodes to run a distributed benchmark. You can specify
                       as much nodes you want. Ex. --nodes 172.20.21.2,172.20.21.3
            --slave    Starts Hydra in Slave Mode.
            --inet     Option required when running in Slave Mode. It defines the ip address
                       that is accessible to the master node.
        -h, --help     Displays this help message.
    """
    System.halt(0)
  end

  defp process(_) do
    process(:help)
  end

  defp connect_nodes(benchmark) do
    master = :"master@127.0.0.1"
    Node.start(master)
    Node.set_cookie(:hydra)

    case benchmark.nodes do
      nil  -> benchmark |> Map.put(:nodes, [master])
      _nodes ->
        slaves = benchmark.nodes |> String.split(",") |> Enum.map(&("slave@" <> &1)) |> Enum.map(&String.to_atom/1)
        slaves |> do_connect_nodes

        benchmark |> Map.put(:nodes, [master| slaves])
    end
  end

  defp do_connect_nodes(slaves) do
    slaves |> Enum.each(fn (slave) ->
      case Node.connect(slave) do
        :false ->
          slave |> show_error_connection_msg
          System.halt(1)
        :true -> :ok
      end
    end)
  end

  defp show_error_connection_msg(slave) do
    IO.puts """
    Node connection error:

      Hydra could not connect to: #{slave}
      Make sure that node is running Hydra in Slave Mode

      $ hydra --slave
    """
  end

  defp run(benchmark) do
    IO.puts "Running #{benchmark.time}s test with #{benchmark.users} users @ #{benchmark.url}\n"
    Hydra.Stats.start_link
    Hydra.Errors.start_link

    tasks = Hydra.UsersManager.start_users(benchmark)
    tasks |> Enum.each(fn task ->
      Task.await(task, :infinity)
    end)

    benchmark
  end

  defp summarize(benchmark) do
    Hydra.Results.summarize(benchmark)
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
        nodes: :string,
        inet: :string
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
end
