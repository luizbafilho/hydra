defmodule Hydra.User do

  ## Public API
  def start(link) do
    connect_socket |> request(link)
  end

  def connect_socket do
    opts = [:binary, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 8080, opts)
    IO.puts inspect socket
    socket
  end

  def request(socket, link) do
    :gen_tcp.send(socket, "GET #{link} HTTP/1.1\r\n\r\n")
    :gen_tcp.recv(socket, 0)

    request(socket, link)
  end
end
