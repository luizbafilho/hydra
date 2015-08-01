defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link) do
    uri = URI.parse(link)
    uri |> connect |> request
  end

  def connect(uri) do
    {:ok, conn} = :hackney.connect(:hackney_tcp_transport, uri.host, uri.port, [])
    {conn, uri}
  end

  def request({conn, uri}) do
    {latency, _} = :timer.tc(fn ->
      opts = {:get, uri.path || "/" , [], <<>>}
      {:ok, status_code, headers, ref} = :hackney.send_request(conn, opts)
      :hackney.body(ref)
    end)

    {_, time, _} = Time.now
    Hydra.Stats.insert({latency, time})

    request({conn, uri})
  end
end
