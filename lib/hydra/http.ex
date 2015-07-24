defmodule Http do
  use GenServer

  @initial_state %{socket: nil}

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
    {:ok, pid } = GenServer.start_link(__MODULE__, @initial_state)
    pid
  end

  def run do
    Agent.start_link(fn -> 0 end, name: __MODULE__)

    processes = Enum.reduce(1..3, [], fn(_, processes) -> [start_link | processes] end)

    # one = start_link
    # two = start_link
    # three = start_link

    processes |> Enum.each(fn(p) -> Task.start_link(fn -> p |> Http.get("/") end) end)

    # Task.start_link(fn -> one |> Http.get("/", 10000) end)
    # Task.start_link(fn -> two |> Http.get("/", 10000) end)
    # Task.start_link(fn -> three |> Http.get("/", 10000) end)
    processes
  end

  def stop(procs) do
    procs |> Enum.each(fn(p) -> GenServer.call(p, :stop) end)
  end


  def init(state) do
    opts = [:binary, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 8080, opts)
    {:ok, %{state | socket: socket}}
  end

  def get(pid, link) do
    GenServer.call(pid, {:get, link}, :infinity)
  end

  def handle_call({:get, link}, from, %{socket: socket} = state) do
    socket |> request(link)

    {:reply, "Done total", state}
  end

  def handle_call(:stop, _from, state) do
    reqs = Agent.get(__MODULE__, fn sum -> sum end)
    IO.puts "Total requests => #{reqs}"
    {:stop, :normal, :ok, state}
  end

  # def request(socket, link, 0) do
  #   reqs = Agent.get(__MODULE__, fn sum -> sum end)
  #   IO.puts "Done! => #{reqs} requests"
  # end

  def request(socket, link) do
    :gen_tcp.send(socket, "GET #{link} HTTP/1.1\r\n\r\n")
    :gen_tcp.recv(socket, 0)

    increment
    socket |> request(link)
  end

  defp increment do
    Agent.update(__MODULE__, fn sum ->  sum + 1 end)
  end
end
