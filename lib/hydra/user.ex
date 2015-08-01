defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link) do
    uri = URI.parse(link)
    uri |> connect |> request
  end

  defp connect(uri) do
    {:ok, conn} = :hackney.connect(:hackney_tcp_transport, uri.host, uri.port, [])
    {conn, uri}
  end

  defp request({conn, uri}) do
    {latency, response} = :timer.tc(fn ->
      opts = {:get, uri.path || "/" , [], <<>>}
      {:ok, status_code, headers, ref} = :hackney.send_request(conn, opts)
      {:ok, body} = :hackney.body(ref)
      { status_code, headers, body }
    end)

    process_request(latency, response)

    request({conn, uri})
  end

  defp process_request(latency, {status_code, headers, body}) do
    {_, time, _} = Time.now

    data_received = String.length(:hackney_headers.to_binary(headers) <> body)

    Hydra.Stats.insert({time, latency, status_code, data_received})
  end
end
