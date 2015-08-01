defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link, method, payload) do
    http_method = method |> String.downcase |> String.to_atom
    uri = URI.parse(link)

    uri |> connect |> request(http_method, payload)
  end

  defp connect(uri) do
    {:ok, conn} = :hackney.connect(:hackney_tcp_transport, uri.host, uri.port, [])
    {conn, uri}
  end

  defp request({conn, uri}, http_method, payload) do
    {latency, response} = :timer.tc(fn ->
      opts = {http_method, uri.path || "/" , [], payload}
      {:ok, status_code, headers, ref} = :hackney.send_request(conn, opts)
      {:ok, body} = :hackney.body(ref)
      { status_code, headers, body }
    end)

    process_request(latency, response)

    request({conn, uri}, http_method, payload)
  end

  defp process_request(latency, {status_code, headers, body}) do
    {_, time, _} = Time.now

    data_received = String.length(:hackney_headers.to_binary(headers) <> body)

    Hydra.Stats.insert({time, latency, status_code, data_received})
  end
end
