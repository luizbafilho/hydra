defmodule Hydra.User do
  use Timex

  ## Public API
  def start(benchmark) do

    benchmark
    |> process_benchmark
    |> connect
    |> request

  end

  defp process_benchmark(%{time: time, url: url, method: method, payload: payload, headers: headers}) do
    %{
      method: method |> String.downcase |> String.to_atom,
      uri: URI.parse(url),
      headers: Enum.map(headers, fn(h) -> String.split(h, ":") |> Enum.map(&String.strip/1) |> List.to_tuple end),
      started: :erlang.monotonic_time,
      payload: payload,
      time: time
    }
  end

  defp connect(%{uri: uri} = request) do
    {:ok, conn} = :hackney.connect(:hackney_tcp_transport, uri.host, uri.port, [])
    request |> Map.put(:conn, conn)
  end

  defp request(%{started: started, time: time} = request) do
    cond do
      time_elapsed(started) <= time ->
        request |> do_request |> process_request
        request(request)
      true -> :ok
    end
  end

  defp do_request(%{conn: conn, method: method, uri: uri, headers: headers, payload: payload}) do
    :timer.tc(fn ->
      opts = {method, uri.path || "/" , headers, payload}
      {:ok, status_code, headers, ref} = :hackney.send_request(conn, opts)
      {:ok, body} = :hackney.body(ref)
      { status_code, headers, body }
    end)
  end

  defp process_request({latency, {status_code, headers, body}}) do
    {_, seconds, _} = :erlang.timestamp

    data_received = String.length(:hackney_headers.to_binary(headers) <> body)

    Hydra.Stats.insert({seconds, latency, status_code, data_received})
  end

  defp time_elapsed(started) do
    (:erlang.monotonic_time - started) / :erlang.convert_time_unit(1, :seconds, :native)
  end
end
