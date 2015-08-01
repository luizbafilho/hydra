defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link) do
    connect |> request(link)
  end

  def connect do
    {:ok, conn} = :hackney.connect(:hackney_tcp_transport, << "localhost" >>, 8080, [])
    conn
  end

  def request(conn, link) do
    {latency, _} = :timer.tc(fn ->
      opts = {:get, << "/" >>, [], <<>>}
      {:ok, status_code, headers, ref} = :hackney.send_request(conn, opts)
      :hackney.body(ref)
    end)

    {_, time, _} = Time.now
    Hydra.Stats.insert({latency, time})

    request(conn, link)
  end
end
