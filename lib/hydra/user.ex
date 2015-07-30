defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link) do
    URI.parse(link) |> connect_socket |> request
  end

  def connect_socket(uri) do
    opts = [:binary, active: false]
    host = String.to_char_list(uri.host)

    {:ok, socket} = :gen_tcp.connect(host, uri.port, opts)
    IO.puts inspect socket
    {socket, uri}
  end

  def request({socket, uri}) do
    {latency, _} = :timer.tc(fn ->
      :gen_tcp.send(socket, "GET #{uri.path} HTTP/1.1\r\n\r\n")
      :gen_tcp.recv(socket, 0)
    end)

    {_, time, _} = Time.now
    Hydra.Stats.insert({latency/1000, time})

    request({socket, uri})
  end
end
