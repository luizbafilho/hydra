defmodule Hydra.User do
  @second :erlang.convert_time_unit(1, :seconds, :native)
  @micro_second :erlang.convert_time_unit(1, :micro_seconds, :native)

  ## Public API
  def start(benchmark) do

    benchmark
    |> process_benchmark
    |> request

  end

  defp process_benchmark(%{time: time, url: url, method: method, payload: payload, headers: headers}) do
    %{
      method: method |> String.downcase |> String.to_atom,
      url: url,
      headers: Enum.map(headers, fn(h) -> String.split(h, ":") |> Enum.map(&String.strip/1) |> List.to_tuple end),
      started: :erlang.monotonic_time,
      payload: payload,
      time: time
    }
  end

  defp request(%{started: started, time: time} = request) do
    cond do
      time_elapsed(started) <= time ->
        request |> do_request |> process_request
        request(request)
      true -> :ok
    end
  end

  defp do_request(%{method: method, url: url, headers: headers, payload: payload}) do
    opts = [{:pool, :connections_pool}]
    start = :erlang.monotonic_time
    case :hackney.request(method, url, headers, payload, opts) do
      {:ok, status_code, headers, ref} ->
        {:ok, body} = :hackney.body(ref)
        latency = :erlang.monotonic_time - start
        {latency, status_code, headers, body }
      {:error, error} ->
        {:error, error}
    end
  end

  defp process_request({:error, error}) do
    Hydra.Errors.insert(error)
  end

  defp process_request({latency, status_code, headers, body}) do
    data_received = String.length(:hackney_headers.to_binary(headers) <> body)

    Hydra.Stats.insert({latency/@micro_second, status_code, data_received})
  end

  defp time_elapsed(started) do
    (:erlang.monotonic_time - started) / @second
  end
end
